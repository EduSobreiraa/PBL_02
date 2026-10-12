# Interfaces aprovadas — DEC-030/031

## Top-level físico

`modulo_principal`: entradas `MAX10_CLK1_50`, `KEY[1:0]`, `SW[9:0]`; saídas `LEDR[9:0]`, `HEX0` a `HEX5` de 7 bits. Clock P11 de 50MHz; KEY ativos baixos, LEDs ativos altos e segmentos ativos baixos [0..6]=a..g. Sem DP ou pino adicional. Assignments oficiais: `hardware.md`.

SW[7:0] é signed8, coeficientes durante três capturas e x depois; SW[9:8]=00/01/10/11 seleciona x/y/x1/x2. KEY0 captura; KEY1 reseta. SW estável na captura; teclas sincronizadas conforme DEC-019. Não há seletor HEX/DEC ou EXECUTAR.

## Contratos de módulos

| Módulo | Entradas | Saídas | Domínio/observação |
|---|---|---|---|
| entrada_coeficientes | clk,key0_n,key1_n,sw[7:0] | a,b,c signed8 | Wrapper público preservado |
| entrada_coeficientes_nucleo | Mesmas entradas | a,b,c signed8; loaded privado | Loaded=progresso11, sem novo FF; até reset |
| somador_completo | a,b,cin, 1 bit cada | sum,cout | Helper estrutural privado |
| somador_23 | lhs,rhs signed23 | sum signed23 | Exato no domínio do caminho y |
| somador_23_nucleo | lhs,rhs signed23 | sum signed23; carry_out privado | Carry binário, carry inicial0 |
| subtrator_18 | lhs,rhs signed18 | difference signed18 | Exato para b²−4ac; inversão+carry inicial1 |
| multiplica_com_sinal_8_por_8 | lhs,rhs signed8 | product signed16 | Todos os 65536 pares |
| multiplica_com_sinal_8_por_sem_sinal_15 | lhs signed8,rhs unsigned15 | product signed22 | Pré-condição rhs em 0..16384; fora dela não promete exatidão signed22 |
| polinomio_y | a,b,c,x signed8 | y signed23,OV interno | Wrapper público, y exato; OV do core segue aritmética signed23 e fica0; LEDR0 segue DEC-039 |
| polinomio_y_nucleo | a,b,c,x signed8 | y signed23,OV interno,carry_y privado | Carry da soma final subtotal+c; saída OV interna não dirige LEDR0 |
| raiz_quadrada_17 | radicand unsigned17 | root unsigned9,remainder unsigned10 | Contrato total: radicand=root²+remainder; 0<=remainder<2root+1 |
| divisor_9_por_8 | dividend unsigned9,divisor unsigned8 | quotient unsigned9,remainder unsigned8,divide_by_zero | Divisor não nulo: N=QD+r; zero: Q=r=0 e flag1 |
| raizes_quadraticas | a,b,c signed8 | delta signed18,x1,x2 signed9,domain_error | Ramo+ em x1; ramo− em x2; erro em a0/Δ<0 força dados0 |
| seletor_resultado | x signed8,y signed23,x1,x2 signed9,sel[1:0] | value signed23 | Extensão explícita; x/y/x1/x2 |
| exibicao_decimal | value signed23,invalid | HEX0..HEX5[6:0],overflow_exibicao | Double-dabble; indicador de faixa decimal fora dos seis displays |
| sinaliza_overflow_erro | loaded,a signed8,delta signed18 | OV aritmético histórico,ERR | ERR=loaded AND (a0 OU Δ negativo); LED OV segue DEC-039 |
| sinaliza_zero | value signed23,sel[1:0],ERR | Z | Zero do valor, mascarado para raiz inválida |
| sinaliza_carry | carry_y,loaded,sel[1:0] | C | Carry AND loaded AND seleção y |

## Conexões e precisão

Top instancia somente os cores de coeficientes e y, ligando loaded/carry_y às flags com fios e portas privadas normais. Não duplicar o circuito para manter wrappers nem usar referência hierárquica. Essa rota foi auditada em DEC-030 e substitui a pendência de detalhamento de DEC-029.

Extensões y: ax² signed22, bx signed16 e c signed8 viram signed23 antes das somas. x²/b² provêm de produto signed16 não negativo, bit15 comprovadamente zero e conversão exata para unsigned15. 4ac usa produto signed16 concatenado a dois zeros para signed18; b² recebe três zeros à esquerda.

Raízes: DEC-031 fixa S=floor(sqrtΔ) e resíduo E exatos; N±=-b±S signed10; A=abs(a) unsigned8; divisão |N|/A com Q/r. O intermediário signed10/F=1 deve permanecer acompanhado dos descritores de resíduo até a decisão de arredondamento final. F=1 sozinho não representa a raiz exata. Prova, fórmula de incremento e casos especiais estão em DEC-031. F=16 deixa de ser candidato a implementar.

## Exibição e validade

Faixa visual positiva0..999999, negativa-99999..-1; sinal em HEX5, zeros iniciais apagados. Se exceder, mostrar seis traços. Para `y` selecionado com coeficientes carregados, o mesmo excesso também acende LEDR0 (OV), conforme DEC-039; em `x`/raízes, OV permanece baixo. A máscara por `invalid` não conta como excesso de faixa. Mesma máscara para resultados antes de loaded e raízes inválidas. Zero numérico em raiz inválida não acende Z. Nenhuma seleção limpa ERR; reset limpa loaded e ERR. Saídas podem apresentar transientes durante propagação combinacional; observar após acomodação.

## Estado

Interfaces e algoritmos decididos. Implementação, testes, fitting/timing e placa ainda exigem evidência nas TASKs; nenhum contrato presume teste executado.
