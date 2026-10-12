# Inventário de módulos — baseline DEC-030/031

A decomposição abaixo está aprovada. Entrada, soma/subtração, multiplicadores, caminho de y, caminho das raízes, seleção, display, flags e top-level estão implementados e aprovados; síntese/STA também executada. Os estados atualizados de cada implementação são registrados nas TASKs; este inventário também inclui entregas futuras.

| Grupo | Módulos/arquivos previstos | Responsabilidade | TASK |
|---|---|---|---|
| Entrada | coefficient_input/coefficient_input_core em rtl/coefficient_input.v | 31 FF, captura a→b→c, reset e loaded | 002 |
| Células | full_adder em rtl/arithmetic_cells.v; helpers de multiplicação locais a rtl/multipliers.v | Portas e encadeamentos explícitos | 003/007 |
| Soma/subtração | add23/add23_core/sub18 em rtl/add_sub.v | Ripple-carry; carry privado; domínio exato | 003 |
| Multiplicação | mul_s8_s8/mul_s8_u15 em rtl/multipliers.v | Produtos parciais espaciais, domínio u15<=16384 | 007 |
| y | polynomial_y/polynomial_y_core em rtl/polynomial_y.v | ((ax²)+(bx))+c, signed23 e carry final privado | 004 |
| Raiz quadrada | sqrt_u17 em rtl/sqrt_u17.v | Nove estágios restauradores, raiz e resto exatos | 008 |
| Divisão | divide_u9_u8 em rtl/divide_u9_u8.v | Nove estágios restauradores, quociente/resto/erro | 009 |
| Raízes | quadratic_roots em rtl/quadratic_roots.v | Δ, sqrt comum, dois divisores, round exato | 011 |
| Seleção | result_select em rtl/result_select.v | Mux4 estrutural, saída signed23 | 006 |
| Decimal | decimal_display em rtl/decimal_display.v | Double-dabble, sinal, máscaras e segmentos | 006 |
| Flags | flag_ov_err/flag_z/flag_c em rtl/status_flags.v | Zero armazenamento adicional | 010/018/019 |
| Integração | top_module em rtl/top_module.v | Cores privados ligados a resultados/displays/LEDs | 012 |

Wrappers públicos não se duplicam com cores no top integrado. Nenhum registrador aritmético, FSM ou compartilhamento temporal. As larguras e portas completas estão em `interfaces.md`; prova numérica e alternativas em DEC-030/031. A síntese poderá otimizar portas, mas o DUT fonte deve continuar estrutural. Não reivindicar mínimo global de LEs antes de medir.

O legado PBL1 serve somente de referência de estilo; módulos, larguras e pinagem do PBL02 seguem esta baseline e `hardware.md`.
