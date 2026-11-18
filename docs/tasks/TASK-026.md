# TASK-026 | Capturar os seis coeficientes em magnitude e sinal

## Objetivo

Adaptar a entrada existente para capturar `a₁`, `b₁`, `c₁`, `a₂`, `b₂` e `c₂`, usando `SW[7:0]` como magnitude e `SW[8]` como sinal, validando a faixa antes de armazenar em complemento de 2 signed8.

## Status

APPROVED | handshake revisado independentemente; VPI passou 187 ciclos, incluindo DONE retido alto durante a aceitação de START e eventos bloqueados durante processamento. Analysis & Synthesis Quartus passou com 0 erros e 13 warnings; sem alegações de timing, fit ou teste físico.

## Requisitos relacionados

- PBL03 PDF §4.1-4.
- `REGRAS.md` §3.

## Decisões relacionadas

- DEC-044 | interface signed-magnitude, faixa −128…127, normalização de −0, KEY0/KEY1 e ordem de captura.
- DEC-046 | estratégia de sincronização e qualificação de KEY0/KEY1 no PBL03 (CONSENSUS).

## Dependências

- TASK-025 define a nova hierarquia e o escopo de arquivos PBL03.
- A semântica de KEY0/KEY1 segue DEC-044 e DEC-046. Interfaces e conexões do top/QSF estão fechadas no Implementation Brief.

## Restrições aplicáveis

- Manter o PBL02 intacto; criar ou adaptar módulos somente na árvore RTL do PBL03.
- Capturar apenas com evento válido de KEY0 e não avançar após entrada fora da faixa.
- Valores positivos aceitos: magnitude 0…127. Valores negativos aceitos: magnitude 0…128. Normalizar sinal negativo com magnitude zero.
- Armazenar os seis valores como complemento de 2 signed8, incluindo −128.
- `KEY1` limpa os seis registradores e reinicia o progresso completo.
- Sincronizar ambos os KEY em dois estágios no clock de 50 MHz; não usá-los como clocks. O evento KEY0 é um pulso de um ciclo na transição sincronizada liberado→pressionado.
- O reset da lógica de entrada é síncrono e ativo alto, derivado de KEY1 sincronizado; manter a rota física invertida existente de KEY1 para o reset assíncrono ativo alto do VGA.
- Exigir acionamento de KEY1 após energizar antes de iniciar a carga, sem presumir estado de power-on dos sincronizadores. KEY0 fica liberado durante o reset.
- O usuário define `SW[8:0]` antes de pressionar KEY0 e o mantém estável até a borda de clock em que o registrador captura o coeficiente.
- Depois de c₂, um evento separado de KEY0 inicia; após DONE, novo KEY0 permite nova validação com coeficientes retidos.
- FSM em módulo dedicado; conversão, comparação e validação permanecem estruturais.
- Um módulo por arquivo; sem `assign`, `generate`, `for` ou `buf` fora das exceções de `REGRAS.md`.

## Arquivos permitidos

- Novos módulos PBL03 em `rtl/entrada/` e primitivas necessárias em `rtl/primitivos/`.
- Novas conexões de entrada no top-level em `rtl/top/top_pbl03.v`.
- `quartus/pbl03.qsf` para incluir os novos módulos PBL03.
- `sim/tb_coefficient_input_pbl03.v`
- `sim/coefficient_input_pbl03_vpi.c`
- `sim/run_coefficient_input_pbl03.sh`
- `docs/tasks/TASK-026.md`

## Arquivos protegidos

- `rtl/entrada_coeficientes.v` e demais arquivos PBL02 na raiz de `rtl/`.
- Todos os arquivos `quartus/pbl02.*`, `testbench/` e decisões aprovadas.
- `vendor/vga/vga_sync.v` e arquivos não listados como permitidos.

## Implementation Brief

### Interface e integração

