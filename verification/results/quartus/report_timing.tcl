package require ::quartus::project
package require ::quartus::sta
set out [file normalize [lindex $quartus(args) 0]]
project_open pbl02
create_timing_netlist
read_sdc
update_timing_netlist
report_sdc -file [file join $out constraints.rpt]
set first0 [get_registers {*key0_sync_stage_1|q}]
set first1 [get_registers {*key1_sync_stage_1|q}]
puts "FIRST_STAGE_KEY0_COUNT=[get_collection_size $first0]"
puts "FIRST_STAGE_KEY1_COUNT=[get_collection_size $first1]"
puts "REGISTER_COUNT=[get_collection_size [get_registers *]]"
set latch_count 0
foreach_in_collection reg [get_registers *] {
    incr latch_count [get_register_info -is_latch $reg]
}
puts "LATCH_COUNT=$latch_count"
foreach_in_collection op [get_available_operating_conditions] {
    set_operating_conditions $op
    update_timing_netlist
    set corner [string map {" " "_"} [get_operating_conditions_info $op -display_name]]
    puts "CORNER=$corner"
    report_timing -setup -from [get_registers *] -to [get_registers *] -npaths 10 -detail full_path -file [file join $out ${corner}_registered_setup.rpt]
    report_timing -hold -from [get_registers *] -to [get_registers *] -npaths 10 -detail full_path -file [file join $out ${corner}_registered_hold.rpt]
    report_timing -setup -to [get_ports {LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}] -npaths 10 -detail full_path -file [file join $out ${corner}_output_budget.rpt]
    report_path -to [get_ports {LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}] -npaths 10 -file [file join $out ${corner}_output_delay.rpt]
    report_path -from [get_ports {SW[*]}] -to [get_registers *] -npaths 10 -file [file join $out ${corner}_manual_sw_delay.rpt]
}
delete_timing_netlist
project_close
