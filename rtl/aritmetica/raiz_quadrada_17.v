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
