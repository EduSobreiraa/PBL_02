# TASK-006 — Seletor de resultado e apresentação decimal

## Objetivo

Planejar e implementar a seleção contínua de `x`, `y`, `x₁` ou `x₂` e a apresentação decimal signed nos displays.

## Status

PLANNED

## Requisitos relacionados

- REQ-004, REQ-009, REQ-011

## Decisões relacionadas

- DEC-011, DEC-017, DEC-019

## Dependências

- TASK-001 e revisão humana da baseline.
- Contratos de resultados dos caminhos de `y` e raízes.
- Nenhuma dependência de TASK-010 para validar seleção/conversão; a integração de flags é tratada separadamente.

## Restrições aplicáveis

- Saída contínua e decimal com sinal; padrões dos segmentos ativos baixos.
- Separar overflow de apresentação de OV aritmético.
- Respeitar restrições estruturais e não alterar pin assignments.

## Arquivos permitidos

- A definir no planejamento para seletor e conversão/display somente; flags são escopo separado em TASK-010.

## Arquivos protegidos

- Interfaces físicas aprovadas, decisões e pin assignments.

## Plano

- Definir interfaces finais com TASKs de resultado; manter apresentação de raízes bloqueada enquanto TASK-011 estiver bloqueada.

## Critérios de aceite

- TEST-008 cobre seleção, conversão, sinal, limites dos displays e fallback.

## Testes

- TEST-008; integração posterior TEST-012.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- Contrato dos resultados e portas de apresentação deve ser definido nesta TASK sem inferência.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status PLANNED.
