`timescale 1ns/1ps
// DEC-031: nine spatial restoring stages; no storage.
module divisor_9_por_8(input wire [8:0] dividend, input wire [7:0] divisor,
    output wire [8:0] quotient, output wire [7:0] remainder, output wire divide_by_zero);
    wire divisor_nao_zero;
    wire [7:0] divisor_efetivo;
    wire [8:0] quociente_bruto;
    wire [7:0] resto_etapa_0;
    wire [7:0] resto_etapa_1;
    wire [7:0] resto_etapa_2;
    wire [7:0] resto_etapa_3;
    wire [7:0] resto_etapa_4;
    wire [7:0] resto_etapa_5;
    wire [7:0] resto_etapa_6;
    wire [7:0] resto_etapa_7;
    wire [7:0] resto_etapa_8;
    wire [7:0] resto_etapa_9;
    nor zero_detect(divide_by_zero, divisor[0], divisor[1], divisor[2], divisor[3], divisor[4], divisor[5], divisor[6], divisor[7]);
    not valid_detect(divisor_nao_zero, divide_by_zero);
    or effective_bit0(divisor_efetivo[0], divisor[0], divide_by_zero);
    etapa_divisao stage0(.previous(8'b0), .next_bit(dividend[8]), .divisor({divisor[7:1],divisor_efetivo[0]}), .remainder(resto_etapa_1), .quotient_bit(quociente_bruto[8]));
    etapa_divisao stage1(.previous(resto_etapa_1), .next_bit(dividend[7]), .divisor({divisor[7:1],divisor_efetivo[0]}), .remainder(resto_etapa_2), .quotient_bit(quociente_bruto[7]));
    etapa_divisao stage2(.previous(resto_etapa_2), .next_bit(dividend[6]), .divisor({divisor[7:1],divisor_efetivo[0]}), .remainder(resto_etapa_3), .quotient_bit(quociente_bruto[6]));
    etapa_divisao stage3(.previous(resto_etapa_3), .next_bit(dividend[5]), .divisor({divisor[7:1],divisor_efetivo[0]}), .remainder(resto_etapa_4), .quotient_bit(quociente_bruto[5]));
    etapa_divisao stage4(.previous(resto_etapa_4), .next_bit(dividend[4]), .divisor({divisor[7:1],divisor_efetivo[0]}), .remainder(resto_etapa_5), .quotient_bit(quociente_bruto[4]));
    etapa_divisao stage5(.previous(resto_etapa_5), .next_bit(dividend[3]), .divisor({divisor[7:1],divisor_efetivo[0]}), .remainder(resto_etapa_6), .quotient_bit(quociente_bruto[3]));
    etapa_divisao stage6(.previous(resto_etapa_6), .next_bit(dividend[2]), .divisor({divisor[7:1],divisor_efetivo[0]}), .remainder(resto_etapa_7), .quotient_bit(quociente_bruto[2]));
    etapa_divisao stage7(.previous(resto_etapa_7), .next_bit(dividend[1]), .divisor({divisor[7:1],divisor_efetivo[0]}), .remainder(resto_etapa_8), .quotient_bit(quociente_bruto[1]));
    etapa_divisao stage8(.previous(resto_etapa_8), .next_bit(dividend[0]), .divisor({divisor[7:1],divisor_efetivo[0]}), .remainder(resto_etapa_9), .quotient_bit(quociente_bruto[0]));
    and mask_q0(quotient[0], quociente_bruto[0], divisor_nao_zero);
    and mask_q1(quotient[1], quociente_bruto[1], divisor_nao_zero);
    and mask_q2(quotient[2], quociente_bruto[2], divisor_nao_zero);
    and mask_q3(quotient[3], quociente_bruto[3], divisor_nao_zero);
    and mask_q4(quotient[4], quociente_bruto[4], divisor_nao_zero);
    and mask_q5(quotient[5], quociente_bruto[5], divisor_nao_zero);
    and mask_q6(quotient[6], quociente_bruto[6], divisor_nao_zero);
    and mask_q7(quotient[7], quociente_bruto[7], divisor_nao_zero);
    and mask_q8(quotient[8], quociente_bruto[8], divisor_nao_zero);
    and mask_r0(remainder[0], resto_etapa_9[0], divisor_nao_zero);
    and mask_r1(remainder[1], resto_etapa_9[1], divisor_nao_zero);
    and mask_r2(remainder[2], resto_etapa_9[2], divisor_nao_zero);
    and mask_r3(remainder[3], resto_etapa_9[3], divisor_nao_zero);
    and mask_r4(remainder[4], resto_etapa_9[4], divisor_nao_zero);
    and mask_r5(remainder[5], resto_etapa_9[5], divisor_nao_zero);
    and mask_r6(remainder[6], resto_etapa_9[6], divisor_nao_zero);
    and mask_r7(remainder[7], resto_etapa_9[7], divisor_nao_zero);
endmodule

module etapa_divisao(input wire [7:0] previous, input wire next_bit,
    input wire [7:0] divisor, output wire [7:0] remainder, output wire quotient_bit);
    wire [8:0] diferenca, divisor_invertido;
    wire [8:0] vai_um;
    wire restaurar;
    wire [7:0] manter_tentativa, manter_diferenca;
    not inv0(divisor_invertido[0], divisor[0]);
    not inv1(divisor_invertido[1], divisor[1]);
    not inv2(divisor_invertido[2], divisor[2]);
    not inv3(divisor_invertido[3], divisor[3]);
    not inv4(divisor_invertido[4], divisor[4]);
    not inv5(divisor_invertido[5], divisor[5]);
    not inv6(divisor_invertido[6], divisor[6]);
    not inv7(divisor_invertido[7], divisor[7]);
    somador_completo_divisao sub0(.a(next_bit), .b(divisor_invertido[0]), .cin(1'b1), .sum(diferenca[0]), .cout(vai_um[1]));
    somador_completo_divisao sub1(.a(previous[0]), .b(divisor_invertido[1]), .cin(vai_um[1]), .sum(diferenca[1]), .cout(vai_um[2]));
    somador_completo_divisao sub2(.a(previous[1]), .b(divisor_invertido[2]), .cin(vai_um[2]), .sum(diferenca[2]), .cout(vai_um[3]));
    somador_completo_divisao sub3(.a(previous[2]), .b(divisor_invertido[3]), .cin(vai_um[3]), .sum(diferenca[3]), .cout(vai_um[4]));
    somador_completo_divisao sub4(.a(previous[3]), .b(divisor_invertido[4]), .cin(vai_um[4]), .sum(diferenca[4]), .cout(vai_um[5]));
    somador_completo_divisao sub5(.a(previous[4]), .b(divisor_invertido[5]), .cin(vai_um[5]), .sum(diferenca[5]), .cout(vai_um[6]));
    somador_completo_divisao sub6(.a(previous[5]), .b(divisor_invertido[6]), .cin(vai_um[6]), .sum(diferenca[6]), .cout(vai_um[7]));
    somador_completo_divisao sub7(.a(previous[6]), .b(divisor_invertido[7]), .cin(vai_um[7]), .sum(diferenca[7]), .cout(vai_um[8]));
    somador_completo_divisao sub8(.a(previous[7]), .b(1'b1), .cin(vai_um[8]), .sum(diferenca[8]), .cout(quotient_bit));
    not restore_select(restaurar, quotient_bit);
    // Selected resultado is always < divisor <=255, hence bit8 is zero.
    and trial0(manter_tentativa[0], next_bit, restaurar);
    and diff0(manter_diferenca[0], diferenca[0], quotient_bit);
    or select0(remainder[0], manter_tentativa[0], manter_diferenca[0]);
    and trial1(manter_tentativa[1], previous[0], restaurar);
    and diff1(manter_diferenca[1], diferenca[1], quotient_bit);
    or select1(remainder[1], manter_tentativa[1], manter_diferenca[1]);
    and trial2(manter_tentativa[2], previous[1], restaurar);
    and diff2(manter_diferenca[2], diferenca[2], quotient_bit);
    or select2(remainder[2], manter_tentativa[2], manter_diferenca[2]);
    and trial3(manter_tentativa[3], previous[2], restaurar);
    and diff3(manter_diferenca[3], diferenca[3], quotient_bit);
    or select3(remainder[3], manter_tentativa[3], manter_diferenca[3]);
    and trial4(manter_tentativa[4], previous[3], restaurar);
    and diff4(manter_diferenca[4], diferenca[4], quotient_bit);
    or select4(remainder[4], manter_tentativa[4], manter_diferenca[4]);
    and trial5(manter_tentativa[5], previous[4], restaurar);
    and diff5(manter_diferenca[5], diferenca[5], quotient_bit);
    or select5(remainder[5], manter_tentativa[5], manter_diferenca[5]);
    and trial6(manter_tentativa[6], previous[5], restaurar);
    and diff6(manter_diferenca[6], diferenca[6], quotient_bit);
    or select6(remainder[6], manter_tentativa[6], manter_diferenca[6]);
    and trial7(manter_tentativa[7], previous[6], restaurar);
    and diff7(manter_diferenca[7], diferenca[7], quotient_bit);
    or select7(remainder[7], manter_tentativa[7], manter_diferenca[7]);
endmodule

module somador_completo_divisao(input wire a, b, cin, output wire sum, cout);
    wire propaga_vai_um, gera_vai_um, vai_um_propagado;
    xor p(propaga_vai_um, a, b);
    xor s(sum, propaga_vai_um, cin);
    and g(gera_vai_um, a, b);
    and h(vai_um_propagado, propaga_vai_um, cin);
    or coeficiente_c(cout, gera_vai_um, vai_um_propagado);
endmodule
