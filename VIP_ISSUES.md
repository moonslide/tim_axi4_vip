# VIP Issues

Persistent maintainer queue for `tim_axi4_vip`. This is project-maintained documentation alongside the VIP; it does not authorize modifying upstream/vendor code.

Add new issues below with a link to the canonical BENCH record. Keep closed entries for history. The project tracker is authoritative for formal status; synchronize this queue's status when the canonical issue changes. Full evidence, repair history and verification results live in the linked issue rather than being duplicated here.

Status vocabulary: **OPEN / IN_PROGRESS / FIXED_PENDING_VERIFICATION / CLOSED**. A code patch alone is not CLOSED; closure requires the recorded validation evidence. Unknown ownership stays unassigned.

## Open issues

### Basic X-injection requests cleared before driver consumption

- **Record:** [BENCH-066 — detailed evidence and repair contract](../../09_ISSUES/relative_mds/BENCH-066_x_injection_flag_cleared_before_item.md)
- **Status:** OPEN (synchronized 2026-09-15)
- **Owner:** Unassigned
- **Summary:** Basic sequences clear the ordinary injection flag before their own item reaches the driver; the driver reads it only after `get_next_item`. Under isolated conditions the intended injection is skipped. This does not prove zero X in every concurrent environment.
- **Impact:** X-injection/recovery claims and assertion-detection self-tests need actual interface evidence; configuration/completion log messages alone are insufficient.
- **Repair:** Synchronize request acceptance/completion with the intended driver, define idle versus active injection semantics, scope agent ownership, and separate recovery and assertion policy.
- **Acceptance:** Isolated fail-before/pass-after X witness, per-signal duration and recovery, no cross-agent request theft, and normal-traffic regression. Full matrix is in the record.
- **Related, distinct existing issue:** [BENCH-040 — active/random orphaned config key](../../09_ISSUES/relative_mds/BENCH-040_x_inject_active_config_db_key_orphaned.md). Do not duplicate or close it based on the basic-sequence repair.

### CPU replacement AXI master lacks programmable legal mid-burst RREADY backpressure

- **Record:** [BENCH-065 — detailed evidence and acceptance criteria](../../09_ISSUES/relative_mds/BENCH-065_soc01_cpu_axi_midburst_rready_stimulus_missing.md)
- **Status:** OPEN (synchronized 2026-09-15; static finding, dynamic reproduction and repair pending)
- **Owner:** Unassigned
- **Summary:** The SoC CPU replacement AXI master lacks configurable, verifiable legal mid-burst RREADY stimulus. Existing `r_wait_states` delays only beat 0; queue saturation, reset and X injection can still lower RREADY.
- **Impact:** A green burst read does not prove response stability during deliberate internal-beat master backpressure.
- **Repair:** Provide a supported stall-position/duration control through the SoC API to the RREADY owner, preserving existing no-stall and first-beat behavior.
- **Acceptance:** Deterministic internal-beat stalls, stable held responses, exact per-transaction beat accounting, pin-level coverage and recorded fail-before/pass-after evidence; see the canonical record.

Both records and this queue are submitted together in MR !467. Both records retain their historical audit provenance; BENCH-065 was originally filed as BENCH-058 and BENCH-066 as BENCH-059 before master allocated those IDs to other issues.

## Closed issues

None recorded in this queue yet. This queue is not a retrospective inventory of every issue in the project tracker.

## Entry template

- **Title:** concise defect description
- **Record:** relative link to the canonical BENCH issue
- **Status / synchronized date:**
- **Owner:** unassigned until accepted
- **Summary / impact:**
- **Repair requirements:**
- **Acceptance / evidence:** link to canonical record
- **Related issues:**
