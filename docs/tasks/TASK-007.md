# TASK-007 — Multiplicadores estruturais signed

## Objetivo

Produzir produtos completos s8×s8→s16 e s8×u15→s22 no domínio quadrático, com linhas parciais e somas espaciais.

## Status

APPROVED

## Requisitos relacionados

REQ-005, REQ-007, REQ-008, REQ-011.

## Decisões relacionadas

DEC-012/013/014/027/028/030.

## Dependências

TASK-001 APPROVED e DEC-030 CONSENSUS. TASK-003 fornece full_adder compartilhado: ordenar integração desse arquivo após sua entrega, sem reabrir decisões. Não depende de roots/loaded.

## Restrições aplicáveis

- DUT estrutural: portas lógicas e instâncias explícitas; sem FSM, `buf`, `if`/`else`, `for`, `generate`, `genvar`, operadores aritméticos/condicionais ou `begin/end` fora do DFF. Comportamento só no FF dedicado com captura incondicional na borda positiva.
- `assign` apenas para fios/constantes/concatenação/seleção estática. Extensão de sinal explícita; sem truncamento implícito.
- Testbench separado pode ter estímulos, comparação, laços e aritmética de referência, mas não `if`/`else`; comparação por `case`.
- Preservar interfaces públicas, pinagem e arquivos fora do escopo. Sem referência hierárquica para obter status privado.

## Arquivos permitidos

- `rtl/multiplicadores.v`
- `rtl/somador_completo.v` apenas para reutilizar/adicionar helpers fixos coerentes com DEC-030, coordenando ownership com TASK-003; nenhuma mudança no full_adder aprovado
- `testbench/tb_multipliers.v`
- `verification/reference_multipliers.py`, `verification/vectors/multipliers.txt`
- `verification/results/task-007.md`, `verification/results/task-007.log`
- `docs/tasks/TASK-007.md`

## Arquivos protegidos

Todo arquivo fora da lista permitida, especialmente requisitos, decisões, interfaces públicas, pinagem, Quartus e `rtl/coefficient_input.v.save`.

## Plano

1. Implementar linhas parciais por AND e deslocamentos/concatenações fixas de lhs estendido; instâncias explícitas.
2. s8×s8: somar linhas dos bits rhs0..6 em 16 bits e subtrair linha peso128 selecionada por rhs7. Prefixo cabe±16256 e produto final[-16256,16384].
3. s8×u15: somar quinze linhas em 22 bits; cada prefixo unsigned≤rhs≤16384, portanto produto intermediário cabe[-2097152,2080768].
4. Ripple-carry espacial, sem Booth/Wallace, magnitude absoluta extra, `*`, `+`, laços, controle sequencial ou compartilhamento temporal.
5. Helpers fixos reutilizam full_adder; para evitar edições concorrentes, TASK-003 entrega arithmetic_cells antes de integrar os multiplicadores. Análise/modelo/testbench podem avançar independentemente.

## Critérios de aceite

- Produtos exatos em todos pares dos domínios e nenhuma perda nos intermediários.
- TEST-003 exaustivo passa; auditoria confirma pré-condição u15 e conversão de quadrados.
- Zero FF, sintaxe permitida, interfaces preservadas e nenhum HIGH/CRITICAL antes de APPROVED.

## Testes

TEST-003 compara com referência matemática independente:65536 pares s8×s8 e 4194560 pares s8×u15 com rhs0..16384. Registrar cobertura/contagem e backend. Quadrados de todos 256 valores verificam bit 15 zero e conversão u15 exata. Auditoria TEST-013.

## Resultado da implementação

Implementados mul_s8_s8 e mul_s8_u15 em rtl/multiplicadores.v, 420 instâncias explícitas de full_adder aprovado, com portas AND para seleção das linhas. Zero FF, sem alterações no helper compartilhado. Referência e testbench independentes nos arquivos permitidos; execução exaustiva concluída.

## Resultado das ferramentas

TEST-003 PASS em Icarus14.0 s20260301-394-g9edaf7b6a via Docker:65536 pares signed,4194560 pares mistos,256 quadrados,91 dirigidos; retorno0, sem warnings -Wall. Comando, hashes SHA-256, limites e tentativas alternativas de ferramenta registrados em verification/results/task-007.md; log integral em verification/results/task-007.log.

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo 1, 11/10/2026.** Gate 1 PASS: inspeção estrutural conferiu todas as 420 conexões full_adder (112+308), seleção e extensão/deslocamento das 23 linhas, carry inicial e subtração do peso de sinal; nenhuma construção proibida, FF ou alteração do helper aprovado. Gate 2 PASS: referências independentes por multiplicação inteira, comparações que rejeitam X/Z e contagens completas; log Icarus final confirma 65536 pares signed, 4194560 pares mistos, 256 quadrados e 91 dirigidos, término normal. Gate 3 PASS: formatos e domínio rhs≤16384 preservados, bit15 dos quadrados comprovado na simulação, cinco hashes atuais conferem com artefatos executados. Nenhum finding aberto. Tentativas Verilator não contam como resultado funcional; a aprovação usa o PASS integral Icarus. Exaustão não repetida; síntese/placa futuras.

## Pendências

Nenhuma pendência desta implementação. TEST-003 e auditoria independente/TEST-013 aprovados. Síntese e validação física permanecem nas tarefas posteriores.

## Implementation Brief

### Objetivo

Produzir produtos completos s8×s8→s16 e s8×u15→s22 no domínio quadrático, com linhas parciais e somas espaciais.

### Requisitos

REQ-005, REQ-007, REQ-008, REQ-011.

### Decisões aplicáveis

