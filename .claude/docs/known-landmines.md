# Known landmines — tim_axi4_vip

Format: Symptom → Cause → Fix → **Trap**. Landmines are EARNED in this repo
(dated, with evidence); never import from other projects.

## 1. Slave write-data phase hangs behind any real DUT (FIXED 2026-08-01)
- Symptom: writes accepted (wlast/wready) but BVALID never driven; behind an
  interconnect every later read stalls (`timeout waiting for rvalid`).
- Cause: `axi4_slave_driver_bfm.sv` write-data loop ran `mem_wlen[a]+1` beats
  where `a` and the address-phase index `i` are INDEPENDENT static counters —
  desynchronise once AW/W interleaving differs from 1:1 wiring.
- Fix: burst now terminates on WLAST (as AXI defines; QoS branch already did).
- **Trap**: static-counter pairing in BFM channel tasks only works in lockstep
  timing. Any new channel task must key off protocol events, not counters.

## 2. BVALID collapses in zero time (FIXED 2026-08-01)
- Symptom: slave "responds" but BVALID never visible on the bus.
- Cause: `bvalid<=1; while(bready===0)@(posedge aclk); bvalid<=0;` — when
  BREADY is already high the loop runs 0 iterations and both NBAs land in the
  same time step; deassert wins. `===0` also treats X as ready.
- Fix: `do @(posedge aclk); … while(bready !== 1'b1);` (always ≥1 edge).
- **Trap**: real interconnects assert READY early; direct wiring hid this.

## 3. `join_any` in slave write task leaks response threads (FIXED 2026-08-01)
- Cause: forever-loop re-forks while the old response thread still holds the
  single-entry `semaphore_rsp_write_key`; most writes never reach response
  phase. Fixed to `join` in `axi4_slave_driver_proxy.sv`.

## 4. BFM ID ports hard-coded [3:0] (FIXED 2026-08-01)
- Real interconnects widen IDs (NIC-400: VIDWidth 4 + 4 source bits = 8).
  Truncation makes responses unroutable. All ID ports + `mem_awid/arid` +
  `bid_local` now follow `AXI_ID_WIDTH` (default 4 — baseline unchanged).

## 5. Manager has no outstanding-response collector (BEING FIXED 2026-08-02)
- Original note: 3 residual `timeout waiting for bready` in
  axi4_id_multiple_writes_different_awid_test (error demoted at the time).
  Reordering BREADY-first fixed 1 case but broke the Track-B read path
  (16 rvalid timeouts) — reverted. Needs manager-side response bookkeeping
  rework, not a handshake reorder.
- 2026-08-02, the real shape: BREADY was driven ONLY from inside
  `axi4_master_driver_proxy`'s per-transaction write-response thread, which
  first takes `write_response_channel_key`. The manager can therefore accept
  one response at a time and only while that particular transaction's task is
  scheduled. When the subordinate legally presents the B for write A while the
  manager is still driving write data for B, nothing can accept it.
- This is NOT a fabric defect and NOT an AXI limitation:
  * the failing build contains ZERO fabric (`grep -c nic400 build.log` = 0;
    hdl_top takes the "Simple direct connection" path at :911). Both builds
    that DO contain the ARM fabric pass.
  * AXI4 explicitly permits multiple outstanding writes with different IDs and
    out-of-order B completion — which is literally what the failing test's own
    header says it verifies.
- It was ALWAYS broken. At HEAD the test reported `UVM_ERROR : 0` while 3-4
  write responses never handshaked at all: the subordinate dropped BVALID on
  its bready timeout and the manager fabricated the response it never got.
  Removing both fabrications (AXI4 A3.2.1: VALID must hold to the handshake;
  a timeout must not invent a completion) turned a FAKE PASS into an honest
  deadlock.
- Fix in progress: a standing collector thread owns BREADY while queue room
  exists, captures at the handshake edge into `b_capture_q`
  (`B_ACCEPT_DEPTH`=64), and the per-transaction task pops its own response by
  `find_first_index with (item.bid == awid)`. Symmetric to the subordinate-side
  AW capture thread added the same day.
- **Trap**: when a green test depends on two components independently giving up
  and pretending, fixing either one alone turns green into a hang. Check what a
  timeout path does AFTER it times out before trusting any test that exercises
  it.

## 6. Handshake polls `=== 0` treat X as asserted (FIXED in slave BFM)
- 8 sites changed to `!== 1'b1`. Master BFM may have more — audit before use.

## 7. Test names containing "error" auto-set errors_are_expected
- `axi4_performance_metrics.sv:468-476` name-matches "*error*" and silently
  passes error storms. Don't name stress tests with "error" unless intended.

## 8. DATA_WIDTH / timeout double-defines
- `DATA_WIDTH` default 1024 (`pkg/axi4_globals_pkg.sv`, now ifndef-guarded;
  NIC-400 hard max is 256 → Track-B uses +define+DATA_WIDTH=256).
- `DEFAULT_TEST_TIMEOUT` defined 10s in `include/` and 10ms in `test/` —
  include order decides. Unify before long soak tests.

## 9. History: `ad38c95` "fixed" regressions by disabling checks
- Bounded ready-timeout SVA → `##[1:$]` (can never fail); 5-test combo suite
  → 39-line shells; `disable_timeout_checks` escape hatch added. Re-enabling
  any of these resurfaces the failures it buried — triage, don't re-revert.
  Full implementations existed at `7b21652`.

## 10. Track-B addresses must stay inside the fabric map
- Stock sequences randomize over 64-bit space → everything DECERRs at the
  default slave and the scoreboard sees zero transactions. Use
  `axi4_master_trackb_*_seq` (4KB-aligned, region-bounded, awsize≤5).

## 11. Reactive slave BFM fabricates transactions from idle (FIXED 2026-08-01)
- Symptom: `slave_assertions.sv:248 AXI_RD_STABLE_SIGNALS_CHECK` fails at exact
  50000-cycle multiples (3000550 / 3002630 / 4000630 / 4002710 ps at a 20 ps
  period); log shows reads of `araddr=0x0` that no sequence ever issued, each
  answered DECERR by the bus matrix.
