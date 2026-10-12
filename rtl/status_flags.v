`timescale 1ns/1ps
module sinaliza_overflow_erro(input wire loaded,
                   input wire signed [7:0] a,
                   input wire signed [17:0] delta,
                   output wire OV, ERR);
    wire coeficiente_a_nao_zero, coeficiente_a_zero, dominio_invalido;
    or (coeficiente_a_nao_zero,a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7]);
    not (coeficiente_a_zero,coeficiente_a_nao_zero);
    or (dominio_invalido,coeficiente_a_zero,delta[17]);
    and (ERR,loaded,dominio_invalido);
    and zero_overflow(OV,1'b0,1'b0);
endmodule

module sinaliza_zero(input wire signed [22:0] value,
              input wire [1:0] sel,
              input wire ERR,
              output wire Z);
    wire divisor_nao_zero, valor_zero, raiz_invalida, valor_valido;
    or (divisor_nao_zero,value[0],value[1],value[2],value[3],value[4],value[5],value[6],value[7],value[8],value[9],value[10],value[11],value[12],value[13],value[14],value[15],value[16],value[17],value[18],value[19],value[20],value[21],value[22]);
    not (valor_zero,divisor_nao_zero);
    and (raiz_invalida,sel[1],ERR);
    not (valor_valido,raiz_invalida);
    and (Z,valor_zero,valor_valido);
endmodule

module sinaliza_carry(input wire carry_y, loaded,
              input wire [1:0] sel,
              output wire C);
    wire nao_selecao_bit1;
    not (nao_selecao_bit1,sel[1]);
    and (C,carry_y,loaded,sel[0],nao_selecao_bit1);
endmodule
