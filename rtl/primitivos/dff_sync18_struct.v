module dff_sync18_struct(input clk, input reset, input [17:0] d, output reg [17:0] q);
wire reset_n;
wire [17:0] d_reset;
not reset_inverter(reset_n, reset);
and reset_data_0(d_reset[0], d[0], reset_n);
and reset_data_1(d_reset[1], d[1], reset_n);
and reset_data_2(d_reset[2], d[2], reset_n);
and reset_data_3(d_reset[3], d[3], reset_n);
and reset_data_4(d_reset[4], d[4], reset_n);
and reset_data_5(d_reset[5], d[5], reset_n);
and reset_data_6(d_reset[6], d[6], reset_n);
and reset_data_7(d_reset[7], d[7], reset_n);
and reset_data_8(d_reset[8], d[8], reset_n);
and reset_data_9(d_reset[9], d[9], reset_n);
and reset_data_10(d_reset[10], d[10], reset_n);
and reset_data_11(d_reset[11], d[11], reset_n);
and reset_data_12(d_reset[12], d[12], reset_n);
and reset_data_13(d_reset[13], d[13], reset_n);
and reset_data_14(d_reset[14], d[14], reset_n);
and reset_data_15(d_reset[15], d[15], reset_n);
and reset_data_16(d_reset[16], d[16], reset_n);
and reset_data_17(d_reset[17], d[17], reset_n);
always @(posedge clk)
    q <= d_reset;
endmodule
