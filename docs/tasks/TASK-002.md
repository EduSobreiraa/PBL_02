# TASK-002 — Sincronização de controles e armazenamento de coeficientes

## Objetivo

Implementar o caminho sequencial de controles e o armazenamento de `a`, `b` e `c` após três capturas ordenadas.

## Status

READY

## Requisitos relacionados

- REQ-001, REQ-002, REQ-011

## Decisões relacionadas

- DEC-008, DEC-009, DEC-014, DEC-019, DEC-023, DEC-024

## Dependências

- TASK-001 concluída; gate humano da baseline atendido conforme registrado em TASK-001.
- Contrato DEC-023 ratificado com clarificações em DEC-024.
- Testbench comportamental autorizado exclusivamente em arquivo separado, conforme DEC-024 e `docs/regras.md`.

## Restrições aplicáveis

- Sem FSM, `buf`, loops/geração ou comportamento fora da exceção autorizada para DFF.
- Não incluir debounce nesta TASK.
- Não usar FSM; o contador linear de progresso e seus enables são a exceção local autorizada por DEC-024 e `docs/regras.md`.

## Arquivos permitidos

- `rtl/coefficient_input.v` (novo módulo local a esta TASK).
- `testbench/tb_coefficient_input.v` (testbench separado; sintaxe comportamental autorizada por DEC-024).
- `docs/tasks/TASK-002.md` e `docs/verificacao.md` para evidências/planejamento desta TASK.

## Arquivos protegidos

- Documentos canônicos, pin assignments e RTL fora do escopo aprovado.

## Plano

- Implementar somente o módulo interno `coefficient_input`, sem alterar `top_module`, pin assignments ou interfaces canônicas.
- Contrato local ratificado em DEC-023/024: entradas `clk` (clock de 50 MHz), `key0_n`/`key1_n` (KEY físicos ativos baixos) e `sw[7:0]`; saídas `a[7:0]`, `b[7:0]`, `c[7:0]` signed.
- Sincronizar KEYs em duas etapas; gerar um evento interno por transição sincronizada de KEY0 para pressionado. Usar contador linear de progresso com enables para gravar sucessivamente `a`, `b` e `c`; após a terceira captura, ignorar novas pressões até reset.
- KEY1 sincronizado produz reset síncrono lógico ativo alto; reset limpa os coeficientes, ignora captura e prepara o histórico do detector de KEY0 como liberado. O sincronizador de KEY1 não é resetado pela própria saída.
- Vetores/expectativas de TEST-001 estão definidos nesta TASK; sequência física exige KEY1 após energizar antes da carga. Não inferir inicialização de power-on.

## Critérios de aceite

- DEC-023/024 ratificadas pelo responsável; testbench comportamental autorizado exclusivamente fora do DUT.
- Após três capturas de `8'h80` (−128), `8'h01` (+1), `8'h7F` (+127), saídas estáveis são `a=8'h80`, `b=8'h01`, `c=8'h7F`.
- Alterar `sw` sem nova captura mantém os três valores.
- Manter KEY0 pressionado enquanto `sw=8'h2A` por pelo menos oito bordas de clock produz somente uma captura; após sincronização/evento, saídas são `a=8'h01`, `b=8'h7F`, `c=8'h2A`.
- Liberar KEY0, esperar pelo menos quatro bordas e pressionar novamente com `sw=8'hD6` (−42) produz uma segunda captura e saídas `a=8'h7F`, `b=8'h2A`, `c=8'hD6`.
- Manter KEY1 pressionado (ativo baixo) e estável por pelo menos seis bordas de clock resulta em `a=b=c=0`; uma pressão simultânea de KEY0 é ignorada. Após liberar KEY1/KEY0 e aguardar a estabilização, não há captura espúria.
- Revisão estrutural confirma que o sincronizador de KEY1 não recebe reset derivado dele próprio, KEY0 tem uma captura por transição e o DFF é a única descrição sequencial permitida.
- Operação física confirma reset após energizar e captura ordenada; fica para TASK-014/TEST-012/015.
- Uma quarta pressão e as seguintes, antes de reset, não alteram `a`, `b` ou `c`.

## Testes

- TEST-001 em simulação, após autorização para testbench; revisão estática em TEST-013/TASK-017; integração posterior em TEST-010 e teste físico em TEST-012/015.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- Validação física posterior na TASK de placa.

