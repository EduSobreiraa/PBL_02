`timescale 1ns/1ps
// Binary full adder: five primitive gates, no storage.
module full_adder(input wire a, b, cin, output wire sum, cout);
    wire axb, ab, carry_term;
    xor (axb, a, b);
    xor (sum, axb, cin);
    and (ab, a, b);
    and (carry_term, axb, cin);
    or (cout, ab, carry_term);
endmodule
