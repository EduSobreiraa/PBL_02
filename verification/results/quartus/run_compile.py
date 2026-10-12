#!/usr/bin/env python3
"""Compile the approved snapshot in a temporary workspace; preserve actual evidence."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'verification/results/quartus'
BIN = Path('/home/edupires/altera_lite/25.1std/quartus/bin')
SOURCES = [f'rtl/{name}.v' for name in (
    'coefficient_input','arithmetic_cells','add_sub','multipliers','polynomial_y',
    'sqrt_u17','divide_u9_u8','quadratic_roots','result_select','decimal_display',
    'status_flags','top_module')] + [f'quartus/pbl02.{ext}' for ext in ('qpf','qsf','sdc')]
workspace = Path(tempfile.mkdtemp(prefix='pbl02-quartus-'))
manifest = {'workspace': str(workspace), 'status': 'RUNNING', 'sources': {}}
for name in SOURCES:
    data = (ROOT/name).read_bytes()
    manifest['sources'][name] = hashlib.sha256(data).hexdigest()
    for base in (workspace, OUT/'source_snapshot'):
        target = base/name
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(data)
command = [str(BIN/'quartus_sh'),'--flow','compile','pbl02']
manifest['command'] = command
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
with (OUT/'version.log').open('w') as log:
    subprocess.run([str(BIN/'quartus_sh'),'--version'],stdout=log,stderr=subprocess.STDOUT,check=True)
with (OUT/'compile.log').open('w') as log:
    result = subprocess.run(command,cwd=workspace/'quartus',stdout=log,stderr=subprocess.STDOUT)
manifest['exit_code'] = result.returncode
manifest['status'] = 'COMPILED' if result.returncode==0 else 'FAILED'
if result.returncode == 0:
    timing_command = [str(BIN/'quartus_sta'), '-t', str(OUT/'report_timing.tcl'), str(OUT)]
    manifest['timing_detail_command'] = timing_command
    with (OUT/'timing-detail.log').open('w') as log:
        timing = subprocess.run(timing_command,cwd=workspace/'quartus',stdout=log,stderr=subprocess.STDOUT)
    manifest['timing_detail_exit_code'] = timing.returncode
    if timing.returncode != 0:
        manifest['status'] = 'TIMING_REPORT_FAILED'
for pattern in ('*.rpt','*.summary','*.smsg'):
    for report in (workspace/'quartus').glob(pattern):shutil.copy2(report,OUT/report.name)
outputs = workspace/'quartus/output_files'
if outputs.exists():shutil.copytree(outputs,OUT/'output_files',dirs_exist_ok=True)
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'status':manifest['status'],'workspace':str(workspace),'exit_code':result.returncode}))
raise SystemExit(result.returncode or manifest.get('timing_detail_exit_code',0))
