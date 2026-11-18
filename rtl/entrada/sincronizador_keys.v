module sincronizador_keys(input clk, input [1:0] key_n, input system_reset, output key0_sync_n, output key1_sync_n);
wire key0_stage1;
wire key1_stage1;
dff_sync_bit #(.RESET_VALUE(1'b1)) key0_sync_first (.clk(clk), .reset(system_reset), .d(key_n[0]), .q(key0_stage1));
dff_sync_bit #(.RESET_VALUE(1'b1)) key0_sync_second (.clk(clk), .reset(system_reset), .d(key0_stage1), .q(key0_sync_n));
dff_bit key1_sync_first (.clk(clk), .d(key_n[1]), .q(key1_stage1));
dff_bit key1_sync_second (.clk(clk), .d(key1_stage1), .q(key1_sync_n));
endmodule
