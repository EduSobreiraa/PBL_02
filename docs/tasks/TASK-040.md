# TASK-040 | Calcular e marcar raízes como extra

## Objetivo

Adaptar os cálculos estruturais legados necessários para exibir raízes e marcadores de F1 e F2.

## Status

**APPROVED.** Pipeline fixo de 23 estágios integrado; regressão, compilação, fitter, STA pós-fit e auditoria independente passaram.

## Dependências

- TASK-036 | regressão obrigatória aprovada.
- TASK-039 | renderer VGA/interseções/vértices aprovado; STA base com 14 endpoints sob 40 ns.
- Processador F1 existente aprovado e instanciado duas vezes pelo top para F1 e F2.
- DEC-007, DEC-031, DEC-058, DEC-059, DEC-060, DEC-063 e DEC-064 em CONSENSUS.

## Planejamento e aceite

- Auditar os módulos legados de raiz, divisão e raiz quadrada antes de reutilizar lógica.
- Calcular raízes sem alterar a validade da parábola quando o discriminante for negativo.
- Apresentar valores e marcadores no formato aprovado, com clipping e prioridades corretos.
- Incluir apenas a renderização necessária aos rótulos das raízes; não criar painel lateral ou depender de gerador de caracteres compartilhado.
- Cobrir discriminante positivo, zero e negativo, raízes racionais/fracionárias, repetidas e fora da tela.
- Medir novamente recursos e timing após incluir os extras.

## Arquivos

Definir a lista permitida na análise de contexto. Não instanciar fontes PBL02 diretamente no QSF; portar somente módulos auditados para a árvore PBL03.

## Resultado

O baseline combinacional teve regressão funcional e compilação Quartus concluídas, mas o STA pós-fit falhou em 12 endpoints RGB (pior slack VGA_G[0] = −55.101 ns; VGA_HS/VGA_VS passaram). DEC-063 substituiu a arquitetura combinacional por pipeline fixo de 23 estágios. Esses resultados são históricos e não validam o pipeline.

**Resultado pós-DEC-063:** a cadeia exata de 23 estágios foi integrada ao processador e ao handshake principal sem alterar ports físicos, QSF, SDC ou o módulo VGA do professor. START aceito captura novos operandos e invalida tokens anteriores; `result_valid` é de um ciclo; os resultados são mantidos até novo START/reset; `root_domain_valid` e `roots_ready` são sticky conforme os contratos. O handshake e a apresentação aguardam os tokens das funções habilitadas.

**Evidências executadas em 2026-11-22:**

- `sim/run_pbl03_regression.sh` passou integralmente. Inclui source checker, suites Icarus de entrada, função, F1, F1/F2, raízes (30 dirigidos + 256 vetores de referência inteira), renderer, handshake, status, e full-frame Verilator. O frame Verilator verificou 800×525, 840.000 ciclos do clock do sistema e 20.161.162 verificações vetoriais. Log: `verification/results/task-040/pipeline/aggregate-regression.log`.
- A reexecução independente da regressão e o fingerprint dos fontes estão em `verification/results/task-040/pipeline/aggregate-regression-audited.log` e `rtl-source-fingerprint.sha256`.
- `python3 verification/check_pbl03_sources.py`: PASS antes e depois da regressão agregada.
- Recompilação auditada com `quartus_sh --flow compile quartus/pbl03`: compilação completa e fitter PASS, 0 erros e 33 avisos. Log: `quartus-compile-audited.log`.
- STA pós-fit auditado no pior corner slow 1200 mV/85 °C: os 14 endpoints VGA passaram, pior slack **+2.587 ns** em `VGA_G[0]`; `VGA_HS` +31.472 ns e `VGA_VS` +31.342 ns. FF→FF passou com pior setup slack **+0.873 ns** e pior hold slack **+0.247 ns**, sem violações. Evidências atuais: `pbl03-sta-audited.rpt` e `vga-paths-audited.log`; os summaries `vga-endpoint-slacks.txt` e `ff-endpoint-slacks.txt` registram esses mesmos resultados.
- Auditoria independente APPROVED: `verification/results/task-040/audit-pipeline.md`; Compliance, Functional e Integration PASS, sem findings HIGH/CRITICAL.
- A suíte isolada de F1 confirmou `root_domain_valid` após a conclusão do token e sua limpeza em reset; a suíte de handshake confirmou que os DONEs dos processadores sem `roots_ready` não concluem a FSM principal.

Não foi realizado teste físico na placa. A TASK foi aprovada pela auditoria independente; a validação física permanece fora dos critérios de aceite desta tarefa e não é alegada.

