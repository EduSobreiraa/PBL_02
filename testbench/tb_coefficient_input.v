`timescale 1ns/1ps
// Verifica a captura dos coeficientes pelos botões e o reinício do circuito.
module tb_coefficient_input;
    reg clock_sistema;
    reg botao0_n;
    reg botao1_n;
    reg [7:0] chaves;
    wire signed [7:0] coeficiente_a;
    wire signed [7:0] coeficiente_b;
    wire signed [7:0] coeficiente_c;

    wire signed [7:0] coeficiente_a_nucleo;
    wire signed [7:0] coeficiente_b_nucleo;
    wire signed [7:0] coeficiente_c_nucleo;
    wire coeficientes_carregados;
    wire [1:0] progresso;
    wire pedido_rearme_nucleo,event_capture_nucleo;
    integer verificacoes = 0;
    integer capturas_observadas = 0;

    entrada_coeficientes_nucleo dut_nucleo (
        .clk(clock_sistema), .key0_n(botao0_n), .key1_n(botao1_n), .sw(chaves),
        .a(coeficiente_a_nucleo), .b(coeficiente_b_nucleo), .c(coeficiente_c_nucleo), .loaded(coeficientes_carregados), .progresso(progresso),
        .pedido_rearme(pedido_rearme_nucleo), .evento_captura(event_capture_nucleo)
    );

    entrada_coeficientes dut (
        .clk(clock_sistema),
        .key0_n(botao0_n),
        .key1_n(botao1_n),
        .sw(chaves),
        .a(coeficiente_a),
        .b(coeficiente_b),
        .c(coeficiente_c)
    );

    initial begin
        clock_sistema = 1'b0;
        forever #10 clock_sistema = ~clock_sistema;
    end

    always @(posedge clock_sistema) begin
        case(event_capture_nucleo)
            1'b1:capturas_observadas=capturas_observadas+1;
            default:;
        endcase
    end

    task wait_clocks;
        input integer contagem;
        integer indice;
        begin
            for (indice = 0; indice < contagem; indice = indice + 1)
                @(posedge clock_sistema);
            #1;
        end
    endtask

    task check_values;
        input [7:0] a_esperado;
        input [7:0] b_esperado;
        input [7:0] c_esperado;
        input carregado_esperado;
        input [1:0] progresso_esperado;
        input [511:0] label;
        begin
            verificacoes = verificacoes + 1;
            case ({(coeficiente_a !== a_esperado), (coeficiente_b !== b_esperado), (coeficiente_c !== c_esperado),
                   (coeficiente_a_nucleo !== coeficiente_a), (coeficiente_b_nucleo !== coeficiente_b), (coeficiente_c_nucleo !== coeficiente_c),
                   (coeficientes_carregados !== carregado_esperado), (progresso !== progresso_esperado)})
                8'b00000000: begin
                end
                default: begin
                    $display("FAIL %0s: coeficiente_a=%h coeficiente_b=%h coeficiente_c=%h esperado=%h %h %h",
                             label, coeficiente_a, coeficiente_b, coeficiente_c, a_esperado, b_esperado, c_esperado);
                    $display("nucleo=%h %h %h coeficientes_carregados=%b carregado_esperado=%b",
                             coeficiente_a_nucleo, coeficiente_b_nucleo, coeficiente_c_nucleo, coeficientes_carregados, carregado_esperado);
                    $fatal(1);
                end
            endcase
        end
    endtask

    task press_key0;
        input [7:0] valor;
        input integer ciclos_espera;
        begin
            @(negedge clock_sistema);
            chaves = valor;
            botao0_n = 1'b0;
            wait_clocks(ciclos_espera);
            @(negedge clock_sistema);
            botao0_n = 1'b1;
            wait_clocks(5);
        end
    endtask

    task press_key1;
        input integer ciclos_espera;
        begin
            @(negedge clock_sistema);
            botao1_n = 1'b0;
            wait_clocks(ciclos_espera);
            @(negedge clock_sistema);
            botao1_n = 1'b1;
            wait_clocks(6);
        end
    endtask

    initial begin
        botao0_n = 1'b0;
        botao1_n = 1'b0;
        chaves = 8'h55;
        wait_clocks(8);
        check_values(8'h00, 8'h00, 8'h00, 1'b0, 2'b00, "rearme suppresses simultaneous capture");

        @(negedge clock_sistema);
        botao0_n = 1'b1;
        botao1_n = 1'b1;
        wait_clocks(8);
        check_values(8'h00, 8'h00, 8'h00, 1'b0, 2'b00, "release after rearme has no spurious capture");

        press_key0(8'h80, 8);
        check_values(8'h80, 8'h00, 8'h00, 1'b0, 2'b01, "long first press captures once, not coeficientes_carregados");
        press_key0(8'h01, 5);
        check_values(8'h80, 8'h01, 8'h00, 1'b0, 2'b10, "second capture, not coeficientes_carregados");
        press_key0(8'h7F, 5);
        check_values(8'h80, 8'h01, 8'h7F, 1'b1, 2'b11, "three ordered captures");
        case(capturas_observadas==3)
            1:;
            default:$fatal(1,"valid capture pulse count=%0d",capturas_observadas);
        endcase

        @(negedge clock_sistema);
        chaves = 8'h44;
        wait_clocks(5);
        check_values(8'h80, 8'h01, 8'h7F, 1'b1, 2'b11, "switch changes without capture");

        press_key0(8'h2A, 8);
        check_values(8'h80, 8'h01, 8'h7F, 1'b1, 2'b11, "long press and fourth capture ignored");
        press_key0(8'hD6, 5);
        check_values(8'h80, 8'h01, 8'h7F, 1'b1, 2'b11, "later captures ignored until rearme");
        case(capturas_observadas==3)
            1:;
            default:$fatal(1,"capture pulse emitted after loaded=%0d",capturas_observadas);
        endcase

        press_key1(6);
        check_values(8'h00, 8'h00, 8'h00, 1'b0, 2'b00, "rearme after completed load");

        press_key0(8'h11, 5);
        check_values(8'h11, 8'h00, 8'h00, 1'b0, 2'b01, "parcial load before rearme");
        press_key1(6);
        check_values(8'h00, 8'h00, 8'h00, 1'b0, 2'b00, "rearme clears parcial progresso");

        press_key0(8'h12, 5);
        press_key0(8'h34, 5);
        press_key0(8'h56, 5);
        check_values(8'h12, 8'h34, 8'h56, 1'b1, 2'b11, "new ordered load after rearme");

        @(negedge clock_sistema);
        botao0_n = 1'b0;
        botao1_n = 1'b0;
        chaves = 8'hAA;
        wait_clocks(8);
        check_values(8'h00, 8'h00, 8'h00, 1'b0, 2'b00, "rearme has priority during key0 press");
        @(negedge clock_sistema);
        botao0_n = 1'b1;
        botao1_n = 1'b1;
        wait_clocks(8);
        check_values(8'h00, 8'h00, 8'h00, 1'b0, 2'b00, "simultaneous release has no capture");
        press_key0(8'hFF, 8);
        check_values(8'hFF, 8'h00, 8'h00, 1'b0, 2'b01, "capture resumes after priority rearme");

        $display("PASS TEST-001 entrada_coeficientes wrapper/nucleo coeficientes_carregados verificacoes=%0d", verificacoes);
        $finish;
    end
endmodule
