# TASK-035 | Fechar QSF, SDC e síntese PBL03

## Objetivo

Configurar o projeto Quartus PBL03 para a DE10-Lite, incluir as fontes finais e obter relatórios reais de síntese, recursos e temporização.

## Status

APPROVED

## Dependências

- TASK-025-032 e TASK-034 | portas e fontes PBL03 estabilizadas.
- Manual oficial e pinagem da revisão de placa utilizada.

## Planejamento e aceite

- Declarar clock, reset, switches, keys, LEDs, displays e VGA no QSF.
- Criar restrições temporais para o clock de sistema e raster VGA com orçamento coerente com a frequência de pixel.
- Não copiar o orçamento de saídas humanas do SDC PBL02 para o caminho de vídeo.
- Executar Analysis & Synthesis, fitting e análise de timing disponíveis.
- Registrar versão do Quartus, revisão do projeto, mensagens, uso de recursos e slack real.
- Abrir decisão antes de mudar arquitetura caso o caminho de pixels não cumpra o período.

## Arquivos

Definir a lista permitida na análise de contexto. Incluir QSF, SDC PBL03 e documentação de evidência Quartus.

## Resultado

Pendente. Não há implementação nem evidência nesta TASK.

## Implementation Brief

### Objetivo

Finalizar a configuração de compilação da revisão `pbl03` para a DE10-Lite, atribuir todos os ports físicos do `top_pbl03`, aplicar restrições temporais coerentes com o clock de sistema e com o período VGA documentado e executar a compilação Quartus até obter relatórios reais de fitting e timing.

### Requisitos

- Requisitos de interface e exibição definidos pelo PBL03 para clock, controles, LEDs, HEX e VGA.
- Os ports atuais do top-level são a interface física congelada desta tarefa.

### Decisões aplicáveis

- DEC-044: cálculo direto a partir das coordenadas VGA; medir o caminho até a seleção da cor; manter `vga_sync.v` intacto.
- DEC-049: `system_reset` síncrono da lógica principal e rota física separada para o reset assíncrono ativo alto do VGA.
- DEC-050: sinais de BUSY/DONE/erro expostos em LEDR e HEX conforme implementação existente.
- DEC-051: sem painel lateral textual no VGA.
- DEC-008/011/018/019: clock, polaridades, pinagem oficial da placa e interface de entrada conforme `docs/hardware.md`.

### Módulos envolvidos

- `top_pbl03` e toda a lista de fontes já declarada em `quartus/pbl03.qsf`.
- Periférico VGA externo `vendor/vga/vga_sync.v`, somente como fonte imutável.

### Interface física e pin assignments

Fonte da pinagem e dos padrões elétricos: `DE10_Lite_User_Manual.pdf`, revisão Terasic de 24/01/2017, tabelas 3-2 a 3-11. Todos os sinais abaixo são 3.3-V LVTTL, exceto os dois KEY, especificados como 3.3-V Schmitt Trigger. HEX usa segmentos ativos baixos; KEY é ativo baixo.

| Port do top | Pinos FPGA, na ordem do índice | Padrão / semântica |
|---|---|---|
| `MAX10_CLK1_50` | P11 | 3.3-V LVTTL; clock 50 MHz |
| `KEY[0]`, `KEY[1]` | B8, A7 | 3.3-V Schmitt Trigger; botões ativos baixos |
| `SW[0..8]` | C10, C11, D12, C12, A12, B12, A13, A14, B14 | 3.3-V LVTTL |
| `LEDR[0..9]` | A8, A9, A10, B10, D13, C13, E14, D14, A11, B11 | 3.3-V LVTTL |
| `HEX0[0..6]` | C14, E15, C15, C16, E16, D17, C17 | 3.3-V LVTTL, active-low |
| `HEX1[0..6]` | C18, D18, E18, B16, A17, A18, B17 | 3.3-V LVTTL, active-low |
| `HEX2[0..6]` | B20, A20, B19, A21, B21, C22, B22 | 3.3-V LVTTL, active-low |
| `HEX3[0..6]` | F21, E22, E21, C19, C20, D19, E17 | 3.3-V LVTTL, active-low |
| `HEX4[0..6]` | F18, E20, E19, J18, H19, F19, F20 | 3.3-V LVTTL, active-low |
| `HEX5[0..6]` | J20, K20, L18, N18, M20, N19, N20 | 3.3-V LVTTL, active-low |
| `VGA_R[0..3]` | AA1, V1, Y2, Y1 | 3.3-V LVTTL |
| `VGA_G[0..3]` | W1, T2, R2, R1 | 3.3-V LVTTL |
| `VGA_B[0..3]` | P1, T1, P4, N2 | 3.3-V LVTTL |
| `VGA_HS`, `VGA_VS` | N3, N1 | 3.3-V LVTTL |

The mapping is complete for every current top-level port. The HEX port order `[0..6]` is the manual's `[a,b,c,d,e,f,g]`; decimal-point pins are not top-level ports and must not be assigned. `SW[8]` is the physical SW8 at B14; no SW9 port exists.

### Clock e reset

