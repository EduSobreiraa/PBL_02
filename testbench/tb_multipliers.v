`timescale 1ns/1ps
module tb_multipliers;
    reg signed [7:0] lhs8, rhs8;
    reg signed [7:0] lhs_mixed;
    reg [14:0] rhs15;
    wire signed [15:0] produto_com_sinal;
    wire signed [21:0] produto_misto;
    integer coeficiente_a,coeficiente_b,esperado,arquivo_vetores,vetor_lido,tipo_vetor,valor_a,valor_b,contagem_com_sinal,contagem_mista,contagem_quadrados,contagem_limites;
    multiplica_com_sinal_8_por_8 signed_dut (.lhs(lhs8),.rhs(rhs8),.product(produto_com_sinal));
    multiplica_com_sinal_8_por_sem_sinal_15 mixed_dut (.lhs(lhs_mixed),.rhs(rhs15),.product(produto_misto));
    initial begin
        contagem_com_sinal=0; contagem_mista=0; contagem_quadrados=0; contagem_limites=0;
        lhs8=0;rhs8=0;lhs_mixed=0;rhs15=0;
        arquivo_vetores=$fopen("verification/vectors/multipliers.txt","r");
        case(arquivo_vetores) 0:$fatal(1,"Missing referencia vectors"); default:; endcase
        while (!$feof(arquivo_vetores)) begin
            vetor_lido=$fscanf(arquivo_vetores,"%d %d %d %d\n",tipo_vetor,valor_a,valor_b,esperado);
            case(vetor_lido)
                4: begin
                    contagem_limites=contagem_limites+1;
                    case(tipo_vetor)
                        0: begin
                            lhs8=valor_a;rhs8=valor_b;#1;
                            case($signed(produto_com_sinal)===esperado)
                                1'b1:; default:$fatal(1,"Boundary signed coeficiente_a=%0d coeficiente_b=%0d",valor_a,valor_b);
                            endcase
                        end
                        1: begin
                            lhs_mixed=valor_a;rhs15=valor_b;#1;
                            case($signed(produto_misto)===esperado)
                                1'b1:; default:$fatal(1,"Boundary mixed coeficiente_a=%0d coeficiente_b=%0d",valor_a,valor_b);
                            endcase
                        end
                        default:$fatal(1,"Unknown limite tipo_vetor");
                    endcase
                end
                default:$fatal(1,"Malformed limite vector");
            endcase
        end
        $fclose(arquivo_vetores);
        for(coeficiente_a=-128;coeficiente_a<128;coeficiente_a=coeficiente_a+1) begin
            for(coeficiente_b=-128;coeficiente_b<128;coeficiente_b=coeficiente_b+1) begin
                lhs8=coeficiente_a;rhs8=coeficiente_b;esperado=coeficiente_a*coeficiente_b;#1;
                case($signed(produto_com_sinal)===esperado)
                    1'b1:;default:$fatal(1,"Signed coeficiente_a=%0d coeficiente_b=%0d got=%0d esperado=%0d",coeficiente_a,coeficiente_b,produto_com_sinal,esperado);
                endcase
                contagem_com_sinal=contagem_com_sinal+1;
            end
        end
        for(coeficiente_a=-128;coeficiente_a<128;coeficiente_a=coeficiente_a+1) begin
            lhs8=coeficiente_a;rhs8=coeficiente_a;esperado=coeficiente_a*coeficiente_a;#1;
            case((produto_com_sinal[15]===1'b0) && ({1'b0,produto_com_sinal[14:0]}===esperado))
                1'b1:;default:$fatal(1,"Square conversion coeficiente_a=%0d",coeficiente_a);
            endcase
            contagem_quadrados=contagem_quadrados+1;
        end
        for(coeficiente_a=-128;coeficiente_a<128;coeficiente_a=coeficiente_a+1) begin
            lhs_mixed=coeficiente_a;
            for(coeficiente_b=0;coeficiente_b<=16384;coeficiente_b=coeficiente_b+1) begin
                rhs15=coeficiente_b;esperado=coeficiente_a*coeficiente_b;#1;
                case($signed(produto_misto)===esperado)
                    1'b1:;default:$fatal(1,"Mixed coeficiente_a=%0d coeficiente_b=%0d got=%0d esperado=%0d",coeficiente_a,coeficiente_b,produto_misto,esperado);
                endcase
                contagem_mista=contagem_mista+1;
            end
            case(coeficiente_a & 31)
                31:$display("TEST-003 progresso operando_esquerdo=%0d mixed=%0d",coeficiente_a,contagem_mista);
                default:;
            endcase
        end
        case((contagem_com_sinal==65536)&&(contagem_mista==4194560)&&(contagem_quadrados==256)&&(contagem_limites==91))
            1'b1:;default:$fatal(1,"Incomplete coverage");
        endcase
        $display("TEST-003 PASS signed=%0d mixed=%0d squares=%0d limite=%0d",contagem_com_sinal,contagem_mista,contagem_quadrados,contagem_limites);
        $finish;
    end
endmodule
