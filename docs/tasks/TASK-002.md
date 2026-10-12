# TASK-002 — Extensão estrutural de carga completa

## Objetivo

Preservar captura a→b→c e disponibilizar loaded pelo core privado, mantendo wrapper público e 31 FF.

## Status

APPROVED

## Requisitos relacionados

REQ-001, REQ-002, REQ-011.

## Decisões relacionadas

DEC-008/014/019/023/024/025/026/027/029/030.

## Dependências

TASK-001 APPROVED; DEC-030 CONSENSUS resolve encapsulamento e autorização local do contador. Independente das unidades aritméticas e das raízes.

## Restrições aplicáveis

- DUT estrutural: portas lógicas e instâncias explícitas; sem FSM, `buf`, `if`/`else`, `for`, `generate`, `genvar`, operadores aritméticos/condicionais ou `begin/end` fora do DFF. Comportamento só no FF dedicado com captura incondicional na borda positiva.
- `assign` apenas para fios/constantes/concatenação/seleção estática. Extensão de sinal explícita; sem truncamento implícito.
- Testbench separado pode ter estímulos, comparação, laços e aritmética de referência, mas não `if`/`else`; comparação por `case`.
- Preservar interfaces públicas, pinagem e arquivos fora do escopo. Sem referência hierárquica para obter status privado.

## Arquivos permitidos

- `rtl/entrada_coeficientes.v`
- `testbench/tb_coefficient_input.v`
- `verification/results/task-002.md` e `verification/results/task-002.log`
- `docs/tasks/TASK-002.md`

## Arquivos protegidos

Todo arquivo fora da lista permitida, especialmente requisitos, decisões, interfaces públicas, pinagem, Quartus e `rtl/coefficient_input.v.save`.

## Plano

1. Mover a lógica existente ao core e conservar nomes/funções dos FF, equações e enable/reset.
2. Conectar loaded à decodificação existente de progresso11. Manter estados00→01→10→11 e bloqueio de novas capturas.
3. Wrapper público instancia core; status extra é apenas porta do core privado. Top-level não é editado nesta TASK.
4. Preservar 24FF coeficientes +2 progresso +5 sincronização/histórico=31. Nenhuma sincronização SW, debounce adicional, latch ou FF de loaded.
5. Atualizar teste para validar core/loaded e equivalência de coeficientes do wrapper. Duplicação de DUT no testbench para comparação não faz parte do sistema sintetizado.

## Critérios de aceite

- Interface do wrapper idêntica à baseline e porta loaded somente no core privado; sem referências hierárquicas.
- TEST-001 passa após refatoração para todos casos e loaded; registro anterior não prova extensão.
- Auditoria confirma 31 FF e lógica estrutural, ordem/captura única/reset/bloqueio inalterados.
- Nenhum HIGH/CRITICAL; evidências reais antes de APPROVED.

## Testes

TEST-001 completo em Icarus/vvp (local ou container DEC-030), cobrindo core e wrapper, com teste de loaded; TEST-013/auditoria de sintaxe/estado. Validação física posterior TASK-014 não bloqueia simulação isolada.

## Resultado da implementação

Extensão DEC-030 implementada em 11/10/2026. Wrapper público preservado, core privado exporta loaded por fio ao decode existente; 31 FF mantidos. TEST-001 compara wrapper/core e loaded em 15 verificações. Evidência: `verification/results/task-002.md` e `.log`. Aguardando Code Auditor.

## Resultado das ferramentas

TEST-001 PASS em Icarus Verilog 14.0 via Docker, 15 verificações, fim em 3391000 ps, compilação -Wall sem warnings. Inspeção estática do Implementer: 31 FF e ausência de palavras-chave proibidas. Fontes, digest, comandos, falhas ambientais de bind mount e logs em `verification/results/task-002.md` e `.log`.

## Resultado da revisão

Code Auditor independente, ciclo 1, 11/10/2026: **APPROVED**. Gate 1 PASS: diff restrito ao wrapper/core e conexão loaded, portas públicas preservadas, comportamento apenas nos FF dedicados, sem construções proibidas. Gate 2 PASS: inspeção das equações preservadas e dos 31 FF; TEST-001 registrado passa 15 verificações incluindo carga parcial/completa, retenção, reset e equivalência wrapper/core; SHA256 dos dois fontes confere com evidência. Gate 3 PASS: loaded usa decode11 privado e não altera top-level/pinagem nem cria estado. Nenhum finding aberto. Não reexecutei simulação, pois os logs e fontes conferem e não surgiu dúvida funcional concreta. Síntese e placa continuam futuras.

