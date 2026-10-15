`timescale 1ns/1ps
// Confere raiz inteira e resto para os radicandos testados.
module tb_sqrt_u17;
    reg [16:0] radicando;
    wire [8:0] raiz;
    wire [9:0] resto;
    integer n,raiz_esperada,resto_esperado,casos_verificados,raiz_observada,resto_observado;
    raiz_quadrada_17 dut (.radicand(radicando),.root(raiz),.remainder(resto));
    initial begin
        raiz_esperada=0;
        casos_verificados=0;
        for(n=0;n<131072;n=n+1) begin
            // A referência procura por inteiros entre quadrados perfeitos.
            while((raiz_esperada+1)*(raiz_esperada+1)<=n)
                raiz_esperada=raiz_esperada+1;
            resto_esperado=n-raiz_esperada*raiz_esperada;
            radicando=n[16:0];
            #1;
            raiz_observada={23'b0,raiz};
            resto_observado={22'b0,resto};
            case((raiz_observada===raiz_esperada) &&
                 (resto_observado===resto_esperado) &&
                 (raiz_observada*raiz_observada<=n) &&
                 (n<(raiz_observada+1)*(raiz_observada+1)) &&
                 (n==raiz_observada*raiz_observada+resto_observado) &&
                 (resto_observado<2*raiz_observada+1))
                1'b1:;
                default:$fatal(1,"TEST-004 FAIL n=%0d raiz=%0d resto=%0d raiz_esperada=%0d resto_esperado=%0d",n,raiz,resto,raiz_esperada,resto_esperado);
            endcase
            casos_verificados=casos_verificados+1;
            case(n & 16383)
                16383:begin
                    $display("TEST-004 progresso casos_verificados=%0d",casos_verificados);
                    $fflush();
                end
                default:;
            endcase
        end
        case(casos_verificados)
            131072:;
            default:$fatal(1,"TEST-004 incompleto coverage=%0d",casos_verificados);
        endcase
        $display("TEST-004 PASS radicands=%0d falhas=0",casos_verificados);
        $finish;
    end
endmodule
