`timescale 1ns/1ps

module tb_coefficient_input;
    reg clk;
    reg key0_n;
    reg key1_n;
    reg [7:0] sw;
    wire signed [7:0] a;
    wire signed [7:0] b;
    wire signed [7:0] c;

    coefficient_input dut (
        .clk(clk),
        .key0_n(key0_n),
        .key1_n(key1_n),
        .sw(sw),
        .a(a),
        .b(b),
        .c(c)
    );

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    task wait_clocks;
        input integer count;
        integer index;
        begin
            for (index = 0; index < count; index = index + 1)
                @(posedge clk);
            #1;
        end
    endtask

    task check_values;
        input [7:0] expected_a;
        input [7:0] expected_b;
        input [7:0] expected_c;
        input [255:0] label;
        begin
            case ({(a !== expected_a), (b !== expected_b), (c !== expected_c)})
                3'b000: begin
                end
                default: begin
                    $display("FAIL %0s: a=%h b=%h c=%h expected=%h %h %h",
                             label, a, b, c, expected_a, expected_b, expected_c);
                    $fatal(1);
                end
            endcase
        end
    endtask

    task press_key0;
        input [7:0] value;
        input integer hold_cycles;
        begin
            @(negedge clk);
            sw = value;
            key0_n = 1'b0;
            wait_clocks(hold_cycles);
            @(negedge clk);
            key0_n = 1'b1;
            wait_clocks(5);
        end
    endtask

    task press_key1;
        input integer hold_cycles;
        begin
            @(negedge clk);
            key1_n = 1'b0;
            wait_clocks(hold_cycles);
            @(negedge clk);
            key1_n = 1'b1;
            wait_clocks(6);
        end
    endtask

    initial begin
        key0_n = 1'b0;
        key1_n = 1'b0;
        sw = 8'h55;
        wait_clocks(8);
        check_values(8'h00, 8'h00, 8'h00, "reset suppresses simultaneous capture");

        @(negedge clk);
        key0_n = 1'b1;
        key1_n = 1'b1;
        wait_clocks(8);
        check_values(8'h00, 8'h00, 8'h00, "release after reset has no spurious capture");

        press_key0(8'h80, 5);
        press_key0(8'h01, 5);
        press_key0(8'h7F, 5);
        check_values(8'h80, 8'h01, 8'h7F, "three ordered captures");

        @(negedge clk);
        sw = 8'h44;
        wait_clocks(5);
        check_values(8'h80, 8'h01, 8'h7F, "switch changes without capture");

        press_key0(8'h2A, 8);
        check_values(8'h80, 8'h01, 8'h7F, "long press and fourth capture ignored");
        press_key0(8'hD6, 5);
        check_values(8'h80, 8'h01, 8'h7F, "later captures ignored until reset");

        press_key1(6);
        check_values(8'h00, 8'h00, 8'h00, "reset after completed load");

        press_key0(8'h11, 5);
        check_values(8'h11, 8'h00, 8'h00, "partial load before reset");
        press_key1(6);
        check_values(8'h00, 8'h00, 8'h00, "reset clears partial progress");

        press_key0(8'h12, 5);
        press_key0(8'h34, 5);
        press_key0(8'h56, 5);
        check_values(8'h12, 8'h34, 8'h56, "new ordered load after reset");

        $display("PASS TEST-001 coefficient_input");
        $finish;
    end
endmodule
