# TASK-010 — Flags OV e ERR para os LEDs

## Objetivo

Planejar e implementar as flags OV e ERR conforme suas semânticas aprovadas e o mapeamento de LEDs documentado.

## Status

PLANNED

## Requisitos relacionados

- REQ-005, REQ-007, REQ-010, REQ-011

## Decisões relacionadas

- DEC-001, DEC-003, DEC-012

## Dependências

- TASK-001 e revisão humana da baseline.
- Sinais de status definidos nos caminhos relevantes.
- Sinais de domínio e OV disponíveis nos caminhos relevantes.

## Restrições aplicáveis

- ERR deve respeitar a condição e persistência de DEC-001; OV deve respeitar DEC-012.
- Não modificar pin assignments nem semânticas aprovadas.

## Arquivos permitidos

- A definir após inventário do RTL e definição do contrato de OV/ERR.

## Arquivos protegidos

- Requisitos, decisões e pin assignments; arquivos fora do escopo aprovado.

## Plano

- Especificar OV e ERR usando apenas condições acordadas em DEC-001/012.
- Z e C são tarefas separadas, pois suas definições estão em PEN-004.

## Critérios de aceite

- Os casos de OV/ERR de TEST-009 atendem DEC-001/012 e mapeiam as saídas correspondentes; casos de Z/C pertencem a TASK-018/019 e não são aceitos por esta tarefa.

## Testes

- Casos de OV/ERR em TEST-009; integração em TEST-011 apenas para essas flags.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- Não há blocker de PEN-004 para OV/ERR; veja TASK-018 (Z) e TASK-019 (C).

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; separada de Z/C; status PLANNED.
