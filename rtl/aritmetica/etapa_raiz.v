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
