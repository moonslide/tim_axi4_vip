# AXI4 Regression Test System

This directory contains a comprehensive parallel regression test system for AXI4 verification with advanced features for parallel execution, test repetition, error tracking, and comprehensive reporting.

## Table of Contents

- [Features](#features)
- [Files](#files)
- [Quick Start](#quick-start)
- [Command Line Options](#command-line-options)
- [Test List Format](#test-list-format)
- [Test Repetition](#test-repetition)
- [Output and Reports](#output-and-reports)
- [Error Detection and Reporting](#error-detection-and-reporting)
- [FSDB Waveform Dumping](#fsdb-waveform-dumping)
- [Enhanced Random Seed Generation](#enhanced-random-seed-generation)
- [Smart Folder Management](#smart-folder-management)
- [VCS Artifact Cleanup](#vcs-artifact-cleanup)
- [LSF Features](#lsf-features)
- [Folder Structure](#folder-structure)
- [Timeout Handling](#timeout-handling)
- [Signal Handling](#signal-handling)
- [Troubleshooting](#troubleshooting)
- [Performance Tips](#performance-tips)
- [Examples](#examples)
- [Recent Improvements](#recent-improvements)

## Features

- ✅ **Parallel Execution**: Run up to 50 tests simultaneously (local) or unlimited (LSF)
- ✅ **Test Repetition**: Run tests multiple times with numbered logs (e.g., `testname run_cnt=10`)
- ✅ **Enhanced Random Seeds**: Multiple entropy sources for better test randomization
- ✅ **LSF Support**: Full Load Sharing Facility integration with job monitoring
- ✅ **Real-time Progress**: Live progress tracking with ETA and job status
- ✅ **Comprehensive Logging**: Detailed logs for each test with automatic organization into logs folder
- ✅ **Smart Folder Management**: Preserve last execution folder and all regression results
- ✅ **VCS Artifact Cleanup**: Automatic cleanup of compilation artifacts between tests
- ✅ **FSDB Waveform Dumping**: Optional waveform dumping control with `--fsdb-dump` flag
- ✅ **Enhanced Error Reporting**: Exact UVM_ERROR and UVM_FATAL count tracking with detailed error messages
- ✅ **Comprehensive Summary Reports**: All test records with detailed error information in regression_summary.txt
- ✅ **Error Analysis**: Automatic failure detection and reporting
- ✅ **Timeout Handling**: Automatic cleanup of stuck tests and LSF jobs
- ✅ **Graceful Shutdown**: Ctrl+C handling with cleanup (including LSF job termination)
- ✅ **Detailed Reports**: Summary statistics and failure analysis with timestamped results

## Files

- `axi4_regression.py` - Main regression runner with advanced features
- `run_regression.sh` - Shell wrapper script for legacy compatibility
- `test_regression.py` - Test runner with sample tests for verification
- `README_REGRESSION.md` - This comprehensive documentation
- `axi4_transfers_regression.list` - Default test list file

## Quick Start

### Getting Started in 30 Seconds

```bash
# 1. Basic run with all default tests
python3 axi4_regression.py

# 2. Run with debugging enabled
python3 axi4_regression.py --verbose --fsdb-dump

# 3. Run specific tests with repetition
echo "axi4_write_read_test run_cnt=3" > my_tests.list
python3 axi4_regression.py --test-list my_tests.list
```

### Local Execution (Default)
```bash
# Run all tests with default settings (auto parallel, 10min timeout)
python3 axi4_regression.py

# Run with custom settings
python3 axi4_regression.py --max-parallel 5 --timeout 900 --verbose

# Run specific test list with FSDB dumping
python3 axi4_regression.py --test-list custom_tests.list --fsdb-dump
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
  --fsdb-dump          Enable FSDB waveform dumping by adding +define+DUMP_FSDB to VCS command (default: disabled)

Examples:
  python3 axi4_regression.py                      # Auto parallel (# of tests), local mode
  python3 axi4_regression.py -p 5                 # Limit to 5 parallel workers
  python3 axi4_regression.py --timeout 900        # 15min timeout per test
  python3 axi4_regression.py --verbose            # Verbose execution output
  python3 axi4_regression.py --fsdb-dump          # Enable FSDB waveform dumping
  python3 axi4_regression.py --lsf                # Use LSF job submission
  python3 axi4_regression.py --lsf -p 10          # LSF mode with 10 parallel jobs
```

## Test List Format

The test list file supports multiple formats for flexible test execution with comprehensive test repetition capabilities.

### Basic Format
```
# Comments start with #
axi4_write_read_test
axi4_blocking_8b_write_read_test
axi4_tc_054_exclusive_read_fail_test

# Group sections are supported
axi4_non_blocking_write_test
```

## Test Repetition

### Format: `testname run_cnt=N`

Run tests multiple times with numbered log files using the explicit `run_cnt=N` syntax:

```
# Single run (default)
axi4_write_read_test

# Run test 5 times
axi4_wstrb_single_bit_test run_cnt=5

# Run test 10 times  
axi4_blocking_32b_write_read_test run_cnt=10

# Mixed format in same file
axi4_tc_054_exclusive_read_fail_test
axi4_wstrb_all_ones_test run_cnt=3
axi4_non_blocking_write_test
```

### Test Repetition Features
- ✅ **Explicit Syntax**: Clear `run_cnt=N` format for better readability
- ✅ **Numbered Logs**: Generates `testname_1.log`, `testname_2.log`, etc.
- ✅ **Unique Seeds**: Each repetition gets a different random seed
- ✅ **Progress Tracking**: Shows individual progress for each repetition
- ✅ **Statistics**: Counts each repetition separately in summary
- ✅ **Error Handling**: Invalid formats fall back to single test with warnings

### Test Repetition Examples
```bash
# Test list with repetitions
echo "axi4_wstrb_single_bit_test run_cnt=5" > repeat_tests.list
echo "axi4_blocking_32b_write_read_test run_cnt=3" >> repeat_tests.list

# Run the repeated tests
python3 axi4_regression.py --test-list repeat_tests.list

# Results will include:
# - axi4_wstrb_single_bit_test_1.log
# - axi4_wstrb_single_bit_test_2.log  
# - axi4_wstrb_single_bit_test_3.log
# - axi4_wstrb_single_bit_test_4.log
# - axi4_wstrb_single_bit_test_5.log
# - axi4_blocking_32b_write_read_test_1.log
# - axi4_blocking_32b_write_read_test_2.log
# - axi4_blocking_32b_write_read_test_3.log
```

### Error Handling and Validation

The test repetition system includes robust error handling:

```bash
# Valid formats
axi4_test run_cnt=5          # ✅ Runs 5 times
axi4_test run_cnt=1          # ✅ Runs 1 time
axi4_test                    # ✅ Runs 1 time (default)

# Invalid formats (fall back to single run with warnings)
axi4_test run_cnt=0          # ⚠️ Warning: run_cnt must be >= 1
axi4_test run_cnt=-1         # ⚠️ Warning: run_cnt must be >= 1  
axi4_test run_cnt=abc        # ⚠️ Warning: invalid literal for int()
```

Console output for invalid formats:
```
⚠️  Warning: Invalid run_cnt format in 'axi4_test run_cnt=0': run_cnt must be >= 1, got 0
    Expected format: 'testname run_cnt=N'
    Treating as single test: axi4_test
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
📁 Created logs folder: logs
🔧 Setting up 10 parallel execution folders...

🧹 [Folder 00] Cleaned simv*
🧹 [Folder 00] Cleaned csrc
🧹 [Folder 01] Cleaned simv*
🧹 [Folder 01] Cleaned csrc
✅ [  1/ 85] axi4_write_read_test                              (  45.2s) Progress:   1.2% ETA: 0:05:30
✅ [  2/ 85] axi4_wstrb_single_bit_test_1                     (  23.1s) Progress:   2.4% ETA: 0:05:15
✅ [  3/ 85] axi4_wstrb_single_bit_test_2                     (  24.3s) Progress:   3.5% ETA: 0:05:10
❌ [  4/ 85] axi4_blocking_8b_write_read_test                  (  28.7s) Progress:   4.7% ETA: 0:05:05
    └─ Error: UVM_ERROR: Comparison failed at address 0x1000
📋 Organizing logs into logs folder...
✅ Verified 85/85 logs are properly organized
🧹 Cleaning up execution folders (keeping last folder for debugging)...
🧹 Removed run_folder_00
🧹 Removed run_folder_01
📁 Keeping last execution folder: run_folder_02 for debugging

📊 Regression results saved in: regression_result_20250711_143025
   View summary: cat regression_result_20250711_143025/regression_summary.txt
   View detailed results: cat regression_result_20250711_143025/regression_results_20250711_143025.txt
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
   Total Tests:     98
   Passed:          95 (96.9%)
   Failed:          1 (1.0%)
   Total Time:      0:08:17
   Average per Test: 5.1s

❌ FAILED TESTS (1):
   FAIL     axi4_non_blocking_write_read_response_out_of_order_test (  59.4s)
            └─ UVM_FATAL Count: 0
            └─ Log: regression_result_20250710_190727/logs/no_pass_logs/axi4_non_blocking_write_read_response_out_of_order_test.log
```

### Detailed Results File
A timestamped results folder is automatically generated with organized logs:
```
regression_result_20250710_190727/
├── regression_results_20250710_190727.txt    # Main results file
├── regression_summary.txt                    # Copy of results file
├── no_pass_list                              # List of failed tests (if any)
└── logs/                                     # All test logs organized by status
    ├── pass_logs/                            # Passing test logs
    │   ├── axi4_write_read_test.log
    │   ├── axi4_tc_049_awlen_out_of_spec_test.log
    │   ├── axi4_tc_051_exclusive_write_success_test.log
    │   └── ...
    └── no_pass_logs/                         # Failing test logs
        └── axi4_non_blocking_write_read_response_out_of_order_test.log
```

## Log Organization

The regression system automatically organizes all test logs by status into dedicated subfolders within each results directory:

### Features
- ✅ **Status-Based Organization**: Test logs separated by pass/fail status for easy analysis
- ✅ **Clear Separation**: Passing tests in `pass_logs/`, failing tests in `no_pass_logs/`
- ✅ **Safe Copy**: Logs are copied immediately after test completion to prevent loss
- ✅ **No Missing Files**: Robust log collection prevents missing log file errors
- ✅ **Easy Analysis**: Failed tests easily identifiable in dedicated folder

### Folder Structure
```
📁 regression_result_YYYYMMDD_HHMMSS/
├── 📄 regression_results_YYYYMMDD_HHMMSS.txt  # Detailed results report (original format)
├── 📄 regression_summary.txt                  # Comprehensive summary with ALL test records and UVM error counts
├── 📄 no_pass_list                           # List of failed tests (if any)
└── 📁 logs/                                  # All test logs organized by status
    ├── 📁 pass_logs/                         # Passing test logs
    │   ├── 📄 test1.log
    │   ├── 📄 test2.log
    │   └── 📄 ...
    └── 📁 no_pass_logs/                      # Failing test logs
        ├── 📄 failed_test1.log
        └── 📄 failed_test2.log
```

### Benefits
- **Status-Based Analysis**: Immediately identify failed tests in dedicated `no_pass_logs/` folder
- **Prevents Loss**: Immediate log copying prevents loss from folder cleanup or test overwrites  
- **Better Debugging**: Failed test logs isolated for focused analysis
- **Consistent Structure**: Every regression run follows the same organization pattern
- **Easy Filtering**: Pass and fail logs clearly separated for different analysis workflows

### Console Output
When logs are organized, you'll see:
```
📋 Verifying log organization...
✅ Verified 98/98 logs are properly organized
📋 Test logs organized in:
   ✅ Pass logs: regression_result_20250710_190727/logs/pass_logs
   ❌ Fail logs: regression_result_20250710_190727/logs/no_pass_logs
```

## Enhanced Random Seed Generation

The regression system uses multiple entropy sources to generate truly random seeds for each test run, ensuring better test coverage and reproducibility.

### Seed Generation Features
- ✅ **Multiple Entropy Sources**: Combines random number, microsecond timestamp, and test name hash
- ✅ **Unique Per Test**: Each test run gets its own randomized seed
- ✅ **Test Repetition Support**: Each repeated test gets a different seed
- ✅ **32-bit Positive Seeds**: Ensures compatibility with VCS requirements
- ✅ **Deterministic Base**: Test name hash provides some determinism for debugging

### Seed Algorithm
```python
# Generate base random seed
random_seed = random.randint(1, 2**31-1)

# Mix with microsecond timestamp for temporal uniqueness  
random_seed ^= int(time.time() * 1000000) & 0x7FFFFFFF

# Mix with test name hash for test-specific variance
random_seed ^= hash(test_name) & 0x7FFFFFFF

# Ensure positive 32-bit value
random_seed &= 0x7FFFFFFF
```

### VCS Command Integration
The generated seed replaces the default `+ntb_random_seed_automatic`:
```bash
# OLD (automatic seed)
vcs +ntb_random_seed_automatic [other options]

# NEW (enhanced random seed)
vcs +ntb_random_seed=1847293756 [other options]
```

### Console Output
You'll see the generated seeds in the VCS command lines:
```
Command: vcs -full64 -lca -kdb -sverilog +v2k -debug_access+all \
+ntb_random_seed=1847293756 -override_timescale=1ps/1ps \
+UVM_TESTNAME=axi4_wstrb_single_bit_test_1 [other options]
```

## FSDB Waveform Dumping

The regression system provides optional FSDB waveform dumping control to help with debugging while allowing users to disable it for faster execution when waveforms are not needed.

### FSDB Dump Features
- ✅ **Optional Control**: Enable/disable FSDB dumping with `--fsdb-dump` flag
- ✅ **Default Disabled**: FSDB dumping is disabled by default for faster execution
- ✅ **VCS Integration**: Automatically adds `+define+DUMP_FSDB` to VCS command when enabled
- ✅ **Both Execution Modes**: Works in both local and LSF execution modes

### Usage

#### Enable FSDB Dumping
```bash
# Local mode with FSDB dumping
python3 axi4_regression.py --fsdb-dump

# LSF mode with FSDB dumping
python3 axi4_regression.py --lsf --fsdb-dump

# Combined with other options
python3 axi4_regression.py --fsdb-dump --verbose --max-parallel 5
```

#### Default Behavior (No FSDB Dumping)
```bash
# Default - no FSDB dumping for faster execution
python3 axi4_regression.py

# Explicitly disable (same as default)
python3 axi4_regression.py
```

### VCS Command Integration
The FSDB dump option affects the VCS command line:

```bash
# WITHOUT --fsdb-dump (default)
vcs -full64 -lca -kdb -sverilog +v2k -debug_access+all \
+ntb_random_seed=1847293756 -override_timescale=1ps/1ps \
+nospecify +no_timing_check +define+UVM_VERDI_COMPWAVE \
-f axi4_compile.f [other options]

# WITH --fsdb-dump
vcs -full64 -lca -kdb -sverilog +v2k -debug_access+all \
+ntb_random_seed=1847293756 -override_timescale=1ps/1ps \
+nospecify +no_timing_check +define+DUMP_FSDB \
+define+UVM_VERDI_COMPWAVE -f axi4_compile.f [other options]
```

### Benefits
- **Faster Execution**: Default behavior skips FSDB dumping for quicker regression runs
- **Debug Support**: Enable FSDB dumping when detailed waveform analysis is needed
- **Flexible Control**: Easy to switch between fast execution and debug modes
- **Automatic Integration**: No need to manually modify VCS commands or compile files

### Console Output
When `--fsdb-dump` is used, you'll see the `+define+DUMP_FSDB` option in the VCS command lines displayed during verbose output.

## Smart Folder Management

The regression system intelligently manages execution folders and result preservation to aid debugging while maintaining clean environments.

### Folder Preservation Features
- ✅ **Always Preserve Results**: `regression_result_YYYYMMDD_HHMMSS/` folders are never deleted
- ✅ **Keep Last Execution Folder**: Highest numbered `run_folder_XX` is preserved for debugging
- ✅ **Clean Intermediate Folders**: Remove unused execution folders to save space
- ✅ **Clear Messaging**: Shows which folders are kept and which are removed
- ✅ **Result Location Summary**: Final message shows where to find all results

### Folder Structure After Execution
```
sim/synopsys_sim/
├── regression_result_20250711_143025/    # PRESERVED - All results and logs
│   ├── regression_results_20250711_143025.txt
│   ├── regression_summary.txt
│   └── logs/
│       ├── pass_logs/
│       └── no_pass_logs/
├── run_folder_02/                        # PRESERVED - Last execution folder
│   ├── simv
│   ├── csrc/
│   ├── test_name.log
│   └── run_test.sh
├── axi4_regression.py
└── [run_folder_00, run_folder_01 REMOVED]
```

### Console Output During Cleanup
```
🧹 Cleaning up execution folders (keeping last folder for debugging)...
🧹 Removed run_folder_00
🧹 Removed run_folder_01  
📁 Keeping last execution folder: run_folder_02 for debugging

📊 Regression results saved in: regression_result_20250711_143025
   View summary: cat regression_result_20250711_143025/regression_summary.txt
   View detailed results: cat regression_result_20250711_143025/regression_results_20250711_143025.txt
```

### Benefits
- **Easy Debugging**: Last execution environment preserved with all artifacts
- **Space Efficient**: Only keep what's needed for debugging
- **Result Safety**: Regression results are never accidentally deleted
- **Clear Navigation**: Always know where to find results and debugging artifacts

## VCS Artifact Cleanup

The regression system automatically cleans up VCS compilation artifacts between test runs to prevent conflicts and ensure clean builds:

### Artifacts Cleaned
- **simv*** - VCS executable and related files  
- **csrc** - VCS compilation directory
- **vc_hdrs.h** - VCS header file
- **ucli.key** - VCS license key file
- **\*.fsdb** - FSDB waveform files
- **\*.daidir** - VCS debug directories
- **work.lib++** - Work library files
- **\*.log** - Previous log files

### When Cleanup Occurs
- ✅ **Before each test**: Ensures clean compilation environment
- ✅ **Between test runs**: When folders are reused for subsequent tests
- ✅ **Both local and LSF modes**: Consistent cleanup across execution modes

### Console Output
When VCS cleanup is active (verbose mode), you'll see:
```
🧹 [Folder 00] Cleaned simv*
🧹 [Folder 00] Cleaned csrc
🧹 [Folder 00] Cleaned vc_hdrs.h
🧹 [Folder 00] Cleaned ucli.key
🧹 [Folder 00] Cleaned *.fsdb
🧹 [Folder 00] Cleaned *.daidir
🧹 [Folder 00] Cleaned work.lib++
🔄 [Folder 00] Starting test_name
```

### Benefits
- **Prevents Conflicts**: Avoids issues from previous compilation artifacts
- **Clean Builds**: Each test starts with a fresh compilation environment
- **Consistent Results**: Eliminates test-to-test contamination
- **Automatic**: No manual intervention required

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

### During Regression Run
```
sim/synopsys_sim/
├── run_folder_00/              # Parallel execution folder 0
│   ├── test1.log               # Current test log
│   ├── simv                    # VCS executable
│   ├── csrc/                   # VCS compilation artifacts
│   ├── run_test.sh             # Generated test script
│   └── axi4_compile.f          # Adjusted compile file
├── run_folder_01/              # Parallel execution folder 1
├── ...
├── run_folder_09/              # Parallel execution folder 9 (max parallel)
├── regression_result_YYYYMMDD_HHMMSS/  # Live results folder
│   ├── logs/                   # Organized test logs
│   │   ├── pass_logs/          # Passing test logs (copied here)
│   │   └── no_pass_logs/       # Failing test logs (copied here)
│   └── [results files created at end]
├── axi4_regression.py          # Main runner
├── run_regression.sh           # Shell wrapper  
└── axi4_transfers_regression.list  # Default test list
```

### After Regression Completion
```
sim/synopsys_sim/
├── run_folder_02/              # PRESERVED - Last execution folder
│   ├── last_test.log           # Final test log
│   ├── simv                    # VCS executable (for debugging)
│   ├── csrc/                   # VCS artifacts (for debugging)
│   └── run_test.sh             # Final test script
├── regression_result_YYYYMMDD_HHMMSS/  # PRESERVED - Complete results
│   ├── regression_results_YYYYMMDD_HHMMSS.txt  # Detailed results
│   ├── regression_summary.txt          # Summary copy
│   ├── no_pass_list                    # Failed tests (if any)
│   └── logs/                           # All organized logs
│       ├── pass_logs/                  # All passing test logs
│       │   ├── axi4_write_read_test.log
│       │   ├── axi4_wstrb_single_bit_test_1.log
│       │   ├── axi4_wstrb_single_bit_test_2.log
│       │   └── ...
│       └── no_pass_logs/               # All failing test logs
│           └── failed_test.log
├── axi4_regression.py          # Main runner
├── run_regression.sh           # Shell wrapper
└── [run_folder_00, run_folder_01 REMOVED for space]
```

## Error Detection and Reporting

### Enhanced Error Detection

The system automatically detects failures based on:

- `UVM_FATAL` messages with exact count tracking
- `UVM_ERROR` messages with exact count tracking (excluding time 0)
- `Error-[` compilation errors
- Simulation aborts or crashes
- Timeouts
- Missing expected success indicators

### UVM Error Count Tracking

The regression system now tracks and reports exact UVM error counts:
- **UVM_ERROR Count**: Exact number of UVM_ERROR messages in the test
- **UVM_FATAL Count**: Exact number of UVM_FATAL messages in the test
- **Error Messages**: Includes UVM counts in error descriptions

### Output Files

#### regression_results_YYYYMMDD_HHMMSS.txt
Original format results file with:
- Summary statistics
- Grouped results by status (TIMEOUT, FAIL, PASS)
- Basic error messages

#### regression_summary.txt
Comprehensive summary report with:
- **All Test Records**: Every test run is listed with full details
- **Detailed Error Info**: Complete error messages with UVM_ERROR and UVM_FATAL counts
- **Test Numbering**: Sequential numbering for easy reference
- **Status Grouping**: Tests sorted by status (TIMEOUT → FAIL/ERROR → PASS)
- **Failed Test Summary**: Dedicated section at the end for all failed tests

Example regression_summary.txt content:
```
AXI4 Regression Summary Report
Generated: 2025-07-11 10:30:45
================================================================================

Overall Statistics:
  Total Tests:     98
  Passed:          95 (96.9%)
  Failed:          3 (3.1%)
  Total Time:      0:08:17
  Average per Test: 5.1s

Detailed Test Results:
================================================================================

[  1] Test: axi4_tc_043_id_multiple_writes_different_awid_test
      Status:     FAIL
      Duration:   23.4s
      Folder:     run_folder_03
      Log:        regression_result_20250711_103045/logs/no_pass_logs/axi4_tc_043_id_multiple_writes_different_awid_test.log
      Error:      UVM_ERROR Count: 13, UVM_FATAL Count: 0
      UVM Counts: UVM_ERROR: 13, UVM_FATAL: 0

[  2] Test: axi4_write_read_test
      Status:     PASS
      Duration:   18.2s
      Folder:     run_folder_00
      Log:        regression_result_20250711_103045/logs/pass_logs/axi4_write_read_test.log

...

Failed Test Summary:
--------------------------------------------------------------------------------
FAIL     axi4_tc_043_id_multiple_writes_different_awid_test            ( 23.4s)
         └─ UVM_ERROR Count: 13, UVM_FATAL Count: 0
```

### Key Improvements in Error Reporting

1. **Exact UVM Count Tracking**: The system now parses UVM report summaries to extract exact error counts
2. **Comprehensive Summary**: `regression_summary.txt` contains ALL test records, not just failed ones
3. **Sequential Numbering**: Tests are numbered [1], [2], [3]... for easy reference
4. **Detailed Error Context**: Each failed test shows complete error information including UVM counts
5. **Status Grouping**: Tests organized by status (TIMEOUT → FAIL/ERROR → PASS) for prioritized review

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

# Or check the organized log file
cat regression_result_YYYYMMDD_HHMMSS/logs/failed_test_name.log
```

### Debug with FSDB Waveforms
```bash
# Run regression with FSDB waveform dumping for debugging
python3 axi4_regression.py --fsdb-dump --verbose

# Run specific test list with FSDB dumping
python3 axi4_regression.py --fsdb-dump --test-list my_debug_tests.list

# Run single test with FSDB dumping using LSF
python3 axi4_regression.py --lsf --fsdb-dump --test-list single_test.list
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

### Test Repetition Examples
```bash
# Create test list with repetitions for stress testing
echo "axi4_wstrb_single_bit_test run_cnt=5" > stress_tests.list
echo "axi4_blocking_32b_write_read_test run_cnt=3" >> stress_tests.list  
echo "axi4_tc_054_exclusive_read_fail_test run_cnt=2" >> stress_tests.list

# Run repeated tests (local mode)
python3 axi4_regression.py --test-list stress_tests.list --max-parallel 4

# Run repeated tests (LSF mode) 
python3 axi4_regression.py --lsf --test-list stress_tests.list --max-parallel 10

# Results folder will contain:
# pass_logs/axi4_wstrb_single_bit_test_1.log
# pass_logs/axi4_wstrb_single_bit_test_2.log
# pass_logs/axi4_wstrb_single_bit_test_3.log
# pass_logs/axi4_wstrb_single_bit_test_4.log
# pass_logs/axi4_wstrb_single_bit_test_5.log
# pass_logs/axi4_blocking_32b_write_read_test_1.log
# pass_logs/axi4_blocking_32b_write_read_test_2.log
# pass_logs/axi4_blocking_32b_write_read_test_3.log
# pass_logs/axi4_tc_054_exclusive_read_fail_test_1.log
# pass_logs/axi4_tc_054_exclusive_read_fail_test_2.log
```

### Mixed Format Examples
```bash
# Create mixed test list (single runs + repetitions)
cat > mixed_tests.list << EOF
# Single runs
axi4_write_read_test
axi4_non_blocking_write_test

# Stress testing with repetitions
axi4_wstrb_all_ones_test run_cnt=3
axi4_wstrb_all_zero_test run_cnt=3

# Critical tests with extra runs
axi4_tc_053_exclusive_read_success_test run_cnt=5
axi4_tc_054_exclusive_read_fail_test run_cnt=5
EOF

# Run mixed test list
python3 axi4_regression.py --test-list mixed_tests.list --max-parallel 6

# This creates 18 total test runs:
# - 2 single runs 
# - 6 repetition runs (3+3)
# - 10 critical test runs (5+5)
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

## Recent Improvements

### Version 2025.01 Major Features

#### Test Repetition System
- ✅ **New Syntax**: `testname run_cnt=N` format for explicit test repetition
- ✅ **Numbered Logs**: Automatic generation of `testname_1.log`, `testname_2.log`, etc.
- ✅ **Unique Seeds**: Each repetition gets different random seed for better coverage
- ✅ **Mixed Format**: Support both single and repeated tests in same test list
- ✅ **Error Handling**: Invalid formats fall back to single test with clear warnings

#### Enhanced Error Reporting
- ✅ **UVM Count Tracking**: Exact parsing of UVM_ERROR and UVM_FATAL counts from test logs
- ✅ **Comprehensive Summary**: New `regression_summary.txt` with ALL test records
- ✅ **Sequential Numbering**: Tests numbered [1], [2], [3]... for easy reference
- ✅ **Status Grouping**: Tests organized by priority (TIMEOUT → FAIL/ERROR → PASS)
- ✅ **Detailed Error Context**: Complete error information with UVM counts for each failed test

#### Advanced Features
- ✅ **FSDB Waveform Control**: Optional `--fsdb-dump` flag for debugging (default: disabled)
- ✅ **Enhanced Random Seeds**: Multiple entropy sources (time, test name hash, random)
- ✅ **Smart Folder Management**: Preserve last execution folder and all regression results
- ✅ **Relative Path Display**: All paths shown as relative for better portability
- ✅ **Result Preservation**: Regression result folders always preserved with clear location messaging

### Core Features (Established)
- ✅ **LSF Integration**: Full Load Sharing Facility support with job monitoring
- ✅ **Parallel Execution**: Up to 50 local parallel tests or unlimited with LSF
- ✅ **Comprehensive Logging**: Automatic log organization by pass/fail status
- ✅ **VCS Artifact Cleanup**: Automatic cleanup between tests for clean builds
- ✅ **Real-time Progress**: Live ETA tracking and status updates
- ✅ **Graceful Shutdown**: Proper cleanup on interruption with LSF job termination
- ✅ **Timeout Handling**: Automatic cleanup of stuck tests and LSF jobs

## Version History

### v2025.01 (Current) - Major Feature Release
- **Test Repetition**: New `run_cnt=N` syntax for explicit test repetition
- **Enhanced Error Reporting**: UVM_ERROR/UVM_FATAL count tracking
- **Comprehensive Summary**: All test records in regression_summary.txt
- **FSDB Waveform Control**: Optional `--fsdb-dump` flag
- **Enhanced Random Seeds**: Multiple entropy sources
- **Smart Folder Management**: Preserve debugging artifacts

### v2024.12 - Core Foundation
- **LSF Integration**: Full cluster support with job monitoring
- **Parallel Execution**: Up to 50 local tests or unlimited LSF
- **Real-time Progress**: Live ETA and status tracking
- **VCS Artifact Cleanup**: Automatic cleanup between tests
- **Comprehensive Logging**: Automatic log organization

## Support and Troubleshooting

### Getting Help
- Check this README for comprehensive documentation
- Run with `--verbose` flag for detailed output
- Examine the preserved `run_folder_XX` for debugging artifacts
- Review detailed results in `regression_result_YYYYMMDD_HHMMSS/`

### Report Issues
When reporting issues, please include:
- Command line used
- Console output (especially error messages)
- Relevant log files from `regression_result_*/logs/no_pass_logs/`
- Contents of preserved `run_folder_XX` if applicable

### Best Practices
1. **Start Small**: Test with a few tests before running full regression
2. **Use Repetition**: Use `run_cnt=N` for stress testing critical tests
3. **Enable FSDB**: Use `--fsdb-dump` only when needed for debugging
4. **Monitor Resources**: Adjust `--max-parallel` based on system capacity
5. **Review Logs**: Always check `regression_summary.txt` for complete results