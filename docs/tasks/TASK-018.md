# TASK-018 — Flag Z do valor selecionado

## Objetivo

Planejar e implementar Z como indicador de que o resultado selecionado é zero, se essa proposta for ratificada.

## Status

BLOCKED

## Requisitos relacionados

- REQ-009, REQ-010

## Decisões relacionadas

- DEC-011, DEC-015

## Dependências

- Ratificação da proposta de Z registrada em DEC-015/PEN-004.
- Resultados de `x`, `y`, `x₁`, `x₂` e seletor disponíveis.

## Restrições aplicáveis

- Não converter uma proposta em decisão aprovada por inferência.
- Comparar o valor lógico selecionado, respeitando a largura signed aprovada.

## Arquivos permitidos

- A definir após ratificação e inventário do RTL.

## Arquivos protegidos

- Requisitos, decisões e interfaces aprovadas; arquivos fora do escopo.

## Plano

- Após a ratificação, detalhar contrato de largura/seleção e casos de teste para zero e não zero em cada seleção.

## Critérios de aceite

- TEST-009 demonstra Z para todas as seleções conforme semântica ratificada.

## Testes

- TEST-009; integração em TEST-011/012.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- Proposta de Z consta como aceita pelo Reviewer, mas PEN-004/DEC-015 permanece BLOCKED no conjunto; aguardar ratificação explícita antes de READY.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status BLOCKED por pendência de ratificação da semântica de Z.
