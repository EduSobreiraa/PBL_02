`timescale 1ns/1ps
// Private structural cells for the nine spatial restoring stages.
module sqrt_full_adder(input wire a,b,cin, output wire sum,cout);
    wire axb,ab,propagate;
    xor (axb,a,b);
    xor (sum,axb,cin);
    and (ab,a,b);
    and (propagate,axb,cin);
    or (cout,ab,propagate);
endmodule

module sqrt_stage(input wire [8:0] root_in,
                  input wire [9:0] remainder_in,
                  input wire [1:0] pair_in,
                  output wire [8:0] root_out,
                  output wire [9:0] remainder_out);
    wire [10:0] trial, shifted, inverted_trial, difference;
    wire [11:0] carry;
    wire take, keep;
    wire [9:0] selected_difference, selected_shifted;
    // Before every stage: root_in <=255 and remainder_in <=510.
    // Hence remainder_in[9] and root_in[8] are zero in this network.
    assign shifted = {remainder_in[8:0],pair_in};
    assign trial = {root_in,2'b01};
    assign carry[0] = 1'b1;
    assign take = carry[11];
    not (keep,take);
    not (inverted_trial[0],trial[0]);
    sqrt_full_adder fa0 (.a(shifted[0]),.b(inverted_trial[0]),.cin(carry[0]),.sum(difference[0]),.cout(carry[1]));
    not (inverted_trial[1],trial[1]);
    sqrt_full_adder fa1 (.a(shifted[1]),.b(inverted_trial[1]),.cin(carry[1]),.sum(difference[1]),.cout(carry[2]));
    not (inverted_trial[2],trial[2]);
    sqrt_full_adder fa2 (.a(shifted[2]),.b(inverted_trial[2]),.cin(carry[2]),.sum(difference[2]),.cout(carry[3]));
    not (inverted_trial[3],trial[3]);
    sqrt_full_adder fa3 (.a(shifted[3]),.b(inverted_trial[3]),.cin(carry[3]),.sum(difference[3]),.cout(carry[4]));
    not (inverted_trial[4],trial[4]);
    sqrt_full_adder fa4 (.a(shifted[4]),.b(inverted_trial[4]),.cin(carry[4]),.sum(difference[4]),.cout(carry[5]));
    not (inverted_trial[5],trial[5]);
    sqrt_full_adder fa5 (.a(shifted[5]),.b(inverted_trial[5]),.cin(carry[5]),.sum(difference[5]),.cout(carry[6]));
    not (inverted_trial[6],trial[6]);
    sqrt_full_adder fa6 (.a(shifted[6]),.b(inverted_trial[6]),.cin(carry[6]),.sum(difference[6]),.cout(carry[7]));
    not (inverted_trial[7],trial[7]);
    sqrt_full_adder fa7 (.a(shifted[7]),.b(inverted_trial[7]),.cin(carry[7]),.sum(difference[7]),.cout(carry[8]));
    not (inverted_trial[8],trial[8]);
    sqrt_full_adder fa8 (.a(shifted[8]),.b(inverted_trial[8]),.cin(carry[8]),.sum(difference[8]),.cout(carry[9]));
    not (inverted_trial[9],trial[9]);
    sqrt_full_adder fa9 (.a(shifted[9]),.b(inverted_trial[9]),.cin(carry[9]),.sum(difference[9]),.cout(carry[10]));
    not (inverted_trial[10],trial[10]);
    sqrt_full_adder fa10 (.a(shifted[10]),.b(inverted_trial[10]),.cin(carry[10]),.sum(difference[10]),.cout(carry[11]));
    // No borrow selects subtraction; selected remainder <=722 fits ten bits.
    // Discarded difference MSB on a rejected subtraction is never observed.
    and (selected_difference[0],difference[0],take);
    and (selected_shifted[0],shifted[0],keep);
    or (remainder_out[0],selected_difference[0],selected_shifted[0]);
    and (selected_difference[1],difference[1],take);
    and (selected_shifted[1],shifted[1],keep);
    or (remainder_out[1],selected_difference[1],selected_shifted[1]);
    and (selected_difference[2],difference[2],take);
    and (selected_shifted[2],shifted[2],keep);
    or (remainder_out[2],selected_difference[2],selected_shifted[2]);
    and (selected_difference[3],difference[3],take);
    and (selected_shifted[3],shifted[3],keep);
    or (remainder_out[3],selected_difference[3],selected_shifted[3]);
    and (selected_difference[4],difference[4],take);
    and (selected_shifted[4],shifted[4],keep);
    or (remainder_out[4],selected_difference[4],selected_shifted[4]);
    and (selected_difference[5],difference[5],take);
    and (selected_shifted[5],shifted[5],keep);
    or (remainder_out[5],selected_difference[5],selected_shifted[5]);
    and (selected_difference[6],difference[6],take);
    and (selected_shifted[6],shifted[6],keep);
    or (remainder_out[6],selected_difference[6],selected_shifted[6]);
    and (selected_difference[7],difference[7],take);
    and (selected_shifted[7],shifted[7],keep);
    or (remainder_out[7],selected_difference[7],selected_shifted[7]);
    and (selected_difference[8],difference[8],take);
    and (selected_shifted[8],shifted[8],keep);
    or (remainder_out[8],selected_difference[8],selected_shifted[8]);
    and (selected_difference[9],difference[9],take);
    and (selected_shifted[9],shifted[9],keep);
    or (remainder_out[9],selected_difference[9],selected_shifted[9]);
    assign root_out = {root_in[7:0],take};
endmodule

// Total unsigned17 contract: radicand = root squared + remainder.
module sqrt_u17(input wire [16:0] radicand,
                output wire [8:0] root,
                output wire [9:0] remainder);
    wire [17:0] paired;
    assign paired = {1'b0,radicand};
    wire [8:0] root0;
    wire [9:0] remainder0;
    wire [8:0] root1;
    wire [9:0] remainder1;
    wire [8:0] root2;
    wire [9:0] remainder2;
    wire [8:0] root3;
    wire [9:0] remainder3;
    wire [8:0] root4;
    wire [9:0] remainder4;
    wire [8:0] root5;
    wire [9:0] remainder5;
    wire [8:0] root6;
    wire [9:0] remainder6;
    wire [8:0] root7;
    wire [9:0] remainder7;
    wire [8:0] root8;
    wire [9:0] remainder8;
    wire [8:0] root9;
    wire [9:0] remainder9;
    assign root0 = 9'b0;
    assign remainder0 = 10'b0;
    sqrt_stage stage0 (.root_in(root0),.remainder_in(remainder0),.pair_in(paired[17:16]),.root_out(root1),.remainder_out(remainder1));
    sqrt_stage stage1 (.root_in(root1),.remainder_in(remainder1),.pair_in(paired[15:14]),.root_out(root2),.remainder_out(remainder2));
    sqrt_stage stage2 (.root_in(root2),.remainder_in(remainder2),.pair_in(paired[13:12]),.root_out(root3),.remainder_out(remainder3));
    sqrt_stage stage3 (.root_in(root3),.remainder_in(remainder3),.pair_in(paired[11:10]),.root_out(root4),.remainder_out(remainder4));
    sqrt_stage stage4 (.root_in(root4),.remainder_in(remainder4),.pair_in(paired[9:8]),.root_out(root5),.remainder_out(remainder5));
    sqrt_stage stage5 (.root_in(root5),.remainder_in(remainder5),.pair_in(paired[7:6]),.root_out(root6),.remainder_out(remainder6));
    sqrt_stage stage6 (.root_in(root6),.remainder_in(remainder6),.pair_in(paired[5:4]),.root_out(root7),.remainder_out(remainder7));
    sqrt_stage stage7 (.root_in(root7),.remainder_in(remainder7),.pair_in(paired[3:2]),.root_out(root8),.remainder_out(remainder8));
    sqrt_stage stage8 (.root_in(root8),.remainder_in(remainder8),.pair_in(paired[1:0]),.root_out(root9),.remainder_out(remainder9));
    assign root = root9;
    assign remainder = remainder9;
endmodule
