module tb_video_axes(input [9:0] x_pixel, input [9:0] y_pixel, input video_on, input processing_done, input f1_hit, input f1_derivada_hit, input f2_hit, input f2_derivada_hit, output signed [9:0] x_cartesiano, output signed [9:0] y_cartesiano, output eixo_horizontal, output eixo_vertical, output [3:0] red, output [3:0] green, output [3:0] blue);
coordenadas_cartesianas coordenadas (.x_pixel(x_pixel), .y_pixel(y_pixel), .x_cartesiano(x_cartesiano), .y_cartesiano(y_cartesiano));
detector_eixos detector (.x_cartesiano(x_cartesiano), .y_cartesiano(y_cartesiano), .video_on(video_on), .eixo_horizontal(eixo_horizontal), .eixo_vertical(eixo_vertical));
compositor_rgb compositor (.video_on(video_on), .eixo_horizontal(eixo_horizontal), .eixo_vertical(eixo_vertical), .processing_done(processing_done), .f1_hit(f1_hit), .f1_derivada_hit(f1_derivada_hit), .f2_hit(f2_hit), .f2_derivada_hit(f2_derivada_hit), .red(red), .green(green), .blue(blue));
endmodule
