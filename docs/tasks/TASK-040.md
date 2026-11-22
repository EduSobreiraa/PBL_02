# TASK-040 | Calcular e marcar raízes como extra

## Objetivo

Adaptar os cálculos estruturais legados necessários para exibir raízes e marcadores de F1 e F2.

## Status

BLOCKED

## Dependências

- TASK-036 | regressão obrigatória aprovada.
- TASK-039 | renderer VGA/interseções/vértices aprovado; STA base com 14 endpoints sob 40 ns.
- Processador F1 existente aprovado e instanciado duas vezes pelo top para F1 e F2.
- DEC-007, DEC-031, DEC-058, DEC-059 e DEC-060 em CONSENSUS.

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

Implementação e verificações funcionais concluídas. A compilação completa do Quartus terminou sem erros (36 warnings), mas o STA pós-fit falhou no limite de 40 ns para os 12 endpoints RGB. Os endpoints VGA_HS e VGA_VS passaram. A TASK permanece BLOCKED: o caminho de renderização de raízes precisa de uma decisão/ação autorizada que resolva o timing sem alterar as restrições protegidas. Nenhum constraint foi modificado.

Evidências salvas em `verification/results/task-040/`: regressão agregada (`regression.log`), compilação (`quartus-compile.log`), slack dos 14 endpoints (`endpoint-slacks.txt`) e paths completos (`vga-paths-full.log`). Pior endpoint: VGA_G[0], slack −55.101 ns, chegada 95.101 ns para requisito de 40.000 ns; caminho inicia no registrador b₂ de F2 e atravessa o cálculo de raízes até a composição RGB. O relatório de endpoints registra todas as 12 violações RGB e os dois endpoints de sincronismo aprovados.

## Implementation Brief

### Objetivo

Como extra opcional do PBL03, calcular as raízes reais de F1 e F2 com o contrato exato já aprovado e apresentá-las no VGA com marcadores e valores textuais locais. Raiz inválida/sem domínio real não produz saída visual, sem alterar a validade, os erros ou o estado de exibição da parábola correspondente.

### Requisitos

- Sem requisito oficial do PDF do PBL03 para calcular ou desenhar raízes. Esta TASK implementa somente o extra mantido no planejamento.
- `REQ-005`, `REQ-006` e `REQ-008` descrevem o caminho legado de raízes/arimética estrutural, não definem por si só a política de validade nem a apresentação VGA desta TASK.

### Decisões aplicáveis

- `DEC-007` — arredondar cada raiz ao inteiro mais próximo; empate exato para longe de zero. Preservar nos documentos a divergência em relação ao texto literal de truncamento de `REQ-006`.
- `DEC-031` — arquitetura matemática exata: preservar restos até o arredondamento final; associação de `x1`/`x2` aos ramos algébricos; raízes de saída signed9; não ordenar por magnitude.
- `DEC-044` e `DEC-047` — validade e exibição da parábola são independentes do domínio real das raízes. `Δ<0` deixa a parábola válida quando seus próprios critérios forem satisfeitos; nesse caso não existem marcadores/valores de raízes reais.
- `DEC-051` — sem painel lateral ou gerador de caracteres compartilhado; se rótulos de raiz forem mantidos, a renderização mínima pertence a esta TASK.
- `DEC-056` — contrato de vértices não define marcadores de raízes. A cruz verde, sua prioridade e a ausência de rótulos em DEC-056 não devem ser estendidas implicitamente às raízes.
- `DEC-058` — contrato visual de roots/labels/markers, gating, prioridade, clipping e timing.
- `DEC-059` — exception estreita a DEC-058: acrescentar somente entradas `VERILOG_FILE` para RTL PBL03 usado/auditado e os mesmos paths/categorias no manifesto. Não editar/reordenar linhas existentes ou outros assignments do QSF.
- `DEC-060` — APIs/callers de raiz, processador, renderer e compositor; esta decisão fecha a partição interna adotada abaixo.
- `DEC-057` e evidência final da `TASK-039` — a composição VGA atual passou síntese/fitter e 14 endpoints com slack positivo sob 40 ns; pior slack registrado +1.421 ns. Isso é margem pequena, não orçamento disponível comprovado para lógica adicional. A TASK-040 deve repetir síntese/STA completa e satisfazer os mesmos 14 endpoints sem mudar SDC, QSF, pinagem ou VGA do professor.

