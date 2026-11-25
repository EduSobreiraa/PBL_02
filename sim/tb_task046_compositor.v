`timescale 1ns/1ps
module tb_task046_compositor;
reg video_on;
reg prompt_mode;
reg prompt_white;
reg panel_active;
reg [3:0] panel_red;
reg [3:0] panel_green;
reg [3:0] panel_blue;
reg eixo_horizontal;
reg eixo_vertical;
reg processing_done;
reg intersection_hit;
reg root_marker_hit;
reg root_label_hit;
reg f1_hit;
reg f1_derivada_hit;
reg f2_hit;
reg f2_derivada_hit;
reg signed [9:0] x_cartesiano;
reg signed [9:0] y_cartesiano;
reg marker_enable_f1;
reg signed [8:0] f1_x_num;
reg [8:0] f1_x_den;
reg signed [17:0] f1_y_num;
reg [9:0] f1_y_den;
reg marker_enable_f2;
reg signed [8:0] f2_x_num;
reg [8:0] f2_x_den;
reg signed [17:0] f2_y_num;
reg [9:0] f2_y_den;
wire [3:0] red;
wire [3:0] green;
wire [3:0] blue;

compositor_rgb dut (.video_on(video_on), .prompt_mode(prompt_mode), .prompt_white(prompt_white), .panel_active(panel_active), .panel_red(panel_red), .panel_green(panel_green), .panel_blue(panel_blue), .eixo_horizontal(eixo_horizontal), .eixo_vertical(eixo_vertical), .processing_done(processing_done), .intersection_hit(intersection_hit), .root_marker_hit(root_marker_hit), .root_label_hit(root_label_hit), .f1_hit(f1_hit), .f1_derivada_hit(f1_derivada_hit), .f2_hit(f2_hit), .f2_derivada_hit(f2_derivada_hit), .x_cartesiano(x_cartesiano), .y_cartesiano(y_cartesiano), .marker_enable_f1(marker_enable_f1), .f1_x_num(f1_x_num), .f1_x_den(f1_x_den), .f1_y_num(f1_y_num), .f1_y_den(f1_y_den), .marker_enable_f2(marker_enable_f2), .f2_x_num(f2_x_num), .f2_x_den(f2_x_den), .f2_y_num(f2_y_num), .f2_y_den(f2_y_den), .red(red), .green(green), .blue(blue));

initial begin
    video_on=1'b1;prompt_mode=1'b1;prompt_white=1'b0;panel_active=1'b1;panel_red=4'hf;panel_green=4'h8;panel_blue=4'h0;
    eixo_horizontal=1'b1;eixo_vertical=1'b1;processing_done=1'b1;intersection_hit=1'b1;root_marker_hit=1'b1;root_label_hit=1'b1;f1_hit=1'b1;f1_derivada_hit=1'b1;f2_hit=1'b1;f2_derivada_hit=1'b1;
    x_cartesiano=10'sd0;y_cartesiano=10'sd0;marker_enable_f1=1'b0;f1_x_num=9'sd0;f1_x_den=9'd1;f1_y_num=18'sd0;f1_y_den=10'd1;marker_enable_f2=1'b0;f2_x_num=9'sd0;f2_x_den=9'd1;f2_y_num=18'sd0;f2_y_den=10'd1;
    #1;case ({red,green,blue}) 12'h000: ; default: $fatal(1, "prompt blank failed: %h", {red,green,blue}); endcase
    prompt_white=1'b1;#1;case ({red,green,blue}) 12'hfff: ; default: $fatal(1, "prompt white failed: %h", {red,green,blue}); endcase
    prompt_mode=1'b0;#1;case ({red,green,blue}) 12'hf80: ; default: $fatal(1, "panel overlay failed: %h", {red,green,blue}); endcase
    panel_active=1'b0;prompt_white=1'b0;intersection_hit=1'b0;root_marker_hit=1'b0;root_label_hit=1'b0;f1_derivada_hit=1'b0;f2_hit=1'b0;f2_derivada_hit=1'b0;eixo_horizontal=1'b0;eixo_vertical=1'b0;#1;
    case ({red,green,blue}) 12'h00f: ; default: $fatal(1, "graph fallthrough failed: %h", {red,green,blue}); endcase
    f1_hit=1'b0;eixo_vertical=1'b1;#1;case ({red,green,blue}) 12'hfff: ; default: $fatal(1, "axis fallthrough failed: %h", {red,green,blue}); endcase
    video_on=1'b0;#1;case ({red,green,blue}) 12'h000: ; default: $fatal(1, "prompt blank failed: %h", {red,green,blue}); endcase
    $display("TASK-046 COMPOSITOR PASS: prompt, opaque panel, graph fallthrough, axis and blanking priorities");
    $finish;
end
endmodule
