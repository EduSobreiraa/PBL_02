module validador_entrada(input [8:0] sw, output entrada_valida);
wire sinal_positivo;
wire magnitude_bit7_n;
wire magnitude_baixa_zero;
wire magnitude_neg_valida;
wire magnitude_pos_valida;
wire valida_positiva;
wire valida_negativa;
not (sinal_positivo, sw[8]);
not (magnitude_bit7_n, sw[7]);
nor (magnitude_baixa_zero, sw[0], sw[1], sw[2], sw[3], sw[4], sw[5], sw[6]);
or (magnitude_neg_valida, magnitude_bit7_n, magnitude_baixa_zero);
and (magnitude_pos_valida, magnitude_bit7_n, 1'b1);
and (valida_positiva, sinal_positivo, magnitude_pos_valida);
and (valida_negativa, sw[8], magnitude_neg_valida);
or (entrada_valida, valida_positiva, valida_negativa);
endmodule
