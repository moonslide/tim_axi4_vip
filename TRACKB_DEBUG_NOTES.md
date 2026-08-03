# Track-B (NIC-400 fabric DUT) — read-path investigation notes

Status (2026-08-01, re-measured, supersedes everything below): **the read path
is closed.** Reads now reach the fabric egress and return data through it. The
remaining Track-B failures are a different defect class — see
"2026-08-01 re-measurement" immediately below before reading the historical
sections, several of which are now stale.

## 2026-08-01 re-measurement

Build/run exactly as in "How to reproduce". Measured, not inferred:

| observation | earlier | now |
|---|---|---|
| `EGRESS[2] ARVALID` | never asserts | asserts (9 probe cycles, 4 reads) |
| `timeout waiting for rvalid` | 16 | **0** |
| master proxy `READ_DATA_THREAD::Response_received` | never | t=2790 and after |
| `slave_assertions.sv:248 AXI_RD_STABLE_SIGNALS_CHECK` failures | 8 | **0** (after the fix below) |
| UVM_ERROR | 16–17 | 14, all `env/axi4_scoreboard.sv` count comparisons |
| `bash ../run_fabric_smoke.sh` | 3/3 PASS | 3/3 PASS |

So the "Still open" and "The open failure" sections further down are **stale** —
they describe a state that the B-channel handshake fix and the write-task
`join_any`→`join` fix already resolved.

### Root cause closed this session: reactive slave BFM fabricated transactions

`agent/slave_agent_bfm/axi4_slave_driver_bfm.sv`, the AWVALID and ARVALID waits:

```systemverilog
while (arvalid !== 1'b1) begin
  @(posedge aclk);
  if (ar_cycles++ > 50000) begin
    //`uvm_error(name,"timeout waiting for arvalid")
    break;                      // <-- falls through and then acts as if
  end                           //     the handshake had happened
