module bcd_stage14(input [15:0] bcd_in, input magnitude_bit, output [15:0] bcd_out);
wire carry_hundreds;
wire carry_tens;
wire carry_ones;
bcd_add3_digit thousands (.digit_in(bcd_in[15:12]), .shift_in(carry_hundreds), .shifted(bcd_out[15:12]));
bcd_add3_digit hundreds (.digit_in(bcd_in[11:8]), .shift_in(carry_tens), .shifted(bcd_out[11:8]), .adjusted_msb(carry_hundreds));
bcd_add3_digit tens (.digit_in(bcd_in[7:4]), .shift_in(carry_ones), .shifted(bcd_out[7:4]), .adjusted_msb(carry_tens));
bcd_add3_digit ones (.digit_in(bcd_in[3:0]), .shift_in(magnitude_bit), .shifted(bcd_out[3:0]), .adjusted_msb(carry_ones));
endmodule
