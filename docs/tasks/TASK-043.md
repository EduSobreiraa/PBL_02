# TASK-043 | Fechar temporização das saídas RGB VGA

## Objetivo

Analisar e reduzir o atraso do caminho combinacional que produz RGB, mantendo o limite público de 40 ns, equivalência funcional do pixel e as restrições estruturais do projeto.

## Status

APPROVED

## Decisões relacionadas

- DEC-054 (CONSENSUS): manter 40 ns, analisar os 12 bits RGB e fechar/revalidar sem mascarar caminhos.
- DEC-045: estímulo e checagem end-to-end por harness externo.
- DEC-053: HS/VS ativos baixos por inversores estruturais no top, com periférico do professor intacto.

## Dependências

- DEC-054 (CONSENSUS) e resultados da revisão implementada de TASK-042, mesmo com TASK-042 ainda BLOCKED: `verification/results/task-042/vga-paths.txt`, `pbl03.sta.rpt`, `pbl03.fit.rpt` e `top-verilator-active-low.log`.
- Harness público existente `sim/pbl03_top_verilator.cpp` e runner `sim/run_pbl03_top_verilator.sh`; não é necessário esperar a aprovação de TASK-036/042 para executar a otimização e medir.
- Após a nova revisão passar todos os paths de 40 ns, TASK-042 repete e registra sua aceitação integrada; depois TASK-036 reexecuta a regressão base. Essa ordem evita dependência circular.

## Escopo inicial

- Identificar os caminhos críticos desde os registradores de raster até cada saída `VGA_R/G/B` usando os relatórios reais da TASK-042.
- Determinar a lógica RTL estrutural estritamente necessária para melhorar profundidade/atraso sem mudar a função lógica das cores.
- Executar harness externo de quadro completo e repetir Quartus Fitter/TimeQuest após qualquer alteração RTL.
- Medir todos os 12 bits RGB e HS/VS com o limite de 40 ns; registrar atrasos/slacks e violações reais.

## Restrições

- Não relaxar o limite de 40 ns, adicionar exceções de timing para caminhos RGB/HS/VS, nem selecionar resultado de compilação sem alteração de revisão como evidência de fechamento.
- Não alterar `vendor/vga/vga_sync.v`, QSF, pinagem, portas públicas, coordenadas, blanking, reset, contrato matemático ou função das cores.
- Preservar sintaxe estrutural de `docs/regras.md`: sem `assign`, `buf`, FSM, `if`/`else`, loops, `generate` ou `begin`/`end` fora da descrição de flip-flops.
- Não inserir pipeline/registrador que desalinhe pixel, sync, `video_on` ou coordenadas sem uma decisão explícita; preferir primeiro otimização combinacional equivalente.

## Arquivos permitidos

- `rtl/video/coordenadas_cartesianas.v` | transformação dos contadores raster para x/y cartesianos.
- `rtl/video/detector_eixos.v` | hits dos eixos que concorrem na composição RGB.
- `rtl/video/compositor_rgb.v` | prioridade/combinação final das quatro curvas, eixos, blanking e canais RGB.
- `rtl/funcao/avaliador_quadratico_f1.v`, `rtl/funcao/avaliador_derivada_f1.v`, `rtl/funcao/detector_hits_f1.v` | caminhos x→f/f′→comparação de y e hits usados por F1 e pela instância F2.
- `rtl/funcao/datapath_f1.v` e `rtl/funcao/processador_f1.v` | callers intermediários dos avaliadores/hits, modificáveis somente se o relatório detalhado mostrar que o caminho cruza essas fronteiras.
- Primitivas aritméticas diretamente instanciadas no caminho medido, se e somente se a análise detalhada mostrar que são necessárias: `rtl/aritmetica/addsub_18.v`, `addsub_25.v`, `conditional_negate_8.v`, `conditional_negate_10.v`, `conditional_negate_18.v`, `conditional_negate_25.v`, `full_adder_1bit.v`, `multiply_unsigned_8x10.v`, `multiply_unsigned_8x17.v`, `multiply_unsigned_10x10.v` e `signed_less_10.v`.
- `verification/results/task-043/**` | script TimeQuest reproduzível, path reports detalhados e logs/resultados Quartus desta revisão.
- `docs/tasks/TASK-043.md`.

O fluxo lógico é `vga_sync:h_count_reg[8] → coordenadas_cartesianas → avaliadores/detector_hits e detector_eixos → processador_f1/top_pbl03 → compositor_rgb → VGA_R/G/B`. Os reports da TASK-042 identificam `h_count_reg[8]` como startpoint dos 12 endpoints RGB; `VGA_B[0]` e `VGA_B[2]` violam 40 ns. Os reports atuais não mostram as etapas completas do caminho lógico; por isso o primeiro passo deve gerar `report_timing -detail full_path` (ou nível equivalente disponível no Quartus) para cada RGB e confirmar quais módulos/instâncias são atravessados. Alterar somente os módulos permitidos comprovadamente presentes no caminho e que contribuam para atraso.

