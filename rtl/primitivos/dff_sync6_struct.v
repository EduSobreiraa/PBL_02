module dff_sync6_struct(input clk, input reset, input [5:0] d, output reg [5:0] q);
wire reset_n;
wire [5:0] d_reset;
not reset_inverter(reset_n, reset);
and reset_data_0(d_reset[0], d[0], reset_n);
and reset_data_1(d_reset[1], d[1], reset_n);
and reset_data_2(d_reset[2], d[2], reset_n);
and reset_data_3(d_reset[3], d[3], reset_n);
and reset_data_4(d_reset[4], d[4], reset_n);
and reset_data_5(d_reset[5], d[5], reset_n);
always @(posedge clk)
    q <= d_reset;
endmodule
