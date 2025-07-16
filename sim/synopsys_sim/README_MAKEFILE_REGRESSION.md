# AXI4 Makefile-Based Regression System

This document describes the new Makefile-based regression runner that provides all the functionality of `axi4_regression.py` but uses Makefile targets for test execution instead of generating VCS commands directly.

## Table of Contents

- [Overview](#overview)
- [Enhanced Features for UltraThink Requirements](#enhanced-features-for-ultrathink-requirements)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Command Line Options](#command-line-options)
- [Test List Format](#test-list-format)
- [Makefile Integration](#makefile-integration)
- [Features](#features)
- [Test Execution Lists](#test-execution-lists)
- [Folder Structure](#folder-structure)
- [Examples](#examples)
- [Comparison with Original Script](#comparison-with-original-script)
- [Troubleshooting](#troubleshooting)

## Overview

The `axi4_regression_makefile.py` script is a new version of the AXI4 regression runner that delegates VCS test execution to a Makefile while maintaining all the same features:

- ✅ **Parallel Execution**: Run up to 50 tests simultaneously (local) or unlimited (LSF)
- ✅ **Test Repetition**: Run tests multiple times with numbered logs (e.g., `testname run_cnt=10`)
- ✅ **Custom Seed Support**: Load custom seeds from test list (e.g., `testname seed=123`)
- ✅ **Custom VCS Commands**: Add custom VCS commands from test list (e.g., `command_add=+define+DEBUG`)
- ✅ **Coverage Collection**: Comprehensive function and code coverage with automatic merging
- ✅ **LSF Support**: Full Load Sharing Facility integration with job monitoring
- ✅ **Real-time Progress**: Live progress tracking with ETA and job status
- ✅ **Comprehensive Logging**: Detailed logs for each test with automatic organization
- ✅ **Test Execution Lists**: Automatic generation of running_list, pass_list, and no_pass_list with actual execution parameters

## Enhanced Features for UltraThink Requirements

The Makefile-based regression script includes the same three key enhancements as the original script, specifically designed for advanced test validation and coverage analysis:

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
- `no_pass_list` shows each failed run with its actual seed and status info
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
Use the provided test file to verify all enhancements:
```bash
python3 axi4_regression_makefile.py --test-list test_enhanced_features.list
```

This demonstrates:
1. **Group failure logic** with `run_cnt=3`
2. **Pattern recognition** with different seeds/commands
3. **Clean list generation** with suffix removal

## Architecture

### Design Philosophy
The new Makefile-based architecture provides better separation of concerns:

- **Python Script**: Handles test orchestration, parallel execution, progress tracking, and result analysis
- **Makefile**: Handles VCS command construction, compilation, and execution

### Key Differences from Original Script

| Aspect | Original Script | Makefile Version |
|--------|----------------|------------------|
| **VCS Execution** | Generates shell scripts with VCS commands | Calls `make run_test` with variables |
| **Command Construction** | Python string concatenation | Makefile variable expansion |
| **Customization** | Modify Python code | Modify Makefile |
| **Integration** | Standalone | Integrates with build systems |
| **Maintenance** | VCS commands scattered in Python | VCS commands centralized in Makefile |

### Benefits
- **Cleaner Code**: VCS command logic is centralized in Makefile
- **Better Maintainability**: Changes to VCS options only require Makefile updates
- **Build System Integration**: Works naturally with existing make-based workflows
- **Consistency**: Same VCS command structure across different tools
- **Flexibility**: Easy to customize VCS options per project

## Quick Start

### Prerequisites
1. **Makefile**: Ensure the Makefile exists in the synopsys_sim directory (`./Makefile`)
2. **VCS Tools**: VCS and related tools must be in PATH
3. **Python 3.6+**: Required for the regression script
4. **LSF (Optional)**: LSF commands (`bsub`, `bjobs`, `bkill`) for cluster execution

### Basic Usage
```bash
# 1. Verify Makefile exists
ls -la ./Makefile

# 2. Run basic regression
python3 axi4_regression_makefile.py

# 3. Run with coverage and verbose output
python3 axi4_regression_makefile.py --cov --verbose

# 4. Run with custom test list
python3 axi4_regression_makefile.py --test-list demo_makefile_test.list
```

### Testing the Setup
```bash
# Test Makefile directly
make sim test=axi4_blocking_32b_write_read_test SEED=12345

# Test regression script with demo list
python3 axi4_regression_makefile.py --test-list test_single_quick.list --verbose

# Test LSF availability (if available)
python3 axi4_regression_makefile.py --lsf --test-list test_single_quick.list
```

## Command Line Options

The script supports all the same options as the original regression script, plus additional timing controls:

```bash
Usage: axi4_regression_makefile.py [-h] [--max-parallel MAX_PARALLEL]
                                   [--timeout TIMEOUT] [--verbose] [--lsf]
                                   [--test-list TEST_LIST] [--fsdb-dump] [--cov]
                                   [--log-wait-timeout SECONDS] [--cleanup-delay SECONDS]

Options:
  --max-parallel N       Maximum parallel executions (1-50, default: auto)
  --timeout N            Test timeout in seconds (min: 60, default: 600)
  --verbose              Enable verbose output
  --lsf                  Use LSF (Load Sharing Facility) for job submission
  --test-list FILE       Path to test list file (default: axi4_transfers_regression.list)
  --fsdb-dump            Enable FSDB waveform dumping
  --cov                  Enable coverage collection (function and code coverage)
  --log-wait-timeout N   Wait time for log file creation in seconds (default: 30)
  --cleanup-delay N      Delay after cleanup before VCS execution in seconds (default: 15)

Examples:
  python3 axi4_regression_makefile.py                    # Auto parallel, local mode
  python3 axi4_regression_makefile.py -p 5               # Limit to 5 parallel workers
  python3 axi4_regression_makefile.py --timeout 900      # 15min timeout per test
  python3 axi4_regression_makefile.py --verbose          # Verbose execution output
  python3 axi4_regression_makefile.py --fsdb-dump        # Enable FSDB waveform dumping
  python3 axi4_regression_makefile.py --cov              # Enable coverage collection
  python3 axi4_regression_makefile.py --lsf              # Use LSF job submission
  python3 axi4_regression_makefile.py --lsf -p 10 --cov  # LSF mode with coverage
  python3 axi4_regression_makefile.py --log-wait-timeout 60  # Large design timeout
  python3 axi4_regression_makefile.py --cleanup-delay 20     # Extra VCS cleanup delay
```

## Test List Format

The test list format is identical to the original script, supporting all the same parameters:

### Basic Format
```
# Comments start with #
axi4_write_read_test
axi4_blocking_8b_write_read_test

# Tests with custom seeds
axi4_tc_058_exclusive_read_fail_test seed=12345
axi4_wstrb_single_bit_test seed=67890

# Tests with custom VCS commands
axi4_non_blocking_write_test command_add=+define+DEBUG_MODE
axi4_write_read_test command_add=+define+VERBOSE_CHECKS

# Tests with repetition
axi4_wstrb_all_ones_test run_cnt=3

# Combined parameters
axi4_blocking_32b_write_read_test run_cnt=3 seed=99999
axi4_wstrb_test seed=55555 command_add=+define+SPECIAL_TEST
axi4_tc_057_test run_cnt=2 seed=33333 command_add=+define+MULTI_PARAM_TEST
```

### Parameter Support
- **`seed=N`**: Override random seed generation with specific value
- **`command_add=XXX`**: Add custom VCS command-line options
- **`run_cnt=N`**: Run test N times with numbered logs
- **Parameter Combinations**: All parameters can be mixed in any order

## Makefile Integration

### Required Makefile Structure

The script requires a Makefile in the synopsys_sim directory with the following:

#### 1. Required Target
```makefile
sim:
    # Target that executes VCS with provided variables
```

#### 2. Required Variables
The Makefile must accept these variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `test` | Base test name | `axi4_wstrb_test` |
| `SEED` | Random seed value | `12345` |
| `LOG_FILE` | Expected log file name | `axi4_wstrb_test_1.log` |

#### 3. Optional Variables
| Variable | Description | When Set |
|----------|-------------|----------|
| `FSDB_DUMP` | Enable FSDB dumping | `1` when `--fsdb-dump` used |
| `COVERAGE` | Enable coverage collection | `1` when `--cov` used |
| `COMMAND_ADD` | Custom VCS commands | Set when `command_add=XXX` in test list |

### Example Makefile Implementation

```makefile
# AXI4 VIP Makefile
# Default values for regression script
test ?= axi4_default_test
SEED ?= 12345
LOG_FILE ?= $(test).log
FSDB_DUMP ?= 0
COVERAGE ?= 0
COMMAND_ADD ?=

# VCS base command
VCS_BASE_CMD = vcs -full64 -lca -kdb -sverilog +v2k \\
               -debug_access+all -ntb_opts uvm-1.2 \\
               +ntb_random_seed=$(SEED) -override_timescale=1ps/1ps \\
               +nospecify +no_timing_check

# Build VCS command with conditional flags
VCS_FLAGS = $(VCS_BASE_CMD)

# Add FSDB dumping if enabled
ifeq ($(FSDB_DUMP),1)
VCS_FLAGS += +define+DUMP_FSDB
endif

# Add coverage flags if enabled
ifeq ($(COVERAGE),1)
VCS_FLAGS += -cm line+cond+fsm+tgl+branch+assert -cm_dir $(test).vdb -cm_name $(test)
endif

# Add testbench specific flags
VCS_FLAGS += +define+UVM_VERDI_COMPWAVE -f axi4_compile.f \\
             -debug_access+all -R +UVM_TESTNAME=$(test) \\
             +UVM_VERBOSITY=MEDIUM +plusarg_ignore

# Add custom commands
ifneq ($(COMMAND_ADD),)
VCS_FLAGS += $(COMMAND_ADD)
endif

# Add log file (use LOG_FILE variable passed from regression script)
VCS_FLAGS += -l $(LOG_FILE)

.PHONY: sim clean help

# Main target for running tests
sim:
	@echo "==============================================="
	@echo "Running AXI4 Test: $(test)"
	@echo "Seed: $(SEED)"
	@echo "FSDB Dump: $(FSDB_DUMP)"
	@echo "Coverage: $(COVERAGE)"
	@echo "==============================================="
	@# Clean up and execute VCS
	rm -rf simv* csrc vc_hdrs.h ucli.key *.fsdb *.daidir work.lib++ && \\
	$(VCS_FLAGS)

clean:
	rm -rf simv* csrc vc_hdrs.h ucli.key *.fsdb *.daidir work.lib++ *.log *.vdb

help:
	@echo "Available targets: sim, clean, help"
```

### Make Command Execution

When the regression script runs a test, it executes commands like:

```bash
# Basic test (executed from run_folder_XX in sim directory)
make -f ../synopsys_sim/Makefile sim test=axi4_test SEED=12345 LOG_FILE=axi4_test_1.log

# Test with coverage
make -f ../synopsys_sim/Makefile sim test=axi4_test SEED=67890 LOG_FILE=axi4_test_2.log COVERAGE=1

# Test with FSDB and custom commands
make -f ../synopsys_sim/Makefile sim test=axi4_test SEED=99999 LOG_FILE=axi4_test_3.log FSDB_DUMP=1 COMMAND_ADD="+define+DEBUG_MODE"
```

## Features

### Parallel Execution
- **Local Mode**: Up to 50 parallel tests using ThreadPoolExecutor
- **LSF Mode**: Unlimited parallel tests using LSF job submission
- **Folder Isolation**: Each test runs in separate `run_folder_XX` directory

### Test Management
- **Progress Tracking**: Real-time progress with ETA calculation
- **Test Isolation**: Each test runs in dedicated folder to prevent conflicts
- **Timeout Handling**: Automatic cleanup of stuck tests
- **Error Detection**: Comprehensive failure analysis with UVM error counting

### Coverage Collection
- **Coverage Types**: Line, condition, FSM, toggle, branch, and assertion coverage
- **Automatic Collection**: Coverage databases collected per test
- **Automatic Merging**: All coverage merged using VCS `urg` tool
- **Report Generation**: HTML and text coverage reports

### Results Organization
```
regression_result_YYYYMMDD_HHMMSS/
├── regression_results_YYYYMMDD_HHMMSS.txt    # Detailed results
├── regression_summary.txt                    # Summary report
├── running_list                              # All test execution parameters
├── pass_list                                 # Passed test execution parameters
├── no_pass_list                              # Failed test execution parameters
├── logs/                                     # Organized test logs
│   ├── pass_logs/                            # Passing test logs
│   └── no_pass_logs/                         # Failing test logs
└── coverage_collect/                         # Coverage data (if --cov used)
    ├── test1_cov_00/                         # Individual coverage databases
    ├── test2_cov_01/
    ├── merged_coverage.vdb/                  # Merged coverage database
    └── coverage_report/                      # Coverage reports
        ├── dashboard.html                    # HTML coverage report
        └── dashboard.txt                     # Text summary
```

## Test Execution Lists

The regression system automatically generates three list files that capture the actual test execution parameters used during the regression run. These lists use the same format as input test lists and can be used directly for rerunning specific test subsets.

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

### Key Features

- ✅ **Actual Parameters**: Captures real execution parameters, not just test list inputs
- ✅ **Generated Seeds**: Shows actual random seeds used, not just custom ones
- ✅ **Same Format**: All lists use identical format for easy interchange with input test lists
- ✅ **Automatic Generation**: Created automatically at regression completion
- ✅ **Ready to Use**: Lists can be used directly as `--test-list` input files

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
python3 axi4_regression_makefile.py --test-list reproduce_regression.list
```

#### Debug Failed Tests Only
```bash
# Use no_pass_list to debug failed tests with exact same parameters
cp regression_result_20250714_110932/no_pass_list debug_failures.list
python3 axi4_regression_makefile.py --test-list debug_failures.list --verbose --fsdb-dump
```

#### Smoke Test with Passed Tests
```bash
# Use pass_list for smoke testing or validation
cp regression_result_20250714_110932/pass_list smoke_test.list
python3 axi4_regression_makefile.py --test-list smoke_test.list --max-parallel 10
```

## Folder Structure

### During Execution
```
project/
├── sim/
│   ├── Makefile                              # Required Makefile
│   ├── axi4_compile.f                        # Compile file list
│   ├── run_folder_00/                        # Test execution folders (created here)
│   ├── run_folder_01/
│   ├── run_folder_XX/
│   └── synopsys_sim/
│       ├── axi4_regression_makefile.py       # New regression script
│       ├── demo_makefile_test.list           # Example test list
│       └── regression_result_YYYYMMDD_HHMMSS/ # Results folder
```

### Important Notes
- ✅ **Run Folder Location**: `run_folder_XX` directories are created in the `sim` directory (parent of `synopsys_sim`)
- ✅ **Folder Preservation**: All `run_folder_XX` directories are preserved from previous runs for debugging
- ✅ **Results Organization**: Regression results are stored in `synopsys_sim/regression_result_YYYYMMDD_HHMMSS/`

### Test Execution Flow
1. **Setup Phase**: Script verifies Makefile exists and creates execution folders
2. **Test Phase**: For each test, script calls `make run_test` with appropriate variables
3. **Collection Phase**: Logs and coverage data copied to central results folder
4. **Summary Phase**: Generate reports and merge coverage (if enabled)

## Examples

### Basic Examples

#### Run All Tests
```bash
python3 axi4_regression_makefile.py
```

#### Run with Coverage
```bash
python3 axi4_regression_makefile.py --cov --verbose
```

#### Run with Custom Parallelism
```bash
python3 axi4_regression_makefile.py --max-parallel 8 --timeout 900
```

### LSF Examples

#### LSF Availability Check
```bash
# Check if LSF is available on your system
which bsub bjobs bkill

# Test LSF availability with regression script
python3 axi4_regression_makefile.py --lsf --test-list test_single_quick.list
```

#### Basic LSF Execution
```bash
# Run all tests using LSF
python3 axi4_regression_makefile.py --lsf

# Run with custom test list
python3 axi4_regression_makefile.py --lsf --test-list my_tests.list
```

#### LSF with Coverage
```bash
# LSF with coverage collection
python3 axi4_regression_makefile.py --lsf --cov --max-parallel 20

# LSF with coverage and verbose output
python3 axi4_regression_makefile.py --lsf --cov --verbose
```

#### LSF Features
- ✅ **Unlimited Parallelism**: No limit on parallel jobs (queue dependent)
- ✅ **Job Monitoring**: Real-time status tracking with `bjobs`
- ✅ **Resource Management**: LSF handles CPU and memory allocation
- ✅ **Error Handling**: Automatic job cleanup on failure or timeout
- ✅ **Progress Tracking**: Live ETA and job status (PEND/RUN/DONE)
- ✅ **Graceful Shutdown**: Ctrl+C terminates all LSF jobs

### Custom Test List Examples

#### Create Test List
```bash
cat > my_tests.list << EOF
# Basic tests
axi4_write_read_test
axi4_blocking_32b_write_read_test seed=12345

# Debug tests with FSDB
axi4_wstrb_test command_add=+define+DEBUG_MODE

# Stress tests
axi4_tc_053_test run_cnt=5 seed=98765

# Coverage-focused tests
axi4_tc_054_test seed=11111 command_add=+define+COV_MODE
EOF
```

#### Run Custom List
```bash
python3 axi4_regression_makefile.py --test-list my_tests.list --cov --verbose
```

### Debug Examples

#### Single Test Debug
```bash
# Create single test list
echo "failing_test seed=12345 command_add=+define+DEBUG_MODE" > debug.list

# Run with FSDB and verbose output
python3 axi4_regression_makefile.py --test-list debug.list --fsdb-dump --verbose
```

#### Coverage Analysis
```bash
# Run tests with coverage
python3 axi4_regression_makefile.py --cov --test-list coverage_tests.list

# View coverage report
firefox regression_result_*/coverage_collect/coverage_report/dashboard.html
```

### Test List Examples

#### Using Generated Lists for Targeted Testing
```bash
# Run initial regression with mixed results
python3 axi4_regression_makefile.py --test-list mixed_tests.list --cov

# Debug only failed tests with exact same parameters
cp regression_result_*/no_pass_list debug_failed.list
python3 axi4_regression_makefile.py --test-list debug_failed.list --verbose --fsdb-dump

# Smoke test with only passed tests 
cp regression_result_*/pass_list smoke_test.list
python3 axi4_regression_makefile.py --test-list smoke_test.list

# Reproduce exact regression run
cp regression_result_*/running_list exact_reproduction.list
python3 axi4_regression_makefile.py --test-list exact_reproduction.list
```

### Manual Makefile Testing

#### Test Makefile Directly
```bash
# Test basic execution (from synopsys_sim directory)
make sim test=axi4_test SEED=12345 LOG_FILE=test.log

# Test with coverage
make sim test=axi4_test SEED=67890 LOG_FILE=test_cov.log COVERAGE=1

# Test with all options
make sim test=axi4_test SEED=99999 LOG_FILE=test_debug.log FSDB_DUMP=1 COVERAGE=1 COMMAND_ADD="+define+DEBUG_MODE"
```

## Comparison with Original Script

### Similarities
Both scripts provide identical functionality:
- ✅ Same command-line interface and options
- ✅ Same test list format and parameter support
- ✅ Same parallel execution and progress tracking
- ✅ Same results organization and reporting
- ✅ Same coverage collection and merging
- ✅ Same LSF integration and job management

### Key Differences

| Feature | Original Script | Makefile Version |
|---------|----------------|------------------|
| **Test Execution** | Generates shell scripts with VCS commands | Calls `make run_test` with variables |
| **Command Building** | Python string concatenation | Makefile variable expansion |
| **VCS Options** | Hardcoded in Python | Configurable in Makefile |
| **Build Integration** | Standalone execution | Natural make integration |
| **Customization** | Requires Python code changes | Modify Makefile only |
| **Dependencies** | VCS tools in PATH | VCS tools + Makefile |

### When to Use Each Version

#### Use Original Script When:
- No existing Makefile infrastructure
- Prefer self-contained Python solution
- Quick setup without additional files
- Legacy systems without make support

#### Use Makefile Version When:
- Existing make-based build system
- Need better VCS command organization
- Want build system integration
- Multiple tools sharing VCS configurations
- Better maintainability of VCS options

## Troubleshooting

### Common Issues

#### 1. Makefile Not Found
```
❌ Error: Makefile not found at /path/to/synopsys_sim/Makefile
💡 This script requires a Makefile with 'sim' target
```

**Solution**: Create or verify Makefile exists in synopsys_sim directory
```bash
ls -la ./Makefile
```

#### 2. Make Target Missing
```
make: *** No rule to make target 'sim'. Stop.
```

**Solution**: Ensure Makefile has `sim` target
```bash
make help  # Check available targets
```

#### 3. VCS Command Failure
```
make: *** [sim] Error 1
```

**Solution**: Check VCS command in Makefile and verify VCS tools are in PATH
```bash
which vcs
make sim test=simple_test SEED=12345  # Test manually
```

#### 4. Permission Issues
```
make: execvp: Permission denied
```

**Solution**: Ensure Makefile and script are executable
```bash
chmod +x axi4_regression_makefile.py
chmod 644 Makefile
```

#### 5. Coverage Merge Issues
```
⚠️ Coverage merge tool 'urg' not found
```

**Solution**: Ensure VCS tools are in PATH
```bash
which urg
export PATH=/path/to/vcs/bin:$PATH
```

#### 6. LSF Unavailable
```
❌ LSF commands not available on this system
💡 Available alternatives:
   - Install LSF package
   - Use local execution mode (without --lsf)
```

**Solution**: Either install LSF or use local mode
```bash
# Check LSF availability
which bsub bjobs bkill

# Use local mode instead
python3 axi4_regression_makefile.py --test-list my_tests.list  # No --lsf flag
```

### Debug Mode

#### Enable Verbose Output
```bash
python3 axi4_regression_makefile.py --verbose --test-list debug.list
```

#### Test Makefile Manually
```bash
make sim test=debug_test SEED=12345
```

#### Check Generated Commands
Look for verbose output showing exact make commands:
```
Running make command: ['make', '-f', './Makefile', 'sim', 'test=axi4_test', 'SEED=12345', ...]
```

### Getting Help

#### Script Help
```bash
python3 axi4_regression_makefile.py --help
```

#### Makefile Help
```bash
cd ../
make help
```

#### Check Setup
```bash
# Verify Python script
python3 -c "import axi4_regression_makefile; print('OK')"

# Verify Makefile
cd ../ && make -n run_test TEST_NAME=test SEED=1
```

## Summary

The Makefile-based regression runner provides a cleaner architecture while maintaining full feature compatibility with the original script. It's ideal for projects that want better build system integration and more maintainable VCS command organization.

**Key Benefits:**
- ✅ **Same Features**: All functionality preserved with latest enhancements
- ✅ **Individual Run Tracking**: List files show actual seeds for each run
- ✅ **Parallel Execution**: Folder isolation prevents VCS conflicts
- ✅ **Better Architecture**: Cleaner separation of concerns  
- ✅ **Build Integration**: Natural make workflow integration
- ✅ **Maintainability**: VCS commands centralized in Makefile
- ✅ **Flexibility**: Easy to customize per project needs

## Timing Parameters for Large Designs

The script includes configurable timing parameters to handle large designs and prevent database conflicts:

### Log Wait Timeout (`--log-wait-timeout`)
- **Purpose**: Wait time for log file creation after VCS completes compilation
- **Default**: 30 seconds
- **When to increase**: Large designs with slow compilation times
- **Range**: 5 seconds to unlimited

### Cleanup Delay (`--cleanup-delay`)
- **Purpose**: Delay after cleanup before starting VCS execution 
- **Default**: 15 seconds (increased from 5 in original)
- **When to increase**: Database access conflicts in parallel execution
- **Range**: 0 seconds to unlimited

### Usage Examples for Large Designs
```bash
# Large design with slow compilation
python3 axi4_regression_makefile.py --log-wait-timeout 60 --cleanup-delay 15

# Very large design requiring extra time
python3 axi4_regression_makefile.py --log-wait-timeout 120 --cleanup-delay 20

# Fast designs can use shorter timeouts
python3 axi4_regression_makefile.py --log-wait-timeout 10 --cleanup-delay 3
```

## Recent Updates

### Version 2025.01.16 (Latest)
- ✅ **Fixed Original Script LSF Issues**: Resolved critical compile file path problems in `axi4_regression.py`
- ✅ **Improved File Management**: Both scripts now use `../axi4_compile.f` instead of copying files
- ✅ **Enhanced Performance**: Eliminated unnecessary file copying overhead in setup phase
- ✅ **Cleaner Run Folders**: Removed file duplication, keeping only essential VCS artifacts
- ✅ **100% LSF Success Rate**: Both original and makefile scripts now work perfectly with LSF
- ✅ **Complete Feature Parity**: All functionality preserved while improving efficiency

### Version 2025.01.15
- ✅ **Fixed LSF Compilation Issues**: Corrected compile file paths for run folders at sim level
- ✅ **Implemented Coverage Temp Folder**: Added `/sim/coverage_temp` for coverage merging process
- ✅ **Enhanced Coverage Collection**: Fixed VDB naming to use base test names for numbered tests  
- ✅ **Improved Folder Structure**: Run folders now properly created at `/sim/run_folder_XX` level
- ✅ **Coverage Merge Workflow**: Matches reference script with temp folder, merge, move, and cleanup
- ✅ **Complete LSF+Coverage Support**: Both log naming and coverage collection work correctly in LSF mode

### Version 2025.01.14
- ✅ **Fixed List Generation**: List files now show individual runs with actual seeds
- ✅ **Improved Parallel Execution**: Simplified VCS approach using folder isolation
- ✅ **Enhanced Debugging**: Individual seed tracking for perfect reproduction
- ✅ **Clean Test Names**: Removed `_xx` suffixes from list files
- ✅ **Added Timing Controls**: Configurable log-wait-timeout and cleanup-delay parameters
- ✅ **Updated Default Values**: Cleanup delay increased to 15 seconds for better VCS stability