## Critérios de aceite preliminares

- O harness externo confirma quadro completo, cores, eixos, blanking, prioridade e fase idênticos ao contrato atual.
- Todos os 12 paths RGB e os paths HS/VS requeridos passam o limite de 40 ns sem slack negativo na revisão final; registrar também a margem mínima positiva.
- Fitter e TimeQuest são executados novamente na revisão final, com relatórios separados dos históricos TASK-035/TASK-042.
- Sem alterações no periférico vendorizado, interface, pinagem ou exceções de timing que mascarem paths requeridos.
- Se não for possível fechar por fatoração combinacional compatível, parar e registrar resultado para nova decisão; não falsificar PASS.

## Resultado

Pendente de implementação, simulação, síntese e auditoria. TASK-042 e TASK-036 continuam bloqueadas até a revalidação integrada descrita em DEC-054.

## Implementation Brief

### Objetivo

Otimizar a lógica combinacional estrutural no caminho raster→RGB para obter slack não negativo nos 12 bits de RGB e nos dois sincronismos públicos, mantendo o orçamento de 40 ns, função booleana, contrato de pixel/fase e interface inalterados. A alteração deve incluir uma mudança RTL real no caminho medido; repetir Quartus sem mudança RTL ou selecionar uma execução favorável não fecha esta TASK.

### Requisitos

- PBL03: pixel VGA a 25 MHz, janela de 40 ns.
- REQ-015: estruturas de teste e simulação para validar funcionamento.
- Contrato de cores/eixos/blanking conforme DEC-044, DEC-052, TASK-031, TASK-036 e TASK-042.

### Decisões aplicáveis

- DEC-054 (CONSENSUS): 40 ns preservados; medir todos os 12 RGB; otimizar equivalência estrutural e repetir regressão/Fitter/TimeQuest; não mascarar caminhos.
- DEC-053: HS/VS públicos ativos baixos por inversores no top; manter inversores e o vendor intactos.
- DEC-045: estímulo/checks externos ao Verilog; usar harness C++/Verilator existente.
- DEC-044/052: preservar as quatro curvas, eixos, blanking, prioridades atuais; quinta cor permanece em TASK-037.

### Módulos/callers envolvidos

- Startpoint de todos os 12 endpoints: `vga_sync:raster|h_count_reg[8]` (eixo de raster pertencente a `vendor/vga/vga_sync.v`, somente para leitura/relatório).
- Blocos que compõem o caminho: `coordenadas_cartesianas`, `avaliador_quadratico_f1`, `avaliador_derivada_f1`, `detector_hits_f1`, `processador_f1` (duas instâncias, F1/F2), `detector_eixos` e `compositor_rgb`, com primitivas aritméticas descritas em Arquivos permitidos quando constarem no path detalhado.
- `top_pbl03` é caller protegido: portas e instâncias permanecem sem alteração. Alterações de interfaces, fiação no top ou raster exigem parar e obter uma decisão, pois extrapolam DEC-054.

### Interface

Não modificar nenhuma interface/port pública ou interna. Manter os larguras, nomes e significados de `x_cartesiano[9:0]`, `y_cartesiano[9:0]`, f/f′, sinais hit, flags de eixo, `video_on`, `processing_done`, `VGA_R/G/B[3:0]` e `VGA_HS/VS`. Manter a saída pública HS/VS ativa baixa definida na TASK-042.

### Clock e reset

- Clock de sistema `MAX10_CLK1_50`, 50 MHz. Raster avança a cada enable de pixel a 25 MHz.
- Sem novos registradores, clocks ou resets nesta TASK. Não alterar sync, coordenadas, `video_on`, KEY/reset, nem compensar fase por mudança no harness.

### Restrições

- Preservar aritmética exata, widths e boolean function completa das cores; nenhuma mudança matemática ou arredondamento.
- Modificar apenas arquivos permitidos e somente módulos comprovadamente no caminho crítico segundo path report detalhado.
- RTL continua estrutural segundo `docs/regras.md`: sem `assign`, `buf`, FSM, `if`/`else`, loops, `generate` ou `begin`/`end` fora da descrição de FF.
- Não alterar SDC de 40 ns, remover `set_max_delay`, acrescentar false-path/multicycle ou restringir/otimizar somente os dois bits que violaram. A análise final inclui todos os 14 outputs RGB/HS/VS.
- Não inserir pipeline, FF ou latência sem uma nova decisão e alinhamento formal do raster.
- `vendor/vga/vga_sync.v`, `UPSTREAM.md`, QSF, top ports/pinos, displays/LEDs, entrada/controle e arquivos PBL02 ficam protegidos.
- Relatórios TASK-035 e TASK-042 permanecem históricos; resultados desta revisão ficam separados em `verification/results/task-043/**`.

