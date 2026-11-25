module restoring_division_18_group2(input [9:0] remainder_in, input [9:0] denominator, input [1:0] dividend_bits, output [9:0] remainder_out, output [1:0] quotient_bits);
wire [9:0] remainder_1;
restoring_division_18_step10 step_0 (.remainder_in(remainder_in), .denominator(denominator), .dividend_bit(dividend_bits[1]), .remainder_out(remainder_1), .take(quotient_bits[1]));
restoring_division_18_step10 step_1 (.remainder_in(remainder_1), .denominator(denominator), .dividend_bit(dividend_bits[0]), .remainder_out(remainder_out), .take(quotient_bits[0]));
endmodule
