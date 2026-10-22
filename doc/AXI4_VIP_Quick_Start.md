# AXI4 VIP Quick Start Guide - Version 2.8
Get up and running in 5 minutes with the enhanced 10x10 bus matrix! ✅ **100% Pass Rate Verified**

## Prerequisites

✓ Linux system  
✓ Synopsys VCS 2024.09+  
✓ Python 3.6+  
✓ UVM 1.2  

## Quick Setup

### 1. Clone Repository
```bash
git clone https://github.com/your-org/axi4_vip.git
cd axi4_vip
```

### 2. Configure Enhanced Bus Matrix (Optional)
```systemverilog
// Edit include/axi4_bus_config.svh for enhanced mode
`define NUM_MASTERS 10          // Enhanced 10x10 matrix
`define NUM_SLAVES 10
`define BUS_MATRIX_10X10        // Enable enhanced features
`define RUN_10X10_CONFIG 
`define ID_MAP_BITS 16
`define ENABLE_PERFORMANCE_METRICS  // Real-time KPI monitoring
```

### 3. Run Test
```bash
cd sim/synopsys_sim
make TEST=axi4_write_read_test
```

### 4. Run Regression
```bash
python3 axi4_regression.py \
  --test-list axi4_transfers_regression.list --cov --lsf
```

🎉 **Expected Result**: 100% PASS (All 141 tests pass - 123 standard + 18 performance KPI tests)

## Common Commands

| Task | Command |
|------|---------|
| Single test | `make TEST=<name>` |
| With waves | `make TEST=<name> WAVES=1` |
| Enhanced test | `make TEST=<name> DEFINES="+define+BUS_MATRIX_10X10 +define+RUN_10X10_CONFIG"` |
| Performance KPI test | `make TEST=axi4_saturation_midburst_reset_qos_boundary_test DEFINES="+define+BUS_MATRIX_10X10"` |
| Clean build | `make clean` |
| Full regression | `python3 axi4_regression.py --test-list axi4_transfers_regression.list` |
| With LSF & coverage | Add `--lsf --cov` |
| KPI report | `python3 scripts/generate_kpi_report.py --dir regression_result_*` |
| Failed tests only | `python3 axi4_regression.py --test-list regression_result_*/no_pass.list` |

## Pro Tips

💡 Always include `axi4_bus_config.svh`  
💡 Use scalable ID macros  
💡 Check `*/logs/no_pass_logs/` for errors  
💡 Run `make clean` when changing config  
💡 Use `--lsf --cov` for parallel execution  
💡 All tests should pass - if not, check troubleshooting guide

## ⚡ Features (v2.8)

🚀 **Version 2.8** - Complete and Production-Ready:

- ✅ **10x10 Bus Matrix**: Revolutionary 10-master × 10-slave configuration
- ✅ **Real-Time Performance KPIs**: 6 comprehensive metrics with live monitoring
- ✅ **141 Test Suite**: 123 standard + 18 performance KPI tests (21 fixed in v2.8)
- ✅ **Performance Metrics Module**: Built-in `axi4_performance_metrics.sv`
- ✅ **QoS Support**: AWQOS/ARQOS value stimulus and slave read-side priority selection; write-side QoS arbitration is not effectively exercised in the default (legacy) mode, the AWQOS master-vs-slave compare is off by default, and Track-B verifies no QoS behaviour. Optional knobs and their limits: README.md "QoS control knobs"
- ✅ **USER Signals**: 8 USER signal tests for security tagging and transaction tracing
- ✅ **3 Bus Matrix Modes**: NONE (1×1), BASE (4×4), ENHANCED (10×10)
- ✅ **Security Features**: AxPROT privilege/security access control verification

**Key Performance Indicators**:
- 📊 Throughput (GB/s)
- 📈 Latency Distribution (p50/p95/p99)
- 🔄 Retry Rate (< 5%)
- ⚡ Reset Recovery Time (< 100 cycles)
- 🛡️ Error Isolation Rate (> 99%)
- ⚖️ Arbitration Fairness (> 0.9)

## Troubleshooting

### If Tests Fail:
1. **Update to v2.8** - All 21 regression failures resolved
2. **Check log files**: `regression_result_*/logs/no_pass_logs/`
3. **Run with debug**: `+UVM_VERBOSITY=UVM_HIGH +define+SLAVE_DRIVER_DEBUG`
4. **Enable KPI monitoring**: `+define+ENABLE_PERFORMANCE_METRICS`

### Enhanced Mode Debugging:
```bash
# Check enhanced configuration
grep "BUS_MATRIX_10X10" <test>.log

# Monitor performance KPIs
grep "KPI:" <test>.log | grep -E "Throughput|Latency|Retry|Fairness"

# Verify bus matrix connections
grep "Master\[.*\] -> Slave\[.*\]" <test>.log

# QoS values printed by the QoS sequences (stimulus only, not an arbitration check)
grep "QoS Priority" <test>.log
```

## Need Help?

📚 Full Guide: `doc/AXI4_VIP_User_Guide.html`  
📧 Support: axi4_vip_support@company.com  
🐛 Issues: GitHub Issues page  
✅ **Status**: Version 2.8 - All 141 tests passing with real-time KPI monitoring
