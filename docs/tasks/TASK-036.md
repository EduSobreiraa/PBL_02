# TASK-036 | Verificar a integração completa do PBL03

## Objetivo

Executar uma regressão reproduzível do caminho entrada→controle→validação→RGB, displays e LEDs antes dos extras. Manter as regressões unitárias aprovadas em Icarus e usar um harness C++ externo com Verilator para a captura eficiente de um quadro end-to-end.

## Status

APPROVED

## Dependências

- TASK-025-032 e TASK-034-035 | base obrigatória integrada e compilável.
- TASK-042 `APPROVED` | evidência final da revisão corrigida em `verification/results/task-042/final/`, incluindo quadro público active-low, Quartus A&S/Fitter/TimeQuest e 14 endpoints com slack positivo.
- DEC-045 | simulação estrutural com estímulo e checagem externos.

## Planejamento e aceite

- Cobrir seis coeficientes, START, BUSY/DONE, reset e reexecução.
- Cobrir F1 e F2 válidas, F2 desabilitada, cada erro, função válida junto de função inválida e clipping.
- Verificar RGB para eixos, quatro curvas, blanking e prioridades atuais entre curvas/eixos.
- Comparar cálculos com uma referência independente e conferir pelo menos um frame completo. A igualdade F1/F2 e a quinta cor pertencem à TASK-037.
- Repetir compilação e regressão com um comando documentado e registrar logs vinculados à revisão.

## Arquivos

Definidos no Implementation Brief. Incluir harness C++ externo/runner, referência independente e casos da regressão base; wrapper Verilog não é necessário.

## Resultado

Implementação e regressão agregada concluídas; aguardando auditoria independente.

## Decisão de sequenciamento

DEC-052 (CONSENSUS) separou a regressão base da quinta cor: esta TASK verifica o comportamento integrado já implementado; igualdade F1/F2 e prioridade da quinta cor serão verificadas na regressão end-to-end estendida pela TASK-037. DEC-044 permanece intacta.

## Estado após DEC-053/054

TASK-042 foi aprovada com a revisão final e artefatos em `verification/results/task-042/final/`. O bloqueio de polaridade e temporização foi resolvido para a regressão base. DEC-052 continua separando igualdade F1/F2 e quinta cor, que pertencem à TASK-037.

## Implementation Brief

### Objetivo

Adicionar uma regressão reproduzível de integração que estimule e verifique a interface física completa de `top_pbl03`, reaproveitando as regressões já aprovadas por módulo. A regressão deve testar controle, entrada, erros, displays, LEDs e vídeo com um modelo de referência independente.

### Requisitos

- PBL03 PDF §§4.1–4.15: captura/configuração, cálculo, VGA, mensagens/indicadores e entrega de estruturas de teste e simulação.
- REQ-015: estruturas de teste, simulações e elementos usados na validação.
- REQ-001: reset/inicialização, para a rota lógica e o reset do VGA.

### Decisões aplicáveis

- DEC-044: seis coeficientes, início/reset, resultados exatos, clipping e cálculo por coordenada VGA. Esta TASK verifica somente as quatro curvas e prioridades atualmente implementadas; igualdade F1/F2 e quinta cor ficam para TASK-037 conforme DEC-052.
- DEC-045: controlar o DUT estrutural diretamente ou por wrapper estrutural; estímulo e checagem externos ao Verilog; falhar explicitamente em divergências.
- DEC-046: sincronização/qualificação de KEY0 e KEY1.
- DEC-048/049: comportamento dos processadores, handshake START/BUSY/DONE e reset.
- DEC-050: mapeamento LEDR, mensagens HEX, prioridade e gate por DONE.
- DEC-051: não existe painel textual VGA.
- DEC-052: separar a regressão base desta TASK da extensão de interseções da TASK-037, preservando DEC-044 e a dependência entre as tarefas.

### Módulos envolvidos

- `top_pbl03` como DUT de integração, compilado pela lista canônica do QSF.
- Toda a hierarquia incluída em `quartus/pbl03.qsf`, incluindo `vendor/vga/vga_sync.v` intacto.
- Regressões existentes dos módulos de entrada, processadores F1/F2, handshake, vídeo e status.

