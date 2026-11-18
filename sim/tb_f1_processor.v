`timescale 1ns/1ps
module tb_f1_processor(input clk, input system_reset, input start_pulse, input signed [7:0] a1, input signed [7:0] b1, input signed [7:0] c1, input signed [9:0] x_cartesiano, input signed [9:0] y_cartesiano, output busy, output done, output error_a_zero, output error_vertex, output display_enable, output f1_hit, output f1_derivada_hit, input [1:0] key_n, input [8:0] sw, output entry_system_reset, output entry_start_pulse, output entry_input_ready, output entry_processing_done, output entry_busy, output signed [7:0] entry_a1);
wire signed [7:0] entry_b1;
wire signed [7:0] entry_c1;
wire signed [7:0] entry_a2;
wire signed [7:0] entry_b2;
wire signed [7:0] entry_c2;
wire entry_error_a_zero;
wire entry_error_vertex;
wire entry_display_enable;
wire entry_f1_hit;
wire entry_f1_derivada_hit;
processador_f1 dut (.clk(clk), .system_reset(system_reset), .start_pulse(start_pulse), .a1(a1), .b1(b1), .c1(c1), .x_cartesiano(x_cartesiano), .y_cartesiano(y_cartesiano), .busy(busy), .done(done), .error_a_zero(error_a_zero), .error_vertex(error_vertex), .display_enable(display_enable), .f1_hit(f1_hit), .f1_derivada_hit(f1_derivada_hit));
entrada_pbl03 entrada (.clk(clk), .key_n(key_n), .sw(sw), .processing_done(entry_processing_done), .a1(entry_a1), .b1(entry_b1), .c1(entry_c1), .a2(entry_a2), .b2(entry_b2), .c2(entry_c2), .start_pulse(entry_start_pulse), .input_ready(entry_input_ready), .system_reset(entry_system_reset));
processador_f1 processador_integrado (.clk(clk), .system_reset(entry_system_reset), .start_pulse(entry_start_pulse), .a1(entry_a1), .b1(entry_b1), .c1(entry_c1), .x_cartesiano(x_cartesiano), .y_cartesiano(y_cartesiano), .busy(entry_busy), .done(entry_processing_done), .error_a_zero(entry_error_a_zero), .error_vertex(entry_error_vertex), .display_enable(entry_display_enable), .f1_hit(entry_f1_hit), .f1_derivada_hit(entry_f1_derivada_hit));
endmodule
