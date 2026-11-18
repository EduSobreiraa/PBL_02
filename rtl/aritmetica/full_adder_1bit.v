module full_adder_1bit(input a, input b, input carry_in, output sum, output carry_out);
wire axb;
wire ab;
wire axbc;
xor (axb, a, b);
xor (sum, axb, carry_in);
and (ab, a, b);
and (axbc, axb, carry_in);
or (carry_out, ab, axbc);
endmodule
