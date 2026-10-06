# TASK-013 — Verificação de sistema por simulação

## Objetivo

Executar os testes de integração/sistema em simulador e registrar evidências reprodutíveis.

## Status

DRAFT

## Requisitos relacionados

- REQ-015

## Decisões relacionadas

- DEC-005, DEC-020

## Dependências

- TASK-012 aprovada.
- Simulador/backend definido e versão registrada.

## Restrições aplicáveis

- Manter testbench separado do HDL sintetizável; registrar limitações.

## Arquivos permitidos

- A definir no planejamento desta TASK para testbenches e relatórios de simulação.

## Arquivos protegidos

- RTL aprovado, requisitos e decisões fora de mudança autorizada.

## Plano

- Executar TEST-010 e TEST-011 em simulador conforme cobertura acordada.
- Registrar comandos, versão, vetores, resultados, falhas e limitações.

## Critérios de aceite

- Evidências reprodutíveis ligam requisitos, testes e resultados de simulação.
- Casos bloqueados ou não cobertos estão identificados.

## Testes

- TEST-010 e TEST-011. TEST-012 é validação física (TASK-014); TEST-013 é revisão estática (TASK-017).

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- Backend e versão do simulador não estão registrados.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; delimitada à simulação; status DRAFT.
