#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ivl_root=${IVERILOG_ROOT:-/usr/local}
iverilog_bin=${IVERILOG_BIN:-$ivl_root/bin/iverilog}
vvp_bin=${VVP_BIN:-$ivl_root/bin/vvp}
cc_bin=${CC:-gcc}
include_dir=${IVERILOG_INCLUDE:-$ivl_root/include/iverilog}
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-task046-panel.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
"$cc_bin" -std=c99 -Wall -Wextra -Werror -fPIC -shared -I"$include_dir" \
    -o "$build_dir/task046_panel.vpi" "$repo_root/sim/task046_panel_reference_vpi.c"
"$iverilog_bin" -g2005 -s tb_task046_panel -o "$build_dir/panel.vvp" \
    "$repo_root/sim/tb_task046_panel.v" \
    "$repo_root/rtl/video/renderizador_quadro_info_vga.v" \
    "$repo_root/rtl/display/glyph_5x7.v" \
    "$repo_root/rtl/display/signed_to_bcd_glyphs14.v" \
    "$repo_root/rtl/display/signed_to_magnitude14.v" \
    "$repo_root/rtl/display/binary_to_bcd14.v" \
    "$repo_root/rtl/display/bcd_add3_digit.v" \
    "$repo_root/rtl/display/bcd_stage14.v" \
    "$repo_root/rtl/display/bcd_to_glyph_id.v" \
    "$repo_root/rtl/aritmetica/round_signed_ratio_18_10.v" \
    "$repo_root/rtl/aritmetica/conditional_negate_16.v" \
    "$repo_root/rtl/aritmetica/conditional_negate_18.v" \
    "$repo_root/rtl/aritmetica/addsub_16.v" \
    "$repo_root/rtl/aritmetica/full_adder_1bit.v"
timeout 120 "$vvp_bin" -M "$build_dir" -m task046_panel "$build_dir/panel.vvp"
