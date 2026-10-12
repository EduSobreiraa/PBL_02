#!/usr/bin/env python3
"""TEST-006: arbitrary-precision mathematical oracle, independent of RTL."""
from itertools import product
from pathlib import Path
import random

SEED = 20261011
MASK = (1 << 23) - 1
DIRECTED = [
    (-128, 127, -128, -128),  # mathematical minimum
    (127, -128, 127, -128),   # mathematical maximum
    (0, 0, 0, 0),
    (127, -128, -128, 0),    # x=0 yields c
    (-128, 127, 127, 0),
    (1, -1, 0, 1),          # nonzero terms cancel
    (-1, 0, 1, 1),          # final -1+1: carry=1, y=0
    (1, 0, -1, 1),          # final 1-1: carry=1, y=0
    (1, -2, 1, 1),
    (-1, 2, -1, 1),
    (1, 127, 0, -127),      # large nonzero terms cancel
    (-1, -128, 0, -128),
]
rows = []

def append(kind, values):
    a, b, c, x = values
    y = a * x * x + b * x + c
    subtotal = a * x * x + b * x
    carry = ((subtotal & MASK) + (c & MASK)) >> 23
    assert all(-128 <= v <= 127 for v in values)
    assert -2113536 <= y <= 2097279
    assert -(1 << 22) <= subtotal < (1 << 22)
    rows.append((kind, a, b, c, x, y, carry))

for values in DIRECTED:
    append(0, values)
for values in product((-128, -127, -1, 0, 1, 126, 127), repeat=4):
    append(1, values)
rng = random.Random(SEED)
for _ in range(10000):
    append(2, tuple(rng.randrange(-128, 128) for _ in range(4)))
path = Path(__file__).resolve().parent / 'vectors' / 'y.txt'
path.write_text(''.join(' '.join(map(str, row)) + '\n' for row in rows))
print(f'TEST-006 reference seed={SEED} directed={len(DIRECTED)} cartesian=2401 random=10000 rows={len(rows)} minimum={min(r[5] for r in rows)} maximum={max(r[5] for r in rows)}')
