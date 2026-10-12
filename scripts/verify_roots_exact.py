#!/usr/bin/env python3
"""TASK-005 / DEC-031: exhaustive software evidence, NOT RTL simulation.

The candidate models the restoring datapath with bounded integer wires.
The oracle compares algebraic roots with half-integers using only signed
integer comparisons and squares. It never uses candidate S/E/Q/r.
Default execution checks every signed8 coefficient triple and both full
primitive input domains. No third-party dependencies are required.
"""
from __future__ import annotations

import hashlib
import json
import platform
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def unsigned(value: int, width: int) -> int:
    if not 0 <= value < (1 << width):
        raise AssertionError(("unsigned wire overflow", value, width))
    return value


def signed(value: int, width: int) -> int:
    if not -(1 << (width - 1)) <= value < (1 << (width - 1)):
        raise AssertionError(("signed wire overflow", value, width))
    return value


def sqrt_restoring(radicand: int) -> tuple[int, int]:
    unsigned(radicand, 17)
    root = remainder = 0
    for pair_index in range(8, -1, -1):
        pair = (radicand >> (pair_index * 2)) & 3
        trial = unsigned((root << 2) | 1, 11)
        temporary = unsigned((remainder << 2) | pair, 11)
        difference = temporary - trial
        accepted = difference >= 0
        remainder = unsigned(difference if accepted else temporary, 10)
        root = unsigned((root << 1) | int(accepted), 9)
    return root, remainder


def divide_restoring(dividend: int, divisor: int) -> tuple[int, int, bool]:
    unsigned(dividend, 9)
    unsigned(divisor, 8)
    zero = divisor == 0
    effective_divisor = divisor if not zero else 1
    quotient = remainder = 0
    for bit_index in range(8, -1, -1):
        temporary = unsigned((remainder << 1) | ((dividend >> bit_index) & 1), 9)
        difference = temporary - effective_divisor
        accepted = difference >= 0
        remainder = unsigned(difference if accepted else temporary, 8)
        quotient = unsigned((quotient << 1) | int(accepted), 9)
    return (0, 0, True) if zero else (quotient, remainder, False)


def reference_round(a: int, b: int, delta: int, branch: int) -> int:
    """Binary-search half-integer boundaries independently of the datapath.

    sign(x_branch-(k+1/2)) = sign(a)*sign(branch*sqrt(delta)-H),
    H=b+a*(2*k+1). sqrt(delta) is compared with an integer h by
    first considering h's sign, then comparing delta and h*h.
    Equality is handled immediately, including negative half-integers.
    """
    low, high = -129, 129
    a_sign = 1 if a > 0 else -1
    while low < high:
        k = (low + high) // 2
        h = b + a * (2 * k + 1)
        radical_threshold = h if branch == 1 else -h
        if radical_threshold < 0:
            cmp_sqrt = 1
        else:
            square = radical_threshold * radical_threshold
            cmp_sqrt = (delta > square) - (delta < square)
        relation = a_sign * branch * cmp_sqrt
        if relation == 0:
            return k + 1 if k >= 0 else k
        if relation < 0:
            high = k
        else:
            low = k + 1
    return low


def reference(a: int, b: int, c: int) -> tuple[int, int, int, bool]:
    delta = b * b - 4 * a * c
    invalid = a == 0 or delta < 0
    if invalid:
        return delta, 0, 0, True
    return delta, reference_round(a, b, delta, 1), reference_round(a, b, delta, -1), False


def build_tables() -> tuple[list[tuple[int, int]], list[list[tuple[int, int, bool]]]]:
    """Memoization of the candidate algorithms, not of the oracle.

    Verify every primitive input against independent mathematical identities
    or Python's divmod. These identities uniquely specify floor sqrt and
    Euclidean division. Cache entries include the complete exact remainders.
    """
    square_roots = []
    for radicand in range(1 << 17):
        root, remainder = sqrt_restoring(radicand)
        if not (root * root <= radicand < (root + 1) * (root + 1)):
            raise AssertionError(("sqrt floor", radicand, root))
        if remainder != radicand - root * root or not 0 <= remainder < 2 * root + 1:
            raise AssertionError(("sqrt identity", radicand, root, remainder))
        square_roots.append((root, remainder))
    division = []
    for divisor in range(256):
        row = []
        for dividend in range(512):
            result = divide_restoring(dividend, divisor)
            expected = (*divmod(dividend, divisor), False) if divisor else (0, 0, True)
            if result != expected:
                raise AssertionError(("division", dividend, divisor, result, expected))
            row.append(result)
        division.append(row)
    return square_roots, division


