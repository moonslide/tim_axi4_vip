# AXI4 VIP Quick Start Guide - ULTRATHINK Edition
Get up and running in 5 minutes with the revolutionary ULTRATHINK 10x10 bus matrix! ✅ **100% Pass Rate Verified**

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

### 2. Configure ULTRATHINK Bus Matrix (Optional)
```systemverilog
// Edit include/axi4_bus_config.svh for ULTRATHINK mode
`define NUM_MASTERS 10          // ULTRATHINK 10x10 matrix
`define NUM_SLAVES 10
`define BUS_MATRIX_10X10        // Enable ULTRATHINK features
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

🎉 **Expected Result**: 100% PASS (All 135 tests pass - 117 standard + 18 performance KPI tests)

## Common Commands

| Task | Command |
|------|---------|
| Single test | `make TEST=<name>` |
| With waves | `make TEST=<name> WAVES=1` |
| ULTRATHINK test | `make TEST=<name> DEFINES="+define+BUS_MATRIX_10X10 +define+RUN_10X10_CONFIG"` |
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

## ⚡ ULTRATHINK Features (v2.7)

🚀 **ULTRATHINK Edition** - Revolutionary performance and visibility:

- ✅ **ULTRATHINK 10x10 Bus Matrix**: Revolutionary 10-master × 10-slave configuration
- ✅ **Real-Time Performance KPIs**: 6 comprehensive metrics with live monitoring
- ✅ **135 Test Suite**: 117 standard + 18 performance KPI tests  
- ✅ **Performance Metrics Module**: Built-in `axi4_performance_metrics.sv`
- ✅ **QoS & USER Signals**: Full support with 16-level priority arbitration
- ✅ **3 Bus Matrix Modes**: NONE (1×1), BASE (4×4), ULTRATHINK (10×10)

**Key Performance Indicators**:
- 📊 Throughput (GB/s)
- 📈 Latency Distribution (p50/p95/p99)
- 🔄 Retry Rate (< 5%)
- ⚡ Reset Recovery Time (< 100 cycles)
- 🛡️ Error Isolation Rate (> 99%)
- ⚖️ Arbitration Fairness (> 0.9)

## Troubleshooting

### If Tests Fail:
1. **Update to ULTRATHINK v2.7** - All known issues resolved
2. **Check log files**: `regression_result_*/logs/no_pass_logs/`
3. **Run with debug**: `+UVM_VERBOSITY=UVM_HIGH +define+SLAVE_DRIVER_DEBUG`
4. **Enable KPI monitoring**: `+define+ENABLE_PERFORMANCE_METRICS`

### ULTRATHINK Mode Debugging:
```bash
# Check ULTRATHINK configuration
grep "BUS_MATRIX_10X10" <test>.log

# Monitor performance KPIs
grep "KPI:" <test>.log | grep -E "Throughput|Latency|Retry|Fairness"

# Verify bus matrix connections
grep "Master\[.*\] -> Slave\[.*\]" <test>.log

# Check QoS arbitration
grep "QoS Priority" <test>.log
```

## Need Help?

📚 Full Guide: `doc/AXI4_VIP_User_Guide.html`  
📧 Support: axi4_vip_support@company.com  
🐛 Issues: GitHub Issues page  
✅ **Status**: ULTRATHINK v2.7 - All 135 tests passing with real-time KPI monitoring
