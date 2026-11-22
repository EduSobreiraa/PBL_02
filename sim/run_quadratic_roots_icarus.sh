#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
run_local() {
    build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-quadratic-roots.XXXXXX")
    trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
    gcc -std=c99 -Wall -Wextra -Werror -fPIC -shared \
        -I"$(dirname "$(command -v iverilog)")/../include/iverilog" \
        -o "$build_dir/quadratic_roots_vpi.vpi" "$repo_root/sim/quadratic_roots_vpi.c"
    iverilog -g2005 -s tb_quadratic_roots -o "$build_dir/quadratic_roots.vvp" \
        "$repo_root/rtl/primitivos/dff_bit.v" \
        "$repo_root/rtl/aritmetica/full_adder_1bit.v" \
        "$repo_root/rtl/aritmetica/addsub_16.v" "$repo_root/rtl/aritmetica/addsub_18.v" \
        "$repo_root/rtl/aritmetica/conditional_negate_8.v" \
        "$repo_root/rtl/aritmetica/conditional_negate_10.v" \
        "$repo_root/rtl/aritmetica/conditional_negate_16.v" \
        "$repo_root/rtl/aritmetica/multiply_unsigned_8x8.v" \
        "$repo_root/rtl/aritmetica/incrementa_9.v" \
        "$repo_root/rtl/aritmetica/etapa_raiz.v" "$repo_root/rtl/aritmetica/somador_completo_raiz.v" \
        "$repo_root/rtl/aritmetica/etapa_divisao.v" "$repo_root/rtl/aritmetica/somador_completo_divisao.v" \
        "$repo_root/rtl/funcao/quadratic_roots.v" "$repo_root/sim/tb_quadratic_roots.v"
    (cd "$repo_root" && vvp -M "$build_dir" -m quadratic_roots_vpi "$build_dir/quadratic_roots.vvp")
}
if command -v iverilog >/dev/null 2>&1 && command -v vvp >/dev/null 2>&1 && command -v gcc >/dev/null 2>&1; then
    run_local
else
    exec docker run --rm -i --security-opt label=disable -v "$repo_root:/workspace:Z" -w /workspace hdlc/iverilog:latest sh -s <<'CONTAINER'
set -eu
cat >/etc/apt/sources.list <<'APT_SOURCES'
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20260824T000000Z bullseye main
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/20260824T000000Z bullseye-security main
deb [check-validity=no] http://snapshot.debian.org/archive/debian/20260824T000000Z bullseye-updates main
APT_SOURCES
apt-get -qq -o Acquire::Check-Valid-Until=false update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -qq install -y gcc libc6-dev >/dev/null 2>&1
sh sim/run_quadratic_roots_icarus.sh
CONTAINER
fi