- Cause: `axi4_slave_driver_bfm.sv` AWVALID/ARVALID waits had a 50000-cycle
  `break` with the `uvm_error` commented out. In SLAVE_MEM_MODE the proxy calls
  these phases from a `forever` loop even on an idle bus, so the break fell
  through, sampled the idle bus as if a handshake had occurred, and the proxy
  then drove a phantom RVALID. The later RREADY timeout dropped RVALID/RLAST
  mid-handshake — that drop is what the SVA caught.
- Fix: both waits are unbounded. A reactive subordinate has no legitimate
  timeout on "am I being addressed?"; hang protection is the base test's
  `timeout_watchdog` (`test/axi4_base_test.sv:492`).
- Evidence: 8 SVA failures → 0; phantom events 16 → 0; baseline sample of 16
  tests (incl. 5 X-injection, 3 reset) unchanged at 0 UVM_ERROR.
- **Trap**: a timeout that `break`s out of a handshake wait and then continues
  is not a watchdog, it is a transaction generator. If a wait must be bounded,
  the timeout path has to abandon the phase, not fall into the sampling code.
  Several such sites remain in the MASTER BFM (see landmine 5) — do not "fix"
  them by copying this change without the manager-side bookkeeping rework.

## 12. Scoreboard assumes 1:1 wiring, so no interconnect can pass it (OPEN)
- Symptom: Track-B ends with 14 UVM_ERROR, all `env/axi4_scoreboard.sv` count
  comparisons, while the bus traffic is provably correct.
- Cause, three independent parts:
  (a) it compares master-side and slave-side AxID/BID/RID for equality, but
      NIC-400 widens egress AxID to `{ingress-port, original-id}`
      (`EGRESS BVALID bid=0x45` vs `INGRESS BVALID bid=0x4`). NOTE: this is the
      leading explanation, NOT a settled one -- a VIP-internal mechanism can
      produce the same symptom, see landmine 14. Do not close bid/rid on the
      interconnect explanation until 14 is eliminated;
  (b) it compares AxQOS, which the fabric does not forward at all — the
      generated RTL has QoS ports only on the ingress side, so
      `hdl_top.sv:760-761` ties egress QoS to 0 and arqos scores 0/8 forever;
  (c) it pairs transactions positionally, so arbitration reordering shows up as
      mismatches between two legitimate values (`'h8ac1df000` vs `'h8963f8000`
      and the exact reverse).
- **Trap**: do not "fix" a Track-B scoreboard error by patching a BFM. Check
  first whether the field survives an interconnect at all.

## 13. QoS write/read response: delete() on an empty queue kills the sim
##     (INTRODUCED 2026-08-01 by the write-task join change, FIXED same day)
- Symptom: `Error-[DT-MCWII] Method called with invalid index ...
  "delete" method called with invalid index (size:0, index:0)` at
  `slave/axi4_slave_driver_proxy.sv:382`, simulation aborts (rc=1, no UVM
  summary). Reproduced with `axi4_qos_basic_priority_test` and
  `axi4_qos_equal_priority_fairness_test` under `+BUS_MATRIX_MODE=ENHANCED`.
- Cause: WRITE_RESPONSE_CHANNEL selects from `qos_queue`, which
  WRITE_ADDRESS_CHANNEL fills, but it only `await()`s WRITE_DATA_CHANNEL. AXI
  permits the write data phase to complete before the write address phase, so
  the queue can legitimately be empty. `join_any` used to hide this because the
  loop restarted on every address completion and the queue accumulated entries;
  changing the fork to `join` made the pairing strictly 1:1 and exposed it.
  `queue_index` / `read_queue_index` are class members, so a stale index also
  survived into the next response.
- Fix: `wait(qos_queue.size() > 0)` before selecting, and seed the index to 0
  instead of inheriting it. Applied symmetrically to the read branch, whose
  `wait(qos_read_queue.size>=2)` guard is disabled after the first read
  (`qos_wait_enable = 1'b0`) and therefore had the identical latent crash.
- Evidence: 2 aborts -> 0; 8 QoS runs across ENHANCED and 4x4 all
  `UVM_ERROR : 0` / `TEST RESULT: PASS`. Verified against a HEAD worktree that
  the crash does NOT exist at `9d2f58d`, i.e. it was introduced, not latent.
- **Trap**: changing a channel fork's join semantics changes which cross-thread
  invariants still hold. `join_any` had been masking an unguarded queue access;
  any future `join_any` -> `join` conversion must re-check every queue/FIFO that
  one channel fills and another consumes.

## 14. Static index desync in the slave BFM response phases (OPEN, UNVERIFIED)
- `axi4_write_response_phase` reads `mem_awid[j]` / `mem_wlast[j]` with its own
  static `int j` (`agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:326`), while
  `axi4_write_address_phase` FILLS those arrays with the interface-scope
  `reg [7:0] i`. `axi4_read_data_phase` likewise reads `mem_arid[j1]` with a
  task-static `j1` against the interface-scope `reg [7:0] j` used by
  `axi4_read_address_phase`. Different types too: `i`/`j` wrap at 256,
  `j`/`j1` are 32-bit, and `mem_*` has only `2**LENGTH`=256 entries.
- This is exactly the pattern landmine 1's Trap warns about and it was fixed for
  `mem_wlen[a]` only. `while(mem_wlast[j]!=1)` at :353 additionally has no
  timeout at all.
- Why it matters: the slave drives `bid <= mem_awid[j]`, so a desynced `j`
  emits the wrong BID irrespective of any interconnect. Until this is
  eliminated, the Track-B `bid 0/4` and `rid 0/4` scoreboard failures cannot be
  attributed solely to NIC-400 ID widening (landmine 12a).
- Also unresolved: `pkg/axi4_globals_pkg.sv:350,369,387` still declare the
  transfer-struct IDs as `bit [3:0]`, so under `+define+AXI_ID_WIDTH=8` the
  widened IDs are truncated at the struct boundary even though the BFM ports
  and `mem_awid`/`mem_arid` were widened.