## Pendências

Nenhuma pendência de implementação desta extensão. Auditoria independente APPROVED; síntese/validação física pertencem às TASKs posteriores. Risco acadêmico da interpretação do contador registrado em DEC-030, sem afirmar aprovação do tutor.

## Implementation Brief

### Objetivo

Preservar captura a→b→c e disponibilizar loaded pelo core privado, mantendo wrapper público e 31 FF.

### Requisitos

REQ-001, REQ-002, REQ-011.

### Decisões aplicáveis

DEC-008/014/019/023/024/025/026/027/029/030.

### Módulos envolvidos

`coefficient_input` (wrapper público), `coefficient_input_core` (lógica existente e loaded), `pbl_dff_plain`, `pbl_dff_sync_reset` (FF existentes).

### Interface

| Sinal | Direção | Largura/formato | Semântica |
|---|---|---|---|
| clk | entrada dos dois módulos | 1 | clock 50MHz |
| key0_n,key1_n | entradas | 1 cada | níveis físicos ativos baixos |
| sw | entrada | 8 | dados de coeficiente em complemento de dois |
| a,b,c | saídas | signed8 cada | três capturas ordenadas, congeladas após c |
| loaded | saída SOMENTE core privado | 1 | progress_1 AND progress_0, zero até c, um até reset |

Wrapper preserva exatamente a lista de portas original. Instancia um core e deixa loaded privado não consumido. Integração futura instancia somente core, sem duplicar wrapper e core como circuitos independentes. Não publicar evento/reset/progresso.

### Clock e reset

Borda positiva de clk=MAX10_CLK1_50. KEYs sincronizados em duas etapas; KEY1 sincronizado/invertido produz reset síncrono ativo alto prioritário. KEY1 não se reseta pela própria saída; reset põe a,b,c/progresso em zero e histórico/estágios KEY0 em liberado. Exigir reset após energização, sem supor estado inicial.

### Restrições

- DUT estrutural: portas lógicas e instâncias explícitas; sem FSM, `buf`, `if`/`else`, `for`, `generate`, `genvar`, operadores aritméticos/condicionais ou `begin/end` fora do DFF. Comportamento só no FF dedicado com captura incondicional na borda positiva.
- `assign` apenas para fios/constantes/concatenação/seleção estática. Extensão de sinal explícita; sem truncamento implícito.
- Testbench separado pode ter estímulos, comparação, laços e aritmética de referência, mas não `if`/`else`; comparação por `case`.
- Preservar interfaces públicas, pinagem e arquivos fora do escopo. Sem referência hierárquica para obter status privado.

### Arquivos permitidos

- `rtl/entrada_coeficientes.v`
- `testbench/tb_coefficient_input.v`
- `verification/results/task-002.md` e `verification/results/task-002.log`
- `docs/tasks/TASK-002.md`

### Arquivos protegidos

Todo arquivo não listado; contratos públicos e pinagem congelados. O implementer registra conflito novo, sem redefinir arquitetura.

### Implementação e instâncias

1. Mover a lógica existente ao core e conservar nomes/funções dos FF, equações e enable/reset.
2. Conectar loaded à decodificação existente de progresso11. Manter estados00→01→10→11 e bloqueio de novas capturas.
3. Wrapper público instancia core; status extra é apenas porta do core privado. Top-level não é editado nesta TASK.
4. Preservar 24FF coeficientes +2 progresso +5 sincronização/histórico=31. Nenhuma sincronização SW, debounce adicional, latch ou FF de loaded.
5. Atualizar teste para validar core/loaded e equivalência de coeficientes do wrapper. Duplicação de DUT no testbench para comparação não faz parte do sistema sintetizado.

### Testes exigidos

TEST-001 completo em Icarus/vvp (local ou container DEC-030), cobrindo core e wrapper, com teste de loaded; TEST-013/auditoria de sintaxe/estado. Validação física posterior TASK-014 não bloqueia simulação isolada.

### Casos de borda

- KEY1 baixo ≥6 bordas: a=b=c=0 e loaded0; KEY0 durante reset não captura.
- Soltar teclas/estabilizar e capturar 80,01,7F: a=-128,b=1,c=127; loaded0 depois de a/b e loaded1 depois de c.
- Pressão longa ≥8 bordas e quarta/quinta pressões após liberação ≥4 bordas não alteram coeficientes/loaded.
- SW muda sem evento: retenção. Reset parcial/completo limpa tudo e permite nova sequência sem captura espúria.
- Sincronizador KEY1 independente do reset que produz; reset prioritário mesmo com enable/evento.

