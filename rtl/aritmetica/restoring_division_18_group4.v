module restoring_division_18_group4(input [9:0] remainder_in, input [9:0] denominator, input [3:0] dividend_bits, output [9:0] remainder_out, output [3:0] quotient_bits);
wire [9:0] remainder_1;
wire [9:0] remainder_2;
wire [9:0] remainder_3;
restoring_division_18_step10 step_0 (.remainder_in(remainder_in), .denominator(denominator), .dividend_bit(dividend_bits[3]), .remainder_out(remainder_1), .take(quotient_bits[3]));
restoring_division_18_step10 step_1 (.remainder_in(remainder_1), .denominator(denominator), .dividend_bit(dividend_bits[2]), .remainder_out(remainder_2), .take(quotient_bits[2]));
restoring_division_18_step10 step_2 (.remainder_in(remainder_2), .denominator(denominator), .dividend_bit(dividend_bits[1]), .remainder_out(remainder_3), .take(quotient_bits[1]));
restoring_division_18_step10 step_3 (.remainder_in(remainder_3), .denominator(denominator), .dividend_bit(dividend_bits[0]), .remainder_out(remainder_out), .take(quotient_bits[0]));
endmodule