- Primary clock: `MAX10_CLK1_50`, rising edge, 50 MHz, period 20.000 ns.
- The VGA manual specifies 640×480 at 60 Hz with 25 MHz pixel frequency, period 40 ns; horizontal timing is 96/48/640/16 pixel cycles and vertical timing is 2/33/480/10 lines (sync/back porch/display/front porch).
- `vga_sync` uses `MAX10_CLK1_50` and generates a 25 MHz pixel enable internally. `p_tick` is internal to the top-level and is not a top port or a separate clock domain; do not create an unconstrained/fictitious external clock port or modify the vendor module.
- SDC policy: constrain the 50 MHz primary clock, derive clock uncertainty, preserve the existing false paths only for asynchronous KEY inputs into their first synchronizer stages, and set a 40.000 ns maximum data-path delay from synchronous register sources to the RGB output ports. This is the 25 MHz raster's per-pixel budget; do not use the PBL02 1 ms human-output budget on RGB. Do not relax timing paths with broad false paths or multicycle exceptions.
- Board reset remains `KEY[1]` inverted into the VGA's asynchronous active-high reset as in the current top. The logic's synchronous `system_reset` behavior remains unchanged.

### Restrições

- Não alterar RTL, testbenches, interface top-level, fonte listada, nem qualquer arquivo em `vendor/vga/`.
- Preservar `vga_sync.v` byte a byte; sua origem e hash estão em `vendor/vga/UPSTREAM.md`.
- Não alterar `quartus/pbl02.qsf` nem `quartus/pbl02.sdc`.
- Não introduzir FSM, lógica de datapath, nem mudanças arquiteturais nesta tarefa.
- Não alegar adequação de frequência sem relatório real do Quartus.

### Arquivos permitidos

- `quartus/pbl03.qsf`
- `quartus/pbl03.sdc` (criar)
- `docs/tasks/TASK-035.md` (registrar comandos e evidências)
- `verification/results/quartus/pbl03/**` (artefatos e resumo dos relatórios reais, se suportado pelo repositório)

### Arquivos protegidos

- Todo `rtl/**` e `sim/**`.
- Todo `vendor/vga/**`.
- `quartus/pbl02.qsf`, `quartus/pbl02.sdc` e fontes legadas.
- Decisões, requisitos e pinagem já aprovada.

### Testes exigidos

- Validar que cada port físico tem exatamente um location assignment e padrão de I/O compatível com o manual.
- Validar a lista de fontes com `python3 verification/check_pbl03_sources.py`.
- Executar Analysis & Synthesis, Fitter e TimeQuest da revisão `pbl03` no Quartus Prime Lite 25.1std.0 Build 1129 (10/21/2025 SC Lite Edition).
- Guardar versões, comandos, mensagens de erro/aviso relevantes, uso de recursos e slack real, identificando caminho crítico e restrição que o limita.
- Não criar teste simulado que substitua o resultado de síntese ou timing.

### Casos de borda

- Verificar no relatório que os bits de vetores foram expandidos para os pinos corretos, em especial `SW[8]`, `HEX[0..6]` e cada canal VGA.
- Verificar que os KEY têm padrão elétrico Schmitt Trigger e polaridade lógica segue ativa baixa.
- Confirmar que as saídas RGB recebem a restrição de 40 ns e que a restrição não mascara o caminho de dados por false path/multicycle.
- Se timing do caminho de pixel falhar, registrar o slack e abrir uma decisão arquitetural antes de alterar pipeline, frequência ou comportamento.

### Critérios de aceite

- QSF atribui todos os ports atuais conforme a tabela e seleciona 3.3-V LVTTL/Schmitt Trigger conforme indicado.
- SDC contém clock de 20 ns e orçamento de 40 ns para os caminhos de dados que chegam ao RGB, além das exceções estreitas para KEY documentadas.
- A compilação real termina com relatórios de Analysis & Synthesis, fitting e timing; nenhum resultado esperado ou inventado.
- Revisão, versão Quartus, mensagens, recursos e slack estão registrados nesta TASK, com evidência apontável.
- `vga_sync.v` permanece idêntico à revisão indicada em `UPSTREAM.md`.

### Dependências

- Ports estabilizados por TASK-025–032 e TASK-034.
- Pinagem oficial da DE10-Lite e timing VGA obtidos no manual local.
- `vendor/vga/UPSTREAM.md` para preservar a revisão do periférico.

### Pendências

- Nenhuma informação de pinagem ou frequência necessária para escrever QSF/SDC está pendente.
- A aceitação de temporização e utilização de recursos continua pendente da execução real do Quartus nesta TASK.

### Resultado do Context Analyst

**READY_FOR_IMPLEMENTATION.** A pinagem de todos os ports é verificável no manual local. O manual também estabelece o período VGA de 40 ns, e DEC-044 exige medir o caminho de pixel direto; o brief define esse valor como limite de atraso de dados até RGB. O Quartus está disponível localmente como Prime Lite 25.1std.0. Não alterei QSF, SDC, RTL nem fontes vendor durante a análise.


## Resultado da implementação

