module fsm_frame_builder(input clk, input system_reset, input start_accepted, input results_ready, input write_valid, input [9:0] write_address, output reg [9:0] issue_index, output reg issue_valid, output reg busy, output reg frame_ready);
localparam WAIT_START = 3'b000;
localparam WAIT_RESULTS = 3'b001;
localparam ISSUE_COLUMNS = 3'b010;
localparam DRAIN_PIPELINE = 3'b011;
localparam FRAME_READY = 3'b100;
reg [2:0] state;
wire [9:0] issue_index_next;
soma_subtrai_10 increment_issue_index (.lhs(issue_index), .rhs(10'd1), .subtract(1'b0), .result(issue_index_next));

always @* begin
    issue_valid = 1'b0;
    busy = 1'b0;
    frame_ready = 1'b0;
    case (state)
        WAIT_RESULTS: busy = 1'b1;
        ISSUE_COLUMNS: begin
            issue_valid = 1'b1;
            busy = 1'b1;
        end
        DRAIN_PIPELINE: busy = 1'b1;
        FRAME_READY: frame_ready = 1'b1;
        default: begin
            issue_valid = 1'b0;
            busy = 1'b0;
            frame_ready = 1'b0;
        end
    endcase
end

always @(posedge clk) begin
    if (system_reset) begin
        state <= WAIT_START;
        issue_index <= 10'd0;
    end else begin
        case (state)
            WAIT_START: if (start_accepted) begin
                state <= WAIT_RESULTS;
                issue_index <= 10'd0;
            end
            WAIT_RESULTS: if (results_ready) begin
                state <= ISSUE_COLUMNS;
                issue_index <= 10'd0;
            end
            ISSUE_COLUMNS: if (issue_index == 10'd639)
                state <= DRAIN_PIPELINE;
            else
                issue_index <= issue_index_next;
            DRAIN_PIPELINE: if (write_valid && write_address == 10'd639)
                state <= FRAME_READY;
            FRAME_READY: if (start_accepted) begin
                state <= WAIT_RESULTS;
                issue_index <= 10'd0;
            end
            default: begin
                state <= WAIT_START;
                issue_index <= 10'd0;
            end
        endcase
    end
end
endmodule
