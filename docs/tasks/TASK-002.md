# TASK-002 — Sincronização de controles e armazenamento de coeficientes

## Objetivo

Implementar o caminho sequencial de controles e o armazenamento de `a`, `b` e `c` após três capturas ordenadas.

## Status

APPROVED

## Requisitos relacionados

- REQ-001, REQ-002, REQ-011

## Decisões relacionadas

- DEC-008, DEC-009, DEC-014, DEC-019, DEC-023, DEC-024, DEC-025, DEC-026

## Dependências

- TASK-001 concluída; gate humano da baseline atendido conforme registrado em TASK-001.
- Contrato DEC-023 ratificado com clarificações em DEC-024.
- Testbench comportamental autorizado exclusivamente em arquivo separado, conforme DEC-024 e `docs/regras.md`.

## Restrições aplicáveis

- Sem `if`/`else` em qualquer fonte Verilog (DEC-025); sem FSM, `buf`, loops/geração ou comportamento fora das exceções autorizadas.
- DFF descrito por `always @(posedge clk)` incondicional; reset síncrono e enable montados estruturalmente na entrada D.
- Comportamento sequencial do DUT somente nos módulos dedicados exclusivamente a flip-flops; esses módulos capturam incondicionalmente D já calculado. Não encapsular lógica de controle/datapath comportamental em módulos FF.
- Minimizar bits de armazenamento preservando interface, temporização, sincronização e comportamento DEC-024; documentar funções/estados com memória, estados distinguíveis e codificação. Não remover estado necessário.
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
- DUT e testbench não contêm as palavras-chave `if`/`else`; testbench usa outra construção autorizada para comparação.
- Reset síncrono, captura por enable e retenção sem enable preservam a semântica aprovada após remoção de condicionais procedurais.
- Após três capturas de `8'h80` (−128), `8'h01` (+1), `8'h7F` (+127), saídas estáveis são `a=8'h80`, `b=8'h01`, `c=8'h7F`.
- Alterar `sw` sem nova captura mantém os três valores.
- Após as três capturas iniciais (`80,01,7F`), manter KEY0 pressionado com `sw=8'h2A` por pelo menos oito bordas não altera as saídas: novas capturas ficam bloqueadas até reset, conforme DEC-024.
- Liberar KEY0, esperar pelo menos quatro bordas e pressionar novamente com `sw=8'hD6` também mantém `a=8'h80`, `b=8'h01`, `c=8'h7F` até reset, conforme DEC-024.
- Manter KEY1 pressionado (ativo baixo) e estável por pelo menos seis bordas de clock resulta em `a=b=c=0`; uma pressão simultânea de KEY0 é ignorada. Após liberar KEY1/KEY0 e aguardar a estabilização, não há captura espúria.
- Revisão estrutural confirma que o sincronizador de KEY1 não recebe reset derivado dele próprio, KEY0 tem uma captura por transição e o DFF é a única descrição sequencial permitida.
- Operação física confirma reset após energizar e captura ordenada; fica para TASK-014/TEST-012/015.
- Uma quarta pressão e as seguintes, antes de reset, não alteram `a`, `b` ou `c`.

## Testes

- Reexecutar TEST-001 em simulação após a alteração; incluir confirmação de reset simultâneo a enable, captura com enable e retenção sem enable.
- Revisão estática comprova ausência de `if`/`else` em todos os fontes Verilog e conformidade com DEC-025. Revisão estática geral em TEST-013/TASK-017; integração posterior em TEST-010 e teste físico em TEST-012/015.

## Resultado da implementação

Implementado `coefficient_input` com sincronizadores KEY0/KEY1 de duas etapas, detecção de transição sincronizada de KEY0, contador linear estrutural de progresso e três bancos de registradores com enables. O sincronizador de KEY1 não recebe reset derivado de si próprio. Os estágios de KEY0 e o histórico são preparados como liberados durante o reset; reset mantém os coeficientes em zero e limpa o progresso. Após a terceira captura, eventos adicionais são ignorados.

Os casos antigos de deslocamento nas capturas posteriores à terceira conflitam com DEC-024. Para esta TASK, prevalece a retenção dos três coeficientes até reset; TEST-001 foi ajustado nesse ponto, sem alterar a decisão.

