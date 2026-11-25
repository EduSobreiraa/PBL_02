#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$repo_root/sim/resolve_altera_mf.sh"
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

build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-video-axes.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM

export PATH="$ivl_root/bin:$PATH"
export LD_LIBRARY_PATH="$ivl_root/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export IVL_PATH="$ivl_root/lib64/ivl"

cd "$build_dir"
"$cc_bin" -std=c99 -Wall -Wextra -Werror -fPIC -shared \
    -I"$ivl_root/include/iverilog" \
    -o "$build_dir/video_axes_icarus_vpi.vpi" \
    "$repo_root/sim/video_axes_icarus_vpi.c"
set --
while IFS= read -r source; do
    set -- "$@" "$repo_root/quartus/$source"
done <<SOURCES
$(sed -n 's/^set_global_assignment -name VERILOG_FILE //p' "$repo_root/quartus/pbl03.qsf")
SOURCES

"$iverilog_bin" -g2005 -s tb_video_axes -s top_pbl03 -o video_axes.vvp \
    "$@" "$altera_mf_v" "$repo_root/sim/tb_video_axes.v"
"$vvp_bin" -M "$build_dir" -m video_axes_icarus_vpi "$build_dir/video_axes.vvp"
"$iverilog_bin" -g2005 -s top_pbl03 -o top_pbl03.vvp "$@" "$altera_mf_v"
echo "IVERILOG PASS: top_pbl03 elaborated with the current QSF source list"
