# AXI4 VIP Future Improvement Plan — Deadlock & Stress Coverage

**Status**: Planning document — **rev 3 (post adversarial review, rounds 1+2, 12 verdicts)**
**Baseline**: `main @ 9d2f58d` (2026-04-14)
**Scope**: Strengthen deadlock, livelock, and stress verification of the AXI4 VIP.

> Rev 3: incorporates all round-2 refutations. Biggest change: the plan is now
> split into **Track A (feasible on the current bench)** and **Track B
> (blocked on a real interconnect)** — see §1.1. Shell-test remediation is now
> "delist first, rebuild later" and covers all 5 shell tests, not 2.

---

## 1. Executive Summary

Adversarial review (4 conclusions × 3 independent lenses) confirmed every
*diagnosis* below against the code, and refuted the *remedies* of rev 1/2
where they were mis-scoped. Confirmed facts:

1. **No deadlock stimulus tests exist**; lookalikes are bounded-tiny,
   conceptual, minimal, or dead code (§3.1).
2. **The hang-detection chain is asymmetric and self-defeating**: dead SVA
   (weak `##[1:$]`), silent BFM bail-outs — including a **fabricated
   B-response** and a mirror **fabricated AW-accept** on the slave side — and
   sticky deadlock/livelock flags that fail even recovered runs (§2.1, §3.2).
3. **Five "combo stress" tests are shells** (one write + one read), each
   running 15–30 regression instances of fake PASS, recorded as
   "PASS (v2.8 fixed)" in `doc/testcase_matrix.csv` (§3.3).
4. **Git archaeology**: full implementations existed. `7b21652` had 298/247-line
   combo tests; `61a5f9f` had bounded assertions. Commits `6caa6cb` /
   `ad38c95` ("fix all regression test issues") deleted/degraded them.
   Everything in this plan is a *re-bring-up with triage*, not greenfield.

### 1.1 Structural constraint (drives the whole plan)

`top/hdl_top.sv:521-586` connects master[j]↔slave[j] **1-to-1 by direct
assign**. No interconnect is instantiated: `top/axi4_smart_interconnect.sv`
exists but appears in no compile list (and is OR-based combinational —
unusable for arbitration as-is); `bm/axi4_bus_matrix_ref.sv` is a zero-time
address-decode function with no clock, queue, or arbiter.

**Consequence**: scenarios that require real multi-master contention —
cyclic-dependency deadlock, same-ID head-of-line blocking across slaves,
hotspot arbitration fairness — are physically impossible to stimulate on this
bench. They form **Track B**, gated on an interconnect decision (§6.3).
Everything else — hang/backpressure/recovery, outstanding saturation,
exclusive livelock, throttling, soak — works on the 1:1 bench: **Track A**.

---

## 2. Current Capability Inventory

(unchanged from rev 2 except corrections; key rows only)

| Area | Status | Evidence |
|---|---|---|
| QoS / starvation | starvation-prevention has a real forward-progress `uvm_error` | `virtual_seq/axi4_virtual_qos_starvation_prevention_seq.sv:138-156` |
| Outstanding | `OUTSTANDING_FIFO_DEPTH=16`; `axi4_master_max_outstanding_seq` is dead code (pkg-included, never started) | `pkg/axi4_globals_pkg.sv:67`, `seq/master_sequences/axi4_master_seq_pkg.sv:193` |
| Exclusive | 16-entry monitor table, single-master tests only | `slave/axi4_slave_driver_proxy.sv:89` |
| Topology | 1:1 direct wiring, no interconnect instantiated | `top/hdl_top.sv:521-586` |

### 2.1 Hang-detection landscape (all claims code-verified by review)

