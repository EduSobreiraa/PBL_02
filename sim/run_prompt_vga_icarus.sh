#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
run_local() {
    build_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-prompt-vga.XXXXXX")
    trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
    gcc -std=c99 -Wall -Wextra -Werror -fPIC -shared \
        -I"$(dirname "$(command -v iverilog)")/../include/iverilog" \
        -o "$build_dir/prompt_vga_vpi.vpi" "$repo_root/sim/prompt_vga_vpi.c"
    iverilog -g2005 -s tb_prompt_vga -o "$build_dir/prompt_vga.vvp" \
        "$repo_root/rtl/display/glyph_5x7.v" \
        "$repo_root/rtl/video/renderizador_prompt_vga.v" \
        "$repo_root/sim/tb_prompt_vga.v"
    vvp -M "$build_dir" -m prompt_vga_vpi "$build_dir/prompt_vga.vvp"
}
if command -v iverilog >/dev/null 2>&1 && command -v vvp >/dev/null 2>&1 && command -v gcc >/dev/null 2>&1; then
    run_local
else
    exec docker run --rm -i --security-opt label=disable -v "$repo_root:/workspace:Z" -w /workspace hdlc/iverilog:latest sh -s <<'CONTAINER'
set -eu
cat >/etc/apt/sources.list <<'APT_SOURCES'
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20260824T000000Z bullseye main
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/20260824T000000Z bullseye-security main
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20260824T000000Z bullseye-updates main
APT_SOURCES
apt-get -qq -o Acquire::Check-Valid-Until=false update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -qq install -y gcc libc6-dev >/dev/null 2>&1
mkdir -p /tmp/iverilog-local/usr/bin /tmp/iverilog-local/usr/lib64 /tmp/iverilog-local/usr/include
ln -sfn /usr/local/bin/iverilog /tmp/iverilog-local/usr/bin/iverilog
ln -sfn /usr/local/bin/vvp /tmp/iverilog-local/usr/bin/vvp
ln -sfn /usr/local/lib/ivl /tmp/iverilog-local/usr/lib64/ivl
ln -sfn /usr/local/include/iverilog /tmp/iverilog-local/usr/include/iverilog
export IVERILOG_ROOT=/tmp/iverilog-local/usr
export IVERILOG_BIN=/tmp/iverilog-local/usr/bin/iverilog
export VVP_BIN=/tmp/iverilog-local/usr/bin/vvp
export CC=/usr/bin/gcc
export PATH=/tmp/iverilog-local/usr/bin:$PATH
export LD_LIBRARY_PATH=/tmp/iverilog-local/usr/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export IVL_PATH=/tmp/iverilog-local/usr/lib64/ivl
sh sim/run_prompt_vga_icarus.sh
CONTAINER
fi
