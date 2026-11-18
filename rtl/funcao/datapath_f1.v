module datapath_f1(input signed [7:0] a1, input signed [7:0] b1, input signed [7:0] c1, input signed [9:0] x_cartesiano, input signed [9:0] y_cartesiano, output signed [24:0] f1_y, output signed [17:0] f1_derivada, output a1_zero, output vertice_y_fora, output function_valid, output f1_hit, output f1_derivada_hit);
avaliador_quadratico_f1 quadratica (.a1(a1), .b1(b1), .c1(c1), .x_cartesiano(x_cartesiano), .f1_y(f1_y));
avaliador_derivada_f1 derivada (.a1(a1), .b1(b1), .x_cartesiano(x_cartesiano), .f1_derivada(f1_derivada));
validador_vertice_f1 validador (.a1(a1), .b1(b1), .c1(c1), .a1_zero(a1_zero), .vertice_y_fora(vertice_y_fora), .function_valid(function_valid));
detector_hits_f1 detector (.f1_y(f1_y), .f1_derivada(f1_derivada), .y_cartesiano(y_cartesiano), .f1_hit(f1_hit), .f1_derivada_hit(f1_derivada_hit));
endmodule
