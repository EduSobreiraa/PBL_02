module signed_to_magnitude14(input signed [13:0] value, output negative, output [13:0] magnitude);
wire [15:0] magnitude_full;
wire [1:0] unused_magnitude;
wire magnitude_nonzero;
wire [13:0] magnitude_or;
conditional_negate_16 magnitude_negate (.value({{2{value[13]}}, value}), .negate(value[13]), .result({unused_magnitude, magnitude}));
or (magnitude_nonzero, magnitude[0], magnitude[1], magnitude[2], magnitude[3], magnitude[4], magnitude[5], magnitude[6], magnitude[7], magnitude[8], magnitude[9], magnitude[10], magnitude[11], magnitude[12], magnitude[13]);
and (negative, value[13], magnitude_nonzero);
endmodule
