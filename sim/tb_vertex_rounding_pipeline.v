`timescale 1ns/1ps
module tb_vertex_rounding_pipeline;
reg clk;
reg reset;
reg start_valid;
reg safe_zero;
reg signed [17:0] numerator;
reg [9:0] denominator;
wire [1:0] terminal_flags;
wire signed [13:0] rounded_candidate;
integer denominator_index;
integer failures;

round_signed_ratio_18_10_pipeline dut (
    .clk(clk), .reset(reset), .start_valid(start_valid), .safe_zero(safe_zero),
    .numerator(numerator), .denominator(denominator),
    .terminal_flags(terminal_flags), .rounded_candidate(rounded_candidate)
);

always #5 clk = ~clk;

task check_case;
    input integer numerator_value;
    input integer denominator_value;
    input integer safe_zero_value;
    integer magnitude_value;
    integer quotient_value;
    integer remainder_value;
    integer rounded_magnitude;
    integer expected_value;
    integer expected_sign;
    integer denominator_reference;
    begin
        reset = 1'b1;
        start_valid = 1'b0;
        safe_zero = 1'b0;
        numerator = 18'sd0;
        denominator = 10'd1;
        @(posedge clk);
        #1;
        @(negedge clk);
        reset = 1'b0;
        start_valid = 1'b1;
        safe_zero = safe_zero_value[0];
        numerator = numerator_value;
        denominator = denominator_value;
        @(posedge clk);
        #1;
        @(negedge clk); start_valid = 1'b0;
        repeat (4) @(posedge clk);
        #1;
        magnitude_value = safe_zero_value ? 0 : (numerator_value < 0 ? -numerator_value : numerator_value);
        denominator_reference = safe_zero_value ? 1 : denominator_value;
        quotient_value = magnitude_value / denominator_reference;
        remainder_value = magnitude_value % denominator_reference;
        rounded_magnitude = quotient_value + ((2 * remainder_value) >= denominator_reference);
        expected_sign = safe_zero_value ? 0 : (numerator_value < 0);
        expected_value = expected_sign ? -rounded_magnitude : rounded_magnitude;
        case ((terminal_flags[0] === 1'b1) &&
              (terminal_flags[1] === (safe_zero_value ? 1'b0 : expected_sign[0])) &&
              (rounded_candidate === expected_value[13:0]))
            1'b1: ;
            default: begin
                failures = failures + 1;
                $display("VERTEX PIPELINE CASE FAIL: n=%0d d=%0d safe=%0d flags=%b expected=%0d observed=%0d",
                         numerator_value, denominator_value, safe_zero_value,
                         terminal_flags, expected_value, rounded_candidate);
                $fatal(1);
            end
        endcase
    end
endtask

initial begin
    clk = 1'b0;
    reset = 1'b1;
    start_valid = 1'b0;
    safe_zero = 1'b0;
    numerator = 18'sd0;
    denominator = 10'd1;
    failures = 0;
    for (denominator_index = 1; denominator_index <= 510; denominator_index = denominator_index + 1)
        check_case(denominator_index * 3, denominator_index, 0);
    check_case(-131071, 17, 0);
    check_case(131071, 17, 0);
    check_case(-7, 2, 0);
    check_case(7, 2, 0);
    check_case(-15, 10, 0);
    check_case(15, 10, 0);
    check_case(-131072, 0, 1);
    check_case(131071, 510, 1);
    $display("VERTEX PIPELINE PASS: denom=1..510, signed extremes, half-away ties, safe-zero, fixed five-edge divider latency");
    $finish;
end
endmodule