### Arquivos protegidos

- `rtl/top/top_pbl03.v`; todos `vendor/vga/**`; `quartus/pbl03.qsf`, `quartus/pbl03.sdc`, `quartus/pbl02.*`.
- `sim/pbl03_top_verilator.cpp` e `sim/run_pbl03_top_verilator.sh` são harness base aprovado para execução e estão protegidos contra mudança de expectativa/test behavior nesta TASK.
- RTL fora da lista permissível, decisões, requisitos e resultados anteriores.

### Testes mínimos exigidos

1. Antes da edição, gerar path report detalhado de todos os 12 endpoints `VGA_R/G/B[0..3]` a partir de `all_registers`, preservando também a consulta específica `h_count_reg[8]`; usar TimeQuest do Quartus 25.1std.0 e não inferir os nós intermediários a partir do resumo.
2. Após qualquer RTL editado, executar `python3 verification/check_pbl03_sources.py` e `git diff --check`; garantir conformidade estrutural e QSF inalterado.
3. Executar `sim/run_pbl03_top_verilator.sh` no harness existente para capturar um frame inteiro e comparar RGB pixel a pixel com a referência independente, incluindo HS/VS active-low, 525×800, blanking, eixos, quatro curvas e prioridade. Sem quinta cor.
4. Se algum arquivo `rtl/aritmetica/**` ou avaliador/detector compartilhado for alterado, repetir no mínimo `sim/run_f1_function_icarus.sh`, `sim/run_f1_processor_icarus.sh`, `sim/run_f1_f2_processors_icarus.sh` e `sim/run_video_axes_icarus.sh` para confirmar os contratos de função, derivada, clipping/hits e composição.
5. Reexecutar para a mesma revisão `quartus_map --read_settings_files=on --write_settings_files=off pbl03`, `quartus_fit --read_settings_files=on --write_settings_files=off pbl03` e `quartus_sta pbl03`.
6. Gerar relatório focado com cada um dos 12 RGB e `VGA_HS`/`VGA_VS`, `-detail full_path` (ou equivalente), `-npaths 1` por endpoint, e budget de 40 ns. Registrar para cada endpoint: startpoint, endpoint, atraso, slack, cenário PVT e caminho detalhado.

### Critérios de aceite executáveis

- O report demonstra as 12 saídas RGB e ambas as saídas sync constrangidas a 40 ns, sem slack negativo; registrar também o mínimo slack positivo entre os 14 endpoints.
- Quartus A&S/Fitter/TimeQuest executam com 0 erros na mesma revisão que passou simulação; mensagens/avisos relevantes e restrição aplicada estão arquivados.
- O frame inteiro passa sem alteração de cores/posições/fase/blanking, comparado à referência externa; HS/VS ativo baixo permanece correto.
- Há mudança RTL estrutural equivalente no caminho confirmado; não foi usada compilação repetida sem mudança para selecionar slack favorável.
- Todos os relatórios finais, script de medição, hash/revisão do código, versões e logs estão sob `verification/results/task-043/**`; nada sobrepõe TASK-035/042.
- Se não houver fatoração equivalente que alcance o timing, ou a correção exigir mudança de pipeline/porta/SDC fora do escopo, parar, registrar medições e enviar ao Decision Workflow; não marcar PASS.

### Dependências

- DEC-054 está `CONSENSUS`.
- Os artefatos de TASK-042 presentes em `verification/results/task-042/` são baseline disponível mesmo enquanto TASK-042 está BLOCKED. Não há dependência de aprovação de TASK-036 ou TASK-042 para realizar a análise e otimização.
- Após resultado positivo, TASK-042 repete/fecha seus critérios de aceitação com os novos outputs e TASK-036 é desbloqueada para regressão base final.

### Pendências

- Os relatórios de timing atuais não incluem o detalhamento completo por célula do caminho entre o registrador raster e cada pino RGB. Isso é a primeira atividade da própria TASK, não pendência externa: obter path detail antes de escolher o RTL a fatorar. O objetivo/escopo e a lista de candidatos estão definidos.
- Não há decisão pendente para as mudanças combinacionais equivalentes descritas; se o relatório revelar necessidade de alterar interfaces, pipeline ou SDC, bloquear e abrir decisão.

### Resultado do Context Analyst