DEC-012/013/014/027/028/030.

### Módulos envolvidos

`mul_s8_s8`, `mul_s8_u15`; full_adder aprovado/reutilizável de TASK-003 e cadeias locais explícitas de largura16/22.

### Interface

| Módulo | Entradas | Saída | Pré-condição |
|---|---|---|---|
| mul_s8_s8 | lhs,rhs signed8 | product signed16 | todos 65536 pares |
| mul_s8_u15 | lhs signed8,rhs unsigned15 | product signed22 | rhs entre0 e16384 inclusive |

rhs não é u15 irrestrito:32767 poderia exigir produto signed23. No caminho y, rhs=x² satisfaz a pré-condição. Produto quadrático s16 tem bit 15=0 e bits 14:0 representam valor exato; não truncar informação. Sem carry/overflow público.

### Clock e reset

Combinacional, sem clock/reset e zero FF.

### Restrições

- DUT estrutural: portas lógicas e instâncias explícitas; sem FSM, `buf`, `if`/`else`, `for`, `generate`, `genvar`, operadores aritméticos/condicionais ou `begin/end` fora do DFF. Comportamento só no FF dedicado com captura incondicional na borda positiva.
- `assign` apenas para fios/constantes/concatenação/seleção estática. Extensão de sinal explícita; sem truncamento implícito.
- Testbench separado pode ter estímulos, comparação, laços e aritmética de referência, mas não `if`/`else`; comparação por `case`.
- Preservar interfaces públicas, pinagem e arquivos fora do escopo. Sem referência hierárquica para obter status privado.

### Arquivos permitidos

- `rtl/multiplicadores.v`
- `rtl/somador_completo.v` apenas para reutilizar/adicionar helpers fixos coerentes com DEC-030, coordenando ownership com TASK-003; nenhuma mudança no full_adder aprovado
- `testbench/tb_multipliers.v`
- `verification/reference_multipliers.py`, `verification/vectors/multipliers.txt`
- `verification/results/task-007.md`, `verification/results/task-007.log`
- `docs/tasks/TASK-007.md`

### Arquivos protegidos

Todo arquivo não listado; contratos públicos e pinagem congelados. O implementer registra conflito novo, sem redefinir arquitetura.

### Implementação e instâncias

1. Implementar linhas parciais por AND e deslocamentos/concatenações fixas de lhs estendido; instâncias explícitas.
2. s8×s8: somar linhas dos bits rhs0..6 em 16 bits e subtrair linha peso128 selecionada por rhs7. Prefixo cabe±16256 e produto final[-16256,16384].
3. s8×u15: somar quinze linhas em 22 bits; cada prefixo unsigned≤rhs≤16384, portanto produto intermediário cabe[-2097152,2080768].
4. Ripple-carry espacial, sem Booth/Wallace, magnitude absoluta extra, `*`, `+`, laços, controle sequencial ou compartilhamento temporal.
5. Helpers fixos reutilizam full_adder; para evitar edições concorrentes, TASK-003 entrega arithmetic_cells antes de integrar os multiplicadores. Análise/modelo/testbench podem avançar independentemente.

### Testes exigidos

TEST-003 compara com referência matemática independente:65536 pares s8×s8 e 4194560 pares s8×u15 com rhs0..16384. Registrar cobertura/contagem e backend. Quadrados de todos 256 valores verificam bit 15 zero e conversão u15 exata. Auditoria TEST-013.

### Casos de borda

lhs -128,-127,-1,0,1,126,127; rhs signed extremos e u15 0,1,127,128,16383,16384; (-128)*(-128)=16384; (-128)*16384=-2097152;127*16384=2080768; sinais mistos e zero. Não reivindicar cobertura válida de rhs16385..32767.

### Critérios de aceite

- Produtos exatos em todos pares dos domínios e nenhuma perda nos intermediários.
- TEST-003 exaustivo passa; auditoria confirma pré-condição u15 e conversão de quadrados.
- Zero FF, sintaxe permitida, interfaces preservadas e nenhum HIGH/CRITICAL antes de APPROVED.

### Dependências

TASK-001 APPROVED e DEC-030 CONSENSUS. TASK-003 fornece full_adder compartilhado: ordenar integração desse arquivo após sua entrega, sem reabrir decisões. Não depende de roots/loaded.

### Pendências

Nenhuma decisão arquitetural aberta. Implementação e TEST-003 concluídos; aguarda Code Auditor independente, incluindo TEST-013.

### Resultado do Context Analyst — 11/10/2026

**READY_FOR_IMPLEMENTATION.** Brief completo e topologia auditada. TASK READY; implementar após entrega das células compartilhadas de TASK-003 ou avançar artefatos independentes sem editar simultaneamente o mesmo arquivo.

## Histórico

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW; TEST-003 exaustivo PASS, hashes fontes executadas registrados. Aprovação depende de Code Auditor.

- 2026-10-11 — DEC-030 em CONSENSUS; brief vigente substitui planejamento anterior, fecha contratos privados/topologia/arquivos/testes. Estado READY; sem RTL ou testes nesta preparação. Autonomia delegada dispensa nova ratificação humana de escolhas compatíveis.

- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
- 2026-10-09 — DEC-028 ratificada: contratos 8×8→16 e 8×u15→s22, produtos completos e sem truncamento implícito registrados; permanece DRAFT para detalhamento e auditoria da topologia.
- 2026-10-09 — Planejamento da Sprint 2 iniciado; status PLANNED. Interface consumidora, proposta/auditoria da topologia e vetores de TEST-003 seguem como gates antes de READY; conversão exata dos produtos quadráticos deve ser demonstrada.
