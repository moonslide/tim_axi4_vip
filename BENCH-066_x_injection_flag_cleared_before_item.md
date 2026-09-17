# BENCH-066 — Basic X-injection request cleared before driver consumption

## Current MR identity (2026-09-15)

MR !467 now records RREADY as **BENCH-065** (formerly BENCH-058) and basic X-injection as **BENCH-066** (formerly BENCH-059). Latest master `4b8874f8a71ddaba7bc8635d3c4a8754fc0fbc32` independently allocated 058/059 and already contains IDs through 064; all its records are preserved. This update was prepared in `C:/Users/RichardFu/.codex/worktrees/vip-bench059/t27-soc`, host `LAPTOP-27QTGPBA`. Earlier MR numbers, branch names and audit identities below are dated history. Historical logs are unchanged byte-for-byte under the renamed paths; this renumbering does not represent a repair or a new simulation verdict.


**Tracker:** Bench Issues · **Category:** TB · **Severity:** Medium

**Status:** Open — source-order defect reviewed; dynamic reproduction pending

**Failing tests:** No measured failing simulation filed; basic `axi4_master_x_inject_seq` paths require an isolated injection witness

**Date:** Detected 2026-09-11; filed/rechecked 2026-09-14 · **DV:** Richard Fu (report requester; repair owner unassigned)

![Mechanism](template/bench066_x_injection_order.svg)

## Summary and evidence provenance

The basic AWADDR sequence sets the injection flag, waits, clears it, then submits its recovery item. The driver reads the flag only after obtaining an item. With an idle driver and no concurrent/pending item during the armed interval, that sequence's own item cannot trigger its intended AWADDR injection hook.

- **MEASURED (static source inspection):** ordering at sequence lines 174/180/183/190/202 and driver lines 400/423/431.
- **INFERRED:** isolated execution skips the intended BFM call; this is not a measured wire-level observation.
- **UNSETTLED:** dynamic behavior in a bound VIP bench, concurrent request consumption, and per-signal recovery behavior.
- Bound tree: `C:/Users/RichardFu/.codex/worktrees/d54f/t27-reproduce-rtl-issue`, host `LAPTOP-27QTGPBA`, HEAD `de9ded351165bef9afaf7a4c09eb9ea54e2aa6f3`; rechecked 2026-09-14 Asia/Taipei. VIP source was unchanged in this working tree at filing.
- No VCS/simv run or FSDB is claimed. All source paths/line anchors below refer to this baseline.
- Maintainer queue: [VIP_ISSUES](../../vip/tim_axi4_vip/VIP_ISSUES.md). Complete evidence and repair requirements live here.

## Historical filing identity and integration (before renumbering)

Renumbered to **BENCH-059** on 2026-09-15 in `C:/Users/RichardFu/.codex/worktrees/vip-bench059/t27-soc`, host `LAPTOP-27QTGPBA`, based on master `e9b4dc154d9ac4aa0c5bdebcb9bf9108a63457a1`. The original X-injection filing used BENCH-057 on a separate branch; master BENCH-057 belongs to the distinct Verilator X/Z literal-fold issue and is unchanged. BENCH-058 is the distinct SoC mid-burst RREADY filing, originally published in MR !466 and now integrated into MR !465 alongside this issue.

This is an identity/index migration, not a new root-cause verdict or a VIP fix. The historical source probe log is retained byte-for-byte under `repro/bench066_source_probe.log` (renamed artifact; original BENCH-059 evidence); its original timestamp, tree and HEAD remain authoritative. Existing evidence and reviews below refer to that original audit. The [BENCH-058 document](BENCH-065_soc01_cpu_axi_midburst_rready_stimulus_missing.md), both tracker rows and the VIP queue are delivered together in MR !465 following the user's 2026-09-15 integration request.

## Root cause

![Request/consume ordering](template/bench066_x_injection_order.svg)

## 1. Concrete failure mechanism

### 1.1 Sequence clears the request before submitting an item

File: `03_VERIFY/vip/tim_axi4_vip/seq/master_sequences/axi4_master_x_inject_seq.sv`

`inject_x_on_awaddr()` 的順序：

| Line | Action |
|---:|---|
| 174 | `uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 1);` |
| 175 | 設定 `x_inject_cycles` |
| 180 | `#(x_inject_cycles * 10ns);` |
| 183 | `uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 0);` |
| 186 | `enable_x_assertions();` |
| 189–190 | 建立 `req`，呼叫 `start_item(req)` |
| 192–200 | randomize 一筆正常 write transaction |
| 202 | `finish_item(req);` |

