`timescale 1ns/1ps
module tb_coordinate_frame_ram;
reg clk;
reg write_enable;
reg [9:0] write_address;
reg [40:0] write_data;
reg read_enable;
reg [9:0] read_address;
wire [40:0] read_data;
reg [40:0] model [0:639];
integer index;
integer bank;
reg [40:0] overwrite_value;

coordinate_frame_ram dut (.clk(clk), .write_enable(write_enable), .write_address(write_address), .write_data(write_data), .read_enable(read_enable), .read_address(read_address), .read_data(read_data));

function [40:0] expected_word;
    input integer address;
    reg [63:0] mixed;
    begin
        mixed = (address + 1) * 64'h1f123bb5;
        mixed = mixed ^ ((address + 17) << 21) ^ 64'h12a55aa5;
        expected_word = mixed[40:0];
    end
endfunction

task clock_edge;
    begin
        #5 clk = 1'b1;
        #1;
        #4 clk = 1'b0;
    end
endtask

initial begin
    clk = 1'b0;
    write_enable = 1'b0;
    write_address = 10'd0;
    write_data = 41'd0;
    read_enable = 1'b0;
    read_address = 10'd0;
    overwrite_value = 41'd0;

    for (index = 0; index < 640; index = index + 1) begin
        write_enable = 1'b1;
        write_address = index[9:0];
        write_data = expected_word(index);
        model[index] = expected_word(index);
        clock_edge;
    end
    write_enable = 1'b0;

    for (index = 0; index < 640; index = index + 1) begin
        read_enable = 1'b1;
        read_address = index[9:0];
        clock_edge;
        case (index > 0)
            1'b1: begin
                case (read_data === model[index - 1])
                    1'b1: ;
                    default: $fatal(1, "FF table mismatch/latency at read %0d: got %h expected %h", index - 1, read_data, model[index - 1]);
                endcase
            end
            default: ;
        endcase
    end
    read_enable = 1'b0;
    clock_edge;
    case (read_data === model[639])
        1'b1: ;
        default: $fatal(1, "last address 639 did not drain from phase 1: got %h expected %h", read_data, model[639]);
    endcase
    clock_edge;
    case (read_data === 41'd0)
        1'b1: ;
        default: $fatal(1, "invalid read token did not select zero: got %h", read_data);
    endcase

    for (index = 640; index < 1024; index = index + 1) begin
        write_enable = 1'b1;
        write_address = index[9:0];
        write_data = expected_word(index);
        read_enable = 1'b1;
        read_address = index[9:0];
        clock_edge;
        case (index > 640)
            1'b1: begin
                case (read_data === 41'd0)
                    1'b1: ;
                    default: $fatal(1, "invalid bank selector %0d did not return zero: %h", index[9:6], read_data);
                endcase
            end
            default: ;
        endcase
    end
    write_enable = 1'b0;
    read_enable = 1'b1;
    for (index = 0; index <= 640; index = index + 1) begin
        read_address = (index < 640) ? index[9:0] : 10'd0;
        clock_edge;
        case (index > 0)
            1'b1: begin
                case (read_data === model[index - 1])
                    1'b1: ;
                    default: $fatal(1, "invalid writes corrupted address %0d: got %h expected %h", index - 1, read_data, model[index - 1]);
                endcase
            end
            default: ;
        endcase
    end
    read_enable = 1'b0;
    clock_edge;
    clock_edge;
    case (read_data === 41'd0)
        1'b1: ;
        default: $fatal(1, "invalid read token did not return zero after full-table readback");
    endcase

    overwrite_value = 41'h155aa55aa55;
    write_enable = 1'b1;
    write_address = 10'd0;
    write_data = overwrite_value;
    clock_edge;
    write_enable = 1'b0;
    model[0] = overwrite_value;
    read_enable = 1'b1;
    read_address = 10'd0;
    clock_edge;
    clock_edge;
    case (read_data === model[0])
        1'b1: ;
        default: $fatal(1, "overwrite at address 0 failed: got %h expected %h", read_data, model[0]);
    endcase

    read_address = 10'd639;
    clock_edge;
    clock_edge;
    case (read_data === model[639])
        1'b1: ;
        default: $fatal(1, "unselected address 639 did not retain its word");
    endcase

    $display("COORDINATE FRAME FF PASS: 640 unique writes, 640 ordered reads plus full 640-word readback after invalid writes, two-phase alignment, overwrite, retention, invalid banks 10-15 zero");
    $finish;
end
endmodule
