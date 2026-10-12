# TASK-022 — OV para limite de exibição de y

## Objetivo

Fazer LEDR0 (OV) acender quando o resultado matemático signed23 `y` não couber em sua representação decimal signed nos seis displays, preservando cálculo e valor completos. Ao selecionar `y` fora da faixa, HEX0–HEX5 continuam exibindo `------`.

## Status

BLOCKED — RTL implementado e revisado estaticamente; faltam vetores dirigidos de fronteira e evidência funcional.

## Requisitos relacionados

- REQ-007
- REQ-009
- REQ-010

## Decisões relacionadas

- DEC-012/013/017/028 — contratos anteriores, explicitamente supersedidos na semântica da flag por DEC-039.
- DEC-039 — faixa e qualificação de OV.
- DEC-030 — integração por portas estruturais.

## Dependências

- TASK-012 APPROVED; integração existente.
- DEC-039 CONSENSUS.

## Restrições aplicáveis

- Preservar y signed23 sem truncamento, saturação ou wrap.
- DUT estrutural conforme `docs/regras.md`; sem `if`, `else`, `buf`, FSM, loops ou blocos proibidos.
- OV de apresentação acende somente quando `loaded=1`, `sel=01` e `y>999999` ou `y<−99999`.
- Não alterar pinagem nem portas físicas.
- Atualizar apenas documentos e arquivos listados após brief.

## Arquivos permitidos

- `rtl/exibicao_decimal.v`
- `rtl/modulo_principal.v`
- `testbench/tb_top_module.v` (atualizar a expectativa de OV e incluir casos dirigidos de fronteira)
- `docs/interfaces.md`
- `docs/decisions/DEC-012.md`
- `docs/decisions/DEC-013.md`
- `docs/decisions/DEC-017.md`
- `docs/decisions/DEC-028.md`
- `docs/tasks/TASK-012.md`
- `docs/tasks/TASK-022.md`

## Critérios de aceite

- OV permanece baixo para `x`, raízes, valor y dentro da faixa, resultado inválido ou coeficientes não carregados.
- OV sobe para seleção y carregada quando `y>999999` ou `y<−99999`.
- HEX mostra `------` nos mesmos casos de overflow de exibição.
- y permanece signed23 exato; nenhum overflow intermediário é exposto como OV.
- Nenhuma alteração na interface física ou pinagem.

## Implementation Brief

### Objetivo

Manter `y` exato em signed23 e acender LEDR0 quando, com coeficientes carregados e `y` selecionado, o valor integral não couber na representação decimal signed dos seis displays. Para essa seleção, a faixa exibível é `0…999999` e `−99999…−1`; fora dela, HEX0–HEX5 mostram `------` e OV=1. Não truncar, saturar nem aplicar wrap ao cálculo.

### Requisitos

- REQ-007
- REQ-009
- REQ-010

### Decisões aplicáveis

- DEC-030 — interface física, seleção e integração estrutural.
- DEC-039 — OV qualificada por `loaded` e seleção `y`, usando o limite de apresentação.
- DEC-012/013/017/028 — histórico do contrato anterior; semântica de OV supersedida por DEC-039, preservando o cálculo signed23 e o fallback `------`.

### Módulos envolvidos

- `modulo_principal` (`rtl/modulo_principal.v`): qualificação de OV por carga e seleção e conexão a LEDR0.
- `exibicao_decimal` (`rtl/exibicao_decimal.v`): faixa visual signed e máscara `------` já definida para excesso de apresentação.
- `tb_top_module` (`testbench/tb_top_module.v`): expectativa de LEDR0 e verificação integrada dos limites.
- Documentação de contrato/interface e histórico listada em Arquivos permitidos.

### Interface

| Sinal | Direção/largura | Semântica |
|---|---|---|
| `MAX10_CLK1_50` | entrada, 1 bit | Clock de 50 MHz do top físico. |
| `KEY[1:0]` | entrada, 2 bits, ativos baixos | KEY0 captura coeficientes; KEY1 solicita reset conforme a arquitetura aprovada. |
| `SW[9:0]` | entrada, 10 bits | `SW[7:0]` fornece dado signed8; `SW[9:8]` seleciona `00=x`, `01=y`, `10=x1`, `11=x2`. |
| `LEDR[9:0]` | saída, 10 bits | LEDR0=OV; LEDR1=Z; LEDR2=C; LEDR3=ERR; LEDR9:4 desligados. OV de apresentação fica alto somente para `loaded=1`, seleção `01` e `y>999999` ou `y<−99999`. |
| `HEX0…HEX5` | saídas, cada uma com 7 bits | Segmentos ativos baixos `[0..6]=a..g`; valor decimal signed, ou seis traços se `y` exceder a faixa de exibição. |
| `y` | sinal interno, signed23 | Resultado integral exato `ax²+bx+c`; permanece sem truncamento e alimenta comparação/apresentação. |
| `loaded` / `sel` | sinais internos, 1 bit / 2 bits | Qualificam OV: todos coeficientes capturados e seleção atual `y`. |

