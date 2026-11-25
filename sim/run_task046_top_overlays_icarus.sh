#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$repo_root/sim/resolve_altera_mf.sh"
ivl_root=${IVERILOG_ROOT:-/usr/local}
iverilog_bin=${IVERILOG_BIN:-$ivl_root/bin/iverilog}
vvp_bin=${VVP_BIN:-$ivl_root/bin/vvp}
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-task046-top.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
export PATH="$ivl_root/bin:$PATH"
export LD_LIBRARY_PATH="$ivl_root/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export IVL_PATH="$ivl_root/lib64/ivl"
set --
while IFS= read -r source; do set -- "$@" "$repo_root/quartus/$source"; done <<SOURCES
$(sed -n 's/^set_global_assignment -name VERILOG_FILE //p' "$repo_root/quartus/pbl03.qsf")
SOURCES
"$iverilog_bin" -g2005 -s tb_task046_top_overlays -o "$build_dir/top_overlays.vvp" \
    "$altera_mf_v" "$@" "$repo_root/sim/tb_task046_top_overlays.v"
timeout 120 "$vvp_bin" "$build_dir/top_overlays.vvp"
