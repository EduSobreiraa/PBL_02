module fsm_principal_pbl03(input clk, input system_reset, input input_ready, input start_pulse, input done_f1, input done_f2, input roots_ready, input frame_start, output reg busy, output reg done, output reg start_accepted);
localparam WAIT_INPUT = 2'b00;
localparam REVIEW = 2'b01;
localparam WAIT_PROCESSORS = 2'b10;
localparam WAIT_FRAME_START = 3'b011;
localparam DISPLAY = 3'b100;
reg [2:0] state;

always @(posedge clk) begin
    if (system_reset)
        state <= WAIT_INPUT;
    else begin
        case (state)
            WAIT_INPUT: if (input_ready) state <= REVIEW;
            REVIEW: if (start_pulse) state <= WAIT_PROCESSORS;
            WAIT_PROCESSORS: if (done_f1 && done_f2 && roots_ready) begin
                if (frame_start) state <= DISPLAY;
                else state <= WAIT_FRAME_START;
            end
            WAIT_FRAME_START: if (frame_start) state <= DISPLAY;
            DISPLAY: if (start_pulse) state <= WAIT_PROCESSORS;
            default: state <= WAIT_INPUT;
        endcase
    end
end

always @* begin
    busy = 1'b0;
    done = 1'b0;
    start_accepted = 1'b0;
    case (state)
        REVIEW: if (start_pulse && !system_reset) start_accepted = 1'b1;
        WAIT_PROCESSORS: busy = 1'b1;
        WAIT_FRAME_START: busy = 1'b1;
        DISPLAY: begin
            done = 1'b1;
            if (start_pulse && !system_reset) start_accepted = 1'b1;
        end
        default: begin
            busy = 1'b0;
            done = 1'b0;
        end
    endcase
end
endmodule
