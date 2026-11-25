#!/usr/bin/env python3
"""Check the PBL03 Quartus source list and documented RTL restrictions."""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = "verification/pbl03_sources.json"
QSF = "quartus/pbl03.qsf"
UPSTREAM = "vendor/vga/UPSTREAM.md"
VGA_SOURCE = "vendor/vga/vga_sync.v"
ALLOWED_RTL_DIRS = (
    "rtl/aritmetica/",
    "rtl/controle/",
    "rtl/display/",
    "rtl/entrada/",
    "rtl/funcao/",
    "rtl/primitivos/",
    "rtl/top/",
    "rtl/video/",
)
CATEGORIES = {"structural", "ff", "fsm", "vendor"}
STRUCTURAL_FORBIDDEN = {
    "assign",
    "always",
    "begin",
    "buf",
    "case",
    "casex",
    "casez",
    "disable",
    "else",
    "end",
    "endcase",
    "for",
    "forever",
    "fork",
    "generate",
    "genvar",
    "if",
    "initial",
    "join",
    "repeat",
    "wait",
    "while",
}
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_$]*$")
MODULE_DECLARATION = re.compile(
    r"\bmodule\s+(?:(?:automatic|static)\s+)?([A-Za-z_][A-Za-z0-9_$]*)\b"
)
QSF_ASSIGNMENT = re.compile(
    r'^\s*set_(?:global|instance)_assignment\s+-name\s+([A-Za-z0-9_]+)\s+(?:"([^"]+)"|(\S+))',
    re.IGNORECASE,
)
QSF_COMMAND = re.compile(r"(?:^|;)\s*([A-Za-z_][A-Za-z0-9_]*)\b")
QSF_VECTOR_TARGET = re.compile(
    r"^\s*set_(?:global|instance|location)_assignment\b.*?\s+-to\s+"
    r"(?P<target>[A-Za-z_][A-Za-z0-9_$]*\[\d+\])\s*$",
    re.IGNORECASE,
)
ALLOWED_QSF_COMMANDS = {
    "set_global_assignment",
    "set_instance_assignment",
    "set_location_assignment",
}
SOURCE_QSF_COMMANDS = {"source", "qip", "read_verilog", "read_vhdl", "read_systemverilog", "read_hdl"}
SHA256_LINE = re.compile(r"^\s*-\s*SHA-256:\s*`?([0-9a-fA-F]{64})`?\s*$", re.MULTILINE)


def _blank_region(source: str, start: int, end: int) -> str:
    """Replace comments or strings with whitespace while retaining line breaks."""
    return "".join("\n" if char == "\n" else " " for char in source[start:end])


def _strip_comments_and_strings(source: str) -> tuple[str, list[str]]:
    """Return source without comments/strings and report unterminated regions."""
    result = list(source)
    errors: list[str] = []
    index = 0

    while index < len(source):
        if source[index] == '"':
            end = index + 1
            while end < len(source):
                if source[end] == "\\":
                    end += 2
                elif source[end] == '"':
                    end += 1
                    break
                else:
                    end += 1
            else:
                errors.append("unterminated string literal")
            end = min(end, len(source))
            result[index:end] = _blank_region(source, index, end)
            index = end
        elif source.startswith("//", index):
            end = source.find("\n", index + 2)
            if end == -1:
                end = len(source)
            result[index:end] = _blank_region(source, index, end)
            index = end
        elif source.startswith("/*", index):
            close = source.find("*/", index + 2)
            if close == -1:
                result[index:] = _blank_region(source, index, len(source))
                errors.append("unterminated block comment")
                break
            end = close + 2
            result[index:end] = _blank_region(source, index, end)
            index = end
        else:
            index += 1

    return "".join(result), errors


def _relative_path(root: Path, raw_path: object, label: str, errors: list[str]) -> str | None:
    if not isinstance(raw_path, str) or not raw_path or "\\" in raw_path:
        errors.append(f"{label}: path must be a non-empty repository-relative POSIX path")
        return None

    pure = PurePosixPath(raw_path)
    if pure.is_absolute() or ".." in pure.parts:
        errors.append(f"{raw_path}: path escapes the repository root")
        return None

    resolved = (root / Path(*pure.parts)).resolve()
    try:
        relative = resolved.relative_to(root.resolve())
    except ValueError:
        errors.append(f"{raw_path}: path escapes the repository root")
        return None

    return relative.as_posix()


def _is_pbl03_source(path: str) -> bool:
    return path == VGA_SOURCE or any(path.startswith(prefix) for prefix in ALLOWED_RTL_DIRS)


def _has_numeric_vector_target(line: str, command_scan: str) -> bool:
    match = QSF_VECTOR_TARGET.fullmatch(command_scan)
    if match is None:
        return False
    start, end = match.span("target")
    return "[" not in line[:start] + line[end:] and "]" not in line[:start] + line[end:]


