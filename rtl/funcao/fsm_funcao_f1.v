module fsm_funcao_f1(input clk, input system_reset, input start_pulse, input a1_zero, input vertice_y_fora, input function_valid, output reg busy, output reg done, output reg error_a_zero, output reg error_vertex, output reg display_enable);
localparam WAIT_START = 2'b00;
localparam VALIDATE = 2'b01;
localparam COMPLETE = 2'b10;
reg [1:0] state;

always @(posedge clk) begin
    if (system_reset) begin
        state <= WAIT_START;
        busy <= 1'b0;
        done <= 1'b0;
        error_a_zero <= 1'b0;
        error_vertex <= 1'b0;
        display_enable <= 1'b0;
    end else begin
        case (state)
            WAIT_START: begin
                if (start_pulse) begin
                    state <= VALIDATE;
                    busy <= 1'b1;
                    done <= 1'b0;
                    error_a_zero <= 1'b0;
                    error_vertex <= 1'b0;
                    display_enable <= 1'b0;
                end
            end
            VALIDATE: begin
                state <= COMPLETE;
                busy <= 1'b0;
                done <= 1'b1;
                error_a_zero <= a1_zero;
                error_vertex <= vertice_y_fora;
                display_enable <= function_valid;
            end
            COMPLETE: begin
                if (start_pulse) begin
                    state <= VALIDATE;
                    busy <= 1'b1;
                    done <= 1'b0;
                    error_a_zero <= 1'b0;
                    error_vertex <= 1'b0;
                    display_enable <= 1'b0;
                end
            end
            default: begin
                state <= WAIT_START;
                busy <= 1'b0;
                done <= 1'b0;
                error_a_zero <= 1'b0;
                error_vertex <= 1'b0;
                display_enable <= 1'b0;
            end
        endcase
    end
end
endmodule
