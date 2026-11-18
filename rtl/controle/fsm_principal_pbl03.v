module fsm_principal_pbl03(input clk, input system_reset, input input_ready, input start_pulse, input done_f1, input done_f2, output reg busy, output reg done);
localparam WAIT_INPUT = 2'b00;
localparam REVIEW = 2'b01;
localparam WAIT_PROCESSORS = 2'b10;
localparam DISPLAY = 2'b11;
reg [1:0] state;

always @(posedge clk) begin
    if (system_reset)
        state <= WAIT_INPUT;
    else begin
        case (state)
            WAIT_INPUT: if (input_ready) state <= REVIEW;
            REVIEW: if (start_pulse) state <= WAIT_PROCESSORS;
            WAIT_PROCESSORS: if (done_f1 && done_f2) state <= DISPLAY;
            DISPLAY: if (start_pulse) state <= WAIT_PROCESSORS;
            default: state <= WAIT_INPUT;
        endcase
    end
end

always @* begin
    busy = 1'b0;
    done = 1'b0;
    case (state)
        WAIT_PROCESSORS: busy = 1'b1;
        DISPLAY: done = 1'b1;
        default: begin
            busy = 1'b0;
            done = 1'b0;
        end
    endcase
end
endmodule
