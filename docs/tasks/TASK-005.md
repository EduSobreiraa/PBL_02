# TASK-005 — Evidência numérica da arquitetura exata de raízes

## Objetivo

Evidência numérica da arquitetura exata de raízes, conforme a arquitetura exata aprovada em DEC-031. O candidato F=16 foi substituído; esta TASK não aguarda nova escolha de precisão.

## Status

APPROVED

## Requisitos relacionados

REQ-005, REQ-006, REQ-008, REQ-011

## Decisões relacionadas

DEC-007, DEC-013 (formatos candidatos supersedidos por DEC-031), DEC-016, DEC-020 (estratégia de evidência atualizada por DEC-031), DEC-024/025/026/027, DEC-030, DEC-031.

## Dependências

DEC-031 em CONSENSUS e brief documental; nenhuma implementação RTL é necessária para executar esta TASK.

## Restrições aplicáveis

Referência e candidato numéricos externos ao HDL; não alterar RTL. Python pode usar laços/condicionais, sem transferir essa permissão aos arquivos Verilog. Não usar resultados da própria arquitetura como referência independente.

## Arquivos permitidos

- `scripts/verify_roots_exact.py`
- `tests/vectors/roots_directed.json`
- `docs/evidence/roots-exhaustive.json`
- `docs/tasks/TASK-005.md` (resultados e auditoria).

## Arquivos protegidos

Requisitos P0, decisões, regras, pin assignments, top-level e todos os arquivos fora do escopo permitido. Helpers de DUT são privados/fixos e definidos no respectivo arquivo autorizado. Novas decisões não podem ser introduzidas pela implementação.

## Plano

1. Implementar o candidato em Python com os nove estágios restauradores de sqrt/divisão e a expressão de arredondamento de DEC-031, respeitando explicitamente larguras e máscaras. Preservar E/r até a saída final.
2. Implementar referência independente por comparação da raiz com meios inteiros: para t=k+1/2, H=b+a(2k+1), comparar s√Δ com H por sinais e quadrados inteiros, sem usar S/E/Q/r ou a expressão up do candidato. Buscar o intervalo na faixa [-129,129], tratando igualdade para escolher o inteiro de maior magnitude. Referência usa inteiros arbitrários.
3. Enumerar 256³ triplas. Válidos exigem a≠0 e Δ≥0, com x1 ramo + e x2 ramo − inclusive a<0. Inválidos exigem domain_error=1 e x1=x2=0. Verificar também Δ, identidade S²+E e identidade Q·A+r.
4. Gerar vetores dirigidos e relatório reproduzível; retornar código de saída não zero em qualquer divergência. Registrar contagens reais; não prever números de válidos ou alegar sucesso antecipado.

## Critérios de aceite

Zero divergências nas 16.777.216 triplas, relatório reproduzível registrado, referência auditada como independente, vetores dirigidos com cobertura explícita. A execução prova o modelo escolhido; a implementação RTL conserva suas próprias obrigações de teste/auditoria. F16 não é testado nem declarado validado.

## Testes

Exaustão do modelo de arquitetura contra a referência independente para todas as triplas signed8; casos dirigidos TEST-007. Comando de execução proposto: `python3 scripts/verify_roots_exact.py` (modo padrão exaustivo, relatório no arquivo permitido). Uma opção explícita de execução dirigida pode auxiliar desenvolvimento, mas não substitui a execução exaustiva exigida. Não afirmar que essa evidência equivale à simulação RTL.

## Implementation Brief

### Objetivo

Implementar o plano acima sem reinterpretar as decisões numéricas.

### Requisitos

REQ-005, REQ-006, REQ-008, REQ-011

### Decisões aplicáveis

DEC-031 controla algoritmo/contratos; DEC-007 controla arredondamento; DEC-016 exige preservar informação; regras.md e DEC-024/025/026/027 controlam sintaxe. DEC-030 controla integração/flags externa.

### Módulos envolvidos

Modelo candidato dos algoritmos de `sqrt_u17`, `divide_u9_u8` e `quadratic_roots`; referência matemática independente externa ao RTL.

### Interface

Entradas: todas as 16.777.216 triplas `(a,b,c)` signed8. Saídas verificadas: delta signed18, x1/x2 signed9 e domain_error booleano. Produzir relatório JSON com total, válidos, inválidos, divergências, tempo, comando, versões e hash da revisão; produzir vetores JSON com entradas, esperados e categoria. Nenhuma interface HDL será modificada.

### Clock e reset

Não há clock/reset neste escopo: programa de evidência externa ao hardware.

### Restrições

Referência e candidato numéricos externos ao HDL; não alterar RTL. Python pode usar laços/condicionais, sem transferir essa permissão aos arquivos Verilog. Não usar resultados da própria arquitetura como referência independente.

### Arquivos permitidos

Somente os enumerados na seção homônima desta TASK.

### Arquivos protegidos

Todos os demais arquivos, incluindo contratos matemáticos, pinagem e módulos consumidores.

### Testes exigidos

Executar integralmente o plano da seção Testes, com resultados reais e reproduzíveis.

### Casos de borda