- Criar `rtl/entrada/entrada_pbl03.v` como wrapper da captura. Portas: `clk`, `key_n[1:0]` (KEY[0] e KEY[1], ativos baixos), `sw[8:0]`, `processing_done`; saídas `a1`, `b1`, `c1`, `a2`, `b2`, `c2` (`signed [7:0]`), `start_pulse` e `input_ready`. Todos os sinais lógicos de controle são ativos altos e síncronos a `clk`.
- O wrapper contém a sincronização e a FSM de entrada e instancia conversor, validador e banco. Interfaces internas podem ser escolhidas pelo implementador, preservando os comportamentos e a separação dos módulos abaixo.
- Criar um arquivo por módulo: `rtl/entrada/sincronizador_keys.v` (duas cadeias de dois DFFs; KEY1 sem reset próprio; estágios/histórico de KEY0 preparados como liberados durante reset), `detector_evento_key0.v` (pulso de um ciclo na transição sincronizada liberado→pressionado), `conversor_sinal_magnitude.v` (SW para signed8 em complemento de 2; −0→0), `validador_entrada.v` (aceitação de magnitude conforme sinal), `fsm_entrada.v` (ordem, captura, START e handshake DONE baixo→alto antes de rearmar) e `banco_coeficientes.v` (seis registradores signed8, reset síncrono e seleção de escrita). Pode-se criar primitivas DFF em `rtl/primitivos/`, também um módulo por arquivo. Não alterar nem instanciar código PBL02 da raiz `rtl/`.
- Na FSM, captura e avanço acontecem na mesma borda somente se ocorrer `key0_event` no estado de coeficiente e `sw` for válido. Evento inválido mantém estado e registradores. O próximo evento após c₂ pulsa `start_pulse`; enquanto o processamento não indicar conclusão, eventos adicionais são ignorados. `processing_done` habilita a espera de nova validação com os coeficientes retidos; o próximo evento gera novo `start_pulse`. `input_ready` indica que c₂ foi capturado e a FSM aguarda START ou está no ciclo de execução/revisão.
- Integrar no `top_pbl03.v`, mantendo a rota atual `not(KEY[1])` para o reset assíncrono ativo alto de `vga_sync`. Adicionar `input [8:0] SW`; instanciar `entrada_pbl03` e ligar `MAX10_CLK1_50`, `KEY`, `SW`. Nesta fatia `processing_done` fica inativo até a integração do processador em uma TASK posterior; coeficientes e `start_pulse` ficam em fios internos para conexão posterior. Não adicionar pin assignments. Atualizar `quartus/pbl03.qsf` somente para listar novos fontes PBL03 e primitivos necessários; manter `vga_sync.v` e suas portas intactos e não incluir fontes PBL02.
- Criar `sim/tb_coefficient_input_pbl03.v`, `sim/coefficient_input_pbl03_vpi.c` e `sim/run_coefficient_input_pbl03.sh`, seguindo o padrão estrutural/verificação externa aprovado em DEC-045 e o runner da TASK-025. VPI conduz relógio, KEY, SW e `processing_done`; verifica saídas dos coeficientes e `start_pulse`. Não colocar estímulos, comparações ou lógica comportamental de testbench no Verilog.

### Sequência temporal e testes exigidos

- A simulação dirige valores iniciais explicitamente, sem inferir estado de power-on. Aplicar KEY1 pressionada por pelo menos três bordas para atravessar os dois estágios do sincronizador; manter KEY0 liberada durante todo reset; soltar KEY1 e aguardar sua propagação antes da primeira entrada. Reset lógico é síncrono; a rota física de KEY1 ao VGA permanece assíncrona.
- Para cada tentativa, definir `SW[8:0]` antes de pressionar KEY0 e mantê-lo estável até e através da borda em que o banco captura. Soltar KEY0 e aguardar a propagação antes de novo acionamento. Manter KEY0 pressionada por várias bordas deve produzir apenas um evento/captura; uma captura adicional só pode ocorrer após liberar e pressionar novamente.
- Exercitar reset com KEY0 liberada e confirmar que os seis registradores e o progresso foram limpos. Cobrir explicitamente KEY0 permanecendo liberada durante o reset e nenhum evento espúrio após sua liberação. Não usar KEY0 pressionada através do reset como protocolo válido.
- Cobrir entradas válidas `+127` (`SW=9'h07f`), `−128` (`9'h180`), `−0` (`9'h100` armazenado como zero), e inválidas `+128` (`9'h080`) e `−129` (`9'h181`). Após cada entrada inválida, o coeficiente corrente deve continuar sendo o próximo destino; confirmar isso armazenando em seguida um valor válido e checando os seis registradores na ordem.
- Capturar a₁,b₁,c₁,a₂,b₂,c₂ e confirmar valores/ordem. Verificar que completar c₂ não inicia por si só, que um evento separado pulsa START por um ciclo, que eventos enquanto `processing_done=0` não rearmam, e que após `processing_done=1` um novo evento pulsa START sem alterar coeficientes; DONE alto retido não rearma até a FSM observar primeiro seu nível baixo e depois uma nova conclusão alta.
- Cobrir F2 nula (a₂=b₂=c₂=0) e F2 inválida por a₂=0 com b₂ ou c₂ não nulo: neste módulo ambas são entradas capturáveis sem erro de faixa; verificar os valores armazenados exatamente para que o processador posterior distinga conjunto nulo de função inválida. A classificação do erro de função pertence ao processador, não a esta TASK.
- O script deve falhar com status diferente de zero em divergência; registrar checks PASS/FAIL explícitos. Executar o runner Icarus/VPI, inspeção estrutural de sintaxe/proibições, integração QSF/top e `git diff --check`. Quartus Analysis & Synthesis pode ser executado se disponível, mas não é critério de bloqueio desta TASK; não afirmar teste físico.

