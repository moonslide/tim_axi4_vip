# TRACKB_DEBUG_NOTES

Track-B = the VIP driven against the **real commercial fabric IP** (ARM CoreLink
NIC-400 class, delivered under `ext/`) instead of the 1:1 direct wiring in
`hdl_top`. This file is the reference `CLAUDE.md` points at from three places:
the key-documents list, the publish-policy allow-list, and iron rule 2.

**Scope note, written 2026-08-12.** This document was (re)created from facts
measured in a single session. Every claim below is either quoted from a run
performed here or cited to a file:line in the tree. Where the history is not
recoverable from the repo it says so rather than inventing one. Anything added
later should hold to the same standard.

---

## 1. The two worlds, and why a result must always name its world

| | baseline | Track-B |
|---|---|---|
| file list | `sim/axi4_compile.f` | `sim/axi4_compile_fabric_ip.f` (10x10) / `sim/axi4_compile_fabric_ip_4x4.f` (4x4) |
| interconnect | **none** — masters wired 1:1 to slaves | real fabric RTL, `top/hdl_top.sv:817` `u_fabric_ip` |
| who decides responses | `bm/axi4_bus_matrix_ref.sv` — a `uvm_component` **reference model** in the env | the fabric's own decoder and arbiters |
| reset | 1 asserted edge | 16 asserted edges + 8 idle (`top/hdl_top.sv:291`) |

The most common way to misread a result here is to quote a `4x4` or `ENHANCED`
run as if it exercised an interconnect. On a baseline build **it does not**:
`+BUS_MATRIX_MODE` only selects which address map the *reference model* scores
against. `bm/axi4_bus_matrix_ref.sv:4` is `class axi4_bus_matrix_ref extends
uvm_component`. Verified 2026-08-12: `sim/axi4_compile.f` contains no
`BUS_MATRIX_FABRIC_IP`, no `ext/` path and no `nic400` reference, and
`BUS_MATRIX_FABRIC_IP` appears in only the two fabric file lists above.

So a message like `Address 0x... unmapped/illegal - returning READ_DECERR` in a
baseline log is the reference model talking, not a DUT.

---

## 2. Verified build and run (2026-08-12, VCS W-2024.09-SP1)

From `sim/synopsys_sim/`:

```bash
vcs -full64 -lca -kdb -sverilog +v2k -debug_access+all -ntb_opts uvm-1.2 \
    -override_timescale=1ps/1ps +nospecify +no_timing_check \
    +define+BUS_MATRIX_FABRIC_IP +define+DATA_WIDTH=256 \
    +define+AXI_ID_WIDTH=8 +define+AXI_ID_LAST=255 \
    -Mdir=csrc_trackb -f ../../sim/axi4_compile_fabric_ip.f -o simv_trackb

./simv_trackb +UVM_TESTNAME=<test> +BUS_MATRIX_MODE=ENHANCED +UVM_VERBOSITY=UVM_LOW
```

Measured: exit 0, 0 errors, ~70 s compile + ~1.2 s elab + ~1.6 s link.
Add `+define+FABRIC_IP_4X4` and use `axi4_compile_fabric_ip_4x4.f` for the 4x4
drop; that also flips the bound topology (see §3).

`sim/axi4_compile_fabric_ip.f` pulls in `sim/axi4_compile.f`, then
`sim/fabric_ip_rtl.f` (generated fabric RTL under `ext/`), then
`top/axi4_fabric_ip_wrapper.sv`.

### `run_fabric_smoke.sh` is NOT a Track-B result

`bash ../run_fabric_smoke.sh` from `sim/synopsys_sim/` gives 3/3 PASS
(`unmapped->DECERR`, `S0 base ->OKAY`, `S0 base read->OKAY`). Two limits,
both verified 2026-08-12:

* it compiles `sim/fabric_ip_rtl.f` only — the **10x10** wrapper. A PASS says
  nothing about the 4x4 drop. (`CLAUDE.md` already warns about this.)
* it contains **no VIP at all**. `grep slave_monitor_bfm sim/fabric_ip*.f` is
  empty and `top/tb_fabric_smoke.sv` is a non-UVM bench. Its evidential value
  for any VIP-side change is therefore **zero** — it proves the fabric wrapper
  still elaborates and answers, nothing more.

