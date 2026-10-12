# DEC-030: registered logic retains the real 50 MHz clock.
create_clock -name MAX10_CLK1_50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty
# Only asynchronous KEY arrivals at the first synchronizer stage are excepted.
set_false_path -from [get_ports {KEY[0]}] -to [get_registers {*key0_sync_stage_1|q}]
set_false_path -from [get_ports {KEY[1]}] -to [get_registers {*key1_sync_stage_1|q}]
# Human-facing asynchronous outputs have a separate 1 ms settling budget.
set_max_delay 1000000.000 -to [get_ports {LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]
# SW-to-register arrival is asynchronous/manual: intentionally no fictitious input delay.
