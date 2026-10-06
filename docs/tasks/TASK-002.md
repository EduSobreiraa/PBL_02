# TASK-002 — Sincronização de controles e armazenamento de coeficientes

## Objetivo

Implementar o caminho sequencial de controles e o armazenamento de `a`, `b` e `c` após três capturas ordenadas.

## Status

BLOCKED

## Requisitos relacionados

- REQ-001, REQ-002, REQ-011

## Decisões relacionadas

- DEC-008, DEC-009, DEC-014, DEC-019

## Dependências

- TASK-001 e revisão humana da baseline.
- Contrato revisado para os sinais/portas internos e forma de instanciação do DFF.

## Restrições aplicáveis

- Sem FSM, `buf`, loops/geração ou comportamento fora da exceção autorizada para DFF.
- Não detectar carga incompleta ou captura excedente.

## Arquivos permitidos

- A definir no planejamento desta TASK, após identificação do layout RTL.

## Arquivos protegidos

- Documentos canônicos, pin assignments e RTL fora do escopo aprovado.

## Plano

- Planejar sincronização em duas etapas de KEY, evento único por pressão de KEY0, reset lógico síncrono e deslocador de três capturas a→b→c.
- Detalhar sinais, widths, arquivos, casos de teste e critérios antes de READY.

## Critérios de aceite

- A definir pelo Planner após confirmar o contrato e os arquivos envolvidos; cobrir reset, ordem, retenção e uma captura por pressão.

## Testes

- TEST-001; integração posterior em TEST-010 e TEST-012.

## Resultado da implementação

Não iniciado.

## Resultado das ferramentas

Não executado.

## Resultado da revisão

Pendente.

## Pendências

- Contrato de portas RTL e compatibilidade de síntese do DFF estrutural devem ser especificados/revisados na TASK antes de READY.
- DEC-023 deve fechar a fronteira interna mínima para a Sprint 1.
- Validação física posterior na TASK de placa.

## Histórico

- 2026-10-06 — TASK candidata criada na Sprint 0; status DRAFT.
- 2026-10-06 — Bloqueada até DEC-023 definir contrato interno suficiente para implementação e revisão.
