#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$repo_root/sim/resolve_altera_mf.sh"
verilator_bin=${VERILATOR_BIN:-$(command -v verilator || true)}
cxx_bin=${CXX:-$(command -v clang++ || command -v g++ || true)}

if [ -z "$verilator_bin" ] || [ ! -x "$verilator_bin" ]; then
    echo "ERROR: Verilator not found (set VERILATOR_BIN)" >&2
    exit 2
fi
if [ -z "$cxx_bin" ] || [ ! -x "$cxx_bin" ]; then
    echo "ERROR: C++ compiler not found (set CXX)" >&2
    exit 2
fi

build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-top-verilator.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
export CXX="$cxx_bin"
export MAKEFLAGS=-s

set --
while IFS= read -r source; do
    set -- "$@" "$repo_root/quartus/$source"
done <<SOURCES
$(sed -n 's/^set_global_assignment -name VERILOG_FILE //p' "$repo_root/quartus/pbl03.qsf")
SOURCES

"$verilator_bin" --cc --exe --build --top-module top_pbl03 \
    --Mdir "$build_dir/obj_dir" --Wno-fatal -CFLAGS "-std=c++17 -O2" \
    "$altera_mf_v" "$repo_root/sim/pbl03_top_verilator.cpp" "$@"
"$build_dir/obj_dir/Vtop_pbl03"
