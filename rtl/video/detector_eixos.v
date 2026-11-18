module detector_eixos(input signed [9:0] x_cartesiano, input signed [9:0] y_cartesiano, input video_on, output eixo_horizontal, output eixo_vertical);
wire x_zero;
wire y_zero;
nor (x_zero, x_cartesiano[0], x_cartesiano[1], x_cartesiano[2], x_cartesiano[3], x_cartesiano[4], x_cartesiano[5], x_cartesiano[6], x_cartesiano[7], x_cartesiano[8], x_cartesiano[9]);
nor (y_zero, y_cartesiano[0], y_cartesiano[1], y_cartesiano[2], y_cartesiano[3], y_cartesiano[4], y_cartesiano[5], y_cartesiano[6], y_cartesiano[7], y_cartesiano[8], y_cartesiano[9]);
and (eixo_horizontal, video_on, y_zero);
and (eixo_vertical, video_on, x_zero);
endmodule
