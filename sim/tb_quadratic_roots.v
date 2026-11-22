module tb_quadratic_roots(input signed [7:0] a, input signed [7:0] b, input signed [7:0] c, output signed [17:0] delta, output signed [8:0] x1, output signed [8:0] x2, output domain_error);
quadratic_roots dut (.a(a), .b(b), .c(c), .delta(delta), .x1(x1), .x2(x2), .domain_error(domain_error));
endmodule