def candidate(a: int, b: int, c: int, square_roots, division):
    square = unsigned(b * b, 15)
    product = signed(a * c, 16)
    four_product = signed(product << 2, 18)
    delta = signed(square - four_product, 18)
    invalid = a == 0 or delta < 0
    root, residual = square_roots[delta if delta >= 0 else 0]
    abs_a = unsigned(abs(a), 8)
    negative_b = signed(-signed(b, 10), 10)
    outputs, metadata = [], []
    for branch in (1, -1):
        numerator = signed(negative_b + branch * root, 10)
        magnitude = unsigned(abs(numerator), 9)
        quotient, remainder, divide_zero = division[abs_a][magnitude]
        positive_correction = numerator * branch > 0
        up = (quotient & 1) and (remainder != 0 or residual == 0 or positive_correction)
        result_magnitude = unsigned((quotient >> 1) + int(up), 9)
        negative = (numerator < 0) != (a < 0)
        result = signed(-result_magnitude if negative else result_magnitude, 9)
        outputs.append(0 if invalid else result)
        metadata.append((numerator, quotient, remainder, residual, positive_correction, divide_zero))
    return (delta, outputs[0], outputs[1], invalid), metadata


def git_state() -> dict:
    def run(*args):
        return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()
    try:
        return {"head": run("rev-parse", "HEAD"), "worktree_dirty": bool(run("status", "--porcelain"))}
    except (OSError, subprocess.CalledProcessError):
        return {"head": None, "worktree_dirty": None}


