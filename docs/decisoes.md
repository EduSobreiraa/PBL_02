# Registro de decisões e esclarecimentos

Somente decisões explícitas do responsável/projeto são registradas como aprovadas. Requisitos P0 prevalecem, salvo exceção expressamente autorizada pelo docente; nesses casos, preservar o texto oficial e registrar a divergência.

## DEC-001 — Comportamento quando as raízes não existem

- **Decisão:** para `a=0` ou `Δ<0`, ativar `ERR` e não produzir/atualizar um resultado de raiz válido. O usuário deve acionar reset para sair dessa condição. Uma mensagem `ERR` nos displays é opcional e não necessária; não será requisito adicional.
- **Motivo:** esclarecimento fornecido pelo responsável do projeto.
- **Alternativas consideradas:** exibir texto `ERR` nos displays; dispensada como firula opcional.
- **Impacto:** flag e persistência até reset devem ser consideradas no fluxo de controle; comportamento detalhado dos displays durante erro permanece fora dos requisitos.
- **Status:** aprovada como interpretação de equipe, sem alterar o requisito P0 de ativar ERR.
- **Fonte/responsável:** mensagem de Felipe CD UEFS, 05/10/2026; responsável do projeto.

## DEC-002 — Tipos de flip-flop permitidos

- **Decisão:** não há restrição da equipe a um tipo específico de flip-flop; um D flip-flop é uma possibilidade.
- **Motivo:** esclarecimento do responsável.
- **Alternativas consideradas:** DFF ou outro flip-flop compatível com a função.
- **Impacto:** implementação concreta e estilo de descrição ainda dependem da conciliação com a proibição de Verilog comportamental e das regras de síntese.
- **Status:** a liberdade de escolha foi aprovada em DEC-002; posteriormente DEC-014 selecionou DFF como forma de armazenamento e autorizou `always` apenas na descrição do flip-flop.
- **Fonte/responsável:** mensagem de Felipe CD UEFS, 05/10/2026; confirmação posterior da dupla do projeto, compartilhada pelo responsável em 06/10/2026. Síntese no ambiente efetivo ainda precisa de validação.

## DEC-003 — Associação de flags aos LEDs na base

- **Decisão:** registrar a associação existente no projeto fornecido: LEDR0=OV, LEDR1=Z, LEDR2=C, LEDR3=ERR.
- **Motivo:** responsável informou que PEN-012 já está implementada no projeto enviado; associação conferida na hierarquia do PBL1.
- **Alternativas consideradas:** não aplicável nesta atualização.
- **Impacto:** usar como mapeamento herdado na documentação; integração final ainda deve ser verificada no PBL02.
- **Status:** confirmada para a base fornecida; reutilização na integração PBL02 sujeita à revisão normal.
- **Fonte/responsável:** mensagem de Felipe CD UEFS, 05/10/2026; fonte HDL PBL1.

## DEC-004 — Versão principal do Quartus

- **Decisão:** usar Quartus Prime Standard Lite 25.1std.0, Build 1129, como ambiente de referência. A instalação foi identificada em 06/10/2026.
- **Motivo:** versão informada pelo responsável.
- **Alternativas consideradas:** versão 17.1 do handbook presente na raiz é referência documental, não a versão de trabalho.
- **Impacto:** a edição/build foram confirmados pela instalação local; conferir a compilação do projeto quando a síntese ocorrer.
- **Status:** aprovada.
- **Fonte/responsável:** mensagem de Felipe CD UEFS, 05/10/2026.

## DEC-005 — Ambiente de simulação

- **Decisão:** EDA Playground é o ambiente de simulação preferido para este projeto.
- **Motivo:** responsável relata que seu projeto anterior foi simulado no EDA Playground e teve comportamento igual ao observado na placa.
- **Alternativas consideradas:** não avaliadas nesta atualização.
- **Impacto:** o PBL02 ainda precisará de seus próprios testbenches e evidências; backend/versão do simulador não foram informados.
- **Status:** aprovada como ferramenta preferida, com evidência relatada referente ao projeto anterior.
- **Fonte/responsável:** mensagem de Felipe CD UEFS, 05/10/2026.

## DEC-006 — Escopo permitido para `begin`/`end`

- **Decisão:** os tokens `begin` e `end` podem aparecer somente na descrição do flip-flop; fora dela são proibidos.
- **Motivo:** esclarecimento direto do responsável sobre a regra 4.
- **Alternativas consideradas:** proibição total; substituída por esta exceção delimitada.
- **Impacto:** à época, a exceção de `begin/end` não liberava automaticamente `always`. DEC-014 esclareceu posteriormente a autorização específica de `always @(posedge clk)` somente na descrição do DFF; outras construções comportamentais continuam proibidas.
- **Status:** aprovada quanto ao escopo de `begin`/`end`; a forma HDL restrita do DFF foi resolvida posteriormente em DEC-014/PEN-006.
- **Fonte/responsável:** esclarecimento de Felipe CD UEFS, mensagem de 05/10/2026, registrado em `docs/regras.md`.

