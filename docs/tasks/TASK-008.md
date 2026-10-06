# TASK-008 — Unidade estrutural de raiz quadrada

## Objetivo

Planejar e implementar a unidade estrutural de raiz quadrada requerida pelo caminho das raízes.

## Status

BLOCKED

## Requisitos relacionados

- REQ-005, REQ-006, REQ-008, REQ-011

## Decisões relacionadas

- DEC-007, DEC-013, DEC-016, DEC-020

## Dependências

- TASK-001 e revisão humana da baseline.
- Contrato da raiz quadrada com formatos, larguras e condições de domínio.
- Evidência PEN-019 para liberar o uso da precisão F=16 no caminho de raízes.

## Restrições aplicáveis

- Implementação estrutural, sem FSM, `buf`, loops/geração ou comportamento não autorizado.
- Preservar a exceção de arredondamento de DEC-007 sem reescrever o requisito P0.

## Arquivos permitidos

- A definir após inventário do RTL e formalização do contrato.

## Arquivos protegidos

- Requisitos e decisões; pin assignments e arquivos fora do escopo.

## Plano

- Explicitar contrato de radicando e resultado sem presumir formato ainda não aprovado.
- Definir casos para quadrados perfeitos/não perfeitos e limites com referência independente.

## Critérios de aceite

- A definir após contrato numérico e evidência PEN-019.

## Testes

- TEST-004; cadeia de raízes em TEST-007.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- PEN-019 bloqueia liberar/validar a precisão candidata F=16.
- Contratos e algoritmos ainda não podem ser fixados por inferência.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status BLOCKED.
