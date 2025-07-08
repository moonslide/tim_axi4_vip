# AXI4 Regression Test System

This directory contains a comprehensive parallel regression test system for AXI4 verification.

## Features

- ✅ **Parallel Execution**: Run up to 10 tests simultaneously
- ✅ **Real-time Progress**: Live progress tracking with ETA
- ✅ **Comprehensive Logging**: Detailed logs for each test
- ✅ **Error Analysis**: Automatic failure detection and reporting
- ✅ **Timeout Handling**: Automatic cleanup of stuck tests
- ✅ **Graceful Shutdown**: Ctrl+C handling with cleanup
- ✅ **Detailed Reports**: Summary statistics and failure analysis

## Files

- `axi4_regression.py` - Main regression runner (Python)
- `run_regression.sh` - Shell wrapper script
- `test_regression.py` - Test runner with sample tests

## Quick Start

### Run Full Regression
```bash
# Run all tests with default settings (10 parallel, 10min timeout)
./run_regression.sh

# Run with custom settings
./run_regression.sh --parallel 5 --timeout 900 --verbose
```

### Run Sample Tests (Verification)
```bash
# Test the system with 3 sample tests
python3 test_regression.py
```

### Run Specific Test List
```bash
python3 axi4_regression.py --test-list custom_tests.list
```

## Command Line Options

### run_regression.sh
```bash
Options:
  -p, --parallel N     Number of parallel tests (default: 10)
  -t, --timeout N      Timeout per test in seconds (default: 600)
  -v, --verbose        Enable verbose output
  -l, --test-list FILE Test list file
  -h, --help           Show help
```

### axi4_regression.py
```bash
Options:
  --max-parallel N     Maximum parallel executions (1-20)
  --timeout N          Test timeout in seconds (min: 60)
  --verbose            Enable verbose output
  --test-list FILE     Path to test list file
```

## Test List Format

The test list file should contain one test name per line:

```
# Comments start with #
axi4_write_read_test
axi4_blocking_8b_write_read_test
axi4_tc_054_exclusive_read_fail_test

# Group sections are supported
axi4_non_blocking_write_test
```

## Output and Reports

### Console Output
```
🚀 Starting AXI4 Regression Runner
⚙️  Configuration: 10 parallel, 600s timeout
📋 Loaded 85 tests from ../../testlists/axi4_transfers_regression.list
🔧 Setting up 10 parallel execution folders...

✅ [  1/ 85] axi4_write_read_test                              (  45.2s) Progress:   1.2% ETA: 0:05:30
❌ [  2/ 85] axi4_blocking_8b_write_read_test                  (  23.1s) Progress:   2.4% ETA: 0:05:15
    └─ Error: UVM_ERROR: Comparison failed at address 0x1000
```

### Summary Report
```
🏁 REGRESSION SUMMARY
================================================================================
📊 Statistics:
   Total Tests:     85
   Passed:          82 (96.5%)
   Failed:          3 (3.5%)
   Total Time:      0:12:45
   Average per Test: 9.0s

❌ FAILED TESTS (3):
   FAIL     axi4_blocking_8b_write_read_test                  ( 23.1s)
            └─ UVM_ERROR: Comparison failed at address 0x1000
            └─ Log: run_folder_02/axi4_blocking_8b_write_read_test.log
```

### Detailed Results File
A timestamped results file is automatically generated:
```
regression_results_20250707_235959.txt
```

## Folder Structure During Execution

```
sim/synopsys_sim/
├── run_folder_00/          # Parallel execution folder 0
│   ├── test1.log
│   ├── simv
│   └── ...
├── run_folder_01/          # Parallel execution folder 1
├── ...
├── run_folder_09/          # Parallel execution folder 9
├── axi4_regression.py      # Main runner
├── run_regression.sh       # Shell wrapper
└── regression_results_*.txt # Results files
```

## Error Detection

The system automatically detects failures based on:

- `UVM_FATAL` messages
- `UVM_ERROR` messages (excluding time 0)
- `Error-[` compilation errors
- Simulation aborts or crashes
- Timeouts
- Missing expected success indicators

## Timeout Handling

- Each test has a configurable timeout (default: 10 minutes)
- Stuck tests are automatically killed
- Process groups are used to ensure clean termination
- Timeout tests are marked as `TIMEOUT` status

## Signal Handling

- `Ctrl+C` (SIGINT) triggers graceful shutdown
- All running tests are terminated
- Temporary folders are cleaned up
- Partial results are saved

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   chmod +x axi4_regression.py run_regression.sh
   ```

2. **Python Not Found**
   ```bash
   # Ensure Python 3.6+ is installed
   python3 --version
   ```

3. **VCS Not Found**
   ```bash
   # Ensure VCS is in PATH
   which vcs
   ```

4. **Test List Not Found**
   ```bash
   # Check test list path
   ls -la ../../testlists/axi4_transfers_regression.list
   ```

### Debug Mode

Run with verbose output for debugging:
```bash
./run_regression.sh --verbose
```

## Performance Tips

1. **Parallel Count**: Match to your CPU cores (typically 8-16)
2. **Timeout**: Adjust based on longest expected test
3. **Memory**: Monitor system memory usage with many parallel tests
4. **Storage**: Ensure sufficient disk space for logs

## Examples

### Quick Smoke Test
```bash
# Run just a few tests quickly
python3 test_regression.py
```

### Full Nightly Regression
```bash
# Run all tests with longer timeout
./run_regression.sh --parallel 8 --timeout 1200
```

### Debug Failed Test
```bash
# Run single test in current directory
vcs [options] +UVM_TESTNAME=failed_test_name
```

### Custom Test Subset
```bash
# Create custom test list
echo "axi4_write_read_test" > my_tests.list
echo "axi4_tc_054_exclusive_read_fail_test" >> my_tests.list

# Run custom list
python3 axi4_regression.py --test-list my_tests.list --parallel 2
```