`timescale 1ns/1ps
// DEC-030: public wrapper preserves the approved interface.
module polinomio_y(input wire signed [7:0] a, b, c, x,
    output wire signed [22:0] y, output wire OV);
    wire vai_um_nao_utilizado;
    polinomio_y_nucleo nucleo(.a(a), .b(b), .c(c), .x(x),
        .y(y), .OV(OV), .carry_y(vai_um_nao_utilizado));
endmodule

// Purely combinational composition: ((coeficiente_a*entrada_x*entrada_x)+(coeficiente_b*entrada_x))+coeficiente_c.
module polinomio_y_nucleo(input wire signed [7:0] a, b, c, x,
    output wire signed [22:0] y, output wire OV, output wire carry_y);
    wire signed [15:0] quadrado_completo, b_x;
    wire [14:0] quadrado;
    wire signed [21:0] a_x_quadrado;
    wire signed [22:0] ax2_estendido, bx_estendido, c_estendido, subtotal;
    wire vai_um_subtotal_nao_utilizado;

    multiplica_com_sinal_8_por_8 multiplicador_quadrado(.lhs(x), .rhs(x), .product(quadrado_completo));
    // x*x is 0..16384; bit 15 is always zero, so this slice is exact.
    multiplica_com_sinal_8_por_sem_sinal_15 multiplicador_quadratico(.lhs(a), .rhs(quadrado_completo[14:0]), .product(a_x_quadrado));
    multiplica_com_sinal_8_por_8 multiplicador_linear(.lhs(b), .rhs(x), .product(b_x));
    somador_23_nucleo somador_subtotal(.lhs({a_x_quadrado[21],a_x_quadrado}), .rhs({{7{b_x[15]}},b_x}),
        .sum(subtotal), .carry_out(vai_um_subtotal_nao_utilizado));
    somador_23_nucleo somador_final(.lhs(subtotal), .rhs({{15{c[7]}},c}),
        .sum(y), .carry_out(carry_y));
    and zero_overflow(OV,1'b0,1'b0);
endmodule
