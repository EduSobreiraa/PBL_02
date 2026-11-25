`timescale 1ns/1ps
module tb_task046_top_overlays;
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

 top_pbl03 dut (.MAX10_CLK1_50(MAX10_CLK1_50), .KEY(KEY), .SW(SW), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .LEDR(LEDR), .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5));

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
        SW=value;KEY=2'b10;
        for(hold_cycle=0;hold_cycle<8;hold_cycle=hold_cycle+1) @(negedge MAX10_CLK1_50);
        KEY=2'b11;
        for(hold_cycle=0;hold_cycle<8;hold_cycle=hold_cycle+1) @(negedge MAX10_CLK1_50);
    end
endtask

task capture_tuple_and_start;
    begin
        key0_click(9'd1);key0_click(9'd0);key0_click(9'd10);
        key0_click(9'd1);key0_click(9'd0);key0_click(9'd10);
        case(dut.input_ready)
            1'b1: ;
            default: $fatal(1,"TASK-046 TOP FAIL: input review not reached");
        endcase
        key0_click(9'd0);
    end
endtask

task wait_for_frame;
    begin
        ready_seen=0;
        for(cycle_count=0;cycle_count<5000 && !ready_seen;cycle_count=cycle_count+1) begin
            @(posedge MAX10_CLK1_50);#1;
            case(dut.frame_ready && dut.done_f1 && dut.done_f2 && dut.roots_ready)
                1'b1: ready_seen=1;
                default: ;
            endcase
        end
        case(ready_seen)
            1'b1: ;
            default: $fatal(1,"TASK-046 TOP FAIL: frame preparation timed out");
        endcase
        case(frame_write_count==640)
            1'b1: ;
            default: $fatal(1,"TASK-046 TOP FAIL: expected 640 writes, got %0d",frame_write_count);
        endcase
    end
endtask

task align_display;
    begin
        tick_seen=0;
        for(cycle_count=0;cycle_count<4 && !tick_seen;cycle_count=cycle_count+1) begin
            @(negedge MAX10_CLK1_50);
            case(dut.raster.pixel_reg)
                1'b1: tick_seen=1;
                default: ;
            endcase
        end
        case(tick_seen)
            1'b1: ;
            default: $fatal(1,"TASK-046 TOP FAIL: pixel tick timeout");
        endcase
        force dut.raster.h_count_reg=10'd0;
        force dut.raster.v_count_reg=10'd0;
        @(posedge MAX10_CLK1_50);#1;
        case(dut.frame_start && dut.video_on_delayed && dut.p_tick_delayed && dut.x_pixel_zero && dut.y_pixel_zero)
            1'b1: ;
            default: $fatal(1,"TASK-046 TOP FAIL: phase-1 frame-start conditions were not natural");
        endcase
        release dut.raster.h_count_reg;
        release dut.raster.v_count_reg;
        @(posedge MAX10_CLK1_50);#1;
        case(dut.processing_done && !dut.processing_busy)
            1'b1: ;
            default: $fatal(1,"TASK-046 TOP FAIL: display did not activate");
        endcase
    end
endtask

task sample_at;
    input [9:0] h;
    input [9:0] v;
    input [11:0] expected_rgb;
    input [120*8:1] label;
    begin
        tick_seen=0;
        for(cycle_count=0;cycle_count<4 && !tick_seen;cycle_count=cycle_count+1) begin
            @(negedge MAX10_CLK1_50);
            case(dut.raster.pixel_reg)
                1'b1: tick_seen=1;
                default: ;
            endcase
        end
        case(tick_seen)
            1'b1: ;
            default: $fatal(1,"TASK-046 TOP FAIL: sample pixel tick timeout");
        endcase
        force dut.raster.h_count_reg=h;
        force dut.raster.v_count_reg=v;
        @(posedge MAX10_CLK1_50);
        @(posedge MAX10_CLK1_50);#1;
        release dut.raster.h_count_reg;
        release dut.raster.v_count_reg;
        case ((dut.x_pixel_delayed2 === h) && (dut.y_pixel_delayed2 === v) &&
              dut.video_on_delayed2 && dut.p_tick_delayed2)
            1'b1: ;
            default: $fatal(1,"TASK-046 TOP FAIL: phase-2 raster/tick mismatch at %0d,%0d: raster=%0d,%0d video=%b tick=%b",h,v,dut.x_pixel_delayed2,dut.y_pixel_delayed2,dut.video_on_delayed2,dut.p_tick_delayed2);
        endcase
        case({VGA_R,VGA_G,VGA_B})
            expected_rgb: ;
            default: $fatal(1,"TASK-046 TOP FAIL: %0s at %0d,%0d expected %h got %h cart=%0d,%0d axes=%b%b panel=%b roots=%b%b curves=%b%b%b%b",label,h,v,expected_rgb,{VGA_R,VGA_G,VGA_B},dut.x_cartesiano_delayed2,dut.y_cartesiano_delayed2,dut.eixo_horizontal,dut.eixo_vertical,dut.panel_active,dut.root_marker_hit,dut.root_label_hit,dut.f1_hit,dut.f1_derivada_hit,dut.f2_hit,dut.f2_derivada_hit);
        endcase
    end
endtask

initial begin
    MAX10_CLK1_50=1'b0;KEY=2'b01;SW=9'd0;frame_write_count=0;cycle_count=0;ready_seen=0;tick_seen=0;
    repeat(4) @(negedge MAX10_CLK1_50);
    KEY=2'b11;
    sample_at(10'd269,10'd237,12'hfff,"prompt visible");
    sample_at(10'd532,10'd320,12'h000,"panel hidden during prompt");
    key0_click(9'd1);key0_click(9'd0);key0_click(9'h164);
    key0_click(9'd1);key0_click(9'd0);key0_click(9'h163);
    case(dut.input_ready)
        1'b1: ;
        default: $fatal(1,"TASK-046 TOP FAIL: real-root tuple did not reach review");
    endcase
    key0_click(9'd0);
    wait_for_frame();
    align_display();
    case ((dut.f1_root_domain_valid === 1'b1) && (dut.f1_vertex_x_rounded === 8'sd0) && (dut.f1_vertex_y_rounded === -14'sd100))
        1'b1: ;
        default: $fatal(1,"TASK-046 TOP FAIL: expected real roots and rounded vertex (0,-100)");
    endcase
    sample_at(10'd330,10'd240,12'hf80,"F1 root marker at x=10");
    case (dut.frame_read_data === {9'd0,9'd20,9'd1,9'd20,4'b1111,1'b0})
        1'b1: ;
        default: $fatal(1,"TASK-046 TOP FAIL: independent x=10 payload oracle mismatch: %h",dut.frame_read_data);
    endcase
    sample_at(10'd303,10'd208,12'hf80,"F1 root label phase-2 pixel");
    sample_at(10'd320,10'd340,12'h0f0,"F1 vertex marker at (0,-100)");
    case (dut.frame_read_data === {-9'sd100,9'd0,-9'sd99,9'd0,4'b1111,1'b0})
        1'b1: ;
        default: $fatal(1,"TASK-046 TOP FAIL: independent vertex-column payload oracle mismatch: %h",dut.frame_read_data);
    endcase
    sample_at(10'd532,10'd320,12'hfff,"panel root glyph");
    sample_at(10'd537,10'd320,12'h000,"opaque panel background");
    sample_at(10'd524,10'd321,12'hf80,"root swatch");
    sample_at(10'd524,10'd361,12'h0f0,"vertex swatch");
    sample_at(10'd520,10'd300,12'hfff,"panel border");
    sample_at(10'd520,10'd280,12'h000,"clear pixel above panel at right edge");
    $display("TASK-047 TOP OVERLAY PASS: phase-2 prompt, real roots/vertex markers and label, numeric panel glyphs/swatches, opaque panel; graph masking covered by compositor priority test");
    $finish;
end
endmodule
