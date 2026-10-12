# TASK-003 — Soma/subtração estrutural de larguras fixas

## Objetivo

Implementar soma signed23 para y e subtração signed18 para Δ, preservando exatidão nos domínios aprovados e carry apenas privado.

## Status

APPROVED

## Requisitos relacionados

REQ-005, REQ-007, REQ-008, REQ-011.

## Decisões relacionadas

DEC-012/013/014/027/028/029/030.

## Dependências

TASK-001 APPROVED e DEC-030 CONSENSUS. Não depende da implementação das raízes nem de TASK-002/007; pode criar/verificar células isoladamente.

## Restrições aplicáveis

- DUT estrutural: portas lógicas e instâncias explícitas; sem FSM, `buf`, `if`/`else`, `for`, `generate`, `genvar`, operadores aritméticos/condicionais ou `begin/end` fora do DFF. Comportamento só no FF dedicado com captura incondicional na borda positiva.
- `assign` apenas para fios/constantes/concatenação/seleção estática. Extensão de sinal explícita; sem truncamento implícito.
- Testbench separado pode ter estímulos, comparação, laços e aritmética de referência, mas não `if`/`else`; comparação por `case`.
- Preservar interfaces públicas, pinagem e arquivos fora do escopo. Sem referência hierárquica para obter status privado.

## Arquivos permitidos

- `rtl/somador_completo.v`, `rtl/somador_subtrator.v`
- `testbench/tb_add_sub.v`
- `verification/reference_add_sub.py`, `verification/vectors/add_sub.txt`
- `verification/results/task-003.md`, `verification/results/task-003.log`
- `docs/tasks/TASK-003.md`

## Arquivos protegidos

Todo arquivo fora da lista permitida, especialmente requisitos, decisões, interfaces públicas, pinagem, Quartus e `rtl/coefficient_input.v.save`.

## Plano

1. full_adder por XOR/AND/OR; sum=a XOR b XOR cin; cout=(a AND b) OR (cin AND (a XOR b)).
2. add23_core encadeia 23 full_adders explícitos com cin0; wrapper add23 instancia core e não expõe carry.
3. sub18 inverte rhs bit a bit e encadeia 18 full_adders com cin1. Carry binário final não integra difference signed no domínio.
4. b² do consumidor vem de produto signed16 não negativo: bit 15=0 provado; bits 14:0 mais três zeros formam signed18. ac signed16 concatenado com00 forma4ac signed18 exato.
5. Extensões do consumidor para 23 preservam sinal; primeiro subtotal cabe [-2113408,2097152]. Não incluir flags/reset/temporalização.

## Critérios de aceite

- Soma/subtração exatas nos domínios; extensão explícita e nenhum bit significativo perdido.
- Sem porta pública carry/overflow, carry privado do core testado; circuitos fixos sem FF.
- TEST-002 passa e auditoria independente sem HIGH/CRITICAL antes de APPROVED.

## Testes

TEST-002: comparar contra inteiros independentes, registrar vetores reproduzíveis; testar helper FA exaustivo8 combinações, wrapper/core e sub18; referência carry é soma unsigned dos padrões23. Auditoria estrutural TEST-013.

## Resultado da implementação

Implementados full_adder, add23_core, add23 e sub18 nos arquivos autorizados, zero FF e instâncias explícitas de portas. Referência independente e vetores reproduzíveis em verification/reference_add_sub.py e verification/vectors/add_sub.txt; testbench em testbench/tb_add_sub.v. TEST-002 concluído; encaminhada ao Code Auditor.

## Resultado das ferramentas

TEST-002 PASS: full_adder=8, exact_add=24808, delta=12401, core_modular=3; 37212 vetores. Icarus 14.0 s20260301-394-g9edaf7b6a via Docker, -g2012 -Wall, código 0 e sem warnings. Comandos, limitações e versão em verification/results/task-003.md; log em verification/results/task-003.log.

## Resultado da revisão

Code Auditor independente, ciclo 1, 11/10/2026: **APPROVED**. Gate 1 PASS: full_adder por cinco portas, cadeias explícitas de 23/18 células, fiação estática, zero FF e ausência de construções proibidas; wrapper preserva contrato sem carry público. Gate 2 PASS: leitura do teste/referência independente e log Icarus PASS (FA8 e 37212 vetores); conferência independente dos arquivos de vetores confirma contagens, aritmética/carry e extremos, com zero inconsistências. Gate 3 PASS: larguras/portas e carry privado conformes DEC-030, sem alteração de consumidores/pinos. FIND-003-01 LOW documental corrigido: Δ=-1 impossível no domínio inteiro; cobertura real inclui -4. Nenhum finding aberto. Simulação não repetida sem preocupação funcional concreta; síntese/placa futuras.

## Pendências

Nenhuma pendência desta implementação: TEST-002 e auditoria independente/TEST-013 aprovados. Síntese e validação física permanecem nas tarefas posteriores.

## Implementation Brief

### Objetivo

Implementar soma signed23 para y e subtração signed18 para Δ, preservando exatidão nos domínios aprovados e carry apenas privado.

### Requisitos

REQ-005, REQ-007, REQ-008, REQ-011.

### Decisões aplicáveis

DEC-012/013/014/027/028/029/030.

### Módulos envolvidos

`full_adder`, `add23_core`, wrapper `add23`, `sub18`; helpers combinacionais fixos de portas, sem parâmetro/geração.

### Interface