Não alterar as portas físicas nem a pinagem. A implementação pode reorganizar apenas a lógica combinacional nos arquivos permitidos; qualquer mudança de interface interna deve permanecer dentro desse escopo e preservar o top físico.

### Clock e reset

OV e apresentação são combinacionais, sem estado próprio. O carregamento segue o clock de 50 MHz, borda de subida, KEY0 sincronizada e reset lógico síncrono via KEY1 conforme DEC-019/030. OV deve cair combinacionalmente ao selecionar `x`, `x1` ou `x2`, ao desmarcar `y` ou quando `loaded=0`; não criar registrador ou latch para a flag.

### Restrições

- Aplicar `docs/regras.md`: DUT estrutural; sem FSM, `if`, `else`, `buf`, `for`, `generate`, `genvar` ou blocos comportamentais fora dos FF dedicados.
- Preservar `y` signed23 exato e a aritmética integral existente; overflow de subtotal é erro de implementação e não OV.
- Não alterar requisitos P0, interfaces físicas, pinagem, LEDs Z/C/ERR nem flags adicionais fora do pedido.
- DEC-039 revisa explicitamente a interpretação anterior de OV e de DEC-017 para esta condição; manter REQ-010 literalmente como está e registrar a interpretação documentalmente. Não afirmar aprovação do tutor.
- Não alegar economia de LEs sem síntese real.

### Arquivos permitidos

- `rtl/exibicao_decimal.v`
- `rtl/modulo_principal.v`
- `testbench/tb_top_module.v`, para expectativas e vetores dirigidos de fronteira.
- `docs/interfaces.md`
- `docs/decisions/DEC-012.md`
- `docs/decisions/DEC-013.md`
- `docs/decisions/DEC-017.md`
- `docs/decisions/DEC-028.md`
- `docs/tasks/TASK-012.md`
- `docs/tasks/TASK-022.md`

### Arquivos protegidos

Todos os arquivos fora da lista permitida, especialmente requisitos P0, pin assignments, QSF, RTL aritmético (`polinomio_y.v` e dependências), `rtl/sinalizadores_status.v` e testbenches não listados. Ler ou compilar uma dependência não autoriza editá-la.

### Testes exigidos

Atualizar/executar a verificação integrada de `tb_top_module` contra uma referência independente calculada com os coeficientes e `x` carregados. Conferir HEX0–HEX5, LEDs, ausência de X/Z e os limites abaixo. Registrar comando, ferramenta/versão, código de saída, contagens e hashes reais na TASK. Esta rodada de Context Analyst não executa testes; resultados permanecem pendentes.

### Casos de borda

- `y=999999`: `a=62,b=0,c=1,x=127`; cabe, OV=0 e valor decimal aparece.
- `y=1000000`: `a=62,b=0,c=2,x=127`; excede, OV=1 e HEX mostra `------`.
- `y=−99999`: `a=−10,b=0,c=1,x=100`; cabe, OV=0 e sinal/dígitos aparecem.
- `y=−100000`: `a=−10,b=0,c=0,x=100`; excede, OV=1 e HEX mostra `------`.
- Para valor de `y` fora da faixa, selecionar `x`, `x1` e `x2`: OV=0. Confirmar também `loaded=0`, raiz inválida e valores `y` dentro da faixa com OV=0.
- Preservar Z, C e ERR nos cenários existentes; nenhuma alteração de pinagem ou saídas físicas.

### Critérios de aceite

- LEDR0 implementa exatamente a condição `loaded AND (sel==01) AND (y>999999 OR y<−99999)`.
- Nos dois limites incluídos, OV=0 e apresentação numérica completa; imediatamente fora, OV=1 e `------`.
- Seleção diferente de `y`, raiz inválida ou falta de carga mantém OV=0.
- O valor integral `y` continua signed23; sem truncamento, saturação, wrap ou OV sticky de intermediário.
- A regressão integrada passa e a auditoria não encontra violação de `docs/regras.md` ou mudança de interface/pinagem.

### Dependências

- TASK-012 APPROVED — top físico e conexões existentes.
- DEC-039 CONSENSUS — semântica de OV de apresentação e qualificadores.
- DEC-030 CONSENSUS — portas físicas, seleção, sinais de carga e convenções estruturais.

### Pendências

