# TASK-032 | Mostrar status e erros nos LEDs e displays

## Objetivo

Exibir BUSY, DONE, ERR_F1, ERR_F2 e mensagens de erro nos dispositivos físicos definidos para o PBL03.

## Status

APPROVED | auditoria independente aprovada após os gates de compliance, funcional e integração.

## Dependências

- TASK-030 | sinais de controle e erros reais disponíveis.
- Prioridade e mapeamento lógico documentados em DEC-050.
- Pinagem oficial da DE10-Lite identificada na análise de contexto.

## Planejamento e aceite

- Mapear LEDs para os estados e erros sem reutilizar sinalizações do PBL02 por suposição.
- Exibir função e tipo de erro nos displays de sete segmentos.
- Verificar polaridade ativa baixa dos segmentos e todas as mensagens.
- Testar erros simultâneos conforme a prioridade aprovada e limpar tudo no reset.

## Arquivos

Ver a allowlist no Implementation Brief.

## Resultado

O top expõe LEDR e HEX0 a HEX5 e conecta BUSY/DONE reais da FSM principal e os quatro flags de erro retidos. Os erros F2 chegam já mascarados pela convenção da tripla nula. O seletor estrutural usa a prioridade DEC-050, sem ocultar os LEDs independentes de erro.

### Arquivos modificados

- `rtl/display/decodificador_glifo_7seg_pbl03.v`: decoder estrutural de três bits. Códigos 0 e 7 apagam o display; 1=E, 2=r, 3=F, 4=u, 5=1 e 6=2. Cada saída é ativa baixa.
- `rtl/display/display_status_pbl03.v`: prioridade dos flags, seis glifos e indicadores LEDR.
- `rtl/top/top_pbl03.v`: portas LEDR/HEX e ligação ao módulo de status.
- `quartus/pbl03.qsf`: somente as duas fontes RTL novas.
- `sim/tb_status_errors_pbl03.v`, `sim/status_errors_pbl03_vpi.c` e `sim/run_status_errors_pbl03_icarus.sh`: wrapper estrutural, checagem externa de status e elaboração com as fontes extraídas do QSF.
- `sim/run_f1_processor_icarus.sh` e `sim/run_f1_f2_processors_icarus.sh`: somente as duas fontes adicionadas às listas de elaboração do top.
- `docs/tasks/TASK-032.md`: resultados da implementação.

### Testes executados

Com `IVERILOG_ROOT=/tmp/task028-iverilog/usr` no worktree `/tmp/task032-worktree`:

| Comando | Resultado |
|---|---|
| `sim/run_status_errors_pbl03_icarus.sh` | PASS, 64 combinações de status, todos os 8 códigos de glifo e 791 ciclos totais com o top real; top elaborado com fontes QSF. |
| `sim/run_f1_processor_icarus.sh` | PASS, 92 ciclos e elaboração do top. |
| `sim/run_f1_f2_processors_icarus.sh` | PASS, 25 ciclos e elaboração do top. |
| `sim/run_main_handshake_pbl03_icarus.sh` | PASS, 250 ciclos e elaboração do top. |
| `sim/run_video_axes_icarus.sh` | PASS, 265 casos e elaboração do top. |
| `git diff --cached --check` | PASS. |

Após copiar os arquivos auditados para a workspace compartilhada, repeti o runner da TASK-032 e as regressões 028–031. Todos passaram novamente. `cmp` confirmou que os nove arquivos de código, simulação e configuração correspondem ao worktree auditado, e a checagem de whitespace passou.

Os 64 padrões isolados cobrem todos os quatro flags de erro, DONE e BUSY. O driver compara os segmentos externos com a tabela de glifos do brief e rejeita valores desconhecidos. O top é exercitado por KEY/SW nas 12 combinações de F1 válida, `a1=0` ou vértice externo com F2 nula, válida, `a2=0` ou vértice externo. Também verifica reset, mensagem retida e reexecução com coeficientes retidos. A reexecução apaga a mensagem durante BUSY, e flags retidos antes do DONE global ainda deixam os HEX em branco.

