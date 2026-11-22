project_open pbl03 -revision pbl03
create_timing_netlist -model slow
read_sdc
update_timing_netlist
foreach endpoint {VGA_R[0] VGA_R[1] VGA_R[2] VGA_R[3] VGA_G[0] VGA_G[1] VGA_G[2] VGA_G[3] VGA_B[0] VGA_B[1] VGA_B[2] VGA_B[3]} {
    puts "OUTPUT_PATH $endpoint"
    report_timing -from [all_registers] -to [get_ports $endpoint] -setup -npaths 1 -detail full_path -stdout
}
foreach endpoint {VGA_HS VGA_VS} {
    puts "OUTPUT_PATH $endpoint"
    report_timing -from [all_registers] -to [get_ports $endpoint] -setup -npaths 1 -detail full_path -stdout
}
delete_timing_netlist
project_close
