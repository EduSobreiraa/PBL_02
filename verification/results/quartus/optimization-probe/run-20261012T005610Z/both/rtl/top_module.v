`timescale 1ns/1ps
module top_module(input wire MAX10_CLK1_50,input wire [1:0] KEY,input wire [9:0] SW,
    output wire [9:0] LEDR,output wire [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
    wire signed [7:0] a,b,c;
    wire signed [22:0] y,value;
    wire signed [17:0] delta;
    wire signed [8:0] x1,x2;
    wire loaded,carry_y,unused_polynomial_OV,unused_domain_error;
    wire selected_result,not_loaded,incomplete,invalid_root,invalid_display;
    coefficient_input_core coefficients(.clk(MAX10_CLK1_50),.key0_n(KEY[0]),.key1_n(KEY[1]),
        .sw(SW[7:0]),.a(a),.b(b),.c(c),.loaded(loaded));
    polynomial_y_core polynomial(.a(a),.b(b),.c(c),.x(SW[7:0]),.y(y),
        .OV(unused_polynomial_OV),.carry_y(carry_y));
    quadratic_roots roots(.a(a),.b(b),.c(c),.delta(delta),.x1(x1),.x2(x2),.domain_error(unused_domain_error));
    result_select select_result(.x(SW[7:0]),.y(y),.x1(x1),.x2(x2),.sel(SW[9:8]),.value(value));
    flag_ov_err errors(.loaded(loaded),.a(a),.delta(delta),.OV(LEDR[0]),.ERR(LEDR[3]));
    flag_z zero(.value(value),.sel(SW[9:8]),.ERR(LEDR[3]),.Z(LEDR[1]));
    flag_c carry(.carry_y(carry_y),.loaded(loaded),.sel(SW[9:8]),.C(LEDR[2]));
    assign LEDR[9:4] = 6'b000000;
    or selected(selected_result,SW[9],SW[8]);
    not unloaded(not_loaded,loaded);
    and pending(incomplete,selected_result,not_loaded);
    and root_error(invalid_root,SW[9],LEDR[3]);
    or presentation_invalid(invalid_display,incomplete,invalid_root);
    decimal_display presentation(.value(value),.invalid(invalid_display),
        .HEX0(HEX0),.HEX1(HEX1),.HEX2(HEX2),.HEX3(HEX3),.HEX4(HEX4),.HEX5(HEX5));
endmodule
