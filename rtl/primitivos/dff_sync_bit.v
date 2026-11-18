module dff_sync_bit #(parameter RESET_VALUE = 1'b0)(input clk, input reset, input d, output reg q);
always @(posedge clk) begin
    if (reset)
        q <= RESET_VALUE;
    else
        q <= d;
end
endmodule
