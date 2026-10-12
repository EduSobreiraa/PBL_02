`timescale 1ns/1ps
module modulo_principal(input wire MAX10_CLK1_50,input wire [1:0] KEY,input wire [9:0] SW,
    output wire [9:0] LEDR,output wire [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
    wire signed [7:0] coeficiente_a,coeficiente_b,coeficiente_c;
    wire signed [22:0] resultado_y,valor;
    wire signed [17:0] delta;
    wire signed [8:0] raiz_x1,raiz_x2;
    wire coeficientes_carregados,vai_um_y,OV_polinomio_nao_utilizado,erro_dominio_nao_utilizado;
    wire resultado_selecionado,nao_carregado,incompleto,raiz_invalida,exibicao_invalida;
    entrada_coeficientes_nucleo captura_coeficientes(.clk(MAX10_CLK1_50),.key0_n(KEY[0]),.key1_n(KEY[1]),
        .sw(SW[7:0]),.a(coeficiente_a),.b(coeficiente_b),.c(coeficiente_c),.loaded(coeficientes_carregados));
    polinomio_y_nucleo polinomio(.a(coeficiente_a),.b(coeficiente_b),.c(coeficiente_c),.x(SW[7:0]),.y(resultado_y),
        .OV(OV_polinomio_nao_utilizado),.carry_y(vai_um_y));
    raizes_quadraticas raizes(.a(coeficiente_a),.b(coeficiente_b),.c(coeficiente_c),.delta(delta),.x1(raiz_x1),.x2(raiz_x2),.domain_error(erro_dominio_nao_utilizado));
    seletor_resultado selecionar_resultado(.x(SW[7:0]),.y(resultado_y),.x1(raiz_x1),.x2(raiz_x2),.sel(SW[9:8]),.value(valor));
    sinaliza_overflow_erro erros(.loaded(coeficientes_carregados),.a(coeficiente_a),.delta(delta),.OV(LEDR[0]),.ERR(LEDR[3]));
    sinaliza_zero zero(.value(valor),.sel(SW[9:8]),.ERR(LEDR[3]),.Z(LEDR[1]));
    sinaliza_carry vai_um(.carry_y(vai_um_y),.loaded(coeficientes_carregados),.sel(SW[9:8]),.C(LEDR[2]));
    and led4_off(LEDR[4],1'b0,1'b0);
    and led5_off(LEDR[5],1'b0,1'b0);
    and led6_off(LEDR[6],1'b0,1'b0);
    and led7_off(LEDR[7],1'b0,1'b0);
    and led8_off(LEDR[8],1'b0,1'b0);
    and led9_off(LEDR[9],1'b0,1'b0);
    or selecionado(resultado_selecionado,SW[9],SW[8]);
    not nao_carregado_porta(nao_carregado,coeficientes_carregados);
    and pendente(incompleto,resultado_selecionado,nao_carregado);
    and erro_raiz(raiz_invalida,SW[9],LEDR[3]);
    or invalidar_apresentacao(exibicao_invalida,incompleto,raiz_invalida);
    exibicao_decimal apresentacao(.value(valor),.invalid(exibicao_invalida),
        .HEX0(HEX0),.HEX1(HEX1),.HEX2(HEX2),.HEX3(HEX3),.HEX4(HEX4),.HEX5(HEX5));
endmodule