### Interface do DUT e estímulo

Instanciar diretamente `top_pbl03` como raiz do Verilator, sem wrapper. O harness C++ dirige as portas públicas e avança o clock com chamadas `eval()`; a referência e as comparações permanecem no C++ externo ao Verilog. As regressões unitárias aprovadas continuam sendo executadas em Icarus/VPI.

| Sinal | Direção/largura | Semântica para a regressão |
|---|---|---|
| `MAX10_CLK1_50` | entrada, 1 bit | Clock de sistema a 50 MHz lógico; ciclo usado pelo driver é 20 ns |
| `KEY[1:0]` | entrada, 2 bits | KEY0 confirma/inicia; KEY1 reseta; ambos pressionados em nível baixo |
| `SW[8:0]` | entrada, 9 bits | `SW[7:0]` magnitude e `SW[8]` sinal; manter valor estável durante captura |
| `LEDR[9:0]` | saída, 10 bits | `[0]=BUSY`, `[1]=DONE`, `[2]=ERR_F1`, `[3]=ERR_F2`, `[9:4]=0` |
| `HEX0..HEX5[6:0]` | saídas, 7 bits cada | Segmentos `[a..g]`, ativos baixos; vazio durante reset/BUSY/sem erro e mensagem conforme DEC-050 após DONE |
| `VGA_HS`, `VGA_VS` | saídas, 1 bit cada | Sincronismos ativos baixos do `vga_sync` fornecido |
| `VGA_R/G/B[3:0]` | saídas, 4 bits por canal | Cor RGB do pixel corrente; preto durante blanking, eixos e quatro curvas/prioridades já implementados conforme TASK-031 quando DONE; não esperar igualdade F1/F2 ou a quinta cor nesta TASK |

### Clock e reset

- O DUT recebe clock de 50 MHz em `MAX10_CLK1_50`.
- Para a entrada, KEY0 e KEY1 passam pelos sincronizadores existentes; usar apertos mantidos pelo intervalo necessário ao debounce/qualificação e liberar entre eventos. Não usar KEY como clock.
- KEY1 baixo ativa o reset assíncrono alto do periférico VGA pela rota existente e, após sincronização, o reset lógico síncrono ativo alto. A regressão deve começar com reset explícito e verificar a limpeza/retorno do fluxo.
- O raster gera avanço de pixel a 25 MHz, 800 posições por linha por 525 linhas por quadro; um quadro completo corresponde a 420.000 posições de pixel (840.000 ciclos do clock de 50 MHz após alinhamento de fase). O driver deve considerar o alinhamento observado do periférico, sem editar seus parâmetros.

### Restrições

- Não modificar RTL sintetizável para facilitar o teste.
- Não modificar `vendor/vga/vga_sync.v` ou o QSF para incluir estímulos/testes como fontes de hardware.
- Seguir DEC-045: estímulo e checagem externos ao Verilog podem dirigir e observar o DUT estrutural. O harness Verilator deve usar somente os ports públicos do top e não adicionar wrapper comportamental Verilog.
- Não usar acesso a estado interno, `force`/`release` ou sondas privadas para contornar entradas/portas do DUT; acionar somente os ports da interface top.
- Usar um modelo independente de `f(x)=ax²+bx+c` e `f′(x)=2ax+b` com aritmética de largura suficiente (p.ex. `int64_t` no driver), comparando valores matemáticos antes de mapear para linha/cores.
- Não arredondar ou truncar resultados para fazê-los caber em pixel; aplicar clipping e prioridade conforme decisões aprovadas.
- Preservar saídas e arquivos PBL02.

### Arquivos permitidos

- `sim/pbl03_top_verilator.cpp` (harness externo C++ de integração direta ao top, incluindo a referência independente e checagens do frame).
- `sim/run_pbl03_top_verilator.sh` (compila/elabora as fontes QSF com Verilator e executa o harness C++ end-to-end).
- `sim/run_pbl03_regression.sh` (comando único para checker de fontes, runners unitários Icarus aprovados e regressão end-to-end Verilator; usar `docker run --rm -i` nas duas execuções containerizadas e markers explícitos por runner para impedir falso PASS por EOF/stdin fechado).
- `docs/tasks/TASK-036.md` (brief, comandos, logs e resultados reais).
- `verification/results/task-036/**` (logs e resumo referenciados pela revisão executada).

