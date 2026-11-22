module incrementa_9(input wire [8:0] value,input wire increment,output wire [8:0] result);
    wire [9:0] vai_um;
    somador_completo_raiz somador_bit_0(.a(value[0]),.b(1'b0),.cin(increment),.sum(result[0]),.cout(vai_um[1]));
    somador_completo_raiz somador_bit_1(.a(value[1]),.b(1'b0),.cin(vai_um[1]),.sum(result[1]),.cout(vai_um[2]));
    somador_completo_raiz somador_bit_2(.a(value[2]),.b(1'b0),.cin(vai_um[2]),.sum(result[2]),.cout(vai_um[3]));
    somador_completo_raiz somador_bit_3(.a(value[3]),.b(1'b0),.cin(vai_um[3]),.sum(result[3]),.cout(vai_um[4]));
    somador_completo_raiz somador_bit_4(.a(value[4]),.b(1'b0),.cin(vai_um[4]),.sum(result[4]),.cout(vai_um[5]));
    somador_completo_raiz somador_bit_5(.a(value[5]),.b(1'b0),.cin(vai_um[5]),.sum(result[5]),.cout(vai_um[6]));
    somador_completo_raiz somador_bit_6(.a(value[6]),.b(1'b0),.cin(vai_um[6]),.sum(result[6]),.cout(vai_um[7]));
    somador_completo_raiz somador_bit_7(.a(value[7]),.b(1'b0),.cin(vai_um[7]),.sum(result[7]),.cout(vai_um[8]));
    somador_completo_raiz somador_bit_8(.a(value[8]),.b(1'b0),.cin(vai_um[8]),.sum(result[8]),.cout(vai_um[9]));
endmodule