## 15. Tests that die at time 0 while reporting `UVM_ERROR : 0`
- `test/axi4_base_matrix_test.sv` ends at `Time: 0 ps` with
  `UVM_FATAL env/axi4_env.sv(95) [FATAL_ENV_AGENT_CONFIG] Couldn't get the
  env_agent_config from config_db` — verified identical at HEAD `9d2f58d`, so
  pre-existing, not a regression.
- 11 files under `test/` are never `` `include ``d in `test/axi4_test_pkg.sv`
  (`axi4_pure_reset_test`, `axi4_x_inject_active_test`,
  `axi4_minimal_pass_test`, the clock/freq family, `axi4_qos_mixed_priority_test`,
  `axi4_stress_reset_test_simplified`), so `+UVM_TESTNAME=<them>` dies with
  `UVM_FATAL [INVTST] ... not found` — also at `Time: 0 ps`, also with
  `UVM_ERROR : 0`.
- None of these are in `testlists/axi4_transfers_regression.list`, and
  `sim/synopsys_sim/axi4_regression.py:1421-1422` does key on UVM_FATAL as well
  as UVM_ERROR, so the suite is not currently mis-scoring them.
- **Trap**: never tally an ad-hoc verification sample by grepping `UVM_ERROR`
  alone. A test that never starts reports zero errors. Require
  `UVM_FATAL : 0` **and** a `TEST RESULT: PASS` line before counting a run.

## 16. Write/read PAYLOAD was never actually compared (FIXED 2026-08-01, one case OPEN)
- Symptom: `check_phase` printed "wdata count comparisons - no transactions
  processed" in essentially every test, including the plain
  `axi4_blocking_write_read_test`. It reads like "nothing to check"; it actually
  meant every comparison had failed and been discarded.
- Cause 1 (the silent pass): `env/axi4_scoreboard.sv` incremented
  `byte_data_cmp_verified_wdata_count` on a match but incremented **nothing** on
  a mismatch. With every comparison failing, both counters stayed 0 and
  check_phase's `(verified==0 && failed==0)` branch reported the vacuous
  "no transactions processed". Same for `wstrb`.
- Cause 2 (why they all failed): the seq-item converters rebuilt the burst with
  `output.wdata.push_front(...)` inside `if (wdata[i] != 0)`, over the whole
  2**LENGTH struct array. That REVERSED the beat order, DROPPED every
  legitimately-zero beat, and took the beat count from "how many were non-zero"
  instead of from AWLEN. Present in BOTH converters, on the write and the read
  path, in five separate functions. The read path had the same shape
  (`while (rdata[i] != 0)` stops at the first zero beat).
- Fix: mismatch branches now count; every payload copy is
  `for (b = 0; b <= AWLEN/ARLEN; b++) push_back(...)` with no value filter, and
  the combined-packet builders take the beat count from the ADDRESS packet
  (the write-data struct carries no AWLEN).
- Evidence: `axi4_blocking_cross_write_read_test`,
  `axi4_blocking_unaligned_addr_write_read_test`,
  `axi4_blocking_outstanding_transfer_write_read_test`,
  `axi4_write_heavy_midburst_reset_rw_contention_test` and
  `axi4_non_blocking_write_read_response_out_of_order_test` went from
  "no transactions processed"/failed to **"wdata/wstrb comparisions are
  succesful"** — i.e. the payload is now genuinely verified for the first time.
- CLOSED: the long-burst residue was a THIRD defect --
  `agent/slave_agent_bfm/axi4_slave_monitor_bfm.sv` declared the write-data beat
  index as `reg[3:0] i`, so it wrapped at 16 and any burst longer than 16 beats
  overwrote wdata[0..15] repeatedly. Measured with AWLEN=141: both sides
  reconstructed 142 beats but only 16 distinct slave values were real. Widened
  to `int`. And a FOURTH: the comparison itself must be masked by WSTRB -- AXI4
  does not define the contents of unstrobed byte lanes, so with a narrow AxSIZE
  behind the fabric the master saw the full 256-bit word and the slave only the
  strobed bytes ('h5bfa in the measured case). See
  `axi4_scoreboard::sb_wdata_equal_under_strobe`.
- **Trap**: a "no transactions processed" line in this scoreboard is not
  reassurance, it is an alarm — it means both counters are zero, which happens
  when the check never ran OR when every failure was discarded. Treat any
  verified==0 field as unverified until proven otherwise.

## 17. Scoreboard ID checks must be multiset membership, not equality
- The check "the manager gets its own BID/RID back" cannot be written as
  `master_tx.bid == master_tx.awid` on the combined packet: with several
  transactions in flight, or an out-of-order subordinate, the monitor pairs the
  response with whichever address packet is next in its FIFO, not the one that
  owns the id. Written that way it produced 17 false failures on
  `axi4_id_multiple_writes_different_awid_test`.
- Correct form (now implemented): keep a per-master multiset of issued
  AxIDs, and require the returned id to be one the master is still waiting on.
- Second trap: the address channel and the response channel are consumed by
  independent `forever` loops, so a response can reach the scoreboard BEFORE
  its address packet. Ids that do not match on arrival are parked and re-tested
  in `check_phase`. Without that, Track-B reported 1 false bid + 1 false rid.


## 18. Bus-mode override now resizes the environment (FIXED 2026-08-01)
- `test/axi4_base_test.sv` `+BUS_MATRIX_MODE=BASE|4x4|ENHANCED|10x10` set the
  MODE only while logging that it had resized the env. A test whose name matches
  the qos/user/error_inject/concurrent/exception patterns in
  `axi4_test_config::configure_for_test()` is already 10x10, so
  `+BUS_MATRIX_MODE=4x4` gave it BASE_BUS_MATRIX with TEN agents, and slaves
  4..9 fell through to the `default:` range 0x0-0xFFFF_FFFF which overlaps S1
  Boot_ROM. Both cases now set num_masters/num_slaves to match the mode.
- Verified across all 108 regression entries that carry
  `command_add=+BUS_MATRIX_MODE=4x4` or `=ENHANCED`, against a HEAD worktree
  control run of the same 108.

## 19. Slave response and scoreboard expectation must use the SAME master index
- `slave/axi4_slave_driver_proxy.sv` inferred the requesting master as
  `AxID % 4|10` at six sites, while the scoreboard now derives it from the
  monitor's source-port stamp. When those disagree the slave computes its
  response from one row of the access matrix and the scoreboard predicts from
  another: `axi4_error_inject_arvalid_random_test` and
  `_rready_random_test` reported 7 x "Response mismatch ... expected READ_OKAY,
  got READ_DECERR" under ENHANCED.
- With the 1:1 direct wiring `top/hdl_top.sv` connects master[j] to slave[j], so
  the slave agent's own `slave_id` IS the source master; that is now used.
  Behind the NIC-400 fabric it is not, and the egress AxID carries the ingress
  port, so the AxID rule is kept under `BUS_MATRIX_FABRIC_IP`.
- Fixing this also cleared `axi4_error_inject_multi_signal_random_test ENHANCED`,
  which was failing at HEAD.
- **Trap**: any change to how one side identifies the requesting master must be
  made on BOTH sides in the same commit.

## 20. axi4_user_signal_passthrough_test +BUS_MATRIX_MODE=4x4 (OPEN, pre-existing)
- Fails identically at HEAD `9d2f58d`: 129 writes all DECERR, perf metrics
  "Protocol Issues : 129" -> TEST RESULT: FAIL.
- Cause: `seq/master_sequences/axi4_master_user_signal_passthrough_seq.sv:132`
  hard-codes `awaddr == 64'h0000_0008_0000_0000 + slave*0x1000`, the ENHANCED
  map's S0 base, and picks `$urandom_range(0,9)`. The regression list also runs
  this test in 4x4, where that base is unmapped.
