# AGENTS.md — IC front-end institution (guidance for ANY AI coding agent)

Tool-agnostic operating manual for IC front-end design/verification work.
(Claude Code additionally loads `CLAUDE.md`; both encode the same
institution — if they disagree, the more recently verified statement wins
and the stale one must be fixed.)

**SCOPE — this constitution governs IC front-end work only.** It applies
to the role suite in `.claude/agents/` and to any design/verification
project bound to it. It does **NOT** govern the sibling subtree
`./fable-harness/`, which is an independent behavioral-protocol harness
carrying its own `AGENTS.md` and `CLAUDE.md`: when EDITING that subtree,
follow ITS instructions — the IC role-routing table and the
mandatory-role-creation rule below do not apply there, and harness work
must never be filed as an IC role.

Do not confuse that with the FABLE-PROTOCOL section further down: the
protocol (delivered from the user-global install `~/fable-harness/`) is a
behavioral FLOOR that applies to work under this institution. The two
directions are complementary, not contradictory — protocol constrains how
we work here; this constitution does not reach into the harness subtree's
own development.

## Project

Arm IOTSOC (r0p2) socA SoC **front-end project** (design + verification
+ sign-off): Cortex-M85 + Ethos-U65 NPU + MALI-C55 ISP + LPDDR4 (Synopsys
UMCTL2+PHY) + USB3 (DWC3) + MIPI + security (LCM/KMU/OTP). Verification is
via a **C-firmware-driven SoC testbench — NOT UVM**: a test is an ARM
firmware image selected by `TESTNAME`; pass/fail = log strings. The agent
suite covers the full front-end lifecycle — RTL design, SoC integration,
synthesis/timing, static/formal sign-off, simulation/emulation/FPGA
verification, and tape-out readiness (role scopes: `ic_design.txt`,
`ic_verificaiton.txt` at the repo root).

## Path anchors

**These anchors are TEMPLATE PLACEHOLDERS, not live paths.** This repo is
the de-identified reference institution (see `README.md`); `IOTSOC`/`socA`
stand in for a real chip program whose tree is NOT in this repo. Before any
build/debug work, BIND them to the actual project tree and record the
binding here — an agent that follows an unbound anchor will fail to find
the Makefile, RTL, and tests.

**IRON RULE — name the tree, then read the fact.** Multiple checkouts of
the same design routinely coexist on one host and DIVERGE (measured
2026-07-26: six sibling trees where the same Makefile line held opposite
default values, and an IP was an unintegrated stub in three trees and a
fully integrated real core in another). Consequences, binding on every
role file:
1. A build knob's default, an IP's integration status, a test's
   registration, and a document's existence are **per-tree facts with a
   shelf life** — read them from the BOUND tree at use time.
2. Every factual claim you write into a role file, a report, or a review
   carries **which tree and when**. A file:line citation without a tree
   is not evidence.
3. When two sources disagree about such a fact, suspect DIFFERENT TREES
   before suspecting either source is wrong — that is the common case,
   and "fixing" the disagreement by flipping the value just breaks the
   other tree's users.

```
$DESIGN  = <PROJECT_ROOT>/logical/       # all RTL, config, testbenches
$OOBTB   = $DESIGN/testbench/<prdtb_dir>/<oobtb_dir>
$REF_LIB = <REFERENCE_LIBRARY_ROOT>      # sibling tree: vendor databooks,
                                         # TRMs, RALF, recovered md_files/
```

`$REF_LIB` is bound the same way as the others — role files write
`$REF_LIB/...` for vendor-document pointers, and it resolves only once
bound. On a given host it is typically a SIBLING directory of the design
tree, not a subdirectory of it; find it by locating the vendor databooks
(`find <projects-root> -maxdepth 3 -name '*databook*.pdf' | head`) and
record the binding here.

## Role files — read before working (this is the core rule)

`.claude/agents/*.md` are plain-markdown ROLE definitions (domain rules,
verified landmines, debug playbooks). They are not Claude-specific: ANY
model must, before starting a domain task, READ the matching role file and
follow its rules as its own.