end
```

In `SLAVE_MEM_MODE` the proxy calls these phase tasks from a `forever` loop even
when the bus is idle. After 50000 idle cycles the loop broke out, sampled the
idle bus (`araddr=0`, `arlen=0`), the proxy decoded that to DECERR and then
called `axi4_read_data_phase` anyway — driving a **phantom RVALID that no
manager had requested**. 50000 cycles later the RREADY wait also timed out and
dropped RVALID/RLAST mid-handshake, which is what
`AXI_RD_STABLE_SIGNALS_CHECK` was catching. The failure times (3000550,
3002630, 4000630, 4002710 ps at a 20 ps period) are exact 50000-cycle multiples,
which is the arithmetic proof that the period is the timeout, not the stimulus.

A reactive subordinate has no legitimate timeout on "am I being addressed?".
**Fix applied**: both waits are now unbounded.

CORRECTION (2026-08-02): an earlier version of this paragraph justified the
unbounded waits by saying "hang protection is the base test's
`timeout_watchdog`". That was wrong for Track-B. `axi4_trackb_smoke_test`
overrides `run_phase` and never calls `super.run_phase()`, so
`axi4_base_test`'s watchdog fork was never reached for it -- a hung Track-B run
had NO bound at all and was killed externally with no UVM summary
(`codex_review.md` Finding 6, reproduced at seed 20260802). The Track-B tests
now carry their own bounded watchdog.

Fail-then-pass evidence:

| metric | before | after |
|---|---|---|
| `AXI_RD_STABLE_SIGNALS_CHECK` failures | 8 | **0** |
| `"outside of arvalid"` events (4 are real reads) | 20 | **4** |
| Track-B UVM_ERROR | 14 | 14 (unchanged — separate defect, see below) |
| baseline sample, 16 tests incl. 5 X-injection + 3 reset | 0 UVM_ERROR | 0 UVM_ERROR |

Note the phantoms never reached the scoreboard: the slave monitor gates on
`arvalid` and on `rready`, and neither ever asserts for a phantom. The SVA
failures and the 14 scoreboard errors are therefore **two independent defects**.

### RESOLVED: the 14 scoreboard errors (now 1, and it is not a DUT bug)

The scoreboard was made interconnect-aware (`env/axi4_env_config.sv` knobs
`sb_keyed_pairing`, `axid/axqos/axregion/axuser_passthrough_chk_cfg`, all
defaulting to the old 1:1 behaviour; the Track-B test opts in). Track-B now
reports **1** UVM_ERROR instead of 14, and the remaining one is the long-burst
payload defect in landmine #16, not a fabric problem.

What replaced the checks that were switched off:
* AxID equality was replaced by a **stronger** property that nothing checked
  before: each manager must receive a BID/RID it is still waiting on
  (per-master multiset of issued AxIDs, with late-arriving responses re-tested
  in `check_phase`). Track-B: 4 verified bid + 4 verified rid.
* Pairing is now keyed on (address, len, size, burst) rather than arrival
  order, so arbitration reordering no longer shows up as a data mismatch.

The historical analysis of the 14 errors is kept below for reference.

### Historical: why there were 14 scoreboard errors

Per-field counts (verified/failed) from the run:

```
awid 1/7   awaddr 6/2  awsize 6/2  awlen 6/2  awcache 6/2  bid 0/4
arid 0/8   araddr 6/2  arsize 6/2  arlen 6/2  arcache 6/2  arprot 6/2
arqos 0/8  rid 0/4
```

Three distinct causes, none of them a fabric malfunction:

1. **ID fields (awid/bid/arid/rid, 4 errors) — leading explanation, NOT settled.**
   NIC-400 widens the egress AxID to `{ingress-port, original-id}` — probe
   evidence `EGRESS BVALID bid=0x45` against `INGRESS BVALID bid=0x4`. The
   scoreboard compares master-side and slave-side IDs for equality, which only
   holds for 1:1 direct wiring. The master does get its own ID back correctly
   (`Master rid=RID_9` for `arid=ARID_9`), so fabric routing is right.
   **However** an adversarial review surfaced a VIP-internal mechanism that
   produces the same symptom and has not been eliminated: the slave BFM drives
   `bid <= mem_awid[j]` where `j` is a task-static counter distinct from the
   interface-scope `i` that fills `mem_awid`, and the transfer struct still
   declares IDs as `bit [3:0]` (`pkg/axi4_globals_pkg.sv:350,369,387`) so
   `AXI_ID_WIDTH=8` is truncated at the struct boundary. See
   `.claude/docs/known-landmines.md` #14. Do not close this on the interconnect
   explanation until that is ruled out.
2. **arqos (1 error, 0 verified / 8 failed — can never pass).** The generated
   fabric has QoS ports only on the ingress side; `top/hdl_top.sv:760-761`
   therefore ties the egress `awqos`/`arqos` to 0. NIC-400 consumes QoS for
   arbitration and does not forward it, so this comparison is invalid by
   construction under any interconnect.
3. **Address/size/len/cache/prot (9 errors, 6 verified / 2 failed each).**
   Mispairing, not corruption: the mismatch pairs are
   `Master AWADDR='h8ac1df000 vs Slave AWADDR='h8963f8000` **and the exact
   reverse**. Both are legitimate addresses from this run, swapped. A real
   interconnect arbitrates, so slave-side arrival order need not equal
   master-side order, and the scoreboard pairs positionally.

Fixing these means making the scoreboard interconnect-aware (key-based pairing,
ID-remap tolerance, no AxQOS check) — a scoreboard change, not a BFM change.
It is deliberately NOT bundled with the BFM fix above.

### Final verified state (2026-08-01, end of session)

| suite | result |
|---|---|
| Track-B smoke (10 masters through the NIC-400 fabric) | **0 UVM_ERROR, 0 UVM_FATAL, 0 SVA failures, 0 vacuous checks, TEST RESULT: PASS** |
| `bash sim/run_fabric_smoke.sh` | 3/3 PASS |
| baseline sample, 28 runs (X-injection, reset, mid-burst reset, out-of-order, QoS, all three bus modes) | 28/28 |
| every regression entry carrying `+BUS_MATRIX_MODE=4x4` or `=ENHANCED`, 108 runs | 107/108 |

The single remaining failure, `axi4_user_signal_passthrough_test` under
`+BUS_MATRIX_MODE=4x4`, fails identically on a HEAD (`9d2f58d`) worktree control
run of the same 108 — it is pre-existing and is a stimulus problem, not a VIP
mechanism problem (see `.claude/docs/known-landmines.md` #20). The HEAD control
scored 106/108, so this session removed one long-standing failure and introduced
none.

### Also found, not patched

* FIXED — `test/axi4_base_test.sv:109-116` — `+BUS_MATRIX_MODE=ENHANCED` and
  `BASE` used to set `bus_matrix_mode` without setting `num_masters`/`num_slaves`, unlike the
  sibling `NONE` (`:97-102`) and `SIMPLE` (`:103-108`) cases which do. For
  `axi4_trackb_smoke_test` the run therefore reports `no_of_masters=4` together
  with `bus_matrix_mode=BUS_ENHANCED_MATRIX` while the UVM_INFO claims "will use
  all 10 masters/10 slaves", and the scoreboard computes
  `inferred_master_id = arid_num % 10`, yielding ids 6 and 9 for which no master
  agent exists.

  Deliberately NOT patched, because the obvious fix is not a no-op:
  - The numbers are not always 4. `test/axi4_test_config.sv:56-64` routes any
    test whose name matches `.*qos.*`, `.*user.*`, `.*error_inject.*`,
    `.*concurrent.*`, `.*exception.*` to `ENHANCED_MATRIX_TESTS`, which already
    sets 10/10. For those, `+BUS_MATRIX_MODE=ENHANCED` is a no-op today.
  - The genuinely broken combination is the other one: those same tests run with
    `+BUS_MATRIX_MODE=4x4` get **BASE_BUS_MATRIX with 10 masters/10 slaves**,
    and `test/axi4_base_test.sv:446-449` gives slaves 4..9 the `default:` range
    `0x0 – 0xFFFF_FFFF`, which overlaps S1 Boot_ROM (`:435-436`). Several slave
    agents then claim the same addresses.
  - `testlists/axi4_transfers_regression.list` carries 54 entries with
    `+BUS_MATRIX_MODE=4x4` and many with `=ENHANCED`; resizing the env changes
    agent count, per-master sequence loops, coverage and scoreboard traffic in
    all of them. This needs its own regression, not the sample used here.

  Structurally 10 masters ARE wired: `pkg/axi4_globals_pkg.sv:26,30`
  `NO_OF_MASTERS = 10`, `top/hdl_top.sv:510-519` generates 10 master and 10
  slave interfaces, and the Track-B fabric wrapper is instantiated with
  `.NUM(NO_OF_MASTERS)`. The risk is behavioural, not structural.
* ADDRESSED — `slave/axi4_slave_driver_proxy.sv` `axi4_read_task()` still closes
  its channel fork with `join_any` (converting it to `join` deadlocks the QoS
  read path, measured), but the handles are now `automatic` so the race is gone.
  Original description: the construct the write task was already changed away
  from. `process rd_addr/rd_data` live in the `forever` block of an automatic
  class method, so their storage is per-call, not per-iteration: iteration N+1
  overwrites the handles iteration N's data thread is about to `.await()`.
* 11 files under `test/` are not `` `include ``d in `test/axi4_test_pkg.sv`, so
  `+UVM_TESTNAME=<them>` dies with `INVTST ... not found` (confirmed for
  `axi4_pure_reset_test` and `axi4_x_inject_active_test`). None are in the
  regression list, so this is dead code rather than a live escape.

