`timescale 1ns/1ns
module tb_quadratic_roots(input system_reset, input start_accepted, input root_enable,
    input signed [7:0] a, input signed [7:0] b, input signed [7:0] c,
    output signed [17:0] delta, output signed [8:0] x1, output signed [8:0] x2,
    output domain_error, output result_valid);
reg clk;
initial clk = 1'b0;
always #5 clk = ~clk;
quadratic_roots dut (.clk(clk), .system_reset(system_reset), .start_accepted(start_accepted),
    .root_enable(root_enable), .a(a), .b(b), .c(c), .delta(delta), .x1(x1), .x2(x2),
    .domain_error(domain_error), .result_valid(result_valid));
endmodule
