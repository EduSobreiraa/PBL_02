# Plano de sprints — PBL02

Este plano organiza a implementação futura; não aprova arquitetura adicional nem inicia código. As sprints são marcos de entrega, sem estimativa de duração. Cada unidade de implementação deverá ser detalhada em uma TASK `docs/tasks/TASK-XXX.md`, conforme `docs/agente_workflow.md`, antes de entrar em READY.

## Ordem e dependências

| Sprint | Entrega principal | Pré-requisito | Estado inicial |
|---|---|---|---|
| 0 — Baseline e preparação | Documentação revisada e plano de tarefas pronto | Nenhum; é a sprint preparatória | Backlog aprovado; revisão humana ainda necessária para liberar implementação |
| 1 — Clock, reset e armazenamento | Captura sincronizada e armazenamento de `a`, `b`, `c` | Sprint 0 concluída, baseline revisada e TASKs READY | Aguardando Sprint 0 e revisão humana |
| 2 — Aritmética e caminho de `y` | Unidades estruturais e cálculo de `y` | Sprint 0 concluída, baseline revisada; larguras/interfaces em TASKs | Planejada, depende de especificação revisada |
| 3 — Discriminante e raízes | Caminho estrutural das raízes | Sprint 0 concluída, baseline revisada; evidência PEN-019 registrada e aprovada | Bloqueada por PEN-019 |
| 4 — Seleção, displays e flags | Saída decimal, seleção e LEDs | Sprints 1–3 conforme dependências; decisão de C para fechar LED C | Parcialmente bloqueada por PEN-004 |
| 5 — Integração, simulação e Quartus | Top-level integrado, evidências de simulação e síntese | Sprints 1–4; interfaces finais e ferramentas definidas | Planejada |
| 6 — Placa e entrega | Validação física e documentação final | TASK-015 concluída; TASK-014 executada; resultados de TASK-013/014/015 disponíveis para TASK-016 | Planejada |

## Backlog inicial da Sprint 0

| TASK | Escopo | Situação inicial |
|---|---|---|
| TASK-002 | Sincronização, reset e armazenamento `a`, `b`, `c` | BLOCKED por PEN-021 até contrato interno ser decidido |
| TASK-003 | Soma/subtração estrutural | DRAFT; contrato de largura/flags precisa ser detalhado |
| TASK-007 | Multiplicação estrutural | DRAFT; contrato de larguras/formato precisa ser detalhado |
| TASK-004 | Caminho combinacional de `y` | DRAFT; depende das unidades e dos intermediários especificados |
| TASK-005 | Evidência numérica de F=16 | PLANNED; executar o plano DEC-020 e registrar PEN-019 |
| TASK-008 / TASK-009 | Raiz quadrada / divisão | BLOCKED; contratos numéricos e evidência PEN-019 |
| TASK-011 | Composição de discriminante e raízes | BLOCKED; depende das unidades e TASK-005 |
| TASK-006 | Seleção e apresentação decimal | PLANNED; interfaces de resultado precisam ser confirmadas |
| TASK-010 | Flags OV e ERR nos LEDs | PLANNED; independentes de PEN-004 |
| TASK-012 | Integração do top-level | DRAFT; depende dos blocos e interfaces aprovados |
| TASK-013 | Verificação de sistema por simulação | DRAFT; depende da integração e da ferramenta de simulação definida |
| TASK-015 | Síntese e compilação Quartus | DRAFT; depende da integração e da baseline de pinos |
| TASK-014 | Validação física na placa | DRAFT; depende de síntese e disponibilidade da DE10-Lite |
| TASK-016 | Relatório e entrega documental | DRAFT; depende das evidências de simulação, síntese e placa |
| TASK-017 | Revisão estática de conformidade HDL | DRAFT; revisar artefatos RTL das TASKs de implementação |
| TASK-018 | Flag Z | BLOCKED; ratificação da proposta de PEN-004 necessária |
| TASK-019 | Flag C | BLOCKED por PEN-004; origem e comportamento ainda sem decisão |

## Regras de execução

- O plano não substitui TASKs: cada módulo/unidade verificável deve ter TASK própria e critérios objetivos.
- A Sprint 0 pode produzir documentação e TASKs antes da revisão humana; não liberar TASKs de implementação dependentes nem iniciar RTL/síntese antes da revisão da baseline, conforme `docs/planejamento.md`.
- Fechar somente as pendências que bloqueiam a TASK específica. PEN-004 bloqueia a semântica/aceite de C, não deve bloquear trabalho independente. PEN-019 bloqueia validar e liberar a precisão F=16 para o caminho de raízes.
- Respeitar `docs/regras.md` e `docs/convencoes_verilog.md`: lógica estrutural, sem FSM, `buf`, loops/geração ou comportamento fora da exceção de DFF autorizada.
- Usar os critérios e casos de `docs/verificacao.md`; registrar ferramentas, resultados e warnings nas TASKs.
- Uma sprint termina quando seus critérios são evidenciados e as TASKs correspondentes chegam a APPROVED; impedimentos permanecem explícitos, sem aprovação parcial disfarçada.

## Referências

- [Planejamento geral](../planejamento.md)
- [Requisitos](../requisitos.md)
- [Arquitetura](../arquitetura.md)
- [Módulos candidatos](../modulos.md)
- [Interfaces](../interfaces.md)
- [Pendências](../pendencias.md)
- [Plano de verificação](../verificacao.md)
- [Workflow de agentes](../agente_workflow.md)