| Layer | Behavior | Holes |
|---|---|---|
| Perf-metrics heuristic (`env/axi4_performance_metrics.sv:328-354`, polled 10us, created unconditionally `env/axi4_env.sv:146`) | 1ms no-progress → `deadlock_detected` + warning; flags consumed in **every** test's report-phase PASS/FAIL (`:483-509`) | **Sticky**: flags never clear on recovery (`:337-341`) — a stall >1ms that fully recovers still FAILs; livelock latch fires at magic `pending_writes>50 && pending_reads>50` (`:349-353`) — 10 masters × depth 16 = 160 pending trips it by design; static counters survive reset; no channel diagnosis; wedged runs die at the global fatal before report-phase |
| Base-test watchdog (`test/axi4_base_test.sv:492-513`) | `#DEFAULT_TEST_TIMEOUT` → `uvm_fatal` | `DEFAULT_TEST_TIMEOUT` doubly defined: `include/axi4_test_defines.svh:14`=10s vs `test/axi4_test_defines.svh:11`=10ms, `ifndef`-guarded, effective value = include-order accident; fatal carries no diagnosis |
| Master driver BFM | AR>1000cyc and R>50000cyc raise `uvm_error` (`axi4_master_driver_bfm.sv:276, 304-335`) | AW/W/B bail out **silently** (errors commented at `:156/:196/:223`); after B timeout the BFM still samples `bid/bresp` and pulses `bready` — **fabricates a response** (`:222-238`); wait loops have **no aresetn escape** — the bail-outs are currently the only way drivers survive mid-burst reset |
| Slave driver BFM | mirror of the above (commented errors `axi4_slave_driver_bfm.sv:170-464`) | after AW bail-out it samples garbage into `mem[]`, increments index, asserts awready — **fabricated accept** (`:181-209`); the B-phase WLAST wait has **no bail-out at all** (`while(mem_wlast[j]!=1)`); `j/j1/mem_*` are static and not cleared by reset |
| SVA (`assertions/master_assertions.sv`, `slave_assertions.sv`) | stability/unknown checks active | all 5-channel `*_READY_WITHIN_LIMIT` are weak `##[1:$]` — can never fail (else-messages cite an unused `ready_delay_cycles=1000`); all 10 `*_VALID_STABLE_CHECK` commented out (never green since first commit); `tb_*_assertions.sv` not in `sim/axi4_compile.f` |
| Scoreboard | end-of-test field checks | requires `verified!=0` — a hang test with 0 completed writes sprays ~8 unrelated errors at check-phase; only exemption is the all-or-nothing `disable_end_of_test_checks` |
| KPI plumbing | Jain fairness + p99 latency computed and printed | **print-only, never a PASS/FAIL criterion** (`:432`); master attribution uses `bid[3:0]`/`rid[3:0]` — random sequence IDs, not master indices (`:181,214` vs `awid inside {[0:9]}` in seqs) — fairness/p99 are meaningless in multi-master runs; `pending_*` keyed by ID only → cross-master collisions corrupt latency; tests with "error" in the name auto-set `errors_are_expected` (`:468-476`) → error storms silently pass |

---

## 3. Gap Analysis (all items review-confirmed)

### 3.1 Missing deadlock/stress stimulus

| # | Gap | Track | Verified non-coverage |
|---|---|---|---|
| G1 | Cyclic cross-slave dependency | **B** | impossible on 1:1 bench |
| G2 | Same-ID HOL blocking (slow+fast slave) | **B** | existing same-ARID test = 2 txns, one slave |
| G3 | AW/W skew (W streamed while AW stalled) | A | none |
| G4 | Sustained/infinite response backpressure | A | ready-delay seqs sweep 0–6 cycles; **no master-side RREADY/BREADY knob exists** (`axi4_master_agent_config.sv:47-57`) |
| G5 | Slave permanent hang | A | `near_timeout` stall is a `#delay` in the master seq (self-admitted conceptual, `axi4_master_exception_seq.sv:180-184`) |
| G6 | Burst stops mid-stream (no WLAST ever) | A | none |
| G7 | Multi-master exclusive livelock | A | single-master tests only |
| G8 | Exclusive monitor exhaustion (>16) | A (backlog) | none |
| G9 | Reset from a wedged state + recovery | A | reset tests never start wedged |
| G10 | Outstanding saturated at FIFO-depth boundary | A | seqs use repeat(5)/(7); max_outstanding_seq dead |
| G11 | Hotspot arbitration fairness | **B** | shell test only; KPI attribution broken anyway |