### Critérios de aceite

- Interface do wrapper idêntica à baseline e porta loaded somente no core privado; sem referências hierárquicas.
- TEST-001 passa após refatoração para todos casos e loaded; registro anterior não prova extensão.
- Auditoria confirma 31 FF e lógica estrutural, ordem/captura única/reset/bloqueio inalterados.
- Nenhum HIGH/CRITICAL; evidências reais antes de APPROVED.

### Dependências

TASK-001 APPROVED; DEC-030 CONSENSUS resolve encapsulamento e autorização local do contador. Independente das unidades aritméticas e das raízes.

### Pendências

Nenhuma decisão técnica aberta. Implementação e nova simulação concluídas; auditoria independente pendente. Risco acadêmico da interpretação do contador registrado em DEC-030, sem afirmar aprovação do tutor.

### Resultado do Context Analyst — 11/10/2026

**READY_FOR_IMPLEMENTATION.** Contrato privado, memória mínima, clock/reset, arquivos e critérios definidos e auditados na decisão. TASK passa a READY; não exige nova consulta.

## Histórico

- 2026-10-11 — Code Implementer concluiu wrapper/core/loaded com 31 FF; TEST-001 PASS (15 verificações), fontes e evidência registrados. Status IMPLEMENTED; encaminhada ao Code Auditor, sem autopromoção para APPROVED.

- 2026-10-11 — DEC-030 em CONSENSUS; brief vigente substitui planejamento anterior, fecha contratos privados/topologia/arquivos/testes. Estado READY; sem RTL ou testes nesta preparação. Autonomia delegada dispensa nova ratificação humana de escolhas compatíveis.

- 2026-10-09 — Reaberta após DEC-029 para especificar `loaded` como saída lógica interna derivada de `progress_1 AND progress_0`, sem FF adicional, mantendo `00→01→10→11` e sem alterar pinos físicos/interface pública do top-level. Status PLANNED até revisão documental, implementação e auditoria independentes; RTL ainda não foi atualizado.
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
- 2026-10-06 — Code Implementer removeu as palavras-chave proibidas do DUT e testbench. `pbl_dff_sync_reset` agora monta reset síncrono prioritário e mux de enable/hold com primitivas `not`, `and`, `or`; mantém apenas `always @(posedge clk) q <= d_next`. A tarefa `check_values` compara com `case`/`default`. `rg -n '\\b(if|else)\\b' --glob '*.v' rtl testbench` não encontrou ocorrências e `git diff --check` passou. TEST-001 não foi executado: a chamada Docker autorizada falhou lendo o arquivo montado (`rtl/entrada_coeficientes.v: Permission denied`, `Preprocessor failed with 1 error(s)`, exit code 1). Uma repetição com UID 1000 foi interrompida antes da execução; portanto, não há resultado funcional novo. Revisão independente e execução do TEST-001 seguem pendentes.
- 2026-10-06 — Code Auditor realizou revisão independente pós-DEC-025: Gate 1 PASS (sem `if`/`else` em todos os fontes Verilog; mux estrutural de reset/enable correto; restrições e interface respeitadas); Gate 2 PASS (TEST-001 Icarus 14.0 passou, incluindo reset simultâneo a enable nos estágios de KEY0, captura, retenção e comparação por `case`); Gate 3 PASS (sem impacto de integração fora da fronteira autorizada). Nenhum finding aberto; parecer **APPROVED**.
- 2026-10-06 — Orchestrator reexecutou os fontes atualizados no container Icarus com cópia em `/tmp` montada somente para leitura e `--security-opt label=disable`; TEST-001 terminou com `PASS TEST-001 coefficient_input` em `2751000` (1 ps). `docs/verificacao.md` atualizado para a nova evidência. Após os três gates aprovados pelo Code Auditor, TASK-002 voltou a **APPROVED** e a Sprint 1 foi concluída novamente.


## Evidências históricas da baseline anterior à extensão DEC-030

O conteúdo abaixo preserva rastreabilidade de execuções/revisões anteriores. Não comprova core/loaded; estados e gates antigos estão supersedidos pelo brief vigente de 11/10/2026.


**Limite da baseline aprovada:** o RTL atualmente registrado implementa o contador e decodifica `progress_done` internamente, mas ainda não disponibiliza `loaded` aos consumidores. A mudança autorizada por DEC-029 não foi implementada nem testada; TASK-002 permanece PLANNED até atualização e auditoria.