## Resultado das ferramentas

Questa Altera Starter FPGA Edition `vlog 2025.2 Compiler 2025.05` compilou DUT e testbench sem erros e sem warnings:

```sh
vlib work
vlog -work work /home/edupires/Estudos/UEFS/Segundo_Semestre/02_CircuitosDigitais/02_PBL02/rtl/coefficient_input.v /home/edupires/Estudos/UEFS/Segundo_Semestre/02_CircuitosDigitais/02_PBL02/testbench/tb_coefficient_input.v
```

A simulação com `vsim -c -lib work work.tb_coefficient_input -do "run -all; quit -f"` ficou **BLOCKED**: Questa encerrou com código 4 e informou `Unable to find the license file`, `Unable to checkout a license` e `Invalid license environment`.

TEST-001 foi então compilado e executado com Icarus Verilog 14.0 no container local `hdlc/iverilog:latest`, usando cópias de `rtl/coefficient_input.v` e `testbench/tb_coefficient_input.v` em `/tmp/pbl02-test001`. Comando informado pelo Orchestrator:

```sh
iverilog -g2012 -s tb_coefficient_input -o /tmp/test001.vvp coefficient_input.v tb_coefficient_input.v
vvp /tmp/test001.vvp
```

Resultado: `PASS TEST-001 coefficient_input`; término normal em tempo de simulação `2751000` (unidade de precisão do testbench: 1 ps). A simulação aprovada cobre reset inicial e simultaneidade, ausência de captura espúria na liberação, três capturas ordenadas incluindo `-128` e `+127`, retenção ao mudar SW, pressão longa, bloqueio de capturas excedentes até reset, reset após carga completa/parcial e nova sequência após reset. A execução funcional passou com Icarus; a limitação de licença do Questa não bloqueia mais TEST-001.

## Resultado da revisão

**APPROVED — auditoria independente após DEC-026 (2026-10-07).** Os três gates foram aprovados; nenhum finding aberto.

### Gate 1 — Compliance pós-DEC-026

**PASS.** Inspecionei os fontes Verilog atuais. No DUT, os dois blocos `always @(posedge clk)` estão em `pbl_dff_plain` e `pbl_dff_sync_reset`, ambos módulos dedicados a armazenamento; cada bloco é incondicional e atualiza apenas `q` com D calculado. Reset, enable/hold e o próximo estado do contador são implementados com primitivas estruturais. Não encontrei `if`/`else`, FSM, `buf`, laços, geração, `?:` ou `begin/end` fora das descrições dos DFFs. A interface de `coefficient_input` continua conforme DEC-023/024; não identifiquei mudança de top-level, pinagem ou escopo.

### Gate 2 — Funcional e armazenamento mínimo

**PASS.** A evidência registrada para TEST-001 informa compilação e execução bem-sucedidas no Icarus Verilog 14.0, saída `PASS TEST-001 coefficient_input` e término em `2751000` (precisão de 1 ps). Os cenários exercitam reset simultâneo à pressão, liberação sem captura espúria, três capturas ordenadas com valores de borda signed, retenção, pressão longa, bloqueio após a terceira captura, reset parcial/completo e nova carga. Não reexecutei o teste nesta auditoria; validei o testbench e a evidência já registrada.

A contagem estática confere: **31 bits** — 24 para os três coeficientes, 5 para sincronizadores de KEY0/KEY1 e histórico do detector, e 2 para distinguir as quatro condições do progresso (`nenhuma`, `uma`, `duas`, `concluída`). A codificação binária do contador (`00→01→10→11`) usa o limite inferior de dois bits. Os estágios de sincronização e o histórico atendem DEC-019, e não identifiquei registradores redundantes sem remover uma função ou estado aprovado.

### Gate 3 — Integração e evidências

**PASS.** O bloco mantém sua interface local e não altera consumidores, top-level ou pinagem. TEST-001 e sua evidência permanecem rastreados; integração e validação física estão corretamente atribuídas a tarefas posteriores.

### Findings pós-DEC-026

Nenhum finding aberto.

### Revisão anterior — versão DEC-025