- Attempted fix REVERTED: deriving the base from
  `axi4_bus_matrix_h.slave_cfg[].start_addr` makes 4x4 target real regions but
  then picks master/slave pairs the ACCESS MATRIX forbids, which broke the
  previously-passing ENHANCED run. A correct fix has to choose only permitted
  (master, slave) pairs -- a stimulus-design task, not a one-line change.
- What was KEPT from that attempt: `env/axi4_env.sv` now publishes
  `axi4_bus_matrix_gm` to the master agents as well as the slave agents. It was
  slave-only before, which is why no master-side sequence could be map-aware.

## 21. check_phase that only inspects FIFO size cannot detect a lost transaction
##     (FIXED 2026-08-02, external review Finding 1)
- Symptom: `axi4_trackb_smoke_test` at seed 424242 -- 10 writes issued, only 9 BIDs
  verified, `UVM_ERROR : 0`, `TEST RESULT: PASS`, process exit 0.
- Cause: every scoreboard channel task does `get()` on the master FIFO and then
  BLOCKS on the slave `get()`. An item already pulled out of a FIFO, parked in a
  keyed holding pool, or counted in `sb_outstanding_awid/arid` and never
  answered, is in none of the FIFOs -- so a size check sees nothing wrong.
- Fix: `sb_end_of_test_completeness_check()` with five independent checks --
  in-flight parked item, master-received vs matched counts, holding pools
  drained, outstanding ID maps zero, AW/W/B and AR/R pipeline balance.
- Two further bugs found while fixing it, both strengthening: the BID/RID
  pending re-test sat inside the READ-mode branch of check_phase so a
  write-only test never ran it; and outstanding-ID retirement happened after
  slave pairing, so a lost SLAVE-side response was misreported as "the manager
  never got its BID" (it is a master-side-only property).
- **Trap**: "the FIFOs are empty" is not "everything was checked". Any consumer
  that removes an item before it can complete the comparison must publish that
  item somewhere check_phase can see. And a new completeness check must be
  proven able to FAIL -- there is a `+SB_SELFTEST_COMPLETENESS=<mask>` hook that
  injects one synthetic fault per check for exactly that purpose.

## 22. $fatal does not make VCS return a non-zero exit code (verified 2026-08-02)
- `top/tb_fabric_smoke.sv` was changed to `$fatal(1,...)` on a functional
  mismatch. Measured on VCS W-2024.09-SP1: the simv process still exited 0.
- So `sim/run_fabric_smoke.sh` gates on LOG CONTENT (requires the
  "FABRIC SMOKE TEST PASSED (3/3)" line AND absence of [FAIL]/timeout text),
  not on the simulator's exit status. The `$fatal` is defence in depth only.
- The same applies to the UVM tests: a run ending `UVM_ERROR : 7` still exits 0.
  `sim/synopsys_sim/axi4_regression.py:1421-1422` parses the counts out of the
  log, so the suite is not fooled -- but any ad-hoc `./simv ...; echo $?` check
  is. **Trap**: never gate a VIP result on the simulator's exit code alone.

## 25. A disabled check keeps its live description comment (verified 2026-08-02)
- `assertions/master_assertions.sv` and `assertions/slave_assertions.sv` each had
  all five `*_VALID_STABLE_CHECK` properties (AXI4 A3.2.1 -- VALID must hold
  until READY) commented out, while the `//Assertion:` / `//Description:`
  headers above them were left in place. The files read as though A3.2.1 was
  being enforced; nothing was.
- Four different comment depths (`//`, `///`, `////`, `/////`) show they were
  disabled one at a time, not in a single deliberate act.
- WHY they were disabled is visible the moment they are re-enabled: VCS rejects
  the original `s_until_with` with `Error-[SVA-SONS] Strong operator not
  supported in this context`. The weak `until_with` compiles and is the correct
  operator anyway -- the strong form also demands READY eventually arrive, which
  is liveness, already owned by the `*_READY_WITHIN_LIMIT` properties.
- Re-enabled and measured: 0 failures on both fabrics, so the VIP does honour
  the rule -- but that was previously an assumption, not a measurement.
- **Trap**: grep for `assert property` when auditing what a bench checks, never
  for the description comments. A commented-out check with a live comment is
  indistinguishable from a working one at a glance.

## 26. Killing a task that holds a semaphore deadlocks its channel forever (verified 2026-08-02)
- `env/axi4_scoreboard.sv` gained reset recovery: run_phase races the five
  channel tasks against a reset event, `disable fork`s them, clears state and
  restarts them.
