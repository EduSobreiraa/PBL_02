module avaliador_quadratico_f1(input signed [7:0] a1, input signed [7:0] b1, input signed [7:0] c1, input signed [9:0] x_cartesiano, output signed [24:0] f1_y);
wire [7:0] a1_magnitude;
wire [7:0] b1_magnitude;
wire [9:0] x_magnitude;
wire [19:0] x_squared_full;
wire [24:0] a1_x_squared_magnitude;
wire [24:0] a1_x_squared;
wire [17:0] b1_x_magnitude;
wire [17:0] b1_x;
wire [24:0] sum_ax2_bx;
wire b1_x_negative;

conditional_negate_8 abs_a1 (.value(a1), .negate(a1[7]), .result(a1_magnitude));
conditional_negate_8 abs_b1 (.value(b1), .negate(b1[7]), .result(b1_magnitude));
conditional_negate_10 abs_x (.value(x_cartesiano), .negate(x_cartesiano[9]), .result(x_magnitude));
multiply_unsigned_10x10 square_x (.lhs(x_magnitude), .rhs(x_magnitude), .product(x_squared_full));
multiply_unsigned_8x17 multiply_ax2 (.lhs(a1_magnitude), .rhs(x_squared_full[16:0]), .product(a1_x_squared_magnitude));
conditional_negate_25 signed_ax2 (.value(a1_x_squared_magnitude), .negate(a1[7]), .result(a1_x_squared));
multiply_unsigned_8x10 multiply_bx (.lhs(b1_magnitude), .rhs(x_magnitude), .product(b1_x_magnitude));
xor (b1_x_negative, b1[7], x_cartesiano[9]);
conditional_negate_18 signed_bx (.value(b1_x_magnitude), .negate(b1_x_negative), .result(b1_x));
addsub_25 add_ax2_bx (.lhs(a1_x_squared), .rhs({{7{b1_x[17]}}, b1_x}), .subtract(1'b0), .result(sum_ax2_bx));
addsub_25 add_c (.lhs(sum_ax2_bx), .rhs({{17{c1[7]}}, c1}), .subtract(1'b0), .result(f1_y));
endmodule
