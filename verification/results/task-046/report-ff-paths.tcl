project_open pbl03
create_timing_netlist -model slow
read_sdc pbl03.sdc
update_timing_netlist
report_timing -setup -file ../verification/results/task-046/ff-critical-paths.rpt -from [all_registers] -to [all_registers] -npaths 20 -detail full_path
project_close