- Each channel task does `key.get(1)` at the top of its forever loop and
  `key.put(1)` at the bottom. A task killed between those two never returns its
  key, so the restarted task blocks on `get(1)` for the rest of the simulation
  and that channel silently stops comparing.
- Measured: the power-on reset killed the write-address task mid-iteration and
  all eight AW field checks then failed with `verified_count == 0`.
- Fix: `sb_clear_on_reset()` re-creates all five semaphores, because all five
  tasks are restarting.
- It was only CAUGHT because those checks are written
  `if ((verified_count != 0) && (failed_count == 0))`. The upstream project
  (`mbits-mirafra/axi4_avip`) dropped the `verified != 0` term -- with that
  form, a channel that compared nothing reports success.
- **Trap**: `disable fork` is not free. Anything the killed process owned --
  semaphores, keys, objections, pool entries -- has to be reconstructed
  explicitly at the restart point.

## 27. Deriving manager identity from egress AxID denies legal transfers (verified 2026-08-02)
- Behind the NIC-400 fabric the subordinate cannot recover which manager issued
  a transfer from AxID: the egress AxID is a per-sub-block REVERSED permutation
  of the ingress port index (measured, 960/960 reads attributed to the wrong
  access-matrix row). Identity is carried explicitly in AxUSER
  (`AXI4_MID_TAG`, `include/axi4_bus_config.svh`).
- The fallback for untagged traffic still guessed from AxID. Baseline tests do
  not stamp AxUSER, so they got an arbitrary master_id, the access matrix denied
  them, and a legal in-range write produced
  `expected WRITE_OKAY, got WRITE_DECERR` -- while the SAME bus matrix logged
  `Address 0x0000000800001058 maps to slave 0`.
- Fix: `master_id = -1` when the tag is absent, and route every permission query
  through `mid_safe_write_resp()` / `mid_safe_read_resp()` in
  `slave/axi4_slave_driver_proxy.sv`. Those keep the ADDRESS DECODE (an unmapped
  address is still DECERR) and drop only the per-manager permission, which the
  scoreboard still checks using the true master port index.
- **Trap**: when an attribute is genuinely unknowable at a boundary, model it as
  unknown. Substituting a guess turns a missing check into a wrong one, and a
  wrong check fails on legal traffic.

## 28. A memory model whose STORAGE granularity differs from its CALLERS' access granularity silently returns a repeated constant (verified 2026-08-05)
- `bm/axi4_bus_matrix_ref.sv` stored one `DATA_WIDTH`-wide entry per
  `DATA_WIDTH`-ALIGNED address (128 bytes at the default 1024-bit bus), while
  every datapath caller -- `slave/axi4_slave_driver_proxy.sv::task_memory_write`
  and `::task_memory_read` -- has always worked ONE BYTE AT A TIME, handing in a
  zero-extended byte in `data[7:0]` and consuming `data[7:0]` on the way back.
- Each byte of a burst therefore overwrote the WHOLE aligned window with a
  zero-extended copy of itself, only the last byte survived, and every read
  address inside that window returned it. Measured: `0xCAFEBABE` written,
  `0xCACACACA...CA` read back; `0xDEADBEEF` -> `0xDEDEDEDE`.
- It was invisible for a year because the only live read-data check compared the
  master monitor's RDATA against the slave monitor's RDATA, and in the 1:1 build
  (`top/hdl_top.sv`) those are the SAME physical wire. Both sides see the same
  wrong value and the comparison passes.
- Fix: `slave_mem` is `bit [7:0]` keyed by BYTE address;
  `store_write()`/`load_read()` are byte granular; explicit
  `store_write_bytes()`/`load_read_bytes()` exist for the few callers that
  really mean a word.
- **Trap**: when a model and its callers disagree about granularity, the model
  does not error -- it returns plausible-looking data. Before trusting any
  memory model, write two DIFFERENT bytes into one alignment window and read
  both back. If they come back equal, the model is word-granular and every
  narrow-access test on it is vacuous.

## 29. A per-beat loop bounded by a field the struct never carried drops every beat but the first (verified 2026-08-05)
- `axi4_slave_seq_item_converter::to_write_class()` copies write beats with
  `for(b = 0; b <= input_conv_h.awlen; b++)`. On the slave DRIVER path the
  struct it is given comes from the subordinate's own dummy write-data
  transaction, whose `awlen` is 0 -- the write-data channel has no AWLEN of its
  own. The BFM (`agent/slave_agent_bfm/axi4_slave_driver_bfm.sv::
  axi4_write_data_phase`) sampled every beat correctly but never recorded HOW
  MANY, so the loop copied exactly one.
- Consequence: in `SLAVE_MEM_MODE` only beat 0 of any multi-beat write was ever
  committed to memory. Measured on `axi4_wstrb_alternating_test`: 24
  `INCR: Stored byte` lines where 32 were due, with the BFM's own struct dump
  showing `awlen:'h0` beside a `wstrb` value that plainly contains both beats.
- It was undetectable until `verify_read()` was re-enabled (AXI_data_integrity.md
  F10) -- the same-wire RDATA self-comparison cannot see missing memory content.
- Fix: `data_write_packet.awlen = <observed beats - 1>` at WLAST, in BOTH
  branches of `axi4_write_data_phase` (QoS and non-QoS). The monitor path was
  already correct -- it takes the beat count from the ADDRESS packet.
- **Trap**: a copy loop bounded by a field that arrives on a DIFFERENT channel
  than the data it bounds will silently truncate. Bound it by something the
  producer actually observed (here, WLAST), or assert that the field is present.

## 30. A package-scope queue shared by every agent instance (QoS BID) (FIXED 2026-08-05)
- Symptom: `axi4_qos_*` tests dropping B responses;
  `SB_INCOMPLETE_OUTSTANDING_AWID` / `SB_INCOMPLETE_PIPELINE` scoreboard errors
  (measured `UVM_ERROR : 4`, 6 dropped B responses, 3 seeds).
