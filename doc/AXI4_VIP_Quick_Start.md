# AXI4 VIP Quick Start Guide
Get up and running in 5 minutes!

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
python3 axi4_regression_makefile.py \
  --test-list axi4_transfers_regression.list --cov
```

## Common Commands

| Task | Command |
|------|---------|
| Single test | `make TEST=<name>` |
| With waves | `make TEST=<name> WAVES=1` |
| Clean build | `make clean` |
| Regression | `python3 axi4_regression_makefile.py --test-list <list>` |
| With LSF | Add `--lsf --parallel 10` |

## Pro Tips

💡 Always include `axi4_bus_config.svh`  
💡 Use scalable ID macros  
💡 Check `*/logs/no_pass_logs/` for errors  
💡 Run `make clean` when changing config  
💡 Use `--parallel` for speed  

## Need Help?

📚 Full Guide: `doc/AXI4_VIP_User_Guide.pdf`  
📧 Support: axi4_vip_support@company.com  
🐛 Issues: GitHub Issues page  
