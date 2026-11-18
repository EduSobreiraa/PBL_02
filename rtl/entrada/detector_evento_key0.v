module detector_evento_key0(input clk, input system_reset, input key0_sync_n, output key0_event);
wire previous_released;
wire pressed_now;
dff_sync_bit #(.RESET_VALUE(1'b1)) key0_history (.clk(clk), .reset(system_reset), .d(key0_sync_n), .q(previous_released));
not (pressed_now, key0_sync_n);
and (key0_event, pressed_now, previous_released);
endmodule
