# TASK-004 — Caminho combinacional de `y`

## Objetivo

Compor as unidades aritméticas aprovadas para calcular `y = ax² + bx + c` em complemento de dois signed de 23 bits.

## Status

DRAFT

## Requisitos relacionados

- REQ-003, REQ-007, REQ-008, REQ-011

## Decisões relacionadas

- DEC-009, DEC-011, DEC-012, DEC-013

## Dependências

- TASK-001 e revisão humana da baseline.
- TASK-003 e TASK-007 aprovadas para soma/subtração e multiplicação; o caminho `y` não depende das unidades de raiz quadrada/divisão.
- Contrato de larguras intermediárias, extensão de sinal e interface revisado.

## Restrições aplicáveis

- Datapath estrutural, combinacional após carga; sem FSM, `buf`, loops/geração ou comportamento proibido.
- Não confundir OV aritmético de 23 bits com overflow da apresentação decimal.

## Arquivos permitidos

- A definir após inventário do RTL e planejamento.

## Arquivos protegidos

- Interfaces, requisitos e decisões canônicas; pin assignments e RTL fora do escopo.

## Plano

- Especificar a composição e explicitar larguras intermediárias sem introduzir um algoritmo não aprovado.
- Preparar vetores independentes para extremos, sinais mistos e cancelamento.

## Critérios de aceite

- Saída signed de 23 bits corresponde à referência para todos os vetores definidos.
- OV segue DEC-012; integração com entradas `a`, `b`, `c` armazenadas e `x` atual.

## Testes

- TEST-006; integração em TEST-010/011.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- Não READY até largura/semântica de intermediários e interfaces estarem explícitas na TASK final.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
