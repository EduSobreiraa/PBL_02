# TASK-019 — Flag C e sua origem

## Objetivo

Planejar e implementar a flag C somente após definir qual operação/estágio fornece o carry e o valor fora desse resultado.

## Status

BLOCKED

## Requisitos relacionados

- REQ-010

## Decisões relacionadas

- DEC-003, DEC-015

## Dependências

- Resolução de PEN-004 por indicação da equipe/tutor registrada em decisão.
- Sinal do estágio definido e disponível no datapath aprovado.

## Restrições aplicáveis

- Não inferir estágio/origem do carry.
- Não tratar carry-out como overflow signed nem reutilizar OV.

## Arquivos permitidos

- A definir após decisão de origem, comportamento e inventário do RTL.

## Arquivos protegidos

- Requisitos, decisões e pin assignments; arquivos fora do escopo aprovado.

## Plano

- Após a decisão, documentar a interface de C e comportamento quando a operação não corresponder à seleção exibida.
- Validar casos de carry/no-carry e o mapeamento LEDR2.

## Critérios de aceite

- TEST-009 e integração demonstram a semântica aprovada de C.

## Testes

- TEST-009 e TEST-011.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- PEN-004 continua BLOCKED; aguardar informação da equipe/tutor e decisão registrada.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status BLOCKED por PEN-004.
