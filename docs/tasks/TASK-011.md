# TASK-011 — Composição estrutural do discriminante e raízes exatas

## Objetivo

Composição estrutural do discriminante e raízes exatas, conforme a arquitetura exata aprovada em DEC-031. O candidato F=16 foi substituído; esta TASK não aguarda nova escolha de precisão.

## Status

APPROVED

## Requisitos relacionados

REQ-005, REQ-006, REQ-008, REQ-011

## Decisões relacionadas

DEC-007, DEC-013 (formatos candidatos supersedidos por DEC-031), DEC-016, DEC-020 (estratégia de evidência atualizada por DEC-031), DEC-024/025/026/027, DEC-030, DEC-031.

## Dependências

Implementações TASK-003/007/008/009 aprovadas para integração; TASK-005 executada e auditada para aprovação funcional. Contratos e decisões já fechados; estas são dependências de execução.

## Restrições aplicáveis

Implementação do DUT exclusivamente estrutural: portas, fios, módulos fixos e instâncias explícitas; sem FSM, FF/registradores, `always`, `if`, `else`, `buf`, `for`, `generate`, `genvar` ou `begin/end`. Operadores aritméticos nas fórmulas são especificação matemática, não autorização de operadores no DUT. Testbenches separados podem usar estímulos/comparações comportamentais, laços e blocos conforme DEC-024, mas `if`/`else` continuam proibidos em todo Verilog. Não alterar interfaces públicas ou pinagem.

## Arquivos permitidos

- `rtl/quadratic_roots.v`
- `testbench/tb_quadratic_roots.v`
- `docs/tasks/TASK-011.md` (resultados e auditoria).

## Arquivos protegidos

Requisitos P0, decisões, regras, pin assignments, top-level e todos os arquivos fora do escopo permitido. Helpers de DUT são privados/fixos e definidos no respectivo arquivo autorizado. Novas decisões não podem ser introduzidas pela implementação.

## Plano

1. Gerar b² unsigned15 e ac signed16, estender respectivamente com zeros/sinal para signed18 e formar 4ac sem perda; delta signed18 em [-65536,81408]. Selecionar radicando zero quando delta negativo, ou delta[16:0] quando não negativo.
2. Receber S9/E10 da sqrt. Estender b a signed10 antes da negação; S com zero a signed10. Formar Nplus=−b+S e Nminus=−b−S signed10, magnitudes unsigned9≤413; A=abs(a) unsigned8 inclui corretamente −128→128.
3. Dividir simultaneamente cada |N| por A: Q9/r8; aplicar sinal signN XOR signa. Q com sinal representa intermediário signed10/F=1, acompanhado de E/r/A/ramo/sinal até o arredondamento final. Não criar armazenamento nem cópia redundante do intermediário.
4. Em cada ramo, base=Q>>1; up=Q[0] AND (r≠0 OR E=0 OR correção de magnitude positiva). A correção positiva é N>0 no ramo + e N<0 no ramo −. Somar base+up em magnitude unsigned9 e aplicar sinal em signed9. N=0 produz zero. Mascarar ambas saídas no domínio inválido.
5. Conferir a prova de DEC-031: nenhum E/r pode desaparecer antes de decidir up; q_fixed sozinho não é a representação completa. Todas conexões/negações/seleções são estruturais.

## Critérios de aceite

Delta exato, saídas/erros conformes, resíduos preservados até arredondamento, zero FF, TEST-007 aprovado, TASK-005 com evidência exaustiva registrada e auditoria independente aprovada. Sem afirmar que domain_error isolado satisfaz persistência ERR até reset.

## Testes

TEST-007: vetores independentes produzidos pela TASK-005, cobrindo todos os grupos abaixo; comparar delta/domain_error e as duas saídas exatas. Adicionar casos aleatórios determinísticos com seed registrada, sem confundir com a exaustão do modelo Python. Registrar simulador, comandos, contagens, logs e hash. Evidência exaustiva da TASK-005 é gate de aprovação da cadeia; simulação RTL continua obrigatória.

## Implementation Brief

### Objetivo

Implementar o plano acima sem reinterpretar as decisões numéricas.

### Requisitos

REQ-005, REQ-006, REQ-008, REQ-011

### Decisões aplicáveis

DEC-031 controla algoritmo/contratos; DEC-007 controla arredondamento; DEC-016 exige preservar informação; regras.md e DEC-024/025/026/027 controlam sintaxe. DEC-030 controla integração/flags externa.

### Módulos envolvidos

`quadratic_roots`, multiplicadores/somadores aprovados de TASK-003/007, uma instância `sqrt_u17`, duas instâncias `divide_u9_u8` e helpers fixos privados prefixados `roots_` no próprio arquivo.

### Interface

