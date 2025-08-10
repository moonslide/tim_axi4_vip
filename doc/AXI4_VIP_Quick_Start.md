# AXI4 VIP Quick Start Guide
Get up and running in 5 minutes! ✅ **100% Pass Rate Verified**

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

### 2. Configure Bus Size (Optional)
```systemverilog
// Edit include/axi4_bus_config.svh
`define NUM_MASTERS 10  // For 10x10 matrix
`define NUM_SLAVES 10
`define ID_MAP_BITS 16
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

🎉 **Expected Result**: 100% PASS (All 113 tests pass)

## Common Commands

| Task | Command |
|------|---------|
| Single test | `make TEST=<name>` |
| With waves | `make TEST=<name> WAVES=1` |
| Clean build | `make clean` |
| Regression | `python3 axi4_regression.py --test-list <list>` |
| With LSF | Add `--lsf --cov` |
| Failed tests only | `python3 axi4_regression.py --test-list regression_result_*/no_pass.list` |

## Pro Tips

💡 Always include `axi4_bus_config.svh`  
💡 Use scalable ID macros  
💡 Check `*/logs/no_pass_logs/` for errors  
💡 Run `make clean` when changing config  
💡 Use `--lsf --cov` for parallel execution  
💡 All tests should pass - if not, check troubleshooting guide

## ⚡ Recent Improvements (v2.1)

🔧 **100% Pass Rate Achieved** - All critical bugs fixed:

- ✅ **Config DB Issues**: Fixed bus matrix reference access
- ✅ **Address 0x0 Spurious Errors**: Constrained dummy transactions  
- ✅ **Response Mismatches**: Fixed SLAVE_MEM_MODE handling
- ✅ **QoS Mode**: Corrected address handling

**Before**: 16 failing tests  
**After**: 0 failing tests (100% pass rate)

## Troubleshooting

### If Tests Fail:
1. **Update to latest version** - Most issues are fixed in v2.1
2. **Check log files**: `regression_result_*/logs/no_pass_logs/`
3. **Run with debug**: `+UVM_VERBOSITY=UVM_HIGH +define+SLAVE_DRIVER_DEBUG`

### Common Fixes:
```bash
# Response mismatch errors (v2.1 fix applied)
grep "Response mismatch" <test>.log

# Config DB errors (v2.1 fix applied)  
grep "Bus matrix reference not found" <test>.log

# Check for address 0x0 issues (v2.1 fix applied)
grep "awaddr.*0x0" <test>.log
```

## Need Help?

📚 Full Guide: `doc/AXI4_VIP_User_Guide.html`  
📧 Support: axi4_vip_support@company.com  
🐛 Issues: GitHub Issues page  
✅ **Status**: All known issues resolved in v2.1
