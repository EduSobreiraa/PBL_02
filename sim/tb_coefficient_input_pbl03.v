module tb_coefficient_input_pbl03(input clk, input [1:0] key_n, input [8:0] sw, input processing_done, output signed [7:0] a1, output signed [7:0] b1, output signed [7:0] c1, output signed [7:0] a2, output signed [7:0] b2, output signed [7:0] c2, output start_pulse, output input_ready);
entrada_pbl03 dut (.clk(clk), .key_n(key_n), .sw(sw), .processing_done(processing_done), .a1(a1), .b1(b1), .c1(c1), .a2(a2), .b2(b2), .c2(c2), .start_pulse(start_pulse), .input_ready(input_ready));
endmodule
