`timescale 1ns/1ps
module tb_quadratic_roots;
    reg signed [7:0] coeficiente_a,coeficiente_b,coeficiente_c;
    wire signed [17:0] delta;
    wire signed [8:0] raiz_x1,raiz_x2;
    wire erro_dominio;
    integer contagem,contagem_validos,contagem_invalidos,semente,n,valor_aleatorio;
    raizes_quadraticas dut(.a(coeficiente_a),.b(coeficiente_b),.c(coeficiente_c),.delta(delta),.x1(raiz_x1),.x2(raiz_x2),.domain_error(erro_dominio));
    // Independent oracle: exact integer comparisons with half-integer boundaries.
    // Does not compute S, E, Q, resto, or the DUT arredondamento expression.
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
    task check;
        input integer valor_a,valor_b,valor_c;
        integer ed,ex1,ex2;
        reg invalido;
        begin
            ed=valor_b*valor_b-4*valor_a*valor_c;
            invalido=(valor_a==0)||(ed<0);
            case (invalido)
                1: begin ex1=0; ex2=0; contagem_invalidos=contagem_invalidos+1; end
                0: begin
                    ex1=arredondamento_referencia(valor_a,valor_b,ed,1);
                    ex2=arredondamento_referencia(valor_a,valor_b,ed,-1);
                    contagem_validos=contagem_validos+1;
                end
            endcase
            coeficiente_a=valor_a[7:0]; coeficiente_b=valor_b[7:0]; coeficiente_c=valor_c[7:0];
            #1;
            case (($signed(delta)===ed) && ($signed(raiz_x1)===ex1) && ($signed(raiz_x2)===ex2) && (erro_dominio===invalido))
                1: ;
                default: $fatal(1,"raizes coeficiente_a=%0d coeficiente_b=%0d coeficiente_c=%0d delta=%0d raiz_x1=%0d raiz_x2=%0d erro=%b esperado=%0d,%0d,%0d,%b",valor_a,valor_b,valor_c,delta,raiz_x1,raiz_x2,erro_dominio,ed,ex1,ex2,invalido);
            endcase
            contagem=contagem+1;
        end
    endtask
    integer aleatorio_a,aleatorio_b,aleatorio_c;
    initial begin
        contagem=0; contagem_validos=0; contagem_invalidos=0; semente=20261011;
        // TASK-005: coeficiente_a_zero
        check(0,-128,127);
        // TASK-005: negative_discriminant
        check(1,0,1);
        // TASK-005: zero_discriminant
        check(1,2,1);
        // TASK-005: positive_half_tie
        check(2,-3,1);
        // TASK-005: negative_half_tie
        check(2,3,1);
        // TASK-005: negative_a_branch_order
        check(-1,0,1);
        // TASK-005: zero_root_and_positive_128
        check(1,-128,0);
        // TASK-005: minimum_coefficients
        check(-128,-128,-128);
        // TASK-005: maximum_discriminant
        check(-128,-128,127);
        // TASK-005: minimum_discriminant
        check(-128,0,-128);
        // TASK-005: maximum_coefficients
        check(127,127,127);
        // TASK-005: sqrt_perfect
        check(1,0,-4);
        // TASK-005: sqrt_nonperfect
        check(1,0,-2);
        // TASK-005: mixed_sign_roots
        check(1,1,-1);
        // TASK-005: branch_plus_r0_perfect_positive_correction_odd_quotient
        check(-128,-128,-32);
        // TASK-005: branch_minus_r0_perfect_nonpositive_correction_odd_quotient
        check(-128,-128,-32);
        // TASK-005: branch_plus_r0_perfect_positive_correction_even_quotient
        check(-128,-128,0);
        // TASK-005: branch_minus_r0_perfect_nonpositive_correction_even_quotient
        check(-128,-128,0);
        // TASK-005: branch_minus_r0_perfect_positive_correction_odd_quotient
        check(-128,-128,96);
        // TASK-005: branch_plus_r0_irrational_positive_correction_odd_quotient
        check(-128,-128,97);
        // TASK-005: branch_minus_r0_irrational_positive_correction_odd_quotient
        check(-128,-128,97);
        // TASK-005: branch_plus_r0_perfect_nonpositive_correction_even_quotient
        check(-128,0,0);
        // TASK-005: branch_minus_r0_perfect_positive_correction_even_quotient
        check(-128,1,127);
        // TASK-005: branch_plus_r0_irrational_positive_correction_even_quotient
        check(-126,0,127);
        // TASK-005: branch_minus_r0_irrational_positive_correction_even_quotient
        check(-126,0,127);
        // TASK-005: branch_plus_r0_perfect_nonpositive_correction_odd_quotient
        check(-126,127,-32);
        // TASK-005: branch_minus_r0_irrational_nonpositive_correction_odd_quotient
        check(-83,-128,-43);
        // TASK-005: branch_plus_r0_irrational_nonpositive_correction_odd_quotient
        check(-83,126,-42);
        // TASK-005: branch_minus_r0_irrational_nonpositive_correction_even_quotient
        check(-64,-128,1);
        // TASK-005: branch_plus_r0_irrational_nonpositive_correction_even_quotient
        check(-63,126,1);
        for (n=0;n<10000;n=n+1) begin
            valor_aleatorio=$random(semente); aleatorio_a=$signed(valor_aleatorio[7:0]);
            valor_aleatorio=$random(semente); aleatorio_b=$signed(valor_aleatorio[7:0]);
            valor_aleatorio=$random(semente); aleatorio_c=$signed(valor_aleatorio[7:0]);
            check(aleatorio_a,aleatorio_b,aleatorio_c);
        end
        case ((contagem==10030) && (contagem_validos+contagem_invalidos==10030))
            1: ;
            default: $fatal(1,"Incomplete raizes test");
        endcase
        $display("TEST-007 PASS dirigidos=30 aleatorio=10000 semente=20261011 total=%0d valido=%0d invalido=%0d delta_roots_error=PASS",contagem,contagem_validos,contagem_invalidos);
        $finish;
    end
endmodule
