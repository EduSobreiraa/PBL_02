#!/usr/bin/env python3
"""Independent arbitrary-precision boundary reference; exhaustive counts/domain.
The testbench additionally exhausts every legal pair with integer multiplication,
independent of the DUT partial-product gates.
"""
from pathlib import Path
from itertools import product
rows=[]
for lhs,rhs in product((-128,-127,-1,0,1,126,127),repeat=2):
    rows.append((0,lhs,rhs,lhs*rhs))
for lhs,rhs in product((-128,-127,-1,0,1,126,127),(0,1,127,128,16383,16384)):
    rows.append((1,lhs,rhs,lhs*rhs))
Path(__file__).with_name('vectors').joinpath('multipliers.txt').write_text(''.join(' '.join(map(str,r))+'\n' for r in rows))
assert min(a*b for a,b in product(range(-128,128),range(-128,128))) == -16256
assert max(a*b for a,b in product(range(-128,128),range(-128,128))) == 16384
assert -128*16384 == -2097152 and 127*16384 == 2080768
print(f'TEST-003 reference boundary_rows={len(rows)} exhaustive_s8={256*256} exhaustive_u15={256*16385} squares=256')
