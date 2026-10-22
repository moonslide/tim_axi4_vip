# AXI4 VIP Quick Start Guide
Get up and running in 5 minutes with the 10x10 bus matrix. Where this page and `README.md` disagree, `README.md` and the live `sim/synopsys_sim/Makefile` win.

## Prerequisites

✓ Linux system  
✓ Synopsys VCS W-2024.09-SP1 (registered installation)  
✓ Python 3 (standard library only)  
✓ UVM 1.2 (VCS built-in, `-ntb_opts uvm-1.2`)  

## Quick Setup

### 1. Clone Repository
```bash
git clone <repository-url> tim_axi4_vip
cd tim_axi4_vip
```

### 2. Select the Bus Matrix (Optional)
```systemverilog
// include/axi4_bus_config.svh derives the sizes from a compile define -- do not edit it.
//   +define+BUS_MATRIX_10X10  -> NUM_MASTERS 10, NUM_SLAVES 10, ID_MAP_BITS 10
//   (no define)               -> NUM_MASTERS 4,  NUM_SLAVES 4,  ID_MAP_BITS 4
// The runtime reference map is chosen separately: +BUS_MATRIX_MODE=NONE|4x4|ENHANCED
// The performance-metrics module is always built in; there is no define to enable it.
```

### 3. Run Test
```bash
cd sim/synopsys_sim
make sim test=axi4_write_read_test SEED=12345 FSDB_DUMP=0
```
The Make variable is lowercase `test`; `make sim` deletes `simv*`, `csrc*`, FSDB and `*.log` in the current directory first.

### 4. Run Regression
```bash
python3 axi4_regression.py \
  --test-list axi4_transfers_regression.list --cov --lsf
```

🎉 **Expected Result**: every run's own log shows `UVM_ERROR : 0` **and** `TEST RESULT: PASS`. The runner's summary alone is not a verdict (it does not require `TEST RESULT: PASS`). The default list `testlists/axi4_transfers_regression.list` (`sim/synopsys_sim/axi4_transfers_regression.list` is a symlink to it) has 340 entries / 199 distinct entry names / 193 distinct test classes, 800 runs with `run_cnt` expanded, counted on commit `4c555f6`. The last recorded full run (794 runs, 2026-09-20/21, README.md "Full-regression confirmation") was 794/794 functional passes; the entries added since were not part of it.

## Common Commands

| Task | Command |
|------|---------|
| Single test | `make sim test=<name> SEED=<n> FSDB_DUMP=0` |
| With waves | `make sim test=<name>` (`FSDB_DUMP` defaults to 1) |
| Enhanced test | `make sim test=<name> COMMAND_ADD='+define+BUS_MATRIX_10X10 +BUS_MATRIX_MODE=ENHANCED'` |
| Performance KPI test | `make sim test=axi4_saturation_midburst_reset_qos_boundary_test COMMAND_ADD='+define+BUS_MATRIX_10X10 +BUS_MATRIX_MODE=ENHANCED'` |
| Clean build | `make clean` |
| Full regression | `python3 axi4_regression.py --test-list axi4_transfers_regression.list` |
| With LSF & coverage | Add `--lsf --cov` |
| Failed tests only | `python3 axi4_regression.py --test-list regression_result_<timestamp>/no_pass_list` |

## Pro Tips

💡 Pass the topology explicitly; the Makefile's test-name auto-detection is unreliable  
💡 Use scalable ID macros  
💡 Check `regression_result_<timestamp>/logs/no_pass_logs/` for errors  
💡 Any compile define change needs a full recompile  
💡 Use `--lsf --cov` for parallel execution  
💡 Read each run's own log for both pass gates before reporting a PASS

## ⚡ Features

