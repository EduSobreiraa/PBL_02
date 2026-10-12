`timescale 1ns/1ps
// DEC-030: public wrapper preserves the approved interface.
module polynomial_y(input wire signed [7:0] a, b, c, x,
    output wire signed [22:0] y, output wire OV);
    wire unused_carry;
    polynomial_y_core core(.a(a), .b(b), .c(c), .x(x),
        .y(y), .OV(OV), .carry_y(unused_carry));
endmodule

// Purely combinational composition: ((a*x*x)+(b*x))+c.
module polynomial_y_core(input wire signed [7:0] a, b, c, x,
    output wire signed [22:0] y, output wire OV, output wire carry_y);
    wire signed [15:0] square_full, bx;
    wire [14:0] square;
    wire signed [21:0] ax2;
    wire signed [22:0] ax2_extended, bx_extended, c_extended, subtotal;
    wire unused_subtotal_carry;

    mul_s8_s8 square_multiplier(.lhs(x), .rhs(x), .product(square_full));
    // x*x is 0..16384; bit 15 is always zero, so this slice is exact.
    assign square = square_full[14:0];
    mul_s8_u15 quadratic_multiplier(.lhs(a), .rhs(square), .product(ax2));
    mul_s8_s8 linear_multiplier(.lhs(b), .rhs(x), .product(bx));
    assign ax2_extended = {ax2[21], ax2};
    assign bx_extended = {{7{bx[15]}}, bx};
    assign c_extended = {{15{c[7]}}, c};
    add23_core subtotal_adder(.lhs(ax2_extended), .rhs(bx_extended),
        .sum(subtotal), .carry_out(unused_subtotal_carry));
    add23_core final_adder(.lhs(subtotal), .rhs(c_extended),
        .sum(y), .carry_out(carry_y));
    assign OV = 1'b0;
endmodule
