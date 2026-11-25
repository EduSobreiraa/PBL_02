module tb_coordinate_frame_ram;
reg clk;
reg write_enable;
reg [9:0] write_address;
reg [31:0] write_data_low;
reg [8:0] write_data_high;
wire [40:0] write_data = {write_data_high, write_data_low};
reg read_enable;
reg [9:0] read_address;
wire [40:0] read_data;
wire [31:0] read_data_low = read_data[31:0];
wire [8:0] read_data_high = read_data[40:32];
coordinate_frame_ram dut (.clk(clk), .write_enable(write_enable), .write_address(write_address), .write_data(write_data), .read_enable(read_enable), .read_address(read_address), .read_data(read_data));
endmodule
