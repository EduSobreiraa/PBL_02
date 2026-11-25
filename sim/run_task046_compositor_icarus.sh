#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ivl_root=${IVERILOG_ROOT:-/usr/local}
iverilog_bin=${IVERILOG_BIN:-$ivl_root/bin/iverilog}
vvp_bin=${VVP_BIN:-$ivl_root/bin/vvp}
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-task046-compositor.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
"$iverilog_bin" -g2005 -s tb_task046_compositor -o "$build_dir/compositor.vvp" \
    "$repo_root/sim/tb_task046_compositor.v" \
    "$repo_root/rtl/video/compositor_rgb.v" \
    "$repo_root/rtl/aritmetica/addsub_20.v" \
    "$repo_root/rtl/aritmetica/addsub_25.v" \
    "$repo_root/rtl/aritmetica/full_adder_1bit.v" \
    "$repo_root/rtl/aritmetica/conditional_negate_25.v" \
    "$repo_root/rtl/aritmetica/multiply_unsigned_10x10.v"
timeout 120 "$vvp_bin" "$build_dir/compositor.vvp"
