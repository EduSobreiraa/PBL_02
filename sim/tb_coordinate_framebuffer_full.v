`timescale 1ns/1ps
module tb_coordinate_framebuffer_full;
localparam integer FRAME_SYSTEM_CYCLES = 800 * 525 * 2;
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
integer write_count;
integer next_write_address;
integer active_cycles;
integer active_ticks;
integer total_ticks;
integer hsync_low_cycles;
integer vsync_low_cycles;
integer seen_axis;
integer seen_axis_white;
integer seen_f1;
integer seen_intersection_off_curve;
integer seen_df1;
integer done_seen;
integer frame_cycle;
integer coefficient_index;
integer coefficient_value;
reg vpi_capture_done;

function [40:0] reference_payload;
    input [9:0] address;
    integer x_cart;
    integer function_value;
    integer derivative_value;
    reg function_valid;
    reg derivative_valid;
    reg [8:0] function_y;
    reg [8:0] derivative_y;
    begin
        x_cart = $signed({1'b0, address}) - 320;
        function_value = (x_cart * x_cart) + 10;
        derivative_value = 2 * x_cart;
        function_valid = (function_value >= -239) && (function_value <= 240);
        derivative_valid = (derivative_value >= -239) && (derivative_value <= 240);
        function_y = function_valid ? function_value[8:0] : 9'b0;
        derivative_y = derivative_valid ? derivative_value[8:0] : 9'b0;
        reference_payload = {function_y, derivative_y, function_y, derivative_y,
                             function_valid, derivative_valid, function_valid,
                             derivative_valid, function_valid};
    end
endfunction

top_pbl03 dut (.MAX10_CLK1_50(MAX10_CLK1_50), .KEY(KEY), .SW(SW),
    .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
    .LEDR(LEDR), .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5));

always #10 MAX10_CLK1_50 = ~MAX10_CLK1_50;

always @(posedge MAX10_CLK1_50) begin
    case (dut.frame_memory_write_enable)
        1'b1: begin
            case (dut.staged_frame_address === next_write_address[9:0])
                1'b1: ;
                default: $fatal(1, "FULL FRAME FAIL: write order expected %0d observed %0d", next_write_address, dut.staged_frame_address);
            endcase
            case (next_write_address < 640)
                1'b1: ;
                default: $fatal(1, "FULL FRAME FAIL: more than 640 writes");
            endcase
            case (dut.staged_frame_data === reference_payload(dut.staged_frame_address))
                1'b1: ;
                default: $fatal(1, "FULL FRAME FAIL: independent 41-bit oracle mismatch at address %0d: expected %h, observed %h",
                                next_write_address, reference_payload(dut.staged_frame_address), dut.staged_frame_data);
            endcase
            next_write_address = next_write_address + 1;
            write_count = write_count + 1;
        end
        default: ;
    endcase
end

function [8:0] sign_magnitude;
    input integer value;
    integer magnitude;
    begin
        magnitude = value < 0 ? -value : value;
        sign_magnitude = magnitude | (value < 0 ? 9'h100 : 9'h000);
    end
endfunction

task key0_click;
    input integer value;
    integer hold_cycle;
    begin
        SW = sign_magnitude(value);
        KEY = 2'b10;
        for (hold_cycle = 0; hold_cycle < 8; hold_cycle = hold_cycle + 1)
            @(negedge MAX10_CLK1_50);
        KEY = 2'b11;
        for (hold_cycle = 0; hold_cycle < 8; hold_cycle = hold_cycle + 1)
            @(negedge MAX10_CLK1_50);
    end
endtask

task sample_raster_cycle;
    integer x;
    integer y;
    begin
        @(posedge MAX10_CLK1_50);
        #1;
        x = dut.x_pixel_delayed;
        y = dut.y_pixel_delayed;
        case (x < 800 && y < 525)
            1'b1: ;
            default: $fatal(1, "FULL FRAME FAIL: delayed raster coordinate out of range (%0d,%0d)", x, y);
        endcase
        case (dut.video_on_delayed === ((x < 640) && (y < 480)))
            1'b1: ;
            default: $fatal(1, "FULL FRAME FAIL: video_on misaligned at (%0d,%0d)", x, y);
        endcase
        case (((VGA_HS === 1'b0) || (VGA_HS === 1'b1)) && ((VGA_VS === 1'b0) || (VGA_VS === 1'b1)))
            1'b1: ;
            default: $fatal(1, "FULL FRAME FAIL: HS/VS unknown");
        endcase
        case (!VGA_HS) 1'b1: hsync_low_cycles = hsync_low_cycles + 1; default: ; endcase
        case (!VGA_VS) 1'b1: vsync_low_cycles = vsync_low_cycles + 1; default: ; endcase
        case (dut.p_tick_delayed) 1'b1: total_ticks = total_ticks + 1; default: ; endcase
        case (dut.video_on_delayed)
            1'b1: begin
                active_cycles = active_cycles + 1;
                case (dut.p_tick_delayed) 1'b1: active_ticks = active_ticks + 1; default: ; endcase
                case (dut.p_tick_delayed && x == 320 && y == 240)
                    1'b1: begin
                        case ({VGA_R, VGA_G, VGA_B} === 12'h0ff)
                            1'b1: ;
                            default: $fatal(1, "FULL FRAME FAIL: derivative priority was not cyan at the origin");
                        endcase
                        seen_axis = 1;
                    end
                    default: ;
                endcase
                case (dut.p_tick_delayed && x == 320 && y == 250)
                    1'b1: begin
                        case ({VGA_R, VGA_G, VGA_B} === 12'hfff)
                            1'b1: ;
                            default: $fatal(1, "FULL FRAME FAIL: vertical axis was not white away from curve overlays");
                        endcase
                        seen_axis_white = 1;
                    end
                    default: ;
                endcase
                case (dut.p_tick_delayed && x == 330 && y == 130)
                    1'b1: begin
                        case ({VGA_R, VGA_G, VGA_B} === 12'hf0f)
                            1'b1: ;
                            default: $fatal(1, "FULL FRAME FAIL: coincident f1/f2 was not magenta at x=10,y=110");
                        endcase
                        seen_f1 = 1;
                    end
                    default: ;
                endcase
                case (dut.p_tick_delayed && x == 330 && y == 131)
                    1'b1: begin
                        case ({VGA_R, VGA_G, VGA_B} === 12'h000)
                            1'b1: ;
                            default: $fatal(1, "FULL FRAME FAIL: column equality painted off-curve pixel x=10,y=109");
                        endcase
                        seen_intersection_off_curve = 1;
                    end
                    default: ;
                endcase
                case (dut.p_tick_delayed && x == 370 && y == 140)
                    1'b1: begin
                        $display("FULL FRAME SAMPLE df1: x_pixel=%0d y_pixel=%0d cart_y=%0d payload=%h df1_hit=%b rgb=%h",
                                 x, y, $signed(dut.y_cartesiano_delayed), dut.frame_read_data[31:23], dut.f1_derivada_hit, {VGA_R, VGA_G, VGA_B});
                        case ({VGA_R, VGA_G, VGA_B} === 12'h0ff)
                            1'b1: ;
                            default: $fatal(1, "FULL FRAME FAIL: f1 derivative was not cyan at x=50,y=100");
                        endcase
                        seen_df1 = 1;
                    end
                    default: ;
                endcase
            end
            default: ;
        endcase
    end
endtask

initial begin
    MAX10_CLK1_50 = 1'b0;
    KEY = 2'b11;
    SW = 9'b0;
    write_count = 0;
    next_write_address = 0;
    active_cycles = 0;
    active_ticks = 0;
    total_ticks = 0;
    hsync_low_cycles = 0;
    vsync_low_cycles = 0;
    seen_axis = 0;
    seen_axis_white = 0;
    seen_f1 = 0;
    seen_intersection_off_curve = 0;
    seen_df1 = 0;
    done_seen = 0;
    frame_cycle = 0;
    coefficient_index = 0;
    coefficient_value = 0;
    vpi_capture_done = 1'b0;

    KEY = 2'b01;
    repeat (8) @(negedge MAX10_CLK1_50);
    KEY = 2'b11;
    repeat (8) @(negedge MAX10_CLK1_50);

    key0_click(1);
    key0_click(0);
    key0_click(10);
    key0_click(1);
    key0_click(0);
    key0_click(10);
    case (dut.input_ready) 1'b1: ; default: $fatal(1, "FULL FRAME FAIL: six coefficients did not reach review"); endcase
    KEY = 2'b10;
    repeat (8) @(negedge MAX10_CLK1_50);
    KEY = 2'b11;

    for (frame_cycle = 0; frame_cycle < 1700000 && !done_seen; frame_cycle = frame_cycle + 1) begin
        @(posedge MAX10_CLK1_50);
        #1;
        case (dut.processing_done) 1'b1: done_seen = 1; default: ; endcase
        case ((frame_cycle % 200000) == 0)
            1'b1: $display("FULL FRAME WAIT PROGRESS: cycles=%0d writes=%0d ready=%b done=%b", frame_cycle, write_count, dut.frame_ready, dut.processing_done);
            default: ;
        endcase
    end
    case (done_seen) 1'b1: ; default: $fatal(1, "FULL FRAME FAIL: timeout waiting for frame_ready/DONE boundary"); endcase
    case (dut.frame_ready && !dut.processing_busy) 1'b1: ; default: $fatal(1, "FULL FRAME FAIL: DONE did not follow ready frame with BUSY low"); endcase
    case (write_count == 640 && next_write_address == 640) 1'b1: ; default: $fatal(1, "FULL FRAME FAIL: expected 640 ordered writes, observed %0d", write_count); endcase
    case (dut.x_pixel_delayed == 0 && dut.y_pixel_delayed == 0 && dut.video_on_delayed && dut.p_tick_delayed) 1'b1: ; default: $fatal(1, "FULL FRAME FAIL: DONE did not align with delayed active pixel (0,0)"); endcase
    case ({VGA_R, VGA_G, VGA_B} === 12'h000) 1'b1: ; default: $fatal(1, "FULL FRAME FAIL: first active pixel was not black"); endcase
    active_cycles = 1;
    active_ticks = 1;
    total_ticks = 1;
    frame_cycle = 1;
    $display("FULL FRAME: frame_ready/DONE aligned at delayed (0,0), p_tick=1; writes=%0d", write_count);

    for (frame_cycle = 1; frame_cycle < FRAME_SYSTEM_CYCLES; frame_cycle = frame_cycle + 1) begin
        sample_raster_cycle();
        case ((frame_cycle % 200000) == 0)
            1'b1: $display("FULL FRAME CAPTURE PROGRESS: cycles=%0d active=%0d ticks=%0d", frame_cycle, active_cycles, total_ticks);
            default: ;
        endcase
    end

    case (active_cycles == 640 * 480 * 2) 1'b1: ; default: $fatal(1, "FULL FRAME FAIL: active cycles expected %0d observed %0d", 640 * 480 * 2, active_cycles); endcase
    case (active_ticks == 640 * 480) 1'b1: ; default: $fatal(1, "FULL FRAME FAIL: active p_tick expected %0d observed %0d", 640 * 480, active_ticks); endcase
    case (total_ticks == 800 * 525) 1'b1: ; default: $fatal(1, "FULL FRAME FAIL: total p_tick expected %0d observed %0d", 800 * 525, total_ticks); endcase
    case (hsync_low_cycles == 96 * 525 * 2) 1'b1: ; default: $fatal(1, "FULL FRAME FAIL: HS low cycles expected %0d observed %0d", 96 * 525 * 2, hsync_low_cycles); endcase
    case (vsync_low_cycles == 2 * 800 * 2) 1'b1: ; default: $fatal(1, "FULL FRAME FAIL: VS low cycles expected %0d observed %0d", 2 * 800 * 2, vsync_low_cycles); endcase
    case (seen_axis && seen_axis_white && seen_f1 && seen_intersection_off_curve && seen_df1) 1'b1: ; default: $fatal(1, "FULL FRAME FAIL: expected axis/origin/F1/off-curve/F1' sample pixels were not all observed"); endcase
    $display("FULL FRAME PASS: %0d cycles, %0d active samples, %0d active ticks, %0d HS-low, %0d VS-low; axis/intersection/df1 pixels aligned",
             FRAME_SYSTEM_CYCLES, active_cycles, active_ticks, hsync_low_cycles, vsync_low_cycles);
    vpi_capture_done = 1'b1;
    #1;
    $finish;
end
endmodule
