# TASK-010 — Flags OV e ERR

## Objetivo

Implementar/verificar o escopo especificado abaixo segundo as decisões aprovadas.

## Status

APPROVED

## Requisitos relacionados

REQ-005/007/010/011

## Decisões relacionadas

DEC-001/003/012/030

## Dependências

loaded da TASK-002 e delta do contrato TASK-011; pode testar isoladamente antes da integração.

## Restrições aplicáveis

Aplicar `docs/regras.md` e `docs/agente_workflow.md`. Contratos matemáticos preservados; DUT estrutural, comportamento somente nos FF dedicados; nenhum novo estado sem decisão explícita. Delegação de 11/10/2026 substitui gates anteriores de consulta humana. READY exige brief e confirmação de contexto; APPROVED exige evidência real e auditoria independente.

## Arquivos permitidos

rtl/sinalizadores_status.v (módulo flag_ov_err); testbench/tb_status_flags.v

## Arquivos protegidos

Requisitos P0, RTL fora do escopo, pinagem oficial e contratos não revisados pelas decisões citadas.

## Plano e contrato fechado

`flag_ov_err(loaded,a signed8,delta signed18 → OV,ERR)`: OV=0; ERR=loaded AND (a zero OR delta negativo). Rede de portas combinacional, nenhum FF. Depois da captura de c, coeficientes e loaded permanecem estáveis até reset, assegurando a persistência de ERR sem latch. Z e C estão em TASK-018/019.

## Critérios de aceite e testes

TEST-009: antes/depois de loaded, a=0, delta<0/0/>0, persistência com mudanças de SW/seleção e limpeza no reset; OV=0.

## Implementation Brief

### Objetivo

Implementar OV constante0 e ERR combinacional qualificado por loaded, preservando persistência a partir dos coeficientes armazenados.

### Requisitos

REQ-005, REQ-007, REQ-010, REQ-011.

### Decisões aplicáveis

DEC-001, DEC-003, DEC-012, DEC-030.

### Módulos envolvidos

flag_ov_err no arquivo compartilhado sinalizadores_status.v.

### Interface

| Sinal | Direção/largura | Semântica |
|---|---|---|
| loaded | entrada1 | captura completa da TASK-002 |
| a | entrada signed8 | coeficiente armazenado |
| delta | entrada signed18 | discriminante da TASK-011 |
| OV | saída1 | constante0 conforme DEC-012 |
| ERR | saída1 | loaded E (a=0 OU delta[17]) |

Zero de a por árvore OR e inversão; ERR por portas. Persistência deriva de loaded e coeficientes estáveis após c; não criar latch/FF. Reset do core de captura limpa loaded e consequentemente ERR. Mudanças de SW/seleção não entram neste módulo e não podem limpar ERR.

### Clock e reset

Puramente combinacional, sem clock/reset, FF, latch ou armazenamento. Sinais de controle são entradas combinacionais.

### Restrições

DUT somente portas e instâncias explícitas de módulos fixos, fios/constantes/concatenações/seleções estáticas por assign. Sem FSM, always/initial, if/else, buf, for/generate/genvar, parâmetros, operadores aritméticos/condicionais ou begin/end. Testbenches separados podem usar referência aritmética, laços, case e estímulos, nunca if/else. Nenhuma alteração silenciosa de contratos ou pinagem. Comparar com referência independente, tratar X/Z como falha, registrar comandos, fontes explícitos, versões, contagens e hashes reais na própria TASK; logs temporários em /tmp, sem criar artefatos fora da lista autorizada.

### Arquivos protegidos

Todos os arquivos fora da lista permitida; incluindo RTL dependente já aprovado, decisões, requisitos, pinagem e top-level. Reutilização/leitura/compilação de dependências aprovadas não autoriza edição.

### Arquivos permitidos

rtl/sinalizadores_status.v, somente flag_ov_err e helpers privados necessários; testbench/tb_status_flags.v; resultados/auditoria na própria docs/tasks/TASK-010.md.

### Testes exigidos

TEST-009: matriz loaded0/1 × a zero/positivo/negativo × delta negativo/zero/positivo; OV sempre0. No teste de integração usar coefficient_input_core aprovado para carregar coeficientes, verificar erro após loaded, mudar SW/seleção mantendo coeficientes e comprovar retenção e limpeza por reset. TASK-011 pode alimentar delta no teste integrado, sem edição de fontes aprovados. Registrar exatamente cobertura isolada/integrada; não inferir teste físico.

### Casos de borda

Antes da carga, loaded0 com a0/delta negativo deve dar ERR0; após carga a0 ou delta negativo dá ERR1; a não zero e delta0 dá ERR0; a=-128/127, delta=-65536/81408; reset torna loaded0.

### Critérios de aceite

Equações e persistência verificadas conforme fontes já aprovadas; OV separado dos limites do display, zero estado e sintaxe permitida; TEST-009 PASS e auditoria independente sem HIGH/CRITICAL.

### Dependências

TASK-002 APPROVED para loaded e armazenamento; TASK-011 APPROVED para delta; TASK-004 APPROVED confirma y exato/OV0. Estados conferidos em11/10/2026.

### Pendências

Nenhuma escolha arquitetural aberta. Implementação, testes reais e auditoria de código permanecem obrigatórios.

### Resultado do Context Analyst — 11/10/2026

READY_FOR_IMPLEMENTATION. Brief derivado dos contratos em CONSENSUS e requisitos citados; interfaces, larguras, arquivos, testes e dependências conferidos. Nenhum RTL ou teste produzido nesta análise.

Coordenar edição de sinalizadores_status.v/tb_status_flags.v entre TASK-010/018/019: um implementer pode executar os três briefs aprovados em conjunto, mantendo evidência por módulo/TASK. Não sobrescrever módulos das outras tarefas nem realizar edições concorrentes do mesmo arquivo.

