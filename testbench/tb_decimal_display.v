`timescale 1ns/1ps
// Testa a conversão do resultado para os seis displays.
module tb_decimal_display;
    reg signed [22:0] valor;
    reg invalido;
    wire [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
    reg [3:0] digito;
    wire [6:0] segmentos_decodificados;
    wire [3:0] bcd_corrigido;
    wire [22:0] modulo_sinalizado;
    wire [26:0] bcd_corrigido;
    wire [27:0] bcd;
    reg [41:0] esperado;
    reg [27:0] bcd_esperado;
    integer contagem,i,j,semente,valor_aleatorio,v,mag,temp,k,limit,d,soma_tres_esperada;
    exibicao_decimal dut(.value(valor),.invalid(invalido),.HEX0(HEX0),.HEX1(HEX1),.HEX2(HEX2),.HEX3(HEX3),.HEX4(HEX4),.HEX5(HEX5));
    decodificador_bcd_segmentos decoder(.digit(digito),.segments(segmentos_decodificados));
    soma_tres_bcd corrector(.digit(digito),.corrected(bcd_corrigido));
    magnitude_decimal abs_check(.value(valor),.magnitude(modulo_sinalizado));
    conversor_binario_bcd conversion_check(.magnitude(modulo_sinalizado),.corrected(bcd_corrigido));
    assign bcd={bcd_corrigido[26:3],bcd_corrigido[2:0],modulo_sinalizado[0]};
    function [6:0] codificar;
        input integer digito_decimal;
        begin
            case (digito_decimal)
                0: codificar=7'b1000000;
                1: codificar=7'b1111001;
                2: codificar=7'b0100100;
                3: codificar=7'b0110000;
                4: codificar=7'b0011001;
                5: codificar=7'b0010010;
                6: codificar=7'b0000010;
                7: codificar=7'b1111000;
                8: codificar=7'b0000000;
                9: codificar=7'b0010000;
                default: codificar=7'b1111111;
            endcase
        end
    endfunction
    task check;
        input integer valor_entrada;
        input entrada_invalida;
        integer valor_absoluto,restante,posicao,valor_digito;
        reg fora_da_faixa;
        begin
            valor=valor_entrada[22:0]; invalido=entrada_invalida;
            case (valor_entrada<0) 1: valor_absoluto=-valor_entrada; default: valor_absoluto=valor_entrada; endcase
            fora_da_faixa=entrada_invalida || (valor_entrada>999999) || (valor_entrada< -99999);
            esperado={6{7'b1111111}};
            case (fora_da_faixa)
                1: esperado={6{7'b0111111}};
                0: begin
                    restante=valor_absoluto;
                    for (posicao=0;posicao<6;posicao=posicao+1) begin
                        valor_digito=restante%10;
                        case ((posicao==0)||(restante!=0))
                            1: esperado[posicao*7+:7]=codificar(valor_digito);
                            default: ;
                        endcase
                        restante=restante/10;
                    end
                    case (valor_entrada<0) 1: esperado[35+:7]=7'b0111111; default: ; endcase
                end
            endcase
            restante=valor_absoluto;
            for (posicao=0;posicao<7;posicao=posicao+1) begin
                valor_digito=restante%10;
                bcd_esperado[posicao*4+:4]=valor_digito[3:0];
                restante=restante/10;
            end
            #1;
            case (({HEX5,HEX4,HEX3,HEX2,HEX1,HEX0}===esperado) && (modulo_sinalizado===valor_absoluto[22:0]) && (bcd===bcd_esperado))
                1: ;
                default: $fatal(1,"exibicao v=%0d invalido=%b got=%h esperado=%h bcd=%h bcd_esperado=%h",valor_entrada,entrada_invalida,{HEX5,HEX4,HEX3,HEX2,HEX1,HEX0},esperado,bcd,bcd_esperado);
            endcase
            contagem=contagem+1;
        end
    endtask
    initial begin
        contagem=0; semente=20261011;
        for (i=0;i<16;i=i+1) begin
            digito=i[3:0];
            case (i>=5) 1: soma_tres_esperada=i+3; default: soma_tres_esperada=i; endcase
            #1;
            case ((segmentos_decodificados===codificar(i)) && (bcd_corrigido===soma_tres_esperada[3:0]))
                1: ;
                default: $fatal(1,"BCD/add3 digito=%d",i);
            endcase
        end
        for (j=0;j<2;j=j+1) begin
            check(0,j[0]); check(1,j[0]); check(-1,j[0]);
            check(99999,j[0]); check(100000,j[0]); check(999999,j[0]);
            check(1000000,j[0]); check(-99999,j[0]); check(-100000,j[0]);
            check(-4194304,j[0]); check(4194303,j[0]);
            check(123456,j[0]); check(-12345,j[0]); check(909090,j[0]);
            check(100001,j[0]); check(-10001,j[0]);
            for (i=0;i<1000;i=i+1) begin
                check(i,j[0]); check(-i,j[0]);
            end
            for (i=0;i<1000;i=i+1) begin
                valor_aleatorio=$random(semente); v=$signed(valor_aleatorio[22:0]);
                check(v,j[0]);
                valor_aleatorio=$random(semente); v=(valor_aleatorio & 32'h7fffffff)%1000000;
                check(v,j[0]); check(-(v%100000),j[0]);
            end
        end
        case (contagem) 10032: ; default: $fatal(1,"Incomplete exibicao test contagem=%0d",contagem); endcase
        $display("TEST-008 DISPLAY PASS cases=%0d BCD_add3=16 semente=20261011 segments_magnitude_BCD=PASS",contagem);
        $finish;
    end
endmodule
