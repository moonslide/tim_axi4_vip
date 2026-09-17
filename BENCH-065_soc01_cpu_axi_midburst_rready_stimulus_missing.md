# BENCH-065 — CPU replacement AXI master lacks programmable legal mid-burst RREADY backpressure

## Current MR identity (2026-09-15)

MR !467 now records RREADY as **BENCH-065** (formerly BENCH-058) and basic X-injection as **BENCH-066** (formerly BENCH-059). Latest master `4b8874f8a71ddaba7bc8635d3c4a8754fc0fbc32` independently allocated 058/059 and already contains IDs through 064; all its records are preserved. This update was prepared in `C:/Users/RichardFu/.codex/worktrees/vip-bench059/t27-soc`, host `LAPTOP-27QTGPBA`. Earlier MR numbers, branch names and audit identities below are dated history. Historical logs are unchanged byte-for-byte under the renamed paths; this renumbering does not represent a repair or a new simulation verdict.


**Tracker:** `T27_bug_tracker.xlsx` → Bench Issues → `BENCH-065`\
**Category:** TB · **Severity:** Medium · **Status:** Open — static source finding; dynamic reproduction and repair pending\
**Failing tests:** No simulated failure claimed; current CPU read stimulus cannot deliberately exercise the specified stall scenario.\
**Date:** 2026-09-14 · **DV:** RichardFu (filing); implementation owner TBD

![Mechanism](template/bench065_midburst_rready.svg)

## Evidence boundary

- Baseline: `cf583b03`, branch `codex/soc01-midburst-rready-issue`, based on `origin/master`.
- Bound tree: `C:/Users/RichardFu/.codex/worktrees/soc01-rready-bench058/t27-soc`.
- Node: `LAPTOP-27QTGPBA`; observed 2026-09-14 +08:00. Exact UTC, full HEAD and source SHA-256 values are recorded in the [source audit log](repro/bench065_source_probe.log).
- Evidence is source inspection plus an executed source-audit script. **No simulation, FSDB, measured pin timing, or UVM PASS is claimed.**
- This finding is a missing stimulus capability, not a T27 RTL defect or proof of a particular Andes interrupt scenario.

## The defect

`01_SOC_DV_ENV` replaces the CPU with the shared `tim_axi4_vip` master, but exposes no supported control to select an internal read-burst beat and hold `RREADY=0` for a specified number of clocks. The shared BFM's transaction-level `r_wait_states` applies only before beat 0. Once a partial burst is being collected, normal operation keeps RREADY high unless the completed-response queue is full.

Consequently, a successful burst read does not establish that the target memory/bridge holds its response correctly when this CPU-replacement master deliberately stops accepting data between beats. This remains a coverage capability gap even if first-beat waits or write-channel stalls were exercised.

## Root cause — source observations

Paths below are relative to the repository root and anchors apply to the bound baseline.

| Claim | Source observation | Consequence |
|---|---|---|
| C1: selected master | `01_SOC_DV_ENV/07_FLIST/vip_axi4.f:70,85` under `03_VERIFY`; `02_TB/interface_connection/soc01_vip_interface_instances.svh:43`; connections file `:65`; `03_ENV/soc01_env.sv:737–748` | Native active master BFM drives CPU-subsystem RREADY; not a passive observer. |
| C2: first-beat-only wait | `03_VERIFY/vip/tim_axi4_vip/agent/master_agent_bfm/axi4_master_driver_bfm.sv:470–475,617` | Existing RID accumulator selects zero delay; `r_wait_states` is not an inter-beat pattern. |
| C3: partial burst policy | Same BFM `:531–535,600–608` | Queue-full returns 0 first; otherwise `r_accum_q.size()>0` returns 1. |
| C4: SoC knob mismatch | `03_VERIFY/01_SOC_DV_ENV/03_ENV/soc01_env_cfg.sv:509–510`; `soc01_env.sv:746–748` | `SOC01_RDY_BP` maps only AW/W/AR channel wait fields, not RREADY. |
| C5: burst API | `03_VERIFY/01_SOC_DV_ENV/04_SEQ/soc01_axi_burst_seq.sv:251–275`; `soc01_axi_atomic_seq.sv:223–241` | These direct transactions do not set `r_wait_states` or randomize the item. This is additional first-beat coverage context, not the cause of the missing inter-beat actuator. |