Não criar wrapper Verilog: a porta do DUT é explícita e DEC-045 autoriza controle direto do alvo estrutural. O harness C++ é código de teste externo, não parte das fontes do dispositivo.

### Arquivos protegidos

- Todos `rtl/**`, `quartus/pbl03.qsf`, `quartus/pbl03.sdc` e `quartus/pbl02.*`.
- `vendor/vga/**`, requisitos, decisões, tarefas aprovadas e harnesses/runners existentes fora dos arquivos explicitamente permitidos.
- Nenhum arquivo de fontes Quartus deve passar a incluir driver, wrapper ou referência de teste.

### Testes exigidos

1. Executar `python3 verification/check_pbl03_sources.py`.
2. Executar os runners de regressão aprovados existentes: `sim/run_video_axes_icarus.sh`, `sim/run_coefficient_input_pbl03.sh`, `sim/run_f1_function_icarus.sh`, `sim/run_f1_processor_icarus.sh`, `sim/run_f1_f2_processors_icarus.sh`, `sim/run_main_handshake_pbl03_icarus.sh` e `sim/run_status_errors_pbl03_icarus.sh`.
3. O runner end-to-end compila a lista `VERILOG_FILE` do QSF atual com Verilator e o harness C++; dirige apenas os ports de `top_pbl03` e compara outputs com casos fixos e referência independente.
4. O runner agregado deve propagar falha de qualquer compilação/teste, produzir log com data/revisão do repositório e ter um comando de execução documentado. As duas chamadas `docker run ... sh -s <<HEREDOC` devem incluir `-i` para o container receber o script pelo stdin.
5. Capturar e comparar pelo menos um quadro inteiro após DONE, cobrindo sincronismos, blanking e posições de pixel dos quatro traços/eixos e suas prioridades atuais.

O Quartus não é o simulador funcional. O QSF/SDC e os resultados físicos da TASK-035 ficam protegidos. Os sete runners de módulos existentes continuam em Icarus/VPI; a compilação/elaboração e a regressão de quadro completo do top usam Verilator/C++ para evitar custo de callback VPI por ciclo.

### Casos de regressão e bordas

- Reset inicial: KEY1 ativo baixo; confirmar reset lógico, VGA sincronizado, entradas/resultados limpos e saídas RGB pretas/HEX em branco.
- Captura de `a₁,b₁,c₁,a₂,b₂,c₂` na ordem, uma confirmação por coeficiente; ver progresso nos displays conforme implementação aprovada; após c₂, revisão sem início até novo evento KEY0.
- START gera BUSY e depois DONE retido; status/HEX/LED conforme DEC-049/050. Reexecução com coeficientes mantidos limpa DONE durante validação, conclui novamente e não aceita evento KEY0 durante BUSY.
- Entrada inválida fora de −128…127 não avança; cobrir o limite −128, 127 e normalização de −0. Confirmar reset KEY1 retorna à captura completa.
- F1 válida com F2 toda nula; duas funções válidas; erro `a=0` em cada função; vértice externo em cada função; uma função válida junto da outra inválida; dois erros simultâneos e prioridade HEX de DEC-050.
- Cálculos em x negativo, x=0 e positivo; extremos de coordenada visível x=−320/319; resultados y em/fora de −239…240 sem alias por truncamento.
- Quadro integral: hsync/vsync, bordas da área ativa, RGB preto fora de `video_on`, eixos, cada uma das quatro curvas e prioridades já implementadas entre elas/eixos/fundo. Não exigir igualdade F1/F2 nem quinta cor; essa extensão e um novo quadro end-to-end são responsabilidade da TASK-037.
- O runner deve incluir ao menos uma entrada deliberadamente inválida para provar que uma divergência ou resultado inesperado retorna código de falha.

