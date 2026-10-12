`timescale 1ns/1ps
module flag_ov_err(input wire loaded,
                   input wire signed [7:0] a,
                   input wire signed [17:0] delta,
                   output wire OV, ERR);
    wire a_nonzero, a_zero, invalid_domain;
    or (a_nonzero,a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7]);
    not (a_zero,a_nonzero);
    or (invalid_domain,a_zero,delta[17]);
    and (ERR,loaded,invalid_domain);
    assign OV = 1'b0;
endmodule

module flag_z(input wire signed [22:0] value,
              input wire [1:0] sel,
              input wire ERR,
              output wire Z);
    wire nonzero, zero_value, invalid_root, valid_value;
    or (nonzero,value[0],value[1],value[2],value[3],value[4],value[5],value[6],value[7],value[8],value[9],value[10],value[11],value[12],value[13],value[14],value[15],value[16],value[17],value[18],value[19],value[20],value[21],value[22]);
    not (zero_value,nonzero);
    and (invalid_root,sel[1],ERR);
    not (valid_value,invalid_root);
    and (Z,zero_value,valid_value);
endmodule

module flag_c(input wire carry_y, loaded,
              input wire [1:0] sel,
              output wire C);
    wire not_sel1;
    not (not_sel1,sel[1]);
    and (C,carry_y,loaded,sel[0],not_sel1);
endmodule