## Plano

1. Implementar interfaces e módulos descritos no Implementation Brief.
2. Reutilizar somente primitivas aprovadas após revisar a implementação e a compatibilidade com `REGRAS.md`.
3. Implementar conversão signed-magnitude e validação da faixa.
4. Implementar a sequência de captura dos seis valores, retenção após c₂ e início em novo evento KEY0.
5. Verificar KEY1, entrada inválida, limites e F2 nula versus F2 inválida.

## Critérios de aceite

- A captura segue a ordem exata a₁→b₁→c₁→a₂→b₂→c₂.
- `+127` e `−128` são aceitos; `+128` e `−129` são rejeitados sem avanço.
- `−0` é armazenado como zero.
- As combinações de coeficientes da F2 nula e da F2 com a₂=0 e outro coeficiente não nulo são capturadas fielmente; a classificação de habilitação/erro fica para o processador de função.
- KEY0 confirma um único valor por evento; depois de c₂, um novo evento inicia; após DONE, outro evento reinicia validação com coeficientes retidos; KEY1 limpa a sessão.
- Os valores retidos têm representação signed8 complemento de 2.
- O RTL PBL02 permanece inalterado.

## Testes

- Invólucro Verilog estrutural e driver externo Icarus/VPI para a sequência completa, conforme DEC-045.
- Cobrir evento único enquanto KEY0 permanece pressionado, nova captura após liberar e pressionar, reset KEY1 com sincronização em dois estágios, KEY0 liberado durante reset, SW estável até a captura, limites, valores inválidos, −0, F2 desabilitada e F2 inválida.
- Exigir KEY1 após energizar no cenário operacional; a simulação deve inicializar estímulos explicitamente sem afirmar estado inicial físico dos sincronizadores.
- Inspeção estrutural, integração dos callers PBL03 e `git diff --check`.

## Resultado da implementação

Criado caminho de entrada PBL03 separado do PBL02. A FSM controla seis capturas ordenadas, START posterior a c₂, espera de `processing_done` e novo START com coeficientes retidos. KEY0/KEY1 passam por dois estágios; a lógica interna usa reset síncrono de KEY1 sincronizada e o VGA mantém sua rota física assíncrona preexistente. Conversão signed-magnitude e validação de faixa são estruturais; seis bancos signed8 têm reset síncrono.

### Arquivos alterados/criados

- `rtl/primitivos/dff_bit.v`
- `rtl/primitivos/dff_sync_bit.v`
- `rtl/primitivos/dff_sync8.v`
- `rtl/entrada/sincronizador_keys.v`
- `rtl/entrada/detector_evento_key0.v`
- `rtl/entrada/conversor_sinal_magnitude.v`
- `rtl/entrada/validador_entrada.v`
- `rtl/entrada/fsm_entrada.v`
- `rtl/entrada/banco_coeficientes.v`
- `rtl/entrada/entrada_pbl03.v`
- `rtl/top/top_pbl03.v`
- `quartus/pbl03.qsf`
- `sim/tb_coefficient_input_pbl03.v`
- `sim/coefficient_input_pbl03_vpi.c`
- `sim/run_coefficient_input_pbl03.sh`
- `docs/tasks/TASK-026.md`