## Resultado da implementação

Implementado somente flag_ov_err em rtl/sinalizadores_status.v, por OR/NOT/AND e constante OV0; zero FF. tb_status_flags.v testa o módulo isolado e integrado com coefficient_input_core, quadratic_roots e result_select aprovados. Nenhum módulo Z/C antecipado.

## Resultado das ferramentas

TEST-009 subset TASK010 PASS: isolated3584, integrated53, failures0. Icarus14.0 (devel), s20260301-394-g9edaf7b6a, Docker hdlc/iverilog:latest; compilação -g2012 -Wall sem warnings, código final0. Tag mutável; versão/hash identificam os artefatos. Log bruto /tmp/task010.log. Nenhuma síntese ou validação física.

Isolado: todos256 valores de a × loaded0/1 × delta{-131072,-65536,-1,0,1,81408,131071}; delta=-1 testa a entrada signed18 do módulo de flag e não é alegado como discriminante alcançável. Integrado: captura de a0, erro por delta=-4, válido delta0;53 checks incluem carga parcial, retenção com16 mudançasSW/sel por cenário, reset e OV0. Raízes/seleção conectadas por portas normais, sem editar dependências.

```sh
tar -cf - rtl/sinalizadores_status.v rtl/entrada_coeficientes.v rtl/raizes_quadraticas.v rtl/somador_completo.v rtl/somador_subtrator.v rtl/multiplicadores.v rtl/raiz_quadrada_u17.v rtl/divisor_9_por_8.v rtl/seletor_resultado.v testbench/tb_status_flags.v | docker run --rm -i hdlc/iverilog:latest sh -c 'mkdir -p /tmp/work; cd /tmp/work; tar -xf -; iverilog -V; iverilog -g2012 -Wall -s tb_status_flags -o /tmp/task010.vvp rtl/sinalizadores_status.v rtl/entrada_coeficientes.v rtl/raizes_quadraticas.v rtl/somador_completo.v rtl/somador_subtrator.v rtl/multiplicadores.v rtl/raiz_quadrada_u17.v rtl/divisor_9_por_8.v rtl/seletor_resultado.v testbench/tb_status_flags.v && vvp /tmp/task010.vvp' > /tmp/task010.log 2>&1
```

```text
TEST-009 TASK010 PASS isolated=3584 integrated=53 failures=0
testbench/tb_status_flags.v:99: $finish called at 7340000 (1ps)
```

SHA-256 dos artefatos executados:

```text
716dc3da17d4eae30af99897fba31741bd4418db3217b7e8c63878d82176353c  rtl/sinalizadores_status.v
b83d645e41ca77f69daecbeb4ddb27e4560cc6a6e9137d26b7f7b077b6f0801c  rtl/entrada_coeficientes.v
4a3ea3a69479a724da17adf1f26c99397d6f7ff8d5e3d9844bba25993392c03e  rtl/raizes_quadraticas.v
0e9e393098a238cf0e5992a187834922fea4506eea13d4cdc635debf7376098e  rtl/somador_completo.v
fad812f3d306bc60b327a464946f96a2915c28f0dbb44b01a782d212dc75da3a  rtl/somador_subtrator.v
95d8de13e7cab690e72544c5b4c89efe7c956f46eadcc714a112f80123ddc371  rtl/multiplicadores.v
9c2dd06c7db0ec74226f4911130739cc8862c1efa46ddad6965b507858aeb2c9  rtl/raiz_quadrada_u17.v
3c78a3f6df23183f9e395cde079e9e2e074fad85cd5ae5e1643d10a2690783cb  rtl/divisor_9_por_8.v
1c0966845e4d864e72ea9f1aa0ac4ff627eb61ab614a2573457e48a1ab593f23  rtl/seletor_resultado.v
5d6334295cc2a2197f4b892183939f844a4ff2be0e2829141657cd4dd9faf566  testbench/tb_status_flags.v
63043ad56860ee34278ce809aa09d97696f08ccd068211437651fa0460bd81a0  /tmp/task010.log
```

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo 1, 11/10/2026.** Gate 1 PASS: flag_ov_err implementa somente portas e OV constante, sem FF/latch/comportamento proibido ou alterações de contrato. Gate 2 PASS: equação ERR=loaded AND (a0 OR delta17) corresponde DEC-030; teste independente cobre todos256 a, duas cargas e sete discriminantes signed18 (3584 casos), com 53 verificações integradas dos cores aprovados: carga parcial não ativa erro, a0 e delta negativo persistem diante de SW/seleção, reset limpa loaded/ERR e OV permanece0. Log final PASS e hashes atuais de DUT/TB conferidos. Gate 3 PASS: portas/formato compatíveis, persistência aproveita coeficientes/progresso existentes sem estado extra; TASK-018/019 não incluídas nesta implementação. Nenhum finding. Sem reexecução desnecessária; validação física/síntese futuras.

## Pendências de execução

Nenhuma pendência desta implementação: TEST-009 subset010 e auditoria independente aprovados. Flags Z/C, integração top-level, síntese e placa permanecem nas tarefas próprias.

## Histórico

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW. TEST-009 subset010 PASS,3584 isolados+53 integrados. Auditoria independente pendente; fontes congeladas.

- 2026-10-11 — Context Analyst conferiu contratos/dependências e registrou Implementation Brief completo; PLANNED → READY. Nenhuma implementação/teste antecipado.

- 2026-10-06 — TASK candidata criada na Sprint 0; separada de Z/C; status PLANNED.
- 2026-10-11 — Contratos, arquivos e critérios fechados sob delegação em DEC-030/031; planejamento reconciliado, sem declarar implementação ou testes.