### Critérios de aceite executáveis

- A execução de `sim/run_pbl03_regression.sh` compila o DUT a partir da lista QSF, executa os sete runners unitários Icarus citados e a regressão end-to-end Verilator/C++, e termina com código zero apenas se todos passarem.
- Ambas as chamadas Docker do agregado mantêm `-i`; se o stdin do container for fechado, o runner não pode emitir PASS.
- O log final contém um marker `RUN PASS <runner>` após o retorno zero de cada um dos sete runners Icarus e do runner Verilator full-frame (oito markers), além de versões Icarus/VVP/Verilator/GCC, saídas PASS dos casos e `TOP VERILATOR PASS: full frame 800x525`. A presença apenas de `PBL03 TASK-036 AGGREGATE PASS` não basta; os oito markers precisam estar presentes.
- Logs da execução final registram hash/commit, comandos, número de checks e valores esperado/observado nas falhas. `existing-runners.log` e `top-verilator.log` são preflight/baseline, não resultado final do agregado desta TASK.
- Os valores esperados vêm do modelo C externo e de contratos fixos independentes do RTL; não se usam sinais internos do DUT como oráculo.
- A captura cobre um quadro completo de 800×525 períodos de pixel e confirma todos os critérios de vídeo enumerados acima.
- `verification/check_pbl03_sources.py` continua aprovado e confirma que os novos arquivos de teste não foram adicionados à compilação Quartus.
- Nenhum arquivo RTL, QSF/SDC ou vendor muda.

### Dependências

- TASK-025, TASK-026, TASK-027, TASK-028, TASK-029, TASK-030, TASK-031 e TASK-032: todas `APPROVED` e definem RTL/contratos de integração.
- TASK-034 e TASK-035: ambas `APPROVED`; fontes Quartus, pinagem, SDC e evidência de compilação estão fechados.
- DEC-045 e DEC-052 estão `CONSENSUS`; a interface física está completa no top-level e documentada por TASK-035.
- TASK-037 permanece dependente desta regressão base aprovada e será responsável por reexecutar o quadro completo com a quinta cor habilitada.
- Regressões atuais estão em `sim/`; o arquivo QSF fornece a lista de fontes única. O Quartus Prime Lite 25.1std.0 e GCC estão presentes localmente.

### Pendências e riscos

- Icarus/VVP estão disponíveis via imagem Docker local `hdlc/iverilog:latest` (v14 devel); Verilator/C++ via `hdlc/verilator:latest`. O host não fornece Icarus/VVP, então a execução reproduzível usa essas imagens e instala GCC/cabeçalhos C para compilar os módulos VPI.
- A execução agregada com fingerprint passou e está registrada em `verification/results/task-036/regression-20261118T165634Z.log`, com manifesto de inputs, oito markers `RUN PASS`, versões e full frame. `regression-20261118T164616Z.log` e `regression-20261118T165315Z.log` preservam execuções anteriores e achados de rastreabilidade; os seus manifests não são a evidência vigente. `existing-runners.log` e `top-verilator.log` continuam sendo apenas preflight/baseline.
- Não há pendência técnica de regressão nesta TASK. Sem teste físico de monitor/placa, que não faz parte dos critérios executáveis desta regressão.

### Resultado do Context Analyst

**READY_FOR_IMPLEMENTATION.** TASK-025–032, TASK-034–035 e TASK-042 estão `APPROVED`; DEC-045 e DEC-052 estão `CONSENSUS`. Os artefatos `verification/results/task-042/final/` confirmam sincronismos active-low, frame RGB e 14 endpoints VGA positivos sob 40 ns. O escopo continua como regressão base; interseções/quinta cor seguem na TASK-037. O runner agregado tem um defeito concreto dentro do escopo: as duas chamadas Docker não usam `-i`, podendo pular os runners por EOF; o brief autoriza corrigir e exige oito markers explícitos de conclusão. Nenhuma decisão ou interface está pendente; preflight logs permanecem históricos e a execução agregada final é critério de implementação.

### Implementação e evidências