| Módulo | Entradas | Saídas | Domínio |
|---|---|---|---|
| full_adder | a,b,cin (1bit) | sum,cout (1bit) | adição binária de três bits |
| add23_core | lhs,rhs signed23 | sum signed23,carry_out 1bit privado | padrão de 23 bits + carry binário |
| add23 | lhs,rhs signed23 | sum signed23 | resultado exato para termos/subtotal de y |
| sub18 | lhs,rhs signed18 | difference signed18 | lhs=b² em 0..16384; rhs=4ac em -65024..65536 |

Não prometer exatidão signed irrestrita a pares que exigiriam bit extra. Domínio primeiro add: ax² signed22 e bx signed16 estendidos; segundo: subtotal+c estendido. Sum final y∈[-2113536,2097279]. Carry_out não é OV nem porta do wrapper público.

### Clock e reset

Combinacional: nenhuma porta clock/reset e zero FF.

### Restrições

- DUT estrutural: portas lógicas e instâncias explícitas; sem FSM, `buf`, `if`/`else`, `for`, `generate`, `genvar`, operadores aritméticos/condicionais ou `begin/end` fora do DFF. Comportamento só no FF dedicado com captura incondicional na borda positiva.
- `assign` apenas para fios/constantes/concatenação/seleção estática. Extensão de sinal explícita; sem truncamento implícito.
- Testbench separado pode ter estímulos, comparação, laços e aritmética de referência, mas não `if`/`else`; comparação por `case`.
- Preservar interfaces públicas, pinagem e arquivos fora do escopo. Sem referência hierárquica para obter status privado.

### Arquivos permitidos

- `rtl/somador_completo.v`, `rtl/somador_subtrator.v`
- `testbench/tb_add_sub.v`
- `verification/reference_add_sub.py`, `verification/vectors/add_sub.txt`
- `verification/results/task-003.md`, `verification/results/task-003.log`
- `docs/tasks/TASK-003.md`

### Arquivos protegidos

Todo arquivo não listado; contratos públicos e pinagem congelados. O implementer registra conflito novo, sem redefinir arquitetura.

### Implementação e instâncias

1. full_adder por XOR/AND/OR; sum=a XOR b XOR cin; cout=(a AND b) OR (cin AND (a XOR b)).
2. add23_core encadeia 23 full_adders explícitos com cin0; wrapper add23 instancia core e não expõe carry.
3. sub18 inverte rhs bit a bit e encadeia 18 full_adders com cin1. Carry binário final não integra difference signed no domínio.
4. b² do consumidor vem de produto signed16 não negativo: bit 15=0 provado; bits 14:0 mais três zeros formam signed18. ac signed16 concatenado com00 forma4ac signed18 exato.
5. Extensões do consumidor para 23 preservam sinal; primeiro subtotal cabe [-2113408,2097152]. Não incluir flags/reset/temporalização.

### Testes exigidos

TEST-002: comparar contra inteiros independentes, registrar vetores reproduzíveis; testar helper FA exaustivo8 combinações, wrapper/core e sub18; referência carry é soma unsigned dos padrões23. Auditoria estrutural TEST-013.

### Casos de borda

Zero/identidades; lhs/rhs positivos e negativos; soma -1+1 tem carry1 e resultado0; 1+1 carry0; extremos dos termos válidos para y; Δ mínimo -65536 (b0,a=c=-128) e máximo81408 (b=-128,a=-128,c=127); casos Δ0 e -4 (Δ=-1 é impossível no domínio inteiro, pois b²−4ac é 0 ou 1 módulo 4); carry separado de signed overflow. Não usar par fora de domínio como prova de contrato exato irrestrito.

### Critérios de aceite

- Soma/subtração exatas nos domínios; extensão explícita e nenhum bit significativo perdido.
- Sem porta pública carry/overflow, carry privado do core testado; circuitos fixos sem FF.
- TEST-002 passa e auditoria independente sem HIGH/CRITICAL antes de APPROVED.

### Dependências

TASK-001 APPROVED e DEC-030 CONSENSUS. Não depende da implementação das raízes nem de TASK-002/007; pode criar/verificar células isoladamente.

### Pendências

Nenhuma decisão aberta; implementação e TEST-002 concluídos. Pendente Code Auditor independente, incluindo TEST-013.

### Resultado do Context Analyst — 11/10/2026

**READY_FOR_IMPLEMENTATION.** Interface, domínios, topologia ripple-carry, arquivos e testes fechados. TASK READY.

## Histórico

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW; TEST-002 PASS, sem warnings. Evidências e limitações registradas. Aprovação depende do Code Auditor.

- 2026-10-11 — DEC-030 em CONSENSUS; brief vigente substitui planejamento anterior, fecha contratos privados/topologia/arquivos/testes. Estado READY; sem RTL ou testes nesta preparação. Autonomia delegada dispensa nova ratificação humana de escolhas compatíveis.

- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
- 2026-10-09 — DEC-028 ratificada: larguras, simultaneidade, ausência de portas externas C/OV e preservação exata registrados; permanece DRAFT para detalhamento e auditoria.
- 2026-10-09 — Planejamento da Sprint 2 iniciado; status PLANNED. Interface estrutural, representação exata de `b²`/`4ac` e vetores reproduzíveis de TEST-002 seguem como gates antes de READY.
- 2026-10-09 — DEC-029 fechou a origem de C. Rota de carry permanece detalhe estrutural a documentar e auditar; sem mudança de porta pública.