## How to reproduce

```bash
cd sim/synopsys_sim
vcs -full64 -lca -kdb -sverilog +v2k -debug_access+all -ntb_opts uvm-1.2 \
    -override_timescale=1ps/1ps +nospecify +no_timing_check \
    +define+BUS_MATRIX_NIC400 +define+DATA_WIDTH=256 +define+AXI_ID_WIDTH=8 +define+AXI_ID_LAST=255 \
    +define+NIC400_DEBUG_PROBE \
    -f ../../sim/axi4_compile_nic400.f -o simv
./simv +UVM_TESTNAME=axi4_trackb_smoke_test +BUS_MATRIX_MODE=ENHANCED
```

Standalone fabric check (no UVM, proves the RTL + wrapper are good):
```bash
bash ../run_fabric_smoke.sh      # 3/3 PASS
```

## What is PROVEN good

* **ARM NIC-400 RTL + `axi4_nic400_fabric_wrapper` are correct.**
  `top/tb_fabric_smoke.sv` passes 3/3: unmapped address -> DECERR, S0 write ->
  OKAY, S0 read -> OKAY with the correct RID routed back to ingress 0.
  Treat the ARM RTL as golden; every remaining problem is on the VIP side.
* **Writes flow correctly in the UVM environment.** Probe output:
  `INGRESS[0] AWVALID awaddr=0x89aa61000 awready=1` followed by
  `EGRESS[2] AWVALID awaddr=0x89aa61000` — decoded and routed to the right port.
* **Reads are accepted at the ingress**: `INGRESS[0..3] ARVALID ... arready=1`.

## ROOT CAUSE FOUND AND FIXED: slave B-channel handshake collapse