Entradas a,b,c signed8. Saídas delta signed18, x1/x2 signed9 e domain_error de 1 bit. Delta=b²−4ac; domain_error=(a=0) OR delta<0. x1=round((-b+√Δ)/(2a)), x2=round((-b−√Δ)/(2a)), empates para longe de zero; x1/x2=0 quando domínio inválido. Não ordenar/trocar raízes quando a<0. ERR persistente e qualificação loaded são externas (DEC-030).

### Clock e reset

Não há clock/reset neste escopo: rede puramente combinacional, zero flip-flops. ERR persistente até reset pertence à integração, não a domain_error.

### Restrições

Implementação do DUT exclusivamente estrutural: portas, fios, módulos fixos e instâncias explícitas; sem FSM, FF/registradores, `always`, `if`, `else`, `buf`, `for`, `generate`, `genvar` ou `begin/end`. Operadores aritméticos nas fórmulas são especificação matemática, não autorização de operadores no DUT. Testbenches separados podem usar estímulos/comparações comportamentais, laços e blocos conforme DEC-024, mas `if`/`else` continuam proibidos em todo Verilog. Não alterar interfaces públicas ou pinagem.

### Arquivos permitidos

Somente os enumerados na seção homônima desta TASK.

### Arquivos protegidos

Todos os demais arquivos, incluindo contratos matemáticos, pinagem e módulos consumidores.

### Testes exigidos

Executar integralmente o plano da seção Testes, com resultados reais e reproduzíveis.

### Casos de borda

a=0, Δ<0/0/>0, a=−128, b=−128, c=−128/127; raiz zero; r=0/E=0 e r=0/E>0 com correção positiva/negativa; meio inteiro dos dois sinais; quadrados perfeitos/vizinhos; sinais mistos; x1/x2 com a<0; magnitudes máximas.

### Critérios de aceite

Delta exato, saídas/erros conformes, resíduos preservados até arredondamento, zero FF, TEST-007 aprovado, TASK-005 com evidência exaustiva registrada e auditoria independente aprovada. Sem afirmar que domain_error isolado satisfaz persistência ERR até reset.

### Dependências

Implementações TASK-003/007/008/009 aprovadas para integração; TASK-005 executada e auditada para aprovação funcional. Contratos e decisões já fechados; estas são dependências de execução.

### Pendências

Dependências APPROVED e implementação/teste concluídos. Nenhuma decisão arquitetural aberta; resta auditoria independente.

### Resultado do Context Analyst — 11/10/2026

PLANNED. Brief técnico completo, mas a composição deve aguardar implementações dependentes. Não há decisão pendente e não existe bloqueio por F16/PEN-019.

## Resultado da implementação

Implementado `quadratic_roots` com dois multiplicadores signed8, sub18, uma sqrt_u17 e dois divide_u9_u8 aprovados. Helpers fixos roots_ fazem negação condicionada, soma/subtração signed10, incremento unsigned9 e máscaras por portas/células full_adder. Delta exato, radicando mascarado no sinal negativo, |a| inclui128, resíduos E/r mantidos até up, aplicação de sinal e máscaras finais independentes da ordem das raízes. Zero FF. Fontes congelados; TEST-007 PASS nos10030 vetores.

## Resultado das ferramentas

TEST-007 concluído:10030 vetores (30dirigidos+10000pseudoaleatórios seed20261011),6255válidos e3775inválidos; delta,ambas raízes e domain_error PASS. Docker Icarus14.0, compilação -Wall sem warnings, processo retornou0. Comando/log/hash abaixo. Teste não é exaustão RTL; TASK-005 fornece a evidência exaustiva independente do modelo.

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo 1, 11/10/2026.** Gate 1 PASS: inspeção integral confirma composição estrutural com helpers fixos, sqrt compartilhada e duas divisões simultâneas, zero FF e nenhuma construção proibida. Gate 2 PASS: b² estendido com zeros e ac deslocado para signed18 preservam delta; b é estendido antes da negação, abs(-128) produz u8=128, numeradores signed10 e magnitudes≤413 não perdem bits. E/r são usados até up=Q0 AND (r≠0 OR E=0 OR correção positiva); sinal de a não troca os ramos e N0 arredonda a zero. Máscaras invalidam a0/Δ negativo. Oracle independente por meios inteiros trata empates e sinais e cabe signed32. Log TEST-007 PASS10030 (6255 válidos/3775 inválidos) inspecionado, com cobertura dirigida e aleatória especificada. Gate 3 PASS: interfaces/formatos DEC-031, dependências APPROVED e hashes atuais de todos os artefatos coincidem com execução. Nenhum finding; simulação não repetida. Esta aprovação inclui RTL amostral e evidência exaustiva separada do modelo TASK-005, sem alegar exaustão RTL, síntese, timing ou placa.

