project_open -revision pbl03 pbl03
create_timing_netlist
read_sdc
update_timing_netlist
foreach endpoint {VGA_R[0] VGA_R[1] VGA_R[2] VGA_R[3] VGA_G[0] VGA_G[1] VGA_G[2] VGA_G[3] VGA_B[0] VGA_B[1] VGA_B[2] VGA_B[3] VGA_HS VGA_VS} {
    puts "OUTPUT_PATH $endpoint"
    report_timing -from [all_registers] -to [get_ports $endpoint] -setup -npaths 1 -detail full_path -stdout
}
project_close
