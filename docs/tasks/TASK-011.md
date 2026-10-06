# TASK-011 — Composição do caminho de discriminante e raízes

## Objetivo

Compor as unidades aprovadas para calcular `Δ`, validar o domínio e produzir `x₁` e `x₂`.

## Status

BLOCKED

## Requisitos relacionados

- REQ-005, REQ-006, REQ-008, REQ-011

## Decisões relacionadas

- DEC-001, DEC-007, DEC-013, DEC-016, DEC-020

## Dependências

- TASK-001 e revisão humana da baseline.
- TASK-003, TASK-007, TASK-008 e TASK-009 aprovadas.
- TASK-005 concluída com evidência PEN-019 registrada, validando F=16 ou registrando decisão revisada pelo fluxo apropriado.

## Restrições aplicáveis

- Caminho combinacional estrutural; sem FSM, `buf`, loops/geração ou comportamento não autorizado.
- `a=0` ou `Δ<0` ativa ERR conforme DEC-001; não declarar as raízes válidas nesses casos.
- Manter explícita a exceção autorizada para arredondamento final (DEC-007) sem alterar o texto P0 de REQ-006.

## Arquivos permitidos

- A definir no planejamento após inventário do RTL e contratos das unidades.

## Arquivos protegidos

- Requisitos e decisões; interfaces não aprovadas; pin assignments e arquivos fora do escopo.

## Plano

- Documentar larguras e conexões a partir dos contratos aprovados.
- Comparar casos de domínio, sinais e arredondamento com referência independente e plano DEC-020.

## Critérios de aceite

- Casos `a=0`, `Δ<0`, `Δ=0`, `Δ>0`, sinais e limites atendem decisões.
- ERR mantém/limpa comportamento conforme DEC-001.
- Evidência da precisão usada está registrada.

## Testes

- TEST-007 e vetores/comparação exaustiva definidos em DEC-020.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- PEN-019 impede liberar F=16 sem evidência registrada em TASK-005.
- Não READY enquanto os contratos ou os resultados de validação numérica estiverem pendentes.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status BLOCKED.