The decisive default policy is:

```systemverilog
if(r_capture_q.size() >= R_ACCEPT_DEPTH) return 1'b0;
if(r_accum_q.size() > 0)                 return 1'b1;
return !r_wait_pending();
```

The delay path separately uses:

```systemverilog
r_wait_cnt = r_accum_q.exists(rid) ? 0 : r_wait_for_id(rid);
```

### Evidence grading and limits

- **STATIC OBSERVED:** assignments, active source path, configuration mappings and scoped absence results in the runnable probe/log.
- **INFERRED:** the supported CPU-replacement API cannot deliberately select a legal internal-beat pause; this scenario cannot be credited merely from a green burst test.
- **UNSETTLED:** exact affected runtime cases, elapsed stall cycles in historical regressions, any masked DUT defect, and whether an Andes interrupt causes backpressure. No such claims are filed here.
- **Exceptions preserved:** reset drives RREADY low; X injection owns it temporarily; completed-response queue saturation can lower it, including during other interleaved partial bursts. Therefore this issue does **not** claim RREADY never drops mid-burst.

## Waveform — mechanism illustration only

![Expected timing, not captured](template/bench065_midburst_rready_waveform.svg)

The figure assumes a four-beat burst, normal responses, available capture capacity and no reset/X injection. The requested middle stall is an **acceptance target**, not a new working knob or a captured failing run. Slave RVALID gaps do not substitute for master RREADY backpressure.

## Blast radius

Static scope: CPU-replacement AXI master in `01_SOC_DV_ENV`. The shared BFM is a reuse dependency, but no claim is made that every other environment lacks its own override. The migrated stream/backpressure criterion in `05_TEST/soc01_stream_test.sv:287–307` checks read/write activity; that does not by itself prove internal-beat RREADY stalls. Existing wait-state coverage samples transaction metadata and is not sufficient evidence of this missing scenario.

The real Andes core's FIFO/consumer backpressure logic motivated this audit; the replacement master need not model the CPU microarchitecture, but needs a legal controllable stall stimulus and an observed pin-level witness. No CPU interrupt emulation is required by this filing.

## Disposition / acceptance criteria

Open; documentation only. Do not modify the shared VIP or waive existing failures as part of filing.

1. Add a supported master-side control for internal-beat stall position and duration, propagated through the SoC API/config to the RREADY owner. Preserve current zero-stall and first-beat-delay semantics. Do not use X injection/reset or queue exhaustion as the intended actuator.
2. Add a deterministic read burst with `ARLEN>=3`; observe at least one accepted beat, then `RVALID===1 && RREADY===0` with beats remaining, then complete the same transaction. Check first/middle/final-beat positions separately; keep stall duration below any declared response-bound policy unless testing that policy explicitly.
3. During the stall require stable `RDATA/RRESP/RID/RLAST` and held RVALID, then exact `ARLEN+1` beat count, correct final RLAST, and no data loss/duplication. For multiple IDs, account per transaction rather than by total bus beats.
4. Require a nonzero pin-level mid-burst-stall coverage witness. Zero matches is unexercised, not a closure result. First-beat `r_wait_states` coverage cannot close it.
5. Fail-first: the current baseline cannot satisfy the directed stimulus/witness requirement. After a fix, run the same guarded case and a no-stall control via the approved compute-node flow; record the parser verdict, logs and FSDB before closing. No new test or successful dynamic run is represented as present today.

**Open discriminator:** execute the future directed case with the pin-level witness armed; this separates an implemented supported actuator from merely incidental queue-full stalls.

## Reproduce — runnable source audit

From the repository root, using Python 3 (stdlib only):

```text
python3 03_VERIFY/09_ISSUES/relative_mds/repro/bench065_source_probe.py
```

