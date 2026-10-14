`timescale 1ns/1ps
module modulo_principal(input wire MAX10_CLK1_50,input wire [1:0] KEY,input wire [9:0] SW,
    output wire [9:0] LEDR,output wire [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
    wire signed [7:0] coeficiente_a,coeficiente_b,coeficiente_c;
    wire signed [22:0] resultado_y,valor;
    wire signed [17:0] delta;
    wire signed [8:0] raiz_x1,raiz_x2;
    wire coeficientes_carregados,vai_um_y,OV_polinomio_nao_utilizado,erro_dominio_nao_utilizado;
    wire OV_aritmetico_nao_utilizado,overflow_exibicao,nao_selecionado_y,selecionado_y;
    wire resultado_selecionado,nao_carregado,incompleto,raiz_invalida,exibicao_invalida;
    wire [1:0] progresso_coeficientes;
    wire [41:0] hex_normal;
    entrada_coeficientes_nucleo captura_coeficientes(.clk(MAX10_CLK1_50),.key0_n(KEY[0]),.key1_n(KEY[1]),
        .sw(SW[7:0]),.a(coeficiente_a),.b(coeficiente_b),.c(coeficiente_c),.loaded(coeficientes_carregados),.progresso(progresso_coeficientes));
    polinomio_y_nucleo polinomio(.a(coeficiente_a),.b(coeficiente_b),.c(coeficiente_c),.x(SW[7:0]),.y(resultado_y),
        .OV(OV_polinomio_nao_utilizado),.carry_y(vai_um_y));
    raizes_quadraticas raizes(.a(coeficiente_a),.b(coeficiente_b),.c(coeficiente_c),.delta(delta),.x1(raiz_x1),.x2(raiz_x2),.domain_error(erro_dominio_nao_utilizado));
    seletor_resultado selecionar_resultado(.x(SW[7:0]),.y(resultado_y),.x1(raiz_x1),.x2(raiz_x2),.sel(SW[9:8]),.value(valor));
    sinaliza_overflow_erro erros(.loaded(coeficientes_carregados),.a(coeficiente_a),.delta(delta),.OV(OV_aritmetico_nao_utilizado),.ERR(LEDR[3]));
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
    not sem_y(nao_selecionado_y,SW[9]);
    and selecao_y(selecionado_y,nao_selecionado_y,SW[8]);
    and qualificar_overflow_exibicao(LEDR[0],coeficientes_carregados,selecionado_y,overflow_exibicao);
    exibicao_decimal apresentacao(.value(valor),.invalid(exibicao_invalida),.overflow_exibicao(overflow_exibicao),
        .HEX0(hex_normal[6:0]),.HEX1(hex_normal[13:7]),.HEX2(hex_normal[20:14]),.HEX3(hex_normal[27:21]),.HEX4(hex_normal[34:28]),.HEX5(hex_normal[41:35]));
    prompt_entrada_coeficientes prompt(.normal(hex_normal),.progresso(progresso_coeficientes),.loaded(coeficientes_carregados),
        .HEX0(HEX0),.HEX1(HEX1),.HEX2(HEX2),.HEX3(HEX3),.HEX4(HEX4),.HEX5(HEX5));
endmodule

module prompt_entrada_coeficientes(input wire [41:0] normal,input wire [1:0] progresso,input wire loaded,
    output wire [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
    wire n0,n1,na,pa,pb,pc;
    wire [6:0] a_part,b_part,c_part,n_part;
    not inv0(n0,progresso[0]); not inv1(n1,progresso[1]); not inv_load(na,loaded);
    and etapa_a(pa,n1,n0,na); and etapa_b(pb,n1,progresso[0],na); and etapa_c(pc,progresso[1],n0,na);
    // Segment indices 0..6 are a..g and active low: A=0001000, b=0000011, C=1000110.
    and a0(a_part[0],pa,1'b0); and a1(a_part[1],pa,1'b0); and a2(a_part[2],pa,1'b0); and a3(a_part[3],pa,1'b1);
    and a4(a_part[4],pa,1'b0); and a5(a_part[5],pa,1'b0); and a6(a_part[6],pa,1'b0);
    and b0(b_part[0],pb,1'b1); and b1(b_part[1],pb,1'b1); and b2(b_part[2],pb,1'b0); and b3(b_part[3],pb,1'b0);
    and b4(b_part[4],pb,1'b0); and b5(b_part[5],pb,1'b0); and b6(b_part[6],pb,1'b0);
    and c0(c_part[0],pc,1'b0); and c1(c_part[1],pc,1'b1); and c2(c_part[2],pc,1'b1); and c3(c_part[3],pc,1'b0);
    and c4(c_part[4],pc,1'b0); and c5(c_part[5],pc,1'b0); and c6(c_part[6],pc,1'b1);
    and n_part0(n_part[0],normal[0],loaded); and n_part1(n_part[1],normal[1],loaded);
    and n_part2(n_part[2],normal[2],loaded); and n_part3(n_part[3],normal[3],loaded);
    and n_part4(n_part[4],normal[4],loaded); and n_part5(n_part[5],normal[5],loaded); and n_part6(n_part[6],normal[6],loaded);
    or out0(HEX0[0],a_part[0],b_part[0],c_part[0],n_part[0]); or out1(HEX0[1],a_part[1],b_part[1],c_part[1],n_part[1]);
    or out2(HEX0[2],a_part[2],b_part[2],c_part[2],n_part[2]); or out3(HEX0[3],a_part[3],b_part[3],c_part[3],n_part[3]);
    or out4(HEX0[4],a_part[4],b_part[4],c_part[4],n_part[4]); or out5(HEX0[5],a_part[5],b_part[5],c_part[5],n_part[5]);
    or out6(HEX0[6],a_part[6],b_part[6],c_part[6],n_part[6]);
    mux_prompt_outros outros(.normal(normal[41:7]),.enable(loaded),.HEX1(HEX1),.HEX2(HEX2),.HEX3(HEX3),.HEX4(HEX4),.HEX5(HEX5));
endmodule

module mux_prompt_outros(input wire [34:0] normal,input wire enable,output wire [6:0] HEX1,HEX2,HEX3,HEX4,HEX5);
    wire disabled;
    not invert_enable(disabled,enable);
    wire [34:0] normal_term;
    and h10(normal_term[0],normal[0],enable); and h11(normal_term[1],normal[1],enable); and h12(normal_term[2],normal[2],enable); and h13(normal_term[3],normal[3],enable); and h14(normal_term[4],normal[4],enable); and h15(normal_term[5],normal[5],enable); and h16(normal_term[6],normal[6],enable);
    and h20(normal_term[7],normal[7],enable); and h21(normal_term[8],normal[8],enable); and h22(normal_term[9],normal[9],enable); and h23(normal_term[10],normal[10],enable); and h24(normal_term[11],normal[11],enable); and h25(normal_term[12],normal[12],enable); and h26(normal_term[13],normal[13],enable);
    and h30(normal_term[14],normal[14],enable); and h31(normal_term[15],normal[15],enable); and h32(normal_term[16],normal[16],enable); and h33(normal_term[17],normal[17],enable); and h34(normal_term[18],normal[18],enable); and h35(normal_term[19],normal[19],enable); and h36(normal_term[20],normal[20],enable);
    and h40(normal_term[21],normal[21],enable); and h41(normal_term[22],normal[22],enable); and h42(normal_term[23],normal[23],enable); and h43(normal_term[24],normal[24],enable); and h44(normal_term[25],normal[25],enable); and h45(normal_term[26],normal[26],enable); and h46(normal_term[27],normal[27],enable);
    and h50(normal_term[28],normal[28],enable); and h51(normal_term[29],normal[29],enable); and h52(normal_term[30],normal[30],enable); and h53(normal_term[31],normal[31],enable); and h54(normal_term[32],normal[32],enable); and h55(normal_term[33],normal[33],enable); and h56(normal_term[34],normal[34],enable);
    or o10(HEX1[0],normal_term[0],disabled); or o11(HEX1[1],normal_term[1],disabled); or o12(HEX1[2],normal_term[2],disabled); or o13(HEX1[3],normal_term[3],disabled); or o14(HEX1[4],normal_term[4],disabled); or o15(HEX1[5],normal_term[5],disabled); or o16(HEX1[6],normal_term[6],disabled);
    or o20(HEX2[0],normal_term[7],disabled); or o21(HEX2[1],normal_term[8],disabled); or o22(HEX2[2],normal_term[9],disabled); or o23(HEX2[3],normal_term[10],disabled); or o24(HEX2[4],normal_term[11],disabled); or o25(HEX2[5],normal_term[12],disabled); or o26(HEX2[6],normal_term[13],disabled);
    or o30(HEX3[0],normal_term[14],disabled); or o31(HEX3[1],normal_term[15],disabled); or o32(HEX3[2],normal_term[16],disabled); or o33(HEX3[3],normal_term[17],disabled); or o34(HEX3[4],normal_term[18],disabled); or o35(HEX3[5],normal_term[19],disabled); or o36(HEX3[6],normal_term[20],disabled);
    or o40(HEX4[0],normal_term[21],disabled); or o41(HEX4[1],normal_term[22],disabled); or o42(HEX4[2],normal_term[23],disabled); or o43(HEX4[3],normal_term[24],disabled); or o44(HEX4[4],normal_term[25],disabled); or o45(HEX4[5],normal_term[26],disabled); or o46(HEX4[6],normal_term[27],disabled);
    or o50(HEX5[0],normal_term[28],disabled); or o51(HEX5[1],normal_term[29],disabled); or o52(HEX5[2],normal_term[30],disabled); or o53(HEX5[3],normal_term[31],disabled); or o54(HEX5[4],normal_term[32],disabled); or o55(HEX5[5],normal_term[33],disabled); or o56(HEX5[6],normal_term[34],disabled);
endmodule