`agent/slave_agent_bfm/axi4_slave_driver_bfm.sv`, write response phase:

```systemverilog
bvalid <= 1;                        // scheduled
b_cycles = 0;
while(bready === 0) begin           // BREADY already high -> ZERO iterations,
  @(posedge aclk); ...              // no clock edge consumed
end
bvalid <= 1'b0;                     // scheduled in the SAME time step
```

Both non-blocking assignments land in one time step, the deassert wins, and
**BVALID is never observable on the bus**. The write therefore never retires.
`=== 0` additionally treats an X on BREADY as "ready".

It survives against the 1:1 direct wiring because the VIP master happens to
have BREADY low at that moment, so the loop waits a cycle and the pulse
appears. A real interconnect asserts BREADY early, which exposes it.

**Fix** (applied): always consume at least one clock edge after asserting
BVALID, then hold it until BREADY is genuinely sampled high
(`do @(posedge aclk); ... while(bready !== 1'b1);`), and the previously
commented-out `uvm_error` on the bready timeout is restored. The same
X-mishandling (`=== 0`) was corrected on the other slave handshake polls
(awvalid/wvalid/arvalid/rready) — 8 sites.

**Fail-then-pass evidence**

| probe | before fix | after fix |
|---|---|---|
| `EGRESS BVALID` (VIP slave -> fabric) | 0 | **1** |
| `INGRESS BVALID` (fabric -> master) | 0 | **7** |

Writes now retire through the fabric. Baseline regression stays green
(5 tests, 0 UVM_ERROR each), so the fix is safe for the existing suite.

## Still open

`EGRESS ARVALID` is still 0 and the Track-B test still reports 16
`timeout waiting for rvalid`. Only one write retires at the slave, so the
other ingress ports remain blocked. The next thing to check is why the write
data phase completes 9 times out of 13 entries and only 2 of those reach the
write response phase — i.e. the same static-index / FIFO pairing question in
`slave/axi4_slave_driver_proxy.sv` `axi4_write_task()`.

## Earlier evidence chain (kept for reference)

```
t=370 EGRESS[2] AWVALID awaddr=0x89aa61000     write address reaches slave 2
t=410 EGRESS[2] WVALID wlast=1 wready=1        LAST write beat ACCEPTED by the VIP slave
      EGRESS BVALID  = 0  (never)              VIP slave NEVER drives a write response
      INGRESS BVALID = 0  (never)              so the fabric never returns B to the master
      EGRESS ARVALID = 0  (never)              and the read is never issued downstream
```

1. The write reaches the VIP slave and the slave accepts the final beat
   (`wlast=1, wready=1`). The wire-level write is complete.
2. **The VIP slave never asserts BVALID.** The failure is inside the slave
   driver proxy / BFM write-response path, after the write data phase.
3. Because no B ever returns, the fabric's ASIB keeps the write outstanding.
   The ASIB is configured `CyclicDependencyAvoidanceScheme = single_slave`,
   which blocks further requests from that ingress port — so the subsequent
   read is accepted into the ASIB and never issued at any AMIB.
4. The master's B-channel wait bails out silently after 1000 cycles and
   fabricates a response (`axi4_master_driver_bfm.sv:223`, `uvm_error`
   commented out), so step 2 produces **no error message at all**. The only
   visible symptom is the read timeout, 16x `timeout waiting for rvalid`.

**The read stall is a downstream symptom. The defect is the missing write
response.** Fixing the read path directly would be treating the symptom.

## The open failure

`EGRESS[*] ARVALID` is X only at t=10, resolves to 0, and **never asserts**.
So AR is accepted by the ASIB but no read request is ever issued by any AMIB.
Masters then hit `timeout waiting for rvalid`
(`agent/master_agent_bfm/axi4_master_driver_bfm.sv:332`), 16 errors.

## VIP bugs found and patched (keep these regardless)

1. **X-tolerance hole in the slave BFM.**
   `agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:383` waits with
   `while(arvalid === 0)`. When `arvalid` is X the condition is false, so the
   loop exits immediately and the slave proceeds with garbage — it even prints
   `outside of arvalid`. Harmless against the stateless 1:1 wiring, fatal
   against real RTL. Mitigated in `top/hdl_top.sv` by qualifying the six
   handshake controls fed to the fabric with `=== 1'b1`, so the fabric can
   never see X on AWVALID/WVALID/ARVALID/BREADY/RREADY/WLAST.