def _load_manifest(root: Path, errors: list[str]) -> list[dict[str, str]]:
    manifest_path = root / MANIFEST
    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"{MANIFEST}: cannot read manifest: {exc}")
        return []

    if not isinstance(data, list):
        errors.append(f"{MANIFEST}: expected a JSON list of source entries")
        return []

    entries: list[dict[str, str]] = []
    seen_paths: set[str] = set()
    seen_modules: dict[str, str] = {}
    for index, item in enumerate(data):
        label = f"{MANIFEST}[{index}]"
        if not isinstance(item, dict) or set(item) != {"path", "module", "category"}:
            errors.append(f"{label}: expected exactly path, module, and category fields")
            continue

        path = _relative_path(root, item["path"], label, errors)
        module = item["module"]
        category = item["category"]
        if path is None:
            continue
        if path in seen_paths:
            errors.append(f"{path}: duplicate source in {MANIFEST}")
        seen_paths.add(path)
        if not isinstance(module, str) or not IDENTIFIER.fullmatch(module):
            errors.append(f"{path}: invalid expected module name in {MANIFEST}")
            continue
        if not isinstance(category, str) or category not in CATEGORIES:
            errors.append(f"{path}: unknown syntax category in {MANIFEST}")
            continue
        if not _is_pbl03_source(path):
            errors.append(f"{path}: legacy or unapproved source path in PBL03 manifest")
        if path == VGA_SOURCE and category != "vendor":
            errors.append(f"{path}: professor VGA source must use category vendor")
        if path != VGA_SOURCE and category == "vendor":
            errors.append(f"{path}: only {VGA_SOURCE} may use category vendor")
        if module in seen_modules:
            errors.append(
                f"{path}: duplicate module {module}; also declared by {seen_modules[module]}"
            )
        else:
            seen_modules[module] = path
        entries.append({"path": path, "module": module, "category": category})

    return entries


def _qsf_sources(root: Path, errors: list[str]) -> list[str]:
    qsf_path = root / QSF
    try:
        lines = qsf_path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        errors.append(f"{QSF}: cannot read Quartus source list: {exc}")
        return []

    sources: list[str] = []
    seen: set[str] = set()
    for line_number, line in enumerate(lines, 1):
        if line.lstrip().startswith("#"):
            continue

        command_scan, lexical_errors = _strip_comments_and_strings(line)
        for issue in lexical_errors:
            errors.append(f"{QSF}:{line_number}: {issue}")
        if ("[" in line or "]" in line) and not _has_numeric_vector_target(line, command_scan):
            errors.append(
                f"{QSF}:{line_number}: Tcl command substitution with square brackets is unsupported: {line.strip()}"
            )

        for command_match in QSF_COMMAND.finditer(command_scan):
            command = command_match.group(1).lower()
            if command not in ALLOWED_QSF_COMMANDS:
                kind = "source inclusion" if command in SOURCE_QSF_COMMANDS else "Tcl command"
                errors.append(
                    f"{QSF}:{line_number}: unsupported {kind} {command!r}; "
                    f"commands that may add sources are not validated: {line.strip()}"
                )

        match = QSF_ASSIGNMENT.match(line)
        if not match:
            continue
        assignment = match.group(1).upper()
        raw_path = match.group(2) or match.group(3)
        if assignment != "VERILOG_FILE":
            if assignment.endswith("_FILE") or assignment in {"SOURCE", "QIP", "IP", "EDIF"}:
                errors.append(
                    f"{QSF}:{line_number}: unsupported source assignment {assignment} "
                    f"{raw_path!r}; only VERILOG_FILE is validated"
                )
            continue
        resolved = (qsf_path.parent / raw_path).resolve()
        try:
            path = resolved.relative_to(root.resolve()).as_posix()
        except ValueError:
            errors.append(f"{QSF}:{line_number}: Verilog source escapes the repository root")
            continue
        if path in seen:
            errors.append(f"{QSF}:{line_number}: duplicate Verilog source {path}")
        seen.add(path)
        if not _is_pbl03_source(path):
            errors.append(f"{QSF}:{line_number}: PBL02/legacy source is not allowed: {path}")
        sources.append(path)

    return sources


