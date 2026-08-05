# tim_axi4_vip — project CLAUDE.md (DV institution binding)

AXI4 UVM VIP: 10 masters x 10 slaves, three bus-matrix modes
(NONE 1x1 / BASE 4x4 / ENHANCED 10x10). Verification plan lives in
`claude.md` (lowercase — historical name, it is the 10x10 access-matrix
spec, NOT this config file).

## Operating model (universal — do not weaken)

- **Delegate-first**: substantive tasks route to `.claude/agents/` specialists
  (routing table in `AGENTS.md`). If no agent matches, create one per
  `.claude/agents/README.md` design rules BEFORE doing the work inline.
- Findings outlive the session: new traps go to
  `.claude/docs/known-landmines.md` via dv-knowledge-scribe discipline;
  docs referenced-but-missing are findings, not annoyances.
- Fix at the correct layer; first error first; one change at a time;
  fail-then-pass evidence for every functional claim.

## Project binding (verified by execution, 2026-08-01)

### Build & run (VCS W-2024.09-SP1, from `sim/synopsys_sim/`)
```bash
# baseline (1:1 direct wiring, DATA_WIDTH=1024, ID=4b)
vcs -full64 -lca -kdb -sverilog +v2k -debug_access+all -ntb_opts uvm-1.2 \
    -override_timescale=1ps/1ps +nospecify +no_timing_check \
    -f ../../sim/axi4_compile.f -o simv
./simv +UVM_TESTNAME=<test> +UVM_VERBOSITY=UVM_LOW

# Track-B (real commercial fabric IP DUT in ext/nic400_vipv3b)
#   +define+BUS_MATRIX_FABRIC_IP +define+DATA_WIDTH=256 +define+AXI_ID_WIDTH=8 +define+AXI_ID_LAST=255
#   -f ../../sim/axi4_compile_fabric_ip.f
#   run with +BUS_MATRIX_MODE=ENHANCED
#   optional +define+FABRIC_IP_DEBUG_PROBE for fabric-boundary tracing

# fabric-only sanity (no UVM), ALSO run from sim/synopsys_sim/ (the script's own
# header says so; it resolves its file lists relative to that cwd):
#   bash ../run_fabric_smoke.sh          # expect 3/3 PASS
# Note it compiles the 10x10 wrapper only (fabric_ip_rtl.f) — a PASS says nothing
# about the 4x4 drop.
```

### Test mechanics
- Test select: `+UVM_TESTNAME=<class>`; bus mode override `+BUS_MATRIX_MODE=NONE|4x4|ENHANCED`.
- Pass criteria: `UVM_ERROR : 0` summary AND perf-metrics
  `TEST RESULT: PASS` (report_phase consumes deadlock/livelock flags for
  EVERY test — `env/axi4_performance_metrics.sv:483-509`).
  Both halves are load-bearing and neither implies the other: `TEST RESULT: PASS`
  never consults the UVM error count (landmine 39), and a run that dies at time 0
  reports `UVM_ERROR : 0` (landmine 15). Read the run's own UVM summary first.
- Regression lists — TWO DIFFERENT LISTS, not synced copies (corrected 2026-08-05):
  * `testlists/axi4_transfers_regression.list` is the **authoritative default**:
    `sim/synopsys_sim/axi4_transfers_regression.list` is a SYMLINK to it, so this
    is what `axi4_regression.py` runs when no `--test-list` is given.
    301 entries / 180 distinct tests.
  * `sim/axi4_transfers_regression.list` is a smaller, separate set
    (151 entries / 139 distinct tests) used when passed explicitly.
  * Content relationship, measured: testlists ⊃ sim except for exactly one test
    (`axi4_write_test`). So a test registered ONLY in `sim/...` will never run by
    default — register new tests in `testlists/...` first, and in both when the
    test is meant for the smaller sample too.
- Timeout defines are doubly defined (`include/` 10s vs `test/` 10ms) —
  include-order decides; see landmines.

### Coverage scope (decided 2026-08-02)
- Code coverage is measured **to the fabric interface only**. The commercial
  fabric IP internals are licensed third-party IP, delivered pre-verified, and golden
  here (iron rule 1) - they are not a VIP verification target and ~300 .v files
  of them in the denominator only deflate LINE/TOGGLE.
- Enforced at instrumentation time, not in the report:
  `vcs ... -cm_hier ../../sim/coverage_scope.cm_hier`
  which keeps `hdl_top` and `u_fabric_ip` (our wrapper) and drops
  `u_fabric_ip.u_fabric` (the generated fabric IP).
- Functional coverage has no such carve-out: the covergroups live in the VIP
  and all of them count.

### Key documents
- `claude.md` — 10x10 access matrix + address map (authoritative spec)
- `VIP_future.md` — improvement plan (rev 3, post adversarial review)
- `TRACKB_DEBUG_NOTES.md` — fabric IP integration evidence chain + open items
- `AXI-Case-list.csv`, `doc/testcase_matrix.csv` — case status
  (matrix.csv had stale fake-PASS entries; verify before trusting)

## Publish & upload policy (HARD GATE — no exceptions without human consent)

**Never upload the commercial fabric IP RTL.** The licensed fabric IP deliverable
under `ext/` (`nic400_vipv3b/`, `nic400_vip4x4q/` — ~705 RTL files) is licensed
third-party IP. It is local-only.

Forbidden without explicit, per-instance human approval — for `ext/**` and
any file derived from it:
- `git add` / commit / push (incl. `git add -A|.`, and NEVER `git add -f ext/`)
- upload to GitHub/GitLab/any remote, gist, PR, or issue attachment
- paste into web tools, MCP services, artifacts, or any external endpoint
- inclusion in tarballs/archives/release bundles intended to leave this machine
- simulator artifacts built from it: `csrc*/`, `simv*`, `*.daidir/` under
  `sim/synopsys_sim/` (they embed elaborated ARM design data)

Enforced mechanically by `.gitignore` (`ext/` + build artifacts). The
`.gitignore` entry is part of the policy — do not remove or override it.

**What IS ours and may be committed** (project-authored, no ARM source inside):
`top/axi4_fabric_ip_wrapper*.sv`, `sim/axi4_compile_fabric_ip*.f`, `sim/fabric_ip*.f` file lists,
`sim/run_fabric_smoke.sh`, `test/axi4_trackb_*`, `seq/master_sequences/axi4_master_trackb_*`,
`TRACKB_DEBUG_NOTES.md`. These reference `ext/` by *path* only — that is fine;
never inline ARM RTL source into them to "make them self-contained".

Before ANY commit/push touching Track-B: run `git status --short` and confirm
no `ext/` path appears. If one does, stop and tell the human — do not `git rm`
history silently.

### Iron rules (project)
1. ARM RTL under `ext/` is golden — never patch it; fix the VIP side.
   It is also NEVER uploaded — see "Publish & upload policy" above.
2. Any BFM/proxy change must re-run the baseline regression sample
   (12+ tests, see TRACKB_DEBUG_NOTES) AND `run_fabric_smoke.sh` before claim.
3. Landmines must be earned in THIS repo — never import from other projects.
4. `claude.md` (lowercase) is the spec; do not overwrite it with config.