### Módulos envolvidos

Topologia e callers conforme DEC-060:

- `quadratic_roots` em `rtl/funcao/quadratic_roots.v`, uma instância por `processador_f1`.
- `processador_f1` em `rtl/funcao/processador_f1.v` acrescenta as saídas de raiz; `rtl/top/top_pbl03.v` já instancia o processador para F1 e F2.
- `renderizador_raizes` em `rtl/video/renderizador_raizes.v`, uma instância do top para as duas funções.
- `compositor_rgb` em `rtl/video/compositor_rgb.v` recebe os dois hits agregados do renderer e faz a prioridade RGB.

#### Auditoria da closure legado

Foram inspecionados `rtl/raizes_quadraticas.v`, `rtl/raiz_quadrada_u17.v`, `rtl/divisor_9_por_8.v`, `rtl/multiplicadores.v`, `rtl/somador_subtrator.v` e `rtl/somador_completo.v`. A varredura dos corpos após remover comentários/strings encontrou somente gates, fios e instanciações estruturais; nenhum token proibido de `docs/regras.md` (`assign`, `always`, `buf`, `if/else`, `begin/end`, laços/geração ou casos) foi encontrado. Isso não autoriza reutilizar os arquivos agregados diretamente: cada um contém múltiplos módulos e a auditoria desta TASK precisa verificar o port final.

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

Contratos numéricos disponíveis para o bloco de cálculo:

- coeficientes `a,b,c`: signed8, em complemento de 2;
- `delta`: signed18;
- `x1,x2`: signed9, saída arredondada conforme DEC-007 e válida somente quando `a≠0` e `delta≥0`;
- domínio aritmético inválido: `a=0` ou `delta<0`; saídas numéricas mascaradas não podem ser interpretadas como raízes válidas.

Interfaces completas conforme DEC-031/060:

- `quadratic_roots`: inputs `a,b,c` signed8; outputs `delta` signed18, `x1,x2` signed9, `domain_error` 1-bit; `domain_error=(a=0)||(delta<0)`; x1/x2 zero no domínio inválido. Fórmulas, resíduos, arredondamento/empate e associação algébrica seguem DEC-031/DEC-007.
- `processador_f1`: acrescentar outputs `root_x1`, `root_x2` signed9 e `root_domain_valid` 1-bit (`!domain_error`), derivados dos mesmos `a1,b1,c1`; sem condicionar ao erro/`display_enable` do vértice.
- `renderizador_raizes`: inputs `video_on`, `processing_done`, `f2_enabled`, `root_domain_valid_f1/f2`, `x_cartesiano/y_cartesiano` signed10, `f1_x1/f1_x2/f2_x1/f2_x2` signed9; outputs `root_marker_hit` e `root_label_hit`, cada um combinando os pixels das duas funções. Gates F1=`processing_done && root_domain_valid_f1`; F2 acrescenta `f2_enabled`.
- `compositor_rgb`: acrescentar inputs 1-bit `root_marker_hit` e `root_label_hit`. Outros ports existentes não mudam. A ordem pixel a pixel é magenta > marker raiz laranja > label raiz laranja > vértice verde > curvas > eixos > fundo; `video_on` mantém blanking preto.
- Top-level externo permanece sem alteração de ports. `top_pbl03` liga as duas instâncias já existentes do processador a uma instância do renderer e conecta os hits no compositor.

Contrato VGA preservado: raízes signed9 já arredondadas, cruz de 5 pixels em `(320+x_root,240)` laranja `(15,8,0)`; labels locais 9 caracteres, fonte bitmap 5×7 com pitch de 6 pixels, formato `F1x1=±ddd` etc., sinal/magnitude derivados do signed9, zero `+000`; linhas VGA 208/216/224/232 centradas horizontalmente no centro da raiz. Raiz repetida: uma cruz e dois labels. Não arredondar novamente nem usar gerador compartilhado.

### Clock e reset

`quadratic_roots` e `renderizador_raizes` são combinacionais, sem clock/reset/FF. `processador_f1` mantém seu clock e reset síncrono `system_reset` existentes para sua FSM; os outputs de raiz são combinacionais dos coeficientes e só aparecem visualmente após o gate `processing_done`.

### Restrições

