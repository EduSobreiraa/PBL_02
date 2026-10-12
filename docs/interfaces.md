# Interfaces aprovadas — DEC-030/031

## Top-level físico

`top_module`: entradas `MAX10_CLK1_50`, `KEY[1:0]`, `SW[9:0]`; saídas `LEDR[9:0]`, `HEX0` a `HEX5` de 7 bits. Clock P11 de 50MHz; KEY ativos baixos, LEDs ativos altos e segmentos ativos baixos [0..6]=a..g. Sem DP ou pino adicional. Assignments oficiais: `hardware.md`.

SW[7:0] é signed8, coeficientes durante três capturas e x depois; SW[9:8]=00/01/10/11 seleciona x/y/x1/x2. KEY0 captura; KEY1 reseta. SW estável na captura; teclas sincronizadas conforme DEC-019. Não há seletor HEX/DEC ou EXECUTAR.

## Contratos de módulos

| Módulo | Entradas | Saídas | Domínio/observação |
|---|---|---|---|
| coefficient_input | clk,key0_n,key1_n,sw[7:0] | a,b,c signed8 | Wrapper público preservado |
| coefficient_input_core | Mesmas entradas | a,b,c signed8; loaded privado | Loaded=progresso11, sem novo FF; até reset |
| full_adder | a,b,cin, 1 bit cada | sum,cout | Helper estrutural privado |
| add23 | lhs,rhs signed23 | sum signed23 | Exato no domínio do caminho y |
| add23_core | lhs,rhs signed23 | sum signed23; carry_out privado | Carry binário, carry inicial0 |
| sub18 | lhs,rhs signed18 | difference signed18 | Exato para b²−4ac; inversão+carry inicial1 |
| mul_s8_s8 | lhs,rhs signed8 | product signed16 | Todos os 65536 pares |
| mul_s8_u15 | lhs signed8,rhs unsigned15 | product signed22 | Pré-condição rhs em 0..16384; fora dela não promete exatidão signed22 |
| polynomial_y | a,b,c,x signed8 | y signed23,OV | Wrapper público, y exato, OV=0 |
| polynomial_y_core | a,b,c,x signed8 | y signed23,OV,carry_y privado | Carry da soma final subtotal+c |
| sqrt_u17 | radicand unsigned17 | root unsigned9,remainder unsigned10 | Contrato total: radicand=root²+remainder; 0<=remainder<2root+1 |
| divide_u9_u8 | dividend unsigned9,divisor unsigned8 | quotient unsigned9,remainder unsigned8,divide_by_zero | Divisor não nulo: N=QD+r; zero: Q=r=0 e flag1 |
| quadratic_roots | a,b,c signed8 | delta signed18,x1,x2 signed9,domain_error | Ramo+ em x1; ramo− em x2; erro em a0/Δ<0 força dados0 |
| result_select | x signed8,y signed23,x1,x2 signed9,sel[1:0] | value signed23 | Extensão explícita; x/y/x1/x2 |
| decimal_display | value signed23,invalid | HEX0..HEX5[6:0] | Double-dabble e máscaras DEC-030 |
| flag_ov_err | loaded,a signed8,delta signed18 | OV,ERR | OV0; ERR=loaded AND (a0 OU Δ negativo) |
| flag_z | value signed23,sel[1:0],ERR | Z | Zero do valor, mascarado para raiz inválida |
| flag_c | carry_y,loaded,sel[1:0] | C | Carry AND loaded AND seleção y |

## Conexões e precisão

Top instancia somente os cores de coeficientes e y, ligando loaded/carry_y às flags com fios e portas privadas normais. Não duplicar o circuito para manter wrappers nem usar referência hierárquica. Essa rota foi auditada em DEC-030 e substitui a pendência de detalhamento de DEC-029.

Extensões y: ax² signed22, bx signed16 e c signed8 viram signed23 antes das somas. x²/b² provêm de produto signed16 não negativo, bit15 comprovadamente zero e conversão exata para unsigned15. 4ac usa produto signed16 concatenado a dois zeros para signed18; b² recebe três zeros à esquerda.

Raízes: DEC-031 fixa S=floor(sqrtΔ) e resíduo E exatos; N±=-b±S signed10; A=abs(a) unsigned8; divisão |N|/A com Q/r. O intermediário signed10/F=1 deve permanecer acompanhado dos descritores de resíduo até a decisão de arredondamento final. F=1 sozinho não representa a raiz exata. Prova, fórmula de incremento e casos especiais estão em DEC-031. F=16 deixa de ser candidato a implementar.

## Exibição e validade

Faixa visual positiva0..999999, negativa-99999..-1; sinal em HEX5, zeros iniciais apagados. Se exceder, mostrar seis traços. Mesma máscara para resultados antes de loaded e raízes inválidas. Zero numérico em raiz inválida não acende Z. Nenhuma seleção limpa ERR; reset limpa loaded e ERR. Saídas podem apresentar transientes durante propagação combinacional; observar após acomodação.

## Estado

Interfaces e algoritmos decididos. Implementação, testes, fitting/timing e placa ainda exigem evidência nas TASKs; nenhum contrato presume teste executado.
