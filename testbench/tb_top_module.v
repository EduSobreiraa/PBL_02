`timescale 1ns/1ps
module tb_top_module;
    reg clock_sistema;
    reg [1:0] KEY;
    reg [9:0] SW;
    wire [9:0] LEDR;
    wire [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
    integer ma,mb,mc,progresso,verificacoes,cenarios,prompt_verificacoes;
    modulo_principal dut(.MAX10_CLK1_50(clock_sistema),.KEY(KEY),.SW(SW),.LEDR(LEDR),
        .HEX0(HEX0),.HEX1(HEX1),.HEX2(HEX2),.HEX3(HEX3),.HEX4(HEX4),.HEX5(HEX5));
    initial begin clock_sistema=0; forever #10 clock_sistema=~clock_sistema; end
    function integer arredondamento_referencia;
        input integer valor_a,valor_b,discriminante,ramo;
        integer limite_inferior,limite_superior,k,h,limite,quadrado,cmp,relacao,asign,concluido;
        begin
            limite_inferior=-129; limite_superior=129; concluido=0;
            case (valor_a>0) 1: asign=1; default: asign=-1; endcase
            while ((limite_inferior<limite_superior) && (concluido==0)) begin
                k=limite_inferior+(limite_superior-limite_inferior)/2;
                h=valor_b+valor_a*(2*k+1);
                limite=ramo*h;
                case (limite<0)
                    1: cmp=1;
                    default: begin
                        quadrado=limite*limite;
                        cmp=(discriminante>quadrado)-(discriminante<quadrado);
                    end
                endcase
                relacao=asign*ramo*cmp;
                case (relacao)
                    0: begin
                        case (k>=0) 1: arredondamento_referencia=k+1; default: arredondamento_referencia=k; endcase
                        concluido=1;
                    end
                    -1: limite_superior=k;
                    1: limite_inferior=k+1;
                    default: $fatal(1,"Invalid oracle relacao");
                endcase
            end
            case (concluido) 0: arredondamento_referencia=limite_inferior; default: ; endcase
        end
    endfunction
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

    function [6:0] codificar_prompt;
        input integer caractere;
        begin
            case(caractere)
                0:codificar_prompt=7'b1111001;
                1:codificar_prompt=7'b0101011;
                2:codificar_prompt=7'b0010010;
                3:codificar_prompt=7'b1111001;
                4:codificar_prompt=7'b0101111;
                5:codificar_prompt=7'b0100011;
                6:codificar_prompt=7'b1111111;
                7:codificar_prompt=7'b0100011;
                8:codificar_prompt=7'b0000011;
                9:codificar_prompt=7'b1000110;
                default:codificar_prompt=7'b1111111;
            endcase
        end
    endfunction

    task wait_clocks;
        input integer ciclos;
        integer k;
        begin
            for(k=0;k<ciclos;k=k+1) @(posedge clock_sistema);
            #1;
        end
    endtask
    task observe;
        input integer valor_x;
        integer selecao,discriminante,raiz_um,raiz_dois,valor_y,subtotal,selecionado,vai_um_sem_sinal;
        integer modulo_sinalizado,restante,posicao,valor_digito;
        reg erro,sinal_zero,sinal_carry,mascarado,fora_da_faixa;
        reg [9:0] leds_esperados;
        reg [41:0] hex_esperado;
        begin
            discriminante=mb*mb-4*ma*mc;
            case ((ma==0)||(discriminante<0))
                1: begin raiz_um=0; raiz_dois=0; end
                default: begin
                    raiz_um=arredondamento_referencia(ma,mb,discriminante,1);
                    raiz_dois=arredondamento_referencia(ma,mb,discriminante,-1);
                end
            endcase
            subtotal=ma*valor_x*valor_x+mb*valor_x;
            valor_y=subtotal+mc;
            vai_um_sem_sinal=((subtotal & 8388607)+(mc & 8388607))>>23;
            erro=(progresso==3)&&((ma==0)||(discriminante<0));
            for(selecao=0;selecao<4;selecao=selecao+1) begin
                @(negedge clock_sistema); SW={selecao[1:0],valor_x[7:0]};
                #2;
                case(selecao)
                    0: selecionado=valor_x;
                    1: selecionado=valor_y;
                    2: selecionado=raiz_um;
                    3: selecionado=raiz_dois;
                endcase
                sinal_zero=(selecionado==0)&&!((selecao>=2)&&erro);
                sinal_carry=(selecao==1)&&(progresso==3)&&(vai_um_sem_sinal==1);
                leds_esperados={6'b0,erro,sinal_carry,sinal_zero,(progresso==3)&&(selecao==1)&&((valor_y>999999)||(valor_y< -99999))};
                mascarado=((selecao!=0)&&(progresso!=3))||((selecao>=2)&&erro);
                fora_da_faixa=mascarado||(selecionado>999999)||(selecionado< -99999);
                hex_esperado={6{7'b1111111}};
                hex_esperado={6{7'b1111111}};
                case(progresso==3)
                    1: begin
                        case(fora_da_faixa)
                            1: hex_esperado={6{7'b0111111}};
                            default: begin
                                case(selecionado<0) 1:modulo_sinalizado=-selecionado; default:modulo_sinalizado=selecionado; endcase
                                restante=modulo_sinalizado;
                                for(posicao=0;posicao<6;posicao=posicao+1) begin
                                    valor_digito=restante%10;
                                    case((posicao==0)||(restante!=0))
                                        1:hex_esperado[posicao*7+:7]=codificar(valor_digito);
                                        default:;
                                    endcase
                                    restante=restante/10;
                                end
                                case(selecionado<0) 1:hex_esperado[35+:7]=7'b0111111; default:; endcase
                            end
                        endcase
                    end
                    default: begin
                        hex_esperado={7'b1111001,7'b0101011,7'b0010010,7'b1111001,7'b0101111,7'b0100011};
                    end
                endcase
                case((LEDR===leds_esperados)&&({HEX5,HEX4,HEX3,HEX2,HEX1,HEX0}===hex_esperado))
                    1:;
                    default:$fatal(1,"top check=%0d coeficiente_a=%0d coeficiente_b=%0d coeficiente_c=%0d progresso=%0d entrada_x=%0d selecao=%0d LEDs=%b esperado=%b HEX0=%b HEX1=%b HEX2=%b HEX3=%b HEX4=%b HEX5=%b esperado=%h",verificacoes,ma,mb,mc,progresso,valor_x,selecao,LEDR,leds_esperados,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,hex_esperado);
                endcase
                verificacoes=verificacoes+1;
            end
        end
    endtask
    task reset_system;
        begin
            @(negedge clock_sistema); KEY=2'b00;
            wait_clocks(8);
            ma=0;mb=0;mc=0;progresso=0;
            observe(0);
            @(negedge clock_sistema); KEY=2'b11;
            wait_clocks(8);
            observe(-128);
        end
    endtask
    task capture;
        input integer coeficiente;
        begin
            @(negedge clock_sistema); SW={2'b00,coeficiente[7:0]}; KEY[0]=0;
            wait_clocks(8);
            case(progresso)
                0:begin ma=coeficiente; progresso=1;end
                1:begin mb=coeficiente; progresso=2;end
                2:begin mc=coeficiente; progresso=3;end
                default:;
            endcase
            // Switch changes and all selections while KEY0 remains pressed.
            observe(99);
            wait_clocks(5);
            @(negedge clock_sistema); KEY[0]=1;
            wait_clocks(6);
            observe(0);
        end
    endtask

    task verify_prompt_frames;
        input integer etapa;
        integer quadro,digito,indice_anel,caractere;
        reg [41:0] esperado;
        begin
            for(quadro=0;quadro<15;quadro=quadro+1) begin
                esperado={6{7'b1111111}};
                for(digito=0;digito<6;digito=digito+1) begin
                    indice_anel=(quadro+digito)%14;
                    case(indice_anel)
                        0:caractere=0;
                        1:caractere=1;
                        2:caractere=2;
                        3:caractere=3;
                        4:caractere=4;
                        5:caractere=5;
                        6:caractere=6;
                        7:begin
                            case(etapa)
                                0:caractere=7;
                                1:caractere=8;
                                2:caractere=9;
                                default:caractere=6;
                            endcase
                        end
                        default:caractere=6;
                    endcase
                    esperado[(5-digito)*7+:7]=codificar_prompt(caractere);
                end
                #1;
                case({HEX5,HEX4,HEX3,HEX2,HEX1,HEX0}===esperado)
                    1:;
                    default:$fatal(1,"prompt etapa=%0d p=%0d esperado=%h recebido=%h",etapa,(quadro%14),esperado,{HEX5,HEX4,HEX3,HEX2,HEX1,HEX0});
                endcase
                prompt_verificacoes=prompt_verificacoes+1;
                case(quadro<14)
                    1:begin
                        advance_prompt_frame;
                    end
                    default:;
                endcase
            end
        end
    endtask

    task advance_prompt_frame;
        begin
            force dut.prompt.rolagem.contador_divisao=24'hbebc1f;
            @(posedge clock_sistema); #1;
            release dut.prompt.rolagem.contador_divisao;
            #1;
        end
    endtask

    task capture_from_mid_animation;
        input integer coeficiente;
        integer indice;
        begin
            advance_prompt_frame;
            wait_clocks(9);
            case((dut.prompt.rolagem.posicao===4'd1)&&(dut.prompt.rolagem.contador_divisao===24'd9))
                1:;
                default:$fatal(1,"capture setup did not reach intermediate frame/divisor");
            endcase
            @(negedge clock_sistema);SW={2'b00,coeficiente[7:0]};KEY[0]=0;
            repeat(2) @(posedge clock_sistema);
            #1;
            case(dut.evento_captura_animacao===1'b1)
                1:;
                default:$fatal(1,"valid capture event was not asserted");
            endcase
            @(posedge clock_sistema);#1;
            case((dut.prompt.rolagem.posicao===4'd0)&&(dut.prompt.rolagem.contador_divisao===24'd0)&&
                 (dut.progresso_coeficientes===2'b01)&&(dut.coeficientes_carregados===1'b0))
                1:;
                default:$fatal(1,"capture did not restart animation and advance to coefficient b");
            endcase
            ma=coeficiente;progresso=1;
            @(negedge clock_sistema);KEY[0]=1;
            wait_clocks(6);
            observe(0);
            advance_prompt_frame;
            advance_prompt_frame;
            case((dut.prompt.rolagem.posicao===4'd2)&&(HEX0===7'b0000011))
                1:;
                default:$fatal(1,"new b suffix was not displayed after capture restart");
            endcase
            for(indice=0;indice<12;indice=indice+1) advance_prompt_frame;
            case(dut.prompt.rolagem.posicao===4'd0)
                1:;
                default:$fatal(1,"animation did not wrap back to p=0 after suffix check");
            endcase
        end
    endtask

    task verify_reset_priority;
        begin
            @(negedge clock_sistema);
            KEY=2'b00;
            force dut.prompt.rolagem.contador_divisao=24'hbebc1f;
            wait_clocks(8);
            release dut.prompt.rolagem.contador_divisao;
            case((dut.prompt.rolagem.posicao===4'd0)&&(dut.prompt.rolagem.contador_divisao===24'd0)&&
                 (dut.progresso_coeficientes===2'b00)&&(dut.evento_captura_animacao===1'b0))
                1:;
                default:$fatal(1,"synchronized reset did not dominate animation tick/capture");
            endcase
            @(negedge clock_sistema);KEY=2'b11;
            wait_clocks(8);
        end
    endtask

    task cenario;
        input integer valor_a,valor_b,valor_c;
        begin
            reset_system;
            capture(valor_a);capture(valor_b);capture(valor_c);
            observe(-128);observe(-1);observe(1);observe(127);
            capture(42); // fourth capture must be ignored
            observe(-3);
            cenarios=cenarios+1;
        end
    endtask
    initial begin
        KEY=2'b00;SW=0;ma=0;mb=0;mc=0;progresso=0;verificacoes=0;cenarios=0;prompt_verificacoes=0;
        reset_system;
        verify_prompt_frames(0);
        capture_from_mid_animation(1);
        verify_prompt_frames(1);
        capture(-3);
        verify_prompt_frames(2);
        verify_reset_priority;
        reset_system;
        cenario(1,-3,2);  // positive integer raizes
        cenario(1,3,2);   // negativo integer raizes
        cenario(2,-3,1);  // positive half tie
        cenario(2,3,1);   // negativo half tie
        cenario(-1,0,1);  // reversed ramo order, final vai_um -1+1
        cenario(1,0,1);   // negativo discriminant
        cenario(0,1,0);   // coeficiente_a zero
        cenario(1,2,1);   // zero discriminant
        cenario(-128,127,-128); // minimum resultado_y and visual overflow
        cenario(127,-128,127);  // maximum resultado_y and visual overflow
        reset_system;capture(17); // rearme during parcial load
        reset_system;capture(18);capture(52);capture(86);
        observe(127);
        reset_system;
        case((cenarios==10)&&(verificacoes==660))
            1:;
            default:$fatal(1,"Coverage mismatch cenarios=%0d verificacoes=%0d",cenarios,verificacoes);
        endcase
        case(prompt_verificacoes==45)
            1:;
            default:$fatal(1,"prompt frame coverage mismatch=%0d",prompt_verificacoes);
        endcase
        $display("TEST-010/011 PASS cenarios=%0d output_checks=%0d prompt_frames=%0d reset_partial_full=PASS held_key=PASS extra_capture=PASS flags_displays=PASS",cenarios,verificacoes,prompt_verificacoes);
        $finish;
    end
endmodule

module tb_prompt_divider_nominal;
    reg clock_sistema;
    reg pedido_rearme,evento_captura;
    wire [3:0] posicao;
    contador_rolagem_prompt dut(.clk(clock_sistema),.pedido_rearme(pedido_rearme),.evento_captura(evento_captura),.posicao(posicao));
    initial begin clock_sistema=0; forever #10 clock_sistema=~clock_sistema; end
    initial begin
        pedido_rearme=1;evento_captura=0;
        repeat(3) @(posedge clock_sistema);
        #1;
        case((posicao===4'd0)&&(dut.contador_divisao===24'd0))
            1:;
            default:$fatal(1,"prompt reset failed pos=%0d count=%0d",posicao,dut.contador_divisao);
        endcase
        @(negedge clock_sistema);pedido_rearme=0;
        repeat(12499999) @(posedge clock_sistema);
        #1;
        case((posicao===4'd0)&&(dut.contador_divisao===24'd12499999))
            1:;
            default:$fatal(1,"prompt advanced before 12500000 cycles pos=%0d count=%0d",posicao,dut.contador_divisao);
        endcase
        @(posedge clock_sistema);#1;
        case((posicao===4'd1)&&(dut.contador_divisao===24'd0))
            1:;
            default:$fatal(1,"prompt did not advance on cycle 12500000 pos=%0d count=%0d",posicao,dut.contador_divisao);
        endcase
        $display("TASK-024 nominal divider PASS cycles=12500000");
        $finish;
    end
endmodule
