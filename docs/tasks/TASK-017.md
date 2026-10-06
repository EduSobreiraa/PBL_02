# TASK-017 — Revisão estática de conformidade HDL

## Objetivo

Revisar de forma independente o HDL e a integração quanto às restrições estruturais e documentar findings antes da aprovação/síntese.

## Status

DRAFT

## Requisitos relacionados

- REQ-008, REQ-011, REQ-013

## Decisões relacionadas

- DEC-014 e decisões de interface aplicáveis aos módulos revisados.

## Dependências

- TASKs de RTL incluídas na rodada de revisão em estado IMPLEMENTED/TESTED.
- Briefs, arquivos modificados e evidências correspondentes disponíveis ao Reviewer.

## Restrições aplicáveis

- Aplicar o Compliance Gate de `docs/agente_workflow.md` antes de avaliar integração.
- Revisor independente não implementa correções; findings retornam ao Implementer.

## Arquivos permitidos

- Seção de resultado de revisão nas TASKs auditadas; nenhum RTL é alterado pelo Reviewer.

## Arquivos protegidos

- RTL, interfaces e decisões durante a revisão; correções são tarefa do Implementer.

## Plano

- Inspecionar ausência de FSM, `buf`, loops/geração e comportamento não autorizado.
- Conferir operadores/estruturas, interfaces, larguras, escopo e hipóteses.
- Registrar APPROVED, REWORK, BLOCKED ou ESCALATE com evidências e severidade.

## Critérios de aceite

- TEST-013 executado e findings ligados a arquivos/localizações e requisitos/regras.
- Nenhum finding CRITICAL/HIGH aberto para liberar a síntese dos arquivos revisados.

## Testes

- TEST-013.

## Resultado da implementação

Não aplicável; tarefa de auditoria.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- O HDL a revisar ainda não foi implementado.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0 para separar TEST-013 da simulação; status DRAFT.