### Inspeções e limitações

As quatro fontes Verilog adicionadas/alteradas são estruturais, com um módulo por arquivo e sem `assign`, `buf`, `generate`, `for`, `always` ou `initial`. A auditoria comparou os arquivos protegidos byte a byte, incluindo VGA, FSMs, processadores, compositor e testes existentes; não encontrou alterações. QSF e runners explícitos diferem somente pelas duas fontes novas. Não houve warnings nos comandos de compilação/simulação. Não foram executados Quartus, síntese, timing, fitting ou validação física; pin assignments permanecem na TASK-035.

## Histórico

- 16/11/2026 | Context Analyst confirmou que a prioridade entre mensagens simultâneas permanece pendente em `REGRAS.md` §11.1; TASK marcada `BLOCKED`. A baseline de pinos e polaridade foi localizada em `docs/hardware.md`/DEC-018, com assignments QSF ainda separados na TASK-035.
- 16/11/2026 | DEC-050 atingiu CONSENSUS e `REGRAS.md` §7/§11 foi atualizado. Context Analyst completou o brief; pin assignments continuam fora da TASK-032.
- 16/11/2026 | Iniciada implementação isolada dos glifos, status e integração do top.
- 16/11/2026 | Code Implementer concluiu RTL estrutural, integração e runner de 791 ciclos; regressões 028–031 passaram. TASK marcada `IMPLEMENTED` para auditoria independente.

## Implementation Brief

### Objetivo

Adicionar indicadores de status e mensagens de erro ao top PBL03. Mostrar BUSY, DONE, ERR_F1 e ERR_F2 em LEDR e os códigos de erro aprovados nos seis displays de sete segmentos.

### Requisitos

- PDF PBL03 §§4.10–12 e 4.15: identificar função/tipo de erro, permitir que a função válida continue visível e indicar BUSY, DONE e erros nos LEDs.
- `REGRAS.md` §§2, 3.11–15, 7.4–7.7 e 10: captura/reset, LEDs e mensagens, sintaxe estrutural e verificação.

### Decisões aplicáveis

- DEC-018: baseline oficial de pinagem e polaridades da DE10-Lite; atribuição física do QSF continua na TASK-035.
- DEC-044/049: erros independentes e sinais BUSY/DONE da FSM principal/processadores.
- DEC-050: prioridade `ERR F1` > `ERR V1` > `ERR F2` > `ERR V2`, HEX em branco antes de DONE, mapeamento LEDR0–3 e portas lógicas do top.

### Módulos envolvidos

- Novo `display_status_pbl03` em `rtl/display/display_status_pbl03.v`: combinar BUSY/DONE, flags de erro, prioridade textual e saídas físicas lógicas.
- Novo `decodificador_glifo_7seg_pbl03` em `rtl/display/decodificador_glifo_7seg_pbl03.v`: converter um código de glifo em sete segmentos ativos baixos.
- `top_pbl03`: expor `LEDR[9:0]`, `HEX0`…`HEX5` e conectar os sinais existentes ao módulo de status.
- Wrapper VPI estrutural e driver externo: testar as mensagens, prioridades, status e integração do top.

### Interface

`top_pbl03` conserva os ports existentes e adiciona:

| Sinal | Direção | Largura | Semântica |
|---|---|---:|---|
| `LEDR` | saída | 10 | `LEDR[0]=BUSY`, `[1]=DONE`, `[2]=ERR_F1`, `[3]=ERR_F2`, `[9:4]=0`; ativo alto. |
| `HEX0`…`HEX5` | saída | 7 cada | Displays HEX0 a HEX5; bit 0 corresponde a `a` e bit 6 a `g`; ativo baixo. |

