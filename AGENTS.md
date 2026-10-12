# PBL02 Agent Instructions

Leia `docs/regras.md` e `docs/agente_workflow.md` antes de atuar.

Quando a tarefa envolver resolução de pendências técnicas:

1. assuma o papel de Orchestrator;
2. leia agents/decision/orchestrator.md;
3. delegue propostas ao papel descrito em agents/decision/decision_architect.md;
4. delegue revisão independente ao papel descrito em agents/decision/decision_reviewer.md;
5. use docs/decisions/DEC-XXX.md como estado compartilhado;
6. permita no máximo 3 rodadas;
7. interrompa em CONSENSUS, BLOCKED ou ESCALATE;
8. não implemente Verilog durante o fluxo de decisão.

Use os arquivos em `docs/decisions/` como estado compartilhado. O arquivo de workflow existente chama-se `docs/agente_workflow.md` (não `docs/agent_workflow.md`).
## Tipos de workflow

Existem dois pipelines agentic distintos.

### Decision workflow

Utilizado para pendências e decisões arquiteturais.

Agentes:

- Decision Orchestrator
- Decision Architect
- Decision Reviewer

### Implementation workflow

Utilizado para TASKs de código em estado READY.

Agentes:

- Implementation Orchestrator
- Context Analyst
- Code Implementer
- Code Auditor

Nunca utilize o pipeline de implementação para resolver decisão arquitetural pendente.

Quando uma TASK de implementação revelar a necessidade de nova decisão, marque-a como BLOCKED ou ESCALATE e encaminhe a questão ao Decision Workflow.

## Autonomia delegada — 11/10/2026

O responsável autorizou fechar escolhas técnicas sem nova consulta, preservando requisitos, contratos matemáticos e restrições de sintaxe. Aplicar Architect → Reviewer (máximo três rodadas); após ACCEPT, Orchestrator registra decisão e atualiza documentos. Não exigir nova ratificação humana de escolhas compatíveis. Decisões podem revisar explicitamente contratos internos; alterações nunca são silenciosas. Evidência numérica, síntese e validação física continuam exigindo resultados reais. Nenhuma autorização permite afirmar aprovação do tutor ou testes não executados. Conflitos não resolvidos são registrados e isolados; continuar trabalho independente.
