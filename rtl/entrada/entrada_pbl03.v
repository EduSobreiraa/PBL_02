module entrada_pbl03(input clk, input [1:0] key_n, input [8:0] sw, input processing_done, output signed [7:0] a1, output signed [7:0] b1, output signed [7:0] c1, output signed [7:0] a2, output signed [7:0] b2, output signed [7:0] c2, output start_pulse, output input_ready, output system_reset);
wire key0_sync_n;
wire key1_sync_n;
wire key0_event;
wire entrada_valida;
wire signed [7:0] valor_convertido;
wire capture_enable;
wire [2:0] capture_select;
not (system_reset, key1_sync_n);
sincronizador_keys sincronizador (.clk(clk), .key_n(key_n), .system_reset(system_reset), .key0_sync_n(key0_sync_n), .key1_sync_n(key1_sync_n));
detector_evento_key0 detector (.clk(clk), .system_reset(system_reset), .key0_sync_n(key0_sync_n), .key0_event(key0_event));
conversor_sinal_magnitude conversor (.sw(sw), .valor(valor_convertido));
validador_entrada validador (.sw(sw), .entrada_valida(entrada_valida));
fsm_entrada controle (.clk(clk), .system_reset(system_reset), .key0_event(key0_event), .entrada_valida(entrada_valida), .processing_done(processing_done), .capture_enable(capture_enable), .capture_select(capture_select), .start_pulse(start_pulse), .input_ready(input_ready));
banco_coeficientes banco (.clk(clk), .reset(system_reset), .capture_enable(capture_enable), .capture_select(capture_select), .data_in(valor_convertido), .a1(a1), .b1(b1), .c1(c1), .a2(a2), .b2(b2), .c2(c2));
endmodule
