module quadratic_roots(input wire signed [7:0] a,b,c,
    output wire signed [17:0] delta, output wire signed [8:0] x1,x2, output wire domain_error);
    wire signed [15:0] quadrado_coeficiente_b,produto_coeficientes_a_c;
    wire coeficiente_a_zero,valido,delta_nao_negativo;
    wire [16:0] radicando;
    wire [8:0] raiz_quadrada;
    wire [9:0] resto_quadrado,oposto_coeficiente_b,numerador_positivo,numerador_negativo;
    wire [7:0] magnitude_coeficiente_a;
    multiplica_com_sinal_8_por_8 mb(.lhs(b),.rhs(b),.product(quadrado_coeficiente_b));
    multiplica_com_sinal_8_por_8 mac(.lhs(a),.rhs(c),.product(produto_coeficientes_a_c));
    subtrator_18 discriminant(.lhs({3'b000,quadrado_coeficiente_b[14:0]}),.rhs({produto_coeficientes_a_c,2'b00}),.difference(delta));
    nor az(coeficiente_a_zero,a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7]);
    // A equação não tem as raízes pedidas quando A é zero ou o discriminante é negativo.
    or err(domain_error,coeficiente_a_zero,delta[17]);
    not v(valido,domain_error);
    not dn(delta_nao_negativo,delta[17]);
    and rad0(radicando[0],delta[0],delta_nao_negativo);
    and rad1(radicando[1],delta[1],delta_nao_negativo);
    and rad2(radicando[2],delta[2],delta_nao_negativo);
    and rad3(radicando[3],delta[3],delta_nao_negativo);
    and rad4(radicando[4],delta[4],delta_nao_negativo);
    and rad5(radicando[5],delta[5],delta_nao_negativo);
    and rad6(radicando[6],delta[6],delta_nao_negativo);
    and rad7(radicando[7],delta[7],delta_nao_negativo);
    and rad8(radicando[8],delta[8],delta_nao_negativo);
    and rad9(radicando[9],delta[9],delta_nao_negativo);
    and rad10(radicando[10],delta[10],delta_nao_negativo);
    and rad11(radicando[11],delta[11],delta_nao_negativo);
    and rad12(radicando[12],delta[12],delta_nao_negativo);
    and rad13(radicando[13],delta[13],delta_nao_negativo);
    and rad14(radicando[14],delta[14],delta_nao_negativo);
    and rad15(radicando[15],delta[15],delta_nao_negativo);
    and rad16(radicando[16],delta[16],delta_nao_negativo);
    // O resto da raiz é mantido até o arredondamento final.
    raiz_quadrada_17 raiz(.radicand(radicando),.root(raiz_quadrada),.remainder(resto_quadrado));
    nega_condicional_10 nb(.value({{2{b[7]}},b}),.negate(1'b1),.result(oposto_coeficiente_b));
    soma_subtrai_10 np(.lhs(oposto_coeficiente_b),.rhs({1'b0,raiz_quadrada}),.subtract(1'b0),.result(numerador_positivo));
    soma_subtrai_10 nm(.lhs(oposto_coeficiente_b),.rhs({1'b0,raiz_quadrada}),.subtract(1'b1),.result(numerador_negativo));
    nega_condicional_8 amag(.value(a),.negate(a[7]),.result(magnitude_coeficiente_a));
    ramo_raizes ramo_mais(.numerator(numerador_positivo),.magnitude_a(magnitude_coeficiente_a),.sign_a(a[7]),.square_remainder(resto_quadrado),.plus_branch(1'b1),.valid(valido),.result(x1));
    ramo_raizes ramo_negativo(.numerator(numerador_negativo),.magnitude_a(magnitude_coeficiente_a),.sign_a(a[7]),.square_remainder(resto_quadrado),.plus_branch(1'b0),.valid(valido),.result(x2));
endmodule
