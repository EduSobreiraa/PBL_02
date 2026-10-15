`timescale 1ns/1ps
// Somador completo de um bit usado pelas etapas da raiz quadrada.
module somador_completo_raiz(input wire a,b,cin, output wire sum,cout);
    wire a_xor_b,a_and_b,propaga_vai_um;
    xor (a_xor_b,a,b);
    xor (sum,a_xor_b,cin);
    and (a_and_b,a,b);
    and (propaga_vai_um,a_xor_b,cin);
    or (cout,a_and_b,propaga_vai_um);
endmodule
// Tenta subtrair a raiz parcial e escolhe o próximo bit da raiz.
module etapa_raiz(input wire [7:0] root_prefix,
                  input wire [9:0] remainder_in,
                  input wire [1:0] pair_in,
                  output wire take,
                  output wire [9:0] remainder_out);
    wire [10:0] tentativa_invertida, diferenca;
    wire [11:0] vai_um;
    wire manter_original;
    wire [9:0] diferenca_selecionada, resto_deslocado_selecionado;
    // A tentativa usa a raiz parcial e o próximo par de bits.
    not (manter_original,take);
    somador_completo_raiz somador_bit0 (.a(pair_in[0]),.b(1'b0),.cin(1'b1),.sum(diferenca[0]),.cout(vai_um[1]));
    somador_completo_raiz somador_bit1 (.a(pair_in[1]),.b(1'b1),.cin(vai_um[1]),.sum(diferenca[1]),.cout(vai_um[2]));
    not (tentativa_invertida[2],root_prefix[0]);
    somador_completo_raiz somador_bit2 (.a(remainder_in[0]),.b(tentativa_invertida[2]),.cin(vai_um[2]),.sum(diferenca[2]),.cout(vai_um[3]));
    not (tentativa_invertida[3],root_prefix[1]);
    somador_completo_raiz somador_bit3 (.a(remainder_in[1]),.b(tentativa_invertida[3]),.cin(vai_um[3]),.sum(diferenca[3]),.cout(vai_um[4]));
    not (tentativa_invertida[4],root_prefix[2]);
    somador_completo_raiz somador_bit4 (.a(remainder_in[2]),.b(tentativa_invertida[4]),.cin(vai_um[4]),.sum(diferenca[4]),.cout(vai_um[5]));
    not (tentativa_invertida[5],root_prefix[3]);
    somador_completo_raiz somador_bit5 (.a(remainder_in[3]),.b(tentativa_invertida[5]),.cin(vai_um[5]),.sum(diferenca[5]),.cout(vai_um[6]));
    not (tentativa_invertida[6],root_prefix[4]);
    somador_completo_raiz somador_bit6 (.a(remainder_in[4]),.b(tentativa_invertida[6]),.cin(vai_um[6]),.sum(diferenca[6]),.cout(vai_um[7]));
    not (tentativa_invertida[7],root_prefix[5]);
    somador_completo_raiz somador_bit7 (.a(remainder_in[5]),.b(tentativa_invertida[7]),.cin(vai_um[7]),.sum(diferenca[7]),.cout(vai_um[8]));
    not (tentativa_invertida[8],root_prefix[6]);
    somador_completo_raiz somador_bit8 (.a(remainder_in[6]),.b(tentativa_invertida[8]),.cin(vai_um[8]),.sum(diferenca[8]),.cout(vai_um[9]));
    not (tentativa_invertida[9],root_prefix[7]);
    somador_completo_raiz somador_bit9 (.a(remainder_in[7]),.b(tentativa_invertida[9]),.cin(vai_um[9]),.sum(diferenca[9]),.cout(vai_um[10]));
    somador_completo_raiz somador_bit10 (.a(remainder_in[8]),.b(1'b1),.cin(vai_um[10]),.sum(diferenca[10]),.cout(take));
    // A etapa usa a diferença quando a subtração não gera empréstimo; caso contrário, mantém o resto.
    and (diferenca_selecionada[0],diferenca[0],take);
    and (resto_deslocado_selecionado[0],pair_in[0],manter_original);
    or (remainder_out[0],diferenca_selecionada[0],resto_deslocado_selecionado[0]);
    and (diferenca_selecionada[1],diferenca[1],take);
    and (resto_deslocado_selecionado[1],pair_in[1],manter_original);
    or (remainder_out[1],diferenca_selecionada[1],resto_deslocado_selecionado[1]);
    and (diferenca_selecionada[2],diferenca[2],take);
    and (resto_deslocado_selecionado[2],remainder_in[0],manter_original);
    or (remainder_out[2],diferenca_selecionada[2],resto_deslocado_selecionado[2]);
    and (diferenca_selecionada[3],diferenca[3],take);
    and (resto_deslocado_selecionado[3],remainder_in[1],manter_original);
    or (remainder_out[3],diferenca_selecionada[3],resto_deslocado_selecionado[3]);
    and (diferenca_selecionada[4],diferenca[4],take);
    and (resto_deslocado_selecionado[4],remainder_in[2],manter_original);
    or (remainder_out[4],diferenca_selecionada[4],resto_deslocado_selecionado[4]);
    and (diferenca_selecionada[5],diferenca[5],take);
    and (resto_deslocado_selecionado[5],remainder_in[3],manter_original);
    or (remainder_out[5],diferenca_selecionada[5],resto_deslocado_selecionado[5]);
    and (diferenca_selecionada[6],diferenca[6],take);
    and (resto_deslocado_selecionado[6],remainder_in[4],manter_original);
    or (remainder_out[6],diferenca_selecionada[6],resto_deslocado_selecionado[6]);
    and (diferenca_selecionada[7],diferenca[7],take);
    and (resto_deslocado_selecionado[7],remainder_in[5],manter_original);
    or (remainder_out[7],diferenca_selecionada[7],resto_deslocado_selecionado[7]);
    and (diferenca_selecionada[8],diferenca[8],take);
    and (resto_deslocado_selecionado[8],remainder_in[6],manter_original);
    or (remainder_out[8],diferenca_selecionada[8],resto_deslocado_selecionado[8]);
    and (diferenca_selecionada[9],diferenca[9],take);
    and (resto_deslocado_selecionado[9],remainder_in[7],manter_original);
    or (remainder_out[9],diferenca_selecionada[9],resto_deslocado_selecionado[9]);
endmodule

// Calcula a raiz inteira de 17 bits e mantém o resto, de modo que radicando = raiz² + resto.
module raiz_quadrada_17(input wire [16:0] radicand,
                output wire [8:0] root,
                output wire [9:0] remainder);
    wire [9:0] resto_etapa_1;
    wire [9:0] resto_etapa_2;
    wire [9:0] resto_etapa_3;
    wire [9:0] resto_etapa_4;
    wire [9:0] resto_etapa_5;
    wire [9:0] resto_etapa_6;
    wire [9:0] resto_etapa_7;
    wire [9:0] resto_etapa_8;
    etapa_raiz stage0 (.root_prefix(8'b0),.remainder_in(10'b0),.pair_in({1'b0,radicand[16]}),.take(root[8]),.remainder_out(resto_etapa_1));
    etapa_raiz stage1 (.root_prefix({7'b0,root[8]}),.remainder_in(resto_etapa_1),.pair_in(radicand[15:14]),.take(root[7]),.remainder_out(resto_etapa_2));
    etapa_raiz stage2 (.root_prefix({6'b0,root[8:7]}),.remainder_in(resto_etapa_2),.pair_in(radicand[13:12]),.take(root[6]),.remainder_out(resto_etapa_3));
    etapa_raiz stage3 (.root_prefix({5'b0,root[8:6]}),.remainder_in(resto_etapa_3),.pair_in(radicand[11:10]),.take(root[5]),.remainder_out(resto_etapa_4));
    etapa_raiz stage4 (.root_prefix({4'b0,root[8:5]}),.remainder_in(resto_etapa_4),.pair_in(radicand[9:8]),.take(root[4]),.remainder_out(resto_etapa_5));
    etapa_raiz stage5 (.root_prefix({3'b0,root[8:4]}),.remainder_in(resto_etapa_5),.pair_in(radicand[7:6]),.take(root[3]),.remainder_out(resto_etapa_6));
    etapa_raiz stage6 (.root_prefix({2'b0,root[8:3]}),.remainder_in(resto_etapa_6),.pair_in(radicand[5:4]),.take(root[2]),.remainder_out(resto_etapa_7));
    etapa_raiz stage7 (.root_prefix({1'b0,root[8:2]}),.remainder_in(resto_etapa_7),.pair_in(radicand[3:2]),.take(root[1]),.remainder_out(resto_etapa_8));
    etapa_raiz stage8 (.root_prefix(root[8:1]),.remainder_in(resto_etapa_8),.pair_in(radicand[1:0]),.take(root[0]),.remainder_out(remainder));
endmodule