a=0; Δ negativo/zero; quadrados perfeitos e vizinhos; a=−128; b/c extremos; r=0 e E=0/E>0 nos dois sentidos de correção; raízes zero; empates positivos/negativos; a negativo sem trocar ramos. Exemplos: (2,−3,1)→(1,1), (2,3,1)→(−1,−1), (−2,3,−1)→(1,1), (1,−128,0)→(128,0).

### Critérios de aceite

Zero divergências nas 16.777.216 triplas, relatório reproduzível registrado, referência auditada como independente, vetores dirigidos com cobertura explícita. A execução prova o modelo escolhido; a implementação RTL conserva suas próprias obrigações de teste/auditoria. F16 não é testado nem declarado validado.

### Dependências

DEC-031 em CONSENSUS e brief documental; nenhuma implementação RTL é necessária para executar esta TASK.

### Pendências

Nenhuma decisão técnica aberta. Implementação e evidência exaustiva concluídas; falta auditoria independente antes de APPROVED.

### Resultado do Context Analyst — 11/10/2026

READY_FOR_IMPLEMENTATION. Contratos, formatos, arquivos, testes e critérios definidos por decisão em CONSENSUS; sem dependência crítica de implementação externa.

## Resultado da implementação

Implementado em 11/10/2026, aguardando auditoria independente:

- `scripts/verify_roots_exact.py`: candidato com estágios restauradores e verificações de largura; cache completo dos domínios primitivos; referência independente por limiares de meio inteiro e quadrados; enumeração exaustiva, máscaras de inválidos e retorno não zero para divergência.
- `tests/vectors/roots_directed.json`: 30 vetores com categorias explícitas, incluindo empates e restos zero/irracionais nos dois sentidos de correção e paridades.
- `docs/evidence/roots-exhaustive.json`: evidência reproduzível com versão Python, comando, revisão, hashes do script/vetores, contagens e limitações.

Nenhum RTL modificado. Cache não reduz cobertura: contém resultados dos algoritmos restauradores, cada um previamente verificado em seu domínio completo.

## Resultado das ferramentas

Comando executado: `python3 scripts/verify_roots_exact.py`.

- Python 3.14.8; execução iniciada em 2026-10-11T14:36:48.602502+00:00; 48,125 segundos; saída 0.
- Total: **16.777.216** triplas; **10.463.208** válidas e **6.314.008** inválidas.
- Inválidas: 65.536 com a=0; 6.248.472 com a≠0 e Δ<0.
- **20.926.416** comparações de raízes válidas; **zero divergências**.
- Domínios primitivos: 131.072 radicandos sqrt e 131.072 pares divisão, todos PASS.
- 30 vetores dirigidos registrados. `git diff --check` dos arquivos acompanhados passou.
- Revisão base: `47b1e30c9bd38d9a6dbc2d7d517449fda002ebc6`, árvore com alterações; hash SHA-256 do script: `bf915d7816fca85e6804f592b3a3a9cdd83c5deb82e7222d0f41c073d1184bd8`.

Resultado **PASS do modelo numérico**. Não houve simulação RTL, síntese, timing ou placa; F16 não é objeto desta evidência. Sem warnings ou erros reportados pelo comando.

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo 1, 11/10/2026.** Gate 1 PASS: programa Python de evidência e artefatos exclusivamente no escopo; não altera RTL e não transfere liberdade sintática ao DUT. Gate 2 PASS: leitura integral confirmou candidato restaurador de nove estágios, cache de todos os 131072 casos de cada primitivo verificados por identidades/divmod, e referência independente por comparações de sinais/quadrados em meios inteiros. A referência não consulta S/E/Q/r nem a expressão up; trata igualdade positiva/negativa e sinal de a. Enumeração cobre 256³ triplas, incluindo máscaras de inválidos; contagens registradas são coerentes (válidos+inválidos=16777216, raízes=2×válidos) e zero divergências. Os 30 vetores incluem r0/E0/irracional, ambas correções/paridades, N0, sinais e empates. Gate 3 PASS: contratos DEC-031, domínios e ordem de ramos preservados; hashes atuais de script/vetores conferem com JSON. Nenhum finding aberto. Não repeti exaustão porque código, hashes e evidência não suscitaram preocupação concreta; aprovação é do modelo numérico, sem certificar futuro RTL/síntese/placa.

## Pendências

Nenhuma pendência desta TASK: implementação, evidência exaustiva e auditoria independente aprovadas. Simulação e auditoria do RTL das raízes continuam obrigatórias nas TASKs próprias.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0 para produzir a evidência de PEN-019; status PLANNED.
- 2026-10-11 — DEC-031 em CONSENSUS substitui F16 por arquitetura exata com resíduos; contratos e Implementation Brief atualizados. Estado READY, sem execução de código/testes.
- 2026-10-11 — Implementação e exaustão concluídas: 16.777.216 triplas, zero divergências; status IMPLEMENTED, aguardando auditoria independente.
- 2026-10-11 — Code Auditor independente aprovou os três gates, conferiu referência/cache/contagens/hashes e separação software/RTL. TASK APPROVED, sem reexecução desnecessária.
