module dff_bus4_norst(input clk, input [3:0] d, output reg [3:0] q);
always @(posedge clk)
    q <= d;
endmodule