**APPROVED — revisão independente da versão DEC-025.** Não foram encontrados findings que impeçam a aprovação.

### Gate 1 — Compliance

**PASS.** Inventariei os fontes Verilog do projeto (`rtl/coefficient_input.v` e `testbench/tb_coefficient_input.v`) e a busca por `if`/`else` em todos os arquivos `.v`, `.sv`, `.vh` e `.svh` não encontrou ocorrências. O DUT não contém FSM, `buf`, laços, geração nem operador condicional; seus únicos blocos `always @(posedge clk)` são incondicionais e pertencem aos módulos DFF autorizados. O `begin/end` no DUT está restrito a essas descrições. A interface local não foi ampliada e não houve alteração de top-level ou pinagem.

No `pbl_dff_sync_reset`, a rede estrutural calcula `normal_data = enable·d + !enable·q` e `d_next = reset·reset_value + !reset·normal_data`. A segunda seleção envolve a primeira, portanto reset síncrono tem prioridade sobre enable; sem reset, enable escolhe `d` e enable baixo realimenta `q`. O armazenamento ocorre somente na borda positiva.

### Gate 2 — Funcional

**PASS.** TEST-001 executou no Icarus Verilog 14.0 e terminou com `PASS TEST-001 coefficient_input` em `2751000` (precisão 1 ps). A comparação foi migrada para `case`/`default` e verifica todas as saídas após cada cenário. A sequência cobre reset junto à pressão de KEY0, ausência de captura espúria após a liberação, três capturas ordenadas com padrões `8'h80`, `8'h01`, `8'h7F`, retenção com SW alterado e enable inativo, pressão longa, capturas excedentes bloqueadas, reset após carga completa e parcial e recarga.

O reset simultâneo a enable é exercitado nos estágios de sincronização de KEY0 e no histórico do detector: essas instâncias têm `enable=1` enquanto KEY1 assertado produz reset, com KEY0 pressionado. O valor de reset prevalece e a verificação após a liberação confirma que não ocorre captura espúria. Captura e retenção também são observadas nas saídas do DUT.

### Gate 3 — Integração

O módulo manteve a fronteira local prevista e não alterou top-level, interfaces canônicas ou pinagem. Integração com consumidores e validação física permanecem em TASKs posteriores.

### Findings

Nenhum finding aberto. A validação de placa permanece fora desta TASK.

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
- DEC-025 — proíbe `if`/`else` em todos os fontes Verilog; no DUT, cálculo estrutural de D e DFF incondicional.
- DEC-026 — restringe o comportamento sequencial do DUT a módulos exclusivos de flip-flops e exige o mínimo de bits de armazenamento que preserve as funções/decisões aprovadas.

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

- Datapath e lógica de sincronização/detecção combinacional estrutural; sem FSM, `buf`, `for`, `generate`, `genvar`, `if` ou `else`.
- `begin/end` somente dentro da descrição do flip-flop; `always @(posedge clk)` incondicional somente para armazenamento. Reset síncrono e enable são muxados estruturalmente antes do DFF.
- Os módulos `pbl_dff_plain` e `pbl_dff_sync_reset` devem conter somente armazenamento; nenhuma lógica de controle/datapath comportamental pode ser colocada neles. A exceção local de contador/enables DEC-024 permanece limitada à TASK-002 e sua lógica combinacional atual é estrutural.
- Usar o mínimo de bits de armazenamento compatível com a função e com as decisões aprovadas; não remover sincronização, histórico de borda, estado de progresso ou coeficientes exigidos.
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
- Após a terceira captura, manter KEY0 pressionado por pelo menos oito bordas com `sw=8'h2A` não altera `a=8'h80`, `b=8'h01`, `c=8'h7F`.
- Liberar KEY0 por pelo menos quatro bordas e pressionar com `sw=8'hD6` também não altera os coeficientes até reset.
- Depois das três capturas válidas, apresentar ao menos mais dois valores distintos e pressionar KEY0; `a`, `b` e `c` devem permanecer inalterados até reset.
- Reset posterior limpa os três valores; comprovar que o sincronizador de KEY1 não é reinicializado por sua saída e que não há captura espúria após liberação/estabilização dos KEYs.
- Reset durante progresso parcial limpa o contador e os registradores; a próxima sequência de três pressões grava nova tripla na ordem correta.

