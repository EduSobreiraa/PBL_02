# TASK-004 — Caminho combinacional de y

## Objetivo

Compor y=((a·x²)+(b·x))+c exato em signed23, com carry privado da soma final e OV conforme DEC-012.

## Status

APPROVED

## Requisitos relacionados

REQ-003, REQ-007, REQ-008, REQ-011.

## Decisões relacionadas

DEC-009/011/012/013/027/028/029/030.

## Dependências

TASK-001 APPROVED; DEC-030 CONSENSUS fecha todos contratos desta composição. Execução depende de TASK-003 e TASK-007 implementadas/testadas/auditadas APPROVED. TASK-002 e raízes não bloqueiam y isolado.

## Restrições aplicáveis

- DUT estrutural: portas lógicas e instâncias explícitas; sem FSM, `buf`, `if`/`else`, `for`, `generate`, `genvar`, operadores aritméticos/condicionais ou `begin/end` fora do DFF. Comportamento só no FF dedicado com captura incondicional na borda positiva.
- `assign` apenas para fios/constantes/concatenação/seleção estática. Extensão de sinal explícita; sem truncamento implícito.
- Testbench separado pode ter estímulos, comparação, laços e aritmética de referência, mas não `if`/`else`; comparação por `case`.
- Preservar interfaces públicas, pinagem e arquivos fora do escopo. Sem referência hierárquica para obter status privado.

## Arquivos permitidos

- `rtl/polynomial_y.v`
- `testbench/tb_polynomial_y.v`
- `verification/reference_y.py`, `verification/vectors/y.txt`
- `verification/results/task-004.md`, `verification/results/task-004.log`
- `docs/tasks/TASK-004.md`

## Arquivos protegidos

Todo arquivo fora da lista permitida, especialmente requisitos, decisões, interfaces públicas, pinagem, Quartus e `rtl/coefficient_input.v.save`.

## Plano

1. mul_s8_s8(x,x) produz signed16 não negativo; bit 15 zero garante representação x² por bits 14:0 unsigned15 exatos.
2. mul_s8_u15(a,x²) produz signed22; mul_s8_s8(b,x) produz signed16 simultaneamente.
3. Estender ax² e bx explicitamente para 23; primeira add23_core gera subtotal. Estender c de8 para 23 e segunda add23_core gera y/carry_y.
4. Encaminhar somente carry da segunda soma; primeiro carry não é C. OV conectado0 conforme domínio exato DEC-012.
5. Wrapper usa um core; integração não duplica wrapper/core. Não implementar seleção, LEDs ou raízes nesta TASK.

## Critérios de aceite

- y exato signed23 em todos vetores, sem truncamento; OV0.
- x² conversão exata, multiplicador u15 dentro domínio, extensão de sinal explícita.
- Carry privado proveniente da última soma, wrapper público preservado; zero FF.
- TASK-003/007 APPROVED, TEST-006 passa e auditoria sem HIGH/CRITICAL para APPROVED.

## Testes

TEST-006: modelo independente de inteiros de precisão ilimitada a*x*x+b*x+c; produto cartesiano {-128,-127,-1,0,1,126,127} para a,b,c,x (2401 vetores), extremos/cancelamento e 10000 vetores de semente fixa registrada. Comparar também carry unsigned da soma final e wrapper/core; auditoria estrutural.

## Resultado da implementação

Implementado `rtl/polynomial_y.v`: wrapper público preservado e core privado; três multiplicadores simultâneos e duas somas estruturais, extensão de sinal explícita, carry somente da soma final, OV constante0 e zero FF. TEST-006 PASS em12413 vetores; fontes congelados para auditoria.

## Resultado das ferramentas

