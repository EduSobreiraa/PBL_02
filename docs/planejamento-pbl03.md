# Planejamento de implementação do PBL03

Este plano leva o PBL03 da base atual até uma entrega funcional e verificável na DE10-Lite. Ele usa as TASKs PBL03 em `docs/tasks/`; `docs/planejamento.md` continua descrevendo o PBL02.

As TASKs 025-032 estão aprovadas. A TASK-034 é a próxima tarefa da sequência. As TASKs 034-041 abaixo são planejamento, não autorização para iniciar implementação. Cada uma passa pelo workflow de implementação e só fica `READY` depois da análise de contexto.

## Como ler este plano

Cada TASK é uma unidade de implementação com aceite verificável. Execute as TASKs na ordem das dependências e registre evidências antes de avançar.

## Como executar

1. Escolha a próxima TASK sem dependências pendentes.
2. Siga os quatro papéis listados em `docs/agente_workflow.md`. Use Implementation Orchestrator, Context Analyst, Code Implementer e Code Auditor.
3. Se a análise encontrar uma decisão técnica aberta, marque a TASK `BLOCKED` ou `ESCALATE` e encaminhe a questão ao Decision Workflow. Não escolha um contrato silenciosamente.
4. Não marque uma TASK como aprovada sem evidência real dos critérios de aceite. Icarus/VPI verifica comportamento; Quartus verifica síntese e temporização; a DE10-Lite verifica a operação física.
5. Atualize o status e os resultados na TASK correspondente. Mantenha `REGRAS.md` como contrato PBL03 e preserve o PBL02 e `vendor/vga/vga_sync.v`.

O plano usa TASKs rastreáveis em vez de PRs. O repositório registra implementação, dependências e evidências em `docs/tasks/`. Gates de screenshots de UI e métricas de performance de software não se aplicam. A visualização real é o sinal VGA na simulação e na placa.

## Sequência de trabalho

| Fase | TASKs | Resultado verificável |
|---|---|---|
| Base funcional | 025-027 | Hierarquia PBL03, entrada de seis coeficientes e datapath aritmético standalone de F1. TASK-025, TASK-026 e TASK-027 estão aprovadas; TASK-028 integra o processador ao sistema. |
| Processadores e controle | 028-030 | F1 e F2 validadas, FSM principal com START, BUSY e DONE reais, reset e reexecução. |
| Saídas obrigatórias | 031-032 | Quatro curvas e eixos, LEDs e mensagens de erro nos displays físicos. |
| Configuração e regressão | 034-036 | Fontes e regras verificadas, projeto Quartus PBL03 configurado, regressão de sistema repetível e análise de timing inicial. |
| Extras visuais | 037, 039-040 | Interseções inteiras, vértices, raízes e marcadores. |
| Fechamento técnico | 041 | Build reproduzível, fontes finais conferidas e evidências ligadas à mesma revisão. |

### Dependências

```text
TASK-025 → TASK-026 → TASK-027 → TASK-028 → TASK-029 → TASK-030 → TASK-031 → TASK-032 → TASK-034 → TASK-035 → TASK-036 ─┬→ TASK-037 ─┐
                                                                                                                               ├→ TASK-039 ─┼→ TASK-041
                                                                                                                               └→ TASK-040 ─┘
```

TASK-030 aguarda ambos os processadores, inclusive F2, e TASK-031 renderiza os resultados de F2. TASK-032 adiciona LEDs e mensagens nos displays físicos. A DEC-051 removeu o painel lateral textual e a tela de coeficientes. TASK-039 e TASK-040 permanecem extras independentes; qualquer rótulo numérico será especificado e renderizado dentro da própria tarefa.

## Gates de decisão e evidência

- **FSMs e transições:** registrar diagrama de estados, tabela de transições e saídas antes de aprovar os controladores. A decisão deve preservar os contratos de START, BUSY, DONE e reset em `REGRAS.md`.
- **Extras numéricos:** decidir formato e arredondamento para valores textuais do vértice e raízes antes de implementá-los. A validação do vértice continua racional e exata.
- **Cor de raízes:** decidir cor e prioridade dos marcadores antes da tarefa de plotagem de raízes.
- **Temporização:** sintetizar F1 depois da TASK-027/028 e medir novamente após integração. Se a rota coordenada→aritmética→comparação→RGB não cumprir o período VGA, abrir uma decisão antes de alterar a arquitetura ou inserir pipeline.
- **Placa e pinos:** obter a pinagem oficial da DE10-Lite e conferir cada porta física antes de fechar QSF/SDC. Não copiar restrições do PBL02 sem validar o domínio de pixel.
- **Periférico do professor:** manter `vendor/vga/vga_sync.v` byte a byte intacto. Confirmar hash antes da entrega.

## Critérios de conclusão

O PBL03 só está pronto quando a regressão cobre a entrada à saída, os critérios obrigatórios de função válida e inválida passam, o projeto Quartus compila e tem relatórios reais de uso e temporização, e a validação na DE10-Lite mostra as demonstrações exigidas pelo PDF. Também devem estar disponíveis o diagrama e a tabela das FSMs, o relatório no modelo do tutor, os resultados de simulação e os artefatos de síntese da mesma revisão.

Uma síntese isolada não comprova temporização nem funcionamento na placa. Uma simulação não comprova pinagem. Registre cada evidência em sua TASK e não afirme resultados que ainda não foram obtidos.

## Pendências de entrega fora das TASKs de código

- Obter o modelo oficial de relatório do tutor e completar o relatório com resultados medidos.
- Preparar demonstração de F1, F1+F2 com derivadas, erros `a=0` e vértice fora da tela, reset e reexecução.
- Demonstrar operação com monitor VGA na DE10-Lite e registrar limitações físicas encontradas.
- Preparar diagrama das FSMs, tabela de transições e resumo de uso de lógica para apresentação.

Estas entregas dependem do hardware, do modelo do tutor e da equipe. Elas não são marcadas como concluídas por uma implementação ou simulação.
