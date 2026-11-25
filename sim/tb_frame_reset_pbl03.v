`timescale 1ns/1ps
module tb_frame_reset_pbl03;
reg MAX10_CLK1_50;
reg [1:0] KEY;
reg [8:0] SW;
wire VGA_HS;
wire VGA_VS;
wire [3:0] VGA_R;
wire [3:0] VGA_G;
wire [3:0] VGA_B;
wire [9:0] LEDR;
wire [6:0] HEX0;
wire [6:0] HEX1;
wire [6:0] HEX2;
wire [6:0] HEX3;
wire [6:0] HEX4;
wire [6:0] HEX5;
integer frame_write_count;
integer cycle_count;
integer ready_seen;
integer tick_seen;
integer reset_seen;
integer start_seen;

top_pbl03 dut (
    .MAX10_CLK1_50(MAX10_CLK1_50), .KEY(KEY), .SW(SW),
    .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
    .LEDR(LEDR), .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
    .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5)
);

always #10 MAX10_CLK1_50 = ~MAX10_CLK1_50;

always @(posedge MAX10_CLK1_50) begin
    case (dut.frame_memory_write_enable)
        1'b1: frame_write_count = frame_write_count + 1;
        default: ;
    endcase
end

task key0_click;
    input [8:0] value;
    integer hold_cycle;
    begin
        SW = value;
        KEY = 2'b10;
        for (hold_cycle = 0; hold_cycle < 8; hold_cycle = hold_cycle + 1)
            @(negedge MAX10_CLK1_50);
        KEY = 2'b11;
        for (hold_cycle = 0; hold_cycle < 8; hold_cycle = hold_cycle + 1)
            @(negedge MAX10_CLK1_50);
    end
endtask

task capture_tuple_and_start;
    begin
        key0_click(9'd1);
        key0_click(9'd0);
        key0_click(9'd10);
        key0_click(9'd1);
        key0_click(9'd0);
        key0_click(9'd10);
        case (dut.input_ready)
            1'b1: ;
            default: $fatal(1, "FRAME RESET FAIL: six coefficients did not reach review");
        endcase
        key0_click(9'd0);
    end
endtask

task wait_for_frame_ready;
    begin
        ready_seen = 0;
        for (cycle_count = 0; cycle_count < 5000 && !ready_seen; cycle_count = cycle_count + 1) begin
            @(posedge MAX10_CLK1_50);
            #1;
            case (dut.frame_ready && dut.done_f1 && dut.done_f2 && dut.roots_ready)
                1'b1: ready_seen = 1;
                default: ;
            endcase
        end
        case (ready_seen)
            1'b1: ;
            default: $fatal(1, "FRAME RESET FAIL: timeout waiting for real frame_ready and processor results");
        endcase
        case (frame_write_count == 640)
            1'b1: ;
            default: $fatal(1, "FRAME RESET FAIL: expected 640 frame writes before DONE, observed %0d", frame_write_count);
        endcase
    end
endtask

task wait_for_vertex_ready_before_roots;
    begin
        ready_seen = 0;
        for (cycle_count = 0; cycle_count < 200 && !ready_seen; cycle_count = cycle_count + 1) begin
            @(posedge MAX10_CLK1_50);
            #1;
            case (dut.vertex_ready)
                1'b1: ready_seen = 1;
                default: ;
            endcase
        end
        case (ready_seen && !dut.roots_ready && !dut.frame_ready && (frame_write_count == 0))
            1'b1: ;
            default: $fatal(1, "FRAME RESET FAIL: vertex_ready did not precede roots_ready with frame issue held");
        endcase
        repeat (4) begin
            @(posedge MAX10_CLK1_50);
            #1;
            case (dut.vertex_ready && !dut.frame_ready && (frame_write_count == 0))
                1'b1: ;
                default: $fatal(1, "FRAME RESET FAIL: vertex_ready was not sticky while roots/frame preparation remained pending");
            endcase
        end
        case (dut.roots_ready)
            1'b0: ;
            default: $fatal(1, "FRAME RESET FAIL: roots_ready did not remain low after vertex_ready");
        endcase
        $display("FRAME RESET: vertex_ready became sticky before roots_ready; no frame writes issued");
    end
endtask

task release_display_at_frame_start;
    begin
        tick_seen = 0;
        for (cycle_count = 0; cycle_count < 4 && !tick_seen; cycle_count = cycle_count + 1) begin
            @(negedge MAX10_CLK1_50);
            case (dut.raster.pixel_reg)
                1'b1: tick_seen = 1;
                default: ;
            endcase
        end
        case (tick_seen)
            1'b1: ;
            default: $fatal(1, "FRAME RESET FAIL: timeout waiting for natural VGA pixel tick");
        endcase
        force dut.raster.h_count_reg = 10'd0;
        force dut.raster.v_count_reg = 10'd0;
        #1;
        case (dut.frame_start && dut.video_on && dut.p_tick && dut.x_pixel_zero && dut.y_pixel_zero)
            1'b1: ;
            default: $fatal(1, "FRAME RESET FAIL: counter alignment did not create the real frame-start condition");
        endcase
        @(posedge MAX10_CLK1_50);
        #1;
        release dut.raster.h_count_reg;
        release dut.raster.v_count_reg;
        case (dut.frame_ready && dut.processing_done && !dut.processing_busy)
            1'b1: ;
            default: $fatal(1, "FRAME RESET FAIL: real frame boundary did not enable display and DONE");
        endcase
    end
endtask

task force_intersection_pixel;
    begin
        force dut.raster.h_count_reg = 10'd330;
        force dut.raster.v_count_reg = 10'd130;
        force dut.raster.pixel_reg = 1'b0;
        repeat (2) @(posedge MAX10_CLK1_50);
        #1;
        case ({VGA_R, VGA_G, VGA_B} === 12'hf0f)
            1'b1: ;
            default: $fatal(1, "FRAME RESET FAIL: displayed graph sample was not magenta before the action");
        endcase
        case (dut.frame_ready && dut.processing_done)
            1'b1: ;
            default: $fatal(1, "FRAME RESET FAIL: frame stopped being displayed before the action");
        endcase
    end
endtask

initial begin
    MAX10_CLK1_50 = 1'b0;
    KEY = 2'b01;
    SW = 9'b0;
    frame_write_count = 0;
    cycle_count = 0;
    ready_seen = 0;
    tick_seen = 0;
    reset_seen = 0;
    start_seen = 0;

    repeat (10) @(negedge MAX10_CLK1_50);
    KEY = 2'b11;
    repeat (10) @(negedge MAX10_CLK1_50);

    capture_tuple_and_start();
    wait_for_vertex_ready_before_roots();
    wait_for_frame_ready();
    release_display_at_frame_start();
    force_intersection_pixel();
    $display("FRAME RESET: DISPLAY1 shows actual intersection (330,130), writes=640, frame_ready=1, DONE=1");

    @(negedge MAX10_CLK1_50);
    KEY = 2'b01;
    reset_seen = 0;
    for (cycle_count = 0; cycle_count < 12 && !reset_seen; cycle_count = cycle_count + 1) begin
        @(posedge MAX10_CLK1_50);
        #1;
        case (dut.system_reset && !dut.frame_ready && !dut.vertex_ready && !dut.processing_done && !dut.processing_busy)
            1'b1: reset_seen = 1;
            default: ;
        endcase
    end
    case (reset_seen)
        1'b1: ;
        default: $fatal(1, "FRAME RESET FAIL: timeout waiting for synchronized KEY1 to clear frame state");
    endcase
    case ({VGA_R, VGA_G, VGA_B} === 12'h000)
        1'b1: ;
        default: $fatal(1, "FRAME RESET FAIL: graph RGB remained visible after KEY1 reset");
    endcase
    release dut.raster.h_count_reg;
    release dut.raster.v_count_reg;
    release dut.raster.pixel_reg;
    KEY = 2'b11;
    repeat (10) @(negedge MAX10_CLK1_50);
    frame_write_count = 0;
    $display("FRAME RESET: KEY1 during DISPLAY1 cleared frame_ready/BUSY/DONE and masked RGB to black");

    capture_tuple_and_start();
    wait_for_vertex_ready_before_roots();
    wait_for_frame_ready();
    release_display_at_frame_start();
    force_intersection_pixel();
    $display("FRAME RESET: DISPLAY2 shows actual intersection (330,130), writes=640, frame_ready=1, DONE=1");

    @(negedge MAX10_CLK1_50);
    KEY = 2'b10;
    SW = 9'b0;
    start_seen = 0;
    for (cycle_count = 0; cycle_count < 12 && !start_seen; cycle_count = cycle_count + 1) begin
        @(posedge MAX10_CLK1_50);
        #1;
        case (dut.start_accepted)
            1'b1: start_seen = 1;
            default: ;
        endcase
    end
    case (start_seen)
        1'b1: ;
        default: $fatal(1, "FRAME RESET FAIL: timeout waiting for real START acceptance in DISPLAY2");
    endcase
    @(posedge MAX10_CLK1_50);
    #1;
    case (!dut.frame_ready && !dut.vertex_ready && !dut.processing_done && dut.processing_busy)
        1'b1: ;
        default: $fatal(1, "FRAME RESET FAIL: START in DISPLAY2 did not clear frame_ready/DONE and assert BUSY");
    endcase
    case ({VGA_R, VGA_G, VGA_B} === 12'h000)
        1'b1: ;
        default: $fatal(1, "FRAME RESET FAIL: old graph RGB remained visible during new preparation");
    endcase
    $display("FRAME RESET PASS: KEY1 in DISPLAY1 and START in DISPLAY2 cleared/masked old frame after 640 writes");
    $finish;
end
endmodule