Implementado `coefficient_input` com sincronizadores KEY0/KEY1 de duas etapas, detecção de transição sincronizada de KEY0, contador linear estrutural de progresso e três bancos de registradores com enables. O sincronizador de KEY1 não recebe reset derivado de si próprio. Os estágios de KEY0 e o histórico são preparados como liberados durante o reset; reset mantém os coeficientes em zero e limpa o progresso. Após a terceira captura, eventos adicionais são ignorados.

Os casos antigos de deslocamento nas capturas posteriores à terceira conflitam com DEC-024. Para esta TASK, prevalece a retenção dos três coeficientes até reset; TEST-001 foi ajustado nesse ponto, sem alterar a decisão.

### Ferramentas históricas

Questa Altera Starter FPGA Edition `vlog 2025.2 Compiler 2025.05` compilou DUT e testbench sem erros e sem warnings:

```sh
vlib work
vlog -work work /home/edupires/Estudos/UEFS/Segundo_Semestre/02_CircuitosDigitais/02_PBL02/rtl/entrada_coeficientes.v /home/edupires/Estudos/UEFS/Segundo_Semestre/02_CircuitosDigitais/02_PBL02/testbench/tb_coefficient_input.v
```

A simulação com `vsim -c -lib work work.tb_coefficient_input -do "run -all; quit -f"` ficou **BLOCKED**: Questa encerrou com código 4 e informou `Unable to find the license file`, `Unable to checkout a license` e `Invalid license environment`.

TEST-001 foi então compilado e executado com Icarus Verilog 14.0 no container local `hdlc/iverilog:latest`, usando cópias de `rtl/entrada_coeficientes.v` e `testbench/tb_coefficient_input.v` em `/tmp/pbl02-test001`. Comando informado pelo Orchestrator:

```sh
iverilog -g2012 -s tb_coefficient_input -o /tmp/test001.vvp entrada_coeficientes.v tb_coefficient_input.v
vvp /tmp/test001.vvp
```

Resultado: `PASS TEST-001 coefficient_input`; término normal em tempo de simulação `2751000` (unidade de precisão do testbench: 1 ps). A simulação aprovada cobre reset inicial e simultaneidade, ausência de captura espúria na liberação, três capturas ordenadas incluindo `-128` e `+127`, retenção ao mudar SW, pressão longa, bloqueio de capturas excedentes até reset, reset após carga completa/parcial e nova sequência após reset. A execução funcional passou com Icarus; a limitação de licença do Questa não bloqueia mais TEST-001.

### Revisão histórica

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

**PASS.** Inventariei os fontes Verilog do projeto (`rtl/entrada_coeficientes.v` e `testbench/tb_coefficient_input.v`) e a busca por `if`/`else` em todos os arquivos `.v`, `.sv`, `.vh` e `.svh` não encontrou ocorrências. O DUT não contém FSM, `buf`, laços, geração nem operador condicional; seus únicos blocos `always @(posedge clk)` são incondicionais e pertencem aos módulos DFF autorizados. O `begin/end` no DUT está restrito a essas descrições. A interface local não foi ampliada e não houve alteração de top-level ou pinagem.

No `pbl_dff_sync_reset`, a rede estrutural calcula `normal_data = enable·d + !enable·q` e `d_next = reset·reset_value + !reset·normal_data`. A segunda seleção envolve a primeira, portanto reset síncrono tem prioridade sobre enable; sem reset, enable escolhe `d` e enable baixo realimenta `q`. O armazenamento ocorre somente na borda positiva.

### Gate 2 — Funcional

**PASS.** TEST-001 executou no Icarus Verilog 14.0 e terminou com `PASS TEST-001 coefficient_input` em `2751000` (precisão 1 ps). A comparação foi migrada para `case`/`default` e verifica todas as saídas após cada cenário. A sequência cobre reset junto à pressão de KEY0, ausência de captura espúria após a liberação, três capturas ordenadas com padrões `8'h80`, `8'h01`, `8'h7F`, retenção com SW alterado e enable inativo, pressão longa, capturas excedentes bloqueadas, reset após carga completa e parcial e recarga.

O reset simultâneo a enable é exercitado nos estágios de sincronização de KEY0 e no histórico do detector: essas instâncias têm `enable=1` enquanto KEY1 assertado produz reset, com KEY0 pressionado. O valor de reset prevalece e a verificação após a liberação confirma que não ocorre captura espúria. Captura e retenção também são observadas nas saídas do DUT.

### Gate 3 — Integração

O módulo manteve a fronteira local prevista e não alterou top-level, interfaces canônicas ou pinagem. Integração com consumidores e validação física permanecem em TASKs posteriores.

### Findings

Nenhum finding aberto. A validação de placa permanece fora desta TASK.
