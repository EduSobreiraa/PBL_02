# TASK-018 — Flag Z do valor selecionado

## Objetivo

Implementar/verificar o escopo especificado abaixo segundo as decisões aprovadas.

## Status

APPROVED

## Requisitos relacionados

REQ-009/010

## Decisões relacionadas

DEC-011/029/030

## Dependências

Contrato value signed23 e seletor decidido em TASK-006; teste isolado permitido.

## Restrições aplicáveis

Aplicar `docs/regras.md` e `docs/agente_workflow.md`. Contratos matemáticos preservados; DUT estrutural, comportamento somente nos FF dedicados; nenhum novo estado sem decisão explícita. Delegação de 11/10/2026 substitui gates anteriores de consulta humana. READY exige brief e confirmação de contexto; APPROVED exige evidência real e auditoria independente.

## Arquivos permitidos

rtl/status_flags.v (módulo flag_z); testbench/tb_status_flags.v

## Arquivos protegidos

Requisitos P0, RTL fora do escopo, pinagem oficial e contratos não revisados pelas decisões citadas.

## Plano e contrato fechado

`flag_z(value signed23,sel[1:0],ERR → Z)`: detectar zero por OR/inversão e mascarar somente quando raiz selecionada sob ERR. Não qualificar Z por loaded. Excesso visual não altera Z; nenhum armazenamento.

## Critérios de aceite e testes

TEST-009: zero/não zero nas quatro seleções, raiz inválida, ERR com x/y selecionados, valores que excedem display.

## Implementation Brief

### Objetivo

Implementar Z do valor selecionado, mascarando raízes inválidas.

### Requisitos

REQ-009, REQ-010.

### Decisões aplicáveis

DEC-011, DEC-029, DEC-030.

### Módulos envolvidos

flag_z no arquivo compartilhado status_flags.v.

### Interface

| Sinal | Direção/largura | Semântica |
|---|---|---|
| value | entrada signed23 | valor após seletor |
| sel | entrada unsigned2 | 00=x,01=y,10=x1,11=x2 |
| ERR | entrada1 | raiz inválida |
| Z | saída1 | value=0 E NÃO(sel[1] E ERR) |

Detectar zero por OR/inversão. Sem entrada loaded ou limitação decimal; para x/y, ERR não mascara Z. Traços por excesso visual não mudam a semântica numérica.

### Clock e reset

Puramente combinacional, sem clock/reset, FF, latch ou armazenamento. Sinais de controle são entradas combinacionais.

### Restrições

DUT somente portas e instâncias explícitas de módulos fixos, fios/constantes/concatenações/seleções estáticas por assign. Sem FSM, always/initial, if/else, buf, for/generate/genvar, parâmetros, operadores aritméticos/condicionais ou begin/end. Testbenches separados podem usar referência aritmética, laços, case e estímulos, nunca if/else. Nenhuma alteração silenciosa de contratos ou pinagem. Comparar com referência independente, tratar X/Z como falha, registrar comandos, fontes explícitos, versões, contagens e hashes reais na própria TASK; logs temporários em /tmp, sem criar artefatos fora da lista autorizada.

### Arquivos protegidos

Todos os arquivos fora da lista permitida; incluindo RTL dependente já aprovado, decisões, requisitos, pinagem e top-level. Reutilização/leitura/compilação de dependências aprovadas não autoriza edição.

### Arquivos permitidos

rtl/status_flags.v, somente flag_z e helpers privados necessários; testbench/tb_status_flags.v; resultados/auditoria na própria docs/tasks/TASK-018.md.

### Testes exigidos

TEST-009: quatro seleções × ERR0/1 × value zero/não zero, sinais e fronteiras; testar zero e padrões one-hot em todos23 bits para observar cada entrada do detector. Referência independente no testbench. Compilar tb_status_flags com fontes explicitamente listados.

### Casos de borda

value0 para x/y com ERR1 mantém Z1; value0 para raiz com ERR1 força Z0; valores±1, -4194304,4194303,1000000 e -100000 dão Z0 mesmo fora da faixa visual.

### Critérios de aceite

Zero e máscara corretos em todas seleções, sem qualificação loaded, zero armazenamento; TEST-009 PASS e auditor independente sem HIGH/CRITICAL.

### Dependências

Contrato value/sel definido na TASK-006/DEC-030. Implementação/teste isolado autorizado independentemente de TASK-006; integração posterior requer seletor aprovado. TASK-004/011 APPROVED fornecem formatos.

### Pendências

Nenhuma escolha arquitetural aberta. Implementação, testes reais e auditoria de código permanecem obrigatórios.

