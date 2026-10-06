# Pendências do PBL02

Prioridade **ALTA** bloqueia decisões centrais; **MÉDIA** afeta arquitetura, integração ou verificação; **BAIXA** pode ser resolvida mais tarde. As prioridades são avaliação de planejamento, não requisitos oficiais.

## Abertas

| ID | Classe | Prioridade | O que falta definir | Fonte/impacto | Quem confirma |
|---|---|---|---|---|---|
| PEN-004 | Requisito | MÉDIA | Z tem proposta de consenso: zero quando a visualização selecionada é zero. C segue BLOCKED até definir qual operação/estágio gera carry e o valor quando essa saída não está selecionada. | REQ-010 não define origem/semântica; [DEC-015](decisions/DEC-015.md) | Tutor/equipe |
| PEN-019 | Teste | MÉDIA | Plano aprovado, mas ainda é necessário executar e registrar a comparação exaustiva de raízes e os vetores dirigidos. Só declarar F=16 validado após essa evidência. | DEC-013; [DEC-020](decisions/DEC-020.md); testes futuros |
| PEN-021 | Interface | MÉDIA | Definir a fronteira interna e os contratos mínimos de sinais/portas para sincronização de KEY e armazenamento de coeficientes sem alterar interfaces físicas acordadas. | [DEC-023](decisions/DEC-023.md); TASK-002 |

## Resolvidas ou esclarecidas

| ID | Resultado | Registro |
|---|---|---|
| PEN-001 | Esclarecida: em `a=0` ou `Δ<0`, ativa-se ERR, não se produz resultado de raiz válido e o usuário usa reset para sair da condição. Exibir texto ERR é opcional e não necessário. | DEC-001 |
| PEN-002 | Resolvida: adotar arredondamento ao inteiro mais próximo para as raízes, com empate para longe de zero, como exceção de implementação autorizada pelo professor. O texto literal de REQ-006 no PDF permanece “truncar”. | DEC-007; autorização relatada pelo responsável |
| PEN-003 | Resolvida: `y` signed de 23 bits; OV indica não representabilidade do resultado nessa faixa e permanece 0 para todas as entradas válidas signed de 8 bits. Overflow de display é questão separada. | DEC-012/013 |
| PEN-005 | Resolvida: carregar `a`, `b`, `c` em três gravações de KEY0, nessa ordem, usando deslocador de três estágios; `SW[7:0]` fornece os valores e depois `x`. Não há detector de carga incompleta/excedente. | DEC-009 |
| PEN-007 | Resolvida: clock `MAX10_CLK1_50`, reset síncrono lógico ativo alto via KEY1, KEY0 captura coeficientes na borda de subida; resultados são combinacionais. KEY ativo baixo; sincronização e pulso de captura definidos em DEC-019. | DEC-008/019 |
| PEN-008 | Resolvida: resultados continuamente disponíveis após carga, sem comando separado de execução/captura. | DEC-010; harmonizada em DEC-008 |
| PEN-009 | Resolvida como formato candidato: `y` signed 23-bit; raízes intermediárias signed 25-bit com F=16 e larguras relacionadas em DEC-013. Validação da precisão segue PEN-019. | DEC-013 |
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

PEN-004 permanece bloqueada pela origem de C. PEN-019 tem estratégia aprovada, mas exige execução e registro da evidência para validar F=16. PEN-020 foi adiada para a fase de relatório. PEN-010/013/014/015/016 foram decididas pelo responsável; seus limites e atividades futuras permanecem registrados nas DEC correspondentes.

## Dependências sem resolução por inferência

DEC-007 a DEC-014 fecharam as decisões de alta prioridade e as larguras/estilo de DFF. DEC-015 a DEC-022 registram a análise das demais pendências: semântica de C (PEN-004) está bloqueada; PEN-020 foi adiada pelo responsável para a fase posterior do relatório; PEN-019 aguarda execução do plano aprovado. As outras decisões foram ratificadas pelo responsável. Os fatos de polaridade de KEY e dos segmentos foram confirmados no manual. Não alterar o texto P0 de REQ-006.
