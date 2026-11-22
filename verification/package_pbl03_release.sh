#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"
out_dir="$repo_root/verification/results/task-041/final"
quartus_project_out="$repo_root/quartus/output_files_pbl03"
mkdir -p "$out_dir"
# Invalidate an earlier PASS before starting a new attempt, so stale evidence
# cannot survive a later failure and be mistaken for this run's result.
rm -f -- "$out_dir/release-summary.md" "$out_dir/artifact-sha256.txt" "$out_dir/artifact-hash-check.log"

utc_start=$(date -u +%Y-%m-%dT%H:%M:%SZ)
head_sha=$(git rev-parse HEAD)
initial_status=$(git status --porcelain=v1)
status_file="$out_dir/worktree-status-start.txt"
printf '%s\n' "${initial_status:-clean}" > "$status_file"

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/pbl03-release.XXXXXXXX")
created_task036=()
task036_dir="$repo_root/verification/results/task-036"
task036_before=()
cleanup() {
    if ((${#task036_before[@]})); then
        local current name
        while IFS= read -r name; do
            if ! printf '%s\n' "${task036_before[@]}" | grep -Fqx -- "$name"; then
                rm -f -- "$task036_dir/$name"
            fi
        done < <(find "$task036_dir" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null || true)
    fi
    rm -rf -- "$tmp_dir"
}
trap cleanup EXIT

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

hash_inputs() {
    local manifest=$1
    local -a paths=()
    local paths_file="$tmp_dir/input-paths.txt"
    if ! python3 - "$repo_root" > "$paths_file" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
qsf = (root / "quartus/pbl03.qsf").read_text(encoding="utf-8")
source_paths = re.findall(r'^set_global_assignment\s+-name\s+VERILOG_FILE\s+"?([^"\s]+)', qsf, re.M)
if len(source_paths) != 57 or len(set(source_paths)) != 57:
    raise SystemExit(f"QSF must contain 57 distinct VERILOG_FILE entries; found {len(source_paths)}")
qsf_paths = {str((Path("quartus") / p).resolve().relative_to(root.resolve())) for p in source_paths}
data = json.loads((root / "verification/pbl03_sources.json").read_text(encoding="utf-8"))
manifest_paths = {entry["path"] for entry in data}
if len(data) != 57 or len(manifest_paths) != 57 or qsf_paths != manifest_paths:
    raise SystemExit("QSF VERILOG_FILE paths and source manifest differ")
active = sorted(manifest_paths)
(root / "verification/results/task-041/final/active-sources.txt").write_text("\n".join(active) + "\n", encoding="utf-8")

extensions = {".v", ".sv", ".vh", ".svh", ".c", ".h", ".cpp", ".hpp", ".sh", ".py", ".qsf", ".sdc"}
listed = set()
for item in __import__("subprocess").check_output(
        ["git", "ls-files", "-co", "--exclude-standard", "-z"], cwd=root).decode().split("\0"):
    if not item:
        continue
    p = Path(item)
    if p.suffix in extensions and not item.startswith("verification/results/"):
        listed.add(item)
listed.update({
    "REGRAS.md", "verification/pbl03_sources.json", "quartus/pbl03.qpf",
    "quartus/pbl03.qsf", "quartus/pbl03.sdc", "vendor/vga/UPSTREAM.md",
})
listed.update(active)
listed.update({
    "verification/check_pbl03_sources.py", "verification/package_pbl03_release.sh",
    "verification/test_check_pbl03_sources.py", "sim/run_pbl03_regression.sh",
    "sim/run_pbl03_top_verilator.sh",
})
for name in sorted(listed):
    if not (root / name).is_file():
        raise SystemExit(f"missing input file: {name}")
    print(name)
PY
    then
        fail "could not enumerate or validate active inputs"
    fi
    mapfile -t paths < "$paths_file"
    ((${#paths[@]} > 0)) || fail "input enumeration returned an empty path list"

    : > "$manifest"
    local path
    for path in "${paths[@]}"; do
        sha256sum -- "$path" >> "$manifest"
    done
}

fingerprint() { sha256sum "$1" | awk '{print $1}'; }
assert_inputs_unchanged() {
    hash_inputs "$tmp_dir/input-after.sha256"
    cmp -s "$out_dir/input-sha256.txt" "$tmp_dir/input-after.sha256" \
        || fail "input files changed during packaging; evidence is not one snapshot"
}

hash_inputs "$out_dir/input-sha256.txt" || fail "input manifest generation failed"
input_fingerprint=$(fingerprint "$out_dir/input-sha256.txt")
printf 'Git HEAD: %s\nInput fingerprint: %s\n' "$head_sha" "$input_fingerprint" > "$tmp_dir/provenance"

echo "PBL03 reproducible technical release package"
echo "UTC start: $utc_start"
echo "Git HEAD: $head_sha"
echo "Worktree at start: ${initial_status:-clean}"
echo "Input fingerprint: $input_fingerprint"

# Keep the pre-existing TASK-036 evidence immutable; the approved runner writes its
# timestamped artifacts there, which are copied here then removed if newly created.
mkdir -p "$task036_dir"
mapfile -t task036_before < <(find "$task036_dir" -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort)
if ! python3 verification/check_pbl03_sources.py > "$out_dir/source-check.log" 2>&1; then
    cat "$out_dir/source-check.log"
    fail "PBL03 source checker failed"
fi
if ! git diff --check -- docs/tasks/TASK-041.md > "$out_dir/diff-check.log" 2>&1; then
    cat "$out_dir/diff-check.log"
    fail "git diff --check failed for TASK-041 documentation"
fi
set +e
git diff --no-index --check -- /dev/null verification/package_pbl03_release.sh >> "$out_dir/diff-check.log" 2>&1
diff_check_rc=$?
set -e
if ((diff_check_rc > 1)) || [[ -s "$out_dir/diff-check.log" ]]; then
    cat "$out_dir/diff-check.log"
    fail "git diff --check failed for package script"
fi
if ! ./sim/run_pbl03_regression.sh > "$out_dir/regression.log" 2>&1; then
    cat "$out_dir/regression.log"
    fail "aggregate regression failed"
fi
mapfile -t task036_after < <(find "$task036_dir" -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort)
for name in "${task036_after[@]}"; do
    if ! printf '%s\n' "${task036_before[@]}" | grep -Fqx -- "$name"; then
        created_task036+=("$task036_dir/$name")
    fi
done
new_regression_log=$(grep -Eo 'verification/results/task-036/regression-[^[:space:]]+\.log' "$out_dir/regression.log" | tail -n 1 || true)
new_tree_manifest=$(grep -Eo 'verification/results/task-036/tree-manifest-[^[:space:]]+\.sha256' "$out_dir/regression.log" | head -n 1 || true)
[[ -n "$new_regression_log" && -f "$new_regression_log" ]] || fail "runner did not produce a regression log"
[[ -n "$new_tree_manifest" && -f "$new_tree_manifest" ]] || fail "runner did not produce an input tree manifest"
cp -- "$new_regression_log" "$out_dir/regression-runner.log"
cp -- "$new_tree_manifest" "$out_dir/regression-inputs.sha256"
for marker in \
    'RUN PASS sim/run_video_axes_icarus.sh' \
    'RUN PASS sim/run_coefficient_input_pbl03.sh' \
    'RUN PASS sim/run_f1_function_icarus.sh' \
    'RUN PASS sim/run_f1_processor_icarus.sh' \
    'RUN PASS sim/run_f1_f2_processors_icarus.sh' \
    'RUN PASS sim/run_quadratic_roots_icarus.sh' \
    'RUN PASS sim/run_root_renderer_icarus.sh' \
    'RUN PASS sim/run_main_handshake_pbl03_icarus.sh' \
    'RUN PASS sim/run_status_errors_pbl03_icarus.sh' \
    'RUN PASS sim/run_pbl03_top_verilator.sh'; do
    grep -Fq "$marker" "$out_dir/regression.log" || fail "missing success marker: $marker"
done
assert_inputs_unchanged

vga_hash=$(sha256sum vendor/vga/vga_sync.v | awk '{print $1}')
expected_vga_hash=$(sed -n 's/^- SHA-256: `\([0-9a-f]*\)`.*/\1/p' vendor/vga/UPSTREAM.md)
[[ -n "$expected_vga_hash" && "$vga_hash" == "$expected_vga_hash" ]] || fail "vendor VGA hash differs from UPSTREAM.md"
printf '%s  vendor/vga/vga_sync.v\n' "$vga_hash" > "$out_dir/vga-upstream.sha256"
sha256sum -c "$out_dir/vga-upstream.sha256" > "$out_dir/vga-hash-check.log" || fail "VGA hash manifest failed"

quartus_sh_bin=$(command -v quartus_sh || true)
[[ -n "$quartus_sh_bin" ]] || fail "quartus_sh is unavailable"
quartus_dir=$(dirname -- "$quartus_sh_bin")
quartus_version="$($quartus_sh_bin --version 2>&1)" || fail "cannot read Quartus version"
printf '%s\n' "$quartus_version" > "$out_dir/quartus-version.log"
if ! "$quartus_sh_bin" --flow compile quartus/pbl03 > "$out_dir/quartus-compile.log" 2>&1; then
    cat "$out_dir/quartus-compile.log"
    fail "Quartus compile failed"
fi
quartus_warning_count=$(grep -c '^Warning (' "$out_dir/quartus-compile.log" || true)
assert_inputs_unchanged

quartus_tcl="$tmp_dir/final_timing.tcl"
cat > "$quartus_tcl" <<'TCL'
project_open -revision pbl03 pbl03
create_timing_netlist -model slow
read_sdc
update_timing_netlist
foreach endpoint {VGA_R[0] VGA_R[1] VGA_R[2] VGA_R[3] VGA_G[0] VGA_G[1] VGA_G[2] VGA_G[3] VGA_B[0] VGA_B[1] VGA_B[2] VGA_B[3] VGA_HS VGA_VS} {
    puts "OUTPUT_PATH $endpoint"
    report_timing -from [all_registers] -to [get_ports $endpoint] -setup -npaths 1 -detail full_path -stdout
}
puts "FF_TO_FF_PATHS"
report_timing -from [all_registers] -to [all_registers] -setup -npaths 1 -detail full_path -stdout
delete_timing_netlist
project_close
TCL
if ! (cd quartus && "$quartus_dir/quartus_sta" -t "$quartus_tcl" pbl03) > "$out_dir/quartus-paths.log" 2>&1; then
    cat "$out_dir/quartus-paths.log"
    fail "Quartus detailed timing report failed"
fi
for endpoint in VGA_R\[0\] VGA_R\[1\] VGA_R\[2\] VGA_R\[3\] VGA_G\[0\] VGA_G\[1\] VGA_G\[2\] VGA_G\[3\] VGA_B\[0\] VGA_B\[1\] VGA_B\[2\] VGA_B\[3\] VGA_HS VGA_VS; do
    grep -Fq "OUTPUT_PATH $endpoint" "$out_dir/quartus-paths.log" || fail "missing timing endpoint $endpoint"
done
grep -Fq FF_TO_FF_PATHS "$out_dir/quartus-paths.log" || fail "missing FF-to-FF timing report"
python3 - "$out_dir/quartus-paths.log" "$out_dir/timing-results.txt" <<'PY'
import re
from pathlib import Path
import sys

log = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
result_path = Path(sys.argv[2])
endpoints = [f"VGA_{c}[{i}]" for c in "RGB" for i in range(4)] + ["VGA_HS", "VGA_VS"]
rows = []
for index, endpoint in enumerate(endpoints):
    marker = f"OUTPUT_PATH {endpoint}"
    start = log.find(marker)
    end = log.find("OUTPUT_PATH ", start + len(marker))
    block = log[start:end if end >= 0 else log.find("FF_TO_FF_PATHS", start)]
    match = re.search(r"Worst case slack is\s+(-?\d+(?:\.\d+)?)", block)
    if not match:
        raise SystemExit(f"no setup slack found for {endpoint}")
    slack = float(match.group(1))
    if slack < 0:
        raise SystemExit(f"timing violation at {endpoint}: slack {slack} ns")
    rows.append(f"{endpoint}: setup slack {slack:.3f} ns (40 ns max-delay constraint)")
ff_block = log.split("FF_TO_FF_PATHS", 1)[1]
ff_match = re.search(r"Worst case slack is\s+(-?\d+(?:\.\d+)?)", ff_block)
if not ff_match:
    raise SystemExit("no setup slack found for FF-to-FF path")
ff_slack = float(ff_match.group(1))
if ff_slack < 0:
    raise SystemExit(f"FF-to-FF setup timing violation: slack {ff_slack} ns")
rows.append(f"Worst FF-to-FF setup slack: {ff_slack:.3f} ns (20 ns clock constraint)")
result_path.write_text("\n".join(rows) + "\n", encoding="utf-8")
PY
assert_inputs_unchanged

for file in pbl03.map.summary pbl03.fit.summary pbl03.sta.summary pbl03.sta.rpt; do
    source="$quartus_project_out/$file"
    [[ -s "$source" ]] || fail "Quartus report missing: $source"
    mkdir -p "$out_dir/quartus"
    cp -- "$source" "$out_dir/quartus/$file"
done
quartus_output="$quartus_project_out"
while IFS= read -r report; do
    [[ -s "$report" ]] || continue
    cp -- "$report" "$out_dir/quartus/$(basename -- "$report")"
done < <(find "$quartus_output" -maxdepth 1 -type f \( -name '*.sta.rpt' -o -name '*.fit.rpt' -o -name '*.map.rpt' \) | LC_ALL=C sort)

# Quartus emits trailing spaces in tables and its license banner. Keep report
# content intact while removing only horizontal whitespace before line endings,
# so the committed evidence passes the repository's whitespace check.
python3 - "$out_dir" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
for path in root.rglob("*"):
    if path.is_file() and path.suffix in {".log", ".rpt", ".summary"}:
        data = path.read_bytes()
        lines = data.splitlines(keepends=True)
        normalized = b"".join(re.sub(rb"[ \t]+(?=\r?\n$)", b"", line) for line in lines)
        if normalized:
            normalized = normalized.rstrip(b"\r\n") + b"\n"
        if normalized != data:
            path.write_bytes(normalized)
PY

python3 - "$out_dir" "$head_sha" "$input_fingerprint" "$utc_start" "$quartus_version" "$quartus_warning_count" <<'PY'
from datetime import datetime, timezone
from pathlib import Path
import sys

out = Path(sys.argv[1])
head, fingerprint, start, quartus_version, quartus_warning_count = sys.argv[2:]
regression = (out / "regression.log").read_text(encoding="utf-8", errors="replace")
report = (out / "quartus-paths.log").read_text(encoding="utf-8", errors="replace")
markers = [line for line in regression.splitlines() if "RUN PASS " in line]
end = datetime.now(timezone.utc).isoformat()
summary = f"""# Pacote técnico reproduzível PBL03

## Proveniência

- Git HEAD no início: `{head}`
- Estado inicial do worktree: registrado em `worktree-status-start.txt` (`clean` significa limpo; texto Git indica alterações locais).
- Fingerprint SHA-256 dos inputs: `{fingerprint}` (`input-sha256.txt`, calculado antes das verificações).
- Início UTC: `{start}`
- Fim UTC: `{end}`
- Quartus: `{quartus_version.strip()}`
- Quartus compile reported {quartus_warning_count} top-level warning messages; see `quartus-compile.log` for details.
- Fontes Quartus ativas: `{len((out / 'active-sources.txt').read_text().splitlines())}` caminhos em `active-sources.txt`, conferidos contra QSF e manifesto.
- Periférico VGA professor: `vga-upstream.sha256` confere com `vendor/vga/UPSTREAM.md`.
- Slacks pós-fit: ver `timing-results.txt`; todos os 14 endpoints VGA e o pior caminho FF→FF precisam ter slack não negativo sob as constraints existentes.

## Comandos e resultados

1. `python3 verification/check_pbl03_sources.py` — PASS; log `source-check.log`.
2. `./sim/run_pbl03_regression.sh` — PASS; log agregado `regression.log`; log próprio do runner `regression-runner.log`.
   Marcadores PASS observados: {len(markers)}; ver log para Icarus/VPI e Verilator.
3. `quartus_sh --flow compile quartus/pbl03` — PASS; `quartus-compile.log` e relatórios atuais em `quartus/`.
4. TimeQuest detalhado: 14 endpoints VGA e consulta FF→FF; `quartus-paths.log`.
5. `git diff --check` — PASS; log `diff-check.log`.
6. `artifact-sha256.txt` valida as evidências finais com `sha256sum -c`.

## Limitações e entregas externas

- Não foi realizado teste físico da DE10-Lite nem do monitor VGA nesta execução.
- O modelo oficial de relatório do tutor não estava disponível no repositório e não está incluído.
- Compilação e TimeQuest são evidências de ferramenta; não demonstram operação física.
- O estado/fingerprint descreve o snapshot verificado. Para repetir, execute `./verification/package_pbl03_release.sh` na raiz do repositório.
"""
(out / "release-summary.md").write_text(summary, encoding="utf-8")
PY

assert_inputs_unchanged
utc_end=$(date -u +%Y-%m-%dT%H:%M:%SZ)
printf '\nPackage end UTC: %s\nInput fingerprint: %s\n' "$utc_end" "$input_fingerprint" >> "$out_dir/release-summary.md"
(
    cd "$out_dir"
    find . -type f ! -name artifact-sha256.txt ! -name artifact-hash-check.log -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum > artifact-sha256.txt
    sha256sum -c artifact-sha256.txt > artifact-hash-check.log
)
echo "PASS: release package created at $out_dir"
