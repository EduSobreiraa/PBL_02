#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ivl_root=${IVERILOG_ROOT:-/tmp/task027-iverilog/usr}
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

build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-f1-function.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM

export IVL_PATH="$ivl_root/lib64/ivl"
export LD_LIBRARY_PATH="$ivl_root/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

"$cc_bin" -std=c99 -Wall -Wextra -Werror -fPIC -shared \
    -I"$ivl_root/include/iverilog" \
    -o "$build_dir/f1_function_vpi.vpi" \
    "$repo_root/sim/f1_function_vpi.c"

"$iverilog_bin" -g2005 -s tb_f1_function -o "$build_dir/f1_function.vvp" \
    "$repo_root/rtl/aritmetica/full_adder_1bit.v" \
    "$repo_root/rtl/aritmetica/addsub_16.v" \
    "$repo_root/rtl/aritmetica/addsub_18.v" \
    "$repo_root/rtl/aritmetica/addsub_20.v" \
    "$repo_root/rtl/aritmetica/addsub_25.v" \
    "$repo_root/rtl/aritmetica/conditional_negate_8.v" \
    "$repo_root/rtl/aritmetica/conditional_negate_10.v" \
    "$repo_root/rtl/aritmetica/conditional_negate_16.v" \
    "$repo_root/rtl/aritmetica/conditional_negate_18.v" \
    "$repo_root/rtl/aritmetica/conditional_negate_25.v" \
    "$repo_root/rtl/aritmetica/multiply_unsigned_8x8.v" \
    "$repo_root/rtl/aritmetica/multiply_unsigned_8x10.v" \
    "$repo_root/rtl/aritmetica/multiply_unsigned_8x17.v" \
    "$repo_root/rtl/aritmetica/multiply_unsigned_10x10.v" \
    "$repo_root/rtl/aritmetica/signed_less_10.v" \
    "$repo_root/rtl/aritmetica/signed_less_18.v" \
    "$repo_root/rtl/funcao/avaliador_quadratico_f1.v" \
    "$repo_root/rtl/funcao/avaliador_derivada_f1.v" \
    "$repo_root/rtl/funcao/validador_vertice_f1.v" \
    "$repo_root/rtl/funcao/detector_hits_f1.v" \
    "$repo_root/rtl/funcao/datapath_f1.v" \
    "$repo_root/sim/tb_f1_function.v"

"$vvp_bin" -M "$build_dir" -m f1_function_vpi "$build_dir/f1_function.vvp"
