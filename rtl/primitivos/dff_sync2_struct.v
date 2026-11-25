module dff_sync2_struct(input clk, input reset, input [1:0] d, output reg [1:0] q);
wire reset_n;
wire [1:0] d_reset;
not reset_inverter(reset_n, reset);
and reset_data_0(d_reset[0], d[0], reset_n);
and reset_data_1(d_reset[1], d[1], reset_n);
always @(posedge clk)
    q <= d_reset;
endmodule