- Manter todos os módulos aritméticos estruturais conforme `docs/regras.md` e `DEC-031`: sem `assign`, `buf`, `if/else`, laços, `generate`, ou lógica comportamental fora dos módulos dedicados de flip-flop.
- Não adicionar FSM ou pipeline ao caminho VGA sem decisão explícita.
- Preservar integralmente resíduos e exatidão até o arredondamento final; signed10/F1 isolado não substitui o descritor exato da raiz.
- `Δ<0` não pode contaminar validade, erro, handshake, habilitação ou desenho da parábola.
- Não alterar `vendor/vga/vga_sync.v`, ports físicos/top-level, pinagem, SDC, clocks, resolução/escala ou configurações físicas. DEC-059 autoriza exclusivamente novas atribuições de fonte RTL `VERILOG_FILE` e as entradas correspondentes no manifesto.
- Não adicionar painel lateral nem depender de gerador de glifos compartilhado.
- Revalidar timing pós-fit dos 14 endpoints VGA sob 40 ns; os +1.421 ns da TASK-039 são baseline, não folga garantida.

### Arquivos permitidos

#### RTL existente a alterar

- `rtl/funcao/processador_f1.v` — instanciar `quadratic_roots`, expor as três saídas DEC-060.
- `rtl/top/top_pbl03.v` — ligar roots F1/F2, renderer e hits ao compositor sem mudar ports físicos.
- `rtl/video/compositor_rgb.v` — receber os hits e inserir as camadas DEC-058 na prioridade especificada.

#### RTL novo e categoria do manifesto

| Path | Module | Categoria |
|---|---|---|
| `rtl/funcao/quadratic_roots.v` | `quadratic_roots` | `structural` |
| `rtl/funcao/ramo_raizes.v` | `ramo_raizes` | `structural` |
| `rtl/aritmetica/nega_condicional_8.v` | `nega_condicional_8` | `structural` |
| `rtl/aritmetica/nega_condicional_9.v` | `nega_condicional_9` | `structural` |
| `rtl/aritmetica/nega_condicional_10.v` | `nega_condicional_10` | `structural` |
| `rtl/aritmetica/soma_subtrai_10.v` | `soma_subtrai_10` | `structural` |
| `rtl/aritmetica/incrementa_9.v` | `incrementa_9` | `structural` |
| `rtl/aritmetica/raiz_quadrada_17.v` | `raiz_quadrada_17` | `structural` |
| `rtl/aritmetica/etapa_raiz.v` | `etapa_raiz` | `structural` |
| `rtl/aritmetica/divisor_9_por_8.v` | `divisor_9_por_8` | `structural` |
| `rtl/aritmetica/etapa_divisao.v` | `etapa_divisao` | `structural` |
| `rtl/aritmetica/somador_completo_raiz.v` | `somador_completo_raiz` | `structural` |
| `rtl/aritmetica/somador_completo_divisao.v` | `somador_completo_divisao` | `structural` |
| `rtl/aritmetica/multiplica_com_sinal_8_por_8.v` | `multiplica_com_sinal_8_por_8` | `structural` |
| `rtl/aritmetica/subtrator_18.v` | `subtrator_18` | `structural` |
| `rtl/video/renderizador_raizes.v` | `renderizador_raizes` | `structural` |

Adicionar exatamente essas 16 fontes no `quartus/pbl03.qsf`, somente com `set_global_assignment -name VERILOG_FILE`; manter todas as linhas existentes e sua ordem relativa byte a byte. Adicionar os mesmos 16 caminhos em `verification/pbl03_sources.json`, com module/category acima. Fontes legadas agregadas não são permitidas. A regra de um módulo por arquivo deve passar no source checker.

#### Testes/callers e arquivos autorizados

- Root unit novo: `sim/tb_quadratic_roots.v`, `sim/quadratic_roots_vpi.c`, `sim/run_quadratic_roots_icarus.sh`.
- Renderer unit novo: `sim/tb_root_renderer.v`, `sim/root_renderer_vpi.c`, `sim/run_root_renderer_icarus.sh`.
- Adaptar callers existentes de `processador_f1`: `sim/tb_f1_processor.v`, `sim/f1_processor_vpi.c`, `sim/run_f1_processor_icarus.sh`, `sim/tb_f1_f2_processors.v`, `sim/f1_f2_processors_vpi.c`, `sim/run_f1_f2_processors_icarus.sh`.
- Adaptar caller de `compositor_rgb`: `sim/tb_video_axes.v`, `sim/video_axes_icarus_vpi.c`, `sim/run_video_axes_icarus.sh`.
- Full-frame caller: `sim/pbl03_top_verilator.cpp`; manter `sim/run_pbl03_top_verilator.sh` como runner (usa QSF source list).
- Agregação: atualizar `sim/run_pbl03_regression.sh` para invocar explicitamente as duas suítes novas.
- Fonte/config de compilação: `quartus/pbl03.qsf` e `verification/pbl03_sources.json` somente nos limites DEC-059.
- Brief/evidência: `docs/tasks/TASK-040.md`, `verification/results/task-040/`.
- Vetores dirigidos independentes: `tests/vectors/roots_directed.json`.

