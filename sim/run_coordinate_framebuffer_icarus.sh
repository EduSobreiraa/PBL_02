#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ivl_root=${IVERILOG_ROOT:-/usr/local}
iverilog_bin=${IVERILOG_BIN:-"$ivl_root/bin/iverilog"}
vvp_bin=${VVP_BIN:-"$ivl_root/bin/vvp"}
for executable in "$iverilog_bin" "$vvp_bin"; do
    if [ ! -x "$executable" ]; then
        echo "ERROR: executable not found or not executable: $executable" >&2
        exit 2
    fi
done
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-coordinate-frame.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
"$iverilog_bin" -g2005 -s tb_coordinate_frame_ram -o "$build_dir/coordinate_frame_ram.vvp" \
    "$repo_root/rtl/primitivos/dff_bit.v" \
    "$repo_root/rtl/primitivos/dff_bus41_norst.v" \
    "$repo_root/rtl/primitivos/dff_bus4_norst.v" \
    "$repo_root/rtl/primitivos/mux2_bus41_struct.v" \
    "$repo_root/rtl/funcao/coordinate_frame_word_ff.v" \
    "$repo_root/rtl/funcao/coordinate_frame_mux64_41.v" \
    "$repo_root/rtl/funcao/coordinate_frame_mux16_41.v" \
    "$repo_root/rtl/funcao/coordinate_frame_ff_bank64.v" \
    "$repo_root/rtl/funcao/coordinate_frame_ram.v" \
    "$repo_root/sim/tb_coordinate_frame_ram.v"
"$vvp_bin" "$build_dir/coordinate_frame_ram.vvp"