---

## 3. Track-B test inventory

All Track-B tests derive from `axi4_trackb_smoke_test`, which is also the
Track-B **base class**. It owns two things on their behalf:

* the **topology binding** — the fabric's port count and decode are burned into
  RTL, so the topology is chosen at COMPILE time by `+define+FABRIC_IP_4X4`,
  and a contradicting `+BUS_MATRIX_MODE` is fatal rather than ignored;
* the **test-scoped watchdog** (`trackb_watchdog_timeout`, default 500us).

Because of that, a derived test supplies stimulus by overriding
`trackb_test_body()` — **never** by overriding `run_phase()`, which would
detach the watchdog.

| test | purpose |
|---|---|
| `axi4_trackb_smoke_test` | 10 masters write then read S2 through the fabric |
| `axi4_trackb_4x4_smoke_test` | same for the 4x4 drop |
| `axi4_trackb_cov_sweep_test` | coverage sweep |
| `axi4_trackb_4k_boundary_test` | 4KB-crossing burst at the real fabric (added 2026-08-12) |
| `axi4_trackb_reset_test` | traffic + global resets through the fabric, verdict in `report_phase` (added 2026-08-12) |

Sequences live in `seq/master_sequences/axi4_master_trackb_*`. They all extend
`axi4_master_trackb_base_seq`, which carries the per-fabric region table and
keeps addresses inside the map — a stock random sequence scatters addresses
over the 64-bit space, every one decodes to the fabric's default slave, and the
scoreboard ends with zero verified counts.

---

## 4. Evidence chain (measured 2026-08-12)

### 4.1 Track-B environment is healthy

`axi4_trackb_smoke_test` with `+BUS_MATRIX_MODE=ENHANCED`:

```
UVM_ERROR : 0   UVM_FATAL : 0
Total Writes : 10   Total Reads : 10
Read Latency:  p50 3.12 ns / p95 4.40 ns / p99 4.40 ns
Protocol Issues : 0
TEST RESULT: PASS - All acceptance criteria met
```

### 4.2 Baseline tests DO NOT pass on Track-B — this is a known condition

Three tests, none of them modified, run on the same Track-B binary:

| test | result |
|---|---|
| `axi4_non_blocking_write_read_test` | UVM_ERROR 21 |
| `axi4_id_multiple_writes_different_awid_test` | UVM_ERROR 20 |
| `axi4_blocking_cross_write_read_test` | UVM_ERROR 24 |

All with the same signature — scoreboard end-of-test accounting:

```
WRITE_ADDRESS / WRITE_DATA / WRITE_RESPONSE channel ended with a master
transaction still awaiting its slave partner ... The comparison never
happened - this is NOT a pass.
```

**Consequence for debugging:** a baseline test failing on Track-B is not
evidence about your change. Validate VIP changes with the Track-B *native*
tests, and use the untouched-baseline-test control above before attributing any
Track-B failure to a code change.

