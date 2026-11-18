# TASK-030 | Integrar a FSM principal e o handshake de processamento

## Objetivo

Coordenar entrada, START, processadores, BUSY, DONE e reset no top-level PBL03.

## Status

APPROVED | auditoria independente aprovou Compliance, Functional e Integration sem findings.

## Dependências

- TASK-026 | entrada com seis coeficientes e pulso de START.
- TASK-028 e TASK-029 | conclusões dos processadores.
- Diagrama e tabela de transições principal aprovados como contrato.

## Planejamento e aceite

- Implementar estados de revisão, disparo, espera e exibição conforme os contratos vigentes.
- Substituir qualquer `processing_done` constante por conclusão real dos processadores.
- Preservar DONE até novo início ou reset; manter BUSY durante validação.
- Tratar F2 desabilitada como concluída sem erro.
- Provar sequência completa, reset em estados relevantes e nova execução com coeficientes retidos.

## Arquivos

Ver lista completa no Implementation Brief.

## Implementation Brief

### Objetivo

Adicionar a FSM principal de quatro estados e integrá-la ao top PBL03 para consolidar a conclusão de F1 e F2, fornecer BUSY/DONE internos e alimentar `entrada_pbl03.processing_done`. Preservar os contratos das FSMs de entrada e dos processadores.

### Requisitos

- PDF PBL03 §§4.4, 4.9–13 e 5.3: controle por FSM, preparação/validação, sinalização de conclusão, reset e estruturas de teste.
- `REGRAS.md` §§2, 3.11–15, 4, 10 e 11.1: captura e reexecução, reset, FSM principal e sintaxe permitida.

### Decisões aplicáveis

- DEC-044: START como pulso, BUSY durante preparação/validação, DONE retido, reexecução com coeficientes retidos e conclusão sem erro de F2 nula.
- DEC-045: wrapper Verilog estrutural e estímulo/verificação externos via VPI.
- DEC-046: clock de 50 MHz e reset lógico síncrono ativo alto derivado da KEY1 sincronizada.
- DEC-048: FSMs dos processadores, DONE retido e handshake baixo→alto observado pela FSM de entrada.
- DEC-049: estados, transições, saídas e interface da FSM principal.

### Módulos envolvidos

- Novo `rtl/controle/fsm_principal_pbl03.v`, módulo `fsm_principal_pbl03`.
- `rtl/top/top_pbl03.v`: separar `done_f1` de `processing_done`; ligar `done_f1`, `done_f2`, `input_ready`, `start_pulse` e `system_reset` à nova FSM; ligar a saída `done` dela a `entrada_pbl03.processing_done`. BUSY e DONE permanecem fios internos do top.
- `entrada_pbl03`, `processador_f1` e respectivas FSMs: instanciar e conectar sem modificar portas ou lógica.

### Interface da FSM principal

| Sinal | Direção | Largura | Semântica |
|---|---|---:|---|
| `clk` | entrada | 1 | `MAX10_CLK1_50`, amostrado na borda de subida. |
| `system_reset` | entrada | 1 | Reset síncrono ativo alto, prioridade em todos os estados. |
| `input_ready` | entrada | 1 | Alto após os seis coeficientes terem sido capturados; mantido pela FSM de entrada até reset. |
| `start_pulse` | entrada | 1 | Pulso da FSM de entrada; consumido na borda seguinte simultaneamente pela FSM principal e pelos dois processadores. |
| `done_f1`, `done_f2` | entrada | 1 cada | DONE retido das duas instâncias de `processador_f1`. A conclusão requer ambos em alto. |
| `busy` | saída | 1 | Alto somente em `WAIT_PROCESSORS`. |
| `done` | saída | 1 | Alto somente em `DISPLAY`; alimenta `entrada_pbl03.processing_done` e habilita a exibição global internamente. |

### Estados e comportamento

| Estado | Transição | `busy` | `done` |
|---|---|---:|---:|
| `WAIT_INPUT` | Reset entra aqui; `input_ready=1` leva a `REVIEW`. | 0 | 0 |
| `REVIEW` | `start_pulse=1` leva a `WAIT_PROCESSORS`. | 0 | 0 |
| `WAIT_PROCESSORS` | `done_f1 && done_f2` leva a `DISPLAY`. | 1 | 0 |
| `DISPLAY` | `start_pulse=1` inicia outra validação e leva a `WAIT_PROCESSORS`. | 0 | 1 |

Em qualquer estado, `system_reset=1` retorna a `WAIT_INPUT`, com BUSY/DONE baixos. A FSM principal não captura coeficientes nem gera START. Durante nova execução, os coeficientes permanecem retidos; a saída DONE cai ao consumir o novo pulso e volta a subir somente após ambos os processadores concluírem. F2 nula deve concluir normalmente por sua FSM já existente.

### Clock e reset