Arquivo alterado: `sim/run_pbl03_regression.sh`. Ambas chamadas Docker agora usam `-i`, e o container Icarus instala `gcc` e `libc6-dev` dos snapshots bullseye main/security/updates para compilar os módulos VPI. Após o retorno zero, o runner registra `RUN PASS <runner>` para cada um dos sete runners Icarus e para a regressão Verilator full-frame. O `set -Eeuo pipefail` externo e `set -eu` dos containers preservam a propagação de falhas. O script foi marcado executável.

Execuções iniciais: `regression-20261118T164616Z.log` passou os oito runners, mas registrou apenas HEAD/status. `regression-20261118T165315Z.log` adicionou fingerprint abrangente e ficou preservada como histórico; a reauditoria apontou que a mudança posterior na documentação impedia validar o manifesto todo.

Execução final após o segundo REWORK: `./sim/run_pbl03_regression.sh`, log `verification/results/task-036/regression-20261118T165634Z.log`, iniciada em 2026-11-18T16:56:34Z no HEAD `c7a98f42523eef5d44a07f88316c98b5db20ac27`. O manifesto está em `verification/results/task-036/tree-manifest-20261118T165634Z.sha256`, SHA-256/fingerprint `0fc4e4cbe85231560302a33a64bdc4f601d4f2c24b80231b9d59b25d4049b9c4`, com 283 entradas. O escopo cobre arquivos `.v .sv .vh .svh .c .h .cpp .hpp .sh .py .qsf .sdc` tracked e untracked não ignorados (RTL, harnesses, runners, checker e configurações); exclui documentação e `verification/results/**` mutáveis. O comando é `git ls-files -co --exclude-standard -z | LC_ALL=C sort -z | grep -zE '\\.(v|sv|vh|svh|c|h|cpp|hpp|sh|py|qsf|sdc)$' | xargs -0 -r sha256sum`, seguido do SHA-256 do manifesto. O snapshot ocorre antes de criar os artefatos da execução, evitando autorreferência. `sha256sum -c` confirmou as 283 entradas após a documentação de resultados ser atualizada.

A execução final teve PASS: checker de fontes; sete markers Icarus, incluindo 187 passos de entrada, 3.421 casos datapath F1, 92 ciclos processador F1, 25 ciclos F1/F2, 265 casos vídeo, 250 ciclos handshake e 64 combinações de status; marker Verilator e full frame 800×525, 1.680.469 checks / 1.661.568 ciclos. Icarus/VVP 14.0 devel, GCC 10.2.1 e Verilator 5.053 devel foram registrados.

O `-i` permitiu que os heredocs realmente executassem; falhas anteriores por headers C ausentes e dependências apt incompletas não foram tratadas como PASS. A execução final passou depois de incluir `libc6-dev` e as fontes snapshot security/updates. `verification/check_pbl03_sources.py` passou antes e depois da regressão; `git diff --check` passou. O log final contém exatamente os oito markers `RUN PASS` e `PBL03 TASK-036 AGGREGATE PASS`.

### Resultado do Implementer

**IMPLEMENTED.** A regressão agregada foi executada com sucesso no branch `EduSobreiraa/PBL-03`; após o finding de identidade, foi repetida com fingerprint SHA-256 dos inputs e executáveis da regressão. A quinta cor/interseções permanece fora desta tarefa e é responsabilidade da TASK-037. Nenhuma alteração RTL, QSF, SDC ou vendor foi feita nesta tarefa.

### Auditoria independente

**REWORK.** Compliance, Functional e Integration passaram, exceto por uma lacuna de rastreabilidade que impede a aprovação da evidência atual.

#### FIND-001 — Identidade incompleta da revisão executada