| Task | Role file |
|---|---|
| compile/elab errors (behavioral VCS), build flags, make targets | `dv-build-engineer.md` |
| a test failed — why? (log triage, first diagnosis) | `dv-failure-triage.md` |
| waveform-level evidence (FSDB, X-trace, handshake) | `dv-wave-debugger.md` |
| run/analyze many tests, LSF, bucketing failures | `dv-regression-runner.md` |
| BUILD/extend regression machinery, new flavors/lists, port to new TB | `dv-regression-architect.md` |
| spec → verification plan, complex-condition enumeration, sign-off criteria | `dv-verification-planner.md` |
| architect/stand up a NEW testbench (topology, components, bring-up ladder) | `dv-tb-architect.md` |
| design complex-condition stimulus (concurrency, corners, irritators) | `dv-stimulus-architect.md` |
| checking strategy: SVA/monitors/scoreboards/reference models | `dv-checker-architect.md` |
| coverage model, hole analysis/dispositions, waiver discipline, sign-off | `dv-coverage-closure.md` |
| write/modify a C testcase or shared test lib | `dv-fw-test-author.md` |
| anything DDR/LPDDR4/PhyInit/UMCTL2 | `dv-ddr-specialist.md` |
| anything USB3/DWC3/xtor/host-mode | `dv-usb3-specialist.md` |
| ZeBu compile (incl. ZEBU_SYNTH synthesizability errors)/runtime, sim-vs-emu divergence | `zebu-emulation-engineer.md` |
| anything MIPI CSI-2 / D-PHY / IPI-to-MALI / MIPI xtor | `dv-mipi-specialist.md` |
| system PLL / POR / clock straps / lock budgets / tc16x | `dv-pll-specialist.md` |
| TRNG / entropy path / LFSR seed / tc15x suite | `dv-trng-specialist.md` |
| OTP/PUF macro / LCM lifecycle states & images / KMU keys / S-only windows | `dv-otp-lifecycle-specialist.md` |
| NPU / ISP domain semantics | no specialist YET — create one first (mandatory-creation rule) |
| author design/interface/register-map specs, performance models, spec-change control | `spec-architect.md` |
| IP micro-architecture & RTL design/review, design-side bug verdicts | `rtl-design-engineer.md` |
| DFT: scan/MBIST strategy, RTL testability rules, insertion, ATPG readiness | `dft-engineer.md` |
| SoC integration: bus/address map/clock/reset/power/pinmux/security attach | `soc-integration-engineer.md` |
| synthesis, SDC constraints, timing closure, PPA reports, STA/DFT/PD liaison | `syn-timing-engineer.md` |
| lint / CDC / RDC / formal / UPF-static / GLS strategy & dispositions | `static-signoff-engineer.md` |
| low-power design & verification: power domains/PMU/isolation/retention/wakeup, UPF or RTL-hardwired intent, LP scenarios/coverage, power estimation | `low-power-engineer.md` |
| FPGA prototyping: readiness, partition, board bring-up, real I/O, post-Si support | `fpga-prototype-engineer.md` |
| tape-out readiness: cross-domain sign-off dashboard, waiver debt, go/no-go | `tapeout-signoff-coordinator.md` |
| UVM work (other benches — NOT this TB) | `uvm-verification-engineer.md` |
| deep/recurring error-record analysis → analysis record | `dv-error-analyst.md` |
| design the fix from an analysis record → proposal record | `dv-solution-proposer.md` |
| implement an approved proposal → execution record | `dv-solution-executor.md` |
| where is X documented? place/organize documents | `dv-doc-librarian.md` |
| root cause found / belief falsified → record it | `dv-knowledge-scribe.md` |

**The four verification platform directions** — each owner is responsible
for PLATFORM CONSTRUCTION and PLATFORM MAINTENANCE, not just running tests
(each agent file has dedicated sections for both):

| Platform | Owner | Platform = |
|---|---|---|
| Assembly + C (firmware-driven sim) | `dv-fw-test-author.md` | startup asm, linker/scatter, shared libs, build system, boot/test protocol |
| UVM / SystemVerilog | `uvm-verification-engineer.md` | env skeleton, interfaces/clocking, agents, RAL, VIP wrappers, run flow |
| ZeBu emulation | `zebu-emulation-engineer.md` | compile flow, synthesizable TB, xtors, memory mapping, runtime, regression |
| FPGA prototyping | `fpga-prototype-engineer.md` | readiness/partition, constraints, board bring-up, bitstream releases, farm health |

**Environment-construction flow** (new SoC/IP verification env):
`dv-verification-planner` (what must be proven) → `dv-tb-architect`
(blueprint + skeleton) → `dv-checker-architect` + `dv-stimulus-architect`
(detection + provocation, in parallel) → implementation agents
(fw-test-author / uvm / build / regression-architect) →
`dv-coverage-closure` (measure → dispositions → sign-off).