**READY_FOR_IMPLEMENTATION.** DEC-054 define o limite, função a preservar, escopo em todos os canais e gates. A evidência da TASK-042 identifica início e endpoints, enquanto a análise detalhada dentro desta TASK determina quais módulos da cadeia permitida realmente precisam mudar. As alterações são restritas à lógica combinacional do caminho, com chamadas top e interfaces imutáveis. O harness de frame completo é existente e reutilizável. Nenhuma simulação foi executada nesta análise.

### Implementação e evidências

Arquivos RTL alterados:

- `rtl/aritmetica/multiply_unsigned_10x10.v`
- `rtl/aritmetica/multiply_unsigned_8x17.v`

Os dois multiplicadores mantêm as mesmas portas e o produto exato. A acumulação serial das linhas parciais foi substituída por árvores balanceadas estruturais de `addsub_20`/`addsub_25`, reduzindo a cadeia para quatro níveis no 10×10 e cinco no 8×17.

Validações realizadas em 2026-11-18:

- `python3 verification/check_pbl03_sources.py`: PASS; `git diff --check`: PASS.
- Icarus/VPI v14.0 devel, container `hdlc/iverilog:latest`: PASS — F1 datapath (3.421 casos), F1 processor (92 ciclos), F1/F2 processors (25 ciclos), video axes/composition (265 casos) e elaboração do top.
- Verilator 5.053 devel, container `hdlc/verilator:latest`: PASS — quadro completo e cenários top, 1.680.469 checks e 1.661.568 ciclos do clock. Sincronismos ativos baixos, blanking, cores, curvas, eixos e fase preservados.
- Quartus Prime Lite 25.1std.0 Build 1129: A&S PASS (0 erros, 31 avisos), Fitter PASS (0 erros, 3 avisos), TimeQuest PASS (0 erros, 0 avisos). O relatório registra que a revisão global ainda não está totalmente constrained para setup/hold.
- `full-paths-final.log` registra os 12 RGB e HS/VS constrangidos a 40 ns, sem violações. Slack RGB (R/G/B, bits 0–3): R = 2.138/2.127/2.112/2.133 ns; G = 2.446/2.833/2.494/2.484 ns; B = 2.555/2.538/2.685/2.626 ns. HS = 30.907 ns; VS = 30.742 ns. Pior slack positivo: 2.112 ns em `VGA_R[2]`.
- `full-paths-baseline.log` confirma o caminho raster→coordenadas→multiplicadores 10×10 e 8×17→comparação/compositor. O report final contém paths completos de todos os 14 endpoints.
- O SHA-256 de `vendor/vga/vga_sync.v` permanece `6f2e841c45f14888aeb6d8cc58e79ec7e7ca5dafddae7c32ef160381daacccc8`, igual a `UPSTREAM.md`.
- Evidências estão em `verification/results/task-043/`, incluindo o script TimeQuest, reports completos, logs de regressões e versões/fingerprints.

### Resultado do Implementer

**IMPLEMENTED.** A alteração estrutural passou nos gates funcionais e o timing focado tem slack positivo nos 14 outputs. TASK-042 deve repetir seus gates integrados e registrar a evidência final antes da auditoria de aceite; TASK-036 continua dependendo da aprovação final de TASK-042. Não houve validação física.

### Auditoria independente

**APPROVED.**

- Compliance Gate: os dois multiplicadores usam somente lógica estrutural e os somadores autorizados; interfaces preservadas; sem `assign`, `buf`, `always`, FSM, loops ou blocos comportamentais. Não foram encontrados arquivos alterados fora do escopo da TASK-043 além das alterações já registradas separadamente para TASK-042/documentação.
- Functional Gate: cada linha parcial é uma parcela não negativa do produto unsigned. As árvores somam as mesmas 10 parcelas deslocadas no módulo 10×10 e 17 parcelas no 8×17. O produto máximo (2¹⁰−1)² cabe em 20 bits e (2⁸−1)(2¹⁷−1) cabe em 25 bits; portanto os intermediários e saídas preservam carry sem truncamento. Regressões Icarus, frame Verilator e síntese passaram.
- Timing Gate: os 12 endpoints RGB e HS/VS têm exceção máxima de 40 ns no relatório final; nenhum slack é negativo. Menor slack positivo: 2.112 ns em `VGA_R[2]`. A STA global ainda informa que setup/hold não estão totalmente constrained; essa limitação permanece explícita.
- Integration Gate: harness, top, SDC, QSF, interfaces e VGA vendorizado permaneceram protegidos/invariantes para esta TASK. Após a TASK-043, a TASK-042 foi revalidada e aprovada; a TASK-036 foi executada e aprovada em seguida.
- Findings HIGH/CRITICAL: nenhum.

Não houve validação em placa/monitor físico.
