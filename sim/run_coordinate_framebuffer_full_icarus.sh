#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ivl_root=${IVERILOG_ROOT:-/tmp/iverilog-local/usr}
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

build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-coordinate-frame-full.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
export PATH="$ivl_root/bin:$PATH"
export LD_LIBRARY_PATH="$ivl_root/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export IVL_PATH="$ivl_root/lib64/ivl"
"$cc_bin" -std=c99 -Wall -Wextra -Werror -fPIC -shared \
    -I"$ivl_root/include/iverilog" \
    -o "$build_dir/coordinate_framebuffer_full_icarus_vpi.vpi" \
    "$repo_root/sim/coordinate_framebuffer_full_vpi.c"
set --
while IFS= read -r source; do
    set -- "$@" "$repo_root/quartus/$source"
done <<SOURCES
$(sed -n 's/^set_global_assignment -name VERILOG_FILE //p' "$repo_root/quartus/pbl03.qsf")
SOURCES
"$iverilog_bin" -g2005 -s tb_coordinate_framebuffer_full -o "$build_dir/coordinate_framebuffer_full.vvp" \
    "$@" "$repo_root/sim/tb_coordinate_framebuffer_full.v"
start_time=$(date +%s)
simulation_log="$build_dir/coordinate_framebuffer_full.log"
if "$vvp_bin" -M "$build_dir" -m coordinate_framebuffer_full_icarus_vpi "$build_dir/coordinate_framebuffer_full.vvp" >"$simulation_log" 2>&1; then
    :
else
    simulation_status=$?
    cat "$simulation_log"
    echo "ERROR: full-frame simulator exited with status $simulation_status" >&2
    exit "$simulation_status"
fi
cat "$simulation_log"
if ! grep -q '^FULL FRAME PASS:' "$simulation_log"; then
    echo "ERROR: missing native testbench FULL FRAME PASS sentinel" >&2
    exit 1
fi
if ! grep -q '^VPI PASS: native TB completed one full 800x525 raster after all 640 oracle-checked writes$' "$simulation_log"; then
    echo "ERROR: missing VPI full-frame completion sentinel" >&2
    exit 1
fi
finish_time=$(date +%s)
echo "FULL FRAME RUNTIME SECONDS: $((finish_time - start_time))"