O módulo `display_status_pbl03` recebe BUSY, DONE e os quatro flags retidos `error_a_zero_f1`, `error_vertex_f1`, `error_a_zero_f2` e `error_vertex_f2`. O top passa os flags F2 já mascarados por `f2_enabled`. `ERR_F1` e `ERR_F2` são os OR dos dois erros da respectiva função.

### Seleção das mensagens e glifos

Aplicar a prioridade DEC-050 somente quando DONE estiver alto. Mostrar uma mensagem de cada vez. HEX5 a HEX0, da esquerda para a direita, representam `E`, `r`, `r`, espaço, `F` ou `u`, e `1` ou `2`. O `r` minúsculo aproxima R; `u` aproxima V. Sem erro ou com DONE baixo, apagar todos os segmentos.

Usar códigos internos de glifo em uma tabela local. Os segmentos abaixo indicam os LEDs acesos na ordem `[a,b,c,d,e,f,g]`; o driver físico deve emitir nível baixo para cada segmento aceso:

| Glifo | Segmentos acesos |
|---|---|
| espaço | nenhum |
| E | a, d, e, f, g |
| r | e, g |
| F | a, e, f, g |
| u (V aproximado) | c, d, e |
| 1 | b, c |
| 2 | a, b, d, e, g |

Se vários erros ocorrerem, o HEX seleciona o primeiro na ordem `ERR F1`, `ERR V1`, `ERR F2`, `ERR V2`. Os LEDs ERR permanecem independentes e podem acender juntos.

### Clock e reset

O display e os LEDs são lógica combinacional e não recebem clock/reset. Os flags vêm das FSMs existentes: DONE oculta mensagens durante validação/reexecução, e KEY1 sincronizada limpa flags, LEDR e HEX pela lógica já integrada. Não alterar FSMs ou interfaces dos processadores.

### Restrições

- Implementar display, decoder, top e wrapper de forma estrutural.
- Sem `assign`, `buf`, `generate`, `for`, `always` ou `initial` nesses módulos.
- Um módulo por arquivo `.v`; não alterar a polaridade física dos HEX nem a semântica dos erros.
- QSF pode receber somente as fontes RTL novas. Não adicionar pin assignments, alterar SDC ou modificar `vendor/vga/vga_sync.v`.
- Não reutilizar a codificação de status do PBL02. O módulo decimal antigo não implementa as mensagens alfanuméricas necessárias.

### Arquivos permitidos

- `docs/tasks/TASK-032.md`.
- `rtl/display/decodificador_glifo_7seg_pbl03.v` (novo).
- `rtl/display/display_status_pbl03.v` (novo).
- `rtl/top/top_pbl03.v`.
- `quartus/pbl03.qsf` (adicionar somente os dois novos arquivos RTL, sem pinos).
- `sim/tb_status_errors_pbl03.v`, `sim/status_errors_pbl03_vpi.c` e `sim/run_status_errors_pbl03_icarus.sh` (novos).
- `sim/run_f1_processor_icarus.sh` e `sim/run_f1_f2_processors_icarus.sh` (adicionar somente as duas novas fontes às listas de elaboração do top).

### Arquivos protegidos

- FSMs, processadores, datapaths, entrada, detectores de coordenadas/hits, compositor e primitivos existentes.
- `vendor/vga/vga_sync.v`, pin assignments/SDC e RTL do PBL02.
- `sim/run_main_handshake_pbl03_icarus.sh` e `sim/run_video_axes_icarus.sh`, que extraem fontes do QSF; `sim/tb_main_handshake_pbl03.v` e `sim/tb_video_axes.v`, cujas instâncias nomeadas podem deixar as novas saídas desconectadas.
- Demais runners e VPI existentes, exceto as duas listas explícitas autorizadas acima.

### Testes exigidos

