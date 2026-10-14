`timescale 1ns/1ps

module entrada_coeficientes (
    input wire clk,
    input wire key0_n,
    input wire key1_n,
    input wire [7:0] sw,
    output wire signed [7:0] a,
    output wire signed [7:0] b,
    output wire signed [7:0] c
);
    wire coeficientes_carregados_nao_utilizado;
    wire [1:0] progresso_nao_utilizado;
    wire pedido_rearme_nao_utilizado, evento_captura_nao_utilizado;

    entrada_coeficientes_nucleo nucleo (
        .clk(clk), .key0_n(key0_n), .key1_n(key1_n), .sw(sw),
        .a(a), .b(b), .c(c), .loaded(coeficientes_carregados_nao_utilizado), .progresso(progresso_nao_utilizado),
        .pedido_rearme(pedido_rearme_nao_utilizado), .evento_captura(evento_captura_nao_utilizado)
    );
endmodule

// Private integration contract, DEC-030. No additional storage.
module entrada_coeficientes_nucleo (
    input wire clk,
    input wire key0_n,
    input wire key1_n,
    input wire [7:0] sw,
    output wire signed [7:0] a,
    output wire signed [7:0] b,
    output wire signed [7:0] c,
    output wire loaded,
    output wire [1:0] progresso,
    output wire pedido_rearme,
    output wire evento_captura
);
    wire botao1_meta;
    wire botao1_sincronizado;
    wire botao0_meta;
    wire botao0_sincronizado;
    wire botao0_anterior;
    wire evento_pressao_botao0;
    wire botao0_liberado_sincronizado;
    wire nao_concluido;
    wire progresso_bit0_proximo;
    wire progresso_bit1_proximo;
    wire nao_progresso_bit0;
    wire nao_progresso_bit1;
    wire seleciona_a;
    wire seleciona_b;
    wire seleciona_c;
    wire habilita_a;
    wire habilita_b;
    wire habilita_c;

    flipflop_simples key1_sync_stage_1 (
        .clk(clk), .d(key1_n), .q(botao1_meta)
    );

    flipflop_simples key1_sync_stage_2 (
        .clk(clk), .d(botao1_meta), .q(botao1_sincronizado)
    );

    flipflop_reset_sincrono key0_sync_stage_1 (
        .clk(clk), .reset(pedido_rearme), .reset_value(1'b1), .enable(1'b1),
        .d(key0_n), .q(botao0_meta)
    );

    flipflop_reset_sincrono key0_sync_stage_2 (
        .clk(clk), .reset(pedido_rearme), .reset_value(1'b1), .enable(1'b1),
        .d(botao0_meta), .q(botao0_sincronizado)
    );

    flipflop_reset_sincrono key0_history (
        .clk(clk), .reset(pedido_rearme), .reset_value(1'b1), .enable(1'b1),
        .d(botao0_sincronizado), .q(botao0_anterior)
    );

    not reset_from_key1 (pedido_rearme, botao1_sincronizado);
    not invert_key0_sync (botao0_liberado_sincronizado, botao0_sincronizado);
    and detected_key0_press (evento_pressao_botao0, botao0_anterior, botao0_liberado_sincronizado);
    not invert_progress_done (nao_concluido, loaded);
    and decode_progress_done (loaded, progresso[0], progresso[1]);
    and allowed_capture (evento_captura, evento_pressao_botao0, nao_concluido, botao1_sincronizado);

    not invert_progress_0 (nao_progresso_bit0, progresso[0]);
    not invert_progress_1 (nao_progresso_bit1, progresso[1]);
    and decode_a (seleciona_a, nao_progresso_bit1, nao_progresso_bit0);
    and decode_b (seleciona_b, nao_progresso_bit1, progresso[0]);
    and decode_c (seleciona_c, progresso[1], nao_progresso_bit0);

    and write_a (habilita_a, evento_captura, seleciona_a);
    and write_b (habilita_b, evento_captura, seleciona_b);
    and write_c (habilita_c, evento_captura, seleciona_c);

    not progress_bit_0_toggle (progresso_bit0_proximo, progresso[0]);
    xor progress_bit_1_toggle (progresso_bit1_proximo, progresso[1], progresso[0]);

    flipflop_reset_sincrono progress_counter_bit_0 (
        .clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(evento_captura),
        .d(progresso_bit0_proximo), .q(progresso[0])
    );

    flipflop_reset_sincrono progress_counter_bit_1 (
        .clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(evento_captura),
        .d(progresso_bit1_proximo), .q(progresso[1])
    );

    flipflop_reset_sincrono coefficient_a_bit_0 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_a), .d(sw[0]), .q(a[0]));
    flipflop_reset_sincrono coefficient_a_bit_1 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_a), .d(sw[1]), .q(a[1]));
    flipflop_reset_sincrono coefficient_a_bit_2 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_a), .d(sw[2]), .q(a[2]));
    flipflop_reset_sincrono coefficient_a_bit_3 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_a), .d(sw[3]), .q(a[3]));
    flipflop_reset_sincrono coefficient_a_bit_4 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_a), .d(sw[4]), .q(a[4]));
    flipflop_reset_sincrono coefficient_a_bit_5 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_a), .d(sw[5]), .q(a[5]));
    flipflop_reset_sincrono coefficient_a_bit_6 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_a), .d(sw[6]), .q(a[6]));
    flipflop_reset_sincrono coefficient_a_bit_7 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_a), .d(sw[7]), .q(a[7]));

    flipflop_reset_sincrono coefficient_b_bit_0 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_b), .d(sw[0]), .q(b[0]));
    flipflop_reset_sincrono coefficient_b_bit_1 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_b), .d(sw[1]), .q(b[1]));
    flipflop_reset_sincrono coefficient_b_bit_2 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_b), .d(sw[2]), .q(b[2]));
    flipflop_reset_sincrono coefficient_b_bit_3 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_b), .d(sw[3]), .q(b[3]));
    flipflop_reset_sincrono coefficient_b_bit_4 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_b), .d(sw[4]), .q(b[4]));
    flipflop_reset_sincrono coefficient_b_bit_5 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_b), .d(sw[5]), .q(b[5]));
    flipflop_reset_sincrono coefficient_b_bit_6 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_b), .d(sw[6]), .q(b[6]));
    flipflop_reset_sincrono coefficient_b_bit_7 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_b), .d(sw[7]), .q(b[7]));

    flipflop_reset_sincrono coefficient_c_bit_0 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_c), .d(sw[0]), .q(c[0]));
    flipflop_reset_sincrono coefficient_c_bit_1 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_c), .d(sw[1]), .q(c[1]));
    flipflop_reset_sincrono coefficient_c_bit_2 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_c), .d(sw[2]), .q(c[2]));
    flipflop_reset_sincrono coefficient_c_bit_3 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_c), .d(sw[3]), .q(c[3]));
    flipflop_reset_sincrono coefficient_c_bit_4 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_c), .d(sw[4]), .q(c[4]));
    flipflop_reset_sincrono coefficient_c_bit_5 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_c), .d(sw[5]), .q(c[5]));
    flipflop_reset_sincrono coefficient_c_bit_6 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_c), .d(sw[6]), .q(c[6]));
    flipflop_reset_sincrono coefficient_c_bit_7 (.clk(clk), .reset(pedido_rearme), .reset_value(1'b0), .enable(habilita_c), .d(sw[7]), .q(c[7]));

endmodule

module flipflop_simples (
    input wire clk,
    input wire d,
    output reg q
);
    always @(posedge clk) begin
        q <= d;
    end
endmodule

module flipflop_reset_sincrono (
    input wire clk,
    input wire reset,
    input wire reset_value,
    input wire enable,
    input wire d,
    output reg q
);
    wire nao_habilita;
    wire dado_habilitado;
    wire dado_retido;
    wire dado_normal;
    wire nao_rearme;
    wire dado_rearme;
    wire dado_normal_selecionado;
    wire proximo_dado;

    not invert_enable (nao_habilita, enable);
    and select_enabled_data (dado_habilitado, enable, d);
    and select_held_data (dado_retido, nao_habilita, q);
    or combine_enable_mux (dado_normal, dado_habilitado, dado_retido);

    not invert_reset (nao_rearme, reset);
    and select_reset_value (dado_rearme, reset, reset_value);
    and select_normal_value (dado_normal_selecionado, nao_rearme, dado_normal);
    or combine_reset_mux (proximo_dado, dado_rearme, dado_normal_selecionado);

    always @(posedge clk) begin
        q <= proximo_dado;
    end
endmodule
