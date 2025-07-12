# AXI4 Regression Runner - Makefile Version

## Overview

`axi4_regression_makefile.py` is a new regression script that provides all the functionality of `axi4_regression.py` but uses Makefile targets to run tests instead of generating VCS commands directly.

## Key Differences from Original Script

### Architecture
- **Original**: Generates VCS command lines directly in shell scripts
- **Makefile Version**: Delegates test execution to `make run_test` with appropriate variables

### Benefits
- Cleaner separation of concerns (Python handles orchestration, Makefile handles VCS execution)
- Easier to maintain VCS command line configurations in Makefile
- Better integration with existing build systems
- Consistent VCS execution across different tools

## Usage

The script supports all the same command-line options as the original:

```bash
# Basic usage
python3 axi4_regression_makefile.py

# With specific options
python3 axi4_regression_makefile.py --max-parallel 5 --timeout 900 --verbose

# Enable coverage collection
python3 axi4_regression_makefile.py --cov

# Enable FSDB waveform dumping
python3 axi4_regression_makefile.py --fsdb-dump

# Use LSF for job submission
python3 axi4_regression_makefile.py --lsf

# Custom test list
python3 axi4_regression_makefile.py --test-list my_tests.list
```

## Makefile Integration

The script requires a `Makefile` in the parent directory with a `run_test` target that accepts the following variables:

### Required Variables
- `TEST_NAME`: Base test name (e.g., `axi4_wstrb_test`)
- `LOG_FILE`: Output log file name (e.g., `axi4_wstrb_test_1.log`)
- `RUN_DIR`: Directory where test should run (e.g., `run_folder_00`)
- `SEED`: Random seed value

### Optional Variables
- `FSDB_DUMP=1`: Enable FSDB waveform dumping
- `COVERAGE=1`: Enable coverage collection
- `COV_DIR`: Coverage database directory name
- `COMMAND_ADD`: Additional VCS command line options

### Example Makefile Target

```makefile
run_test:
	@echo "Running test $(TEST_NAME) in $(RUN_DIR)"
	cd $(RUN_DIR) && \
	vcs -full64 -lca -kdb -sverilog +v2k \
	    -debug_access+all -ntb_opts uvm-1.2 \
	    +ntb_random_seed=$(SEED) -override_timescale=1ps/1ps \
	    +nospecify +no_timing_check \
	    $(if $(FSDB_DUMP),+define+DUMP_FSDB) \
	    $(if $(COVERAGE),-cm line+cond+fsm+tgl+branch+assert -cm_dir $(COV_DIR) -cm_name $(TEST_NAME)) \
	    +define+UVM_VERDI_COMPWAVE -f ../axi4_compile.f \
	    -debug_access+all -R +UVM_TESTNAME=$(TEST_NAME) \
	    +UVM_VERBOSITY=MEDIUM +plusarg_ignore \
	    $(COMMAND_ADD) \
	    -l $(LOG_FILE)
```

## Test List Format

Supports the same test list format as the original script:

```
# Simple test
axi4_wstrb_test

# Test with custom seed
axi4_blocking_test seed=12345

# Test with multiple runs
axi4_burst_test run_cnt=3

# Test with custom VCS options
axi4_exclusive_test command_add=+define+SPECIAL_MODE

# Combined parameters
axi4_complex_test run_cnt=2 seed=98765 command_add=+define+DEBUG_MODE
```

## Features

All features from the original script are supported:

- ✅ Parallel execution (local and LSF)
- ✅ Test isolation in separate run_folder_XX directories
- ✅ Progress tracking and real-time status
- ✅ Comprehensive logging and error analysis
- ✅ Timestamped results folders
- ✅ Coverage collection and merging
- ✅ FSDB waveform dumping
- ✅ Timeout handling
- ✅ Failed test list generation
- ✅ Detailed summary reports

## Output Structure

The script creates the same output structure:

```
regression_result_YYYYMMDD_HHMMSS/
├── logs/
│   ├── pass_logs/          # Logs from passed tests
│   └── no_pass_logs/       # Logs from failed tests
├── coverage_collect/       # Coverage databases (if --cov enabled)
├── no_pass_list           # List of failed test names
├── regression_summary.txt  # Comprehensive summary
└── regression_results_YYYYMMDD_HHMMSS.txt  # Detailed results
```

## Examples

```bash
# Run a small test set
python3 axi4_regression_makefile.py --test-list test_cov_minimal.list --verbose

# Run with coverage and 3 parallel workers
python3 axi4_regression_makefile.py --cov --max-parallel 3

# Run on LSF with coverage
python3 axi4_regression_makefile.py --lsf --cov --max-parallel 10
```

## Comparison with Original Script

| Feature | Original Script | Makefile Version |
|---------|----------------|------------------|
| VCS Command Generation | Direct in Python | Delegated to Makefile |
| Test Orchestration | ✅ | ✅ |
| Parallel Execution | ✅ | ✅ |
| LSF Support | ✅ | ✅ |
| Coverage Collection | ✅ | ✅ |
| Progress Tracking | ✅ | ✅ |
| Error Analysis | ✅ | ✅ |
| Folder Management | ✅ | ✅ |

## Prerequisites

1. Python 3.6+
2. Makefile with `run_test` target in parent directory
3. VCS tools in PATH
4. LSF tools (if using `--lsf` option)

## Error Handling

The script includes the same robust error handling as the original:

- Graceful shutdown on Ctrl+C
- Timeout detection and process cleanup
- LSF job monitoring and cleanup
- Detailed error reporting and log analysis
- UVM error/fatal counting