- Runner novo com wrapper estrutural e estímulos/checagens VPI externos. Testar cada uma das quatro mensagens, LEDR, blank, segmentos ativos baixos e todos os padrões de erro simultâneos para validar a prioridade.
- Verificar DONE baixo apaga HEX mesmo com flags presentes; DONE alto mantém a mensagem prioritária; ausência de erros deixa HEX apagado; reset limpa mensagens/LEDs; reexecução mantém HEX apagado enquanto BUSY.
- Exercitar o status module com todas as 16 combinações dos quatro flags, DONE em 0/1 e BUSY em 0/1. Verificar as combinações realizáveis também pelo top real via entrada KEY/SW.
- Elaborar `top_pbl03` com todas as fontes extraídas do QSF atual e executar as regressões TASK-028–031. As runners TASK-028/029 precisam incluir os novos arquivos nas suas listas explícitas.
- Checar sintaxe/whitespace, contagem de módulos e fonte VGA protegida. Não alegar síntese nem validação de placa.

### Casos de borda

- F2 desabilitada: ERR_F2 e mensagem F2 baixos; a mensagem de F1 permanece correta.
- Erros em ambas as funções: os dois LEDs ERR acendem; o HEX segue a prioridade aprovada.
- `error_a_zero` e `error_vertex` simultâneos da mesma função: `a=0` tem prioridade conforme DEC-050.
- LEDR[9:4] permanece zero em todos os estados.
- DONE baixo, reset e ausência de erros mantêm os HEX apagados.

### Critérios de aceite

- Mapeamento LEDR e prioridade/message positions correspondem a DEC-050.
- Todos os padrões de glifos respeitam a polaridade ativa baixa e passam na tabela VPI.
- BUSY/DONE e erros chegam das fontes reais do top sem alterar os processadores.
- Top elabora com QSF e as runners explícitas atualizadas; regressões TASK-028–031 passam.
- QSF não ganha pin assignments; VGA, datapaths e interface física existente permanecem íntegros.
- Auditor independente aprova conformidade, função e integração.

### Dependências

- TASK-030 APPROVED; sinais principais e erros de F1/F2 integrados.
- DEC-050 CONSENSUS; mapping, prioridade e HEX ports definidos.
- Pinagem/polaridade em `docs/hardware.md` e DEC-018. A atribuição de pinos permanece na TASK-035.

### Pendências

Nenhuma decisão pendente bloqueia a implementação. Os padrões de glifos acima são aproximações em sete segmentos. Não há validação física nem pin assignments nesta tarefa.

## Auditoria independente

**Resultado: APPROVED.** Os gates de compliance, funcional e integração passaram, sem findings.

- **Compliance:** os quatro arquivos Verilog da entrega têm um módulo por arquivo e não contêm `assign`, `buf`, `generate`, `for`, `always` ou `initial`. A allowlist corresponde aos arquivos da tarefa. `quartus/pbl03.qsf` não contém pin assignments, atribuições IO_STANDARD ou SDC; comparado à origem, difere somente pelas duas linhas dos novos módulos de display. `git diff --cached --check` passou.
- **Funcional:** `IVERILOG_ROOT=/tmp/task028-iverilog/usr sim/run_status_errors_pbl03_icarus.sh` passou: 64 combinações de BUSY/DONE/flags, 8 códigos de glifo, 791 ciclos de status/top, incluindo reset, mensagens retidas, prioridade e flags independentes. Os padrões ativos baixos conferem com a tabela do brief.
- **Integração:** os runners `run_f1_processor_icarus.sh`, `run_f1_f2_processors_icarus.sh`, `run_main_handshake_pbl03_icarus.sh` e `run_video_axes_icarus.sh` passaram com o mesmo `IVERILOG_ROOT`; todos elaboraram o top com as fontes do QSF. A tripla nula de F2 mantém ERR_F2 apagado; os casos F2 inválidos e válidos mantêm os flags independentes de F1. 68 arquivos protegidos RTL, VGA, PBL02 e simulação foram comparados byte a byte com a origem e estavam idênticos.
- **Limite da evidência:** não foram executados Quartus, síntese, timing, fitting ou validação física; isso permanece fora do aceite desta tarefa.

Auditoria registrada em 16/11/2026.
