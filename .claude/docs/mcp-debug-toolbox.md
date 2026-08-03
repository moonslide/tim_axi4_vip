# MCP Debug Toolbox — TraceWeave + xverif

Owned by `dv-wave-debugger` / `dv-failure-triage`. How the debug MCP servers
are installed, health-checked, auto-recovered, and used well.

## Inventory (verified 2026-07-03, global stdio servers in ~/.claude.json)

| Server | Launch | Source / recovery |
|---|---|---|
| **TraceWeave** | `python3.11 ~/Projects/mcp/TraceWeave/server.py` | local project at `~/Projects/mcp/TraceWeave` |
| **xverif** | `~/xverif/tools/xverif-mcp` | github.com/BLANK2077/xverif → clone to `~/xverif` |

## Health check & auto-install (run when MCP tools are expected but absent)

1. Confirm absence properly: search the session's tool list (ToolSearch for
   `traceweave` / `xverif`) — tools are deferred, not always visible.
2. If configured but dead: check the launch path exists
   (`ls ~/Projects/mcp/TraceWeave/server.py ~/xverif/tools/xverif-mcp`) and
   that `python3.11` is on PATH. Fix the local install first.
3. If xverif is missing entirely, it MAY be re-fetched:
   `git clone https://github.com/BLANK2077/xverif ~/xverif` (then follow its
   README build steps), and register:
   `claude mcp add xverif -s user -- ~/xverif/tools/xverif-mcp`
4. If TraceWeave's directory is gone: there is no known public remote —
   STOP and ask the user; do not substitute something else silently.
5. Registration changes need a session restart to take effect — tell the
   user instead of retrying in-session.
6. **Consent rule: installing/updating any NEW or unlisted MCP server
   (anything not in this table) requires explicit user approval first.**
   Downloading code that will run locally is an outward-facing action.
7. No MCP at all and user unavailable? Degrade gracefully: Verdi/grep/
   readmemh-level debugging still works — say which tool tier you used.

## TraceWeave — waveform/log/hierarchy debug (canonical workflow)

Order matters; each step feeds the next:
1. `get_diagnostic_snapshot` — FIRST, zero-cost; shows what's already
   cached; skip completed steps.
2. `get_sim_paths` — discovers logs/waves/simulator. Check discovery_mode;
   if `unknown`, follow hints, don't guess paths. Prefer elaborate-phase
   compile_log; prefer .vcd if fsdb_runtime disabled.
3. `build_tb_hierarchy` + `scan_structural_risks` — in PARALLEL (both parse
   the same compile log). If `ambiguous_basenames` non-empty → resolve via
   `lookup_tb_files` before reading ANY source file.
4. Targeted tools by symptom:
   - log first: `parse_sim_log`, `get_error_context`, `analyze_failures`
   - X hunting: `trace_x_source` (fix at origin, never downstream)
   - dead handshake: `inspect_handshake`, `sweep_handshakes`,
     `suggest_handshakes`
   - who drives/reads: `explain_signal_driver`, `find_signal_loads`,
     `trace_signal_path`
   - activity windows: `get_signal_transitions`, `get_signals_around_time`
     (narrow the window from run-log timestamps first — big fsdb is slow)
   - pass-vs-fail: `diff_first_divergence`, `diff_sim_failure_results`
   - bus-level: `reconstruct_transactions`, `suggest_protocol_bundles`
   - stuck? `recommend_failure_debug_next_steps`

## xverif — deterministic verification queries

- Stateful backends (may run via LSF): `xverif_debug_session_open` →
  `xverif_debug_query` → close; coverage likewise (`xverif_cov_*`).
- **Use `xverif_batch` for open→query→close sequences** (avoids racing a
  query before the session is ready). Note nested-args shape: outer `args`
  = MCP params, inner `args` = action arguments.
- On `SESSION_LOST`: server already cleaned up; you MUST explicitly reopen
  (no auto-retry). If terminal_source=transport/timeout, narrow the query
  scope or raise timeout env vars — tell the user the trade-off.
- Stateless helpers (call directly): `xverif_bit_*` (bit-field decode/
  eval/slice), `xverif_sva_*` (assertion parse/explain), `xverif_loc_*`,
  `xverif_entry_*`, `xverif_wave_*` (value-at, changes, render).
- Start any unfamiliar session with `xverif_tools` / `xverif_tool_help`.

## Technique rules (apply regardless of tool)

- State the hypothesis + discriminating observation BEFORE querying waves.
- Evidence = `signal @ time = value` triples, log `path:line` quotes.
- Check clock/reset/power-state of a domain before interpreting its signals.
- Prefer structured MCP queries over hand-grepping 100MB logs; prefer
  narrow time windows over whole-run scans.
- Wave missing? FSDB_DUMP=1 must be set at BOTH compile and run.
- **TraceWeave FSDB time unit is FEMTOSECONDS** (verified 2026-07-04): the raw
  `time_ps` field is actually femtoseconds — `real_ns = raw / 1e6`. An
  uncalibrated read produced a completely wrong (later retracted) verdict. ALWAYS
  calibrate the time axis against a known log anchor (e.g. the `Test Ended` UART
  timestamp) before trusting any `signal @ time = value`; the sim end time bounds
  every legitimate edge, so an "edge" past sim-end means your units are off.
- **FSDB files are keyed on TESTNAME and OVERWRITTEN on rerun**:
  `vcs/log/<TESTNAME>.fsdb` — a second run of the same test (or a second session
  in the same `vcs/`) silently clobbers it. Archive/rename before rerunning if
  you need the prior waves.
- **`-debug_access+all` is ELABORATION-time, ignored on the RUN line**: passing
  it to the simv run command is silently dropped (RT_UO warning). `ucli force` /
  visibility of internal nets requires it at COMPILE (`VCS_DEBUG_ALL=1` Makefile
  knob). And a FAILED `ucli force` aborts the whole tcl script — remaining forces
  and `run` never execute (zero sim time, empty FSDB that mimics a hang).
