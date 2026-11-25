#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ivl_root=${IVERILOG_ROOT:-/tmp/task028-iverilog/usr}
iverilog_bin=${IVERILOG_BIN:-"$ivl_root/bin/iverilog"}
vvp_bin=${VVP_BIN:-"$ivl_root/bin/vvp"}
cc_bin=${CC:-$(command -v gcc || command -v cc || true)}

if [ -z "$cc_bin" ]; then
    echo "ERROR: no C compiler found (set CC to a compiler executable)" >&2
    exit 2
fi

for executable in "$iverilog_bin" "$vvp_bin" "$cc_bin"; do
    if [ ! -x "$executable" ]; then
        echo "ERROR: executable not found or not executable: $executable" >&2
        exit 2
    fi
done

build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-main-handshake.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM

export IVL_PATH="$ivl_root/lib64/ivl"
export LD_LIBRARY_PATH="$ivl_root/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

"$cc_bin" -std=c99 -Wall -Wextra -Werror -fPIC -shared \
    -I"$ivl_root/include/iverilog" \
    -o "$build_dir/main_handshake_pbl03_vpi.vpi" \
    "$repo_root/sim/main_handshake_pbl03_vpi.c"

set --
while IFS= read -r source; do
    set -- "$@" "$repo_root/quartus/$source"
done <<SOURCES
$(sed -n 's/^set_global_assignment -name VERILOG_FILE //p' "$repo_root/quartus/pbl03.qsf")
SOURCES

"$iverilog_bin" -g2005 -s tb_main_handshake_pbl03 -o "$build_dir/main_handshake.vvp" \
    "$@" "$repo_root/sim/tb_main_handshake_pbl03.v"
"$vvp_bin" -M "$build_dir" -m main_handshake_pbl03_vpi "$build_dir/main_handshake.vvp"

"$iverilog_bin" -g2005 -s top_pbl03 -o "$build_dir/top_pbl03.vvp" "$@"
echo "IVERILOG PASS: top_pbl03 elaborated with the current QSF source list"