def _check_source(root: Path, entry: dict[str, str], errors: list[str]) -> None:
    path = entry["path"]
    source_path = root / path
    try:
        raw_source = source_path.read_text(encoding="utf-8")
    except OSError as exc:
        errors.append(f"{path}: source file is missing or unreadable: {exc}")
        return

    source, lexical_errors = _strip_comments_and_strings(raw_source)
    for issue in lexical_errors:
        errors.append(f"{path}: {issue}")

    modules = MODULE_DECLARATION.findall(source)
    if len(modules) != 1:
        errors.append(f"{path}: expected exactly one module, found {len(modules)}")
    elif modules[0] != entry["module"]:
        errors.append(
            f"{path}: module is {modules[0]}, expected {entry['module']} from manifest"
        )

    if entry["category"] in {"structural"}:
        tokens = re.findall(r"\b[A-Za-z_][A-Za-z0-9_$]*\b", source)
        for token in tokens:
            if token in STRUCTURAL_FORBIDDEN:
                errors.append(f"{path}: token {token!r} is forbidden in structural modules by REGRAS.md §2")


def _check_ff_frame_backend(root: Path, entries: list[dict[str, str]], errors: list[str]) -> None:
    """Enforce the TASK-047 FF-only table contract in this feature workspace."""
    backend_path = root / "rtl/funcao/coordinate_frame_ram.v"
    if not backend_path.exists():
        return

    try:
        backend = backend_path.read_text(encoding="utf-8")
    except OSError as exc:
        errors.append(f"rtl/funcao/coordinate_frame_ram.v: cannot read FF backend: {exc}")
        return

    source, _ = _strip_comments_and_strings(backend)
    if re.search(r"\baltsyncram\b|\baltsyncram_[A-Za-z0-9_$]+\b", source, re.IGNORECASE):
        errors.append("rtl/funcao/coordinate_frame_ram.v: TASK-047 backend must not instantiate altsyncram")
    unpacked_storage = re.search(
        r"\b(?:reg|wire|logic)\s+(?:signed\s+)?(?:\[[^\]]+\]\s*)?"
        r"[A-Za-z_][A-Za-z0-9_$]*\s*\[[^\]]+\]",
        source,
    )
    if unpacked_storage:
        errors.append("rtl/funcao/coordinate_frame_ram.v: TASK-047 backend must not declare unpacked storage arrays")

    required = {
        "rtl/funcao/coordinate_frame_ram.v": "coordinate_frame_ram",
        "rtl/funcao/coordinate_frame_ff_bank64.v": "coordinate_frame_ff_bank64",
        "rtl/funcao/coordinate_frame_word_ff.v": "coordinate_frame_word_ff",
        "rtl/funcao/coordinate_frame_mux64_41.v": "coordinate_frame_mux64_41",
        "rtl/funcao/coordinate_frame_mux16_41.v": "coordinate_frame_mux16_41",
        "rtl/primitivos/dff_bus41_norst.v": "dff_bus41_norst",
        "rtl/primitivos/dff_bus4_norst.v": "dff_bus4_norst",
        "rtl/primitivos/mux2_bus41_struct.v": "mux2_41",
    }
    actual = {entry["path"]: entry["module"] for entry in entries}
    for path, module in required.items():
        if actual.get(path) != module:
            errors.append(f"{path}: missing required FF-only backend source/module {module} in {MANIFEST}")


def _check_vga_hash(root: Path, errors: list[str]) -> None:
    upstream_path = root / UPSTREAM
    source_path = root / VGA_SOURCE
    try:
        upstream = upstream_path.read_text(encoding="utf-8")
    except OSError as exc:
        errors.append(f"{UPSTREAM}: cannot read professor source record: {exc}")
        return
    match = SHA256_LINE.search(upstream)
    if not match:
        errors.append(f"{UPSTREAM}: missing registered SHA-256 for {VGA_SOURCE}")
        return
    try:
        actual = hashlib.sha256(source_path.read_bytes()).hexdigest()
    except OSError as exc:
        errors.append(f"{VGA_SOURCE}: source file is missing or unreadable: {exc}")
        return
    if actual != match.group(1).lower():
        errors.append(f"{VGA_SOURCE}: SHA-256 differs from {UPSTREAM}")


def check_project(root: Path = ROOT) -> list[str]:
    """Return all source-manifest, syntax, legacy, and VGA-integrity errors."""
    root = Path(root).resolve()
    errors: list[str] = []
    entries = _load_manifest(root, errors)
    qsf_sources = _qsf_sources(root, errors)

    manifest_paths = [entry["path"] for entry in entries]
    if len(manifest_paths) == len(set(manifest_paths)):
        manifest_set = set(manifest_paths)
        qsf_set = set(qsf_sources)
        for path in sorted(manifest_set - qsf_set):
            errors.append(f"{path}: present in manifest but missing from {QSF}")
        for path in sorted(qsf_set - manifest_set):
            errors.append(f"{path}: present in {QSF} but missing from manifest")

    for entry in entries:
        _check_source(root, entry, errors)

    _check_ff_frame_backend(root, entries, errors)
    _check_vga_hash(root, errors)
    return errors


def main() -> int:
    errors = check_project()
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print("PBL03 source check: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
