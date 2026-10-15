`timescale 1ns/1ps
// Testa soma e subtração em vários valores e tipos de operação.
module tb_add_sub;
    reg fa_a, fa_b, fa_cin;
    wire fa_sum, fa_cout;
    reg signed [22:0] lhs23, rhs23;
    wire signed [22:0] soma_publica, soma_nucleo;
    wire vai_um_saida;
    reg signed [17:0] lhs18, rhs18;
    wire signed [17:0] diferenca;
    integer arquivo_vetores, vetor_lido, tipo_vetor, operando_esquerdo, operando_direito, esperado, vai_um_esperado;
    integer n, contagem_linhas, contagem_somas, contagem_subtracoes, contagem_modular;
    somador_completo fa (.a(fa_a), .b(fa_b), .cin(fa_cin), .sum(fa_sum), .cout(fa_cout));
    somador_23 somador_publico (.lhs(lhs23), .rhs(rhs23), .sum(soma_publica));
    somador_23_nucleo nucleo (.lhs(lhs23), .rhs(rhs23), .sum(soma_nucleo), .carry_out(vai_um_saida));
    subtrator_18 subtrator (.lhs(lhs18), .rhs(rhs18), .difference(diferenca));
    initial begin
        for (n=0; n<8; n=n+1) begin
            {fa_a,fa_b,fa_cin}=n[2:0];
            esperado=(n & 1)+((n >> 1) & 1)+((n >> 2) & 1);
            #1;
            case ({fa_cout,fa_sum} === esperado[1:0])
                1'b1: ;
                default: $fatal(1,"FA mismatch n=%0d",n);
            endcase
        end
        arquivo_vetores=$fopen("verification/vectors/add_sub.txt","r");
        case (arquivo_vetores)
            0: $fatal(1,"Cannot open vectors");
            default: ;
        endcase
        contagem_linhas=0; contagem_somas=0; contagem_subtracoes=0; contagem_modular=0;
        while (!$feof(arquivo_vetores)) begin
            vetor_lido=$fscanf(arquivo_vetores,"%d %d %d %d %d\n",tipo_vetor,operando_esquerdo,operando_direito,esperado,vai_um_esperado);
            case (vetor_lido)
                5: begin
                    contagem_linhas=contagem_linhas+1;
                    case (tipo_vetor)
                        0,2: begin
                            lhs23=operando_esquerdo; rhs23=operando_direito;
                            #1;
                            case (($signed(soma_nucleo) === esperado) && (vai_um_saida === vai_um_esperado[0]))
                                1'b1: ;
                                default: $fatal(1,"add nucleo linha=%0d operando_esquerdo=%0d operando_direito=%0d got=%0d vai_um=%0d esperado=%0d vai_um=%0d",contagem_linhas,operando_esquerdo,operando_direito,soma_nucleo,vai_um_saida,esperado,vai_um_esperado);
                            endcase
                            case (tipo_vetor)
                                0: begin
                                    contagem_somas=contagem_somas+1;
                                    case ($signed(soma_publica) === esperado)
                                        1'b1: ;
                                        default: $fatal(1,"public soma linha=%0d",contagem_linhas);
                                    endcase
                                end
                                2: contagem_modular=contagem_modular+1;
                            endcase
                        end
                        1: begin
                            lhs18=operando_esquerdo; rhs18=operando_direito;
                            #1;
                            contagem_subtracoes=contagem_subtracoes+1;
                            case ($signed(diferenca) === esperado)
                                1'b1: ;
                                default: $fatal(1,"sub linha=%0d got=%0d esperado=%0d",contagem_linhas,diferenca,esperado);
                            endcase
                        end
                        default: $fatal(1,"Unknown vector type");
                    endcase
                end
                default: $fatal(1,"Malformed vector linha=%0d vetor_lido=%0d",contagem_linhas,vetor_lido);
            endcase
        end
        $fclose(arquivo_vetores);
        case ((contagem_linhas==37212) && (contagem_somas==24808) && (contagem_subtracoes==12401) && (contagem_modular==3))
            1'b1: ;
            default: $fatal(1,"Incomplete vectors rows=%0d",contagem_linhas);
        endcase
        $display("TEST-002 PASS somador_completo=8 exact_add=%0d delta=%0d core_modular=%0d rows=%0d",contagem_somas,contagem_subtracoes,contagem_modular,contagem_linhas);
        $finish;
    end
endmodule