TEST-006 executado em Docker Icarus14.0 devel s20260301-394-g9edaf7b6a, compilação -Wall sem warnings, saída0. PASS:12 dirigidos+2401 cartesianos+10000 pseudoaleatórios, semente20261011; wrapper/core, carry final e OV verificados em todos. Modelo Python independente. Comando, SHA-256 e limites em `verification/results/task-004.md`; saída em `verification/results/task-004.log`. Primeira tentativa negada no socket Docker; reexecução escalada via tar/stdin concluída. Nenhuma síntese/timing/placa alegados.

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo 1, 11/10/2026.** Gate 1 PASS: composição exclusivamente por módulos aprovados e conexões/concatenações estáticas, zero FF/comportamento, wrapper público preservado. Gate 2 PASS: referência Python independente calcula y e carry binário final; testbench rejeita X/Z e exige contagens completas. Log Icarus confirma PASS nos 12413 vetores (12 dirigidos, 2401 cartesianos, 10000 aleatórios), incluindo extremos, cancelamentos, wrapper/core, carry e OV. Gate 3 PASS: x² não perde magnitude na conversão u15, rhs respeita domínio≤16384, extensões signed23 explícitas e carry procede exclusivamente da soma com c; dependências APPROVED e sete hashes atuais iguais aos registrados. Nenhum finding aberto. Não repeti simulação sem preocupação concreta; aprovação não implica exaustão das 2³² entradas, síntese ou placa.

## Pendências

Nenhuma pendência desta implementação: dependências, TEST-006 e auditoria independente aprovados. Integração de flags/top-level e síntese/placa pertencem às tarefas posteriores.

## Implementation Brief

### Objetivo

Compor y=((a·x²)+(b·x))+c exato em signed23, com carry privado da soma final e OV conforme DEC-012.

### Requisitos

REQ-003, REQ-007, REQ-008, REQ-011.

### Decisões aplicáveis

DEC-009/011/012/013/027/028/029/030.

### Módulos envolvidos

`polynomial_y` wrapper público; `polynomial_y_core` privado;2 mul_s8_s8,1 mul_s8_u15,2 add23_core.

### Interface

| Sinal | Direção | Largura/formato | Semântica |
|---|---|---|---|
| a,b,c,x | entradas wrapper/core | signed8 cada | domínio -128..127 |
| y | saída wrapper/core | signed23 | resultado integral completo |
| OV | saída wrapper/core |1| constante0 para domínio válido |
| carry_y | saída SOMENTE core |1| carry-out binário da última soma com c |

Wrapper público tem somente a,b,c,x→y,OV. Wrapper instancia core; top-level futuro instancia somente core para alcançar carry_y por fio privado. loaded e sel não são portas deste bloco: qualificação C cabe a TASK-019. Não alterar wrapper/add23 públicos nem acessar sinais hierarquicamente.

### Clock e reset

Combinacional após alterações de entradas; nenhum clock/reset/FF.

### Restrições

- DUT estrutural: portas lógicas e instâncias explícitas; sem FSM, `buf`, `if`/`else`, `for`, `generate`, `genvar`, operadores aritméticos/condicionais ou `begin/end` fora do DFF. Comportamento só no FF dedicado com captura incondicional na borda positiva.
- `assign` apenas para fios/constantes/concatenação/seleção estática. Extensão de sinal explícita; sem truncamento implícito.
- Testbench separado pode ter estímulos, comparação, laços e aritmética de referência, mas não `if`/`else`; comparação por `case`.
- Preservar interfaces públicas, pinagem e arquivos fora do escopo. Sem referência hierárquica para obter status privado.

### Arquivos permitidos

- `rtl/polynomial_y.v`
- `testbench/tb_polynomial_y.v`
- `verification/reference_y.py`, `verification/vectors/y.txt`
- `verification/results/task-004.md`, `verification/results/task-004.log`
- `docs/tasks/TASK-004.md`

### Arquivos protegidos

Todo arquivo não listado; contratos públicos e pinagem congelados. O implementer registra conflito novo, sem redefinir arquitetura.

### Implementação e instâncias

