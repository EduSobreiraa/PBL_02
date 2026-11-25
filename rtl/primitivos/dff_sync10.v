module dff_sync10(input clk, input reset, input [9:0] d, output reg [9:0] q);
always @(posedge clk) begin
    if (reset)
        q <= 10'b0;
    else
        q <= d;
end
endmodule