- ✅ **10x10 Bus Matrix**: 10-master × 10-slave configuration
- ✅ **Performance KPIs**: 6 metrics printed by `axi4_performance_metrics` in report_phase
- ✅ **Test Suite**: 231 test classes in `test/` (9 of them base classes); the default regression list runs 193 of them (see Expected Result), including 6 performance KPI tests × 3 bus modes = 18 entries
- ✅ **Performance Metrics Module**: Built-in `axi4_performance_metrics.sv`
- ✅ **QoS Support**: AWQOS/ARQOS value stimulus and slave read-side priority selection; write-side QoS arbitration is not effectively exercised in the default (legacy) mode, the AWQOS master-vs-slave compare is off by default, and Track-B verifies no QoS behaviour. Optional knobs and their limits: README.md "QoS control knobs"
- ✅ **USER Signals**: 8 USER signal tests for security tagging and transaction tracing
- ✅ **3 Bus Matrix Modes**: NONE (1×1), BASE (4×4), ENHANCED (10×10) — on the baseline build these select the reference model's address map; there is no interconnect in that build
- ✅ **Security Features**: AxPROT-dependent privilege/security access rules in the ENHANCED reference map
- ✅ **Track-B**: the same VIP against a licensed commercial fabric IP (4×4 and 10×10), built from its own file lists; see "Track-B" below

**Key Performance Indicators** (printed values; no threshold is applied to them):
- 📊 Throughput (GB/s)
- 📈 Latency Distribution (p50/p95/p99)
- 🔄 Retry Rate
- ⚡ Reset Recovery Time
- 🛡️ Issue Isolation Rate
- ⚖️ Arbitration Fairness

The metrics verdict (`TEST RESULT`) checks only: protocol issues = 0, no deadlock, no livelock.

## Track-B

Track-B replaces the 1:1 direct wiring with the commercial fabric IP. Its RTL is licensed, local-only and never committed or uploaded (README.md "Licensed-IP boundary"). Build it with `-f ../../sim/axi4_compile_fabric_ip.f` (10×10) or `-f ../../sim/axi4_compile_fabric_ip_4x4.f` plus `+define+FABRIC_IP_4X4` (4×4) and the Track-B defines; full commands: README.md "Track-B: commercial fabric as DUT". `axi4_regression.py` compiles the baseline file list; `testlists/axi4_trackb_nonnative.list` adds the fabric per entry through `command_add`. `bash ../run_fabric_smoke.sh` (from `sim/synopsys_sim/`) exercises the 10×10 fabric without the VIP. Evidence and open items: `TRACKB_DEBUG_NOTES.md`.

## Troubleshooting

### If Tests Fail:
1. **Read the first error**: `UVM_ERROR`/`UVM_FATAL` in the run's own log
2. **Check log files**: `regression_result_<timestamp>/logs/no_pass_logs/`
3. **Run with debug**: `+UVM_VERBOSITY=UVM_HIGH`; slave-driver messages carry the report ID `SLAVE_DRIVER_DEBUG` (a message ID, not a define)
4. **Check the metrics banner**: `TEST RESULT:` in the same log

### Enhanced Mode Debugging:
```bash
# Check the bound topology (TEST_CONFIG summary; some lines need +UVM_VERBOSITY=UVM_MEDIUM)
grep -E "TEST_CONFIG|BUS_MATRIX_MODE" <test>.log

# Performance KPIs (report_phase)
grep -A 30 "KEY PERFORMANCE INDICATORS" <test>.log

# Pass gates
grep -E "TEST RESULT:|UVM_(ERROR|FATAL) *:" <test>.log

# QoS values printed by the QoS sequences (stimulus only, not an arbitration check)
grep "QoS Priority" <test>.log
```

## Need Help?

📚 Full reference: `README.md` (authoritative); `doc/AXI4_VIP_User_Guide.html`  
🐛 Track-B evidence and open items: `TRACKB_DEBUG_NOTES.md`  
✅ **Status**: counts above taken on commit `4c555f6` (2026-10-22); pass status per README.md "Full-regression confirmation"
