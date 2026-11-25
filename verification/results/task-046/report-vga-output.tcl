project_open pbl03
create_timing_netlist -model slow
read_sdc pbl03.sdc
update_timing_netlist
report_timing -setup -file ../verification/results/task-046/vga-outputs-14.rpt -from [all_registers] -to [get_ports {VGA_R[*] VGA_G[*] VGA_B[*]}] -npaths 14 -detail full_path
project_close