- Todas as FSMs usam `MAX10_CLK1_50`, borda de subida.
- A nova FSM usa apenas `system_reset` síncrono ativo alto.
- Preservar a conexão física atual de KEY1 ao reset assíncrono do VGA, sem alterar o periférico.

### Restrições

- Verilog comportamental somente no módulo de FSM; usar lógica estrutural no top e nos wrappers.
- Sem `assign`, `buf`, `generate`, laços, `initial` ou blocos `always` fora dos módulos autorizados de FSM/FF.
- Um módulo por arquivo `.v`; nenhuma alteração nas interfaces públicas existentes.
- Não alterar `vendor/vga/vga_sync.v`, pin assignments, SDC ou RTL do PBL02.
- Sem composição RGB/LEDs nesta tarefa; BUSY/DONE ficam internos.

### Arquivos permitidos

- `docs/tasks/TASK-030.md`.
- `rtl/controle/fsm_principal_pbl03.v` (novo).
- `rtl/top/top_pbl03.v`.
- `quartus/pbl03.qsf` (adicionar a fonte da nova FSM, sem outras mudanças).
- `sim/tb_main_handshake_pbl03.v` (novo wrapper estrutural).
- `sim/main_handshake_pbl03_vpi.c` e `sim/run_main_handshake_pbl03_icarus.sh` (novos estímulos/verificação e runner externo).
- `sim/run_f1_f2_processors_icarus.sh` (adicionar a nova fonte à lista usada para elaborar top).
- `sim/run_f1_processor_icarus.sh` (adicionar somente a nova fonte à elaboração de `top_pbl03`, preservando a regressão da TASK-028).

### Arquivos protegidos

- `rtl/entrada/entrada_pbl03.v`, `rtl/entrada/fsm_entrada.v`, `rtl/funcao/processador_f1.v`, `rtl/funcao/fsm_funcao_f1.v` e os datapaths já aprovados.
- `vendor/vga/vga_sync.v`, pin assignments e SDC de `quartus/pbl03.qsf`.
- Todos os arquivos do PBL02 e os runners/regressões existentes, exceto a inclusão da nova fonte no runner explicitamente permitido.

### Testes exigidos

- Usar wrapper estrutural e VPI externo, conforme DEC-045. O runner novo deve simular a integração de entrada, FSM principal e processadores, e também elaborar `top_pbl03` com a lista completa de fontes do QSF.
- Cobrir reset inicial/operação antes da captura, captura completa e estado de revisão, pulso START, BUSY durante validação, espera por ambos os DONEs e DONE retido em DISPLAY.
- Cobrir F2 toda nula chegando a DONE sem erro nem BUSY preso.
- Cobrir nova execução após DONE sem recapturar os coeficientes, observando queda e nova retenção de DONE.
- Cobrir reset em revisão, validação e exibição, confirmando retorno à entrada e limpeza de BUSY/DONE.
- Reexecutar os runners das TASK-026 a TASK-029 e `git diff --check`. Os runners TASK-028 e TASK-029 elaboram `top_pbl03` com listas explícitas de fontes, então ambos precisam incluir a nova FSM nessa etapa de elaboração.

### Casos de borda

- START ocorre como pulso registrado pela entrada e é consumido pela FSM principal e processadores na borda seguinte, sem estado de despacho adicional.
- `DISPLAY` mantém DONE alto até novo START aceito ou reset.
- A transição para `DISPLAY` exige `done_f1 && done_f2`; um único DONE não conclui a operação.
- A FSM principal deve aguardar `input_ready` após reset antes de aceitar início.

### Critérios de aceite

- A tabela DEC-049 está implementada sem mudanças de estado, polaridade, retenção ou responsabilidades.
- `entrada_pbl03.processing_done` recebe DONE da FSM principal, nunca DONE individual de F1.
- BUSY e DONE internos refletem os estados definidos e F2 nula não bloqueia conclusão.
- A sequência completa, reset em estados definidos e reexecução com coeficientes retidos passam na simulação.
- O top elabora com todas as fontes QSF e nenhuma interface protegida ou pin assignment muda.
- Auditoria independente aprova Compliance, Functional e Integration.

### Dependências

- TASK-026, TASK-028 e TASK-029 aprovadas.
- Contrato principal em DEC-049/`REGRAS.md` §11.1.
- Verificação externa VPI definida em DEC-045; Icarus disponível em `/tmp/task028-iverilog/usr` nesta sessão.

### Pendências

- Nenhuma pendência de arquitetura impede a implementação. Síntese, timing, fitting e validação física continuam fora desta TASK.

## Resultado

A FSM principal implementa `WAIT_INPUT`, `REVIEW`, `WAIT_PROCESSORS` e `DISPLAY` conforme DEC-049. O top expõe DONE individual de F1 em `done_f1` e usa o DONE consolidado em `processing_done`. `processing_busy` fica ativo enquanto a principal aguarda ambas as conclusões.

### Arquivos modificados