### Testes e resultados

- `sim/run_coefficient_input_pbl03.sh` | PASS, 187 ciclos de simulação VPI; todos os checks passaram.
- `iverilog -g2005 -s top_pbl03 -o /tmp/pbl03-task026.vvp` com todos os arquivos RTL PBL03 e o periférico listado no QSF | PASS, elaboração completa do top.
- Verificação negativa VPI: expectativa de `a1` temporariamente alterada de 127 para 126; runner exibiu `VPI FAIL` e retornou exit status 1. O vetor foi restaurado e a execução final passou.
- `git diff --check` | sem problemas reportados.
- Busca `rg -n '\b(assign|generate|for|buf|always|initial)\b' rtl/entrada rtl/primitivos rtl/top/top_pbl03.v sim/tb_coefficient_input_pbl03.v` | as ocorrências são somente `always` dentro das primitivas DFF e da FSM dedicada, permitidas pelas regras. Os módulos combinacionais e wrapper não contêm construtos comportamentais proibidos.
- `sha256sum vendor/vga/vga_sync.v` | `6f2e841c45f14888aeb6d8cc58e79ec7e7ca5dafddae7c32ef160381daacccc8`, inalterado.
- Sem pin assignments adicionados. Sem alterações em fontes PBL02 ou `quartus/pbl02.*`.

### Vetores VPI aprovados

- Reset inicial sincronizado, KEY0 liberado durante reset e ausência de evento espúrio após soltar KEY1.
- `+128` e `−129` rejeitados sem avanço; em seguida `+127` e `−128` capturados nos destinos corretos.
- `−0` normalizado para zero; captura completa a₁→b₁→c₁→a₂→b₂→c₂.
- KEY0 mantido não repete captura; liberação permite novo evento.
- c₂ não inicia processamento. Um evento separado gera START de um ciclo.
- Eventos durante BUSY são ignorados. Após DONE alto, o próximo START é aceito mesmo mantendo DONE alto; eventos subsequentes não geram START até a FSM observar DONE baixo e uma conclusão alta posterior. Coeficientes permanecem retidos.
- KEY1 limpa seis registradores e progresso. F2 toda zero e F2 com a₂=0,b₂=1,c₂=0 são armazenadas fielmente.

## Resultado das ferramentas

A simulação estrutural Icarus/VPI passou em todos os 187 ciclos. A elaboração do `top_pbl03` também passou. `quartus_map pbl03 --read_settings_files=on --write_settings_files=off` concluiu Analysis & Synthesis com 0 erros e 13 warnings. Dois warnings são truncamentos de parâmetros inteiros na fonte externa imutável `vga_sync.v`; os demais indicam entradas KEY/SW sem dependência de saída nesta fatia, pois processadores e displays ainda não consomem os coeficientes. A síntese não mede timing nem comprova fit ou operação na placa.

## Resultado da revisão

**APPROVED | auditoria independente, ciclo 2.** A correção de `FIND-026-001` resolve o rearm prematuro, e o teste atualizado cobre a retenção de DONE através da aceitação do novo pulso START. Não encontrei findings abertos.

### Evidência da correção

O handshake da FSM agora separa `WAIT_DONE_LOW` e `WAIT_DONE_HIGH`. Ao aceitar START, a FSM espera o processador retirar `processing_done`; só então passa a aguardar a próxima conclusão. Isso impede que o DONE antigo, retido alto, reabra a espera antes da aceitação do novo pulso.

A VPI mantém `processing_done=1` através da aceitação do START seguinte, aplica KEY0 enquanto esse DONE antigo continua alto e confirma que START não repete. Em seguida dirige DONE baixo, verifica que KEY0 ainda é ignorado durante processamento, e só após uma nova subida de DONE confirma rearmamento e novo START.

- **Compliance | PASS:** o controle está na FSM dedicada; demais módulos da equipe permanecem estruturais e DFFs estão em primitivas dedicadas. A revisão de escopo não encontrou alterações em arquivos legados PBL02; QSF inclui apenas as fontes PBL03 e o periférico registrado, sem pin assignments.
- **Functional | PASS:** executei `sim/run_coefficient_input_pbl03.sh`; os 187 passos passaram. A cobertura inclui limites e inválidos, −0, sequência, captura única, reset, retenção de coeficientes, pulso START, DONE retido alto durante aceitação, evento KEY0 ignorado nesse estado, DONE baixo observado e conclusão posterior antes do rearm.
- **Integration | PASS:** top/QSF conectam a entrada sem alterar VGA ou PBL02. A interface do wrapper e larguras conferem; KEY1 mantém as rotas síncrona interna e assíncrona VGA. A compilação/elaboração do top e a evidência Quartus estão registradas abaixo.