**Error-handling pipeline:** analyze → propose → execute, with file-based
handoff in `.claude/docs/error-records/` (`<id>-analysis.md` →
`<id>-proposal.md` → `<id>-execution.md`). Each stage refuses work whose
preceding record is missing; risky proposals wait at the APPROVAL gate;
a done execution closes the loop through `dv-knowledge-scribe`.
`dv-failure-triage` remains the fast first responder and feeds this
pipeline when a failure deserves a formal record.

**Vendor-document intake** (databooks, TRMs, app notes, RALF, IP drops):
vendor collateral is READ-ONLY reference truth — never edited, extended,
or "completed" in place. On arrival: `dv-doc-librarian` registers location
+ authority in its doc map → the owning domain specialist runs a
first-pass gap assessment (what it answers, what it leaves ambiguous for
THIS project, contradictions with observed behavior) → project-side
derivations (vplan lines, landmines, work-log notes) are recorded via
`dv-knowledge-scribe` in PROJECT docs, citing the vendor doc by
path + section. Deepening/extension always lands on the project side,
never inside the vendor file.

No matching role? Create one first (design rules: `.claude/agents/README.md`),
register it there and here, then execute through it.

## Orchestration & supervision (for tools with sub-agent support)

The top-level agent is the MANAGER: decompose → brief → launch specialist
sub-agents (parallel when independent, each with question + evidence +
expected deliverable) → integrate → report. Domain work executes inside
sub-agents, not in the manager's context. Tools without sub-agents: adopt
the role file directly and follow its rules yourself.

Supervision rules (no idle limbo, no zombie agents):
- Launching is not done: track every sub-agent/background job to a
  CONFIRMED terminal state (result received, or explicitly stopped). Never
  assume completion without a completion signal or a verified result.
- Set a duration expectation at launch (survey ≈ minutes, debug ≈ tens of
  minutes). Silent far beyond expectation = suspect: check status → nudge
  with a concrete question → if unresponsive/looping, kill it, then
  relaunch with a narrower brief or escalate to the human.
- Use your platform's completion notifications as the primary signal, with
  a periodic fallback status check (~20–30 min); do not busy-wait or poll
  tight loops.
- External machinery (LSF jobs, long sims) follows the same rule at the
  right cadence: `bjobs` / result dirs / log-still-advancing to
  distinguish queued vs running vs hung.
- Every status report to the human lists: running, finished, killed (and
  why).

## Precedence & external executors (Codex, scripts, other AI tools)

Rules bind to the REPO, not to the tool. Anything that works in this tree —
Claude, Codex, Cursor, a script, another model — is governed in this order:

1. The human user's explicit instruction for this task.
2. This `AGENTS.md` (Codex CLI and most agent tools load it natively).
3. The matching role file in `.claude/agents/` — when one agent/tool calls
   an external executor, the CALLER must inject the role file's relevant
   rules and landmines into the brief, because the callee may not read
   `.claude/agents/` on its own.
4. The external tool's own defaults — only where 1–3 are silent.

Accountability stays with the caller: an external executor is a
sub-contractor. Its output is UNVERIFIED input until the caller checks it
against the Iron Rules (evidence quoted, no PASS without proof, no
generated-RTL edits, one variable at a time). Delegation transfers work,
never responsibility; supervision rules above apply to external executors
exactly as to sub-agents.

## Behavior floor — FABLE-PROTOCOL (binds ANY main session)

Every main session driving this repo — regardless of vendor/model — runs
under FABLE-PROTOCOL v1 (codename `FABLE-PROTOCOL-V1-CANARY`): OODA
evidence-first (read before guessing), adversarial review before trusting
major conclusions (root causes, architecture, production-affecting),
fail-then-pass Definition of Done, and honest first-sentence-is-the-result
reporting. Delivery per runtime:

- **Claude Code**: injected by global hooks (`~/.claude/settings.json` →
  `~/fable-harness/.claude/hooks/`).
- **Codex CLI** (main session since 2026-07-06, model gpt-5.5) and other
  AGENTS.md-native tools: `~/.codex/AGENTS.md` → symlink to
  `~/fable-harness/AGENTS.md` (the canonical AGENTS.md edition; the
  adversarial-review personas live in `~/fable-harness/.claude/agents/`,
  spawned as parallel `codex exec` child processes per its §2).

The protocol is a FLOOR UNDER this institution, not a replacement (its
§6): the role files, routing table, and Iron Rules here stay binding.
Codex implements the manager pattern of "Orchestration & supervision"
with `codex exec` children, injecting the matching role file into each
brief per the Precedence section above. If `~/fable-harness` is missing,
this paragraph is the fallback summary and still binds.

## Autonomy boundary — the human gates (flow MUST stop here, by design)

