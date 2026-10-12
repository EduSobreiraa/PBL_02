# Pendências do PBL02

Prioridade **ALTA** bloqueia decisões centrais; **MÉDIA** afeta arquitetura, integração ou verificação; **BAIXA** pode ser resolvida mais tarde. As prioridades são avaliação de planejamento, não requisitos oficiais.

## Decisões técnicas em aberto

Nenhuma na baseline DEC-030/031/033/035/036 de 12/10/2026. O fechamento de escolhas anteriores cobre decisões de projeto, não execução de testes, aceite acadêmico ou disponibilidade física.

## Evidências e obrigações ainda necessárias

| Atividade | Responsável / registro | Condição real de conclusão |
|---|---|---|
| Comparação do RTL de raízes contra referência aprovada | TASK-008/009/011 | TASK-005 APPROVED: exaustão software concluída; simulação do futuro RTL permanece necessária |
| RTL, simulação e auditoria | TASKs de implementação / TASK-013/017 | Evidências e revisão independentes |
| Síntese, recursos, timing e pinagem | TASK-015 | Relatórios reais e gates aprovados |
| Validação em placa | TASK-014 | DE10-Lite acessível e procedimento executado |
| Modelo oficial do relatório | TASK-016 | Obter/aplicar instruções do tutor para entrega |
| Interpretação acadêmica do contador | Risco DEC-030/PEN-022 | A escolha local mantém DEC-024; não há confirmação externa alegada. Fato acadêmico contrário exige revisão |

## Resolvidas ou esclarecidas

| ID | Resultado | Registro |
|---|---|---|
| PEN-001 | Esclarecida: em `a=0` ou `Δ<0`, ativa-se ERR, não se produz resultado de raiz válido e o usuário usa reset para sair da condição. Exibir texto ERR é opcional e não necessário. | DEC-001 |
| PEN-002 | Resolvida: adotar arredondamento ao inteiro mais próximo para as raízes, com empate para longe de zero, como exceção de implementação autorizada pelo professor. O texto literal de REQ-006 no PDF permanece “truncar”. | DEC-007; autorização relatada pelo responsável |
| PEN-003 | Resolvida: `y` signed de 23 bits; OV indica não representabilidade do resultado nessa faixa e permanece 0 para todas as entradas válidas signed de 8 bits. Overflow de display é questão separada. | DEC-012/013 |
| PEN-004 | Resolvida: Z indica zero do valor selecionado (`x`, `y`, `x₁`, `x₂`); raiz inválida selecionada sob ERR força Z=0. C é o carry-out unsigned da última soma em `((a·x²)+(b·x))+c`, válido somente com `loaded=1` e seleção `y`; C é distinto de OV. `loaded` deriva estruturalmente do estado `11` já existente, sem FF ou pino físico. Rota privada wrapper/core detalhada e auditada em DEC-030; implementação e testes nas TASKs. | DEC-015/029/030; ratificação do responsável em 09/10/2026 |
| PEN-005 | Resolvida e atualizada: carregar `a`, `b`, `c` por três pressões sincronizadas de KEY0, com contador de progresso e enables; após `c`, ignorar novas capturas até reset. `SW[7:0]` fornece cada valor signed. | DEC-009, supersedida neste ponto por DEC-024 |
| PEN-007 | Resolvida: clock `MAX10_CLK1_50`, reset síncrono lógico ativo alto via KEY1, KEY0 captura coeficientes na borda de subida; resultados são combinacionais. KEY ativo baixo; sincronização e pulso de captura definidos em DEC-019. | DEC-008/019 |
| PEN-008 | Resolvida: resultados continuamente disponíveis após carga, sem comando separado de execução/captura. | DEC-010; harmonizada em DEC-008 |
| PEN-009 | Resolvida: y signed23; raízes finais signed9. Candidato F16 de DEC-013 substituído pela representação exata com resíduos e signed10/F1 em DEC-031. | DEC-013/031 |
| PEN-011 | Resolvida: `SW[9:8]` seleciona `x`, `y`, `x₁`, `x₂`; `SW[7:0]` fornece dados/`x`; KEY0 grava; KEY1 reseta; saída decimal com sinal prioritária. | DEC-011 |
| PEN-006 | Resolvida: adotado DFF, com `always @(posedge clk)` autorizado exclusivamente na descrição do flip-flop; datapath/controle permanecem estruturais e sem FSM. Compatibilidade de síntese será verificada na implementação. | DEC-002/006/014; `regras.md` |
| PEN-012 | Mapeamento já presente na base fornecida: LEDR0=OV, LEDR1=Z, LEDR2=C, LEDR3=ERR. A integração completa do PBL02 ainda será verificada. | DEC-003 |
| PEN-017 | Esclarecido: `begin`/`end` só podem aparecer dentro da descrição do flip-flop; fora dela são proibidos. A autorização posterior de `always` é restrita ao DFF, conforme DEC-014. | DEC-006/014 e `regras.md` |
| PEN-018 | EDA Playground é a ferramenta de simulação preferida. O responsável relata equivalência entre simulação e placa no projeto anterior; o PBL02 ainda precisará de seus próprios testes. | DEC-005 |
| PEN-010 | Resolvida: preservar precisão e arredondar ao mais próximo, empate para longe de zero, somente quando necessário reduzir a precisão intermediária. | DEC-016; aprovação do responsável em 06/10/2026 |
| PEN-013 | Resolvida por ora: exibir `------` quando o resultado decimal signed completo não couber nos seis displays; não alterar OV. | DEC-017; aprovação do responsável em 06/10/2026 |
| PEN-014 | Resolvida como baseline documental: usar assignments oficiais do manual compilados em `hardware.md`; validar QSF após definição do top-level. | DEC-018; aprovação do responsável em 06/10/2026 |
| PEN-015 | Resolvida documentalmente: KEY ativos baixos; segmentos ativos baixos e índices 0–6=a–g. Sincronizar KEYS em duas etapas, emitir evento por pressão de KEY0 e exigir reset KEY1 após energizar; futura implementação restrita às regras de DFF. | DEC-019; aprovação condicional do responsável em 06/10/2026 |
| PEN-016 | Resolvida: Quartus Prime Standard Lite 25.1std.0, Build 1129 (21/10/2025), detectado no ambiente. Nenhuma compilação foi executada. | DEC-021; `quartus_sh --version` e `quartus_pgm --version` |
| PEN-021 | Resolvida quanto ao contrato da baseline: fronteira `coefficient_input`, contador/enables, bloqueio após a terceira captura e testbench ratificados em DEC-024. TASK-002 foi reaberta em DEC-029; extensão privada DEC-030 implementada, TEST-001 passou e auditoria aprovou em 11/10/2026. Validação física permanece futura. | DEC-023/024/029; TASK-002 |