### Finding histórico

`FIND-026-001` HIGH foi corrigido: `WAIT_DONE` foi dividido em `WAIT_DONE_LOW` e `WAIT_DONE_HIGH`. A FSM não considera a conclusão anterior um rearmamento: depois de START, ela observa a desativação de `processing_done` pela nova aceitação e espera a próxima ativação antes de voltar a `WAIT_START`.

### Evidências e limites

- Reexecutei `sim/run_coefficient_input_pbl03.sh`: saída final `VPI PASS: all 187 coefficient-input steps passed`.
- O caso de handshake dirige `processing_done=1` através do evento START e da borda em que o processador o aceita, tenta novo evento KEY0 enquanto o DONE antigo permanece alto, depois aplica nível baixo e só então uma nova conclusão alta. Os checks confirmam ausência de START indevido e rearm apenas após a sequência baixo→alto.
- A expectativa restaurada de `a1=+127` permanece no driver VPI; a execução normal passa. `git diff --check` não reportou problemas.
- A inspeção estrutural encontrou `always` somente nas primitivas DFF e na FSM dedicada. O hash de `vendor/vga/vga_sync.v` confere com o registro em `vendor/vga/UPSTREAM.md`: `6f2e841c45f14888aeb6d8cc58e79ec7e7ca5dafddae7c32ef160381daacccc8`.
- O relatório Quartus registra Analysis & Synthesis bem-sucedido: 0 erros e 13 warnings. Dois são truncamentos de parâmetros no periférico VGA imutável; 10 entradas KEY0/SW não chegam a uma saída porque coeficientes e START ainda não estão conectados aos módulos de processamento/apresentação futuros, mais o warning agregado de entradas sem uso. A síntese otimiza esses caminhos no top atual; isso não valida timing, fit, recursos finais nem placa.

### Saída relevante

```text
VPI PASS: new START accepted while old processing_done remains high
VPI PASS: KEY0 event ignored while stale processing_done remains high
VPI PASS: processing_done low is observed before next completion
VPI PASS: KEY0 event ignored during rearmed processing
VPI PASS: new completion rearms start wait after low-to-high handshake
VPI PASS: later START rearmed after processing_done deassertion and assertion
VPI PASS: all 187 coefficient-input steps passed
```

## Pendências

- A classificação do caso `a₂=0` com outro coeficiente não nulo pertence ao processador de função em tarefa posterior.

## Histórico

- 15/11/2026 | TASK criada como PLANNED; aguarda a definição da captura confiável dos botões.
- 15/11/2026 | aberta DEC-046 para decidir sincronização/qualificação compatível com a captura PBL03 e o reset VGA assíncrono.
- 15/11/2026 | DEC-046 chegou a CONSENSUS na Rodada 2; atualização das interfaces e análise de contexto pendentes antes de READY.
- 15/11/2026 | Análise de contexto fechou wrapper, interfaces observáveis, integração top/QSF e matriz Icarus/VPI; status READY_FOR_IMPLEMENTATION.

- 15/11/2026 | TASK-026 implementada; runner Icarus/VPI passou 159 ciclos, compilação do top e checagens de escopo registradas. Status IMPLEMENTED aguardando auditoria independente.
- 15/11/2026 | Auditoria independente, ciclo 1: Compliance passou; Functional devolvido para REWORK por FIND-026-001, corrida de rearm com DONE retido alto. Nenhum RTL alterado pelo auditor.

- 15/11/2026 | Corrigido FIND-026-001 com handshake `processing_done` baixo→alto; runner passou 187 ciclos e teste agora conserva DONE alto durante nova aceitação START.
- 15/11/2026 | Auditoria independente, ciclo 2: Compliance, Functional e Integration aprovados; FIND-026-001 fechado. Icarus/VPI passou 187 passos. Analysis & Synthesis Quartus CLI: 0 erros, 13 warnings; sem timing, fit ou validação física.
