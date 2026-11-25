#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$repo_root/sim/resolve_altera_mf.sh"
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

build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-f1-f2-processors.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM

export IVL_PATH="$ivl_root/lib64/ivl"
export LD_LIBRARY_PATH="$ivl_root/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

"$cc_bin" -std=c99 -Wall -Wextra -Werror -fPIC -shared \
    -I"$ivl_root/include/iverilog" \
    -o "$build_dir/f1_f2_processors_vpi.vpi" \
    "$repo_root/sim/f1_f2_processors_vpi.c" -lm

"$iverilog_bin" -g2005 -s tb_f1_f2_processors -o "$build_dir/f1_f2_processors.vvp" \
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
    "$repo_root/rtl/funcao/fsm_funcao_f1.v" \
    "$repo_root/rtl/funcao/processador_f1.v" \
    "$repo_root/rtl/aritmetica/round_signed_ratio_18_10.v" \
    "$repo_root/rtl/aritmetica/restoring_division_18_step10.v" \
    "$repo_root/rtl/aritmetica/restoring_division_18_group4.v" \
    "$repo_root/rtl/aritmetica/restoring_division_18_group2.v" \
    "$repo_root/rtl/aritmetica/round_signed_ratio_18_10_pipeline.v" \
    "$repo_root/rtl/funcao/quadratic_roots.v" \
    "$repo_root/rtl/funcao/ramo_raizes.v" \
    "$repo_root/rtl/aritmetica/nega_condicional_8.v" \
    "$repo_root/rtl/aritmetica/nega_condicional_9.v" \
    "$repo_root/rtl/aritmetica/nega_condicional_10.v" \
    "$repo_root/rtl/aritmetica/soma_subtrai_10.v" \
    "$repo_root/rtl/aritmetica/incrementa_9.v" \
    "$repo_root/rtl/aritmetica/raiz_quadrada_17.v" \
    "$repo_root/rtl/aritmetica/etapa_raiz.v" \
    "$repo_root/rtl/aritmetica/somador_completo_raiz.v" \
    "$repo_root/rtl/aritmetica/divisor_9_por_8.v" \
    "$repo_root/rtl/aritmetica/etapa_divisao.v" \
    "$repo_root/rtl/aritmetica/somador_completo_divisao.v" \
    "$repo_root/rtl/aritmetica/multiplica_com_sinal_8_por_8.v" \
    "$repo_root/rtl/aritmetica/subtrator_18.v" \
    "$repo_root/rtl/primitivos/dff_bit.v" \
    "$repo_root/rtl/primitivos/dff_sync_bit.v" \
    "$repo_root/rtl/primitivos/dff_sync8.v" \
    "$repo_root/rtl/primitivos/dff_sync8_struct.v" \
    "$repo_root/rtl/primitivos/dff_sync14_struct.v" \
    "$repo_root/rtl/primitivos/dff_sync2_struct.v" \
    "$repo_root/rtl/primitivos/dff_sync6_struct.v" \
    "$repo_root/rtl/primitivos/dff_sync10_struct.v" \
    "$repo_root/rtl/primitivos/dff_sync18_struct.v" \
    "$repo_root/rtl/primitivos/dff_sync22_struct.v" \
    "$repo_root/rtl/entrada/sincronizador_keys.v" \
    "$repo_root/rtl/entrada/detector_evento_key0.v" \
    "$repo_root/rtl/entrada/conversor_sinal_magnitude.v" \
    "$repo_root/rtl/entrada/validador_entrada.v" \
    "$repo_root/rtl/entrada/fsm_entrada.v" \
    "$repo_root/rtl/entrada/banco_coeficientes.v" \
    "$repo_root/rtl/entrada/entrada_pbl03.v" \
    "$repo_root/sim/tb_f1_f2_processors.v"

"$vvp_bin" -M "$build_dir" -m f1_f2_processors_vpi "$build_dir/f1_f2_processors.vvp"

set --
while IFS= read -r source; do
    set -- "$@" "$repo_root/quartus/$source"
done <<SOURCES
$(sed -n 's/^set_global_assignment -name VERILOG_FILE //p' "$repo_root/quartus/pbl03.qsf")
SOURCES
"$iverilog_bin" -g2005 -s top_pbl03 -o "$build_dir/top_pbl03.vvp" "$@" "$altera_mf_v"

echo "IVERILOG PASS: top_pbl03 elaborated with the complete QSF source list"
