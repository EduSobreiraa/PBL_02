# TASK-012 — Integração do top-level

## Objetivo

Integrar armazenamento, caminhos de cálculo, seleção, apresentação e sinais de status no `top_module` da DE10-Lite.

## Status

DRAFT

## Requisitos relacionados

- REQ-001–REQ-011, REQ-013, REQ-014

## Decisões relacionadas

- DEC-003, DEC-008–DEC-019

## Dependências

- TASK-001 e revisão humana da baseline.
- TASKs dos blocos integrados aprovadas, ou bloqueios isolados e declarados fora dos casos cobertos.
- Contrato do top-level e baseline de pinagem conforme hardware/DEC-018.

## Restrições aplicáveis

- Preservar as interfaces externas acordadas e pin assignments autorizados.
- Sem FSM, `buf`, loops/geração ou comportamento não autorizado.

## Arquivos permitidos

- A definir após inventário do RTL e contrato do top-level.

## Arquivos protegidos

- Requisitos, decisões e pin assignments; código fora do escopo aprovado.

## Plano

- Planejar instâncias e conectividade a partir dos contratos revisados, sem redefinir interfaces.
- Validar fluxo de carga, seleção, cálculo e apresentação.

## Critérios de aceite

- Conectividade e larguras coerentes com as interfaces aprovadas.
- TEST-010/011 cobrem caminhos disponíveis, explicitando casos ainda bloqueados.

## Testes

- TEST-010 e TEST-011; revisão estática TEST-013 em TASK-017.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- TASKs dependentes e interfaces finais ainda não foram aprovadas.
- QSF só pode ser fechado após top-level e pinos revisados.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
