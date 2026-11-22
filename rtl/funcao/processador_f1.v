module processador_f1(input clk, input system_reset, input start_pulse, input signed [7:0] a1, input signed [7:0] b1, input signed [7:0] c1, input signed [9:0] x_cartesiano, input signed [9:0] y_cartesiano, output busy, output done, output error_a_zero, output error_vertex, output display_enable, output f1_hit, output f1_derivada_hit, output signed [24:0] f1_y, output signed [8:0] vertex_x_num, output [8:0] vertex_x_den, output signed [17:0] vertex_y_num, output [9:0] vertex_y_den);
wire a1_zero;
wire vertice_y_fora;
wire function_valid;
wire f1_hit_raw;
wire f1_derivada_hit_raw;
datapath_f1 datapath (.a1(a1), .b1(b1), .c1(c1), .x_cartesiano(x_cartesiano), .y_cartesiano(y_cartesiano), .f1_y(f1_y), .f1_derivada(), .a1_zero(a1_zero), .vertice_y_fora(vertice_y_fora), .function_valid(function_valid), .f1_hit(f1_hit_raw), .f1_derivada_hit(f1_derivada_hit_raw), .x_num(vertex_x_num), .x_den(vertex_x_den), .y_num(vertex_y_num), .y_den(vertex_y_den));
fsm_funcao_f1 controle (.clk(clk), .system_reset(system_reset), .start_pulse(start_pulse), .a1_zero(a1_zero), .vertice_y_fora(vertice_y_fora), .function_valid(function_valid), .busy(busy), .done(done), .error_a_zero(error_a_zero), .error_vertex(error_vertex), .display_enable(display_enable));
and (f1_hit, f1_hit_raw, display_enable);
and (f1_derivada_hit, f1_derivada_hit_raw, display_enable);
endmodule
