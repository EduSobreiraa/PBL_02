module dff_bus41_norst(input clk, input [40:0] d, output reg [40:0] q);
always @(posedge clk)
    q <= d;
endmodule
