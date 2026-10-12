# Plano de sprints — PBL02

Baseline DEC-030/031, 11/10/2026. O responsável delegou o fechamento das escolhas aos agentes. Contratos/algoritmos estão decididos; as próximas sprints produzem código e evidências. Não se repete ratificação humana de escolhas compatíveis.

| Sprint | Entrega | Dependência de execução | Estado |
|---|---|---|---|
| 0 — Baseline | Requisitos e backlog | Concluída anteriormente | Concluída |
| 1 — Entrada | Captura/reset e coeficientes | Baseline aprovada; extensão loaded na Sprint2 | Concluída, inclusive extensão privada loaded testada/auditada |
| Fechamento único | DEC030/031, contratos e briefs | Architect → Reviewer ACCEPT | Concluída; consenso e auditoria documental |
| 2 — Aritmética/y | TASK002,003,007,004 | Executar003 antes de007;004 após003/007 | Concluída: TASK002/003/007/004 APPROVED |
| 3 — Raízes | TASK005,008,009,011 | 005/008/009/011 aprovadas | Concluída, evidências e auditorias registradas |
| 4 — Apresentação/flags | TASK006,010,018,019 | TASK006/010/018/019 aprovadas | Concluída, simulações e auditorias independentes registradas |
| 5 — Integração/Quartus | TASK012,013,017,015 | TASK012/013/017/015 aprovadas | Concluída: integração, simulação, auditoria estática e Quartus |
| 6 — Placa/entrega | TASK014,016 | Bitstream, placa e evidências; modelo oficial para entrega | Parcialmente preparada; BLOCKED por validação física e modelo oficial |

## Backlog e prontidão

| TASK | Escopo | Estado após fechamento |
|---|---|---|
| 002 | Core privado com loaded, preservar wrapper/31FF | APPROVED |
| 003 | Células e soma23/sub18 | APPROVED |
| 007 | Multiplicadores; u15 limitado ao domínio quadrático | APPROVED |
| 004 | Caminho y/OV/carry privado | APPROVED |
| 005 | Exaustão numérica independente do algoritmo exato | APPROVED; modelo software, RTL ainda futuro |
| 008/009 | sqrt e divisão com resíduos | APPROVED |
| 011 | Discriminante/raízes e round exato | APPROVED |
| 006 | Seleção/display | APPROVED |
| 010/018/019 | OV/ERR, Z, C | APPROVED |
| 012 | Top-level | APPROVED |
| 013 | Simulação integrada | APPROVED |
| 017 | Auditoria estática | APPROVED |
| 015 | Síntese/Quartus | APPROVED; Quartus 25.1std.0, fitting e STA registrados |
| 014 | Validação na DE10-Lite | BLOCKED; procedimento pronto, execução e evidências físicas ainda necessárias |
| 016 | Relatório e entrega | BLOCKED; rascunho técnico pronto, modelo oficial e resultados físicos ainda necessários |

## Execução

Implementation Orchestrator → Context Analyst/brief → Implementer → ferramentas → Auditor. READY não significa implementado; APPROVED exige código, testes aplicáveis e auditoria. Compartilhamento de arquivos exige ordem, sem duas edições concorrentes nas células ou flags. Nenhuma FSM, if/else, buf, laço/generate ou comportamento fora dos FF no DUT. Repetições explícitas; assign apenas conexão estática conforme DEC030.

A prova DEC031 fecha escolha numérica; TASK005 e os testes reais continuam obrigatórios. Disponibilidade da placa, modelo do tutor e interpretação acadêmica não são fatos inferidos. Registro: `../pendencias.md`.

- [Sprint de fechamento](sprint-fechamento-decisoes.md)
- [Sprint 2](sprint-02-aritmetica-y.md)
- [Sprint 3](sprint-03-raizes.md)
- [Sprint 4](sprint-04-apresentacao-flags.md)
- [Sprint 5](sprint-05-integracao-quartus.md)
- [Sprint 6](sprint-06-placa-entrega.md)
- [Workflow](../agente_workflow.md)