## DEC-007 — Arredondamento final das raízes

- **Decisão:** arredondar as raízes ao inteiro mais próximo; empates exatos vão para longe de zero.
- **Autorização:** o responsável confirmou que o professor incentivou e autorizou arredondar como desafio do projeto.
- **Ressalva documental:** o texto literal de REQ-006/PDF ainda diz “truncar”. A decisão é uma exceção de implementação autorizada, não retificação do PDF; manter essa diferença explícita em relatórios.
- **Status:** consenso Architect/Reviewer em DEC-007.

## DEC-008 a DEC-011 — Controles e tempo de cálculo

- Clock global `MAX10_CLK1_50`, borda de subida. Reset lógico síncrono ativo alto por KEY1; KEY0 captura os coeficientes. Os KEY são ativos baixos; sincronização em duas etapas e evento único de captura foram aceitos em DEC-019.
- Carregar `a`, `b`, `c` em três capturas de KEY0, nessa ordem, com deslocador de três estágios; não usar contador/enables sem prova de conformidade à regra sem FSM. O procedimento exige exatamente três capturas e não detecta entrada incorreta/incompleta/excedente.
- `SW[9:8]` seleciona `00=x`, `01=y`, `10=x₁`, `11=x₂`. `SW[7:0]` fornece coeficientes durante a carga e `x` depois. A apresentação prioriza decimal com sinal; sem seletor HEX/DEC e sem botão EXECUTAR.
- Coeficientes são sequenciais; cálculo e apresentação dos resultados são combinacionais e continuamente disponíveis depois da carga.
- **Status:** decisões de equipe aceitas nas DEC-008 a DEC-011; fallback `------` aprovado em DEC-017.

## DEC-012 — Overflow de y

- `y` integral signed de 23 bits preserva toda a faixa válida para entradas signed de 8 bits.
- `OV` representa não representabilidade aritmética nessa faixa e permanece 0 para entradas válidas. Overflow visual é separado e mostra `------` quando o valor não cabe (DEC-017).
- **Status:** consenso em DEC-012; REQ-007/010 não exigem que OV ative em um caso válido.

## DEC-013 — Larguras numéricas candidatas

- Usar os limites e larguras de `Δ`, produtos, radicando e quociente registrados em DEC-013; `y` signed 23 bits.
- Raízes intermediárias: signed 25-bit com 16 bits fracionários (`F=16`), como recomendação de projeto; precisão correta precisa de evidência futura em PEN-019.
- **Status:** consenso técnico; a precisão requer evidência em PEN-019 e a origem de C segue PEN-004.

## DEC-014 — Forma HDL do flip-flop

- Descrever DFFs com `always @(posedge clk)` somente dentro da descrição/módulo de flip-flop, com reset síncrono/enable próprios conforme DEC-008/009.
- `always` fora dos flip-flops, lógica comportamental de datapath/controle, FSM, `buf`, laços e geração continuam proibidos; demais conexões/cálculos são estruturais.
- **Status:** consenso na Rodada 3 após autorização explícita do responsável e revisão independente.

## DEC-015 a DEC-022 — Pendências restantes

- **DEC-015 / PEN-004:** Z é zero do valor selecionado; C continua bloqueada até definir sua operação/estágio de origem.
- **DEC-016 / PEN-010:** arredondar ao mais próximo, empate para longe de zero, somente ao reduzir precisão; preservar os bits enquanto possível. Aprovado pelo responsável.
- **DEC-017 / PEN-013:** mostrar `------` quando o valor decimal signed completo não couber; OV permanece independente. Aprovado por ora.
- **DEC-018 / PEN-014:** adotar como baseline os pin assignments da documentação oficial já compilados em `docs/hardware.md`; QSF deve ser conferido quando houver top-level. Aprovado.
- **DEC-019 / PEN-015:** KEY ativo baixo; segmentos ativos baixos, índices 0–6=a–g. Sincronização em duas etapas, uma captura por pressão de KEY0 e reset após energizar; aprovado sob restrição de sintaxe de DEC-014.
- **DEC-020 / PEN-019:** plano aprovado de comparar exaustivamente casos de raízes válidas com referência exata e acrescentar vetores dirigidos. Execução/evidência ainda pendente; F=16 não está validado.
- **DEC-021 / PEN-016:** versão instalada identificada como Quartus Prime Standard Lite 25.1std.0 Build 1129 (21/10/2025), pelos comandos `quartus_sh --version` e `quartus_pgm --version`. Nenhuma compilação foi iniciada.
- **DEC-022 / PEN-020:** adiada pelo responsável para a etapa posterior de preparação do relatório.
