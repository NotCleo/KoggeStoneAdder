# How to Run

Run everything from the project root (`ksa4_synth_sta/`), in this order.

## 0. Prerequisites

- `yosys`, `iverilog`/`vvp` on PATH
- OpenSTA — either a native `sta` binary, or docker (see step 3)
- Liberty files present in `lib/`: `NangateOpenCellLibrary_{typical,slow,fast}.lib`

## 1. Functional sanity check (RTL simulation)

```bash
iverilog -o ksa4_tb.vvp tb/ksa4_tb.v rtl/ksa4_reg.v
vvp ksa4_tb.vvp
```

Expect: `RESULT: 512 passed, 0 failed` and `ALL TESTS PASSED`.

## 2. Synthesis (Yosys)

```bash
yosys -s scripts/synth.tcl | tee reports/yosys_area.rpt
```

- `-s <file>` runs the script; `tee` saves the full log (incl. the `stat` area
  breakdown) as the area report.
- Outputs: `netlist/ksa4_netlist.v` + `reports/yosys_area.rpt`.

## 3. Static timing analysis (OpenSTA, one run per corner)

With a native `sta` binary:

```bash
sta -exit scripts/run_sta_slow.tcl    # setup-critical corner
sta -exit scripts/run_sta_fast.tcl    # hold-critical corner
sta -exit scripts/run_sta_typ.tcl     # baseline corner
```

- `-exit` quits after the script instead of dropping into the TCL shell.
- Outputs per corner: `reports/setup_*.rpt`, `hold_*.rpt`, `wns_*.rpt`, `tns_*.rpt`.

No native `sta`? Run it from the OpenLane docker image (mount the project dir):

```bash
docker run --rm --user $(id -u):$(id -g) -v $PWD:/work -w /work \
  ghcr.io/the-openroad-project/openlane:<tag> sta -exit scripts/run_sta_slow.tcl
```

## 4. Power estimate (optional, vectorless)

```bash
sta -exit scripts/run_power_typ.tcl
```

Output: `reports/power_typ.rpt` — default-activity estimate, not signoff.

## 5. Check the results

- Look for `slack (MET)` / `slack (VIOLATED)` at the bottom of each
  `setup_*.rpt` and `hold_*.rpt`.
- `reports/summary.md` consolidates everything.

## Note on the two netlists

- `netlist/ksa4_netlist.v` — raw synthesis output; fails hold at the fast corner.
- `netlist/ksa4_netlist_holdfix.v` — final netlist after the manual hold-fix
  ECO; **the `run_sta_*.tcl` scripts point at this one.** To reproduce the
  original violation, temporarily change `read_verilog` in a script back to
  `ksa4_netlist.v`.

To re-verify the fixed netlist at gate level (needs Nangate45 Verilog cell models):

```bash
iverilog -o ksa4_gl.vvp tb/ksa4_tb.v netlist/ksa4_netlist_holdfix.v <path>/stdcells.v
vvp ksa4_gl.vvp
```
