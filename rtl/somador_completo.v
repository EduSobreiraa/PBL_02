`timescale 1ns/1ps
// Soma dois bits e o vai-um de entrada, produzindo a soma e o vai-um de saída.
module somador_completo(input wire a, b, cin, output wire sum, cout);
    wire a_xor_b, a_and_b, termo_vai_um;
    xor (a_xor_b, a, b);
    xor (sum, a_xor_b, cin);
    and (a_and_b, a, b);
    and (termo_vai_um, a_xor_b, cin);
    or (cout, a_and_b, termo_vai_um);
endmodule
