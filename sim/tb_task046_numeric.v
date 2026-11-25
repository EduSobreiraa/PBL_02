`timescale 1ns/1ps
module tb_task046_numeric;
reg [13:0] magnitude;
wire [15:0] bcd;
reg signed [13:0] signed_value;
wire negative;
wire [4:0] sign_glyph;
wire [4:0] thousands_glyph;
wire [4:0] hundreds_glyph;
wire [4:0] tens_glyph;
wire [4:0] ones_glyph;
reg signed [17:0] numerator;
reg [9:0] denominator;
wire signed [13:0] rounded_value;
integer index;
integer expected_bcd;
integer absolute_value;
integer expected_rounded;
integer test_numerator;
integer test_denominator;

binary_to_bcd14 bcd_dut (.magnitude(magnitude), .bcd(bcd));
signed_to_bcd_glyphs14 signed_formatter (.value(signed_value), .negative(negative), .sign_glyph(sign_glyph), .thousands_glyph(thousands_glyph), .hundreds_glyph(hundreds_glyph), .tens_glyph(tens_glyph), .ones_glyph(ones_glyph));
round_signed_ratio_18_10 rounder (.numerator(numerator), .denominator(denominator), .rounded_value(rounded_value));

initial begin
    for (index = 0; index <= 8192; index = index + 1) begin
        magnitude = index[13:0];
        expected_bcd = ((index / 1000) << 12) | (((index / 100) % 10) << 8) | (((index / 10) % 10) << 4) | (index % 10);
        #1;
        case (bcd == expected_bcd[15:0]) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    end
    signed_value = 14'sd0; #1;
    case (negative == 1'b0) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    case (sign_glyph == 5'd11) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    case (thousands_glyph == 5'd1 && hundreds_glyph == 5'd1 && tens_glyph == 5'd1 && ones_glyph == 5'd1) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    signed_value = 14'sd129; #1;
    case (negative == 1'b0 && sign_glyph == 5'd11) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    case (thousands_glyph == 5'd1 && hundreds_glyph == 5'd2 && tens_glyph == 5'd3 && ones_glyph == 5'd10) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    signed_value = -14'sd129; #1;
    case (negative == 1'b1 && sign_glyph == 5'd12) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    case (thousands_glyph == 5'd1 && hundreds_glyph == 5'd2 && tens_glyph == 5'd3 && ones_glyph == 5'd10) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    signed_value = -14'sd4224; #1;
    case (negative == 1'b1 && sign_glyph == 5'd12) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    case (thousands_glyph == 5'd5 && hundreds_glyph == 5'd3 && tens_glyph == 5'd3 && ones_glyph == 5'd5) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    signed_value = 14'sd4223; #1;
    case (negative == 1'b0 && sign_glyph == 5'd11) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    case (thousands_glyph == 5'd5 && hundreds_glyph == 5'd3 && tens_glyph == 5'd3 && ones_glyph == 5'd4) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    for (test_numerator = -4224; test_numerator <= 4223; test_numerator = test_numerator + 311) begin
        for (test_denominator = 1; test_denominator <= 257; test_denominator = test_denominator + 64) begin
            numerator = test_numerator;
            denominator = test_denominator;
            absolute_value = (test_numerator < 0) ? -test_numerator : test_numerator;
            expected_rounded = (absolute_value * 2 + test_denominator) / (2 * test_denominator);
            expected_rounded = (test_numerator < 0) ? -expected_rounded : expected_rounded;
            #1;
            case (rounded_value == expected_rounded[13:0]) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
        end
    end
    numerator = -18'sd1; denominator = 10'd2; #1;
    case (rounded_value == -14'sd1) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    numerator = 18'sd1; denominator = 10'd2; #1;
    case (rounded_value == 14'sd1) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    numerator = -18'sd1; denominator = 10'd3; #1;
    case (rounded_value == 14'sd0) 1'b1: ; default: $fatal(1, "TASK-046 numeric reference mismatch"); endcase
    $display("TASK-046 NUMERIC PASS: BCD 0..8192, signed glyph boundaries, and rational half-away rounding grid");
    $finish;
end
endmodule
