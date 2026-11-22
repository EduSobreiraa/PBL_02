`timescale 1ns/1ps
module tb_main_handshake_pbl03(input clk, input [1:0] key_n, input [8:0] sw,
    input probe_reset, input probe_ready, input probe_start,
    input probe_done_f1, input probe_done_f2, input probe_roots_ready,
    output probe_busy, output probe_done);
top_pbl03 dut (.MAX10_CLK1_50(clk), .KEY(key_n), .SW(sw), .VGA_HS(), .VGA_VS(), .VGA_R(), .VGA_G(), .VGA_B());
fsm_principal_pbl03 probe (.clk(clk), .system_reset(probe_reset), .input_ready(probe_ready),
    .start_pulse(probe_start), .done_f1(probe_done_f1), .done_f2(probe_done_f2),
    .roots_ready(probe_roots_ready), .start_accepted(),
    .busy(probe_busy), .done(probe_done));
endmodule