### Resultado do Context Analyst — 11/10/2026

READY_FOR_IMPLEMENTATION. Brief derivado dos contratos em CONSENSUS e requisitos citados; interfaces, larguras, arquivos, testes e dependências conferidos. Nenhum RTL ou teste produzido nesta análise.

Coordenar edição de status_flags.v/tb_status_flags.v entre TASK-010/018/019: um implementer pode executar os três briefs aprovados em conjunto, mantendo evidência por módulo/TASK. Não sobrescrever módulos das outras tarefas nem realizar edições concorrentes do mesmo arquivo.

## Resultado da implementação

Adicionado somente flag_z ao status_flags.v: redução OR de23 bits, inversões e máscara de raiz inválida por portas, zero FF. flag_ov_err e top tb_status_flags de TASK010 foram preservados textualmente; teste018 em top separado tb_flag_z no mesmo arquivo permitido.

## Resultado das ferramentas

TEST-009 subset TASK018 PASS240 checks, failures0. Icarus14.0 (devel) s20260301-394-g9edaf7b6a via Docker hdlc/iverilog:latest, -Wall sem warnings, exit0. A tag é mutável; versão e hashes abaixo identificam execução. Log bruto/tmp/task018.log. Nenhuma síntese/placa realizada.

Cobertura: quatro seleções × ERR0/1 ×30 padrões: zero,±1, extremos signed23,1000000,-100000 e23 padrões one-hot. Referência independente testa igualdade inteira e seleção; comparação case de quatro estados rejeita X/Z. Z mantém valor correto sob ERR com x/y e mascara somente raízes; não há entrada loaded nem limite visual no módulo.

```sh
tar -cf - rtl/status_flags.v testbench/tb_status_flags.v | docker run --rm -i hdlc/iverilog:latest sh -c 'mkdir -p /tmp/work; cd /tmp/work; tar -xf -; iverilog -V; iverilog -g2012 -Wall -s tb_flag_z -o /tmp/task018.vvp rtl/status_flags.v testbench/tb_status_flags.v && vvp /tmp/task018.vvp' > /tmp/task018.log 2>&1
```

```text
TEST-009 TASK018 PASS checks=240 failures=0
testbench/tb_status_flags.v:142: $finish called at 240000 (1ps)
```

SHA-256 dos artefatos executados:

```text
ed817cd55b6c66b0585e9432842c15dcf678e40deea1e9888d3cca7d838372e3  rtl/status_flags.v
4e06a4b69a2e03119eab33891019cbf4cc771112ea38d8b71830432fdfe36acb  testbench/tb_status_flags.v
8d74fd3d5606ceb738757687f642a58e72b245897e5901e4f9d547555680260c  /tmp/task018.log
```

## Resultado da revisão

**APPROVED — Code Auditor independente, ciclo 1, 11/10/2026.** Gate 1 PASS: redução OR explícita dos23 bits, inversões e máscara por portas; zero FF/comportamento e interface preservada. Gate 2 PASS: Z indica zero e é suprimida somente em sel[1] AND ERR, sem loaded/faixa decimal; teste independente cobre240 combinações, inclusive todos23 bits isolados, sinais/extremos, quatro seleções e ERR0/1, rejeitando X/Z. Log final PASS240 e hashes de DUT/TB conferidos. Gate 3 PASS: módulo e teste010 mantidos, top018 separado e contratos DEC-029/030 atendidos; nenhuma edição de dependências ou pinagem. Nenhum finding. Sem reexecução desnecessária; síntese/placa futuras.

## Pendências de execução

Nenhuma pendência desta implementação: TEST-009 subset018 e auditoria independente aprovados. TASK-019 e integração/top-level permanecem independentes; síntese/placa futuras.

## Histórico

- 2026-10-11 — READY → IMPLEMENTING → IMPLEMENTED → TESTING → TESTED → REVIEW; TEST-009 subset018 PASS240 checks. Fontes congelados para auditoria; módulos010 preservados.

- 2026-10-11 — Context Analyst conferiu contratos/dependências e registrou Implementation Brief completo; PLANNED → READY. Nenhuma implementação/teste antecipado.

- 2026-10-06 — TASK candidata criada na Sprint 0; status BLOCKED por pendência de ratificação da semântica de Z.
- 2026-10-09 — Semântica de Z e C ratificada em DEC-029; TASK passa a PLANNED. A rota estrutural de C segue como gate técnico em TASK-019, sem reabrir a decisão semântica.
- 2026-10-11 — Contratos, arquivos e critérios fechados sob delegação em DEC-030/031; planejamento reconciliado, sem declarar implementação ou testes.
