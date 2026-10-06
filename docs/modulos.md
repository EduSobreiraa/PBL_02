# Módulos: inventário e candidatos

Os módulos PBL2 abaixo são candidatos conceituais; nenhum foi implementado e a divisão final ainda não foi aprovada. As funções/controles que já têm decisão devem seguir `docs/arquitetura.md` e `docs/interfaces.md`; detalhes de portas permanecem pendentes.

| ID / nome candidato | Responsabilidade | Entradas conceituais | Saídas conceituais | Dependências | Requisitos | Status |
|---|---|---|---|---|---|---|
| MOD-01 `top_module` | Integração externa do sistema | `MAX10_CLK1_50`, KEY0/KEY1, SW[9:0] | LEDs e seis displays conforme placa | Todos os blocos integrados | REQ-001–REQ-016 | Candidato; interface lógica decidida |
| MOD-02 `coefficient_storage` | Guardar `a`, `b`, `c` após três gravações ordenadas | SW[7:0], captura KEY0, reset KEY1 e clock | Coeficientes retidos | DFF; `always` restrito à descrição dos FF (DEC-014) | REQ-001, 002, 004, 011 | Candidato conforme DEC-008/009 |
| MOD-03 `input_control` | Encaminhar captura, reset e seleção de visualização | KEY0/KEY1, SW[9:8] | Captura de coeficientes e seleção x/y/x₁/x₂ | `coefficient_storage`, seletor de resultado | REQ-001, 004, 008, 011 | Candidato; sem execução separada (DEC-010/011) |
| MOD-04 `polynomial_path` | Calcular `y=ax²+bx+c` | `a`, `b`, `c`, `x` signed 8-bit | `y` signed 23-bit e OV aritmético | Soma/subtração, multiplicação | REQ-003, 007, 008; DEC-012 | Candidato; combinacional após carga |
| MOD-05 `roots_path` | Calcular discriminante e duas raízes válidas | `a`, `b`, `c` | `Δ`, `x₁`, `x₂`, erro/validade | Soma/subtração, multiplicação, raiz, divisão | REQ-005, 006, 008 | Proposto |
| MOD-06 `add_sub_unit` | Operações de soma/subtração | Operandos (larguras pendentes), controle de operação | Resultado e carry/overflow (semântica pendente) | Portas/FA estruturais | REQ-007, 008, 010 | Proposto |
| MOD-07 `multiplier_unit` | Multiplicação assinada conforme operações requeridas | Operandos e larguras pendentes | Produto com largura pendente | Lógica estrutural | REQ-005, 007, 008 | Proposto |
| MOD-08 `sqrt_unit` | Raiz quadrada usada na Opção 1 | Discriminante válido | Aproximação/raiz; precisão pendente | Lógica estrutural | REQ-005, 006, 008 | Proposto |
| MOD-09 `divider_unit` | Divisão usada no cálculo das raízes | Numerador, denominador, larguras pendentes | Quociente e condição de divisão inválida | Lógica estrutural | REQ-005, 006, 008 | Proposto |
| MOD-10 `result_selector` | Escolher `x`, `y`, `x₁` ou `x₂` para apresentação | Resultados e `SW[9:8]`: 00/01/10/11 nessa ordem | Valor selecionado continuamente | Caminhos de cálculo | REQ-004, 009; DEC-010/011 | Candidato conforme decisão |
| MOD-11 `display_conversion` | Codificar valor selecionado para displays decimais com sinal; indicar excesso com `------` | Resultado selecionado | Segmentos HEX0–HEX5 | Conversão e decodificadores | REQ-009; DEC-011/017/019 | Candidato; validar conversão na implementação |
| MOD-12 `status_flags` | Produzir OV, Z, C e ERR | Resultados e condições de cálculo | Quatro flags | Caminhos aritméticos | REQ-005, 007, 010 | Proposto |

## Módulos encontrados na base PBL1 (não são módulos PBL2 aprovados)

| Módulo existente | Portas observadas na fonte | Papel observado | Reutilização para PBL2 |
|---|---|---|---|
| `top_module` | `sw[9:0]`; `ledr[9:0]`; `hex0`–`hex5` `[6:0]` | Integra equação fixa do PBL1, displays e flags | Não atende ao armazenamento/operações PBL2; referência de topologia |
| `half_adder` | `a`, `b` → `sum`, `carry` (1 bit) | Somador de meio bit estrutural | Candidato a referência |
| `full_adder` | `a`, `b`, `cin` → `sum`, `cout` (1 bit) | Somador completo hierárquico | Candidato a referência |
| `adder_16bit` | `a[15:0]`, `b[15:0]`, `cin` → `sum[15:0]`, `cout`, `overflow` | Soma estrutural de 16 bits | Revisar largura/overflow antes de eventual adaptação |
| `mux2_1` | `d0`, `d1`, `sel` → `y` (1 bit) | MUX estrutural | Candidato a referência |
| `mux_7bit` | `d0[6:0]`, `d1[6:0]`, `sel` → `y[6:0]` | Seleção de padrão para segmentos | Candidato a referência |
| `abs_16bit` | `in_val[15:0]` → `out_abs[15:0]` | Valor absoluto em 16 bits | Revisar caso mínimo assinado e faixas |
| `pp_gen_8bit` | `a[7:0]`, `b` → `y[7:0]` | Produto parcial por AND | Referência de multiplicação sem sinal |
| `bcd_add3` | quatro bits `w,x,y,z` → quatro bits `a,b,c,d` | Célula de correção BCD | Candidato a referência |
| `bcd_step` | `pre[19:0]`, `y_bit` → `next_pre[19:0]` | Etapa de conversão binário para BCD | Candidato; estrutura sem laços deve ser revisada |
| `bin_to_bcd_16` | `bin_in[15:0]` → `bcd_out[19:0]` | Conversor de 16 bits para BCD | Limite de faixa deve ser revisto |
| `bcd_7seg`, `hex_7seg`, `off_7seg`, `minus_7seg` | dígitos/saídas de segmentos conforme fonte | Decodificação e padrões de display | Revisar polaridade com manual da placa |
| `display_controller` | BCD `[19:0]`, hex `[15:0]`, seleção hex, sinal negativo; seis saídas `[6:0]` | Controle dos displays no PBL1 | Interface/formato não é PBL2 aprovado |
| `error_detector` | `ov1`–`ov3` → `err_out` | OR de overflow legado | Não cobre sozinho erros de domínio do PBL2 |
| `zero_detector_16bit` | `in_val[15:0]` → `is_zero` | Detector de zero | Largura deve corresponder aos resultados PBL2 |
| `flags_controller` | quatro flags de 1 bit → quatro saídas de LED | Encaminha OV/Z/C/ERR | Candidato após definição de semântica |

Portas foram inventariadas da fonte compactada; não equivalem a uma interface PBL2. Testes e síntese do arquivo não foram executados nesta auditoria.
