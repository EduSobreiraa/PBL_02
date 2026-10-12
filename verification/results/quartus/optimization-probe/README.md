# Quartus area optimization probe

## Result

The minimized seven-segment decoder is the only tested candidate that reduced area. It saved 8 LEs, or 0.37% of the 2,187-LE baseline. The minimized `decimal_add3` used 20 more LEs. Combining both candidates used 13 more LEs than baseline.

No production RTL changed. Candidate sources live in timestamped run directories. Each candidate changed only `rtl/decimal_display.v`; QPF, QSF, SDC, device, pins, and all other RTL inputs match the approved Quartus baseline. The input hashes are recorded before Quartus adds its `LAST_QUARTUS_VERSION` metadata to its working QSF.

## Measurements

Quartus Prime 25.1std.0 Build 1129 SC Lite, device 10M50DAF484C7G. Each candidate was compiled three times. The LE count, setup/hold slack, and worst output delay were identical across all three runs.

| Variant | LEs | Change | Minimum setup slack | Minimum hold slack | Worst output delay |
|---|---:|---:|---:|---:|---:|
| Approved baseline | 2,187 | — | 15.669 ns | 0.153 ns | 160.472 ns |
| Minimized `decimal_add3` | 2,207 | +20 | 15.960 ns | 0.148 ns | 153.315 ns |
| Minimized seven-segment decoder | 2,179 | -8 | 14.583 ns | 0.152 ns | 159.983 ns |
| Both minimized | 2,200 | +13 | 14.834 ns | 0.152 ns | 152.984 ns |

The timing columns show the worst values across the three available corners. All candidate setup and hold slacks remained positive. The `decimal_add3` changes reduced worst output delay but increased LE use. The combined candidate also improved output delay but increased LE use. The area objective therefore favors only the decoder candidate among the variants tested.

The baseline counts and reports are in `verification/results/quartus/README.md`. Candidate summaries and timing reports are in `run-20261012T005610Z/`, `run-20261012T010043Z/`, and `run-20261012T010327Z/`. Each run has a manifest, source hashes, compile log, fitted resource summary, and timing reports.

## Functional scope and limits

The generated `decimal_add3` equations match the reference mapping for input digits 0 through 9. A digit-level invariant check confirms that the correction-and-shift operation stays within 0 through 9 for either incoming bit. The decoder equations match the existing active-low segment outputs for all ten valid BCD digits. These checks passed in the probe script.

Neither candidate was run through the complete RTL simulation suite. The minimized functions may differ for internal BCD codes 10 through 15. They are safe to consider only while those codes remain unreachable. Run the display and integrated regressions before adopting a candidate, then repeat the Quartus compile from the approved production project.

The multiplier blocks account for a larger opportunity in the current fitting hierarchy: four `mul_s8_s8` instances use 627 LEs in total, and the `mul_s8_u15` instance uses 408 LEs. These hierarchy counts include each block's child logic and do not overlap. A carry-save or Baugh-Wooley structural design is a stronger next area experiment than the 8-LE decoder reduction, but it needs its own exact-product and timing comparison.

## Reproduction

Run `python3 -B verification/area_optimization_probe.py`. The script checks the minimized truth tables, creates fresh isolated project copies, hashes all project inputs before compilation, runs Quartus fitting and STA, and writes evidence under a new timestamped directory. It does not edit production RTL or the approved baseline evidence.

The first probe attempt is retained in `run-20261012T005501Z/`; its decoder candidate had an incorrectly sized temporary wire and failed compilation. That attempt was excluded from the table. The corrected variants passed three complete fitting and timing runs.
