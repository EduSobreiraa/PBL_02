module somador_completo_raiz(input wire a,b,cin, output wire sum,cout);
    wire a_xor_b,a_and_b,propaga_vai_um;
    xor (a_xor_b,a,b);
    xor (sum,a_xor_b,cin);
    and (a_and_b,a,b);
    and (propaga_vai_um,a_xor_b,cin);
    or (cout,a_and_b,propaga_vai_um);
endmodule