- Cause: the subordinate's QoS branch built BID from
  `awid_queue_for_qos.pop_front()`. `awid_queue_for_qos` is declared at PACKAGE
  scope (`pkg/axi4_globals_pkg.sv:316`), so ONE queue is shared by all 10x10
  master/slave pairs; every master pushes into it
  (`master/axi4_master_driver_proxy.sv:634-654`) with no cross-agent
  synchronisation. One manager's AWID could therefore be consumed as another
  pair's BID, and the pop had no `size()` guard — an empty pop silently drives
  BID = 0.
- Fix: the subordinate sources BID from the AWID **it sampled on its own AW
  channel** (`slave/axi4_slave_driver_proxy.sv:485`,
  `struct_write_packet.bid = struct_write_packet.awid`). The shared queue is
  still drained (guarded `pop_front()`, `:478-483`) purely because
  `master/axi4_master_driver_proxy.sv:620` reads its TAIL for back-to-back QoS
  arbitration — draining with `delete()` instead would have broken that.
- Evidence: 3 seeds red → 3 seeds green with a single-variable no-skew control;
  28-test baseline 28/28; fabric smoke 3/3. `test/axi4_qos_bid_queue_race_test.sv`
  is the durable detector, registered in both regression lists.
  Full chain: `AXI_ooo.md` F1.
- **Trap**: a `[$]` queue declared in a package is ONE object for the whole
  simulation, not one per agent. Before using any package-scope variable as
  per-transaction state, ask how many agents write it. And when you change how a
  queue is drained, grep for every OTHER reader of that queue first — this fix's
  first attempt used `find_first_index`+`delete()` and silently changed the tail
  the manager's arbitration depends on.

## 31. A `join` added to fix a race pinned a queue's depth to 1 and made a whole feature vacuous (OPEN — F7)
- Symptom: none. `axi4_cross_id_write_reorder_test`,
  `axi4_non_blocking_only_write_response_out_of_order_test` and
  `axi4_non_blocking_write_read_response_out_of_order_test` all report
  `UVM_ERROR : 0` / `TEST RESULT: PASS` while returning BIDs in exact issue order
  (measured 0,1,2,…,7 — the exact condition the first test's own header defines
  as "proved nothing").
- Cause: `slave/axi4_slave_driver_proxy.sv`'s write fork (branches
  WRITE_ADDRESS / WRITE_DATA / WRITE_RESPONSE) is closed by `join` — ALL
  branches — introduced by `238ffbc` (2026-08-03) to fix a BVALID-not-driven
  race, replacing a `join_any`. Side effect: the response-ID queue's push and
  pop are forced into the same loop iteration, so its depth at pop time is
  structurally 1. `shuffle()` on a 1-element queue reorders nothing, the same-ID
  continuation branch is dead code, and `ONLY_WRITE_RESP_OUT_OF_ORDER` is a
  no-op. The read side kept `join_any` plus an explicit backlog-accumulation
  gate — that asymmetry is why read-OOO works and write-OOO does not.
- Status: OPEN by design. Relaxing the join is `AXI_ooo.md` P4.5 and must be its
  own design pass — the file's own comments record two prior attempts/reverts
  here (see also landmine 13, the crash the earlier `join_any`→`join` change
  exposed). Two things become live the moment it is relaxed: the F1 hardening
  guards, and the BID/BRESP pairing rule in landmine 32.
- **Trap**: a structural constant is not a passing test. If a mode's whole point
  is a non-trivial queue depth, a test for it must ASSERT the depth it achieved
  (or the reorder it observed), never just exit clean — otherwise a synchronisation
  fix elsewhere can silently delete the feature and every test stays green.
  Reclassify such tests PASS-BUT-VACUOUS, do not count them as coverage.

## 32. Two fields of ONE response chosen by two independent orderings (FIXED 2026-08-05)
- Cause: the first Phase-2 write-side redesign gave pending same-ID entries a
  per-ID COUNT plus a random arbiter to pick BID, while BRESP kept coming from
  the strict-FIFO write-address order. The two selections were never rebound to
  each other. Counterexample: AW order (ID=A→legal→OKAY), (ID=B→illegal→DECERR)
  can emit `BID=B,BRESP=OKAY` then `BID=A,BRESP=DECERR` — each response now
  belongs to the other transaction.
- It was unreachable at the time only because landmine 31's `join` caps the
  write backlog at 1 (`OOO_ARB` instrumentation: `candidates=1` on every write
  arbitration in every run). A latent bug masked by an unrelated structural
  accident is still a bug.
- Fix: `bid_local = local_slave_addr_tx.awid`
  (`slave/axi4_slave_driver_proxy.sv:728`) — BID now comes from the same
  transaction BRESP is computed from, so divergence is impossible by
  construction; ~60 lines of arbiter machinery deleted rather than guarded.
  Verified empirically: 44/44 driven `bid_local` values match the BFM's
  independently protocol-bound `this_awid`, and the BID completion histogram is
  byte-identical before/after. `AXI_ooo.md` Phase 2 execution update.
- **Trap**: when one bus response carries several fields, ONE selection must
  choose the transaction and every field must be read out of it. Any design
  where two fields of the same beat are picked by two orderings is a
  mis-attribution waiting for enough backlog to show up.

## 33. A timeout that `break`s past an assignment leaves a null handle (FIXED 2026-08-05)
- `slave/axi4_slave_driver_proxy.sv`: a W beat with no corresponding AW (or an
  AW more than 50000 cycles late) `break`s out of the wait without ever
  assigning `local_slave_addr_tx`; the next line dereferences it → UVM_FATAL
  whose message names the dereference, not the missing AW. Most likely trigger
  is a mid-burst reset or a fabric-IP scenario, where the subordinate BFM's
  reset clears `aw_capture_q`/`aw_resp_id_q`/`w_done_q` and can desynchronise
  AW/W pairing across the boundary.
- Fix: an explicit `uvm_fatal` naming the real cause ("no AW for this W") on the
  timeout path, before any dereference (`:511`). `AXI_ooo.md` F11.
- **Trap**: this is landmine 11's Trap in its quiet form — the timeout path here
  does not fabricate a transaction, it falls into code that assumes the wait
  SUCCEEDED. After adding any bounded wait, read every line between the `break`
  and the end of the block and ask which of them the timeout just invalidated.

