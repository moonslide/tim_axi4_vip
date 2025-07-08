# AXI4 Regression Test System

This directory contains a comprehensive parallel regression test system for AXI4 verification.

## Features

- ✅ **Parallel Execution**: Run up to 50 tests simultaneously (local) or unlimited (LSF)
- ✅ **LSF Support**: Full Load Sharing Facility integration with job monitoring
- ✅ **Real-time Progress**: Live progress tracking with ETA and job status
- ✅ **Comprehensive Logging**: Detailed logs for each test with automatic cleanup
- ✅ **Error Analysis**: Automatic failure detection and reporting
- ✅ **Timeout Handling**: Automatic cleanup of stuck tests and LSF jobs
- ✅ **Graceful Shutdown**: Ctrl+C handling with cleanup (including LSF job termination)
- ✅ **Detailed Reports**: Summary statistics and failure analysis with timestamped results

## Files

- `axi4_regression.py` - Main regression runner (Python)
- `run_regression.sh` - Shell wrapper script
- `test_regression.py` - Test runner with sample tests

## Quick Start

### Local Execution (Default)
```bash
# Run all tests with default settings (auto parallel, 10min timeout)
python3 axi4_regression.py

# Run with custom settings
python3 axi4_regression.py --max-parallel 5 --timeout 900 --verbose

# Run specific test list
python3 axi4_regression.py --test-list custom_tests.list
```

### LSF Execution (Cluster Mode)
```bash
# Run all tests using LSF job submission
python3 axi4_regression.py --lsf

# Run with custom LSF settings
python3 axi4_regression.py --lsf --max-parallel 20 --timeout 1200 --verbose

# Run specific test list with LSF
python3 axi4_regression.py --lsf --test-list custom_tests.list
```

### Legacy Shell Wrapper
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
  --max-parallel N     Maximum parallel executions (1-50, default: auto)
  --timeout N          Test timeout in seconds (min: 60, default: 600)
  --verbose            Enable verbose output
  --lsf                Use LSF (Load Sharing Facility) for job submission
  --test-list FILE     Path to test list file (default: axi4_transfers_regression.list)

Examples:
  python3 axi4_regression.py                      # Auto parallel (# of tests), local mode
  python3 axi4_regression.py -p 5                 # Limit to 5 parallel workers
  python3 axi4_regression.py --timeout 900        # 15min timeout per test
  python3 axi4_regression.py --verbose            # Verbose execution output
  python3 axi4_regression.py --lsf                # Use LSF job submission
  python3 axi4_regression.py --lsf -p 10          # LSF mode with 10 parallel jobs
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

#### Local Mode
```
🚀 Starting AXI4 Regression Runner
📋 Loaded 85 tests from axi4_transfers_regression.list
⚙️  Configuration: Local mode, 10 parallel workers, 600s timeout
🧹 Cleaning up existing run_folder_xx directories...
✅ Cleaned up 5 existing run folders
📁 Created results folder: regression_result_20250708_143025
🔧 Setting up 10 parallel execution folders...

✅ [  1/ 85] axi4_write_read_test                              (  45.2s) Progress:   1.2% ETA: 0:05:30
❌ [  2/ 85] axi4_blocking_8b_write_read_test                  (  23.1s) Progress:   2.4% ETA: 0:05:15
    └─ Error: UVM_ERROR: Comparison failed at address 0x1000
```

#### LSF Mode
```
🚀 Starting AXI4 Regression Runner
📋 Loaded 85 tests from axi4_transfers_regression.list
⚙️  Configuration: LSF mode, 20 parallel workers, 600s timeout
✅ LSF commands available (bsub, bjobs, bkill)
🧹 Cleaning up existing run_folder_xx directories...
📁 Created results folder: regression_result_20250708_143025
🔧 Setting up 20 parallel execution folders...
📤 [LSF] Submitted 85 jobs, monitoring for completion...
📊 [LSF Status] Done: 0/85 (0.0%) | Remaining: 85 | Pending: 20 | Running: 0 | ETA: Unknown

✅ [  1/ 85] axi4_write_read_test                              (  42.3s) Progress:   1.2% ETA: 0:04:20 [Remaining:84 P:15 R:5]
❌ [  2/ 85] axi4_blocking_8b_write_read_test                  (  18.7s) Progress:   2.4% ETA: 0:04:05 [Remaining:83 P:12 R:8]
    └─ Error: UVM_ERROR: Comparison failed at address 0x1000

📊 [LSF Status] Done: 12/85 (14.1%) | Remaining: 73 | Pending: 8 | Running: 12 | ETA: 0:03:45
           Results: 10 PASS, 2 FAIL
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
A timestamped results file is automatically generated in a dedicated folder:
```
regression_result_20250708_143025/
├── regression_results_20250708_143025.txt    # Main results file
├── no_pass_list                              # List of failed tests
├── axi4_write_read_test.log                 # Individual test logs
├── axi4_blocking_8b_write_read_test.log
└── ...
```

## LSF Features

### LSF Requirements
- LSF commands must be available: `bsub`, `bjobs`, `bkill`
- Access to LSF queue system (typically `normal` queue)
- Proper LSF environment setup

### LSF Job Management
```bash
# Check LSF availability
which bsub bjobs bkill

# Run with LSF
python3 axi4_regression.py --lsf
```

### LSF Job Monitoring
The system provides comprehensive real-time monitoring of LSF jobs:

#### Individual Test Progress
- **Remaining:N** - Number of tests still to complete
- **P:N** - Number of pending (queued) jobs
- **R:N** - Number of running jobs

#### Periodic Status Updates (every 10 seconds)
- **Done: X/Y (Z%)** - Completed tests with percentage
- **Remaining: N** - Tests still to complete
- **Pending: N** - Jobs waiting in LSF queue
- **Running: N** - Jobs currently executing
- **ETA: H:MM:SS** - Estimated time to completion
- **Results: X PASS, Y FAIL** - Pass/fail breakdown

#### Additional Features
- Automatic timeout detection and job termination
- Job status tracking: PEND → RUN → DONE/EXIT
- Real-time ETA calculations based on completion history

### LSF Resource Configuration
Default LSF job settings (configurable in code):
```bash
#BSUB -q normal           # Queue name
#BSUB -n 1               # Number of cores
#BSUB -R "rusage[mem=4000]"  # Memory requirement (4GB)
```

### LSF Error Handling
- Automatic cleanup of LSF jobs on Ctrl+C
- Timeout handling with `bkill` for stuck jobs
- Graceful degradation when LSF unavailable
- Clear error messages for LSF issues

### LSF vs Local Mode Comparison
| Feature | Local Mode | LSF Mode |
|---------|------------|----------|
| Parallelism | Limited by local CPU | Limited by cluster resources |
| Resource Management | Manual | Automatic via LSF |
| Queue Priority | N/A | LSF queue priority |
| Fault Tolerance | Local only | Distributed across cluster |
| Monitoring | Process-based | LSF job-based |
| Cleanup | Process termination | LSF job termination |

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

# Run custom list (local mode)
python3 axi4_regression.py --test-list my_tests.list --max-parallel 2

# Run custom list (LSF mode)
python3 axi4_regression.py --lsf --test-list my_tests.list --max-parallel 5
```

### LSF Examples
```bash
# Quick LSF smoke test
python3 axi4_regression.py --lsf --test-list test_mixed.list

# Full LSF regression with custom settings
python3 axi4_regression.py --lsf --max-parallel 30 --timeout 1800 --verbose

# LSF with specific queue (modify script for other queues)
# Edit line 234 in axi4_regression.py: f.write('#BSUB -q your_queue_name\n')
```