## Implementation Brief

### Objetivo

Como extra opcional do PBL03, calcular as raízes reais de F1 e F2 com o contrato exato já aprovado e apresentá-las no VGA com marcadores e valores textuais locais. Raiz inválida/sem domínio real não produz saída visual, sem alterar a validade, os erros ou o estado de exibição da parábola correspondente.

### Requisitos

- O enunciado `TEC498_2026_2_Problema3.pdf` e `REGRAS.md` são as fontes normativas para esta TASK do PBL03. Raízes e seus marcadores são extras opcionais documentados em `REGRAS.md` §8; esta TASK implementa esse extra.
- `docs/regras.md` e `docs/requisitos.md` pertencem ao PBL02. Suas proibições/requisitos (incluindo REQ-005/006/008/011) não são fontes normativas para o PBL03.
- Preservar as regras obrigatórias do PBL03: datapaths aritméticos estruturais, FFs dedicados, uma FSM principal, uma FSM de entrada e uma por processador de função, com a hierarquia autorizada por DEC-044/046/048/049 e harmonizada por DEC-064.

### Decisões aplicáveis

- `DEC-007` — arredondar cada raiz ao inteiro mais próximo; empate exato para longe de zero. Preservar nos documentos a divergência em relação ao texto literal de truncamento de `REQ-006`.
- `DEC-031` — arquitetura matemática exata: preservar restos até o arredondamento final; associação de `x1`/`x2` aos ramos algébricos; raízes de saída signed9; não ordenar por magnitude.
- `DEC-044` e `DEC-047` — validade e exibição da parábola são independentes do domínio real das raízes. `Δ<0` deixa a parábola válida quando seus próprios critérios forem satisfeitos; nesse caso não existem marcadores/valores de raízes reais.
- `DEC-051` — sem painel lateral ou gerador de caracteres compartilhado; se rótulos de raiz forem mantidos, a renderização mínima pertence a esta TASK.
- `DEC-056` — contrato de vértices não define marcadores de raízes. A cruz verde, sua prioridade e a ausência de rótulos em DEC-056 não devem ser estendidas implicitamente às raízes.
- `DEC-058` — contrato visual de roots/labels/markers, gating, prioridade, clipping e timing.
- `DEC-059` — exception estreita a DEC-058: acrescentar somente entradas `VERILOG_FILE` para RTL PBL03 usado/auditado e os mesmos paths/categorias no manifesto. Não editar/reordenar linhas existentes ou outros assignments do QSF.
- `DEC-060` — APIs/callers de raiz, processador, renderer e compositor; interfaces sequenciais ajustadas pelo addendum de DEC-063.
- `DEC-063` — pipeline fixo de 23 estágios, tokens, START/reset/hold, `roots_ready` e gates temporais.
- `DEC-064` — CONSENSUS; aplicar ao PBL03 `REGRAS.md` e o PDF PBL03. `docs/regras.md` e `docs/requisitos.md` são materiais legados PBL02; a proibição de FSM/REQ-011 não rege esta TASK. A hierarquia permitida permanece limitada à FSM principal, FSM de entrada e FSM dos processadores de função já autorizadas; o pipeline não adiciona FSM.
- `DEC-057` e evidência final da `TASK-039` — a composição VGA atual passou síntese/fitter e 14 endpoints com slack positivo sob 40 ns; pior slack registrado +1.421 ns. Isso é margem pequena, não orçamento disponível comprovado para lógica adicional. A TASK-040 deve repetir síntese/STA completa e satisfazer os mesmos 14 endpoints sem mudar SDC, QSF, pinagem ou VGA do professor.

### Módulos envolvidos

Topologia e callers conforme DEC-060:

- `quadratic_roots` em `rtl/funcao/quadratic_roots.v`, uma instância por `processador_f1`.
- `processador_f1` em `rtl/funcao/processador_f1.v` acrescenta as saídas de raiz; `rtl/top/top_pbl03.v` já instancia o processador para F1 e F2.
- `renderizador_raizes` em `rtl/video/renderizador_raizes.v`, uma instância do top para as duas funções.
- `compositor_rgb` em `rtl/video/compositor_rgb.v` recebe os dois hits agregados do renderer e faz a prioridade RGB.

#### Auditoria da closure legado

