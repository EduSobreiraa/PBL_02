# Relatório de situação das decisões

**Data:** 06/10/2026  
**Escopo:** decisões do fluxo em `docs/decisions/`; prioridade conforme `docs/pendencias.md`.

## Pendências de alta prioridade

| Pendência | Decisão | Estado | Resultado |
|---|---|---|---|
| PEN-002 | [DEC-007](DEC-007.md) | CONSENSUS | Raízes arredondadas ao inteiro mais próximo; empate exato para longe de zero. O responsável confirmou autorização/incentivo do professor. A exceção fica documentada sem reescrever o PDF, que ainda diz “truncar”. |
| PEN-003 | [DEC-012](DEC-012.md) | CONSENSUS | `y` signed de 23 bits cobre toda a faixa válida. OV indica não representabilidade aritmética nessa faixa e, portanto, permanece 0 para entradas válidas. Overflow visual é separado. |
| PEN-005 | [DEC-009](DEC-009.md) | CONSENSUS | `SW[7:0]` fornece `a`, `b`, `c`; KEY0 é pressionado exatamente três vezes nessa ordem, carregando deslocador de três estágios. Depois, SW fornece `x`. Não detecta entrada incompleta ou captura extra. A alternativa de contador/enables não foi adotada porque a worklogic citada não estava disponível para revisão e o Reviewer apontou risco de FSM. |
| PEN-007 | [DEC-008](DEC-008.md) | CONSENSUS | `MAX10_CLK1_50`, borda de subida; reset lógico síncrono ativo alto em KEY1; KEY0 captura coeficientes. KEY ativo baixo; sincronização e captura única aprovadas em DEC-019. |
| PEN-008 | [DEC-010](DEC-010.md) | CONSENSUS | Resultados continuamente disponíveis após carga, sem botão EXECUTAR nem captura de resultados. |
| PEN-011 | [DEC-011](DEC-011.md) | CONSENSUS | `SW[9:8]`: `00=x`, `01=y`, `10=x₁`, `11=x₂`. `SW[7:0]` fornece dados/`x`; KEY0 grava; KEY1 reseta. Decimal com sinal é o padrão prioritário. |

## Decisões de prioridade média relacionadas

| Pendência | Decisão | Estado | Situação |
|---|---|---|---|
| PEN-009 | [DEC-013](DEC-013.md) | CONSENSUS | `y` signed 23-bit; raízes signed 25-bit com 16 frações (F=16) como recomendação candidata. A faixa/precisão numérica ainda precisa de validação em PEN-019. |
| PEN-004 | [DEC-015](DEC-015.md) | BLOCKED | Z tem proposta de consenso como zero do valor selecionado; a origem/semântica de C precisa ser informada por tutor/equipe. |
| PEN-006 | [DEC-014](DEC-014.md) | CONSENSUS | DFF adotado. `always @(posedge clk)` é autorizado somente dentro da descrição do flip-flop; datapath/controle seguem estruturais, sem FSM. |
| PEN-010 | [DEC-016](DEC-016.md) | DECIDIDA | Responsável aprovou preservar precisão e arredondar ao mais próximo, empate longe de zero, somente ao reduzir precisão. |
| PEN-013 | [DEC-017](DEC-017.md) | DECIDIDA | Responsável aprovou `------` quando o decimal signed completo exceder a capacidade dos displays, sem alterar OV. |
| PEN-014 | [DEC-018](DEC-018.md) | DECIDIDA | Responsável aprovou baseline de assignments oficiais; validar QSF quando existir top-level. |
| PEN-015 | [DEC-019](DEC-019.md) | DECIDIDA | Responsável aprovou sincronização em duas etapas e evento único por pressão, condicionado a DEC-014/regras de sintaxe; reset KEY1 após energizar. |
| PEN-019 | [DEC-020](DEC-020.md) | PLANO APROVADO | Responsável aprovou exaustão de coeficientes válidos para raízes e vetores dirigidos. Executar depois de PEN-010; F=16 ainda não foi validado. |

### Pendências de baixa prioridade

| Pendência | Decisão | Estado | Situação |
|---|---|---|---|
| PEN-016 | [DEC-021](DEC-021.md) | RESOLVIDA | Detectado Quartus Prime Standard Lite 25.1std.0 Build 1129 (10/21/2025). Nenhuma compilação foi iniciada. |
| PEN-020 | [DEC-022](DEC-022.md) | ADIADA | Responsável esclareceu que a etapa do relatório é posterior; retomar quando esse processo começar. |

## Estado geral

Todas as decisões de alta prioridade passaram pelo ciclo Architect → Reviewer e chegaram a consenso. PEN-002 foi fechada na Rodada 3 após o responsável confirmar a autorização do professor; PEN-003 foi fechada depois da escolha de faixa em PEN-009. A proposta mais recente de controle de carga por contador/enables foi revisada na Rodada 3 de PEN-005 e não foi adotada; o resultado aceito permanece o deslocador sem FSM.

PEN-006, de prioridade média, chegou a CONSENSUS na Rodada 3 após o responsável autorizar o uso restrito de `always` na descrição de flip-flops e o Reviewer confirmar o escopo.

A worklogic `WORKLOGIC_PROBLEMA2_CIRCUITOSD...` citada pelo responsável não está presente no workspace e, portanto, não foi examinada. Se a equipe quiser substituir o deslocador pelo contador/enables nela descrito, será necessário disponibilizar o conteúdo para revisão e reabrir PEN-005.

O guia oficial Intel Quartus Prime 25.1 documenta estilos HDL para inferir registradores; essa evidência confirma suporte técnico e não amplia a exceção autorizada no projeto.

Nenhum requisito do PDF foi editado. A divergência do arredondamento está documentada como exceção autorizada. Nenhum Verilog foi implementado e nenhum teste foi executado nesta etapa.

## Auditoria documental — 06/10/2026

Foram alinhados `AGENTS.md`, `docs/agente_workflow.md`, `docs/regras.md`, `docs/requisitos.md`, `docs/decisoes.md`, `docs/pendencias.md`, `docs/arquitetura.md`, `docs/interfaces.md`, `docs/hardware.md`, `docs/modulos.md`, `docs/verificacao.md`, `docs/convencoes_verilog.md`, `docs/fontes.md` e `docs/planejamento.md` às decisões atuais. Corrigiu-se também o nome do workflow referenciado (o arquivo existente é `docs/agente_workflow.md`) e a situação final do DFF.

O fluxo adicional analisou PEN-004/010/013/014/015/016/019/020 em DEC-015 a DEC-022, com no máximo duas rodadas. O responsável ratificou PEN-010/013/014/015/019; identificamos Quartus instalado para PEN-016; PEN-020 foi adiada para a fase posterior do relatório. PEN-004 continua bloqueada pela origem indefinida de C. PEN-019 ainda exige execução futura dos testes; não é resultado de validação. Nenhum requisito oficial foi reescrito. Não houve implementação de Verilog nem execução de testes.

Os fatos físicos de polaridade dos botões e mapeamento/nível dos segmentos foram confirmados no manual e atualizados em `docs/hardware.md`/`docs/interfaces.md`. A sincronização e a regra de início após power-on foram ratificadas sob a condição de cumprir DEC-014 e `docs/regras.md`.