| PEN-019 | Escolha encerrada: F16 substituído pelo algoritmo exato com resíduos de DEC-031, prova revisada. TASK-005 executada e auditada após o sprint de decisão: 16.777.216 triplas e zero divergências no modelo. Isso não aprova o RTL das raízes. | DEC-031 |
| PEN-020 | Organização do conteúdo fechada; aplicar estrutura REQ-016 e matriz de evidências. Modelo externo do tutor ainda deve ser obtido para entrega final. | DEC-022/030; TASK-016 |
| PEN-022 | Escolha local encerrada: manter contador saturante estrutural autorizado em DEC-024; quatro condições em dois FF. A interpretação acadêmica permanece risco explícito, sem afirmar aprovação do tutor. | DEC-027/030 |
| Proibição de `assign` contínuo no RTL | Consenso: eliminar todos os `assign` do RTL e cópia `.save`, preservando testbenches e possível uso dentro de DFF; aliases por conexão direta, sem portas identidade. TASK-020 aprovada após implementação, regressão e auditoria; o código 130 do wrapper de `tb_multipliers` permanece explicitamente registrado. | DEC-033; TASK-020 |
| Interface privada do estágio BCD para remoção de `assign` | Consenso: separar correção dos dígitos e deslocamento nas conexões internas; preservar interfaces públicas e migrar somente o caller direto no TB de display. | DEC-035 |
| Interface privada de `sqrt_stage` para remoção de `assign` | Consenso: dirigir cada bit público da raiz diretamente com `take` de uma etapa e encadear prefixos/restos estruturalmente, sem alteração das portas públicas. Implementada e aprovada; TEST-004 passou em 131.072 radicandos. | DEC-036; TASK-020 |
| Solicitação de revisão da apresentação (12/10/2026) | Fechada sem alteração RTL: usos de `assign` avaliados conforme a permissão existente; `y` segue signed23; entrada de `x` já usa `SW[7:0]`; testbench BCD já existe e está aprovado. A captura não identifica outro sinal de 16 bits. | DEC-032; TASK-006 |

Nenhuma TASK é APPROVED pelo simples encerramento de decisão. Contratos e detalhes de implementação seguem DEC-030/031 e os briefs; evidências têm os gates acima. Requisitos P0 não foram alterados.
