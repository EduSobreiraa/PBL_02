project_open pbl03
create_timing_netlist -model slow
read_sdc pbl03.sdc
update_timing_netlist
report_timing -setup -file ../verification/results/task-048/quartus/vga-output-paths.rpt -from [all_registers] -to [get_ports {VGA_R[*] VGA_G[*] VGA_B[*] VGA_HS VGA_VS}] -npaths 14 -detail full_path
report_timing -setup -file ../verification/results/task-048/quartus/ff-setup-paths.rpt -from [all_registers] -to [all_registers] -npaths 20 -detail full_path
report_timing -hold -file ../verification/results/task-048/quartus/ff-hold-paths.rpt -from [all_registers] -to [all_registers] -npaths 20 -detail full_path
project_close
