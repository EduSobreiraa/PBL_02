#!/usr/bin/env python3
"""Reproduce TEST-010/011 with fixed source scope and recorded Docker identity."""
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tarfile
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parent.parent
SOURCES = [f"rtl/{name}.v" for name in (
    "entrada_coeficientes", "somador_completo", "somador_subtrator", "multiplicadores",
    "polinomio_y", "raiz_quadrada_u17", "divisor_9_por_8", "raizes_quadraticas",
    "seletor_resultado", "exibicao_decimal", "sinalizadores_status", "modulo_principal",
)] + ["testbench/tb_top_module.v"]
RESULTS = ROOT / "verification/results"
LOG = RESULTS / "system-icarus.log"
MANIFEST = RESULTS / "system-icarus.json"
EXPECTED = ("TEST-010/011 PASS scenarios=10 output_checks=660 "
            "reset_partial_full=PASS held_key=PASS extra_capture=PASS flags_displays=PASS")
IMAGE = "hdlc/iverilog:latest"


def main():
    # Invalidate previous success before any operation that can fail.
    MANIFEST.write_text(json.dumps({"status": "RUNNING"}) + "\n")
    LOG.write_text("")
    image = json.loads(subprocess.check_output(
        ["docker", "image", "inspect", IMAGE], text=True))[0]
    image_id = image["Id"]
    archive = io.BytesIO()
    hashes = {}
    with tarfile.open(fileobj=archive, mode="w") as package:
        for name in SOURCES:
            data = (ROOT / name).read_bytes()
            hashes[name] = hashlib.sha256(data).hexdigest()
            member = tarfile.TarInfo(name)
            member.size = len(data)
            package.addfile(member, io.BytesIO(data))
    compile_command = "iverilog -g2012 -Wall -s tb_top_module -o /tmp/system.vvp " + " ".join(SOURCES)
    command = ["docker", "run", "--rm", "-i", image_id, "sh", "-c",
               "mkdir -p /tmp/work && cd /tmp/work && tar -xf - && "
               "iverilog -V && " + compile_command + " && vvp /tmp/system.vvp"]
    result = subprocess.run(command, input=archive.getvalue(), stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT)
    LOG.write_bytes(result.stdout)
    output = result.stdout.decode("utf-8", errors="replace")
    passed = result.returncode == 0 and output.splitlines().count(EXPECTED) == 1
    metadata = {
        "status": "PASS" if passed else "FAIL",
        "executed_at_utc": datetime.now(timezone.utc).isoformat(),
        "backend": "Icarus Verilog/vvp via Docker",
        "image_tag_requested": IMAGE, "image_id_executed": image_id,
        "repo_digests": image.get("RepoDigests", []),
        "command": command, "source_sha256": hashes,
        "log_sha256": hashlib.sha256(result.stdout).hexdigest(),
        "exit_code": result.returncode,
        "seed": None, "stimulus": "deterministic directed TASK-012 testbench",
        "scenarios": 10, "output_checks": 660,
        "expected_pass_marker": EXPECTED,
        "limits": "Functional simulation; no physical timing, synthesis or board evidence.",
    }
    MANIFEST.write_text(json.dumps(metadata, indent=2) + "\n")
    print(metadata["status"] + ": " + str(LOG.relative_to(ROOT)))
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