### Justificativa de minimização de flip-flops (DEC-026)

O RTL atual usa 31 bits de armazenamento: 2 estágios do sincronizador de KEY1; 2 estágios do sincronizador de KEY0 e 1 bit de histórico para detectar sua transição sincronizada; 2 bits no contador para distinguir as quatro condições `nenhuma`, `uma`, `duas` e `concluída`; e 24 bits para reter os três coeficientes de 8 bits. Cada grupo atende uma função/estado distinto aprovado. As quatro condições do contador exigem ao menos 2 bits; os coeficientes exigem 24 bits; os sincronizadores de duas etapas e o histórico do detector seguem DEC-019. A codificação atual do contador é `00→01→10→11`, portanto não há bit de progresso excedente identificado nesta análise estática.

### Revalidação do Context Analyst — DEC-026

**READY_FOR_IMPLEMENTATION.** A TASK foi reaberta para revalidar os módulos atuais contra DEC-026. A inspeção de `rtl/coefficient_input.v` encontrou ambos os `always @(posedge clk)` apenas nos módulos dedicados `pbl_dff_plain` e `pbl_dff_sync_reset`, capturando suas entradas D sem condicionais. A lógica de reset/enable, detecção, decodificação e contador é estrutural. A análise de estado acima contabiliza 31 bits e não identificou registrador redundante sem contrariar requisitos ou decisões. Portanto, não há correção concreta de RTL indicada pelo Context Analyst; o Code Auditor deve confirmar a conformidade e a contagem antes de retornar a TASK a APPROVED. Nenhuma mudança arquitetural ou informação pendente foi identificada.

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

### Resultado anterior do Context Analyst

**READY_FOR_IMPLEMENTATION (2026-10-06).** O responsável ratificou DEC-023 com as clarificações de DEC-024 e autorizou o testbench comportamental separado. Contrato, entradas/saídas e critérios mínimos estavam definidos antes da implementação original.

## Histórico

- 2026-10-07 — Code Auditor concluiu revisão independente pós-DEC-026: Gate 1 PASS (comportamento sequencial restrito aos módulos dedicados a FFs e entrada D calculada estruturalmente); Gate 2 PASS (TEST-001 Icarus aprovado segundo evidência registrada; contagem conferida em 31 bits, sem redundância identificada); Gate 3 PASS (interface e escopo preservados). Nenhum finding aberto; status **APPROVED**.

