# TASK-040 — Relatório de auditoria independente

**Resultado: BLOCKED — não aprovado.** O gate de conformidade passou e a evidência funcional/integrada examinada passou. A aprovação final está bloqueada pela STA pós-fit: 12 dos 14 endpoints VGA RGB excedem o limite de 40 ns. Essa pendência foi encaminhada à DEC-061. Não encontrei finding de código que exija rework nesta revisão.

## Gate 1 — Compliance

**PASS**, pelos seguintes motivos:

- Inspecionei os 16 novos módulos RTL incluídos na TASK-040. Cada arquivo contém exatamente uma declaração `module`; a varredura sintática após remover comentários e strings não encontrou `assign`, `always`, `buf`, `if/else`, laços, `generate/genvar`, `begin/end` ou `case`. A mesma verificação não encontrou construções proibidas nos 8 arquivos Verilog modificados/criados para os testbenches e integração. Os módulos aritméticos novos são descritos estruturalmente por instâncias de portas e módulos.
- `python3 verification/check_pbl03_sources.py` retornou `PBL03 source check: PASS`. Os 16 novos caminhos `VERILOG_FILE` correspondem às 16 entradas novas do manifesto, todas classificadas `structural`; o checker aprovou a closure e a regra de um módulo por arquivo.
- A diferença de `quartus/pbl03.qsf` consiste somente nas 16 linhas `VERILOG_FILE` autorizadas por DEC-059, anexadas ao final. As atribuições preexistentes mantêm conteúdo e ordem relativa. `quartus/pbl03.sdc` e `vendor/vga/vga_sync.v` não têm diferenças. O `top_pbl03` mantém seus ports externos; as extensões são conexões internas previstas em DEC-060.
- Os arquivos RTL, runners, harnesses, manifesto e QSF alterados estão no escopo permitido pela TASK-040. Não observei alteração de pinagem, clocks, restrições físicas/temporais, fonte VGA do professor ou interfaces físicas.

## Gate 2 — Functional

**PASS para os testes e evidências registrados; nenhum resultado foi reexecutado como parte desta auditoria.** Inspecionei os harnesses/oráculos relevantes e os logs de execução disponíveis.

- `verification/results/task-040/regression.log` registra 30 vetores dirigidos e 256 pseudoaleatórios para raízes, 1.538 casos de pixel/gating do renderer, testes de propagação nos processadores e composição, seguida da regressão full-frame Verilator e do source checker.
- A regressão full-frame verifica cada pixel ativo contra uma referência C++ independente e testa raízes/domínios, blanking, rótulos, colisões e prioridades. O caso **“F2 valid isolated marker with invalid F1”** verifica F2 isolada; o caso **“upper/lower vertex crosses clipped at y=240/-239”** percorre o quadro nas bordas verticais. Há ainda um frame de F2 desabilitada e teste unitário de gate do renderer por `f2_enabled`/domínio.
- O log agregado termina com `20,161,162` verificações no top e `PBL03 source check: PASS`; os casos full-frame apresentados cobrem 11 quadros completos. Os arquivos de verificação abrangem as condições solicitadas na TASK-040/DEC-058 para integração e apresentação.
- Limite da evidência: a comparação pseudoaleatória do teste unitário de raízes usa `sqrtl` e arredondamento em `long double`. Os 30 vetores fixos incluem discriminantes/domínios extremos, ramos com `a<0` e empates positivos/negativos; portanto, não abro finding de correção por essa escolha, mas os 256 casos aleatórios não equivalem a uma prova exata/exaustiva.

## Gate 3 — Integration

**PASS estrutural; STA pendente e reprovada.** `top_pbl03` liga as duas instâncias já existentes de `processador_f1` (F1 e F2) ao renderer e conecta separadamente `root_marker_hit`/`root_label_hit` ao compositor. O gate visual usa `processing_done`, validade própria do domínio de raízes e `f2_enabled` somente para F2; não reutiliza `display_enable` do vértice. O compositor aplica as novas camadas na precedência definida por DEC-058 e preserva blanking final por `video_on`. As larguras permanecem signed8 para coeficientes, signed18 para discriminante e signed9 para raízes; não encontrei ligação de largura incorreta.

O relatório real de TimeQuest em `verification/results/task-040/endpoint-slacks.txt` reprova **12 endpoints RGB** no requisito de 40 ns. Pior slack: `VGA_G[0] = −55.101 ns`. `VGA_HS` e `VGA_VS` passam (+29.897 ns e +30.140 ns). A compilação Quartus terminou com 0 erros e 36 warnings, mas contém avisos críticos de requisitos temporais não atendidos. Os detalhes do caminho estão em `verification/results/task-040/vga-paths-full.log`. Esses resultados impedem APPROVED e exigem a decisão/gate descritos em DEC-061; nenhuma mudança de constraint é recomendada ou autorizada.

## Findings

Não encontrei findings de código CRITICAL/HIGH/MEDIUM/LOW que exijam rework no snapshot auditado. O bloqueio é o gate temporal reprovado, documentado como pendência arquitetural em DEC-061, não uma não conformidade de sintaxe ou funcional identificada nesta auditoria.

## Evidências consultadas

- `docs/regras.md`, `docs/tasks/TASK-040.md` e DEC-031/058/059/060/061.
- `verification/results/task-040/regression.log`.
- `verification/results/task-040/quartus-compile.log`.
- `verification/results/task-040/endpoint-slacks.txt`.
- `verification/results/task-040/vga-paths-full.log`.
- Execução do checker nesta auditoria: `python3 verification/check_pbl03_sources.py` — PASS.

**Status da TASK-040:** manter `BLOCKED`. A regressão funcional e checker aprovados não superam a falha STA; após resolver DEC-061, é necessária nova síntese/fitter/STA pós-fit e auditoria da nova implementação.
