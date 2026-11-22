module somador_completo_divisao(input wire a, b, cin, output wire sum, cout);
    wire propaga_vai_um, gera_vai_um, vai_um_propagado;
    xor p(propaga_vai_um, a, b);
    xor s(sum, propaga_vai_um, cin);
    and g(gera_vai_um, a, b);
    and h(vai_um_propagado, propaga_vai_um, cin);
    or coeficiente_c(cout, gera_vai_um, vai_um_propagado);
endmodule
