`timescale 1ns/1ps
module tb_f1_f2_processors(input clk, input system_reset, input start_pulse,
    input signed [7:0] a1, input signed [7:0] b1, input signed [7:0] c1,
    input signed [7:0] a2, input signed [7:0] b2, input signed [7:0] c2,
    input signed [9:0] x_cartesiano, input signed [9:0] y_cartesiano,
    output busy_f1, output done_f1, output error_a_zero_f1, output error_vertex_f1,
    output display_enable_f1, output f1_hit, output f1_derivada_hit,
    output signed [8:0] root_x1_f1, output signed [8:0] root_x2_f1, output root_domain_valid_f1,
    output signed [8:0] f1_x_num, output [8:0] f1_x_den, output signed [17:0] f1_y_num, output [9:0] f1_y_den,
    output busy_f2, output done_f2, output error_a_zero_f2, output error_vertex_f2,
    output display_enable_f2, output f2_hit, output f2_derivada_hit,
    output signed [8:0] root_x1_f2, output signed [8:0] root_x2_f2, output root_domain_valid_f2,
    output signed [8:0] f2_x_num, output [8:0] f2_x_den, output signed [17:0] f2_y_num, output [9:0] f2_y_den);
wire error_a_zero_f2_raw;
wire error_vertex_f2_raw;
wire f2_enabled;
or (f2_enabled, a2[7], a2[6], a2[5], a2[4], a2[3], a2[2], a2[1], a2[0],
    b2[7], b2[6], b2[5], b2[4], b2[3], b2[2], b2[1], b2[0],
    c2[7], c2[6], c2[5], c2[4], c2[3], c2[2], c2[1], c2[0]);
processador_f1 processador_1 (.clk(clk), .system_reset(system_reset), .start_pulse(start_pulse),
    .a1(a1), .b1(b1), .c1(c1), .x_cartesiano(x_cartesiano), .y_cartesiano(y_cartesiano),
    .busy(busy_f1), .done(done_f1), .error_a_zero(error_a_zero_f1),
    .error_vertex(error_vertex_f1), .display_enable(display_enable_f1),
    .f1_hit(f1_hit), .f1_derivada_hit(f1_derivada_hit), .f1_y(),
    .root_x1(root_x1_f1), .root_x2(root_x2_f1), .root_domain_valid(root_domain_valid_f1),
    .vertex_x_num(f1_x_num), .vertex_x_den(f1_x_den), .vertex_y_num(f1_y_num), .vertex_y_den(f1_y_den));
processador_f1 processador_2 (.clk(clk), .system_reset(system_reset), .start_pulse(start_pulse),
    .a1(a2), .b1(b2), .c1(c2), .x_cartesiano(x_cartesiano), .y_cartesiano(y_cartesiano),
    .busy(busy_f2), .done(done_f2), .error_a_zero(error_a_zero_f2_raw),
    .error_vertex(error_vertex_f2_raw), .display_enable(display_enable_f2),
    .f1_hit(f2_hit), .f1_derivada_hit(f2_derivada_hit), .f1_y(),
    .root_x1(root_x1_f2), .root_x2(root_x2_f2), .root_domain_valid(root_domain_valid_f2),
    .vertex_x_num(f2_x_num), .vertex_x_den(f2_x_den), .vertex_y_num(f2_y_num), .vertex_y_den(f2_y_den));
and (error_a_zero_f2, error_a_zero_f2_raw, f2_enabled);
and (error_vertex_f2, error_vertex_f2_raw, f2_enabled);
endmodule