## Pendências

Nenhuma pendência desta implementação: dependências, TEST-007 e auditoria independente aprovados. Integração com loaded/ERR/apresentação e síntese/placa seguem nas tarefas correspondentes.

## Histórico

- 2026-10-11 — TASK-003/005/007/008/009 APPROVED, satisfazendo todas as dependências de execução. O Implementation Brief vigente permanece inalterado; TASK promovida a READY pelo Implementation Orchestrator, sem nova decisão arquitetural.

- 2026-10-06 — TASK candidata criada na Sprint 0; status BLOCKED.
- 2026-10-11 — DEC-031 em CONSENSUS substitui F16 por arquitetura exata com resíduos; contratos e Implementation Brief atualizados. Estado PLANNED, sem execução de código/testes.

## Reprodução e evidências do Code Implementer — 11/10/2026

```sh
tar -cf - rtl/arithmetic_cells.v rtl/add_sub.v rtl/multipliers.v rtl/sqrt_u17.v rtl/divide_u9_u8.v rtl/quadratic_roots.v testbench/tb_quadratic_roots.v | docker run --rm -i hdlc/iverilog:latest sh -c 'mkdir -p /tmp/work; cd /tmp/work; tar -xf -; iverilog -V; iverilog -g2012 -Wall -s tb_quadratic_roots -o /tmp/task011.vvp rtl/arithmetic_cells.v rtl/add_sub.v rtl/multipliers.v rtl/sqrt_u17.v rtl/divide_u9_u8.v rtl/quadratic_roots.v testbench/tb_quadratic_roots.v && vvp /tmp/task011.vvp' > /tmp/task-011.log 2>&1
```

Backend Docker hdlc/iverilog:latest (tag mutável), Icarus14.0 devel s20260301-394-g9edaf7b6a. Primeira tentativa negada no socket; reexecução escalada via tar/stdin. Log bruto temporário em `/tmp/task-011.log`; trecho final persistido abaixo nesta TASK. Sem síntese/timing/validação física.

TEST-007 usa30 triplas dirigidas de `tests/vectors/roots_directed.json`, mantendo suas categorias, mais10000 triplas determinísticas por $random(seed), seed inicial20261011 no backend registrado. O oracle do TB calcula delta com inteiros e busca fronteiras k+1/2 comparando delta com quadrados inteiros; não usa sqrt/divisão restauradora nem a fórmula de up. Limites intermediários do oracle cabem em integer signed32 (|H|≤33152, H²<2³¹); meio da busca calculado como low+(high−low)/2 preserva piso mesmo para low negativo. Inválidos são comparados com erro1 e raízes0, válidos preservam identidade de cada ramo inclusive a<0. Igualdade case rejeita X/Z. Trata-se de simulação amostral RTL, distinta da evidência exaustiva do modelo em TASK-005.

### SHA-256 dos artefatos executados

```text
0e9e393098a238cf0e5992a187834922fea4506eea13d4cdc635debf7376098e  rtl/arithmetic_cells.v
fad812f3d306bc60b327a464946f96a2915c28f0dbb44b01a782d212dc75da3a  rtl/add_sub.v
95d8de13e7cab690e72544c5b4c89efe7c956f46eadcc714a112f80123ddc371  rtl/multipliers.v
9c2dd06c7db0ec74226f4911130739cc8862c1efa46ddad6965b507858aeb2c9  rtl/sqrt_u17.v
3c78a3f6df23183f9e395cde079e9e2e074fad85cd5ae5e1643d10a2690783cb  rtl/divide_u9_u8.v
4a3ea3a69479a724da17adf1f26c99397d6f7ff8d5e3d9844bba25993392c03e  rtl/quadratic_roots.v
48cecc3eb8153562e3b8e101d8f1694bf7327b9757731f127c8dd9f5229f6354  testbench/tb_quadratic_roots.v
9fed7974bf632d30f13b7cdb26e2e913b9b48813f87dbe671ded72171db7c5a2  tests/vectors/roots_directed.json
```

### Resultado real da execução

```text
Icarus Verilog version 14.0 (devel) (s20260301-394-g9edaf7b6a)
TEST-007 PASS directed=30 random=10000 seed=20261011 total=10030 valid=6255 invalid=3775 delta_roots_error=PASS
testbench/tb_quadratic_roots.v:140: $finish called at 10030000 (1ps)
process exit code: 0
```

Compilação -Wall sem warnings. Durante a execução, diagnóstico docker top confirmou vvp computando99,6%CPU; teste preservado integralmente até concluir. Nenhum erro funcional observado. Não houve modificações de fonte durante a simulação.

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW; TEST-007 PASS10030 vetores; evidências entregues ao Code Auditor.