`config_db::set()` 在這裡只是更新控制旗標，不會直接呼叫 BFM 或把 DUT interface 訊號變成 X。固定時間等待也不是 injection-complete acknowledgment。

### 1.2 Driver only consumes the flag after receiving an item

File: `03_VERIFY/vip/tim_axi4_vip/master/axi4_master_driver_proxy.sv`

```systemverilog
// Line 400: blocks until an item is available
axi_write_seq_item_port.get_next_item(req_wr);

// Lines 423–432: only reached after get_next_item returns
if (!uvm_config_db#(bit)::get(null, "*", "x_inject_awaddr", x_inject_awaddr))
  x_inject_awaddr = 0;
if (x_inject_awaddr) begin
  // Read duration, call BFM, then clear the request.
  // ...
  axi4_master_drv_bfm_h.inject_x_on_awaddr(x_inject_cycles);
  uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 0);
end
```

以上 excerpt 省略部分 duration lookup，不能作為完整修補程式直接套用。

在 idle driver、無其他流量時，事件順序為：

```text
Sequence: set flag=1 --> wait --> set flag=0 --> submit item
Driver:   wait at get_next_item ----------------> read flag=0
                                                       |
                                                       +--> skip X-injection task
```

### 1.3 The BFM has actual X-driving code

File: `03_VERIFY/vip/tim_axi4_vip/agent/master_agent_bfm/axi4_master_driver_bfm.sv`

`inject_x_on_awaddr()` at lines 1115–1130 contains:

```systemverilog
awvalid <= 1'b1;
awaddr <= 'x;
repeat(cycles) @(posedge aclk);
awvalid <= 1'b0;
awaddr <= '0;
```

因此定位是 sequence 到 driver 的 request/consume 時機錯誤。BFM 是否在特定環境造成其他握手或恢復問題，仍須另外量測。

## 2. Affected basic injection paths

Sequence file below is `seq/master_sequences/axi4_master_x_inject_seq.sv`; driver file is `master/axi4_master_driver_proxy.sv`. Both are relative to the VIP location in the baseline table.

| Signal | Sequence task starts | Sequence behavior | Driver flag read | BFM call |
|---|---:|---|---:|---:|
| AWVALID | 130 | set 1 → wait → set 0; no item submitted by this task | 404 | 414 |
| AWADDR | 166 | set 1 → wait → set 0 → recovery write item | 423 | 431 |
| WDATA | 212 | set 1 → wait → set 0 → recovery write item | 439 | 447 |
| ARVALID | 256 | set 1 → wait → set 0 → recovery read item | 941 | 949 |
| BREADY | 302 | set 1 → wait → set 0 → recovery write item | 455 | 463 |
| RREADY | 346 | set 1 → wait → set 0 → recovery read item | 958 | 966 |

Write-side flag reads occur after `get_next_item` at line 400; read-side reads occur after `get_next_item` at line 934. The driver run phase starts read/write loops; no independent background injection-request consumer was identified in the inspected driver path.

`virtual_seq/axi4_virtual_error_inject_seq.sv` also contains basic AWVALID/AWADDR/WDATA/ARVALID virtual sequences that directly toggle the ordinary flags without submitting their own traffic. BREADY/RREADY variants call the basic master sequence. Include these entry points in the repair regression.

## 3. Scope limits and additional risks

### 3.1 Do not claim every environment always produces no X

The setters and consumers use `set/get(null, "*", key)`. Another sequence or master can supply an item while a flag is 1, allowing a driver to consume it. The symptom can therefore change with concurrency, and a request may be consumed on an unintended master.

The supported conclusion is: **the basic sequence does not reliably synchronize its injection request with its own traffic; with no concurrent item during the flag window, its intended injection is skipped.** It is not proof that every existing regression has zero X activity.

### 3.2 Assertion gating can change even when no X is driven

File: `assertions/master_assertions.sv`, relative to the VIP location.

- Lines 463–483 poll the six ordinary injection flags on clock edges and update `x_inject_mode`.
- Lines 537 and 550 use `disable iff (!x_chk_armed || x_inject_mode)`.
- The corresponding assertion labels are `NO_HANDSHAKE_DURING_X` (542) and `NO_READY_HANDSHAKE_DURING_X` (555).
- Line 431 also gates the AWVALID X-recovery property with `x_inject_mode`.
- The basic sequence also calls assertion-control tasks at lines 390–403. Their simulator-specific targeting behavior was not dynamically verified here.

Thus a flag window can suppress these checks without proving an actual X event occurred. This assertion-side polling does not drive X and is not an asynchronous injection engine.

