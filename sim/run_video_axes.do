transcript on
set script_dir [file dirname [file normalize [info script]]]
if {[file exists work]} {vdel -lib work -all}
vlib work
vlog -work work "$script_dir/../rtl/video/coordenadas_cartesianas.v" "$script_dir/../rtl/video/detector_eixos.v" "$script_dir/../rtl/video/compositor_rgb.v" "$script_dir/../rtl/top/top_pbl03.v" "$script_dir/../vendor/vga/vga_sync.v" "$script_dir/tb_video_axes.v"
vsim -quiet work.tb_video_axes
force -freeze sim:/tb_video_axes/x_pixel 0 0
force -freeze sim:/tb_video_axes/y_pixel 240 0
force -freeze sim:/tb_video_axes/video_on 1 0
run 1 ns
if {[examine -radix unsigned sim:/tb_video_axes/x_cartesiano] != 704} {error "x=0 must map to signed -320 (unsigned 704)"}
if {[examine -radix unsigned sim:/tb_video_axes/eixo_vertical] != 0} {error "x=0 must not be vertical axis"}
force -freeze sim:/tb_video_axes/x_pixel 639 0
run 1 ns
if {[examine -radix unsigned sim:/tb_video_axes/x_cartesiano] != 319} {error "x=639 must map to 319"}
force -freeze sim:/tb_video_axes/x_pixel 320 0
force -freeze sim:/tb_video_axes/y_pixel 240 0
run 1 ns
if {[examine -radix unsigned sim:/tb_video_axes/x_cartesiano] != 0} {error "origin x must map to 0"}
if {[examine -radix unsigned sim:/tb_video_axes/y_cartesiano] != 0} {error "origin y must map to 0"}
if {[examine -radix unsigned sim:/tb_video_axes/eixo_vertical] != 1} {error "origin must activate vertical axis"}
if {[examine -radix unsigned sim:/tb_video_axes/eixo_horizontal] != 1} {error "origin must activate horizontal axis"}
if {[examine -radix unsigned sim:/tb_video_axes/red] != 15} {error "axis RGB must be white"}
force -freeze sim:/tb_video_axes/x_pixel 0 0
force -freeze sim:/tb_video_axes/y_pixel 0 0
run 1 ns
if {[examine -radix unsigned sim:/tb_video_axes/y_cartesiano] != 240} {error "y=0 must map to 240"}
force -freeze sim:/tb_video_axes/y_pixel 479 0
run 1 ns
if {[examine -radix unsigned sim:/tb_video_axes/y_cartesiano] != 785} {error "y=479 must map to signed -239 (unsigned 785)"}
force -freeze sim:/tb_video_axes/x_pixel 10 0
force -freeze sim:/tb_video_axes/y_pixel 10 0
run 1 ns
if {[examine -radix unsigned sim:/tb_video_axes/red] != 0} {error "off-axis pixel must be black"}
force -freeze sim:/tb_video_axes/video_on 0 0
force -freeze sim:/tb_video_axes/x_pixel 320 0
force -freeze sim:/tb_video_axes/y_pixel 240 0
run 1 ns
if {[examine -radix unsigned sim:/tb_video_axes/red] != 0} {error "blanking must be black"}
puts "PASS: coordinate limits, axes, RGB, and video_on clipping"
quit -sim
vsim -quiet work.top_pbl03
force -freeze sim:/top_pbl03/KEY 2'b01 0
run 1 ns
if {[examine -radix unsigned sim:/top_pbl03/reset_vga] != 1} {error "pressed KEY1 must assert VGA reset"}
force -freeze sim:/top_pbl03/KEY 2'b11 0
run 1 ns
if {[examine -radix unsigned sim:/top_pbl03/reset_vga] != 0} {error "released KEY1 must deassert VGA reset"}
puts "PASS: KEY1 VGA reset polarity"
quit -f