- **Severidade:** MEDIUM
- **Arquivo/localização:** `sim/run_pbl03_regression.sh` (registro inicial da revisão); `verification/results/task-036/regression-20261118T164616Z.log` (linhas `Git HEAD` e `Working tree status at start`).
- **Problema:** o log registra commit `c7a98f42523eef5d44a07f88316c98b5db20ac27` e nomes de arquivos dirty, mas a regressão executou uma revisão de trabalho que também contém alterações e arquivos não commitados. O hash de HEAD sozinho não identifica o conteúdo exato testado; status lista caminhos, sem fingerprint dos bytes de RTL, runner e harness.
- **Critério relacionado:** aceite executável de TASK-036 exige hash/commit da revisão final que foi testada.
- **Evidência:** o log de início lista `rtl/top/top_pbl03.v`, dois multiplicadores e SDC modificados, além de harnesses e scripts de simulação não rastreados; esses arquivos participam da regressão.
- **Correção necessária:** registrar uma identidade determinística da árvore de trabalho efetivamente testada (incluindo diffs tracked e arquivos source/test untracked relevantes) ou executar a regressão em um commit que contenha esses arquivos. Reexecutar o runner após a correção e apontar para o novo log.

Demais gates: o runner fornece `-i` às duas chamadas Docker; os shells internos propagam falhas; o log final contém oito `RUN PASS`, versões, sete regressões Icarus, frame Verilator 800×525/1.680.469 checks, source checker antes/depois e `PBL03 TASK-036 AGGREGATE PASS`. Não houve mudança de RTL, QSF, SDC ou vendor nesta TASK. `verification/check_pbl03_sources.py` e `git diff --check` passaram durante a auditoria.

### Reauditoria de FIND-001

**REWORK — finding permanece aberto.** O novo log `regression-20261118T165315Z.log` contém HEAD, status, fingerprint SHA-256 e aponta para `tree-manifest-20261118T165315Z.sha256`. Os oito markers `RUN PASS`, o checker antes/depois, as sete suites Icarus e o quadro Verilator continuam presentes e a regressão final termina com `PBL03 TASK-036 AGGREGATE PASS`.

Ao verificar o manifesto, 2.372 das 2.374 entradas coincidem com os arquivos atuais; `sha256sum -c` falha em `docs/tasks/TASK-036.md` e `sim/run_pbl03_regression.sh`. A documentação foi atualizada depois da execução. O próprio runner também foi alterado depois: a versão atual restringe o manifesto a extensões de fontes/configuração e registra esse escopo, mas o log/manifesto 16:53 foram produzidos pela versão anterior, que hashava todos os arquivos. Assim o novo comando/fingerprint ainda não foi exercitado e a revisão efetivamente executada não está identificada pelo escopo de hash agora documentado.

`FIND-001` segue MEDIUM. A versão atual do runner já propõe o escopo correto: fontes RTL/vendor e arquivos de estímulo, scripts, harnesses, QSF/SDC e fixtures que os runners leem, excluindo documentação e resultados; HEAD e `git status` ficam separados. Agora é necessário executar o agregado usando essa versão, produzir log/manifesto correspondentes e confirmar o manifesto contra os inputs sem mutação posterior.

### Resolução após o segundo REWORK

A regressão completa foi executada com o escopo restrito. `regression-20261118T165634Z.log` corresponde ao manifesto `tree-manifest-20261118T165634Z.sha256`, fingerprint `0fc4e4cbe85231560302a33a64bdc4f601d4f2c24b80231b9d59b25d4049b9c4`; `sha256sum -c` passou para as 283 entradas. O log registra escopo/comando, HEAD, status, oito markers `RUN PASS`, frame completo e `PBL03 TASK-036 AGGREGATE PASS`. `git diff --check` passou.

### Reauditoria final

**APPROVED.** FIND-001 foi resolvido: o manifesto cobre apenas os inputs de código/configuração da regressão, excluindo documentação e resultados mutáveis. O fingerprint agregado corresponde ao manifesto e todas as 283 entradas passaram `sha256sum -c`. HEAD e status do working tree permanecem separados. O log final contém os oito marcadores `RUN PASS`, checker de fontes antes/depois, sete suítes Icarus, frame Verilator completo com 1.680.469 checks e `PBL03 TASK-036 AGGREGATE PASS`. O runner inclui `-i` nos dois containers e propaga falhas. Avisos de auxiliares do `iverilog -V` e `inside_y` do Verilator ficaram registrados e não impediram os gates. Nenhum finding HIGH/CRITICAL permanece.