- 2026-10-07 — Code Implementer revalidou a implementação existente após DEC-026. Não encontrou defeito concreto nem fez refactor: o DUT mantém `always @(posedge clk)` incondicional somente em `pbl_dff_plain` e `pbl_dff_sync_reset`, módulos compostos apenas pelo armazenamento; lógica de controle e cálculo de D permanecem estruturais. A contagem é 31 bits (24 coeficientes, 5 sincronização/histórico, 2 progresso), sem armazenamento excedente identificado. TEST-001 passou com Icarus Verilog: `PASS TEST-001 coefficient_input`, término normal em 2751000 (1 ps). A primeira execução montando o workspace falhou por `Permission denied`; cópias dos fontes em `/tmp` executaram com sucesso no container Icarus. Encaminhada para auditoria independente.
- 2026-10-07 — Após DEC-026, TASK-002 reaberta e movida de APPROVED para READY para revalidar os módulos atuais. Context Analyst documentou o limite de 31 bits (24 coeficientes, 5 sincronização/histórico e 2 progresso), não identificou correção de RTL necessária e encaminhou confirmação independente ao Code Auditor.
- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
- 2026-10-06 — Bloqueada até DEC-023 definir contrato interno suficiente para implementação e revisão.
- 2026-10-06 — DEC-023 chegou a CONSENSUS; critérios/vetores foram detalhados. TASK segue BLOCKED aguardando ratificação humana do contrato e autorização do testbench.
- 2026-10-06 — Responsável ratificou DEC-023 com as clarificações de DEC-024; TASK passou a READY. DUT/testbench ainda não implementados nem executados.
- 2026-10-06 — Context Analyst confirmou READY_FOR_IMPLEMENTATION; implementação iniciada pelo fluxo.
- 2026-10-06 — Implementação e compilação concluídas; TEST-001 bloqueado pela indisponibilidade de licença do simulador. Status BLOCKED até obter execução funcional.
- 2026-10-06 — Code Auditor aprovou o Compliance Gate e a inspeção estática, mas classificou a TASK como BLOCKED porque TEST-001 não executou: `vsim` não obteve licença. Nenhum defeito concreto de código encontrado; aprovação funcional depende da execução do teste.
- 2026-10-06 — Orchestrator executou TEST-001 no container `hdlc/iverilog:latest` com Icarus Verilog 14.0; saída `PASS TEST-001 coefficient_input`, término normal em 2751000 (1 ps). Code Auditor atualizou Gate 2; TASK aprovada. A falha de licença do Questa permanece registrada, sem bloquear a evidência alternativa.
- 2026-10-06 — DEC-025 ratificada após solicitação do responsável: proibição de `if`/`else` em todo fonte Verilog. TASK-002 reaberta e retornou a READY para recalcular D estruturalmente, substituir comparação condicional do testbench, reexecutar TEST-001 e auditar.
- 2026-10-06 — Context Analyst reavaliou a reabertura sob DEC-025: **READY_FOR_IMPLEMENTATION**. `docs/regras.md`, interface e comportamento permanecem definidos; o RTL requer substituir o controle `if/else` de `pbl_dff_sync_reset` por muxes estruturais na entrada D, preservando reset síncrono prioritário, captura por enable e retenção por realimentação. O testbench requer substituir sua comparação condicional por `case` sem as palavras-chave proibidas. Restrições: preservar interface/comportamento DEC-023/024; nenhum `if`/`else` em qualquer fonte Verilog; manter `always @(posedge clk)` incondicional somente nos DFFs; sem `?:`, FSM, `buf`, loops/geração no DUT ou alterações fora dos arquivos permitidos. TEST-001 deve ser recompilado e executado no Icarus Docker após a mudança, cobrindo reset simultâneo a enable, captura, retenção e todos os casos existentes; a auditoria estática deve confirmar ausência de `if`/`else` em todo Verilog.
- 2026-10-06 — Code Implementer removeu as palavras-chave proibidas do DUT e testbench. `pbl_dff_sync_reset` agora monta reset síncrono prioritário e mux de enable/hold com primitivas `not`, `and`, `or`; mantém apenas `always @(posedge clk) q <= d_next`. A tarefa `check_values` compara com `case`/`default`. `rg -n '\\b(if|else)\\b' --glob '*.v' rtl testbench` não encontrou ocorrências e `git diff --check` passou. TEST-001 não foi executado: a chamada Docker autorizada falhou lendo o arquivo montado (`rtl/coefficient_input.v: Permission denied`, `Preprocessor failed with 1 error(s)`, exit code 1). Uma repetição com UID 1000 foi interrompida antes da execução; portanto, não há resultado funcional novo. Revisão independente e execução do TEST-001 seguem pendentes.
- 2026-10-06 — Code Auditor realizou revisão independente pós-DEC-025: Gate 1 PASS (sem `if`/`else` em todos os fontes Verilog; mux estrutural de reset/enable correto; restrições e interface respeitadas); Gate 2 PASS (TEST-001 Icarus 14.0 passou, incluindo reset simultâneo a enable nos estágios de KEY0, captura, retenção e comparação por `case`); Gate 3 PASS (sem impacto de integração fora da fronteira autorizada). Nenhum finding aberto; parecer **APPROVED**.
- 2026-10-06 — Orchestrator reexecutou os fontes atualizados no container Icarus com cópia em `/tmp` montada somente para leitura e `--security-opt label=disable`; TEST-001 terminou com `PASS TEST-001 coefficient_input` em `2751000` (1 ps). `docs/verificacao.md` atualizado para a nova evidência. Após os três gates aprovados pelo Code Auditor, TASK-002 voltou a **APPROVED** e a Sprint 1 foi concluída novamente.
