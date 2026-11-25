module coordinate_frame_function_pipeline(input clk, input reset, input signed [7:0] a, input signed [7:0] b, input signed [7:0] c, input signed [9:0] x, output signed [24:0] f, output signed [17:0] derivative);
wire [7:0] a_magnitude;
wire [7:0] b_magnitude;
wire [9:0] x_magnitude;
wire [19:0] x_squared_full;
wire [17:0] bx_magnitude;
wire [17:0] ax_magnitude;
wire [17:0] bx_signed;
wire [17:0] ax_signed;
wire bx_sign;
wire ax_sign;
wire [16:0] x_squared_stage1;
wire [7:0] a_magnitude_stage1;
wire a_sign_stage1;
wire [17:0] bx_stage1;
wire [17:0] ax_stage1;
wire [7:0] b_stage1;
wire [7:0] c_stage1;
wire [24:0] ax2_magnitude_stage2;
wire [24:0] ax2_signed_stage2;
wire [24:0] sum_ax2_bx;
wire [17:0] sum_two_ax_b;

conditional_negate_8 abs_a (.value(a), .negate(a[7]), .result(a_magnitude));
conditional_negate_8 abs_b (.value(b), .negate(b[7]), .result(b_magnitude));
conditional_negate_10 abs_x (.value(x), .negate(x[9]), .result(x_magnitude));
multiply_unsigned_10x10 square_x (.lhs(x_magnitude), .rhs(x_magnitude), .product(x_squared_full));
multiply_unsigned_8x10 multiply_bx (.lhs(b_magnitude), .rhs(x_magnitude), .product(bx_magnitude));
multiply_unsigned_8x10 multiply_ax (.lhs(a_magnitude), .rhs(x_magnitude), .product(ax_magnitude));
xor bx_sign_gate(bx_sign, b[7], x[9]);
xor ax_sign_gate(ax_sign, a[7], x[9]);
conditional_negate_18 sign_bx (.value(bx_magnitude), .negate(bx_sign), .result(bx_signed));
conditional_negate_18 sign_ax (.value(ax_magnitude), .negate(ax_sign), .result(ax_signed));

dff_sync17_struct stage1_x_squared (.clk(clk), .reset(reset), .d(x_squared_full[16:0]), .q(x_squared_stage1));
dff_sync8_struct stage1_a_magnitude (.clk(clk), .reset(reset), .d(a_magnitude), .q(a_magnitude_stage1));
dff_sync_bit stage1_a_sign (.clk(clk), .reset(reset), .d(a[7]), .q(a_sign_stage1));
dff_sync18_struct stage1_bx (.clk(clk), .reset(reset), .d(bx_signed), .q(bx_stage1));
dff_sync18_struct stage1_ax (.clk(clk), .reset(reset), .d(ax_signed), .q(ax_stage1));
dff_sync8_struct stage1_b (.clk(clk), .reset(reset), .d(b), .q(b_stage1));
dff_sync8_struct stage1_c (.clk(clk), .reset(reset), .d(c), .q(c_stage1));

multiply_unsigned_8x17 multiply_ax2 (.lhs(a_magnitude_stage1), .rhs(x_squared_stage1), .product(ax2_magnitude_stage2));
conditional_negate_25 sign_ax2 (.value(ax2_magnitude_stage2), .negate(a_sign_stage1), .result(ax2_signed_stage2));
addsub_25 add_ax2_bx (.lhs(ax2_signed_stage2), .rhs({{7{bx_stage1[17]}}, bx_stage1}), .subtract(1'b0), .result(sum_ax2_bx));
addsub_18 add_two_ax_b (.lhs({ax_stage1[16:0], 1'b0}), .rhs({{10{b_stage1[7]}}, b_stage1}), .subtract(1'b0), .result(derivative));
addsub_25 add_c (.lhs(sum_ax2_bx), .rhs({{17{c_stage1[7]}}, c_stage1}), .subtract(1'b0), .result(f));
endmodule
