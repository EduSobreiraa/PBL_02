#!/usr/bin/env python3
"""TEST-002: integer reference independent of the gate/ripple implementation.
Rows: kind lhs rhs expected_signed expected_binary_carry.
kind 0: exact y-consumer addition; 1: exact delta subtraction;
kind 2: core-only modular probes outside the public exact consumer contract.
"""
from itertools import product
from pathlib import Path
import random

SEED = 20261011
MASK = (1 << 23) - 1
rows = []

def add(lhs, rhs, kind=0):
    """Calcula a soma esperada e registra os operandos e o carry."""
    mathematical = lhs + rhs
    carry = ((lhs & MASK) + (rhs & MASK)) >> 23
    if kind == 0:
        assert -(1 << 22) <= mathematical < (1 << 22)
        expected = mathematical
    else:
        pattern = mathematical & MASK
        expected = pattern - (1 << 23) if pattern >= (1 << 22) else pattern
    rows.append((kind, lhs, rhs, expected, carry))

def consumers(a, b, c, x):
    """Gera os valores esperados usados pelos cálculos de y e do discriminante."""
    ax2, bx = a * x * x, b * x
    add(ax2, bx)
    add(ax2 + bx, c)
    delta = b * b - 4 * a * c
    assert -65536 <= delta <= 81408
    rows.append((1, b * b, 4 * a * c, delta, 0))

for lhs, rhs in [(0, 0), (-1, 1), (1, 1), (-1, -1), (0, -128), (0, 127)]:
    add(lhs, rhs)
for values in product((-128, -127, -1, 0, 1, 126, 127), repeat=4):
    consumers(*values)
rng = random.Random(SEED)
for _ in range(10000):
    consumers(*(rng.randrange(-128, 128) for _ in range(4)))
# Separa o vai-um binário do overflow com sinal; estes casos testam apenas o núcleo.
for lhs, rhs in [((1 << 22) - 1, 1), (-(1 << 22), -1), (-(1 << 22), -(1 << 22))]:
    add(lhs, rhs, 2)
path = Path(__file__).resolve().parent / 'vectors' / 'add_sub.txt'
path.write_text(''.join(' '.join(map(str, row)) + '\n' for row in rows))
print(f'TEST-002 reference seed={SEED} rows={len(rows)} exact_add={sum(r[0]==0 for r in rows)} delta={sum(r[0]==1 for r in rows)} core_modular={sum(r[0]==2 for r in rows)}')
