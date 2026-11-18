module fsm_entrada(input clk, input system_reset, input key0_event, input entrada_valida, input processing_done, output reg capture_enable, output reg [2:0] capture_select, output reg start_pulse, output reg input_ready);
localparam CAPTURE_A1 = 4'd0;
localparam CAPTURE_B1 = 4'd1;
localparam CAPTURE_C1 = 4'd2;
localparam CAPTURE_A2 = 4'd3;
localparam CAPTURE_B2 = 4'd4;
localparam CAPTURE_C2 = 4'd5;
localparam WAIT_START = 4'd6;
localparam WAIT_DONE_LOW = 4'd7;
localparam WAIT_DONE_HIGH = 4'd8;
reg [3:0] state;
always @* begin
    capture_enable = 1'b0;
    capture_select = state[2:0];
    if (!system_reset && key0_event && entrada_valida && (state <= CAPTURE_C2))
        capture_enable = 1'b1;
end
always @(posedge clk) begin
    if (system_reset) begin
        state <= CAPTURE_A1;
        start_pulse <= 1'b0;
        input_ready <= 1'b0;
    end else begin
        start_pulse <= 1'b0;
        case (state)
            CAPTURE_A1: if (key0_event && entrada_valida) state <= CAPTURE_B1;
            CAPTURE_B1: if (key0_event && entrada_valida) state <= CAPTURE_C1;
            CAPTURE_C1: if (key0_event && entrada_valida) state <= CAPTURE_A2;
            CAPTURE_A2: if (key0_event && entrada_valida) state <= CAPTURE_B2;
            CAPTURE_B2: if (key0_event && entrada_valida) state <= CAPTURE_C2;
            CAPTURE_C2: if (key0_event && entrada_valida) begin
                state <= WAIT_START;
                input_ready <= 1'b1;
            end
            WAIT_START: if (key0_event) begin
                state <= WAIT_DONE_LOW;
                start_pulse <= 1'b1;
            end
            WAIT_DONE_LOW: if (!processing_done) state <= WAIT_DONE_HIGH;
            WAIT_DONE_HIGH: if (processing_done) state <= WAIT_START;
            default: state <= CAPTURE_A1;
        endcase
    end
end
endmodule
