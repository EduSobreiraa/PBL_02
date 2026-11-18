module avaliador_derivada_f1(input signed [7:0] a1, input signed [7:0] b1, input signed [9:0] x_cartesiano, output signed [17:0] f1_derivada);
wire [7:0] a1_magnitude;
wire [7:0] b1_magnitude;
wire [9:0] x_magnitude;
wire [17:0] ax_magnitude;
wire [17:0] ax_signed;
wire ax_negative;

conditional_negate_8 abs_a1 (.value(a1), .negate(a1[7]), .result(a1_magnitude));
conditional_negate_8 abs_b1 (.value(b1), .negate(b1[7]), .result(b1_magnitude));
conditional_negate_10 abs_x (.value(x_cartesiano), .negate(x_cartesiano[9]), .result(x_magnitude));
multiply_unsigned_8x10 multiply_ax (.lhs(a1_magnitude), .rhs(x_magnitude), .product(ax_magnitude));
xor (ax_negative, a1[7], x_cartesiano[9]);
conditional_negate_18 signed_ax (.value(ax_magnitude), .negate(ax_negative), .result(ax_signed));
addsub_18 add_two_ax_b (.lhs({ax_signed[16:0], 1'b0}), .rhs({{10{b1[7]}}, b1}), .subtract(1'b0), .result(f1_derivada));
endmodule