1. mul_s8_s8(x,x) produz signed16 não negativo; bit 15 zero garante representação x² por bits 14:0 unsigned15 exatos.
2. mul_s8_u15(a,x²) produz signed22; mul_s8_s8(b,x) produz signed16 simultaneamente.
3. Estender ax² e bx explicitamente para 23; primeira add23_core gera subtotal. Estender c de8 para 23 e segunda add23_core gera y/carry_y.
4. Encaminhar somente carry da segunda soma; primeiro carry não é C. OV conectado0 conforme domínio exato DEC-012.
5. Wrapper usa um core; integração não duplica wrapper/core. Não implementar seleção, LEDs ou raízes nesta TASK.

### Testes exigidos

TEST-006: modelo independente de inteiros de precisão ilimitada a*x*x+b*x+c; produto cartesiano {-128,-127,-1,0,1,126,127} para a,b,c,x (2401 vetores), extremos/cancelamento e 10000 vetores de semente fixa registrada. Comparar também carry unsigned da soma final e wrapper/core; auditoria estrutural.

### Casos de borda

Mínimo a=-128,b=127,c=-128,x=-128→-2113536; máximo a=127,b=-128,c=127,x=-128→2097279; x0→c; todos0; sinais mistos; a1,b=-1,c0,x1→0; cancelamentos com termos não nulos. Para carry esperado, somar padrões unsigned23 de subtotal e c estendido e extrair bit23; OV0 em todos. Incluir soma -1+1 final para demonstrar carry1/result0.

### Critérios de aceite

- y exato signed23 em todos vetores, sem truncamento; OV0.
- x² conversão exata, multiplicador u15 dentro domínio, extensão de sinal explícita.
- Carry privado proveniente da última soma, wrapper público preservado; zero FF.
- TASK-003/007 APPROVED, TEST-006 passa e auditoria sem HIGH/CRITICAL para APPROVED.

### Dependências

TASK-001 APPROVED; DEC-030 CONSENSUS fecha todos contratos desta composição. Execução depende de TASK-003 e TASK-007 implementadas/testadas/auditadas APPROVED. TASK-002 e raízes não bloqueiam y isolado.

### Pendências

TASK-003/007 APPROVED; execução e TEST-006 concluídos. Resta auditoria independente, sem decisão arquitetural pendente.

### Resultado do Context Analyst — 11/10/2026

**Brief completo; prontidão técnica da especificação confirmada.** TASK permanece PLANNED exclusivamente aguardando TASK-003/007 APPROVED. Ao cumprir essa dependência, Orchestrator registra READY_FOR_IMPLEMENTATION/READY sem reabrir decisões e encaminha ao implementer.

## Histórico

- 2026-10-11 — DEC-030 em CONSENSUS; brief vigente substitui planejamento anterior, fecha contratos privados/topologia/arquivos/testes. Estado PLANNED; sem RTL ou testes nesta preparação. Autonomia delegada dispensa nova ratificação humana de escolhas compatíveis.

- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
- 2026-10-09 — DEC-028 ratificada: fronteira matemática e exatidão do caminho `y` registrados; TASK permanece DRAFT, dependente das interfaces de TASK-003/007.
- 2026-10-09 — Planejamento da Sprint 2 iniciado; status PLANNED. TEST-006 possui vetores de referência; interface de composição e auditoria estrutural dependem do fechamento das interfaces de TASK-003/007 antes de READY.
- 2026-10-09 — DEC-029 ratificou a associação da soma e a semântica de C; rotas internas estruturais seguem sujeitas a documentação/auditoria antes de READY.

## Liberação pelo Orchestrator — 11/10/2026

TASK-003 e TASK-007 APPROVED após testes e auditoria independente. Dependências do brief satisfeitas: READY_FOR_IMPLEMENTATION; TASK promovida a READY conforme autorização expressa do Context Analyst. Encaminhada ao Code Implementer, sem nova decisão arquitetural.

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW. TEST-006 PASS12413 vetores, sem warnings; relatório/hash/log entregues ao Code Auditor.
