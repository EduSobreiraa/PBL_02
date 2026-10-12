`timescale 1ns/1ps
module tb_divide_u9_u8;
    reg [8:0] dividendo;
    reg [7:0] divisor;
    wire [8:0] quociente;
    wire [7:0] resto;
    wire divisao_por_zero;
    integer n, d, quociente_esperado, resto_esperado, contagem, contagem_validos, contagem_divisor_zero;
    reg zero_esperado;
    divisor_9_por_8 dut(.dividend(dividendo), .divisor(divisor),
        .quotient(quociente), .remainder(resto), .divide_by_zero(divisao_por_zero));
    initial begin
        contagem=0; contagem_validos=0; contagem_divisor_zero=0;
        for (n=0; n<512; n=n+1) begin
            for (d=0; d<256; d=d+1) begin
                dividendo=n[8:0]; divisor=d[7:0];
                case (d)
                    0: begin
                        quociente_esperado=0; resto_esperado=0; zero_esperado=1'b1;
                        contagem_divisor_zero=contagem_divisor_zero+1;
                    end
                    default: begin
                        quociente_esperado=n/d; resto_esperado=n%d; zero_esperado=1'b0;
                        contagem_validos=contagem_validos+1;
                    end
                endcase
                #1;
                case ((quociente === quociente_esperado[8:0]) &&
                    (resto === resto_esperado[7:0]) &&
                    (divisao_por_zero === zero_esperado))
                    1'b1: ;
                    default: $fatal(1,"divide mismatch n=%0d d=%0d q=%0d r=%0d zero=%b quociente_esperado=%0d resto_esperado=%0d zero_esperado=%b",n,d,quociente,resto,divisao_por_zero,quociente_esperado,resto_esperado,zero_esperado);
                endcase
                case (d)
                    0: ;
                    default: begin
                        case ((n == quociente*d+resto) && (resto < d))
                            1'b1: ;
                            default: $fatal(1,"divide identity n=%0d d=%0d",n,d);
                        endcase
                    end
                endcase
                contagem=contagem+1;
            end
        end
        case ((contagem==131072) && (contagem_validos==130560) && (contagem_divisor_zero==512))
            1'b1: ;
            default: $fatal(1,"Incomplete coverage contagem=%0d",contagem);
        endcase
        $display("TEST-005 PASS pairs=%0d valido=%0d divisor_zero=%0d quotient_remainder=PASS identity=PASS masks=PASS",contagem,contagem_validos,contagem_divisor_zero);
        $finish;
    end
endmodule
