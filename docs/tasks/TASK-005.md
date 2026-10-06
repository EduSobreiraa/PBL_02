# TASK-005 — Evidência numérica da precisão F=16

## Objetivo

Executar e registrar a comparação exaustiva de raízes e os vetores dirigidos aprovados para validar ou refutar a precisão intermediária candidata F=16.

## Status

PLANNED

## Requisitos relacionados

- REQ-005, REQ-006, REQ-008, REQ-011

## Decisões relacionadas

- DEC-007, DEC-013, DEC-016, DEC-020

## Dependências

- TASK-001 e revisão humana da baseline antes de qualquer liberação de implementação dependente.
- Método e vetores de referência definidos em DEC-020.

## Restrições aplicáveis

- Comparação numérica independente; não alterar RTL nem requisitos/decisões.
- Se os resultados exigirem mudança de precisão ou arquitetura, encaminhar ao Decision Workflow.

## Arquivos permitidos

- Registros de cálculo/vetores a definir na TASK detalhada; não alterar arquivos RTL.

## Arquivos protegidos

- Requisitos e decisões; interfaces não aprovadas; pin assignments e código fora do escopo.

## Plano

- Executar a comparação aprovada em DEC-020 usando referência independente.
- Registrar método, casos, resultados e divergências para PEN-019.

## Critérios de aceite

- Resultados e método de DEC-020 executados e reproduzíveis; conclusão sobre F=16 registrada pelo processo apropriado.

## Testes

- Comparação exaustiva e vetores dirigidos conforme DEC-020.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- PEN-019: a evidência deve validar F=16 ou motivar revisão pelo Decision Workflow.
- Esta TASK não altera a arquitetura nem libera sozinha a implementação das raízes.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0 para produzir a evidência de PEN-019; status PLANNED.
