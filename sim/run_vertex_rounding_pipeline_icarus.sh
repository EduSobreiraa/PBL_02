#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ivl_root=${IVERILOG_ROOT:-/usr/local}
iverilog_bin=${IVERILOG_BIN:-"$ivl_root/bin/iverilog"}
vvp_bin=${VVP_BIN:-"$ivl_root/bin/vvp"}
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-vertex-pipeline.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM

"$iverilog_bin" -g2005 -s tb_vertex_rounding_pipeline -o "$build_dir/vertex_pipeline.vvp" \
    "$repo_root/rtl/aritmetica/full_adder_1bit.v" \
    "$repo_root/rtl/aritmetica/addsub_16.v" \
    "$repo_root/rtl/aritmetica/conditional_negate_16.v" \
    "$repo_root/rtl/aritmetica/conditional_negate_18.v" \
    "$repo_root/rtl/aritmetica/restoring_division_18_step10.v" \
    "$repo_root/rtl/aritmetica/restoring_division_18_group4.v" \
    "$repo_root/rtl/aritmetica/restoring_division_18_group2.v" \
    "$repo_root/rtl/aritmetica/round_signed_ratio_18_10_pipeline.v" \
    "$repo_root/rtl/primitivos/dff_sync2_struct.v" \
    "$repo_root/rtl/primitivos/dff_sync6_struct.v" \
    "$repo_root/rtl/primitivos/dff_sync10_struct.v" \
    "$repo_root/rtl/primitivos/dff_sync14_struct.v" \
    "$repo_root/rtl/primitivos/dff_sync18_struct.v" \
    "$repo_root/rtl/primitivos/dff_sync22_struct.v" \
    "$repo_root/sim/tb_vertex_rounding_pipeline.v"
"$vvp_bin" "$build_dir/vertex_pipeline.vvp"
