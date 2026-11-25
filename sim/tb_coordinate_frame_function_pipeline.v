`timescale 1ns/1ps
module tb_coordinate_frame_function_pipeline;
reg clk;
reg reset;
reg signed [7:0] a;
reg signed [7:0] b;
reg signed [7:0] c;
reg signed [9:0] x;
wire signed [24:0] f;
wire signed [17:0] derivative;

coordinate_frame_function_pipeline dut (.clk(clk), .reset(reset), .a(a), .b(b), .c(c), .x(x), .f(f), .derivative(derivative));

always #5 clk = ~clk;

task check_result;
    input signed [24:0] expected_f;
    input signed [17:0] expected_derivative;
    begin
        case ((f === expected_f) && (derivative === expected_derivative))
            1'b1: ;
            default: $fatal(1, "PIPELINE FAIL: x=%0d expected f=%0d df=%0d observed f=%0d df=%0d",
                            x, expected_f, expected_derivative, f, derivative);
        endcase
    end
endtask

initial begin
    clk = 1'b0;
    reset = 1'b1;
    a = 8'sd1;
    b = 8'sd0;
    c = 8'sd0;
    x = 10'sd10;
    repeat (2) @(negedge clk);
    reset = 1'b0;
    @(posedge clk); #1; check_result(25'sd100, 18'sd20);
    @(negedge clk); x = 10'sd11;
    @(posedge clk); #1; check_result(25'sd121, 18'sd22);
    @(negedge clk); x = 10'sd12;
    @(posedge clk); #1; check_result(25'sd144, 18'sd24);
    @(negedge clk); x = 10'sd13;
    @(posedge clk); #1; check_result(25'sd169, 18'sd26);
    @(negedge clk); x = 10'sd14;
    @(posedge clk); #1; check_result(25'sd196, 18'sd28);
    @(negedge clk); x = 10'sd15;
    @(posedge clk); #1; check_result(25'sd225, 18'sd30);
    @(negedge clk);
    a = -8'sd2;
    b = 8'sd3;
    c = -8'sd5;
    x = -10'sd10;
    @(posedge clk); #1; check_result(-25'sd235, 18'sd43);
    @(negedge clk);
    a = -8'sd128;
    b = 8'sd127;
    c = -8'sd128;
    x = -10'sd320;
    @(posedge clk); #1; check_result(-25'sd13147968, 18'sd82047);
    $display("PIPELINE PASS: one-cycle latency, one column/cycle throughput, signed and extreme inputs");
    $finish;
end
endmodule
