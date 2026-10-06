# Hardware DE10-Lite relevante ao PBL02

## Base oficial

Fonte principal desta ficha: `DE10_Lite_User_Manual.pdf`, Terasic, 24 jan. 2017. O PBL identifica a placa DE10-Lite em TEC498 §3–5. As tabelas abaixo transcrevem recursos relevantes; não constituem pin assignment do projeto nem autorizam alterar arquivos Quartus.

## FPGA e recursos usados potencialmente

- FPGA: Intel/Altera MAX 10 `10M50DAF484C7G` (manual §1.3, p. 5).
- A placa disponibiliza 10 switches deslizantes, 2 push-buttons com condicionamento Schmitt/debounce, 10 LEDs de usuário e seis displays de sete segmentos (manual §1.3, p. 5).
- Clocks FPGA disponíveis: `MAX10_CLK1_50` em 50 MHz, pino `P11`; `MAX10_CLK2_50` em 50 MHz, pino `N14` (manual §3.2, p. 24). DEC-008 seleciona `MAX10_CLK1_50`, borda de subida, como clock único.

## Switches

Manual §3.3, tabela 3-4, p. 26. PBL requer `SW[7:0]` como entrada `x`, com bit 7 de sinal.

| Sinal | Pino FPGA | I/O |
|---|---|---|
| SW0 | C10 | 3.3-V LVTTL |
| SW1 | C11 | 3.3-V LVTTL |
| SW2 | D12 | 3.3-V LVTTL |
| SW3 | C12 | 3.3-V LVTTL |
| SW4 | A12 | 3.3-V LVTTL |
| SW5 | B12 | 3.3-V LVTTL |
| SW6 | A13 | 3.3-V LVTTL |
| SW7 | A14 | 3.3-V LVTTL |
| SW8 | B14 | 3.3-V LVTTL |
| SW9 | F15 | 3.3-V LVTTL |

O manual informa: posição DOWN fornece nível baixo e UP nível alto. DEC-011 atribui `SW[9:8]` à seleção de visualização (`00=x`, `01=y`, `10=x₁`, `11=x₂`); `SW[7:0]` fornece dados de coeficiente durante a carga e `x` depois dela. Isso é mapeamento lógico, não pin assignment novo.

## Push-buttons

| Sinal | Pino FPGA | Informação oficial |
|---|---|---|
| KEY0 | B8 | Push-button de usuário com entrada Schmitt/debounce; 3.3 V Schmitt Trigger |
| KEY1 | A7 | Push-button de usuário com entrada Schmitt/debounce; 3.3 V Schmitt Trigger |

Fonte: manual §3.3, figs. 3-13/14 e tabela 3-3, pp. 25–26. O circuito tem pull-up e fecha para GND ao pressionar; portanto KEY0/KEY1 são ativos em nível baixo no FPGA. DEC-011 atribui KEY0 à gravação e KEY1 ao reset lógico síncrono ativo alto (DEC-008), exigindo inversão lógica de KEY1. DEC-019 aprova sincronização em duas etapas e captura única; a integração ainda precisa de validação física.

## LEDs de usuário

O manual informa LEDs ativos em nível alto (nível alto liga; baixo desliga), §3.3, tabela 3-5, p. 27.

| LED | Pino FPGA | I/O |
|---|---|---|
| LEDR0 | A8 | 3.3-V LVTTL |
| LEDR1 | A9 | 3.3-V LVTTL |
| LEDR2 | A10 | 3.3-V LVTTL |
| LEDR3 | B10 | 3.3-V LVTTL |
| LEDR4 | D13 | 3.3-V LVTTL |
| LEDR5 | C13 | 3.3-V LVTTL |
| LEDR6 | E14 | 3.3-V LVTTL |
| LEDR7 | D14 | 3.3-V LVTTL |
| LEDR8 | A11 | 3.3-V LVTTL |
| LEDR9 | B11 | 3.3-V LVTTL |

O PBL exige no mínimo OV, Z, C e ERR, mas não determina qual LED representa cada flag. DEC-003 registra a associação herdada da base fornecida: LEDR0=OV, LEDR1=Z, LEDR2=C e LEDR3=ERR; a integração final PBL02 ainda deve ser verificada.

## Displays de sete segmentos

O manual §3.4, tabelas 3-6, pp. 28–29, descreve seis displays de ânodo comum. Cada segmento acende com nível baixo e apaga com nível alto. A tabela lista sete segmentos e um pino decimal DP por display. O PBL prioriza decimal com sinal; uso de DP não foi exigido.

| Display | Segmentos `[0,1,2,3,4,5,6]` nos pinos | DP (não requerido) |
|---|---|---|
| HEX0 | C14, E15, C15, C16, E16, D17, C17 | D15 |
| HEX1 | C18, D18, E18, B16, A17, A18, B17 | A16 |
| HEX2 | B20, A20, B19, A21, B21, C22, B22 | A19 |
| HEX3 | F21, E22, E21, C19, C20, D19, E17 | D22 |
| HEX4 | F18, E20, E19, J18, H19, F19, F20 | F17 |
| HEX5 | J20, K20, L18, N18, M20, N19, N20 | L19 |

Todos os pinos de segmentos/DP indicados são 3.3-V LVTTL. O manual §3.4, fig. 3-17, mapeia os índices `[0..6]` a `[a,b,c,d,e,f,g]`; `DP` é o índice 7. Os segmentos são ativos em nível baixo.

## Limitações e pendências de hardware

- Não inferir pin assignments do PBL1. A tabela deste documento é a baseline oficial aprovada em DEC-018; o pacote reformulado não traz `.qsf` ou `.qpf`.
- O manual declara o I/O standard 3.3-V LVTTL para os pinos listados; limites elétricos detalhados e uso de periféricos externos devem ser consultados no manual/esquemático se necessários.
- Validar na placa a sincronização/captura única de KEY conforme DEC-019.
- O clock, controles lógicos, polaridade e baseline de pin assignments estão definidos em DEC-008/011/018/019. Criar e validar o QSF quando os ports do top-level forem estabelecidos.