- `rtl/controle/fsm_principal_pbl03.v`: FSM dedicada com dois bits de estado e BUSY/DONE decodificados do estado.
- `rtl/top/top_pbl03.v`: instância da FSM e conexão da conclusão consolidada à entrada.
- `quartus/pbl03.qsf`: apenas a fonte da nova FSM.
- `sim/tb_main_handshake_pbl03.v`: wrapper estrutural do top real e uma instância isolada da FSM para testar DONEs independentes.
- `sim/main_handshake_pbl03_vpi.c` e `sim/run_main_handshake_pbl03_icarus.sh`: controle externo da simulação e elaboração com as fontes extraídas do QSF atual.
- `sim/run_f1_processor_icarus.sh` e `sim/run_f1_f2_processors_icarus.sh`: fonte da nova FSM adicionada somente à elaboração do top.
- `docs/tasks/TASK-030.md`: resultados e evidências.

### Testes executados

Todos os comandos usaram `IVERILOG_ROOT=/tmp/task028-iverilog/usr` no worktree de implementação.

| Comando | Resultado |
|---|---|
| `sim/run_main_handshake_pbl03_icarus.sh` | PASS, 250 ciclos e elaboração de `top_pbl03` com as fontes QSF atuais. |
| `sim/run_f1_f2_processors_icarus.sh` | PASS, 25 ciclos F1/F2 e elaboração do top. |
| `sim/run_f1_processor_icarus.sh` | PASS, 92 ciclos F1 e elaboração do top. |
| `sim/run_coefficient_input_pbl03.sh` | PASS, 187 passos da entrada. |
| `sim/run_f1_function_icarus.sh` | PASS, 3421 casos do datapath. |
| `git diff --check` | PASS. |

Depois da cópia aprovada para a workspace compartilhada, repeti os cinco runners nela. Os resultados foram iguais. `cmp` confirmou que os nove arquivos correspondem ao worktree auditado, e a checagem de whitespace não encontrou espaços finais.

A simulação nova verifica captura dos seis coeficientes por KEY0 físico, revisão sem START, pulso START, BUSY de preparação/validação, DONE retido, F2 nula sem erros, nova execução com coeficientes retidos e reset sincronizado em revisão, validação e exibição. A instância isolada verifica START antes da entrada pronta, espera por apenas um DONE em cada ordem, START ignorado durante espera e prioridade de reset.

### Limitações e inspeção

Não houve warning nos comandos executados. A comparação de bytes com a workspace de origem confirmou que os RTL protegidos, o periférico VGA e os testes existentes permaneceram iguais, exceto pelos arquivos permitidos. O QSF difere apenas pela linha da nova fonte. Não foram executados Quartus, síntese, timing, fitting ou validação física.

## Histórico

- 16/11/2026 | Context Analyst identificou dependência arquitetural pendente; TASK marcada `BLOCKED` até consenso em DEC-049.
- 16/11/2026 | Após DEC-049 atingir CONSENSUS e atualizar `REGRAS.md` §11.1, Context Analyst concluiu o Implementation Brief; TASK liberada para implementação.

- 16/11/2026 | Code Implementer concluiu FSM e integração no worktree exclusivo; runner novo de 250 ciclos, regressões 026–029 e elaboração do top passaram. Status `IMPLEMENTED`.
- 16/11/2026 | Code Auditor aprovou Compliance, Functional e Integration sem findings. Reexecutou os cinco runners, comparou fontes protegidas byte a byte com a workspace original e confirmou que o QSF só ganhou a nova fonte.

## Resultado da revisão

**APPROVED.** Compliance, Functional e Integration passaram. Não há findings.

- A FSM usa os quatro estados de DEC-049. BUSY fica alto em `WAIT_PROCESSORS`; DONE fica alto em `DISPLAY`. A conclusão exige `done_f1 && done_f2`, e `processing_done` recebe apenas DONE consolidado.
- A entrada e os dois processadores compartilham START/reset sem alteração de suas interfaces. F2 nula termina sem erro. A integração verifica captura por KEY, reexecução com coeficientes retidos e reset em revisão, validação e exibição.
- A FSM e os demais fontes Verilog adicionados respeitam a restrição estrutural/comportamental: blocos comportamentais aparecem somente no módulo FSM; não há `assign`, `buf`, laços ou módulos Verilog múltiplos por arquivo.
- As fontes protegidas da entrada, processadores, datapaths, primitivos e `vendor/vga/vga_sync.v` coincidem byte a byte com a workspace original. O QSF difere somente pela inclusão de `fsm_principal_pbl03.v`.
- O top elaborou com a lista atual do QSF. Os cinco runners passaram: 250 ciclos de handshake, 25 ciclos F1/F2, 92 ciclos F1, 187 passos de entrada e 3421 casos de datapath. `git diff --cached --check` passou.

Não foram executados Quartus, síntese, fitting, análise de timing ou validação física.
