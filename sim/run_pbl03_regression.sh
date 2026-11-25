#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "$0")/.." && pwd)
result_dir="$repo_root/verification/results/task-047"
mkdir -p "$result_dir"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
log_file="$result_dir/regression-$timestamp.log"
manifest_file="$result_dir/tree-manifest-$timestamp.sha256"
tmp_manifest=$(mktemp)
(
    cd "$repo_root"
    git ls-files -co --exclude-standard -z \
        | LC_ALL=C sort -z \
        | grep -zE '\.(v|sv|vh|svh|c|h|cpp|hpp|sh|py|qsf|sdc)$' \
        | xargs -0 -r sha256sum
) >"$tmp_manifest"
tree_fingerprint=$(sha256sum "$tmp_manifest" | awk '{print $1}')
cp "$tmp_manifest" "$manifest_file"
rm -f "$tmp_manifest"
exec > >(tee -a "$log_file") 2>&1

echo "PBL03 TASK-047 FF-only aggregate regression"
echo "UTC start: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Repository: $repo_root"
echo "Git HEAD: $(git -C "$repo_root" rev-parse HEAD)"
echo "Worktree SHA256: $tree_fingerprint"
echo "Worktree manifest: $manifest_file"
echo "Fingerprint scope: RTL, test harnesses, runners, checker, QSF/SDC input files (.v .sv .vh .svh .c .h .cpp .hpp .sh .py .qsf .sdc); excludes docs and verification/results"
echo "Fingerprint command: git ls-files -co --exclude-standard -z | LC_ALL=C sort -z | grep -zE '\\.(v|sv|vh|svh|c|h|cpp|hpp|sh|py|qsf|sdc)$' | xargs -0 -r sha256sum; sha256sum <manifest>"
echo "Working tree status at start:"
git -C "$repo_root" status --short
echo "Log: $log_file"

python3 "$repo_root/verification/check_pbl03_sources.py"

echo "== Icarus FF-only regression (hdlc/iverilog:latest; no altera_mf.v) =="
docker run --rm -i --security-opt label=disable \
    -v "$repo_root:/workspace:Z" \
    -w /workspace hdlc/iverilog:latest sh -s <<'ICARUS_CONTAINER'
set -eu
cat >/etc/apt/sources.list <<'APT_SOURCES'
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20260824T000000Z bullseye main
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/20260824T000000Z bullseye-security main
deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20260824T000000Z bullseye-updates main
APT_SOURCES
if ! apt-get -qq -o Acquire::Check-Valid-Until=false update >/tmp/task047-apt-update.log 2>&1; then
    cat /tmp/task047-apt-update.log
    exit 2
fi
if ! DEBIAN_FRONTEND=noninteractive apt-get -qq install -y gcc libc6-dev >/tmp/task047-apt-install.log 2>&1; then
    cat /tmp/task047-apt-install.log
    exit 2
fi
mkdir -p /tmp/task028-iverilog/usr/bin /tmp/task028-iverilog/usr/lib64 /tmp/task028-iverilog/usr/include
ln -sfn /usr/local/bin/iverilog /tmp/task028-iverilog/usr/bin/iverilog
ln -sfn /usr/local/bin/vvp /tmp/task028-iverilog/usr/bin/vvp
ln -sfn /usr/local/lib/ivl /tmp/task028-iverilog/usr/lib64/ivl
ln -sfn /usr/local/include/iverilog /tmp/task028-iverilog/usr/include/iverilog
export IVERILOG_ROOT=/tmp/task028-iverilog/usr
export IVERILOG_BIN=/tmp/task028-iverilog/usr/bin/iverilog
export VVP_BIN=/tmp/task028-iverilog/usr/bin/vvp
export CC=/usr/bin/gcc
export PATH=/tmp/task028-iverilog/usr/bin:$PATH
export LD_LIBRARY_PATH=/tmp/task028-iverilog/usr/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export IVL_PATH=/tmp/task028-iverilog/usr/lib64/ivl
echo "Icarus version:"
iverilog -V | head -n 2
echo "VVP version:"
vvp -V | head -n 2
echo "GCC version:"
gcc --version | head -n 1
for runner in \
    sim/run_video_axes_icarus.sh \
    sim/run_coefficient_input_pbl03.sh \
    sim/run_f1_function_icarus.sh \
    sim/run_f1_processor_icarus.sh \
    sim/run_f1_f2_processors_icarus.sh \
    sim/run_quadratic_roots_icarus.sh \
    sim/run_root_renderer_icarus.sh \
    sim/run_main_handshake_pbl03_icarus.sh \
    sim/run_status_errors_pbl03_icarus.sh \
    sim/run_coordinate_frame_function_pipeline_icarus.sh \
    sim/run_vertex_rounding_pipeline_icarus.sh \
    sim/run_coordinate_framebuffer_icarus.sh \
    sim/run_frame_reset_pbl03_icarus.sh \
    sim/run_task046_numeric_icarus.sh \
    sim/run_task046_panel_icarus.sh \
    sim/run_task046_compositor_icarus.sh \
    sim/run_task046_top_overlays_icarus.sh \
    sim/run_coordinate_framebuffer_full_icarus.sh; do
    echo "RUN $runner"
    sh "$runner"
    echo "RUN PASS $runner"
done
ICARUS_CONTAINER

echo "== Verilator top-level integration (hdlc/verilator:latest) =="
verilator_log="$result_dir/verilator-$timestamp.log"
verilator_result=PASS
set +e
docker run --rm -i --security-opt label=disable \
    -v "$repo_root:/workspace:Z" \
    -w /workspace hdlc/verilator:latest sh -s <<'VERILATOR_CONTAINER' >"$verilator_log" 2>&1
set -eu
echo "Verilator version:"
verilator --version
echo "C++ compiler version:"
clang++ --version | head -n 1
export CXX=/usr/bin/clang++
sh sim/run_pbl03_top_verilator.sh
echo "RUN PASS sim/run_pbl03_top_verilator.sh"
VERILATOR_CONTAINER
verilator_exit=$?
set -e
if [ "$verilator_exit" -eq 0 ]; then
    cat "$verilator_log"
else
    cat "$verilator_log"
    echo "RUN FAIL sim/run_pbl03_top_verilator.sh (exit $verilator_exit)"
    exit "$verilator_exit"
fi

python3 "$repo_root/verification/check_pbl03_sources.py"
echo "UTC finish: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "PBL03 TASK-047 AGGREGATE PASS; VERILATOR=$verilator_result"