Foram inspecionados `rtl/raizes_quadraticas.v`, `rtl/raiz_quadrada_u17.v`, `rtl/divisor_9_por_8.v`, `rtl/multiplicadores.v`, `rtl/somador_subtrator.v` e `rtl/somador_completo.v`. A análise histórica de sintaxe consultou `docs/regras.md` (regras legadas PBL02); para esta TASK, a conformidade normativa deve ser auditada contra `REGRAS.md` PBL03, que permite comportamento somente nas FSMs/FFs autorizados e exige datapaths estruturais. Isso não autoriza reutilizar os arquivos agregados diretamente: cada um contém múltiplos módulos e a auditoria desta TASK precisa verificar o port final.

Closure funcional antiga e destino do port:

| Módulo legado/dependência | Destino PBL03 |
|---|---|
| `raizes_quadraticas` | Portar como `quadratic_roots`, interface/semântica DEC-031. |
| `raiz_quadrada_17`, `etapa_raiz` | Portar em `raiz_quadrada_17.v` e `etapa_raiz.v`, respectivamente. |
| `divisor_9_por_8`, `etapa_divisao` | Portar em `divisor_9_por_8.v` e `etapa_divisao.v`, respectivamente. |
| `ramo_raizes`, `nega_condicional_9`, `soma_subtrai_10`, `incrementa_9` | Integrar a lógica combinacional no único `quadratic_roots`, usando os componentes PBL03 listados abaixo; não criar helpers RTL adicionais. |
| `nega_condicional_8`, `nega_condicional_10` | Reusar `conditional_negate_8` e `conditional_negate_10`, já no QSF/manifesto. |
| `somador_completo`, `somador_completo_raiz`, `somador_completo_divisao` | Reusar `full_adder_1bit`, já no QSF/manifesto. |
| `multiplica_com_sinal_8_por_8` | Formar magnitudes e sinal usando `multiply_unsigned_8x8` e `conditional_negate_16`, já no QSF/manifesto. |
| `subtrator_18` | Reusar `addsub_18` com subtração estrutural, já no QSF/manifesto. |

Portar a closure funcional como um módulo por arquivo. `somador_completo` será substituído por `full_adder_1bit`, já existente no projeto. Os nomes legados `raiz_quadrada_17`, `divisor_9_por_8` e `raizes_quadraticas` que aparecem na tabela seguinte são os nomes dos módulos portados, exceto a raiz pública que se chamará `quadratic_roots` conforme DEC-031. A closure tem 15 novos módulos aritméticos/funcionais e um renderer; todos os demais módulos instanciados devem ser fontes já presentes no manifesto/QSF. Se a auditoria da implementação identificar outra dependência, não a adicionar implicitamente: reabrir o Context Analysis antes de alterar a allowlist.

### Interface

- `quadratic_roots`: inputs `clk`, `system_reset`, `start_accepted`, `root_enable`, `a/b/c` signed8; outputs `delta` signed18, `x1/x2` signed9, `domain_error` e `result_valid`. `result_valid` é token de um ciclo, disponível em N+22; saídas são retidas até START aceito/reset. F2 inativa não injeta token.
- `processador_f1`: acrescentar `start_accepted` e `root_enable`; propagar token de raízes ao top como `root_result_valid`. `root_x1/x2` signed9 e `root_domain_valid` sticky; reset ou START aceito limpa, `root_result_valid && !domain_error` seta. Validade não depende do vértice/`display_enable`.
- `fsm_principal_pbl03`: input `roots_ready`, output `start_accepted`; aceitar `start_pulse` somente em REVIEW/DISPLAY. WAIT_PROCESSORS conclui apenas com `done_f1 && done_f2 && roots_ready`. START durante WAIT_PROCESSORS é ignorado. Esta alteração está dentro da FSM principal já autorizada por DEC-064.
- `top_pbl03`: `roots_ready` sticky por FF estrutural; reset/START aceito limpa; token F1 basta se F2 inativa, caso contrário tokens F1 e F2 precisam chegar. Ports físicos inalterados.
- `renderizador_raizes` permanece com a interface DEC-060/058: raízes signed9, coordenadas signed10, hits separados para marcador e label. `compositor_rgb` mantém as entradas de hits e precedência DEC-058.

Pipeline fixo, estágio 0–22: 0 captura a/b/c e enable; 1 calcula b² unsigned15 e ac signed16; 2 calcula delta signed18, erro parcial e `A_original`; 3–11 executam nove passos restauradores da raiz quadrada; 12 prepara duas lanes, numeradores/magnitudes unsigned9, `A_original`, `A_eff`, `divide_by_zero`, resíduos/sinais/ramo; 13–21 executam nove passos restauradores de divisão por lane, consumindo magnitude bits 8→0; 22 mascara divisor zero e registra arredondamento exato, delta, domínio, x1/x2 e token. Payload e token ficam alinhados. Para divisor não nulo, preservar `|N|=Q·A_original+r`, `0≤r<A_original`. Para `A_original=0`, usar `A_eff=1`, carregar `divide_by_zero=1`, mascarar Q/r em zero e produzir `domain_error=1`.