Windows may use `python` or an explicit Python executable. To capture a fresh local audit, pass `--output <new-log-path>`; do not overwrite the filed historical log when auditing a later baseline.

Recorded evidence: [bench065_source_probe.log](repro/bench065_source_probe.log). The final marker `STATIC_PATTERN_CONFIRMED` confirms this bounded source pattern, **not simulation PASS**. Exit 2 / `SOURCE_DRIFT_REAUDIT_REQUIRED` means the pattern or configuration changed and needs manual review, not automatic proof of a fix. The script is a source-audit replay, not a substitute for the future simulator acceptance test above.

## Historical combined submission (before renumbering)

On 2026-09-15, the user requested one combined MR. BENCH-058 from commit `54f67778` is integrated with BENCH-059 in MR !465 on `codex/vip-x-injection-bench059`, based on master `e9b4dc154d9ac4aa0c5bdebcb9bf9108a63457a1`. Both tracker rows and the [VIP maintainer queue](../../vip/tim_axi4_vip/VIP_ISSUES.md) are included together. MR !466 is superseded by this combined delivery; neither issue is fixed or closed by this documentation integration. Historical source/coordination logs remain byte-identical, and the original audit boundary above still applies.

## Cross-branch ID coordination — dated history

The following describes earlier states and is superseded by the Current MR identity section.

The [dated task-message excerpts](repro/bench065_coordination.log) preserve the peer's agreement and edit-stop statement. This is coordination evidence, not a repository lock or approval to merge.

At filing time master `cf583b03` already uses BENCH-057 for the [Verilator/SRAM issue](BENCH-057_verilator_xz_literal_fold_sram_failedwrite.md). The other task, “記錄 VIP X 注入缺陷”, used the same ID for a different X-injection issue in commit `967518ef` on the richard reproduction branch. That commit is not an ancestor of this baseline. **IDs alone do not establish issue identity.**

Coordination history (2026-09-14): retain master 057; this issue owns 058; 059 was reserved for the peer's X-injection renumbering and had not yet been applied.

Coordination update (2026-09-15, before publication, LAPTOP-27QTGPBA): BENCH-059 is now present in the separate, uncommitted worktree `C:/Users/RichardFu/.codex/worktrees/vip-bench059/t27-soc`, branch `codex/vip-x-injection-bench059`, baseline `e9b4dc154d9ac4aa0c5bdebcb9bf9108a63457a1`. The author independently checked its HEAD, branch and untracked canonical document; this does not mean 059 is merged or included here. The peer owns `03_VERIFY/vip/tim_axi4_vip/VIP_ISSUES.md`, which lists 059 and records 058 as a pending companion with a plain-text path until merged. This branch does not modify that index or add a 059 tracker row. Each task writes its own worktree; this branch owns only 058 additions and its tracker regeneration. The two worktrees currently have different baselines; recheck the actual target before integration.

Before either future MR merges: reconcile by title and Doc reference; recheck the destination's occupied IDs; keep both substantive issues; resolve README/generator text first and regenerate CSV/XLSX from the integrated generator. Do not merge the binary workbook with ours/theirs, globally replace bare `057`, reorder existing IDs, or copy this branch's workbook over a newer target. The original source task branch was left untouched. The original filing was documentation-only and uncommitted. On 2026-09-15 the user authorized publishing this independent branch as an MR targeting master.

## References

- [Shared read-response ownership issue (different mechanism)](BENCH-032_abandoned_read_response_misbind.md).
- [SoC environment documentation](../../01_SOC_DV_ENV/00_DOC/README.md).
- [Issue navigation](README.md).
- [Runnable source probe](repro/bench065_source_probe.py).

Historical publication coordination (2026-09-15, before consolidation; superseded by Current MR identity): the peer reports BENCH-059 published in commit `37d8db0c`, [MR !465](http://gitlab.jmemtek.online/paullo/t27-soc/-/merge_requests/465), targeting master. The fetched `origin/codex/vip-x-injection-bench059` provides its committed source. This supersedes the earlier uncommitted status; no merged state is asserted. BENCH-058 remains a separate change and does not modify `VIP_ISSUES.md`.