### 3.2 Detection & measurement defects (fix list)

Summarized in §2.1; the fixes are INF-01..07 below. History warning: bounded
assertions were reverted once (`ad38c95`); `VALID_STABLE` has never been green
— stage the bring-up and triage failures instead of re-reverting.

### 3.3 Shell tests — **five**, not two

All verified as one-write-one-read (or near) shells despite their names:

1. `axi4_hotspot_fairness_boundary_error_reset_backpressure_test.sv` (39 lines)
2. `axi4_throughput_ordering_longtail_throttled_write_test.sv` (39 lines)
3. `axi4_stability_burnin_longtail_backpressure_error_recovery_test.sv` ("backpressure phase" = `#100ns`)
4. `axi4_write_heavy_midburst_reset_rw_contention_test.sv` (no reset, no contention; fork with one branch)
5. `axi4_saturation_midburst_reset_qos_boundary_test.sv` (223 lines of config, traffic = 1 write + 1 read)

Each appears in **both** regression lists (`sim/axi4_transfers_regression.list`
and `testlists/…`, 3 bus modes × run_cnt=5) and is recorded as
"PASS (v2.8 fixed)" in `doc/testcase_matrix.csv:131,135,181` — ~150 fake-PASS
regression instances per full run. Full implementations existed at `7b21652`
(298/247 lines: hotspot_many_to_one, long_tail_latency,
write_response_throttling, …) — deleted by `6caa6cb`, recreated as shells by
`ad38c95`. Rebuilds can start from `7b21652`.

---

## 4. Test Plan

### 4.1 Phase 0 — stop the bleeding (near-zero cost, immediate)

* Delist the 5 shell tests from **both** regression lists; mark the classes
  deprecated (or delete); correct `doc/testcase_matrix.csv` and
  `RELEASE_NOTES_v2.8.md` status entries. This ends the coverage over-reporting
  without writing a single test.
* Unify `DEFAULT_TEST_TIMEOUT` (one define, one owner file).
* Delete `test/axi4_stress_reset_test.sv.backup`; revive-or-delete the dead
  `axi4_master_max_outstanding_seq` (revived by ST-A2).
* Decide the Track-B interconnect question (§6.3).

### 4.2 Track A — feasible on the current 1:1 bench

| ID | Test | Scenario | Gates on | Priority |
|----|------|----------|----------|----------|
| DL-A1 | `axi4_deadlock_hang_test` (parameterized) | `hang_mode` ∈ {NEVER_READY_AW, NEVER_READY_AR, NO_B_RESP, NO_R_RESP, STOP_MID_BURST, MASTER_NO_RREADY, MASTER_NO_BREADY} × {bounded, infinite}. **Minimal must-run subset: 14 entries** (7×bounded + 7×infinite); `reset_during_hang` knob only on 2 representative modes (NEVER_READY_AW, NO_R_RESP) — other reset crosses explicitly not run | INF-01,02,04,05,06 | P0 |
| DL-A2 | `axi4_aw_w_skew_test` | W beats for queued writes while AW stalled; sweep skew depth | INF-04 | P1 |
| DL-A3 | `axi4_exclusive_livelock_pingpong_test` | M-pair alternate exclusive RD/WR, mutual monitor invalidation; forward-progress bound | — | P1 |
| ST-A1 | `axi4_outstanding_boundary_sweep_test` | outstanding = depth-1/depth/depth+1, R and W independently, then all masters (1:1, per-master saturation) | INF-05 (else the magic-50 livelock latch red-flags it by design) | P0 |
| ST-A2 | `axi4_wvalid_throttle_longtail_test` (**honest new name** — replaces the ST-02 same-name rewrite) | duty-cycled WVALID + p99 long-tail + per-ID ordering. Note: WVALID throttling is a **new driver capability**, not an existing knob (`wait_count_*` are measurement counters, consumed by nothing) | INF-04, INF-07 (else p99 is garbage) | P1 |
| ST-A3 | `axi4_soak_per_master_test` (reframed ST-04) | 100k+ txns/master on the 1:1 bench, random QoS/PROT/CACHE + ready delays, address-map (bm) response coverage; `reset_storm` knob absorbs old ST-08 | Phase-0 timeout fix; INF-05 | P1 |
| ST-A4 | `axi4_error_storm_recovery_test` | DECERR/SLVERR bursts + X windows during saturation, then clean window. Naming rule: **avoid "error" in stress-test names** or fix the `errors_are_expected` auto-detect first | INF-05 | P1 |