### Clock e reset

- Clock `MAX10_CLK1_50`, borda positiva; `system_reset` síncrono conforme DEC-063.
- START aceito na borda N captura o estágio 0; invalida valid[1..22] e resultados anteriores. Tokens avançam um estágio por ciclo; `result_valid` aparece em N+22 por um ciclo. Resultados permanecem estáveis até START aceito/reset. Reset limpa todas as validades e resultados. START em WAIT_PROCESSORS não interrompe o pipeline.
- Cada estágio registra payload e token por instâncias de FF dedicadas com D estrutural. O datapath entre estágios é combinacional estrutural; não introduzir FSM, contador de fase ou controle comportamental no pipeline.

### Restrições

- Aplicar `REGRAS.md` e o PDF PBL03 como fontes normativas. `docs/regras.md`/`docs/requisitos.md` são legado PBL02 e não se aplicam a esta TASK.
- Restringir Verilog comportamental aos módulos específicos de FF e às três FSMs PBL03 autorizadas (principal, entrada e uma por processador de função); manter datapaths estruturais e um módulo por arquivo, conforme `REGRAS.md` §§2 e 4 e DEC-064. Nenhuma FSM/controlador de fase adicional no pipeline.
- Preservar matemática DEC-031/062, arredondamento e associação x1/x2, layout/prioridade DEC-058, VGA do professor, ports físicos, pinagem, SDC, clock, resolução e escala.
- Critérios pós-fit: todos os caminhos FF→FF abaixo de 20 ns e todos os 14 endpoints VGA abaixo de 40 ns. Não relaxar constraints.

### Arquivos permitidos

#### RTL existente a alterar

- `rtl/funcao/quadratic_roots.v` — substituir o cálculo combinacional pela cadeia fixa de 23 estágios.
- `rtl/funcao/processador_f1.v` — ligar `start_accepted`/`root_enable`, propagar token e validade sticky.
- `rtl/controle/fsm_principal_pbl03.v` — ligar `roots_ready` e `start_accepted`, dentro do escopo da FSM principal aprovado por DEC-064.
- `rtl/top/top_pbl03.v` — ligar processadores F1/F2 e implementar `roots_ready` sticky.

#### RTL existente de suporte, somente leitura

- `rtl/primitivos/dff_sync_bit.v`, `rtl/primitivos/dff_sync8.v`, `rtl/primitivos/dff_bit.v`.
- `rtl/aritmetica/etapa_raiz.v`, `rtl/aritmetica/etapa_divisao.v`, mais as fontes aritméticas da closure portável já listadas no QSF/manifesto.
- `rtl/video/renderizador_raizes.v`, `rtl/video/compositor_rgb.v`; manter contrato DEC-058 e não inserir latência de pixel.

Os módulos de suporte/dependência da closure legada (15 módulos enumerados na tabela “Auditoria da closure legado”, incluindo `quadratic_roots` e `ramo_raizes`) já constam como fontes separadas em `quartus/pbl03.qsf` e `verification/pbl03_sources.json`. Verificação estática confirmou também que os três FFs, `processador_f1`, FSM principal, top, compositor e renderer estão presentes em ambos os inventários e que os arquivos existem no repositório. Usar os FFs existentes para armazenamento estrutural; não criar fontes Verilog, `include` ou módulos auxiliares novos. QSF/manifesto não precisam de mudanças nesta implementação. Se a closure compilável revelar dependência ausente, parar e reabrir Context Analysis.

#### Testes/callers autorizados