- `quartus/pbl03.qsf` preserva a lista aprovada de 41 fontes e atribui os 78 bits/ports físicos atuais (contagem de 78 locations e 78 IO standards). `SW[8]` está em B14; HEX usa índices `[0..6]`; VGA R/G/B e HS/VS seguem a tabela do brief. Nenhum pino DP foi incluído.
- O nome QSF que Quartus 25.1 aceita para KEY é `3.3 V Schmitt Trigger` (com espaços, sem hífen). O nome transcrito inicialmente do manual como `3.3-V Schmitt Trigger` e a variante `3.3-V Schmitt Trigger Input` geraram Error (169216); a forma aceita foi confirmada no Fitter e é consistente com a Tabela 3-3 do manual.
- `quartus/pbl03.sdc` define MAX10_CLK1_50 em 20.000 ns, deriva incerteza, limita cada caminho síncrono de registrador até RGB a 40.000 ns e exclui KEY0/KEY1 somente até os primeiros estágios já existentes (`dff_sync_bit:key0_sync_first` e `dff_bit:key1_sync_first`). A hierarquia foi conferida no relatório de mapeamento; TimeQuest não reportou filtro SDC ignorado.
- `vendor/vga/vga_sync.v` permaneceu byte a byte idêntico: SHA-256 `6f2e841c45f14888aeb6d8cc58e79ec7e7ca5dafddae7c32ef160381daacccc8`.

### Evidências e ferramentas

Quartus Prime Lite 25.1std.0 Build 1129 (10/21/2025 SC Lite Edition), projeto/revisão `pbl03`, dispositivo `10M50DAF484C7G`.

| Comando | Resultado observado |
|---|---|
| `python3 verification/check_pbl03_sources.py` | PASS |
| `quartus_map --read_settings_files=on --write_settings_files=off pbl03` | Sucesso; 0 erros, 31 avisos; 3.279 logic elements, 94 registradores, 78 pinos (12 entradas e 66 saídas). |
| `quartus_fit --read_settings_files=on --write_settings_files=off pbl03` | Sucesso; 0 erros, 3 avisos; 3.243 logic elements (7%), 94 registradores e 78/360 pinos. |
| `quartus_sta pbl03` | Sucesso; 0 erros, 0 avisos do processo STA; clock 20 ns carregado, incerteza derivada. |
| Relatório explícito `report_timing -from [all_registers] -to [get_ports {VGA_R[*] VGA_G[*] VGA_B[*]}]` | Todos os canais receberam exceção máxima de 40.000 ns; pior caminho RGB medido separadamente por bit: `vga_sync:raster|h_count_reg[8]` → `VGA_B[0]`, data delay 35.414 ns, slack 0.962 ns, sem violação. |

Os slacks globais do TimeQuest foram 0.618 ns setup e 0.342 ns hold no modelo slow 1200mV/85C; 2.207 ns setup e 0.306 ns hold no modelo slow 1200mV/0C; e 11.871 ns setup e 0.148 ns hold no modelo fast 1200mV/0C. O pior caminho global de setup pertence ao clock; o pior caminho de pixel acima é avaliado contra a exceção RGB de 40 ns.

O relatório informa que o design não está totalmente constrangido para setup/hold, pois os switches não têm input delay e as saídas não RGB não têm restrição externa; isso permanece coerente com o brief (sem atraso externo fictício e com foco explícito no orçamento de pixel). A evidência não equivale a validação física da placa.

Avisos relevantes registrados nos relatórios: A&S reporta truncamentos inteiros nas linhas 74 e 78 de `vga_sync.v` (fonte vendorizada preservada) e saídas LED/HEX constantes conforme o RTL atual; o relatório de mapeamento também registra `Warning (10236)` para a net implícita `inside_y` em `rtl/funcao/validador_vertice_f1.v:38`. O Code Auditor confirmou que a net está conectada e é usada; esse aviso não invalida compilação, fitting ou timing. O RTL protegido está fora do escopo da TASK-035 e não foi alterado. Fitter indica 12 pinos sujeitos aos requisitos de interface da nota Intel AN 447 e algumas atribuições de I/O incompletas. Não ocorreram colisões de pinos. Esses avisos não impediram fitting.

Relatórios reais preservados em `verification/results/quartus/pbl03/`: `pbl03.map.summary`, `pbl03.fit.summary`, `pbl03.sta.rpt`, `rgb_max_delay_path.txt` e `rgb_paths.txt`.

## Pendências

- Timing externo completo de todos os ports e teste na placa permanecem fora do que os relatórios atuais demonstram.

## Auditoria independente

- Resultado: **APPROVED** após correção do FIND-035-001 (LOW), que solicitava registrar o warning 10236 de `inside_y`.
- Compliance: QSF/SDC dentro do escopo; lista de fontes e módulo VGA preservados; sem colisões de pinos.
- Evidência: `python3 verification/check_pbl03_sources.py` passou; `git diff --check` passou; `rgb_paths.txt` confirma os 12 bits RGB, com pior caminho `VGA_B[0]` em 35.414 ns e slack de 0.962 ns.
- Limites: os resultados não demonstram validação física na placa nem restrições externas completas para todos os ports.