Não há alteração permitida em `verification/check_pbl03_sources.py`, `quartus/pbl03.sdc`, módulos/ports físicos ou fontes do professor.

### Arquivos protegidos

- `vendor/vga/vga_sync.v` e demais arquivos originais fornecidos pelo professor;
- pinagem, ports físicos, resolução, escala e temporização VGA;
- `quartus/pbl03.sdc` e configuração física do projeto;
- contratos/RTL de validade, processamento e exibição da parábola, exceto conexões aditivas autorizadas pela decisão;
- resíduos do cálculo exato e suas regras de arredondamento.

### Testes executados

1. **Icarus roots:** PASS — 30 vetores dirigidos e 256 casos pseudoaleatórios determinísticos, comparados com referência independente.
2. **Icarus processor propagation:** PASS — F1 em 92 ciclos e propagação F1/F2 em 25 ciclos.
3. **Icarus renderer/compositor:** PASS — 1.538 casos do renderer e 283 casos de prioridade/composição.
4. **Top full-frame:** PASS — referência C++ independente verificou 20.161.162 condições e 11 varreduras completas 800×525; 19.930.445 ciclos de sistema.
5. **Regressão agregada:** PASS — `sim/run_pbl03_regression.sh`; log em `verification/results/task-040/regression.log`.
6. **Source checker:** PASS — `python3 verification/check_pbl03_sources.py`.
7. **Quartus/STA:** compilação PASS, 0 erros e 36 warnings. STA FAIL: 12 RGB endpoints violam 40 ns; VGA_HS e VGA_VS passam. Pior slack VGA_G[0] = −55.101 ns. Evidências: `verification/results/task-040/quartus-compile.log`, `endpoint-slacks.txt` e `vga-paths-full.log`. SDC e demais constraints permaneceram intactos.

### Critérios de aceite

- Aritmética da implementação corresponde aos vetores dirigidos e referência independente que exercita DEC-031/DEC-007.
- Domínio sem raízes reais não altera a elegibilidade nem os pixels da parábola; não há raiz fictícia desenhada.
- Marcadores, rótulos, cores, prioridade, clipping e texto correspondem integralmente a DEC-058.
- As suítes Icarus acima, o frame completo Verilator, o runner agregado e source checker passam.
- Síntese/fitter concluem e os 14 endpoints VGA atendem ao orçamento de 40 ns sem relaxar restrições. **Não atendido:** os 12 endpoints RGB falham STA.
- Auditoria independente aprova sem findings críticos/altos.

### Dependências

- TASK-036 — regressão base aprovada.
- TASK-039 — aprovada com marcador de vértice por predicados racionais; sua STA final registra pior slack +1.421 ns.
- Processadores F1/F2 e contratos da parábola — aprovados.
- DEC-031/058/059/060 em CONSENSUS; DEC-061 OPEN para resolver o STA; TASK-036 e TASK-039 aprovadas.
- A implementação/auditoria deve confirmar que só a closure mapeada acima é necessária; qualquer dependência nova fora do allowlist reabre esta TASK para revisão de contexto/decisão.

### Pendências

1. STA continua bloqueando a aprovação: DEC-061 deve fechar uma solução compatível com o contrato funcional e o limite de 40 ns sem alterar constraints protegidas.
2. Auditor Code Auditor precisa aprovar independentemente a closure estrutural portada e a correspondência QSF/manifesto.

**BLOCKED.** As verificações funcionais e compilação passaram, mas o STA reprovou 12 endpoints RGB. Não declarar a TASK concluída nem tentar workaround de constraints. O desbloqueio exige decisão explícita para resolver o caminho de timing, mantendo DEC-058/059 e os arquivos protegidos.
