`timescale 1ns/1ps
// Private binary nucleo. Exact signed results are guaranteed only in consumer domains.
module somador_23_nucleo(input wire signed [22:0] lhs, rhs,
                  output wire signed [22:0] sum, output wire carry_out);
    wire [23:0] vai_um;
    somador_completo somador_bit0 (.a(lhs[0]), .b(rhs[0]), .cin(1'b0), .sum(sum[0]), .cout(vai_um[1]));
    somador_completo somador_bit22 (.a(lhs[22]), .b(rhs[22]), .cin(vai_um[22]), .sum(sum[22]), .cout(carry_out));
    somador_completo somador_bit1 (.a(lhs[1]), .b(rhs[1]), .cin(vai_um[1]), .sum(sum[1]), .cout(vai_um[2]));
    somador_completo somador_bit2 (.a(lhs[2]), .b(rhs[2]), .cin(vai_um[2]), .sum(sum[2]), .cout(vai_um[3]));
    somador_completo somador_bit3 (.a(lhs[3]), .b(rhs[3]), .cin(vai_um[3]), .sum(sum[3]), .cout(vai_um[4]));
    somador_completo somador_bit4 (.a(lhs[4]), .b(rhs[4]), .cin(vai_um[4]), .sum(sum[4]), .cout(vai_um[5]));
    somador_completo somador_bit5 (.a(lhs[5]), .b(rhs[5]), .cin(vai_um[5]), .sum(sum[5]), .cout(vai_um[6]));
    somador_completo somador_bit6 (.a(lhs[6]), .b(rhs[6]), .cin(vai_um[6]), .sum(sum[6]), .cout(vai_um[7]));
    somador_completo somador_bit7 (.a(lhs[7]), .b(rhs[7]), .cin(vai_um[7]), .sum(sum[7]), .cout(vai_um[8]));
    somador_completo somador_bit8 (.a(lhs[8]), .b(rhs[8]), .cin(vai_um[8]), .sum(sum[8]), .cout(vai_um[9]));
    somador_completo somador_bit9 (.a(lhs[9]), .b(rhs[9]), .cin(vai_um[9]), .sum(sum[9]), .cout(vai_um[10]));
    somador_completo somador_bit10 (.a(lhs[10]), .b(rhs[10]), .cin(vai_um[10]), .sum(sum[10]), .cout(vai_um[11]));
    somador_completo somador_bit11 (.a(lhs[11]), .b(rhs[11]), .cin(vai_um[11]), .sum(sum[11]), .cout(vai_um[12]));
    somador_completo somador_bit12 (.a(lhs[12]), .b(rhs[12]), .cin(vai_um[12]), .sum(sum[12]), .cout(vai_um[13]));
    somador_completo somador_bit13 (.a(lhs[13]), .b(rhs[13]), .cin(vai_um[13]), .sum(sum[13]), .cout(vai_um[14]));
    somador_completo somador_bit14 (.a(lhs[14]), .b(rhs[14]), .cin(vai_um[14]), .sum(sum[14]), .cout(vai_um[15]));
    somador_completo somador_bit15 (.a(lhs[15]), .b(rhs[15]), .cin(vai_um[15]), .sum(sum[15]), .cout(vai_um[16]));
    somador_completo somador_bit16 (.a(lhs[16]), .b(rhs[16]), .cin(vai_um[16]), .sum(sum[16]), .cout(vai_um[17]));
    somador_completo somador_bit17 (.a(lhs[17]), .b(rhs[17]), .cin(vai_um[17]), .sum(sum[17]), .cout(vai_um[18]));
    somador_completo somador_bit18 (.a(lhs[18]), .b(rhs[18]), .cin(vai_um[18]), .sum(sum[18]), .cout(vai_um[19]));
    somador_completo somador_bit19 (.a(lhs[19]), .b(rhs[19]), .cin(vai_um[19]), .sum(sum[19]), .cout(vai_um[20]));
    somador_completo somador_bit20 (.a(lhs[20]), .b(rhs[20]), .cin(vai_um[20]), .sum(sum[20]), .cout(vai_um[21]));
    somador_completo somador_bit21 (.a(lhs[21]), .b(rhs[21]), .cin(vai_um[21]), .sum(sum[21]), .cout(vai_um[22]));
endmodule

// Public wrapper has no vai_um or overflow port.
module somador_23(input wire signed [22:0] lhs, rhs, output wire signed [22:0] sum);
    wire vai_um_nao_utilizado;
    somador_23_nucleo nucleo (.lhs(lhs), .rhs(rhs), .sum(sum), .carry_out(vai_um_nao_utilizado));
endmodule

// Delta consumer: operando_esquerdo=coeficiente_b squared, operando_direito=four times coeficiente_a times coeficiente_c, both signed18.
module subtrator_18(input wire signed [17:0] lhs, rhs, output wire signed [17:0] difference);
    wire [17:0] direito_invertido;
    wire [18:0] vai_um;
    not (direito_invertido[0], rhs[0]);
    not (direito_invertido[1], rhs[1]);
    not (direito_invertido[2], rhs[2]);
    not (direito_invertido[3], rhs[3]);
    not (direito_invertido[4], rhs[4]);
    not (direito_invertido[5], rhs[5]);
    not (direito_invertido[6], rhs[6]);
    not (direito_invertido[7], rhs[7]);
    not (direito_invertido[8], rhs[8]);
    not (direito_invertido[9], rhs[9]);
    not (direito_invertido[10], rhs[10]);
    not (direito_invertido[11], rhs[11]);
    not (direito_invertido[12], rhs[12]);
    not (direito_invertido[13], rhs[13]);
    not (direito_invertido[14], rhs[14]);
    not (direito_invertido[15], rhs[15]);
    not (direito_invertido[16], rhs[16]);
    not (direito_invertido[17], rhs[17]);
    somador_completo somador_bit0 (.a(lhs[0]), .b(direito_invertido[0]), .cin(1'b1), .sum(difference[0]), .cout(vai_um[1]));
    somador_completo somador_bit1 (.a(lhs[1]), .b(direito_invertido[1]), .cin(vai_um[1]), .sum(difference[1]), .cout(vai_um[2]));
    somador_completo somador_bit2 (.a(lhs[2]), .b(direito_invertido[2]), .cin(vai_um[2]), .sum(difference[2]), .cout(vai_um[3]));
    somador_completo somador_bit3 (.a(lhs[3]), .b(direito_invertido[3]), .cin(vai_um[3]), .sum(difference[3]), .cout(vai_um[4]));
    somador_completo somador_bit4 (.a(lhs[4]), .b(direito_invertido[4]), .cin(vai_um[4]), .sum(difference[4]), .cout(vai_um[5]));
    somador_completo somador_bit5 (.a(lhs[5]), .b(direito_invertido[5]), .cin(vai_um[5]), .sum(difference[5]), .cout(vai_um[6]));
    somador_completo somador_bit6 (.a(lhs[6]), .b(direito_invertido[6]), .cin(vai_um[6]), .sum(difference[6]), .cout(vai_um[7]));
    somador_completo somador_bit7 (.a(lhs[7]), .b(direito_invertido[7]), .cin(vai_um[7]), .sum(difference[7]), .cout(vai_um[8]));
    somador_completo somador_bit8 (.a(lhs[8]), .b(direito_invertido[8]), .cin(vai_um[8]), .sum(difference[8]), .cout(vai_um[9]));
    somador_completo somador_bit9 (.a(lhs[9]), .b(direito_invertido[9]), .cin(vai_um[9]), .sum(difference[9]), .cout(vai_um[10]));
    somador_completo somador_bit10 (.a(lhs[10]), .b(direito_invertido[10]), .cin(vai_um[10]), .sum(difference[10]), .cout(vai_um[11]));
    somador_completo somador_bit11 (.a(lhs[11]), .b(direito_invertido[11]), .cin(vai_um[11]), .sum(difference[11]), .cout(vai_um[12]));
    somador_completo somador_bit12 (.a(lhs[12]), .b(direito_invertido[12]), .cin(vai_um[12]), .sum(difference[12]), .cout(vai_um[13]));
    somador_completo somador_bit13 (.a(lhs[13]), .b(direito_invertido[13]), .cin(vai_um[13]), .sum(difference[13]), .cout(vai_um[14]));
    somador_completo somador_bit14 (.a(lhs[14]), .b(direito_invertido[14]), .cin(vai_um[14]), .sum(difference[14]), .cout(vai_um[15]));
    somador_completo somador_bit15 (.a(lhs[15]), .b(direito_invertido[15]), .cin(vai_um[15]), .sum(difference[15]), .cout(vai_um[16]));
    somador_completo somador_bit16 (.a(lhs[16]), .b(direito_invertido[16]), .cin(vai_um[16]), .sum(difference[16]), .cout(vai_um[17]));
    somador_completo somador_bit17 (.a(lhs[17]), .b(direito_invertido[17]), .cin(vai_um[17]), .sum(difference[17]), .cout(vai_um[18]));
endmodule
