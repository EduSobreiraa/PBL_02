# TASK-003 — Unidade estrutural de soma/subtração

## Objetivo

Planejar e implementar a unidade estrutural de soma/subtração usada pelos caminhos aritméticos do sistema.

## Status

DRAFT

## Requisitos relacionados

- REQ-005, REQ-007, REQ-008, REQ-011

## Decisões relacionadas

- DEC-012, DEC-013, DEC-014

## Dependências

- TASK-001 e revisão humana da baseline.
- Contrato desta unidade, com larguras e semânticas registradas antes de READY.

## Restrições aplicáveis

- Implementação estrutural; sem operadores ou construções não autorizados, FSM, `buf`, loops/geração.
- Não assumir semântica da flag C; ela pertence à PEN-004.

## Arquivos permitidos

- A definir no planejamento da unidade específica.

## Arquivos protegidos

- Interfaces aprovadas, documentos canônicos e arquivos fora do escopo da unidade.

## Plano

- Definir largura/formato dos operandos e resultado, e semântica de carry/overflow, sem fixar algoritmo ou portas por inferência.
- Associar a unidade aos consumidores e registrar vetores próprios.

## Critérios de aceite

- Definir após fechamento dos contratos; exigir testes de sinal e fronteira conforme TEST-002.

## Testes

- TEST-002, com vetores independentes e casos extremos.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- Larguras e interface desta unidade ainda precisam constar no contrato final antes de READY.
- PEN-004 bloqueia somente o aceite de C, não as operações aritméticas independentes dessa semântica.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
