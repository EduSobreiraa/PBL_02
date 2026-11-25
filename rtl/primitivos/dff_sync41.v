module dff_sync41(input clk, input reset, input [40:0] d, output reg [40:0] q);
always @(posedge clk) begin
    if (reset)
        q <= 41'b0;
    else
        q <= d;
end
endmodule
