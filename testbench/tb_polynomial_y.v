`timescale 1ns/1ps
module tb_polynomial_y;
    reg signed [7:0] coeficiente_a, coeficiente_b, coeficiente_c, entrada_x;
    wire signed [22:0] resultado_y_publico, resultado_y_nucleo;
    wire OV_publico, OV_nucleo, vai_um_y;
    integer arquivo_vetores, vetor_lido, tipo_vetor, valor_a, valor_b, valor_c, valor_x, resultado_y_esperado, vai_um_esperado;
    integer rows, contagem_dirigidos, contagem_cartesianos, contagem_aleatorios;
    polinomio_y dut_publico(.a(coeficiente_a), .b(coeficiente_b), .c(coeficiente_c), .x(entrada_x), .y(resultado_y_publico), .OV(OV_publico));
    polinomio_y_nucleo dut_nucleo(.a(coeficiente_a), .b(coeficiente_b), .c(coeficiente_c), .x(entrada_x),
        .y(resultado_y_nucleo), .OV(OV_nucleo), .carry_y(vai_um_y));
    initial begin
        arquivo_vetores=$fopen("verification/vectors/resultado_y.txt","r");
        case (arquivo_vetores)
            0: $fatal(1,"Cannot open resultado_y vectors");
            default: ;
        endcase
        rows=0; contagem_dirigidos=0; contagem_cartesianos=0; contagem_aleatorios=0;
        while (!$feof(arquivo_vetores)) begin
            vetor_lido=$fscanf(arquivo_vetores,"%d %d %d %d %d %d %d\n",tipo_vetor,valor_a,valor_b,valor_c,valor_x,resultado_y_esperado,vai_um_esperado);
            case (vetor_lido)
                7: begin
                    coeficiente_a=valor_a[7:0]; coeficiente_b=valor_b[7:0]; coeficiente_c=valor_c[7:0]; entrada_x=valor_x[7:0];
                    #1;
                    rows=rows+1;
                    case (($signed(resultado_y_nucleo) === resultado_y_esperado) &&
                        ($signed(resultado_y_publico) === resultado_y_esperado) &&
                        (vai_um_y === vai_um_esperado[0]) &&
                        (OV_nucleo === 1'b0) && (OV_publico === 1'b0))
                        1'b1: ;
                        default: $fatal(1,"resultado_y linha=%0d coeficiente_a=%0d coeficiente_b=%0d coeficiente_c=%0d entrada_x=%0d nucleo=%0d public=%0d esperado=%0d vai_um=%0d vai_um_esperado=%0d OV=%b%b",rows,valor_a,valor_b,valor_c,valor_x,resultado_y_nucleo,resultado_y_publico,resultado_y_esperado,vai_um_y,vai_um_esperado,OV_nucleo,OV_publico);
                    endcase
                    case (tipo_vetor)
                        0: contagem_dirigidos=contagem_dirigidos+1;
                        1: contagem_cartesianos=contagem_cartesianos+1;
                        2: contagem_aleatorios=contagem_aleatorios+1;
                        default: $fatal(1,"Unknown vector type");
                    endcase
                end
                default: $fatal(1,"Malformed resultado_y vector linha=%0d vetor_lido=%0d",rows,vetor_lido);
            endcase
        end
        $fclose(arquivo_vetores);
        case ((rows==12413) && (contagem_dirigidos==12) && (contagem_cartesianos==2401) && (contagem_aleatorios==10000))
            1'b1: ;
            default: $fatal(1,"Incomplete resultado_y vectors rows=%0d",rows);
        endcase
        $display("TEST-006 PASS dirigidos=%0d cartesian=%0d aleatorio=%0d rows=%0d wrapper_core=PASS vai_um=PASS OV=PASS",contagem_dirigidos,contagem_cartesianos,contagem_aleatorios,rows);
        $finish;
    end
endmodule
