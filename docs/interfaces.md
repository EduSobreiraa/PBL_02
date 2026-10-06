# Interfaces do sistema

## Interface física e controles lógicos acordados

| Sinal | Direção | Largura | Função acordada | Estado / limite |
|---|---|---:|---|---|
| `SW[7:0]` | Entrada | 8 bits signed | Durante carga, valor de `a`, `b` ou `c`; depois, entrada `x` da Opção 2. `SW[7]` é o bit de sinal | Origem e largura definidas por PBL/DEC-009/011; sincronização/amostragem física a definir |
| `SW[9:8]` | Entrada | 2 bits | `00=x`, `01=y`, `10=x₁`, `11=x₂` | Seleção de visualização (DEC-011); níveis da chave seguem manual |
| `KEY0` | Entrada | 1 bit | Grava o valor de `SW[7:0]`; três capturas na ordem `a`, `b`, `c` | Ativo baixo; DEC-019 aprova sincronização em duas etapas e pulso único por pressão; validar na placa |
| `KEY1` | Entrada | 1 bit | Solicita reset lógico síncrono ativo alto | Ativo baixo fisicamente, invertido após sincronização em duas etapas; pressionar após energizar antes de iniciar (DEC-008/019) |
| `MAX10_CLK1_50` | Entrada | 1 bit, 50 MHz | Clock único da lógica sequencial, borda de subida | DEC-008; pinagem oficial no manual |
| `LEDR[9:0]` | Saída | 10 bits | Inclui OV, Z, C e ERR; base associa LEDR0=OV, LEDR1=Z, LEDR2=C, LEDR3=ERR | DEC-003; integração PBL02 precisa de verificação. LEDs ativos em nível alto |
| `HEX0`–`HEX5` | Saída | 6 × 7 bits | Valor selecionado em decimal com sinal prioritário; `------` se valor signed completo não couber | Índices [0..6]=[a..g], segmentos ativos em nível baixo; fallback DEC-017/019 |

Não existe seletor HEX/DEC nem botão EXECUTAR na interface acordada. Os resultados ficam disponíveis continuamente após a carga. `MAX10_CLK2_50` não foi escolhido.

Fontes: PBL §§3–4; manual DE10-Lite §§3.2–3.4; decisões DEC-008 a DEC-012. A tabela não é pin assignment QSF. Consulte `docs/hardware.md` para pinos físicos e pendências elétricas.

## Interfaces internas conceituais

Os contratos abaixo refletem funções acordadas, não declarações de portas HDL. A divisão física em módulos continua sendo proposta.

| Interface lógica | Direção | Largura/formato conhecido | Função | Estado |
|---|---|---|---|---|
| `a`, `b`, `c` | armazenamento → cálculo | 8-bit signed cada | Coeficientes capturados em ordem por três gravações | Acordado DEC-009; detalhes do deslocador e habilitação sujeitos a futura implementação |
| `x` | switch → avaliação | 8-bit signed | Entrada atual para `y=ax²+bx+c` | PBL/DEC-011 |
| `y` | avaliação → seletor | 23-bit signed | Resultado completo; OV aritmético para essa faixa é sempre 0 em entradas válidas | DEC-012; excesso de faixa visual usa DEC-017 |
| `x₁`, `x₂` | cálculo de raízes → seletor | Saída inteira signed; intermediários 25-bit signed, F=16 candidato | Raízes finais arredondadas conforme exceção DEC-007 | Precisão a validar em PEN-019 |
| Seletor de saída | `SW[9:8]` → apresentação | 2 bits | Selecionar x/y/x₁/x₂ | DEC-011 |
| Flags | cálculo/controle → LEDs | 1 bit conceitual por flag | OV, Z, C, ERR | ERR persistente até reset (DEC-001); OV em DEC-012; Z é zero do valor selecionado; origem C segue PEN-004 |

## Itens ainda não fechados

- Ratificar Z como detector de zero do valor selecionado e definir a origem/semântica de C: PEN-004.
- Precisão candidata F=16 ainda requer evidência: PEN-019.
- Baseline de pin assignments: PEN-014; QSF depende do top-level.
- Sincronização/amostragem e captura única de KEY: decididas em PEN-015; validação física posterior.
- Vetores de referência para validar larguras e precisão: PEN-019.

Não fixar portas HDL, formato de Δ/denominador/quocientes ou lógica de sincronização por inferência. O DFF pode usar `always @(posedge clk)` somente dentro de sua descrição, conforme DEC-014 e `docs/regras.md`.
