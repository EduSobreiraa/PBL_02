`timescale 1ns/1ps
// Confere qual entrada aparece para cada valor de seleção.
module tb_result_select;
    reg signed [7:0] entrada_x;
    reg signed [22:0] resultado_y;
    reg signed [8:0] raiz_x1,raiz_x2;
    reg [1:0] selecao;
    wire signed [22:0] valor;
    integer i,j,semente,esperado,contagem,valor_aleatorio;
    seletor_resultado dut(.x(entrada_x),.y(resultado_y),.x1(raiz_x1),.x2(raiz_x2),.sel(selecao),.value(valor));
    task check_selections;
        begin
            for (j=0;j<4;j=j+1) begin
                selecao=j[1:0];
                case (j)
                    0: esperado=$signed(entrada_x);
                    1: esperado=$signed(resultado_y);
                    2: esperado=$signed(raiz_x1);
                    3: esperado=$signed(raiz_x2);
                endcase
                #1;
                case ($signed(valor)===esperado)
                    1: ;
                    default: $fatal(1,"select selecao=%d got=%d esperado=%d",j,valor,esperado);
                endcase
                contagem=contagem+1;
            end
        end
    endtask
    initial begin
        contagem=0; semente=20261011;
        for (i=0;i<512;i=i+1) begin
            entrada_x=i[7:0]; raiz_x1=i[8:0]; raiz_x2=~i[8:0];
            case (i[0]) 0: resultado_y=-4194304; 1: resultado_y=4194303; endcase
            check_selections;
        end
        for (i=0;i<1000;i=i+1) begin
            valor_aleatorio=$random(semente); entrada_x=valor_aleatorio[7:0];
            valor_aleatorio=$random(semente); resultado_y=valor_aleatorio[22:0];
            valor_aleatorio=$random(semente); raiz_x1=valor_aleatorio[8:0];
            valor_aleatorio=$random(semente); raiz_x2=valor_aleatorio[8:0];
            check_selections;
        end
        case (contagem) 6048: ; default: $fatal(1,"Incomplete select test"); endcase
        $display("TEST-008 SELECT PASS cases=%0d semente=20261011",contagem);
        $finish;
    end
endmodule