Track-A backlog (P2, not scheduled): exclusive monitor overflow (policy
decision pending), mixed-geometry stress, clk-gate + max-outstanding option on
the existing gating test, trimmed covergroups (outstanding-depth histogram,
ready-delay max bin only; the rest dropped).

### 4.3 Track B — gated on a real interconnect (§6.3)

| ID | Test | Scenario |
|----|------|----------|
| DL-B1 | cyclic cross-slave dependency | G1 |
| DL-B2 | same-ID HOL blocking, slow+fast slaves | G2 |
| ST-B1 | hotspot arbitration fairness + QoS inversion (merges old ST-01/ST-07; `qos_profile` knob UNIFORM/INVERTED) | G11; requires INF-07 for a meaningful Jain criterion; hotspot target must be an all-masters-legal slave per the access matrix (S2/S8), never default S0 |

Do **not** author Track-B tests before the interconnect exists — on the
current bench they would be vacuous passes.

---

## 5. Infrastructure Work Items

| ID | Item | Detail |
|----|------|--------|
| INF-01 | **BFM bail-out remediation** (both sides) | Remove/parameterize silent escapes; kill the fabricated B-response (`axi4_master_driver_bfm.sv:222-238`) and fabricated AW-accept (`axi4_slave_driver_bfm.sv:181-209`); add the missing WLAST-wait bail-out; restore commented `uvm_error`s behind a knob. **Must ship together with**: (a) `aresetn`-abort escapes in every wait loop — today the bail-outs are the only reset-survival mechanism, removing them naïvely hangs the whole reset suite; (b) slave BFM static-state (`j/j1/mem_*`) reset cleanup — else any reset-during-hang run fails on TB residue; (c) a compatibility audit of tests that oversupply reactive slave items (e.g. `axi4_concurrent_error_stress_virtual_seq.sv:72-96` forever-loops) which will hit end-of-test "waiting for awvalid" errors once un-silenced |
| INF-02 | **Disable/demote plumbing** | Fix `disable_timeout_checks` one-shot `#1` read + scope mismatch (`axi4_master_agent_bfm.sv:187-194` vs `set(this,"*",…)` in tests); per-assertion, per-test control (error/x-inject suites judge PASS by `UVM_ERROR==0` and need demotion) |
| INF-03 | **Bounded SVA bring-up (staged)** | Re-bound `*_READY_WITHIN_LIMIT` (both sides) to a parameterized `##[1:bound]`; first-time-enable `*_VALID_STABLE_CHECK`s. Order: after INF-01/02; measure legitimate stalls **after** INF-01 (BFM bail-outs truncate observable stalls today); enable per-test before globally. **Invariant to enforce: SVA bound < BFM timeout < global watchdog** — otherwise the BFM gives up first and the SVA never fires |
| INF-04 | **Hang/throttle knobs, both sides** | `hang_mode_e` covering slave-side {NEVER_READY_AW/AR, NO_B_RESP, NO_R_RESP, STOP_MID_BURST} **and master-side {NO_RREADY, NO_BREADY}** (one enum, matching DL-A1); WVALID duty-cycle throttling as a new driver capability |
| INF-05 | **Detection semantics & diagnostics** (~small edits, no new component) | Un-stick the deadlock/livelock flags (clear on progress-resumption, or window-based judgment) — currently any >1ms stall fails even after full recovery; scale the livelock threshold from configured outstanding depth (replace magic 50); clear static counters on reset; dump the pending-txn table (ID/addr/age) on detection; emit diagnosis before the global fatal; give infinite-hang negative tests a short per-test watchdog so they don't idle for the full global timeout × 3 bus modes in CI |
| INF-06 | **Scoreboard partial exemption** | A per-channel/per-scope end-of-test exemption for hang tests — the current all-or-nothing `disable_end_of_test_checks` (`axi4_scoreboard.sv:988-993`) either sprays ~8 zero-count errors over the hang diagnosis or throws away the recovery verification too |
| INF-07 | **KPI attribution fix** | Tag transactions with true master index at the monitor level; re-key `grant_count`/`pending_*` by (master, ID); make Jain/p99 thresholds actual PASS/FAIL criteria; fix or fence the `"*error*"`-name → `errors_are_expected` auto-pass. Prerequisite for ST-A2/ST-B1 KPIs |

