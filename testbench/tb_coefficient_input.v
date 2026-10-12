`timescale 1ns/1ps

module tb_coefficient_input;
    reg clk;
    reg key0_n;
    reg key1_n;
    reg [7:0] sw;
    wire signed [7:0] a;
    wire signed [7:0] b;
    wire signed [7:0] c;

    wire signed [7:0] core_a;
    wire signed [7:0] core_b;
    wire signed [7:0] core_c;
    wire loaded;
    integer checks = 0;

    coefficient_input_core core_dut (
        .clk(clk), .key0_n(key0_n), .key1_n(key1_n), .sw(sw),
        .a(core_a), .b(core_b), .c(core_c), .loaded(loaded)
    );

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
        input expected_loaded;
        input [511:0] label;
        begin
            checks = checks + 1;
            case ({(a !== expected_a), (b !== expected_b), (c !== expected_c),
                   (core_a !== a), (core_b !== b), (core_c !== c),
                   (loaded !== expected_loaded)})
                7'b0000000: begin
                end
                default: begin
                    $display("FAIL %0s: a=%h b=%h c=%h expected=%h %h %h",
                             label, a, b, c, expected_a, expected_b, expected_c);
                    $display("core=%h %h %h loaded=%b expected_loaded=%b",
                             core_a, core_b, core_c, loaded, expected_loaded);
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
        check_values(8'h00, 8'h00, 8'h00, 1'b0, "reset suppresses simultaneous capture");

        @(negedge clk);
        key0_n = 1'b1;
        key1_n = 1'b1;
        wait_clocks(8);
        check_values(8'h00, 8'h00, 8'h00, 1'b0, "release after reset has no spurious capture");

        press_key0(8'h80, 8);
        check_values(8'h80, 8'h00, 8'h00, 1'b0, "long first press captures once, not loaded");
        press_key0(8'h01, 5);
        check_values(8'h80, 8'h01, 8'h00, 1'b0, "second capture, not loaded");
        press_key0(8'h7F, 5);
        check_values(8'h80, 8'h01, 8'h7F, 1'b1, "three ordered captures");

        @(negedge clk);
        sw = 8'h44;
        wait_clocks(5);
        check_values(8'h80, 8'h01, 8'h7F, 1'b1, "switch changes without capture");

        press_key0(8'h2A, 8);
        check_values(8'h80, 8'h01, 8'h7F, 1'b1, "long press and fourth capture ignored");
        press_key0(8'hD6, 5);
        check_values(8'h80, 8'h01, 8'h7F, 1'b1, "later captures ignored until reset");

        press_key1(6);
        check_values(8'h00, 8'h00, 8'h00, 1'b0, "reset after completed load");

        press_key0(8'h11, 5);
        check_values(8'h11, 8'h00, 8'h00, 1'b0, "partial load before reset");
        press_key1(6);
        check_values(8'h00, 8'h00, 8'h00, 1'b0, "reset clears partial progress");

        press_key0(8'h12, 5);
        press_key0(8'h34, 5);
        press_key0(8'h56, 5);
        check_values(8'h12, 8'h34, 8'h56, 1'b1, "new ordered load after reset");

        @(negedge clk);
        key0_n = 1'b0;
        key1_n = 1'b0;
        sw = 8'hAA;
        wait_clocks(8);
        check_values(8'h00, 8'h00, 8'h00, 1'b0, "reset has priority during key0 press");
        @(negedge clk);
        key0_n = 1'b1;
        key1_n = 1'b1;
        wait_clocks(8);
        check_values(8'h00, 8'h00, 8'h00, 1'b0, "simultaneous release has no capture");
        press_key0(8'hFF, 8);
        check_values(8'hFF, 8'h00, 8'h00, 1'b0, "capture resumes after priority reset");

        $display("PASS TEST-001 coefficient_input wrapper/core loaded checks=%0d", checks);
        $finish;
    end
endmodule