## Implementation Brief

### Objetivo

Implementar somente o módulo interno `coefficient_input`: sincronizar KEY0/KEY1, gerar uma captura por pressão de KEY0 e armazenar os três valores signed de 8 bits em ordem `a`, `b`, `c` por contador linear de progresso e enables. Depois da terceira captura, ignorar novas pressões até reset. O bloco é uma fronteira local desta TASK; não altera a interface física ou o top-level aprovado.

### Requisitos

- REQ-001 — reset do sistema.
- REQ-002 — entrada ordenada dos coeficientes.
- REQ-011 — implementação estrutural compatível com as restrições do projeto.

### Decisões aplicáveis

- DEC-008 — `MAX10_CLK1_50`, reset lógico síncrono ativo alto, amostrado na borda de subida; reset dos coeficientes.
- DEC-009 — registro histórico; a arquitetura do deslocador foi supersedida para esta TASK por DEC-024.
- DEC-014 — `always @(posedge clk)` somente na descrição dos DFFs; lógica combinacional/controle permanece estrutural.
- DEC-019 — KEY ativos baixos; sincronização em duas etapas; evento único de KEY0 na transição sincronizada para pressionado; preparação do histórico de KEY0 como liberado durante reset; KEY1 não é reinicializado pela saída do seu próprio sincronizador; exige reset via KEY1 após energizar.
- DEC-023 — contrato externo local de `coefficient_input`, ratificado com clarificações em DEC-024.
- DEC-024 — contador linear com enables, proteção após terceira captura e autorização de testbench comportamental separado.

### Módulos envolvidos

- Novo módulo local `coefficient_input` em `rtl/coefficient_input.v`.
- Não alterar `top_module`, criar submódulos fora do escopo ou introduzir FSM. O contador linear e a condição interna de concluído são autorizados por DEC-024; não expor sinal `complete` na interface.

### Interface local ratificada (DEC-023/024)

| Sinal | Direção | Largura | Semântica |
|---|---|---:|---|
| `clk` | entrada | 1 | Clock `MAX10_CLK1_50`, 50 MHz; amostragem na borda de subida. |
| `key0_n` | entrada | 1 | Nível físico ativo baixo de KEY0; sincronizado em duas etapas; transição sincronizada liberado `1` para pressionado `0` gera uma captura. |
| `key1_n` | entrada | 1 | Nível físico ativo baixo de KEY1; sincronizado em duas etapas; pressionado solicita reset lógico síncrono ativo alto após sincronização. |
| `sw` | entrada | 8 | `SW[7:0]`, padrão de bits signed em complemento de dois, amostrado no evento de captura. |
| `a` | saída | 8 | Coeficiente signed mais antigo após a terceira captura ordenada. |
| `b` | saída | 8 | Coeficiente signed intermediário após a terceira captura ordenada. |
| `c` | saída | 8 | Coeficiente signed mais recente após a terceira captura ordenada. |

Evento de captura, reset lógico e estado do detector permanecem internos; não expor portas adicionais sem revisão do contrato. Após capturar sucessivamente `a`, `b`, `c`, as saídas devem corresponder a esses valores nessa ordem.

### Clock e reset

- Clock: `MAX10_CLK1_50`; borda ativa de subida.
- KEY0 e KEY1 chegam como sinais físicos ativos baixos e são sincronizados em duas etapas.
- Reset de coeficientes: síncrono, lógico ativo alto, produzido pelo KEY1 sincronizado. Limpa `a`, `b`, `c`, ignora captura enquanto ativo e prepara amostra/histórico do detector de KEY0 para liberado (`1`).
- O sincronizador de KEY1 não recebe reset derivado de sua própria saída. Não presumir inicialização de power-on; o procedimento exige pressionar KEY1 após energizar e antes de carregar.

### Restrições

- Datapath e lógica de sincronização/detecção combinacional estrutural; sem FSM, `buf`, `for`, `generate`, `genvar`, ou `always` fora da descrição de DFF.
- `begin/end` somente dentro da descrição do flip-flop; `always @(posedge clk)` restrito ao armazenamento e às condições de reset síncrono/enable aprovadas.
- Não usar KEY como clock, não adicionar reset assíncrono, nem inferir inicialização de power-on.
- Não sincronizar `SW` nem incluir debounce. Após a terceira captura, ignorar captura excedente até reset; não expor sinal de validade/completude.
- Não alterar interfaces canônicas, pin assignments ou outros arquivos RTL.