Dropped in review: the standalone watchdog component (rev 1), covergroup
bundle (trimmed to backlog), the same-name shell-test rewrites (replaced by
Phase-0 delisting + honest-named rebuilds).

---

## 6. Roadmap

### Phase 0 — immediate housekeeping (§4.1)
Exit: shell tests delisted from both lists, docs truthful, single timeout
define, interconnect decision made.

### Phase 1 — foundations
INF-01 (with its three co-requisites), INF-02, INF-05, INF-04.
Exit: reset suite still green with bail-outs removed (fail-then-pass evidence
on at least one mid-burst-reset test); DL-A1 prototype (2 hang modes) produces
a diagnosed failure naming the stuck channel, and a bounded-mode PASS **with
recovered-stall runs no longer failing on sticky flags**.

### Phase 2 — Track A rollout
INF-03 staged SVA bring-up; INF-06; INF-07; DL-A1 full 14-entry subset,
ST-A1, DL-A2, DL-A3, ST-A2, ST-A3, ST-A4; regression list + CSV integration.
Exit: full regression green with bounded SVA on non-error-inject sections;
nightly soak green 3 consecutive runs.

### Track B — separate effort, own decision gate (§6.3)
DL-B1/DL-B2/ST-B1 once an arbitrated interconnect exists.

### 6.3 Open decision: the interconnect
Options: (a) integrate an external RTL interconnect as DUT (e.g. a gen_amba
crossbar) with the VIP on its ports — most realistic; (b) build/repair
`axi4_smart_interconnect.sv` into an arbitrated model (currently OR-based
combinational, unusable as-is — significant work); (c) keep the VIP 1:1-only
and formally drop Track B scenarios from scope. **User decision required.**

---

## 7. Definition of Done (unchanged discipline)

1. Fail evidence: fault injected → run FAILS with the new diagnostic (stuck
   channel + endpoint named), log captured.
2. Pass evidence: fault removed → PASS, scoreboard clean (with INF-06
   scoped exemptions where applicable).
3. A wedged bus must never end as an *undiagnosed* fatal.
4. Regression-listed in all applicable bus-matrix modes before "done".
5. Negative tests must respect the CI wall-time budget (short per-test
   watchdog, INF-05).

## 8. Open Questions

* Track-B interconnect option (a)/(b)/(c) — §6.3. **Blocks DL-B*/ST-B1 only.**
* Exclusive-monitor overflow policy (evict-oldest vs deny-EXOKAY) — blocks
  the backlog overflow test only.
* Soak sizing (proposal: 100k txns nightly, 1M weekly).

## 9. Review Provenance

Rev 3 reflects a 2-round, 12-verdict adversarial review (4 conclusions × 3
lenses). All factual diagnoses were independently confirmed against the code;
all remedy designs were revised per the refutations. Line numbers spot-checked
by an independent verifier (a few ±1 offsets corrected). This document is
planning only — no testbench code has been changed.