## 34. A checker's own fail-then-pass evidence says nothing about its false positives (verified 2026-08-05)
- The Phase-3 same-ID order checker passed its red/green gate on the first try
  (5/5 seeds caught F2, control clean, 28-test baseline green) and was still
  refuted by review, twice, over three fix passes. Real defects found AFTER the
  green evidence: one of its two mechanisms (SHAPE) was structurally dead code
  and could only ever have produced a FALSE conviction; its content shadow was
  keyed by address alone, so cross-master writes or a legal read/write race
  could indict an innocent sibling (45% of checks in one PASSING test already
  reached the sibling-search stage); its skip path left the per-(port,id) head
  permanently one entry stale, i.e. a systematic false-violation generator; and
  it shadowed writes the subordinate never committed. Each of the last three was
  demonstrated on a directed probe (`test/axi4_refused_write_shadow_test.sv`
  convicts an innocent sibling TWICE under the previous gate, with
  `RESP_IN_ORDER` and nothing reordered anywhere).
- **Trap**: red-then-green proves a checker has TEETH. It does not prove the
  teeth only bite the guilty. A checker needs a second, opposite body of
  evidence: run it across a broad sample of tests that should be silent and
  require zero output, and build a directed probe for each false-positive route
  you can name. Also count what the checker actually ADJUDICATED — a summary
  line saying `checked=24 content_adjudicated=0` means the run did accounting
  only, and "checker enabled" must never be read as "traffic checked".

## 35. `axi4_regression.py` reported PASS before it read the UVM summary (FIXED 2026-08-05)
- Symptom: a test with `UVM_ERROR : 2` in its own log filed under `pass_logs`
  (measured: `axi4_refused_write_shadow_test` in
  `regression_result_20260805_121616`, two `SB_SAMEID_ORDER_VIOLATION` lines).
- Cause: the verdict function scanned `success_patterns` FIRST and returned
  `'PASS', None, 0, 0` on the first regex hit ANYWHERE in the log. That list
  contains `UVM_INFO.*PASSED` matched case-insensitively, and
  `env/axi4_performance_metrics.sv:495` prints
  `[ERROR_INJECT] Error injection test PASSED` — one narrow internal sub-check —
  so it buried the UVM_ERROR summary check that ran afterwards.
- Scope, measured rather than estimated: a sweep of all 1761 archived regression
  logs found **16** logs whose own summary reported `UVM_ERROR > 0` filed as
  PASS; and ZERO logs that would change verdict from reordering the checks.
- Fix: the UVM report summary is consulted first and decides; `success_patterns`
  survives only as the fallback for runs that never reached `report_phase`.
  Applied to all THREE copies of this function — `axi4_regression.py`,
  `axi4_regression_makefile.py`, `axi4_regression_makefile_runfolder.py`.
- **Trap**: any pass/fail counted from a regression summary produced BEFORE
  2026-08-05 must be re-derived from the logs' own `UVM_ERROR :` lines. And when
  a repo has three near-copies of its runner, a fix to one is a fix to none —
  grep for the function body, not the filename.

## 36. Concurrent `axi4_regression.py` runs destroy each other's results (OPEN)
- `axi4_regression.py` stages every job into a SHARED `sim/run_folder_00..11`
  pool and cleans that pool at startup, so two runs — even from the same user on
  the same machine — silently overwrite each other's logs. It happened twice in
  one session on 2026-08-05: once self-inflicted (three drivers launched from a
  single shell command), once when another session started a list while a
  control run was mid-flight, which is why that control has only a local-run log.
- Related, same class: a regression launched detached (`setsid`) with an
  uncommitted working tree does `rm -rf` + recompile PER JOB over hours, so any
  source edit during that window mixes code versions into one result set with no
  way to tell afterwards. One such run was deliberately killed for this reason.
- Until a per-run workspace exists: `ps aux | grep axi4_regression.py` before
  launching, do not detach a run from the agent that must interpret it, and do
  not edit VIP source while one is in flight.
- **Trap**: a regression result directory carries a timestamp, which reads like
  isolation. It is not — the WORK directory is shared and unversioned.

## 37. Manager BFM: credit-1 claiming + RID-specific wait + bounded collector = silent read-data loss (MITIGATED 2026-08-05)
- Symptom: `AXI4_MASTER_DRIVER_BFM ... timeout waiting for a read burst with
  rid=0x0 - read data phase abandoned` after 50000 cycles, on a legal reorder;
  the run then COMPLETES and reports `TEST RESULT: PASS` (see landmine 39).
  Hit live in tonight's final full regression: `axi4_same_id_nonadjacent_reorder_test_1`,
  seed 1413795560, `UVM_ERROR:1`.
- Mechanism, fully quantified 2026-08-05: the manager claims read data one
  transaction at a time in issue order (`outstanding_read_credits` default 1),
  and each claim task waits on ONE specific RID. Bursts for other RIDs pile into
  the bounded collector (`R_ACCEPT_DEPTH`,
  `agent/master_agent_bfm/axi4_master_driver_bfm.sv:381`), RREADY deasserts, the
  R channel wedges head-of-line until the FIXED 50000-cycle escape; the stale
  outstanding entry is then deleted, so when the real burst finally arrives it is
  discarded as "answers no read outstanding". Net: silent data loss, not a hang.
- Proven pre-existing and NOT caused by the same-ID/OOO rework: a 20-seed A/B
  fired the SAME timeout on 8/20 seeds with the PRE-Phase-2 subordinate versus
  3/20 after it; an arbiter trace shows the subordinate dispatched the awaited
  ARID 2 clocks AFTER each manager timeout (`candidates=1` — it was never
  starved). Causality runs manager → subordinate.
- Why it matters beyond the VIP: a real DUT is ALLOWED to reorder this way, so a
  legal interconnect can trigger it. `AXI_ooo.md` F2's P0.2 follow-up.