### Arquivos permitidos

- `rtl/coefficient_input.v` — novo módulo desta TASK, após liberação.
- `testbench/tb_coefficient_input.v` — autorizado; construções comportamentais permitidas apenas no testbench, separadas do DUT.
- `docs/tasks/TASK-002.md` — brief, plano e evidências desta TASK.
- `docs/verificacao.md` — registro/planejamento de evidências do TEST-001 relacionadas a esta TASK.

### Arquivos protegidos

- Outros RTL, `top_module`, interfaces e documentos canônicos fora das permissões acima.
- Requisitos, decisões, pin assignments e arquivos Quartus.

### Testes exigidos

- TEST-001; inicializar explicitamente o testbench, sem pressupor estado power-on.
- Revisão estática estrutural conforme TEST-013/TASK-017 quando executada; integração posterior em TEST-010 e validação física em TEST-012/015 na TASK de placa.

### Casos de borda e expectativas de TEST-001

- KEY1 baixo por pelo menos seis bordas, aguardando a sincronização: `a=b=c=0`; KEY0 pressionado durante reset não captura.
- Após reset e estabilização, capturar `8'h80`, `8'h01`, `8'h7F` em pressões separadas: ao final `a=8'h80`, `b=8'h01`, `c=8'h7F`.
- Alterar `sw` sem nova pressão mantém as saídas.
- Manter KEY0 pressionado por pelo menos oito bordas com `sw=8'h2A` produz apenas uma captura; então `a=8'h01`, `b=8'h7F`, `c=8'h2A`.
- Liberar KEY0 por pelo menos quatro bordas e pressionar com `sw=8'hD6` produz nova captura; então `a=8'h7F`, `b=8'h2A`, `c=8'hD6`.
- Depois das três capturas válidas, apresentar ao menos mais dois valores distintos e pressionar KEY0; `a`, `b` e `c` devem permanecer inalterados até reset.
- Reset posterior limpa os três valores; comprovar que o sincronizador de KEY1 não é reinicializado por sua saída e que não há captura espúria após liberação/estabilização dos KEYs.
- Reset durante progresso parcial limpa o contador e os registradores; a próxima sequência de três pressões grava nova tripla na ordem correta.

### Critérios de aceite

- DEC-023/024 ratificadas; autorização humana para testbench registrada.
- Interface, ordem, larguras e clock/reset locais correspondem ao contrato ratificado e às DEC-008/009/014/019/024.
- TEST-001 passa para os casos acima após autorizado; revisão estrutural confirma DFF como única descrição sequencial e respeita as demais restrições.
- Evidência documentada confirmando bloqueio de capturas posteriores à terceira e sem alegar inicialização de power-on.
- Validação física permanece fora desta TASK e é requisito posterior, não critério para implementação/simulação isolada.

### Dependências

- TASK-001 concluída; o gate humano de revisão da baseline foi atendido conforme registrado em TASK-001.
- TEST-001 para verificar esta unidade; integração e teste de placa ficam nas TASKs posteriores indicadas acima.

### Pendências

- Teste físico posterior em TASK-014/TASK de placa; não bloqueia a implementação isolada após os gates acima.

### Resultado do Context Analyst

**READY.** O responsável ratificou DEC-023 com as clarificações de DEC-024 e autorizou o testbench comportamental separado. Contrato, entradas/saídas e critérios mínimos estão definidos. A implementação e a execução de TEST-001 ainda não começaram; o gate humano da baseline foi atendido conforme TASK-001.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
- 2026-10-06 — Bloqueada até DEC-023 definir contrato interno suficiente para implementação e revisão.
- 2026-10-06 — DEC-023 chegou a CONSENSUS; critérios/vetores foram detalhados. TASK segue BLOCKED aguardando ratificação humana do contrato e autorização do testbench.
- 2026-10-06 — Responsável ratificou DEC-023 com as clarificações de DEC-024; TASK passou a READY. DUT/testbench ainda não implementados nem executados.
