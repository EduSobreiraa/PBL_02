`timescale 1ns/1ps
module tb_status_errors_pbl03(input clk, input [1:0] key_n, input [8:0] sw, input probe_busy, input probe_done, input [3:0] probe_errors, input [2:0] probe_glifo, output [9:0] probe_led, output [6:0] probe_hex0, output [6:0] probe_hex1, output [6:0] probe_hex2, output [6:0] probe_hex3, output [6:0] probe_hex4, output [6:0] probe_hex5, output [6:0] probe_segmentos);
top_pbl03 dut (.MAX10_CLK1_50(clk), .KEY(key_n), .SW(sw), .VGA_HS(), .VGA_VS(), .VGA_R(), .VGA_G(), .VGA_B());
display_status_pbl03 probe (.busy(probe_busy), .done(probe_done), .error_a_zero_f1(probe_errors[0]), .error_vertex_f1(probe_errors[1]), .error_a_zero_f2(probe_errors[2]), .error_vertex_f2(probe_errors[3]), .LEDR(probe_led), .HEX0(probe_hex0), .HEX1(probe_hex1), .HEX2(probe_hex2), .HEX3(probe_hex3), .HEX4(probe_hex4), .HEX5(probe_hex5));
decodificador_glifo_7seg_pbl03 glifo (.glifo(probe_glifo), .segmentos(probe_segmentos));
endmodule
