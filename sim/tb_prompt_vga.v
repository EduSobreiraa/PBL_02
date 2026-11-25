module tb_prompt_vga(input [4:0] glyph_id, input [2:0] row, input [2:0] column, input [9:0] x_pixel, input [9:0] y_pixel, input video_on, input prompt_mode, output pixel, output prompt_white);
glyph_5x7 glyph (.glyph_id(glyph_id), .row(row), .column(column), .pixel(pixel));
renderizador_prompt_vga prompt (.x_pixel(x_pixel), .y_pixel(y_pixel), .video_on(video_on), .prompt_mode(prompt_mode), .prompt_white(prompt_white));
endmodule