def main() -> int:
    started = time.monotonic()
    timestamp = datetime.now(timezone.utc).isoformat()
    print("Building and verifying all 131072 sqrt and 131072 division inputs...", flush=True)
    square_roots, division = build_tables()
    print(f"Primitive domains passed in {time.monotonic() - started:.2f}s; starting 256^3 triples.", flush=True)
    counts = {"total": 0, "valid": 0, "invalid": 0, "a_zero": 0, "negative_delta_nonzero_a": 0,
              "root_comparisons": 0, "divergences": 0}
    examples = []
    directed = {}

    def remember(category, a, b, c, expected):
        directed.setdefault(category, {"category": category, "a": a, "b": b, "c": c,
                                       "delta": expected[0], "x1": expected[1], "x2": expected[2],
                                       "domain_error": expected[3]})

    # Named witnesses are evaluated by the independent oracle, not hardcoded outputs.
    for category, triple in (
        ("a_zero", (0, -128, 127)), ("negative_discriminant", (1, 0, 1)),
        ("zero_discriminant", (1, 2, 1)), ("positive_half_tie", (2, -3, 1)),
        ("negative_half_tie", (2, 3, 1)), ("negative_a_branch_order", (-1, 0, 1)),
        ("zero_root_and_positive_128", (1, -128, 0)), ("minimum_coefficients", (-128, -128, -128)),
        ("maximum_discriminant", (-128, -128, 127)), ("minimum_discriminant", (-128, 0, -128)),
        ("maximum_coefficients", (127, 127, 127)), ("sqrt_perfect", (1, 0, -4)),
        ("sqrt_nonperfect", (1, 0, -2)), ("mixed_sign_roots", (1, 1, -1)),
    ):
        expected = reference(*triple)
        got, _ = candidate(*triple, square_roots, division)
        if got != expected:
            raise AssertionError(("directed", category, got, expected))
        remember(category, *triple, expected)

    # Exhaust every coefficient, including invalid inputs. Candidate tables are
    # preverified complete domains; the reference does not access either table.
    for a in range(-128, 128):
        abs_a = abs(a)
        division_row = division[abs_a]
        for b in range(-128, 128):
            b_square = b * b
            for c in range(-128, 128):
                # Bounded datapath delta, computed independently from oracle below.
                product = a * c
                delta = b_square - (product << 2)
                if not (-16384 <= product <= 16384 and -131072 <= delta < 131072):
                    raise AssertionError(("datapath width", a, b, c))
                expected_delta = b ** 2 - 4 * a * c
                invalid = (a == 0) or (delta < 0)
                expected_invalid = a == 0 or expected_delta < 0
                counts["total"] += 1
                if invalid:
                    counts["invalid"] += 1
                    counts["a_zero" if a == 0 else "negative_delta_nonzero_a"] += 1
                    # Exercise actual candidate zero-divisor and output masks too.
                    got, _ = candidate(a, b, c, square_roots, division)
                    expected = (expected_delta, 0, 0, expected_invalid)
                    if got != expected:
                        counts["divergences"] += 1
                        if len(examples) < 20:
                            examples.append({"abc": [a, b, c], "got": got, "expected": expected})
                    continue
                counts["valid"] += 1
                root, residual = square_roots[delta]
                for branch in (1, -1):
                    numerator = -b + branch * root
                    magnitude = abs(numerator)
                    if not 0 <= magnitude <= 413:
                        raise AssertionError(("numerator width", a, b, c, numerator))
                    quotient, remainder, divide_zero = division_row[magnitude]
                    if divide_zero or quotient * abs_a + remainder != magnitude:
                        raise AssertionError(("division application identity", a, b, c))
                    correction_positive = numerator * branch > 0
                    up = (quotient & 1) and (remainder != 0 or residual == 0 or correction_positive)
                    rounded = (quotient >> 1) + int(up)
                    result = -rounded if ((numerator < 0) != (a < 0)) else rounded
                    expected_root = reference_round(a, b, expected_delta, branch)
                    counts["root_comparisons"] += 1
                    if result != expected_root or not -256 <= result <= 255:
                        counts["divergences"] += 1
                        if len(examples) < 20:
                            examples.append({"abc": [a, b, c], "branch": branch,
                                             "got": result, "expected": expected_root})
                    if remainder == 0:
                        category = (f"branch_{'plus' if branch == 1 else 'minus'}_r0_"
                                    f"{'perfect' if residual == 0 else 'irrational'}_"
                                    f"{'positive' if correction_positive else 'nonpositive'}_correction_"
                                    f"{'odd' if quotient & 1 else 'even'}_quotient")
                        if category not in directed:
                            expected = reference(a, b, c)
                            remember(category, a, b, c, expected)
                if delta != expected_delta or invalid != expected_invalid:
                    counts["divergences"] += 1
                if root * root + residual != delta:
                    raise AssertionError(("sqrt application identity", a, b, c))
        if (a + 129) % 8 == 0:
            print(f"a={a:4d}; triples={counts['total']:,}; mismatches={counts['divergences']}; "
                  f"elapsed={time.monotonic() - started:.1f}s", flush=True)

    if counts["total"] != 256 ** 3 or counts["valid"] + counts["invalid"] != counts["total"]:
        raise AssertionError(("incomplete enumeration", counts))
    vectors = {"decision": "DEC-031", "oracle": "integer half-boundary comparisons",
               "vectors": list(directed.values())}
    vector_path = ROOT / "tests/vectors/roots_directed.json"
    vector_path.write_text(json.dumps(vectors, indent=2) + "\n")
    script_digest = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    report = {"task": "TASK-005", "decision": "DEC-031", "kind": "software_model_exhaustion_not_rtl",
              "result": "PASS" if counts["divergences"] == 0 else "FAIL",
              "started_utc": timestamp, "duration_seconds": round(time.monotonic() - started, 3),
              "command": "python3 scripts/verify_roots_exact.py", "python": sys.version,
              "platform": platform.platform(), "git": git_state(), "script_sha256": script_digest,
              "vectors_sha256": hashlib.sha256(vector_path.read_bytes()).hexdigest(),
              "primitive_domains": {"sqrt_u17_cases": 131072, "divide_u9_u8_cases": 131072,
                                    "result": "PASS"},
              "counts": counts, "directed_vector_count": len(directed),
              "divergence_examples": examples,
              "candidate": "9 restoring stages per primitive, cached complete domains, exact residues retained",
              "oracle": "signed integer comparisons at half-integer boundaries, exact squared thresholds",
              "limitations": ["No RTL simulation, synthesis, timing, or board validation performed.",
                              "F16 is superseded and is not being validated."]}
    (ROOT / "docs/evidence/roots-exhaustive.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"result": report["result"], "counts": counts,
                      "duration_seconds": report["duration_seconds"], "directed_vectors": len(directed)}, indent=2))
    return int(counts["divergences"] != 0)


if __name__ == "__main__":
    raise SystemExit(main())
