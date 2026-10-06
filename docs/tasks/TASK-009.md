# TASK-009 — Unidade estrutural de divisão

## Objetivo

Planejar e implementar a unidade estrutural de divisão usada no cálculo das raízes.

## Status

BLOCKED

## Requisitos relacionados

- REQ-005, REQ-006, REQ-008, REQ-011

## Decisões relacionadas

- DEC-007, DEC-013, DEC-016, DEC-020

## Dependências

- TASK-001 e revisão humana da baseline.
- Contrato de numerador, denominador, quociente e condição de divisão inválida.
- Evidência PEN-019 para liberar o uso da precisão F=16 no caminho de raízes.

## Restrições aplicáveis

- Implementação estrutural, sem FSM, `buf`, loops/geração ou comportamento não autorizado.
- Não inferir formato de quociente nem algoritmo de divisão.

## Arquivos permitidos

- A definir após inventário do RTL e formalização do contrato.

## Arquivos protegidos

- Requisitos e decisões; pin assignments e arquivos fora do escopo.

## Plano

- Especificar sinais, formatos e condições de domínio antes de READY.
- Comparar sinais, resto/quociente e limites com uma referência independente.

## Critérios de aceite

- Contrato numérico final documentado.
- Resultados correspondem à referência nos vetores aprovados, incluindo divisor zero e limites.

## Testes

- TEST-005; cadeia de raízes em TEST-007.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- PEN-019 bloqueia liberar/validar a precisão candidata F=16.
- Formato, larguras e algoritmo permanecem sem especificação suficiente.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status BLOCKED.