- **Mitigation landed (2026-08-05)**: `R_ACCEPT_DEPTH` raised 8 → 64
  (`agent/master_agent_bfm/axi4_master_driver_bfm.sv:381`) — a single-variable
  change, no credit/semaphore semantics touched. Fail-then-pass: same seed
  (1413795560), same test, `UVM_ERROR:1` (rid=0x0 timeout) → `UVM_ERROR:0`
  (`TEST RESULT: PASS`), `SB_SAMEID_ORDER checked=24 violations=0` unchanged
  before/after (confirms the fix touches only the manager-side claim deadlock,
  not the F2 checking logic). Verified with a 27-run LSF sample covering all 3
  modes of the failing test plus cross-ID reorder, OOO, QoS BID race,
  outstanding-depth, id-multiple-different-id and outstanding-transfer tests:
  27/27 PASS, no regressions. `run_fabric_smoke.sh`: 3/3 PASS.
  `sim/synopsys_sim/r37_red_seed1413795560.log` /
  `r37_green_seed1413795560.log`, `regression_result_20260805_205709/`.
- **Still not a structural guarantee**: raising the depth does not make the
  collector unbounded — an adversarial DUT could in principle still queue more
  distinct-RID bursts than the new depth before delivering the awaited one.
  The real fix (crediting AR issuance itself so at most `outstanding_read_credits`
  reads are ever truly in flight, matching claim-task concurrency to what the
  wire can produce) remains tracked as `VIP_future.md` FW-6 / this landmine —
  now a lower-priority hardening item rather than an open failure mode, since
  the practical trigger window this bench can produce is now well clear of the
  new depth.
- **Trap**: a bounded response collector, a per-ID wait and a credit of 1 are
  each defensible alone; together they are a deadlock the protocol permits any
  DUT to provoke. When reviewing a manager BFM, check what happens to a response
  that arrives while the only claim task is watching a different ID.

## 38. Unconstrained random addresses are harmless in NONE mode and DECERR everywhere else (FIXED for one test; pattern is repo-wide)
- Symptom: `axi4_all_master_slave_access_test +BUS_MATRIX_MODE=ENHANCED` fails
  seed-dependently on `axi4_performance_metrics.sv:507` "Acceptance criteria not
  met" / "Protocol Issues: 4", while the same test in its default NONE mode
  passes.
- Cause: it drove `axi4_master_bk_write_seq`/`_read_seq`, which randomise
  AxADDR across the whole `ADDRESS_WIDTH` space with only a size-alignment soft
  constraint. In NONE mode `axi4_bus_matrix_ref::decode()` maps EVERY address to
  slave 0 and answers OKAY unconditionally, so the defect is invisible; under
  BASE/ENHANCED the same addresses land in unmapped space and the matrix
  correctly answers DECERR.
- Fix: dedicated sequences in
  `virtual_seq/axi4_virtual_all_master_slave_access_seq.sv` constrain AxADDR to
  the window the ACTIVE bus-matrix mode mapped to the target slave, read from
  `master_min/max_addr_range_array` (the same source the mem-mode sequences
  use), with 4 KiB of headroom for the longest burst. Verified by
  `sim/synopsys_sim/asmsa_fix.list` (the two exact failing seeds + all three bus
  modes + the neighbour tests that share the unconstrained pattern + the
  boundary/DECERR family that must stay red).
- Scope, not yet cleaned up: repo-wide only **28 of 172** master sequences bind
  `araddr` to a determined value at all (~16%), and 12 of those 28 sit in the
  address window `AXI_data_integrity.md` F9 shows is outside every active
  slave's decode range — so at most ~9% of master sequences could support a
  read-after-write check even in principle.
- **Trap**: NONE mode is not a weaker version of the others, it is a DIFFERENT
  decode that cannot fail. A sequence proven in NONE mode has proven nothing
  about its addresses. Run any address-sensitive test in ENHANCED at least once
  before believing it.

## 39. `TEST RESULT: PASS` does not mean `UVM_ERROR : 0` (verified repeatedly 2026-08-05)
- `env/axi4_performance_metrics.sv`'s `report_phase` prints its own
  `TEST RESULT: PASS/FAIL` from the deadlock/livelock flags and its acceptance
  criteria. It does NOT consult the UVM error count. Measured on 45 consecutive
  runs of the F2 repro that were each silently dropping read bursts (landmine
  37): every one printed `TEST RESULT: PASS`.
- The converse trap is landmine 15: a run that dies at time 0 prints
  `UVM_ERROR : 0`. So neither half is sufficient alone.
- **Trap**: the project pass criterion is BOTH parts, in this order — read
  `UVM_ERROR :` and `UVM_FATAL :` from the run's own UVM summary first, then
  require `TEST RESULT: PASS`. This is stated in CLAUDE.md as an AND and was
  still misread several times in one session, because the perf-metrics line is
  the loudest thing near the end of the log.

## 40. A checker commented out with "// will fixed later" stayed dead for a year (FIXED 2026-08-05)
- `env/axi4_scoreboard.sv::verify_read()` — the only reader of `expected_mem`,
  and the only content check of read data against what was written — had its
  call site commented out by `f6f93b6` (2025-06-27), the day AFTER it was added.
  Git archaeology shows why: that commit moved a variable out of a
  declaration-after-statement position to fix a COMPILE error, and disabled the
  call in the same hunk. Not a functional decision, a make-it-compile sweep.
- Consequence: `wstrb_compare_enable` — the knob 8 tests opt into believing they
  get data checking — was a complete no-op, and the only live read-data check
  compared the master monitor's RDATA against the slave monitor's RDATA, which
  in the 1:1 build (`top/hdl_top.sv`) are the SAME physical wire via a
  continuous assign. Not "blind to shared corruption": a tautology. It is what
  hid landmines 28 and 29 for a year.
- Re-enabling it needed two of its own bugs fixed first (a class-scope
  `exp_val` leaking state across calls; a full-`DATA_WIDTH` compare treating
  never-written bytes as expected-zero, i.e. a false-positive engine) — see
  `AXI_data_integrity.md` F10.
- **Trap**: audit what a bench CHECKS by grepping for live call sites of its
  checkers, never by the presence of the checker function (compare landmine 25,
  the same shape for assertions). And treat "// will fix later" in a commit that
  fixes a COMPILE error as a defect report: nobody was measuring whether the
  check still ran.
