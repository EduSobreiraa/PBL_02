`timescale 1ns/1ps
// Testa os sinais de erro, zero e vai-um.
module tb_status_flags;
    reg coeficientes_carregados;
    reg signed [7:0] coeficiente_a;
    reg signed [17:0] delta;
    wire OV,ERR;
    reg clock_sistema,botao0_n,botao1_n;
    reg [7:0] chaves;
    reg [1:0] selecao;
    wire signed [7:0] stored_a,stored_b,stored_c;
    wire stored_loaded,integrated_ov,integrated_err,erro_dominio;
    wire [1:0] progresso_captura;
    wire pedido_rearme_captura,evento_captura_captura;
    wire signed [17:0] stored_delta;
    wire signed [8:0] raiz_x1,raiz_x2;
    wire signed [22:0] valor_selecionado;
    integer l,av,dv,esperado,indice,verificacoes,verificacoes_integradas;
    sinaliza_overflow_erro dut(.loaded(coeficientes_carregados),.a(coeficiente_a),.delta(delta),.OV(OV),.ERR(ERR));
    entrada_coeficientes_nucleo capture(.clk(clock_sistema),.key0_n(botao0_n),.key1_n(botao1_n),.sw(chaves),.a(stored_a),.b(stored_b),.c(stored_c),.loaded(stored_loaded),.progresso(progresso_captura),.pedido_rearme(pedido_rearme_captura),.evento_captura(evento_captura_captura));
    raizes_quadraticas raizes(.a(stored_a),.b(stored_b),.c(stored_c),.delta(stored_delta),.x1(raiz_x1),.x2(raiz_x2),.domain_error(erro_dominio));
    sinaliza_overflow_erro integrated(.loaded(stored_loaded),.a(stored_a),.delta(stored_delta),.OV(integrated_ov),.ERR(integrated_err));
    seletor_resultado selector(.x(chaves),.y(23'sd0),.x1(raiz_x1),.x2(raiz_x2),.sel(selecao),.value(valor_selecionado));
    always #5 clock_sistema=~clock_sistema;
    task reset_capture;
        begin
            botao0_n=1;botao1_n=0;
            repeat(8) @(negedge clock_sistema);
            botao1_n=1;
            repeat(8) @(negedge clock_sistema);
            case({stored_loaded,integrated_ov,integrated_err})
                3'b000:;
                default:$fatal(1,"rearme did not clear ERR/coeficientes_carregados");
            endcase
            verificacoes_integradas=verificacoes_integradas+1;
        end
    endtask
    task capture_value(input [7:0] valor);
        begin
            chaves=valor;botao0_n=1;
            repeat(8) @(negedge clock_sistema);
            botao0_n=0;
            repeat(8) @(negedge clock_sistema);
            botao0_n=1;
            repeat(8) @(negedge clock_sistema);
        end
    endtask
    task hold_and_check(input erro_esperado);
        integer k;
        begin
            for(k=0;k<16;k=k+1) begin
                chaves=k*17;selecao=k[1:0];
                repeat(2) @(negedge clock_sistema);
                case((integrated_err===erro_esperado)&&(integrated_ov===1'b0)&&(stored_loaded===1'b1))
                    1'b1:;
                    default:$fatal(1,"persist k=%0d ERR=%0d",k,integrated_err);
                endcase
                verificacoes_integradas=verificacoes_integradas+1;
            end
        end
    endtask
    initial begin
        clock_sistema=0;botao0_n=1;botao1_n=0;chaves=0;selecao=0;
        coeficientes_carregados=0;coeficiente_a=0;delta=0;verificacoes=0;verificacoes_integradas=0;
        for(l=0;l<2;l=l+1) begin
            for(av=-128;av<128;av=av+1) begin
                for(indice=0;indice<7;indice=indice+1) begin
                    case(indice)
                        0:dv=-131072;1:dv=-65536;2:dv=-1;3:dv=0;
                        4:dv=1;5:dv=81408;6:dv=131071;
                    endcase
                    coeficientes_carregados=l[0];coeficiente_a=av[7:0];delta=dv[17:0];
                    esperado=(l!=0)&&((av==0)||(dv<0));#1;
                    case((ERR===esperado[0])&&(OV===1'b0))
                        1'b1:;
                        default:$fatal(1,"isolated coeficientes_carregados=%0d coeficiente_a=%0d delta=%0d",l,av,dv);
                    endcase
                    verificacoes=verificacoes+1;
                end
            end
        end
        reset_capture;
        capture_value(8'd0);
        capture_value(8'd1);
        case({stored_loaded,integrated_err})
            2'b00:;default:$fatal(1,"parcial a0 raised ERR");
        endcase
        verificacoes_integradas=verificacoes_integradas+1;
        capture_value(8'd1);
        hold_and_check(1'b1);
        reset_capture;
        capture_value(8'd1);capture_value(8'd0);capture_value(8'd1);
        hold_and_check(1'b1);
        reset_capture;
        capture_value(8'd1);capture_value(8'd0);capture_value(8'd0);
        hold_and_check(1'b0);
        reset_capture;
        case((verificacoes==3584)&&(verificacoes_integradas==53))
            1'b1:;default:$fatal(1,"incompleto verificacoes=%0d integrated=%0d",verificacoes,verificacoes_integradas);
        endcase
        $display("TEST-009 TASK010 PASS isolated=%0d integrated=%0d falhas=0",verificacoes,verificacoes_integradas);
        $finish;
    end
endmodule

// Confere a regra que acende o LED Z para resultado zero.
module tb_flag_z;
    reg signed [22:0] valor;
    reg [1:0] selecao;
    reg ERR;
    wire Z;
    integer indice_selecao,valor_erro,indice,numero,esperado,casos_verificados;
    sinaliza_zero dut(.value(valor),.sel(selecao),.ERR(ERR),.Z(Z));
    initial begin
        casos_verificados=0;
        for(indice_selecao=0;indice_selecao<4;indice_selecao=indice_selecao+1) begin
            for(valor_erro=0;valor_erro<2;valor_erro=valor_erro+1) begin
                for(indice=0;indice<30;indice=indice+1) begin
                    case(indice)
                        0:numero=0;
                        1:numero=1;
                        2:numero=-1;
                        3:numero=-4194304;
                        4:numero=4194303;
                        5:numero=1000000;
                        6:numero=-100000;
                        default:numero=1 << (indice-7);
                    endcase
                    valor=numero[22:0];selecao=indice_selecao[1:0];ERR=valor_erro[0];
                    esperado=(numero==0)&&!((selecao>=2)&&(valor_erro!=0));
                    #1;
                    case(Z===esperado[0])
                        1'b1:;
                        default:$fatal(1,"TASK018 mismatch selecao=%0d ERR=%0d valor=%0d Z=%0d",selecao,valor_erro,valor,Z);
                    endcase
                    casos_verificados=casos_verificados+1;
                end
            end
        end
        case(casos_verificados)
            240:;
            default:$fatal(1,"TASK018 incompleto coverage=%0d",casos_verificados);
        endcase
        $display("TEST-009 TASK018 PASS verificacoes=%0d falhas=0",casos_verificados);
        $finish;
    end
endmodule
// Verifica a condição que controla o LED de vai-um.
module tb_flag_c;
    reg vai_um_y,coeficientes_carregados;
    reg [1:0] selecao;
    wire C;
    reg signed [7:0] coeficiente_a,coeficiente_b,coeficiente_c,entrada_x;
    wire signed [22:0] resultado_y;
    wire OV,vai_um_nucleo,integrated_C;
    integer cy,ld,indice_selecao,cenario,verificacoes,verificacoes_integradas,esperado;
    integer valor_a,valor_b,valor_c,valor_x,parcial,resultado_y_esperado,subtotal_sem_sinal,coeficiente_c_sem_sinal,vai_um_esperado;
    sinaliza_carry dut(.carry_y(vai_um_y),.loaded(coeficientes_carregados),.sel(selecao),.C(C));
    polinomio_y_nucleo nucleo(.a(coeficiente_a),.b(coeficiente_b),.c(coeficiente_c),.x(entrada_x),.y(resultado_y),.OV(OV),.carry_y(vai_um_nucleo));
    sinaliza_carry integrated(.carry_y(vai_um_nucleo),.loaded(coeficientes_carregados),.sel(selecao),.C(integrated_C));
    initial begin
        coeficiente_a=0;coeficiente_b=0;coeficiente_c=0;entrada_x=0;verificacoes=0;verificacoes_integradas=0;
        for(cy=0;cy<2;cy=cy+1) begin
            for(ld=0;ld<2;ld=ld+1) begin
                for(indice_selecao=0;indice_selecao<4;indice_selecao=indice_selecao+1) begin
                    vai_um_y=cy[0];coeficientes_carregados=ld[0];selecao=indice_selecao[1:0];
                    esperado=(cy!=0)&&(ld!=0)&&(selecao==1);#1;
                    case(C===esperado[0])
                        1'b1:;default:$fatal(1,"TASK019 isolated cy=%0d ld=%0d selecao=%0d",cy,ld,selecao);
                    endcase
                    verificacoes=verificacoes+1;
                end
            end
        end
        for(cenario=0;cenario<8;cenario=cenario+1) begin
            case(cenario)
                0:begin valor_a=0;valor_b=-1;valor_c=1;valor_x=1;end
                1:begin valor_a=1;valor_b=-1;valor_c=0;valor_x=1;end
                2:begin valor_a=0;valor_b=1;valor_c=1;valor_x=1;end
                3:begin valor_a=0;valor_b=-1;valor_c=-1;valor_x=1;end
                4:begin valor_a=0;valor_b=0;valor_c=-128;valor_x=0;end
                5:begin valor_a=-128;valor_b=127;valor_c=-128;valor_x=-128;end
                6:begin valor_a=127;valor_b=-128;valor_c=127;valor_x=-128;end
                7:begin valor_a=-128;valor_b=-128;valor_c=127;valor_x=127;end
            endcase
            coeficiente_a=valor_a[7:0];coeficiente_b=valor_b[7:0];coeficiente_c=valor_c[7:0];entrada_x=valor_x[7:0];
            parcial=valor_a*valor_x*valor_x+valor_b*valor_x;
            resultado_y_esperado=parcial+valor_c;
            subtotal_sem_sinal=parcial & 8388607;
            coeficiente_c_sem_sinal=valor_c & 8388607;
            vai_um_esperado=(subtotal_sem_sinal+coeficiente_c_sem_sinal)>>23;
            for(ld=0;ld<2;ld=ld+1) begin
                for(selecao=0;selecao<4;selecao=selecao+1) begin
                    coeficientes_carregados=ld[0];selecao=selecao[1:0];
                    esperado=(vai_um_esperado!=0)&&(ld!=0)&&(selecao==1);#1;
                    case((integrated_C===esperado[0])&&(vai_um_nucleo===vai_um_esperado[0])&&
                         ($signed(resultado_y)===resultado_y_esperado)&&(OV===1'b0))
                        1'b1:;default:$fatal(1,"TASK019 integrated cenario=%0d ld=%0d selecao=%0d vai_um=%0d expectedcarry=%0d",cenario,ld,selecao,vai_um_nucleo,vai_um_esperado);
                    endcase
                    verificacoes_integradas=verificacoes_integradas+1;
                end
            end
        end
        case((verificacoes==16)&&(verificacoes_integradas==64))
            1'b1:;default:$fatal(1,"TASK019 incompleto coverage");
        endcase
        $display("TEST-009 TASK019 PASS isolated=%0d integrated=%0d falhas=0",verificacoes,verificacoes_integradas);
        $finish;
    end
endmodule
