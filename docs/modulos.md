# Inventário de módulos — baseline DEC-030/031

A decomposição abaixo está aprovada. Entrada, soma/subtração, multiplicadores, caminho de y, caminho das raízes, seleção, display, flags e top-level estão implementados e aprovados; síntese/STA também executada. Os estados atualizados de cada implementação são registrados nas TASKs; este inventário também inclui entregas futuras.

| Grupo | Módulos/arquivos previstos | Responsabilidade | TASK |
|---|---|---|---|
| Entrada | entrada_coeficientes/entrada_coeficientes_nucleo em rtl/coefficient_input.v | 31 FF, captura a→b→c, reset e loaded | 002 |
| Células | somador_completo em rtl/arithmetic_cells.v; helpers de multiplicação locais a rtl/multipliers.v | Portas e encadeamentos explícitos | 003/007 |
| Soma/subtração | somador_23/somador_23_nucleo/subtrator_18 em rtl/add_sub.v | Ripple-carry; carry privado; domínio exato | 003 |
| Multiplicação | multiplica_com_sinal_8_por_8/multiplica_com_sinal_8_por_sem_sinal_15 em rtl/multipliers.v | Produtos parciais espaciais, domínio u15<=16384 | 007 |
| y | polinomio_y/polinomio_y_nucleo em rtl/polynomial_y.v | ((ax²)+(bx))+c, signed23 e carry final privado | 004 |
| Raiz quadrada | raiz_quadrada_17 em rtl/sqrt_u17.v | Nove estágios restauradores, raiz e resto exatos | 008 |
| Divisão | divisor_9_por_8 em rtl/divide_u9_u8.v | Nove estágios restauradores, quociente/resto/erro | 009 |
| Raízes | raizes_quadraticas em rtl/quadratic_roots.v | Δ, sqrt comum, dois divisores, round exato | 011 |
| Seleção | seletor_resultado em rtl/result_select.v | Mux4 estrutural, saída signed23 | 006 |
| Decimal | exibicao_decimal em rtl/decimal_display.v | Double-dabble, sinal, máscaras e segmentos | 006 |
| Flags | sinaliza_overflow_erro/sinaliza_zero/sinaliza_carry em rtl/status_flags.v | Zero armazenamento adicional | 010/018/019 |
| Integração | modulo_principal em rtl/top_module.v | Cores privados ligados a resultados/displays/LEDs | 012 |

Wrappers públicos não se duplicam com cores no top integrado. Nenhum registrador aritmético, FSM ou compartilhamento temporal. As larguras e portas completas estão em `interfaces.md`; prova numérica e alternativas em DEC-030/031. A síntese poderá otimizar portas, mas o DUT fonte deve continuar estrutural. Não reivindicar mínimo global de LEs antes de medir.

O legado PBL1 serve somente de referência de estilo; módulos, larguras e pinagem do PBL02 seguem esta baseline e `hardware.md`.
