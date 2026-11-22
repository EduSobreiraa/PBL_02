module ramo_raizes(input wire [9:0] numerator, input wire [7:0] magnitude_a,
    input wire sign_a, input wire [9:0] square_remainder, input wire plus_branch,valid,
    output wire [8:0] result);
    wire [9:0] magnitude_numerador;
    wire [8:0] quociente,quociente_arredondado,resultado_com_sinal;
    wire [7:0] resto;
    wire divisor_zero,numerador_nao_zero,numerador_positivo,ramo_negativo,correcao_ramo_positivo,correcao_ramo_negativo,correcao_arredondamento;
    wire resto_nao_zero,quadrado_exato,condicao_arredondamento,arredondar_para_cima,sinal_resultado;
    // A divisão usa o módulo do numerador, e o sinal é aplicado ao final.
    nega_condicional_10 modulo_sinalizado(.value(numerator),.negate(numerator[9]),.result(magnitude_numerador));
    // A magnitude do numerador cabe em nove bits para os coeficientes permitidos.
    divisor_9_por_8 divide(.dividend(magnitude_numerador[8:0]),.divisor(magnitude_a),.quotient(quociente),.remainder(resto),.divide_by_zero(divisor_zero));
    or nn(numerador_nao_zero,numerator[0],numerator[1],numerator[2],numerator[3],numerator[4],numerator[5],numerator[6],numerator[7],numerator[8]);
    wire numerador_nao_negativo;
    not nns(numerador_nao_negativo,numerator[9]);
    and np(numerador_positivo,numerador_nao_negativo,numerador_nao_zero);
    not mb(ramo_negativo,plus_branch);
    and cp(correcao_ramo_positivo,plus_branch,numerador_positivo);
    and cm(correcao_ramo_negativo,ramo_negativo,numerator[9]);
    or co(correcao_arredondamento,correcao_ramo_positivo,correcao_ramo_negativo);
    or rn(resto_nao_zero,resto[0],resto[1],resto[2],resto[3],resto[4],resto[5],resto[6],resto[7]);
    nor se(quadrado_exato,square_remainder[0],square_remainder[1],square_remainder[2],square_remainder[3],square_remainder[4],square_remainder[5],square_remainder[6],square_remainder[7],square_remainder[8],square_remainder[9]);
    // A fração e o resto da raiz definem se o quociente será arredondado.
    or rc(condicao_arredondamento,resto_nao_zero,quadrado_exato,correcao_arredondamento);
    and u(arredondar_para_cima,quociente[0],condicao_arredondamento);
    incrementa_9 arredondamento(.value({1'b0,quociente[8:1]}),.increment(arredondar_para_cima),.result(quociente_arredondado));
    xor rs(sinal_resultado,numerator[9],sign_a);
    nega_condicional_9 restore_sign(.value(quociente_arredondado),.negate(sinal_resultado),.result(resultado_com_sinal));
    and mask0(result[0],resultado_com_sinal[0],valid);
    and mask1(result[1],resultado_com_sinal[1],valid);
    and mask2(result[2],resultado_com_sinal[2],valid);
    and mask3(result[3],resultado_com_sinal[3],valid);
    and mask4(result[4],resultado_com_sinal[4],valid);
    and mask5(result[5],resultado_com_sinal[5],valid);
    and mask6(result[6],resultado_com_sinal[6],valid);
    and mask7(result[7],resultado_com_sinal[7],valid);
    and mask8(result[8],resultado_com_sinal[8],valid);
endmodule
