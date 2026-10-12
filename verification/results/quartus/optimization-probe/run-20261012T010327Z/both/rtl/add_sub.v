`timescale 1ns/1ps
// Private binary core. Exact signed results are guaranteed only in consumer domains.
module add23_core(input wire signed [22:0] lhs, rhs,
                  output wire signed [22:0] sum, output wire carry_out);
    wire [23:0] carry;
    assign carry[0] = 1'b0;
    assign carry_out = carry[23];
    full_adder fa0 (.a(lhs[0]), .b(rhs[0]), .cin(carry[0]), .sum(sum[0]), .cout(carry[1]));
    full_adder fa1 (.a(lhs[1]), .b(rhs[1]), .cin(carry[1]), .sum(sum[1]), .cout(carry[2]));
    full_adder fa2 (.a(lhs[2]), .b(rhs[2]), .cin(carry[2]), .sum(sum[2]), .cout(carry[3]));
    full_adder fa3 (.a(lhs[3]), .b(rhs[3]), .cin(carry[3]), .sum(sum[3]), .cout(carry[4]));
    full_adder fa4 (.a(lhs[4]), .b(rhs[4]), .cin(carry[4]), .sum(sum[4]), .cout(carry[5]));
    full_adder fa5 (.a(lhs[5]), .b(rhs[5]), .cin(carry[5]), .sum(sum[5]), .cout(carry[6]));
    full_adder fa6 (.a(lhs[6]), .b(rhs[6]), .cin(carry[6]), .sum(sum[6]), .cout(carry[7]));
    full_adder fa7 (.a(lhs[7]), .b(rhs[7]), .cin(carry[7]), .sum(sum[7]), .cout(carry[8]));
    full_adder fa8 (.a(lhs[8]), .b(rhs[8]), .cin(carry[8]), .sum(sum[8]), .cout(carry[9]));
    full_adder fa9 (.a(lhs[9]), .b(rhs[9]), .cin(carry[9]), .sum(sum[9]), .cout(carry[10]));
    full_adder fa10 (.a(lhs[10]), .b(rhs[10]), .cin(carry[10]), .sum(sum[10]), .cout(carry[11]));
    full_adder fa11 (.a(lhs[11]), .b(rhs[11]), .cin(carry[11]), .sum(sum[11]), .cout(carry[12]));
    full_adder fa12 (.a(lhs[12]), .b(rhs[12]), .cin(carry[12]), .sum(sum[12]), .cout(carry[13]));
    full_adder fa13 (.a(lhs[13]), .b(rhs[13]), .cin(carry[13]), .sum(sum[13]), .cout(carry[14]));
    full_adder fa14 (.a(lhs[14]), .b(rhs[14]), .cin(carry[14]), .sum(sum[14]), .cout(carry[15]));
    full_adder fa15 (.a(lhs[15]), .b(rhs[15]), .cin(carry[15]), .sum(sum[15]), .cout(carry[16]));
    full_adder fa16 (.a(lhs[16]), .b(rhs[16]), .cin(carry[16]), .sum(sum[16]), .cout(carry[17]));
    full_adder fa17 (.a(lhs[17]), .b(rhs[17]), .cin(carry[17]), .sum(sum[17]), .cout(carry[18]));
    full_adder fa18 (.a(lhs[18]), .b(rhs[18]), .cin(carry[18]), .sum(sum[18]), .cout(carry[19]));
    full_adder fa19 (.a(lhs[19]), .b(rhs[19]), .cin(carry[19]), .sum(sum[19]), .cout(carry[20]));
    full_adder fa20 (.a(lhs[20]), .b(rhs[20]), .cin(carry[20]), .sum(sum[20]), .cout(carry[21]));
    full_adder fa21 (.a(lhs[21]), .b(rhs[21]), .cin(carry[21]), .sum(sum[21]), .cout(carry[22]));
    full_adder fa22 (.a(lhs[22]), .b(rhs[22]), .cin(carry[22]), .sum(sum[22]), .cout(carry[23]));
endmodule

// Public wrapper has no carry or overflow port.
module add23(input wire signed [22:0] lhs, rhs, output wire signed [22:0] sum);
    wire unused_carry;
    add23_core core (.lhs(lhs), .rhs(rhs), .sum(sum), .carry_out(unused_carry));
endmodule

// Delta consumer: lhs=b squared, rhs=four times a times c, both signed18.
module sub18(input wire signed [17:0] lhs, rhs, output wire signed [17:0] difference);
    wire [17:0] inverted_rhs;
    wire [18:0] carry;
    assign carry[0] = 1'b1;
    not (inverted_rhs[0], rhs[0]);
    not (inverted_rhs[1], rhs[1]);
    not (inverted_rhs[2], rhs[2]);
    not (inverted_rhs[3], rhs[3]);
    not (inverted_rhs[4], rhs[4]);
    not (inverted_rhs[5], rhs[5]);
    not (inverted_rhs[6], rhs[6]);
    not (inverted_rhs[7], rhs[7]);
    not (inverted_rhs[8], rhs[8]);
    not (inverted_rhs[9], rhs[9]);
    not (inverted_rhs[10], rhs[10]);
    not (inverted_rhs[11], rhs[11]);
    not (inverted_rhs[12], rhs[12]);
    not (inverted_rhs[13], rhs[13]);
    not (inverted_rhs[14], rhs[14]);
    not (inverted_rhs[15], rhs[15]);
    not (inverted_rhs[16], rhs[16]);
    not (inverted_rhs[17], rhs[17]);
    full_adder fa0 (.a(lhs[0]), .b(inverted_rhs[0]), .cin(carry[0]), .sum(difference[0]), .cout(carry[1]));
    full_adder fa1 (.a(lhs[1]), .b(inverted_rhs[1]), .cin(carry[1]), .sum(difference[1]), .cout(carry[2]));
    full_adder fa2 (.a(lhs[2]), .b(inverted_rhs[2]), .cin(carry[2]), .sum(difference[2]), .cout(carry[3]));
    full_adder fa3 (.a(lhs[3]), .b(inverted_rhs[3]), .cin(carry[3]), .sum(difference[3]), .cout(carry[4]));
    full_adder fa4 (.a(lhs[4]), .b(inverted_rhs[4]), .cin(carry[4]), .sum(difference[4]), .cout(carry[5]));
    full_adder fa5 (.a(lhs[5]), .b(inverted_rhs[5]), .cin(carry[5]), .sum(difference[5]), .cout(carry[6]));
    full_adder fa6 (.a(lhs[6]), .b(inverted_rhs[6]), .cin(carry[6]), .sum(difference[6]), .cout(carry[7]));
    full_adder fa7 (.a(lhs[7]), .b(inverted_rhs[7]), .cin(carry[7]), .sum(difference[7]), .cout(carry[8]));
    full_adder fa8 (.a(lhs[8]), .b(inverted_rhs[8]), .cin(carry[8]), .sum(difference[8]), .cout(carry[9]));
    full_adder fa9 (.a(lhs[9]), .b(inverted_rhs[9]), .cin(carry[9]), .sum(difference[9]), .cout(carry[10]));
    full_adder fa10 (.a(lhs[10]), .b(inverted_rhs[10]), .cin(carry[10]), .sum(difference[10]), .cout(carry[11]));
    full_adder fa11 (.a(lhs[11]), .b(inverted_rhs[11]), .cin(carry[11]), .sum(difference[11]), .cout(carry[12]));
    full_adder fa12 (.a(lhs[12]), .b(inverted_rhs[12]), .cin(carry[12]), .sum(difference[12]), .cout(carry[13]));
    full_adder fa13 (.a(lhs[13]), .b(inverted_rhs[13]), .cin(carry[13]), .sum(difference[13]), .cout(carry[14]));
    full_adder fa14 (.a(lhs[14]), .b(inverted_rhs[14]), .cin(carry[14]), .sum(difference[14]), .cout(carry[15]));
    full_adder fa15 (.a(lhs[15]), .b(inverted_rhs[15]), .cin(carry[15]), .sum(difference[15]), .cout(carry[16]));
    full_adder fa16 (.a(lhs[16]), .b(inverted_rhs[16]), .cin(carry[16]), .sum(difference[16]), .cout(carry[17]));
    full_adder fa17 (.a(lhs[17]), .b(inverted_rhs[17]), .cin(carry[17]), .sum(difference[17]), .cout(carry[18]));
endmodule
