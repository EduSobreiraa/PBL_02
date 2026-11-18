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
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-coefficient-input.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
export PATH="$ivl_root/bin:$PATH"
export LD_LIBRARY_PATH="$ivl_root/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export IVL_PATH="$ivl_root/lib64/ivl"
cd "$build_dir"
"$cc_bin" -std=c99 -Wall -Wextra -Werror -fPIC -shared \
    -I"$ivl_root/include/iverilog" \
    -o "$build_dir/coefficient_input_pbl03_vpi.vpi" \
    "$repo_root/sim/coefficient_input_pbl03_vpi.c"
"$iverilog_bin" -g2005 -o coefficient_input_pbl03.vvp \
    "$repo_root/rtl/primitivos/dff_bit.v" \
    "$repo_root/rtl/primitivos/dff_sync_bit.v" \
    "$repo_root/rtl/primitivos/dff_sync8.v" \
    "$repo_root/rtl/entrada/sincronizador_keys.v" \
    "$repo_root/rtl/entrada/detector_evento_key0.v" \
    "$repo_root/rtl/entrada/conversor_sinal_magnitude.v" \
    "$repo_root/rtl/entrada/validador_entrada.v" \
    "$repo_root/rtl/entrada/fsm_entrada.v" \
    "$repo_root/rtl/entrada/banco_coeficientes.v" \
    "$repo_root/rtl/entrada/entrada_pbl03.v" \
    "$repo_root/sim/tb_coefficient_input_pbl03.v"
"$vvp_bin" -M "$build_dir" -m coefficient_input_pbl03_vpi "$build_dir/coefficient_input_pbl03.vvp"
