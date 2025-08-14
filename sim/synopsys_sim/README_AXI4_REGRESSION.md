# AXI4 VIP 18-Case Comprehensive Regression Guide

## Overview
The `axi4_transfers_regression.list` contains 18 comprehensive test cases covering all 3 bus matrix modes with complete performance KPI measurements.

## Test Configuration
- **6 Base Tests** × **3 Bus Matrix Modes** = **18 Total Test Cases**
- Each test runs 5 iterations with automatic seed generation
- All tests include comprehensive performance metrics reporting

### Bus Matrix Modes
1. **NONE Mode (1x1)**: Basic AXI4 protocol without bus matrix complexity
2. **BASE Mode (4x4)**: Traditional 4x4 bus matrix configuration  
3. **ENHANCED Mode (10x10)**: Full 10x10 enhanced bus matrix with advanced KPI tracking

### Core Test Cases (Applied to Each Mode)
1. `axi4_blocking_write_read_test` - Basic blocking operations
2. `axi4_non_blocking_write_read_test` - Basic non-blocking operations
3. `axi4_blocking_incr_burst_write_read_test` - INCR burst operations
4. `axi4_blocking_unaligned_addr_write_read_test` - Unaligned address patterns
5. `axi4_blocking_outstanding_transfer_write_read_test` - Outstanding transfers stress
6. `axi4_blocking_slave_error_write_read_test` - Error response handling

## Performance KPIs Measured (All Tests)
Each test automatically collects and reports these 6 KPIs per `axi_stress_reset_test.md`:

1. **Throughput (GB/s)** - Write/Read/Combined throughput measurements
2. **Latency Distribution (p50/p95/p99)** - Transaction latency percentiles  
3. **Retry Rate (%)** - Percentage of retried transactions
4. **Reset Recovery Time** - Time to recover from reset events
5. **Error Isolation Rate (%)** - Percentage of errors properly isolated
6. **Arbitration Fairness** - Jain's fairness index for bus matrix arbitration

## Acceptance Criteria
- **Pass**: Protocol Checker 0 error, no deadlock/livelock, scoreboard 100% consistency
- **KPI**: All 6 metrics measured and reported with PASS/FAIL determination

## Running the Regression

### Sequential Execution (Recommended)
```bash
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --verbose
```

### Parallel Execution (4 workers)
```bash
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --verbose -p 4
```

### With Coverage Collection
```bash
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --cov --verbose
```

### With Extended Timeout (for large designs)
```bash
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --timeout 1200 --verbose
```

## Results Analysis

### Automatic Result Collection
The script creates timestamped results folder `regression_result_YYYYMMDD_HHMMSS/` containing:
- `logs/pass_logs/` - All passing test logs
- `logs/no_pass_logs/` - All failing test logs  
- `no_pass_list` - List of failed tests for rerun
- `regression_summary.txt` - Complete summary report

### KPI Analysis
Each test log contains detailed performance metrics report:
```
====================================================
        AXI4 PERFORMANCE METRICS REPORT
====================================================
ACCEPTANCE CRITERIA:
  Protocol Errors    : 0 (Required: 0)
  Deadlock Detected  : NO (Required: No)
  Livelock Detected  : NO (Required: No)
KEY PERFORMANCE INDICATORS:
  Write Throughput   : 0.12 GB/s
  Read Throughput    : 0.08 GB/s
  Total Throughput   : 0.20 GB/s
  Retry Rate         : 0.00%
  Reset Recovery Time: 0
  Error Isolation    : 100.00%
  Arbitration Fairness: 1.00
TEST RESULT: PASS - All acceptance criteria met
====================================================
```

### Rerunning Failed Tests
```bash
python3 axi4_regression_makefile.py --test-list regression_result_*/no_pass_list --verbose
```

## Test Execution Timing
- **NONE Mode**: ~2-5 minutes per test (simple topology)
- **BASE Mode**: ~5-10 minutes per test (4x4 matrix)  
- **ENHANCED Mode**: ~10-20 minutes per test (10x10 matrix with full KPI collection)

**Total Estimated Runtime**: 2-4 hours for complete 18-case regression

## Troubleshooting

### Common Issues
1. **Compilation Errors**: Check VCS installation and compile file paths
2. **Timeout Issues**: Increase `--timeout` for large designs
3. **Permission Errors**: Ensure write permissions in sim directory
4. **Memory Issues**: Reduce parallel workers with `-p 1` for sequential execution

### Debug Mode
```bash
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --verbose --log-wait-timeout 60
```

## Summary
This comprehensive regression validates AXI4 VIP across all 3 bus matrix topologies with complete KPI measurement coverage, ensuring full protocol compliance and performance characterization per `axi_stress_reset_test.md` requirements.