### 3.3 Logging and coverage are not injection witnesses

Sequence messages such as `Configured X injection on AWADDR for %0d cycles` and `X injection on AWADDR completed with recovery test` describe control flow, not observed interface values.

Trap: a completed test or zero UVM errors is mistaken for successful X injection and recovery. Coverage based only on requested config state has the same limitation. This report does not declare all existing coverage invalid; each metric needs its own observation-source audit.

In contrast, `assertions/master_assertions.sv:559–569` contains `X_INJECT_MONITOR`, which checks actual interface signals with `$isunknown`. That observation is distinct from a sequence's configuration/completion message. It aggregates several conditions, so it still needs attribution to the intended signal, interface, time window and injector before it can prove this repair's full acceptance criteria.

### 3.4 Other X families need separate disposition

The separate active/random orphaned-key defect is already tracked in [BENCH-040](BENCH-040_x_inject_active_config_db_key_orphaned.md). This issue covers the ordinary-key basic sequence ordering defect. Do not duplicate BENCH-040 or mark it repaired by changing the basic sequence ordering.

## 4. Suggested repair contract

These are implementation requirements for the VIP maintainer, not an already implemented patch.

1. Define the intended injection mode per signal: idle injection, pre-transaction injection, or injection during an actual channel phase. The current proxy hook is before normal item dispatch, so preserving that hook alone does not establish active-phase injection.
2. Couple request consumption to the intended driver/interface. For transaction-triggered injection, arm before the relevant item reaches the consumer and keep the request valid until consumption is acknowledged. For idle injection without any item, provide a dedicated driver/BFM control path that does not wait on `get_next_item`.
3. Use explicit accepted/started/completed status with bounded timeout. Do not assume `#(cycles * 10ns)` means the BFM finished; the BFM measures actual `aclk` edges.
4. Scope control to a specific agent/interface and signal. Prevent unrelated traffic from consuming a global request or overwriting the shared duration.
5. Separate injection traffic from the recovery transaction. Define when recovery starts and which response/data checks prove recovery.
6. Define assertion policy explicitly. Robustness testing may intentionally suppress selected checks; an assertion-detection self-test must keep its target assertion armed. Do not suppress every expected failure and then claim the checker caught the violation.
7. Restore signal ownership and request state on completion, timeout, reset and sequence abort. Verify that normal driver/response-collector threads cannot overwrite the injection unexpectedly.

Moving `set(..., 0)` after `finish_item()` may address part of the ordering defect, but it is not a complete repair of idle injection, global ownership, active-phase timing, acknowledgment or assertion policy.

## 5. Fail-before / pass-after validation

The following is a proposed validation procedure, **not an executed simulation result**. Bind it to the maintainer's actual VIP bench and record tree, commit, node, seed, command, log and waveform paths. T27 EDA runs must follow the project's compute-node/srun policy.

### Minimal isolated reproduction

1. Use one active master; release reset and ensure there is no background traffic or pending item. Use a valid responder and bounded transaction timeout.
2. Run the basic AWADDR injection task with a nonzero duration and a target address valid for that bench. Avoid letting unrelated randomization constraints prevent entry into the task.
3. Observe the request flag, `get_next_item` return, BFM task entry, AWVALID/AWADDR on the interface, and transaction completion.
4. Before repair, the source predicts flag 1 → flag 0 → item delivery, with no call to `inject_x_on_awaddr` from that item and no corresponding intentional X event. Count only after reset; do not mistake initialization X for an injection witness.
5. A dedicated checker requiring the intended X event must fail on the unfixed isolated case. After repair, the same checker must observe X on the correct signal/interface for the defined duration, followed by the specified recovery.

### Required repair matrix

| Scenario | Required evidence |
|---|---|
| Each of AWVALID/AWADDR/WDATA/ARVALID/BREADY/RREADY | Correct interface signal actually becomes X; request/consume/complete timestamps agree |
| Injection disabled control | No intentional X event; normal transaction checks remain active |
| Idle injection, where supported | Injection starts and completes without depending on an unrelated item |
| Active-phase mode, where advertised | X overlaps the required VALID/READY/response phase, not merely an idle interval |
| Different clock periods and injection lengths | Duration follows observed clock edges, not a hardcoded 10 ns assumption |
| Concurrent traffic on another master | No cross-agent injection or request theft |
| Reset/timeout/abort | No stuck request, stale X drive, hung item or disabled-check leakage |
| Recovery | Expected transaction completes and required data/response checks pass |
| Assertion-detection test | Named target assertion is enabled and its expected failure is observed |