1. Entry: product requirements / the decision to build (specs start from
   a human PRD). 2. PDK/library paths for synthesis. 3. FPGA board/tool
   provisioning. 4. Frequency/timing-budget renegotiation. 5. Costly
   architectural trade-offs flagged by integration. 6. Spec ambiguity
   that is a product call. 7. Error-pipeline APPROVAL gate. 8. Blocked
   after 3 serious attempts → evidence bundle. 9. P2+ bug dispositions.
   10. Waiver-debt / residual-risk acceptance. 11. Sign-off GO/NO-GO
   (coordinator recommends; humans decide). 12. Git commits/tags/pushes
   (consent-gated). Everything between the gates is agent-executable.

**Licensed-IP egress gate (this repo, absolute).** The commercial fabric IP
RTL under `ext/` is licensed third-party IP: never `git add`/commit/push it,
never upload it to a remote/gist/PR/web tool/MCP service, never bundle it or
its simulator artifacts (`sim/synopsys_sim/csrc*`, `simv*`, `*.daidir`) into
anything leaving this machine. Enforced by `.gitignore`; do not override it
(no `git add -f ext/`). Project-authored wrappers, file lists, and Track-B
tests that merely *reference* `ext/` paths are fine to commit. Full policy:
`CLAUDE.md` § "Publish & upload policy".

## Iron Rules

1. Never edit generated RTL; fix `logical/config/iotsoc_user_cfg.yaml` and
   re-render (`shared/tools/bin/render_yaml.sh`). SCOPED EXCEPTION: the
   `…ext_logic_0_socA.sv` HYBRID files (Arm-config-generated base +
   project `[item#]` HAND-EDITS, NO in-repo generator, no yaml knob for
   those blocks) are hand-edited by design — check `[item#]` provenance
   first (details: `soc-integration-engineer.md`, `known-landmines.md`).
2. Test layer here is C firmware, not UVM: `make run TESTNAME=<tc>`, no
   `+UVM_TESTNAME`. Nuance: the bench DOES carry live VIP compile hooks
   (APB_VIP/AXI5_VIP/JTAG_VIP) and regression supports hybrid
   `sim_mode=rtl_uvm_c/uvm_rtl` — that path is owned by
   `uvm-verification-engineer.md`.
3. `DWC_USB_PHY` gate is REMOVED and `USB_HOST=1` is a no-op; tc450–463
   SKIPs are expected (details: `dv-usb3-specialist.md`).
4. DDR init mode is a FIRMWARE `#define` (`DDR_CPU_INIT`/`DDR_SKIP_INIT`),
   not a TB define (details: `dv-ddr-specialist.md`).
5. FSDB waves need `FSDB_DUMP=1` at BOTH compile and run.
6. Never claim PASS without quoting `*** Test PASS ***` + the log path
   (`vcs/log/<tc>_run.log`).
7. Prefer make targets / `regression.py` over hand-rolled tool commands
   (`make help`, `make help-tests`).
8. One variable at a time; reproduce before fixing.
9. First error first — the earliest error is the cause, the rest fallout.
10. Identify the compile mode before debugging: behavioral VCS (no ZeBu
    macro) vs ZEBU_SIM (`ZEBU_SYNTH`+`IOTSOC_SIM_INITS` — the NECESSARY
    pre-emulation function-sign-off world: confirm function in VCS after
    `zebu_compile` without emulator time) vs real ZeBu HW (`ZEBU_SYNTH`).
11. Blocked after 3 serious attempts → stop; give the human an evidence
    bundle (repro command, log excerpts, falsified hypotheses).
12. No documentation for an area? Don't guess: executable truth (Makefile/
    scripts) → code → precedent/git history → safe non-destructive probe →
    ask. Then write the missing doc (protocol: `dv-doc-librarian.md`).

## Quick reference

Commands, log paths, pass criteria: `.claude/docs/quick-reference.md`.
Verified traps (READ before debugging DDR/USB/build):
`.claude/docs/known-landmines.md`. MCP debug servers (TraceWeave/xverif)
workflows + install/recovery: `.claude/docs/mcp-debug-toolbox.md`.
DDR work state: `$OOBTB/ddr_fw_update.md`.
Authoritative human docs: `$OOBTB/README.md`.

## Maintenance contract

These files are living institution, not scripture. When reality and a file
disagree: verify, then fix the file in the same session (format and
destinations: `dv-knowledge-scribe.md`). Findings must outlive the session.

## Communication

- 與使用者以繁體中文溝通；code、log、commit message 維持英文。
- Report failures verbatim (quote the log); never paraphrase an error away.