Nenhuma decisão técnica bloqueadora para iniciar a implementação. A ressalva documental de que REQ-010 usa a expressão “overflow aritmético” está registrada em DEC-039; preservar o texto P0 e a interpretação adotada. Simulação, síntese e validação física ainda precisam de evidência nas etapas próprias.

## Testes

Casos de fronteira previstos: `999999`, `1000000`, `-99999`, `-100000`, y overflow com seleção diferente, unloaded e raiz inválida. Execução de testes fica fora do escopo desta rodada.

## Resultado da implementação

IMPLEMENTED (RTL). `exibicao_decimal` expõe `overflow_exibicao` a partir dos mesmos dígitos BCD que controlam a faixa visível, sem incluir `invalid`. `modulo_principal` qualifica esse sinal por `loaded` e seleção `01` e conecta o resultado diretamente a LEDR0. A saída aritmética signed23, a apresentação `------` e o módulo `sinaliza_overflow_erro`/ERR permanecem preservados. A porta física e a pinagem não mudaram.

Limitação: implementação ainda não verificada funcionalmente nem em síntese; regressão integrada e auditoria permanecem pendentes.

## Resultado das ferramentas

Testes, simulação e síntese não executados nesta rodada, conforme o escopo atribuído.

### Arquivos tocados

- `rtl/exibicao_decimal.v`
- `rtl/modulo_principal.v`
- `docs/tasks/TASK-022.md`

## Resultado da revisão

**BLOCKED — revisão estática concluída; aprovação funcional pendente.** Follow-up feito após as correções informadas. Não executei testes, simulação nem síntese, conforme o escopo desta revisão.

### Compliance

- **PASS estático:** `rtl/exibicao_decimal.v` e `rtl/modulo_principal.v` usam composição estrutural nos trechos inspecionados; não encontrei `assign`, `buf`, `always`, `if`/`else`, FSM nem laços proibidos. A interface física do top-level permanece com as mesmas portas e larguras, e não há alteração de pinagem nesta tarefa.
- A nova saída `overflow_exibicao` é ligada no top-level; o chamador `testbench/tb_decimal_display.v` a deixa desconectada. Isso não altera a verificação atual de HEX, mas esse testbench não cobre a nova saída.

### Integração e lógica de faixa

- **Resolvido — expectativa integrada de OV:** `testbench/tb_top_module.v:101` agora calcula LEDR0 para resultado `y` carregado e selecionado quando ultrapassa `999999` ou fica abaixo de `-99999`. A condição estática corresponde ao contrato de DEC-039.
- **Resolvido — contrato de interface:** `docs/interfaces.md:21-28,42` agora distingue OV aritmético interno da flag de apresentação no LEDR0, declara `overflow_exibicao` e documenta sua qualificação por `loaded`/seleção.
- **Pendente — casos dirigidos de fronteira:** `tb_top_module.v` ainda não acrescenta os quatro casos exigidos (`999999`, `1000000`, `-99999`, `-100000`). Os cenários existentes cobrem extremos de `y`, mas não comprovam os limites inclusivos/imediatamente externos definidos no Brief.
- A lógica implementada corresponde estaticamente à semântica aprovada em DEC-039: o BCD da magnitude completa determina excesso positivo quando o dígito de milhão não é zero e excesso negativo quando o valor é negativo e o dígito de cem mil não é zero, que são as fronteiras `y>999999` e `y<−99999`. A apresentação e o OV reutilizam essa classificação; `invalid` afeta os traços, mas não cria OV.
- No top-level, LEDR0 é a AND de `coeficientes_carregados`, seleção `01` e `overflow_exibicao`. Assim, a flag cai para `x`/raízes e antes de carregar os coeficientes. Raiz inválida não seleciona `y`, e `ERR` continua em LEDR3; não encontrei conflito de drivers nas conexões inspecionadas.
- O caminho aritmético continua signed23 e não foi editado, preservando o contrato de cálculo. Não avaliei sua exatidão funcional nesta TASK.

### Pendência para desbloqueio

Adicionar os quatro vetores dirigidos de fronteira ao testbench e executar a regressão funcional prevista, registrando evidência real. Sem essa evidência, não é possível aprovar a TASK.

## Pendências

Faltam os quatro vetores dirigidos de fronteira e a execução/evidência da regressão funcional; revisão estática concluída com status BLOCKED.

## Histórico

- 2026-10-12 — criada após consenso de DEC-039; aguardando análise de contexto.
- 2026-10-12 — Context Analyst confirmou DEC-039 CONSENSUS, completou Implementation Brief e marcou READY_FOR_IMPLEMENTATION. Nenhum RTL, teste ou síntese foi executado nesta análise.
- 2026-10-12 — Code Implementer concluiu a alteração RTL prevista; testes/simulação/síntese e revisão independente pendentes.
