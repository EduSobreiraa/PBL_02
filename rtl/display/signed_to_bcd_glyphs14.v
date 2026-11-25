module signed_to_bcd_glyphs14(input signed [13:0] value, output negative, output [4:0] sign_glyph, output [4:0] thousands_glyph, output [4:0] hundreds_glyph, output [4:0] tens_glyph, output [4:0] ones_glyph);
wire [13:0] magnitude;
wire [15:0] bcd;
wire magnitude_nonzero;
signed_to_magnitude14 magnitude_converter (.value(value), .negative(negative), .magnitude(magnitude));
binary_to_bcd14 bcd_converter (.magnitude(magnitude), .bcd(bcd));
bcd_to_glyph_id thousands_converter (.digit(bcd[15:12]), .glyph_id(thousands_glyph));
bcd_to_glyph_id hundreds_converter (.digit(bcd[11:8]), .glyph_id(hundreds_glyph));
bcd_to_glyph_id tens_converter (.digit(bcd[7:4]), .glyph_id(tens_glyph));
bcd_to_glyph_id ones_converter (.digit(bcd[3:0]), .glyph_id(ones_glyph));
or (magnitude_nonzero, magnitude[0], magnitude[1], magnitude[2], magnitude[3], magnitude[4], magnitude[5], magnitude[6], magnitude[7], magnitude[8], magnitude[9], magnitude[10], magnitude[11], magnitude[12], magnitude[13]);
not (sign_glyph[0], negative);
not (sign_glyph[1], negative);
and (sign_glyph[2], value[13], magnitude_nonzero);
and (sign_glyph[3], 1'b1, 1'b1);
and (sign_glyph[4], 1'b0, 1'b0);
endmodule
