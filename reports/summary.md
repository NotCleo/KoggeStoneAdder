# ksa4_reg — Yosys + OpenSTA Results Summary (post hold-fix ECO)

**Flow:** Yosys 0.33 (synthesis) → manual min-delay-padding ECO → OpenSTA 2.4.0
(STA, run via the OpenLane docker image `ghcr.io/the-openroad-project/openlane:ff5509f...`,
since no native `sta` binary is installed). Target library: Nangate45
(typical / slow / fast corner `.lib` from the OpenSTA upstream examples).
Constraint: 2.0 ns clock (500 MHz), 0.10 ns uncertainty, 0.30 ns latency,
0.40 ns I/O delays.

**Functional verification:** Icarus Verilog exhaustive TB (512 vectors) passes
on the RTL **and** on the post-ECO gate-level netlist simulated against the
Nangate45 cell models (`stdcells.v`) — 512/512, 0 mismatches, both runs.

## Hold-fix ECO

Initial STA on the raw synthesis netlist (`ksa4_netlist.v`) showed a
fast-corner hold violation: worst slack **−0.0354 ns** at `_49_/D` (sum[0]
output flop); all violating paths ended at the 5 output-register D pins
(`_49_`–`_53_`). Fix: BUF_X1 min-delay padding chains inserted at those D pins
in `netlist/ksa4_netlist_holdfix.v` — 2 buffers on sum[1]/sum[2]/sum[3], 4
buffers on sum[0] and cout (their short paths needed more padding). 14 BUF_X1
total. All STA reports below are for the **fixed** netlist.

## Area (Yosys `stat`, typical lib)

| Metric | Pre-fix (`yosys_area.rpt`) | Post-fix (`yosys_area_holdfix.rpt`) |
|---|---|---|
| Total cells | 34 (line 553) | **48** (line 55) |
| Chip area | 98.952 µm² (line 564) | **110.124 µm²** (line 67) |

Post-fix cell mix: 14× DFFR_X1, 14× BUF_X1 (hold fix), 6× XNOR2_X1, 2× each of
AND2_X1, AOI21_X1, NAND2_X1, NOR2_X1, OAI21_X1, OR2_X1, XOR2_X1.

## Setup (max-path) — worst path per corner, post-fix

| Corner | Worst path | Data arrival | Setup slack | Source |
|---|---|---|---|---|
| slow | reg `_58_` (b[0] flop) → reg `_53_` (cout flop) | 1.5131 ns | **+0.5313 ns (MET)** | setup_slow.rpt lines 31, 44 |
| typical | reg `_53_` → port `cout` | 0.3945 ns | **+1.4055 ns (MET)** | setup_typ.rpt lines 13, 25 |
| fast | reg `_53_` → port `cout` | 0.3546 ns | **+1.4454 ns (MET)** | setup_fast.rpt lines 13, 25 |

The slow-corner critical path now runs through the full Kogge-Stone carry
chain into the cout flop *including its 4 hold buffers*: setup slack paid
≈0.30 ns for the ECO (+0.8332 → +0.5313 ns) — an explicit, measured
hold-vs-setup trade-off, still comfortably met at 500 MHz.

## Hold (min-path) — worst path per corner, post-fix

| Corner | Worst path | Hold slack | Source |
|---|---|---|---|
| slow | reg `_62_` → … → reg `_49_` | +0.2904 ns (MET) | hold_slow.rpt line 26 |
| typical | — | +0.0800 ns (MET) | hold_typ.rpt line 31 |
| fast | reg `_56_` → … → reg `_51_` (sum[2] flop) | **+0.0064 ns (MET)** | hold_fast.rpt line 30 |

Fast-corner hold is now met at every endpoint (verified with
`report_checks -path_delay min -slack_max 0.10 -endpoint_count 50`). The
+0.0064 ns worst margin is thin but positive — typical of hold fixing, which
pads only to just-met since every extra buffer costs setup slack and area; the
0.10 ns clock uncertainty already inside the check provides the guard band.

## WNS / TNS (setup/max paths)

wns 0.00 / tns 0.00 at all three corners (`wns_*.rpt` / `tns_*.rpt`). Note
these OpenSTA commands cover max (setup) paths only; hold status comes from
the `hold_*.rpt` min-path reports, which are now all MET.

## Power (typical, `report_power`, vectorless — rough estimate only)

Post-fix total: **5.17e-05 W (≈51.7 µW)** (`power_typ.rpt` line 9), up from
4.53e-05 W pre-fix due to the 14 added buffers. Default activity assumptions,
no SAIF/VCD — not signoff-quality numbers.

## Cross-corner finding

Setup slack degrades toward the slow corner (+1.4454 fast → +1.4055 typ →
+0.5313 ns slow) while hold slack tightens toward the fast corner (+0.2904
slow → +0.0800 typ → +0.0064 ns fast). Pre-fix, the fast corner had a real
hold violation (−0.0354 ns) — fixed by min-delay padding at the measured cost
of 0.30 ns slow-corner setup slack, 11.172 µm² area, and ~6 µW estimated
power. Setup is bounded by the slow library and hold by the fast library,
which is exactly why dual-corner STA is required.

## Multicycle paths

None declared, deliberately: every register-to-register path in this
single-stage registered adder is a genuine single-cycle path.