- Roots unit: `sim/tb_quadratic_roots.v`, `sim/quadratic_roots_vpi.c`, `sim/run_quadratic_roots_icarus.sh`, `tests/vectors/roots_directed.json`.
- Processadores F1/F2: `sim/tb_f1_processor.v`, `sim/f1_processor_vpi.c`, `sim/tb_f1_f2_processors.v`, `sim/f1_f2_processors_vpi.c`; runners `sim/run_f1_processor_icarus.sh`, `sim/run_f1_f2_processors_icarus.sh`.
- Handshake: `sim/tb_main_handshake_pbl03.v`, `sim/main_handshake_pbl03_vpi.c`, `sim/run_main_handshake_pbl03_icarus.sh`.
- Integração raster: `sim/pbl03_top_verilator.cpp`, `sim/run_pbl03_top_verilator.sh`. Renderer/compositor suites permanecem callers existentes: `sim/run_root_renderer_icarus.sh` e `sim/run_video_axes_icarus.sh`.
- Aggregate/checker: `sim/run_pbl03_regression.sh`; executar `python3 verification/check_pbl03_sources.py`, sem editar o checker.
- Evidência Quartus em `verification/results/task-040/pipeline/`: `quartus-compile.log`, `ff-endpoint-slacks.txt`, `vga-endpoint-slacks.txt`, `vga-paths-full.log`.

### Arquivos protegidos

- `vendor/vga/vga_sync.v` e demais arquivos originais fornecidos pelo professor;
- pinagem, ports físicos, resolução, escala e temporização VGA;
- `quartus/pbl03.sdc` e configuração física do projeto;
- contratos/RTL de validade, processamento e exibição da parábola, exceto conexões aditivas autorizadas pela decisão;
- resíduos do cálculo exato e suas regras de arredondamento.

### Testes exigidos

- Roots unit Icarus: latência exata N→N+22; `result_valid` por um ciclo; outputs retidos; flush por START aceito/reset; payload/token alinhados em todos os estágios; F2 inativa sem token; referência independente inteira para DEC-031 (sem `sqrt` floating point), vetores dirigidos e casos determinísticos.
- F1/F2: `root_domain_valid` sticky limpa em reset/START e seta somente em token sem erro; propagação de token; F2 inativa; a=0; delta negativo; independência de flags do vértice/parábola.
- Handshake: aceitação START apenas em REVIEW/DISPLAY; START em WAIT ignorado sem flush; roots_ready sticky; não concluir/DONE antes de `done_f1 && done_f2 && roots_ready`; F2 inativa; reset/START novo.
- Full-frame Verilator: preservar raster/latência por pixel; validar gating, roots inválidas, F2 inativa, clipping e precedência DEC-058.
- Rodar suites de renderer/compositor, `sim/run_pbl03_regression.sh` e source checker.
- Quartus: `quartus_sh --flow compile quartus/pbl03`; salvar logs/relatórios nos paths permitidos e comprovar os limites FF→FF de 20 ns e 14 endpoints VGA de 40 ns. Resultado pós-DEC-063: compilação/fitter PASS; FF→FF setup pior slack +0.873 ns, hold +0.247 ns; 14 endpoints VGA passaram, pior slack +2.587 ns em `VGA_G[0]`.
- Ferramentas: simulação funcional realizada com Icarus/VPI e integração raster com Verilator. Questa não foi executado porque a licença não estava disponível; isso não substituiu nem foi reportado como teste aprovado.

### Critérios de aceite

- Aritmética da implementação corresponde aos vetores dirigidos e referência independente que exercita DEC-031/DEC-007.
- Domínio sem raízes reais não altera a elegibilidade nem os pixels da parábola; não há raiz fictícia desenhada.
- Marcadores, rótulos, cores, prioridade, clipping e texto correspondem integralmente a DEC-058.
- As suítes Icarus acima, o frame completo Verilator, o runner agregado e source checker passaram; o log agregado registra 20.161.162 verificações vetoriais no frame completo.
- Síntese/fitter concluíram; caminhos FF→FF atenderam 20 ns e os 14 endpoints VGA atenderam 40 ns, sem relaxar restrições. Evidências pós-DEC-063 estão em `verification/results/task-040/pipeline/`.
- Auditoria independente aprovada sem findings críticos/altos em `verification/results/task-040/audit-pipeline.md`.

### Dependências

- TASK-036 — regressão base aprovada.
- TASK-039 — aprovada com marcador de vértice por predicados racionais; sua STA final registra pior slack +1.421 ns.
- Processadores F1/F2 e contratos da parábola — aprovados.
- DEC-031/058/059/060/063/064 em CONSENSUS; TASK-036 e TASK-039 aprovadas.
- A implementação/auditoria deve confirmar que só a closure mapeada acima é necessária; qualquer dependência nova fora do allowlist reabre esta TASK para revisão de contexto/decisão.

### Pendências

1. Não houve teste físico na placa. Questa não foi executado por indisponibilidade de licença; a validação disponível usa Icarus/VPI e Verilator, além da compilação e STA do Quartus. Esta limitação não bloqueia os critérios de aceite da TASK.
