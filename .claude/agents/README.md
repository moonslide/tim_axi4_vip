# IOTSOC DV Agent Suite

Specialist agent definitions for this workspace, modeled on the
[agency-agents](https://github.com/msitarzewski/agency-agents) pattern
(identity → mission → critical rules → workflow) but grounded in the real
IOTSOC OOB testbench. Authored 2026-07-03 in a Fable 5 session with the
explicit goal of encoding senior-level judgment for future smaller-model
sessions. Routing table lives in the repo-root `AGENTS.md` (the shared,
tool-agnostic constitution); `CLAUDE.md` carries only the Claude-Code layer.
New agents must be registered in BOTH this README's table and AGENTS.md.

| Agent | Owns |
|---|---|
| `dv-build-engineer` | VCS/xrun compile & elab, make targets, defines, 3 compile modes |
| `dv-failure-triage` | First response to any failing/hanging test; classification & routing |
| `dv-wave-debugger` | FSDB/Verdi/TraceWeave/xverif signal-level evidence |
| `dv-regression-runner` | regression.py, test lists, LSF, failure bucketing |
| `dv-regression-architect` | BUILDING regression machinery: flavors, lists, fresh-checkout setup, ports |
| `dv-fw-test-author` | C testcases, tests/lib, ROM budgets, arm-none-eabi flow |
| `dv-ddr-specialist` | LPDDR4 UMCTL2/PHY, PhyInit FW, HWEMUL, DFI |
| `dv-usb3-specialist` | DWC3, UTMI xtor, host mode, event rings, USB test lists |
| `dv-mipi-specialist` | DWC CSI-2 host/RX D-PHY, IPI→MALI path, serial BFM vs DV_PHY_MDL vs MIPI xtor, tc300+ |
| `dv-pll-specialist` | DWC 3GHz system PLL/POR, clock straps/lock budgets, real-vs-behavioral clock worlds, tc16x |
| `dv-trng-specialist` | DWC TRNG core (PILL slot 2), entropy path/LFSR seed, stub-vs-real, tc15x (orphaned suite) |
| `dv-otp-lifecycle-specialist` | PUF/OTP macro, LCM lifecycle states/images, KMU keys, S-only windows, model-swap gate |
| `zebu-emulation-engineer` | ZeBu flows, xtors, sim-vs-emulation divergence |
| `uvm-verification-engineer` | UVM methodology — for OTHER benches (this TB has no UVM) |
| `spec-architect` | design/interface/register-map specs (single source of truth), perf models |
| `rtl-design-engineer` | IP micro-architecture + synthesizable RTL, design-side bug verdicts |
| `dft-engineer` | scan/MBIST strategy, testability rules, insertion, ATPG readiness |
| `soc-integration-engineer` | SoC top integration: maps, clock/reset/power trees, security attach |
| `syn-timing-engineer` | synthesis, SDC, timing closure, PPA, STA/DFT/PD liaison |
| `static-signoff-engineer` | lint/CDC/RDC/formal/UPF-static/GLS dispositions |
| `low-power-engineer` | power domains/PMU/iso/retention/wakeup semantics, LP vplan+review, power estimation |
| `fpga-prototype-engineer` | FPGA readiness/partition/board bring-up/real I/O, post-Si support |
| `tapeout-signoff-coordinator` | cross-domain readiness dashboard, waiver debt, go/no-go rec |
| `dv-verification-planner` | spec → vplan, complex-condition enumeration, sign-off criteria |
| `dv-tb-architect` | NEW testbench architecture: topology, component table, bring-up ladder |
| `dv-stimulus-architect` | complex-condition scenario design with provocation proof |
| `dv-checker-architect` | SVA/monitor/scoreboard strategy: failure mode → detection mechanism |
| `dv-coverage-closure` | coverage model, hole dispositions, waiver discipline, sign-off |
| `dv-error-analyst` | Pipeline stage 1: error records → structured analysis record (read-only) |
| `dv-solution-proposer` | Pipeline stage 2: analysis → ranked options + execution/verify/rollback plan |
| `dv-solution-executor` | Pipeline stage 3: approved plan → faithful execution + evidence record |
| `dv-doc-librarian` | Document management/access: doc map, placement, dedup, serving refs |
| `dv-knowledge-scribe` | Turning findings into durable records; correcting stale ones |

Shared knowledge docs live in `../docs/` (`quick-reference.md`,
`known-landmines.md`) — placement governed by `dv-doc-librarian`.

Design rules for every agent in this suite: a detailed frontmatter
description (scope, concrete triggers, deliverables — routing depends on
it); a `model:` tier in frontmatter (coding/execution-heavy → `sonnet`,
thinking/judgment-heavy → `opus`; aliases always resolve to the latest
version); a "Delegation — open sub-agents when it pays" section (agents
are expected to spawn Explore/general-purpose/fellow-specialist sub-agents
in parallel rather than grind inline, handing over a precise question plus
evidence); and domain landmines recorded with their Trap (what a naive
debugger would wrongly conclude).

Maintenance contract: when an agent's guidance is found wrong, fix the agent
file in the same session (see `dv-knowledge-scribe`). These files are the
institution; keep them true.
