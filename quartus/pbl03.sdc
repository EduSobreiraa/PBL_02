# DE10-Lite system clock: 50 MHz.
create_clock -name MAX10_CLK1_50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty

# Asynchronous KEY inputs are excepted only through each existing first-stage FF.
set_false_path -from [get_ports {KEY[0]}] -to [get_registers {*|dff_sync_bit:key0_sync_first|q}]
set_false_path -from [get_ports {KEY[1]}] -to [get_registers {*|dff_bit:key1_sync_first|q}]

# VGA raster pixel period is 40 ns (25 MHz); constrain registered RGB paths.
set_max_delay 40.000 -from [all_registers] -to [get_ports {VGA_R[*] VGA_G[*] VGA_B[*]}]
set_max_delay 40.000 -from [all_registers] -to [get_ports {VGA_HS VGA_VS}]