Record wire-level observations as well as driver logs. `Configured...` is not sufficient. For expected-negative assertion tests, state the expected failure signature and harness verdict separately from an ordinary zero-error regression PASS. Never suppress the expected event just to obtain zero UVM errors.

## 6. Relationship to migration NEG-2

Migration NEG-2 requests evidence that a known protocol-violation sequence causes master assertions to fire. This basic injection defect can prevent the intended stimulus from reaching the interface, so lack of assertion firing does not by itself prove an assertion defect.

Repairing injection does not automatically satisfy NEG-2: select an event that actually violates the named property and verify that property is armed. An expected DECERR response or a randomization rejection proves something different and is not an equivalent replacement.

This handoff does not authorize changing migration acceptance, waive NEG-2, or conclude all other testcase migration work is blocked.

## 7. Handoff deliverables expected from the maintainer

- Patch and explanation of request ownership/timing, including all affected basic entry points.
- Isolated fail-before and pass-after evidence, with interface waveform or sampled X witness.
- Results for the repair matrix and normal-traffic regression.
- Explicit disposition of active/random/slave families: verified, separately defective, or unverified.
- Any remaining limitation, without claiming that all X-injection coverage is restored from sequence log messages alone.

## Waveform

![Expected isolated timing](template/bench066_x_injection_order_waveform.svg)

**Expected/mechanism (static finding), not captured.** This figure has no measured simulation timestamps. It depicts ordering only; configuration flag activity must not be mistaken for X activity on the interface.

## Reproduce

### Executed source-order probe

From the repository root:

```bash
python3 03_VERIFY/09_ISSUES/relative_mds/repro/bench066_source_probe.py
```

Evidence: [source probe output](repro/bench066_source_probe.log). The probe exits 0 when it successfully reproduces the static defect signature, not when the VIP is fixed. It checks source ordering only and deliberately does not claim simulation PASS or prove the complete repair.

### Simulator diagnostic pattern — NOT RUN

The following uses the existing MTX carrier to run the companion virtual AWADDR flag-only sequence. It exercises the no-item flag path; it does not replace the isolated basic-sequence fail-before/pass-after procedure in section 5. Run from the intended Linux checkout; select an available compute node and use the normal project license/tool setup. Serialize against other users of the shared AMBA build directory.

```bash
export PRJ_HOME="$(pwd -P)"
export T27_HOME="$PRJ_HOME"
srun -N1 -n1 -c 8 --mem=8G bash -lc '
  set -e
  source /eda/tools/2025/bashrc2025
  source "$PRJ_HOME/03_VERIFY/ip_env/AMBA_BUS_DV_ENV/configuration/source_me_bash"
  export AMBA_MTX_ENV_HOME="$PRJ_HOME/03_VERIFY/02_IP_DV_ENV/01_AMBA_MTX_ENV"
  cd "$AMBA_BUS_DV_ENV_HOME/sim"
  "$AMBA_MTX_ENV_HOME/sim/run" -f "$AMBA_MTX_ENV_HOME/flist/top_unified.f"     -t brg_apb_base_test -watchdog 900 -w=fsdb     -addr-lo 0x03200000 -addr-hi 0x0327FFFF     +VIP_SEQ=axi4_virtual_error_inject_awaddr_x_seq +VIP_SEQ_KIND=virtual
'
```

Expected artifact location from the wrapper contract: `03_VERIFY/ip_env/AMBA_BUS_DV_ENV/sim/brg_apb_base_test.log` and the corresponding FSDB selected by the runner. **No evidence run exists for this command at filing.** Preserve uniquely named run artifacts before another carrier run overwrites them. A compile/config failure is a prerequisite failure, not evidence of the injection defect. Observe flags, driver/BFM entry and actual AWADDR/AWVALID; do not use the sequence completion message as the verdict.

## Adversarial review and disposition

Read-only review on this bound tree, 2026-09-14. All three reviewers used `gpt-5.6-sol`, the repository-authorized substitution for unavailable Opus.

| Lens | Verdict | Scope |
|---|---|---|
| skeptic | SURVIVED | Clear-before-own-item and item-gated consumer establish the isolated ordering defect |
| red-team | SURVIVED | No ordinary-key asynchronous BFM consumer found; concurrency can consume the wildcard flag and limits the claim |
| simplifier | SURVIVED | File the narrow static defect; do not claim every X family or every environment is ineffective |

Result: 3/3 survived for the conditional source mechanism. Dynamic evidence and fix verification remain pending. Repair owner: unassigned. No RTL change, sign-off waiver, or change to migration acceptance is authorized by this filing.