2. **Reset far too short for real RTL.**
   With `-override_timescale=1ps/1ps` the testbench `clk_period = 10.0` is
   10 **ps**, and the initial reset released after `repeat (1) @(posedge aclk)`
   — a single edge. Stateless direct wiring does not care; NIC-400 arbiters,
   outstanding-transaction FIFOs and CDC structures do. `top/hdl_top.sv` now
   holds reset for 16 cycles and idles 8 more before traffic, under
   `BUS_MATRIX_NIC400` only.

Neither patch fixed the read stall on its own, but both are genuine defects
exposed by putting real RTL in the path.

## Hypotheses already REFUTED by experiment (do not retry)

| Hypothesis | How it was refuted |
|---|---|
| Fabric/wrapper read path is mis-wired | `tb_fabric_smoke.sv` CASE3 reads fine, RID correct |
| Missing slave responder sequences | Added on slave 0, then on every slave via `_all[]`: error count unchanged (17). Consistent with base test setting `read_data_mode = SLAVE_MEM_MODE`, in which the slave read task does **not** wait on the sequencer |
| Wrong bus-matrix mode / slave address ranges | `+BUS_MATRIX_MODE=ENHANCED` applied; slave ranges become S0=0x8_0000_0000 … which match the fabric map, and slave 2 reports `IS INSIDE slave 2 range`. Error count unchanged |
| Scoreboard compares remapped IDs | Relaxing the AWID compare changed nothing. The real signal is `verified_awid_count == 0`, i.e. **no comparison ever happened**, not a value mismatch. Change was reverted |
| ID width hard-coded to [3:0] in both BFMs (real fix, see below) — as the *sole* cause | Patched all four ID ports + `mem_awid`/`mem_arid` + `bid_local` to follow `AXI_ID_WIDTH`. Necessary and correct, but BVALID is still never asserted, so it was not the whole story |
| Reset too short (as the sole cause) | Extended to 16 cycles + 8 idle: `EGRESS ARVALID` still never asserts |

## Where to look next (narrowed to one place)

`slave/axi4_slave_driver_proxy.sv` `axi4_write_task()` — trace the path between
the write **data** phase completing and `axi4_write_response_phase()` being
called. Suspects, in order:
* the static indices (`j`, `j1`, `i`) into `mem_awid`/`mem_wlen`/... in
  `agent/slave_agent_bfm/axi4_slave_driver_bfm.sv`. With four masters funnelling
  into one egress port the AW/W arrival interleaving differs from the 1:1 case
  and these indices can desynchronise, leaving the response phase waiting on a
  slot that never fills.
* `completed_initial_txn` / semaphore gating in the proxy write task.
* whether the proxy reaches `axi4_write_response_phase` at all — add a UVM_LOW
  print at its entry; there is currently no low-verbosity trace there.

## Next step

Generate a waveform and trace inside the fabric, which is where the answer now
has to be — AR enters the ASIB and does not leave the AMIB:

1. Add `$fsdbDumpfile`/`$fsdbDumpvars` (or `-debug_access+all` + VPD) to the
   Track-B build and capture a run.
2. `xverif_debug_session_open` on the dump, then `xverif_debug_query` with
   `trace.drivers` on `nic_s_arvalid[2]` / the AMIB's internal request.
3. `mcp__TraceWeave__explain_signal_driver` with `recursive=true` from the
   egress ARVALID back through `busmatrix_bm0` to the ASIB read request, to see
   which stage swallows it.

Specific things worth checking in that trace:
* whether the write B-responses ever return (an unfinished write could hold the
  fabric's outstanding queues and gate reads),
* whether `nic_m_rready` from the VIP master is ever high — NIC-400 may refuse
  to issue AR downstream while the return path is unavailable,
* whether the AR handshake really completes or `arready` is a constant tie.

### Additional refuted hypothesis (this session)

| Hypothesis | How it was refuted |
|---|---|
| Reset must be asserted from time 0 (as the passing standalone TB does), because `hdl_top` starts with `aresetn = 1'b1` and only asserts at `#10`, letting real RTL latch X | Tried `aresetn = 1'b0` from time 0 under `BUS_MATRIX_NIC400`. Made it **worse**: the simulation hangs after "Initial reset completed" at t=490 with **zero** egress activity (previously writes at least reached EGRESS[2]). Change reverted |

Remaining reset-related patch that IS kept: 16 cycles asserted + 8 idle cycles
after release (still starting from `aresetn = 1'b1` at time 0, as upstream).