**Update 2026-10-21 — non-native tests made to pass per test.** Since the
2026-10-20 decision (§6 item 1), a baseline test is brought onto Track-B by
settings inside `` `ifdef BUS_MATRIX_FABRIC_IP `` in that test only: keyed
pairing on, AxID and ARQOS passthrough checks off, ARREGION/AxUSER checks on,
and an AxUSER manager-identity mask where the stimulus carries one. The
scoreboard pairing key was strengthened for this (W key = address + shape, `c18b6f3`;
AxUSER manager-identity term, `85b851c`; both on main).
Each run prints `SB_CHECK_LEDGER` lines naming every check that was off.
Measured with `UVM_ERROR : 0` and `TEST RESULT: PASS` at seeds 777, 1 and one
runner-random seed each, ENHANCED 10x10 fabric:

| test | Track-B since |
|---|---|
| `axi4_user_based_qos_routing_test` | `dacdf09` |
| `axi4_qos_region_routing_reset_backpressure_test` | `dacdf09` |
| `axi4_qos_bid_queue_race_test` | `dacdf09` |
| `axi4_user_signal_passthrough_test` | `dacdf09` |
| `axi4_qos_basic_priority_test` | branch `exec/20261021-trackb-qos-reorder` |
| `axi4_qos_equal_priority_fairness_test` | branch `exec/20261021-trackb-qos-reorder` |
| `axi4_same_id_nonadjacent_reorder_test` | branch `exec/20261021-trackb-qos-reorder` (consistency check only, see the list header) |

They are in `testlists/axi4_trackb_nonnative.list`. In none of them is any
QoS behaviour verified on Track-B (the fabric has no egress QoS port), and
AxID equality is replaced, not checked. The three tests in the table above
this update have not been re-measured or converted.

### 4.3 The real fabric handles a 4KB-crossing burst cleanly

`axi4_trackb_4k_boundary_test`, ENHANCED. Both pages inside one mapped region
(S2 DDR Shared Buffer) so decode cannot be the variable:

```
Track-B 4KB-CROSSING WRITE S2 addr=0x0000000880001ffc awid=7 awlen=1 awsize=2 (spans 0x0000000880002004)
Track-B 4KB-CROSSING READ  S2 addr=0x0000000880001ffc arid=3 arlen=1 arsize=2 (spans 0x0000000880002004)
Total Writes : 2   Total Reads : 2      (in-page control + crossing, each)
DECERR/SLVERR responses : 0
Protocol Issues : 0   UVM_ERROR : 0     TEST RESULT: PASS
```

No DECERR, no dropped beat, no timeout. This matters because the *baseline*
(direct-wiring) environment shows a crossing read timing out
(`agent/master_agent_bfm/axi4_master_driver_bfm.sv:990`, "timeout waiting for a
read burst"). That is therefore a VIP-side gap, not interconnect behaviour —
there is no interconnect in that build.

### 4.4 Reset through the fabric

`axi4_trackb_reset_test`, ENHANCED: 10 masters write, 2 global resets of 16
asserted cycles each, 10 masters read back.

```
Total Writes : 10   Total Reads : 10   Total Global Resets: 2
UVM_ERROR : 0   UVM_FATAL : 0
TRACK-B RESET TEST PASSED
```

Negative control (late-phase error promoted with
`+uvm_set_severity=*,axi4_performance_metrics,UVM_INFO,UVM_ERROR`):

```
UVM_ERROR : 28
TRACK-B RESET TEST FAILED (UVM_ERROR 0 -> 27, UVM_FATAL 0)
```

i.e. the `report_phase` verdict really does see errors raised after `run_phase`
ended. A `run_phase` verdict cannot, and cannot see `UVM_FATAL` at all.

### 4.5 Manager AxID is 0..15 at the fabric ingress (measured 2026-10-20)

Both delivered fabrics have a 4-bit ingress AxID (VIDWidth 4, `AXI_VID_WIDTH`);
`AXI_ID_WIDTH=8` (10x10) / `6` (4x4) is the egress width the slave agents must
echo, not a manager-side width. `top/hdl_top.sv` used to drop the upper bits
silently: a forced master-0 AWID 0x13 reached the fabric as 0x3, never paired,
and `axi4_trackb_smoke_test` ended with `UVM_ERROR : 3` while still printing
`TEST RESULT: PASS`. The ingress now stops such a run with
`UVM_FATAL [IDW_INGRESS_TRUNC] master 0 AWID 0x13 ... the fabric would see 0x3`
at the first offending AWVALID/ARVALID. No Track-B test in the tree issues an
AxID >= 16 (24 runs identical before/after). Details: `.claude/docs/known-landmines.md`
#59 (local institution file, not in git).

---

## 5. Iron rule 2 — the baseline regression sample

Iron rule 2 requires any BFM/proxy change to re-run the baseline regression
sample (12+ tests) **and** `run_fabric_smoke.sh` before any claim.

The sample referenced there is the **28-test list** that the phase driver
scripts share verbatim — `sim/synopsys_sim/p2_runall.sh`, `p2b_runall.sh`,
`p4_runall.sh` all drive the identical set into `<outdir>/sample/`:

```
axi4_arlen_out_of_spec_test                      axi4_non_blocking_qos_write_read_test [ENHANCED]
axi4_basic_reset_test                            axi4_qos_basic_priority_test [4x4, ENHANCED]
axi4_blocking_cross_write_read_test              axi4_qos_equal_priority_fairness_test [ENHANCED]
axi4_blocking_outstanding_transfer_write_read_test  axi4_qos_saturation_stress_test [ENHANCED]
axi4_blocking_slave_error_write_read_test        axi4_qos_starvation_prevention_test [ENHANCED]
axi4_blocking_unaligned_addr_write_read_test     axi4_qos_with_user_priority_boost_test [ENHANCED]
axi4_blocking_write_read_test                    axi4_saturation_midburst_reset_qos_boundary_test
axi4_error_inject_arvalid_x_test                 axi4_slave_inject_rvalid_x_test
axi4_error_inject_awvalid_x_test                 axi4_stress_reset_test [NONE, 4x4, ENHANCED]
axi4_error_inject_x_drive_test                   axi4_write_heavy_midburst_reset_rw_contention_test
axi4_id_multiple_writes_different_awid_test
axi4_independent_reset_test
axi4_non_blocking_slave_error_write_read_test
axi4_non_blocking_write_read_test
axi4_non_blocking_write_read_response_out_of_order_test
```

Note `run_fabric_smoke.sh` satisfies the letter of the rule but, per §2, proves
nothing about a VIP-side change. When the change is in a BFM, the load-bearing
evidence is the baseline sample plus a Track-B native run.

Prefer LSF for anything larger than the sample:

```bash
python3 axi4_regression.py --lsf --test-list ../../testlists/axi4_transfers_regression.list -p 20 -t 1800
```

**Do not edit the working tree while a regression runs.** Each test folder
invokes VCS against the live tree, so a mid-run edit is compiled in a
half-finished state. Observed 2026-08-12: three runs failed with
`Error-[MFNF] Member not found` from a file being edited at that moment, and
the whole round had to be discarded.

---

## 6. Open items

1. **Baseline tests fail on Track-B (§4.2).** Decided 2026-10-20: non-native
   tests are to be fixed to pass, one test at a time, with per-test settings
   under `` `ifdef BUS_MATRIX_FABRIC_IP `` and a stronger scoreboard pairing key —
   not declared out of scope, and never "fixed" only by switching checks off
   (each run's `SB_CHECK_LEDGER` lines list what is off). Four tests pass on
   Track-B at `dacdf09`, three more on branch `exec/20261021-trackb-qos-reorder`
   (§4.2 update). Still open: the other baseline tests, including the three in
   the §4.2 table, and the 4x4 fabric drop for all of them.
2. **Crossing read times out on the direct-wiring build (§4.3)** while the real
   fabric handles it. VIP-side; not diagnosed.
3. **No clocking blocks anywhere in the interfaces/BFMs.** Monitors read signals
   at the active clock edge, so correct sampling currently depends on the
   drivers happening to use non-blocking assignment. AMBA A3.2.1 defines the
   transfer at the rising edge where VALID and READY are both high, meaning the
   value that met setup *before* that edge; the robust idiom is a clocking block
   with `default input #1step`. Applies to every channel, both monitors.
4. **4x4 Track-B drop is far less exercised than 10x10.** Only
   `axi4_trackb_4x4_smoke_test` targets it, and `run_fabric_smoke.sh` does not
   cover it at all.
5. **History before 2026-08-12 is not recorded here.** The previous version of
   this file is not in the repo or in git history; if a copy exists elsewhere,
   merge it in rather than letting two versions drift.

---

## 7. Publish policy reminder

`ext/` and anything built from it never leaves this machine — see the hard gate
in `CLAUDE.md`. This file references `ext/` by **path only**, which is allowed;
never inline fabric RTL source into it. Before any commit touching Track-B, run
`git status --short` and confirm no `ext/` path appears. Build artifacts
(`simv*`, `csrc*/`, `*.daidir/`) under `sim/synopsys_sim/` embed elaborated
design data and are covered by `.gitignore`; verify with `git check-ignore`
rather than trusting the pattern by eye.
