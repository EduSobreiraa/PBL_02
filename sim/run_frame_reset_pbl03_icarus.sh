#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ivl_root=${IVERILOG_ROOT:-/tmp/task028-iverilog/usr}
iverilog_bin=${IVERILOG_BIN:-"$ivl_root/bin/iverilog"}
vvp_bin=${VVP_BIN:-"$ivl_root/bin/vvp"}

for executable in "$iverilog_bin" "$vvp_bin"; do
    if [ ! -x "$executable" ]; then
        echo "ERROR: executable not found or not executable: $executable" >&2
        exit 2
    fi
done

build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-frame-reset.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
export PATH="$ivl_root/bin:$PATH"
export LD_LIBRARY_PATH="$ivl_root/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export IVL_PATH="$ivl_root/lib64/ivl"

set --
while IFS= read -r source; do
    set -- "$@" "$repo_root/quartus/$source"
done <<SOURCES
$(sed -n 's/^set_global_assignment -name VERILOG_FILE //p' "$repo_root/quartus/pbl03.qsf")
SOURCES

"$iverilog_bin" -g2005 -s tb_frame_reset_pbl03 -o "$build_dir/frame_reset.vvp" \
    "$@" "$repo_root/sim/tb_frame_reset_pbl03.v"
timeout 120 "$vvp_bin" "$build_dir/frame_reset.vvp"
