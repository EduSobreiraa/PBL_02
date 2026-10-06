# TASK-007 — Unidade estrutural de multiplicação

## Objetivo

Planejar e implementar a unidade estrutural de multiplicação signed para os produtos usados pelos caminhos de `y` e das raízes.

## Status

DRAFT

## Requisitos relacionados

- REQ-005, REQ-007, REQ-008, REQ-011

## Decisões relacionadas

- DEC-012, DEC-013, DEC-014

## Dependências

- TASK-001 e revisão humana da baseline.
- Contrato de operandos, produto, extensão de sinal e consumidores especificado antes de READY.

## Restrições aplicáveis

- Implementação estrutural; sem FSM, `buf`, loops/geração ou comportamento não autorizado.
- Não inferir larguras nem algoritmo a partir de módulos legados do PBL1.

## Arquivos permitidos

- A definir no planejamento desta TASK após inventário do RTL.

## Arquivos protegidos

- Interfaces, requisitos, decisões e arquivos fora do escopo aprovado.

## Plano

- Especificar os casos/formatos necessários ao caminho de `y` e ao de raízes sem ampliar os contratos aprovados.
- Planejar testes independentes para operandos signed e limites dos produtos usados.

## Critérios de aceite

- Contrato de largura/formato final explícito.
- Produto corresponde à referência para os vetores signed de fronteira definidos em TEST-003.

## Testes

- TEST-003; integração conforme TEST-006/007.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- Não READY enquanto larguras, interface e vetores não estiverem especificados.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
