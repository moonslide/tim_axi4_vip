# AXI4 Regression Test System

This directory contains a comprehensive parallel regression test system for AXI4 verification with advanced features for parallel execution, test repetition, error tracking, and comprehensive reporting.

## Table of Contents

- [Features](#features)
- [Files](#files)
- [Quick Start](#quick-start)
- [Command Line Options](#command-line-options)
- [Test List Format](#test-list-format)
- [Test Repetition](#test-repetition)
- [Custom Seed and Command Support](#custom-seed-and-command-support)
- [Coverage Collection](#coverage-collection)
- [Output and Reports](#output-and-reports)
- [Error Detection and Reporting](#error-detection-and-reporting)
- [FSDB Waveform Dumping](#fsdb-waveform-dumping)
- [Enhanced Random Seed Generation](#enhanced-random-seed-generation)
- [Smart Folder Management](#smart-folder-management)
- [VCS Artifact Cleanup](#vcs-artifact-cleanup)
- [LSF Features](#lsf-features)
- [Test Execution Lists](#test-execution-lists)
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
- ✅ **Custom Seed Support**: Load custom seeds from test list (e.g., `testname seed=123`)
- ✅ **Custom VCS Commands**: Add custom VCS commands from test list (e.g., `command_add=+define+DEBUG`)
- ✅ **Coverage Collection**: Comprehensive function and code coverage with automatic merging
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
- ✅ **Test Execution Lists**: Automatic generation of running_list, pass_list, and no_pass_list with actual execution parameters

## Enhanced Features for UltraThink Requirements

The regression script includes three key enhancements specifically designed for advanced test validation and coverage analysis:

### 🎯 Group Failure Logic
**When using `run_cnt=10`, if one test fails, all 10 instances are marked as FAIL** in:
- `regression_result_xxxxx.txt` - All 10 instances marked as FAIL
- `regression_summary.txt` - Complete failure tracking
- Group failure logic ensures consistent test stability reporting

**Implementation**:
- Automatic test group tracking for `run_cnt > 1` tests
- If any test in a group fails, entire group is marked as FAIL
- Provides clear indication of test stability issues

**Example**:
```bash
# Test list entry
axi4_wstrb_test run_cnt=10

# If axi4_wstrb_test_3 fails, then axi4_wstrb_test_1 through axi4_wstrb_test_10 
# will ALL be marked as FAIL for consistent failure reporting
```

### 🎯 Individual Run Tracking in List Files
**List files show individual runs with actual seeds** for better debugging and reproduction:
- `pass_list` shows each individual run with its actual seed
- `no_pass_list` shows each failed run with its actual seed
- `running_list` shows all runs with actual execution parameters

**Benefits**:
- Perfect seed tracking for reproduction
- Individual run visibility for debugging
- Clean test names without `_xx` suffixes

**Example**:
```bash
# Test list entry:
axi4_wstrb_test run_cnt=3

# pass_list shows:
axi4_wstrb_test seed=1518832966
axi4_wstrb_test seed=150298808
axi4_wstrb_test seed=987654321
```

### 🎯 Pattern Recognition for Different Settings
**Same pattern name with different settings gets unique names** for proper coverage and log collection:
- Automatically detects duplicate patterns with different settings
- Generates unique names with `_configN` suffix
- Ensures proper coverage collection and log separation

**Example**:
```bash
# Test list entries:
axi4_wstrb_test seed=123
axi4_wstrb_test seed=456 command_add=+define+DEBUG  
axi4_wstrb_test seed=789

# Results in unique test names:
axi4_wstrb_test           # First occurrence
axi4_wstrb_test_config2   # Second occurrence with different settings
axi4_wstrb_test_config3   # Third occurrence with different settings
```

**Benefits**:
- Accurate coverage collection for each configuration
- Separate log files for each test variant
- Proper identification of different test scenarios
- Prevents coverage data corruption from mixed configurations

### Testing Enhanced Features
Use the provided test file to verify all three enhancements:
```bash
python3 axi4_regression.py --test-list test_enhanced_features.list
```

This will demonstrate:
1. **Group failure logic** with `run_cnt=3` tests
2. **Pattern recognition** with multiple `axi4_wstrb_all_ones_test` entries using different settings
3. **Clean list generation** with suffix removal in the generated list files

The test file includes:
```bash
# Group failure test - if one fails, all should be marked as failed
axi4_tc_046_id_multiple_writes_same_awid_test run_cnt=3

# Pattern recognition test - should get unique names
axi4_wstrb_all_ones_test seed=123
axi4_wstrb_all_ones_test seed=456 command_add=+define+DEBUG
axi4_wstrb_all_ones_test seed=789

# Clean list test - check suffix removal in pass_list/no_pass_list
axi4_wstrb_all_zero_test run_cnt=2 seed=111
```

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
  --cov                Enable coverage collection (function and code coverage) with VCS -cm options

Examples:
  python3 axi4_regression.py                      # Auto parallel (# of tests), local mode
  python3 axi4_regression.py -p 5                 # Limit to 5 parallel workers
  python3 axi4_regression.py --timeout 900        # 15min timeout per test
  python3 axi4_regression.py --verbose            # Verbose execution output
  python3 axi4_regression.py --fsdb-dump          # Enable FSDB waveform dumping
  python3 axi4_regression.py --cov                # Enable coverage collection
  python3 axi4_regression.py --lsf                # Use LSF job submission
  python3 axi4_regression.py --lsf -p 10 --cov    # LSF mode with coverage and 10 parallel jobs
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

### Enhanced Format with Parameters
```
# Basic tests (random seed)
axi4_write_read_test
axi4_blocking_8b_write_read_test

# Tests with custom seeds
axi4_tc_058_exclusive_read_fail_test seed=12345
axi4_wstrb_single_bit_test seed=67890

# Tests with custom VCS commands
axi4_non_blocking_write_test command_add=+define+DEBUG_MODE
axi4_write_read_test command_add=+define+VERBOSE_CHECKS

# Tests combining multiple parameters
axi4_blocking_32b_write_read_test run_cnt=3 seed=99999
axi4_wstrb_all_ones_test seed=55555 command_add=+define+SPECIAL_TEST
axi4_tc_057_exclusive_read_success_test run_cnt=2 seed=33333 command_add=+define+MULTI_PARAM_TEST
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

## Custom Seed and Command Support

The regression system supports loading custom seeds and VCS commands directly from the test list, providing fine-grained control over test execution parameters.

### Custom Seed Support

#### Features
- ✅ **Direct Seed Control**: Override random seed generation with specific values
- ✅ **Reproducible Tests**: Use consistent seeds for debugging and reproduction
- ✅ **Test List Integration**: Specify seeds directly in test list files
- ✅ **Validation**: Automatic validation of seed ranges (0 ≤ seed ≤ 2³¹-1)
- ✅ **Fallback**: Invalid seeds fall back to random generation with warnings

#### Format: `testname seed=N`
```
# Tests with custom seeds for reproducible results
axi4_write_read_test seed=12345
axi4_wstrb_single_bit_test seed=67890
axi4_tc_054_exclusive_read_fail_test seed=99999

# Mixed with repetition
axi4_blocking_32b_write_read_test run_cnt=3 seed=55555

# Each repetition uses the same custom seed
# Results: test_1.log, test_2.log, test_3.log (all with seed=55555)
```

#### VCS Command Integration
```bash
# Without custom seed (random generation)
vcs +ntb_random_seed=1847293756 [other options]

# With custom seed
vcs +ntb_random_seed=12345 [other options]
```

#### Console Output
```
📋 Loaded axi4_write_read_test with seed=12345
    Using custom seed: 12345
```

### Custom VCS Command Support

#### Features  
- ✅ **Flexible Command Addition**: Add any VCS command-line options
- ✅ **Debug Support**: Add debugging defines and options
- ✅ **Complex Commands**: Support multiple defines and options
- ✅ **Test List Integration**: Specify commands directly in test list files
- ✅ **Safe Parsing**: Handles complex command strings with proper parsing

#### Format: `testname command_add=+define+XXX`
```
# Tests with custom VCS commands
axi4_write_read_test command_add=+define+DEBUG_MODE
axi4_wstrb_single_bit_test command_add=+define+VERBOSE_CHECKS
axi4_blocking_32b_write_read_test command_add=+define+SPECIAL_TEST

# Multiple defines in one command
axi4_tc_054_exclusive_read_fail_test command_add=+define+DEBUG+define+VERBOSE

# Complex commands with multiple options
axi4_non_blocking_write_test command_add=+define+TEST_MODE+define+ENABLE_CHECKS
```

#### VCS Command Integration
```bash
# Without custom command
vcs -full64 -lca -kdb [standard options] -l test.log

# With custom command
vcs -full64 -lca -kdb [standard options] +define+DEBUG_MODE -l test.log

# With multiple defines
vcs -full64 -lca -kdb [standard options] +define+DEBUG+define+VERBOSE -l test.log
```

#### Console Output
```
📋 Loaded axi4_write_read_test with command_add=+define+DEBUG_MODE
    Adding custom command: +define+DEBUG_MODE
```

### Combined Parameter Support

#### Multiple Parameters
All parameters can be combined in any order:
```
# All parameter combinations supported
testname seed=123
testname command_add=+define+DEBUG
testname run_cnt=3
testname seed=123 command_add=+define+DEBUG
testname run_cnt=3 seed=123
testname run_cnt=3 command_add=+define+DEBUG
testname run_cnt=3 seed=123 command_add=+define+DEBUG
```

#### Parameter Processing Order
Parameters are processed independently and can appear in any order:
```
# These are equivalent
axi4_test run_cnt=3 seed=123 command_add=+define+DEBUG
axi4_test seed=123 command_add=+define+DEBUG run_cnt=3
axi4_test command_add=+define+DEBUG run_cnt=3 seed=123
```

#### Error Handling
```bash
# Valid formats
axi4_test seed=12345                    # ✅ Valid seed
axi4_test command_add=+define+DEBUG     # ✅ Valid command
axi4_test seed=0                        # ✅ Valid (minimum seed)
axi4_test seed=2147483647              # ✅ Valid (maximum seed)

# Invalid formats (fall back with warnings)
axi4_test seed=-1                       # ⚠️ Warning: seed out of range
axi4_test seed=2147483648              # ⚠️ Warning: seed too large
axi4_test seed=abc                      # ⚠️ Warning: invalid literal for int()
axi4_test command_add=                  # ⚠️ Warning: command_add cannot be empty
```

#### Console Output for Errors
```
⚠️  Warning: Invalid seed format in 'axi4_test seed=-1': seed must be 0 <= seed <= 2^31-1, got -1
    Expected format: 'testname seed=123'

⚠️  Warning: Invalid command_add format in 'axi4_test command_add=': command_add cannot be empty
    Expected format: 'testname command_add=+define+XXX'
```

### Practical Examples

#### Debugging Workflow
```bash
# 1. Create debug test list with custom seed for reproducibility
echo "failing_test seed=12345 command_add=+define+DEBUG_MODE" > debug.list

# 2. Run with verbose output and FSDB dumping
python3 axi4_regression.py --test-list debug.list --verbose --fsdb-dump

# 3. Re-run with same seed to reproduce exact behavior
python3 axi4_regression.py --test-list debug.list --verbose
```

#### Stress Testing
```bash
# Create stress test list with repeated runs using same seed
cat > stress.list << EOF
critical_test run_cnt=10 seed=99999
critical_test run_cnt=5 seed=88888 command_add=+define+STRESS_MODE
EOF

python3 axi4_regression.py --test-list stress.list
```

#### Performance Testing
```bash
# Test with different compilation flags
cat > performance.list << EOF
perf_test command_add=+define+NO_ASSERTIONS
perf_test command_add=+define+MINIMAL_LOGGING
perf_test command_add=+define+FAST_MODE+define+NO_CHECKS
EOF

python3 axi4_regression.py --test-list performance.list
```

## Coverage Collection

The regression system provides comprehensive coverage collection capabilities using VCS coverage tools, with automatic collection, merging, and reporting.

### Coverage Features
- ✅ **Complete Coverage Types**: Line, condition, FSM, toggle, branch, and assertion coverage
- ✅ **Automatic Collection**: Coverage data collected per test with unique naming
- ✅ **Centralized Storage**: All coverage databases stored in dedicated folder
- ✅ **Automatic Merging**: Coverage databases merged using VCS `urg` tool
- ✅ **Multiple Report Formats**: Both HTML and text coverage reports generated
- ✅ **Coverage Summary**: Automatic display of coverage statistics

### Coverage Collection Setup

#### Enable Coverage Collection
```bash
# Local mode with coverage
python3 axi4_regression.py --cov

# LSF mode with coverage  
python3 axi4_regression.py --lsf --cov

# Coverage with other options
python3 axi4_regression.py --cov --verbose --max-parallel 4
python3 axi4_regression.py --cov --fsdb-dump --test-list debug.list
```

#### VCS Coverage Integration
When `--cov` is enabled, VCS commands automatically include coverage flags:
```bash
# Standard VCS command (without coverage)
vcs -full64 -lca -kdb -sverilog +v2k -debug_access+all [options]

# With coverage collection enabled
vcs -full64 -lca -kdb -sverilog +v2k -debug_access+all \
    -cm line+cond+fsm+tgl+branch+assert \  # Coverage types including assertions
    -cm_dir test_name.vdb \                # Coverage database directory
    -cm_name test_name \                   # Coverage instance name
    [other options]
```

### Coverage Data Organization

#### Folder Structure
```
regression_result_YYYYMMDD_HHMMSS/
├── logs/                              # Test logs
│   ├── pass_logs/
│   └── no_pass_logs/
└── coverage_collect/                  # ← Coverage collection folder
    ├── test1_cov_00.vdb/              # Individual test coverage databases
    ├── test2_cov_01.vdb/
    ├── test3_cov_02.vdb/
    ├── ...
    ├── merged_coverage.vdb/           # ← Merged coverage database
    └── coverage_report/               # ← Coverage reports
        ├── index.html                 # HTML coverage report
        ├── summary.txt                # Text coverage summary
        ├── hier.html                  # Hierarchical coverage
        ├── module.html                # Module-level coverage
        └── [other coverage files]
```

#### Coverage Database Naming
Each test gets a unique coverage database to avoid conflicts:
- Format: `{test_name}_cov_{folder_id:02d}.vdb`
- Examples:
  - `axi4_write_read_test_cov_00.vdb`
  - `axi4_wstrb_all_ones_test_1_cov_01.vdb` (for repeated tests)
  - `axi4_blocking_32b_write_read_test_cov_02.vdb`

### Coverage Collection Process

#### Per-Test Collection
1. **VCS Generation**: Each test generates coverage data with `-cm` flags
2. **Database Creation**: VCS creates `test_name.vdb` in run folder
3. **Automatic Copy**: Coverage database copied to central collection folder
4. **Unique Naming**: Renamed with folder ID to prevent conflicts

#### Console Output During Collection
```
📊 [Folder 00] Enabling coverage collection: axi4_write_read_test.vdb
    Enabling coverage collection: axi4_write_read_test.vdb

📊 [Folder 00] Copied coverage data: axi4_write_read_test.vdb -> axi4_write_read_test_cov_00
```

### Coverage Merging and Reporting

#### Automatic Coverage Merge
At regression completion, all coverage databases are automatically merged:
```bash
# Automatic urg command execution
urg -dir test1_cov_00.vdb -dir test2_cov_01.vdb -dir test3_cov_02.vdb \
    -dbname merged_coverage.vdb \
    -format both \
    -report coverage_report
```

#### Coverage Merge Output
```
📊 Merging coverage data from 15 test runs...
✅ Coverage merge completed successfully
   Merged database: regression_result_20250712_135844/coverage_collect/merged_coverage.vdb
   Coverage report: regression_result_20250712_135844/coverage_collect/coverage_report

📊 Coverage Summary:
   Line Coverage:      87.5% (1250/1429)
   Condition Coverage: 82.3% (234/284)
   FSM Coverage:       95.0% (38/40)
   Toggle Coverage:    78.9% (567/719)
   Branch Coverage:    85.2% (156/183)
```

### Viewing Coverage Results

#### HTML Reports (Recommended)
```bash
# Open main coverage report in browser
firefox regression_result_*/coverage_collect/coverage_report/index.html

# Or use any web browser
open regression_result_*/coverage_collect/coverage_report/index.html
```

#### Text Summary
```bash
# View text coverage summary
cat regression_result_*/coverage_collect/coverage_report/summary.txt
```

#### DVE Coverage Browser
```bash
# Open coverage database in DVE
dve -cov -covdir regression_result_*/coverage_collect/merged_coverage.vdb
```

### Coverage Examples

#### Basic Coverage Collection
```bash
# Run regression with coverage
python3 axi4_regression.py --cov --verbose

# Results available in:
# regression_result_*/coverage_collect/coverage_report/index.html
```

#### Coverage with Custom Tests
```bash
# Create test list with specific tests for coverage
cat > coverage_tests.list << EOF
axi4_write_read_test
axi4_wstrb_all_ones_test seed=12345
axi4_blocking_32b_write_read_test command_add=+define+COVERAGE_MODE
axi4_tc_053_exclusive_read_success_test run_cnt=3
EOF

# Run with coverage collection
python3 axi4_regression.py --cov --test-list coverage_tests.list
```

#### Coverage with LSF
```bash
# Large regression with coverage using LSF
python3 axi4_regression.py --lsf --cov --max-parallel 20 --verbose

# Coverage merge happens automatically after all LSF jobs complete
```

### Coverage Troubleshooting

#### Common Issues

1. **No Coverage Data Found**
   ```bash
   ⚠️  No coverage data found in coverage_collect folder
   ```
   - Verify VCS supports coverage (`which urg`)
   - Check test compilation succeeded
   - Ensure coverage collection is enabled (`--cov`)

2. **Coverage Merge Failed**
   ```bash
   ⚠️  Coverage merge tool 'urg' not found
   ```
   - Add VCS tools to PATH: `export PATH=/path/to/vcs/bin:$PATH`
   - Verify urg tool: `which urg`

3. **Coverage Merge Timeout**
   ```bash
   ⚠️  Coverage merge timed out after 10 minutes
   ```
   - Large number of tests may require longer merge time
   - Merge manually: `urg -dir test*.vdb -dbname merged.vdb`

#### Debug Coverage Collection
```bash
# Run single test with coverage and verbose output
echo "debug_test" > single.list
python3 axi4_regression.py --cov --verbose --test-list single.list

# Check coverage folder contents
ls -la regression_result_*/coverage_collect/
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
├── running_list                              # All test execution parameters
├── pass_list                                 # Passed test execution parameters
├── no_pass_list                              # Failed test execution parameters
├── logs/                                     # All test logs organized by status
│   ├── pass_logs/                            # Passing test logs
│   │   ├── axi4_write_read_test.log
│   │   ├── axi4_tc_049_awlen_out_of_spec_test.log
│   │   ├── axi4_tc_051_exclusive_write_success_test.log
│   │   └── ...
│   └── no_pass_logs/                         # Failing test logs
│       └── axi4_non_blocking_write_read_response_out_of_order_test.log
└── coverage_collect/                         # Coverage data (if --cov used)
    ├── test1_cov_00.vdb/                     # Individual coverage databases
    ├── test2_cov_01.vdb/
    ├── merged_coverage.vdb/                  # Merged coverage database
    └── coverage_report/                      # Coverage reports
        ├── index.html                        # HTML coverage report
        └── summary.txt                       # Text summary
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

## Test Execution Lists

The regression system automatically generates three list files that capture the actual test execution parameters used during the regression run. These lists are invaluable for test reproduction, debugging, and rerunning specific test subsets.

### Generated List Files

#### running_list
Contains all test execution parameters actually used during the regression run:
- **Format**: `test_name [seed=XXX] [command_add=XXX]`
- **Content**: Every test with its actual execution parameters (including generated seeds)
- **Use Case**: Complete record of regression execution for reproduction

#### pass_list  
Contains only the passed tests with their execution parameters:
- **Format**: `test_name [seed=XXX] [command_add=XXX]`
- **Content**: Only tests that passed with PASS status
- **Use Case**: Rerun only successful tests or verify passing configurations

#### no_pass_list
Contains only the failed tests with their execution parameters:
- **Format**: `test_name [seed=XXX] [command_add=XXX]`
- **Content**: Only tests that failed (FAIL, ERROR, TIMEOUT status)
- **Use Case**: Rerun only failed tests for debugging or fixing

### List Generation Features

- ✅ **Actual Parameters**: Captures real execution parameters, not just test list inputs
- ✅ **Generated Seeds**: Shows actual random seeds used, not just custom ones
- ✅ **Same Format**: All lists use identical format for easy interchange
- ✅ **Automatic Generation**: Created automatically at regression completion
- ✅ **Ready to Use**: Lists can be used directly as test list input files

### Example List Contents

#### Sample running_list
```
# Running list generated on 2025-07-14 11:10:27
# Test execution parameters actually used in this regression run
# Format: test_name [seed=XXX] [command_add=XXX]
# Total tests: 5
#
axi4_write_read_test seed=1234567890
axi4_blocking_32b_write_read_test seed=9876543210 command_add=+define+DEBUG
axi4_wstrb_all_ones_test_1 seed=1111111111
axi4_wstrb_all_ones_test_2 seed=2222222222
axi4_nonexistent_test seed=5555555555
```

#### Sample pass_list
```
# Pass list generated on 2025-07-14 11:10:27
# Test execution parameters for passed tests
# Format: test_name [seed=XXX] [command_add=XXX]
# Total passed tests: 4
#
axi4_write_read_test seed=1234567890
axi4_blocking_32b_write_read_test seed=9876543210 command_add=+define+DEBUG
axi4_wstrb_all_ones_test_1 seed=1111111111
axi4_wstrb_all_ones_test_2 seed=2222222222
```

#### Sample no_pass_list
```
# No pass list generated on 2025-07-14 11:10:27
# Test execution parameters for failed tests
# Format: test_name [seed=XXX] [command_add=XXX]
# Total failed tests: 1
#
axi4_nonexistent_test seed=5555555555
```

### Console Output During Generation
```
📋 Generated running list: regression_result_20250714_110932/running_list
📋 Generated pass list: regression_result_20250714_110932/pass_list
📋 Generated no pass list: regression_result_20250714_110932/no_pass_list
```

### Practical Usage Examples

#### Reproduce Entire Regression
```bash
# Use running_list to reproduce exact same regression
cp regression_result_20250714_110932/running_list reproduce_regression.list
python3 axi4_regression.py --test-list reproduce_regression.list
```

#### Rerun Only Failed Tests
```bash
# Use no_pass_list to debug failed tests with exact same parameters
cp regression_result_20250714_110932/no_pass_list debug_failures.list
python3 axi4_regression.py --test-list debug_failures.list --verbose --fsdb-dump
```

#### Rerun Only Passed Tests
```bash
# Use pass_list for smoke testing or validation
cp regression_result_20250714_110932/pass_list smoke_test.list
python3 axi4_regression.py --test-list smoke_test.list --max-parallel 10
```

#### Create Custom Subset
```bash
# Combine lists or extract specific tests
head -5 regression_result_20250714_110932/running_list > quick_test.list
echo "axi4_custom_test seed=99999" >> quick_test.list
python3 axi4_regression.py --test-list quick_test.list
```

### Benefits

1. **Perfect Reproduction**: Exact same seeds and commands used in original run
2. **Efficient Debugging**: Focus only on failed tests with original parameters
3. **Incremental Testing**: Rerun only passed tests for verification
4. **Test History**: Complete record of what was actually executed
5. **Easy Integration**: Lists work seamlessly with existing test list infrastructure

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
│   ├── running_list                    # All test execution parameters
│   ├── pass_list                       # Passed test execution parameters
│   ├── no_pass_list                    # Failed test execution parameters
│   ├── logs/                           # All organized logs
│   │   ├── pass_logs/                  # All passing test logs
│   │   │   ├── axi4_write_read_test.log
│   │   │   ├── axi4_wstrb_single_bit_test_1.log
│   │   │   ├── axi4_wstrb_single_bit_test_2.log
│   │   │   └── ...
│   │   └── no_pass_logs/               # All failing test logs
│   │       └── failed_test.log
│   └── coverage_collect/               # Coverage data (if --cov used)
│       ├── test1_cov_00.vdb/           # Individual coverage databases
│       ├── test2_cov_01.vdb/
│       ├── merged_coverage.vdb/        # Merged coverage database
│       └── coverage_report/            # Coverage reports
│           ├── index.html              # HTML coverage report
│           └── summary.txt             # Text summary
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

5. **LSF Issues**
   ```bash
   # Check LSF availability
   which bsub bjobs bkill
   
   # Check LSF job status
   bjobs -u $USER
   
   # If LSF jobs fail with "Cannot open file" errors:
   # Verify axi4_compile.f exists at sim level
   ls -la ../axi4_compile.f
   
   # Check run folder creation
   ls -la ../run_folder_*
   
   # For "LSF job exited with error":
   # Check individual job logs in run folders
   cat ../run_folder_*/testname.log
   ```

6. **File Path Issues**
   ```bash
   # Verify compile file path from run folder
   cd ../run_folder_00
   ls -la ../axi4_compile.f  # Should exist
   
   # Check if using correct relative path
   grep "axi4_compile.f" lsf_job_*.sh
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

### Coverage Collection Examples
```bash
# Basic coverage collection
python3 axi4_regression.py --cov --verbose

# Coverage with specific test list
python3 axi4_regression.py --cov --test-list coverage_tests.list

# Coverage with LSF for large regressions
python3 axi4_regression.py --lsf --cov --max-parallel 20

# Combined coverage and debugging
python3 axi4_regression.py --cov --fsdb-dump --verbose --test-list debug.list

# View coverage results
firefox regression_result_*/coverage_collect/coverage_report/index.html
```

### Advanced Parameter Examples
```bash
# Create advanced test list with all features
cat > advanced_tests.list << EOF
# Basic tests
axi4_write_read_test
axi4_blocking_8b_write_read_test

# Custom seeds for reproducibility
axi4_wstrb_single_bit_test seed=12345
axi4_tc_054_exclusive_read_fail_test seed=67890

# Custom VCS commands for debugging
axi4_non_blocking_write_test command_add=+define+DEBUG_MODE
axi4_write_read_test command_add=+define+VERBOSE_CHECKS

# Combined parameters
axi4_blocking_32b_write_read_test run_cnt=3 seed=99999
axi4_wstrb_all_ones_test seed=55555 command_add=+define+SPECIAL_TEST
axi4_tc_057_exclusive_read_success_test run_cnt=2 seed=33333 command_add=+define+MULTI_PARAM_TEST
EOF

# Run with coverage and verbose output
python3 axi4_regression.py --cov --verbose --test-list advanced_tests.list
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

### Version 2025.01.16 (Latest)

#### LSF System Improvements
- ✅ **Fixed Critical LSF Issues**: Resolved compile file path problems that caused LSF job failures
- ✅ **Improved File Management**: Both scripts now use `../axi4_compile.f` instead of copying files
- ✅ **Enhanced Performance**: Eliminated unnecessary file copying overhead in setup phase
- ✅ **Cleaner Run Folders**: Removed file duplication, keeping only essential VCS artifacts
- ✅ **100% LSF Success Rate**: Both original and makefile scripts now work perfectly with LSF
- ✅ **Complete Feature Parity**: All functionality preserved while improving efficiency
- ✅ **Better Resource Usage**: Reduced disk usage by eliminating redundant file copies

### Version 2025.01 Major Features

#### Test Execution Lists (Enhanced)
- ✅ **running_list**: Shows individual runs with actual seeds (no `_xx` suffixes)
- ✅ **pass_list**: Shows individual passed runs with actual seeds (no consolidation)
- ✅ **no_pass_list**: Shows individual failed runs with actual seeds and status info
- ✅ **Individual Run Tracking**: Each test run tracked separately, not consolidated
- ✅ **Clean Test Names**: Removed `_xx` suffixes for better readability
- ✅ **Perfect Reproduction**: Use exact seeds from lists to reproduce specific test runs

#### Test Repetition System
- ✅ **New Syntax**: `testname run_cnt=N` format for explicit test repetition
- ✅ **Numbered Logs**: Automatic generation of `testname_1.log`, `testname_2.log`, etc.
- ✅ **Unique Seeds**: Each repetition gets different random seed for better coverage
- ✅ **Mixed Format**: Support both single and repeated tests in same test list
- ✅ **Error Handling**: Invalid formats fall back to single test with clear warnings

#### Custom Seed and Command Support
- ✅ **Custom Seeds**: Load specific seeds from test list (e.g., `testname seed=123`)
- ✅ **VCS Commands**: Add custom VCS commands from test list (e.g., `command_add=+define+DEBUG`)
- ✅ **Parameter Combinations**: Mix run_cnt, seed, and command_add in any order
- ✅ **Reproducible Debugging**: Use consistent seeds for test reproduction
- ✅ **Flexible Testing**: Add compilation flags and defines per test

#### Coverage Collection System
- ✅ **Comprehensive Coverage**: Line, condition, FSM, toggle, branch, and assertion coverage
- ✅ **Automatic Collection**: Coverage databases collected per test with unique naming
- ✅ **Centralized Storage**: All coverage data stored in dedicated collection folder
- ✅ **Automatic Merging**: Coverage databases merged using VCS urg tool
- ✅ **Multiple Reports**: HTML and text coverage reports with summary statistics

#### Enhanced Error Reporting
- ✅ **UVM Count Tracking**: Exact parsing of UVM_ERROR and UVM_FATAL counts from test logs
- ✅ **Comprehensive Summary**: New `regression_summary.txt` with ALL test records
- ✅ **Sequential Numbering**: Tests numbered [1], [2], [3]... for easy reference
- ✅ **Status Grouping**: Tests organized by priority (TIMEOUT → FAIL/ERROR → PASS)
- ✅ **Detailed Error Context**: Complete error information with UVM counts for each failed test

#### UltraThink Advanced Features
- ✅ **Group Failure Logic**: When `run_cnt=10` and one test fails, all 10 are marked as FAIL
- ✅ **Clean List Files**: Suffix removal (`_xx`) for consolidated test entries in lists
- ✅ **Pattern Recognition**: Unique names for same test with different settings (`_configN`)
- ✅ **Enhanced Coverage**: Proper coverage collection for each test configuration
- ✅ **Smart Test Grouping**: Automatic tracking and management of test groups

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

### v2025.01.15 (Current) - Enhanced List Generation & Parallel Execution
- **Fixed List Generation**: List files now show individual runs with actual seeds for perfect debugging
- **Group Failure Logic**: When using `run_cnt=N`, if one test fails, all N instances are marked as FAIL
- **Clean Test Names**: Removed `_xx` suffixes from list files for cleaner output
- **Pattern Recognition**: Same test name with different settings gets unique names for proper coverage
- **Improved Parallel Execution**: Better folder isolation and VCS conflict prevention
- **Individual Run Tracking**: Each test run shows its actual seed and parameters in lists

### v2025.01 - Major Feature Release  
- **Test Execution Lists**: Automatic generation of running_list, pass_list, and no_pass_list with actual execution parameters
- **Test Repetition**: New `run_cnt=N` syntax for explicit test repetition
- **Custom Seed Support**: Load custom seeds from test list (`seed=123`)
- **Custom VCS Commands**: Add VCS commands from test list (`command_add=+define+DEBUG`)
- **Coverage Collection**: Comprehensive coverage with automatic merging (`--cov`)
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

## Additional Features

### Makefile Version
For users who prefer Makefile-based execution, see `axi4_regression_makefile.py` which includes:
- **Timing Controls**: Configurable `--log-wait-timeout` and `--cleanup-delay` parameters for large designs
- **Makefile Integration**: VCS commands centralized in Makefile for better maintainability
- **Build System Integration**: Natural integration with existing make-based workflows

See `README_MAKEFILE_REGRESSION.md` for complete documentation.

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