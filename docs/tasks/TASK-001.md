# TASK-001 — Revisar baseline e preparar backlog de implementação

## Objetivo

Executar a Sprint 0: preparar a rastreabilidade documental e decompor o trabalho futuro em TASKs pequenas, sem implementar RTL nem criar decisões técnicas.

## Status

APPROVED

## Requisitos relacionados

- REQ-001–REQ-016, somente para rastreabilidade do backlog.

## Decisões relacionadas

- DEC-001, DEC-003, DEC-007–DEC-021, distribuídas nas TASKs específicas conforme o escopo de cada uma; DEC-022 permanece ligada à fase de relatório conforme `docs/pendencias.md`.

## Dependências

- Plano de sprints em `docs/sprints/`.

## Restrições aplicáveis

- Não editar RTL, testbench, projeto Quartus ou pin assignments.
- Não resolver pendências técnicas por inferência nem alterar requisitos/decisões.
- Registrar blockers somente nas TASKs que dependem deles.
- Seguir o formato e os estados definidos em `docs/agente_workflow.md`.

## Arquivos permitidos

- `docs/tasks/TASK-*.md`
- `docs/sprints/README.md` e arquivos de sprint, somente para corrigir rastreabilidade desta decomposição.

## Arquivos protegidos

- RTL e testbenches existentes ou futuros.
- Requisitos, decisões e interfaces canônicas; só podem ser atualizados por processo apropriado e com aprovação correspondente.
- Arquivos Quartus e pin assignments.

## Plano

1. Mapear entregas das sprints a requisitos, decisões, testes e dependências documentadas.
2. Preparar TASKs candidatas com escopo pequeno, arquivos permitidos/protegidos e critérios de aceite objetivos.
3. Identificar TASKs que podem avançar e as que dependem de PEN-004, PEN-019 ou da revisão humana da baseline.
4. Registrar o parecer do Context Analyst sobre suficiência do contexto e blockers.
5. Manter TASKs não prontas em DRAFT/PLANNED/BLOCKED; nenhuma implementação começa nesta tarefa.

## Análise do Context Analyst

- **Classificação inicial:** BLOCKED para conclusão integral; a decomposição documental podia avançar.
- A revisão humana da baseline é gate para liberar implementação, não para produzir backlog.
- PEN-019 bloqueia liberar/validar F=16 e o caminho das raízes. PEN-004 afeta a semântica/aceite de C e deve ser isolada.
- Recomendada a divisão por unidade para manter os bloqueios locais; aplicada no backlog abaixo.
- **Parecer final:** a entrega documental da Sprint 0 pode ser concluída antes da aprovação humana da baseline; essa aprovação permanece gate para liberação de implementação.
- Ajustes recomendados pela análise/auditoria foram incorporados: TASK-005 separa a evidência PEN-019; flags Z/C e OV/ERR foram separadas; TEST-013 está em TASK-017; simulação, síntese, validação física e relatório estão em TASKs distintas.

## Backlog produzido

- TASK-002: sincronização, reset e armazenamento.
- TASK-003: soma/subtração estrutural.
- TASK-007: multiplicação estrutural.
- TASK-004: caminho de `y`.
- TASK-005: evidência numérica da precisão candidata F=16 (PEN-019).
- TASK-008: raiz quadrada; TASK-009: divisão; TASK-011: composição das raízes.
- TASK-006: seleção e apresentação decimal; TASK-010: flags OV/ERR; TASK-018: flag Z; TASK-019: flag C.
- TASK-012: integração top-level; TASK-013: simulação; TASK-015: síntese; TASK-014: validação física; TASK-016: relatório; TASK-017: revisão estática HDL.

Os estados, dependências, testes e arquivos de cada candidata estão registrados em `docs/tasks/TASK-*.md`. A revisão humana da baseline e a aprovação de contratos específicos ainda são necessárias antes de promover tarefas a READY.

## Critérios de aceite

- Backlog inicial cobre armazenamento/controle, unidades aritméticas e caminho de `y`, raízes, apresentação/flags, integração/verificação e validação física/entrega.
- Cada TASK candidata referencia requisitos e decisões relevantes sem alterar seu significado.
- Dependências e pendências estão explícitas; PEN-004 limita apenas tarefas de semântica/aceite de C e PEN-019 bloqueia validar F=16 e liberar o caminho de raízes.
- Revisão humana da baseline aparece como gate explícito para liberar tarefas de implementação dependentes; não é pré-requisito para concluir esta tarefa documental.
- Nenhum artefato de RTL, testbench ou Quartus é criado/modificado.

## Testes

- Revisão documental dos links, IDs e dependências das TASKs candidatas.
- Sem simulação, lint ou síntese: não há código nesta tarefa.

## Resultado da implementação

Backlog documental TASK-002 a TASK-019 produzido; nenhum RTL, testbench ou arquivo Quartus foi alterado.

## Resultado das ferramentas

Verificação manual de IDs, estados, dependências e divisão dos gates; nenhuma ferramenta de implementação executada.

## Resultado da revisão

APPROVED — auditoria documental independente confirmou a rastreabilidade e as dependências do backlog; sem findings pendentes.

## Pendências

- Aprovação humana da baseline documental antes de liberar TASKs de implementação dependentes (gate externo a esta TASK).
- Semântica/origem de C segue PEN-004.
- Evidência numérica para precisão F=16 segue PEN-019.

## Histórico

- 2026-10-06 — Criada como tarefa de planejamento da Sprint 0; status PLANNED.
- 2026-10-06 — Backlog inicial produzido; aprovação humana registrada como gate de liberação de implementação, não de conclusão documental.
- 2026-10-06 — Auditoria documental independente aprovada; TASK-001 concluída como entrega documental.
- 2026-10-06 — Responsável autorizou avançar para a Sprint 1; gate humano da baseline considerado atendido para esta sequência de trabalho.
