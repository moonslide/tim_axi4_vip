# AXI4 Regression Test System

This directory contains two comprehensive parallel regression test systems for AXI4 verification with advanced features for parallel execution, test repetition, error tracking, and comprehensive reporting.

## 🚀 Quick Start

Choose your preferred regression approach:

### Option 1: Direct VCS Execution (Recommended)
```bash
# Run single test
python3 axi4_regression.py --test-list axi4_quick_test.list

# Run full regression with coverage
python3 axi4_regression.py --test-list axi4_transfers_regression.list --cov --lsf
```

### Option 2: Makefile-Based Execution
```bash
# Run single test  
python3 axi4_regression_makefile.py --test-list axi4_quick_test.list

# Run full regression with coverage
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --cov --lsf
```

## 📋 System Comparison

| Feature | axi4_regression.py | axi4_regression_makefile.py |
|---------|-------------------|----------------------------|
| **Execution Method** | Direct VCS commands | Makefile delegation |
| **Performance** | Slightly faster startup | Unified build system |
| **Debugging** | Direct VCS control | Makefile integration |
| **Maintenance** | Standalone | Requires Makefile sync |
| **Use Case** | Production/CI | Development/Integration |

## ✨ Common Features (Both Systems)

- ✅ **Parallel Execution**: Run up to 50 tests simultaneously (local) or unlimited (LSF)
- ✅ **Test Repetition**: Run tests multiple times with numbered logs (e.g., `testname run_cnt=10`)
- ✅ **Custom Seed Support**: Load custom seeds from test list (e.g., `testname seed=123`)
- ✅ **Custom VCS Commands**: Add custom VCS commands from test list (e.g., `command_add=+define+DEBUG`)
- ✅ **Coverage Collection**: Comprehensive function and code coverage with automatic merging
- ✅ **LSF Support**: Full Load Sharing Facility integration with job monitoring
- ✅ **Real-time Progress**: Live progress tracking with ETA and job status
- ✅ **Comprehensive Logging**: Detailed logs for each test with automatic organization
- ✅ **Enhanced Random Seeds**: Multiple entropy sources for better test randomization
- ✅ **Smart Folder Management**: Preserve last execution folder and all regression results
- ✅ **VCS Artifact Cleanup**: Automatic cleanup of compilation artifacts between tests
- ✅ **FSDB Waveform Dumping**: Optional waveform dumping control with `--fsdb-dump` flag
- ✅ **Enhanced Error Reporting**: Exact UVM_ERROR and UVM_FATAL count tracking
- ✅ **Test Execution Lists**: Automatic generation of running_list, pass_list, and no_pass_list

## 🎯 Enhanced Features for UltraThink Requirements

Both systems include three key enhancements specifically designed for advanced test validation and coverage analysis:

### Group Failure Logic
**When using `run_cnt=10`, if one test fails, all 10 instances are marked as FAIL** in:
- `regression_result_xxxxx.txt` - All 10 instances marked as FAIL
- `regression_summary.txt` - Complete failure tracking
- Group failure logic ensures consistent test stability reporting

### Individual Run Tracking in List Files
**List files show individual runs with actual seeds** for better debugging and reproduction:
- `pass_list` shows each individual run with its actual seed
- `no_pass_list` shows each failed run with its actual seed
- `running_list` shows all runs with actual execution parameters

### Pattern Recognition for Different Settings
**Same pattern name with different settings gets unique names** for proper coverage and log collection.

## 📝 Command Line Options

Both systems support identical command line options:

| Option | Description | Example |
|--------|-------------|---------|
| `--test-list` | Test list file to run | `--test-list my_tests.list` |
| `--cov` | Enable coverage collection | `--cov` |
| `--lsf` | Use LSF for parallel execution | `--lsf` |
| `--jobs` | Number of parallel jobs (local only) | `--jobs 8` |
| `--fsdb-dump` | Enable FSDB waveform dumping | `--fsdb-dump` |
| `--timeout` | Test timeout in seconds | `--timeout 3600` |
| `--verbose` | Verbose output | `--verbose` |
| `--dry-run` | Show commands without execution | `--dry-run` |

## 📊 Test List Format

Both systems use identical test list format:

```bash
# Basic test
axi4_write_read_test

# Test with repetition
axi4_wstrb_test run_cnt=10

# Test with custom seed
axi4_burst_test seed=123456

# Test with custom VCS commands
axi4_exclusive_test command_add=+define+DEBUG_MODE

# Combined parameters
axi4_complex_test run_cnt=5 seed=789012 command_add=+define+COVERAGE
```

## 📈 System Architecture

### axi4_regression.py (Direct VCS)
```
Python Script → VCS Commands → Test Execution → Results Collection
```
- Direct VCS command generation and execution
- Minimal overhead between script and simulation
- Full control over VCS parameters

### axi4_regression_makefile.py (Makefile-Based)  
```
Python Script → Makefile Targets → VCS Commands → Test Execution → Results Collection
```
- Delegates VCS execution to Makefile system
- Consistent with manual `make` workflow
- Unified build and test system

## 📁 Output Structure (Identical for Both Systems)

```
regression_result_YYYYMMDD_HHMMSS/
├── logs/                          # Individual test logs
│   ├── test_name_1.log
│   ├── test_name_2.log
│   └── ...
├── coverage_collect/              # Coverage databases (if --cov)
│   ├── test_name_1.vdb/
│   ├── test_name_2.vdb/
│   └── merged_coverage.vdb/
├── regression_result_*.txt        # Main results file
├── regression_summary.txt         # Detailed summary
├── running_list                   # Tests that ran
├── pass_list                      # Tests that passed
├── no_pass_list                   # Tests that failed
└── execution_stats.txt           # Performance statistics
```

## 🛠️ When to Use Which System

### Use `axi4_regression.py` when:
- Running production regressions
- Need maximum performance
- CI/CD pipeline integration
- Simple, direct test execution
- Primary recommendation for most users

### Use `axi4_regression_makefile.py` when:
- Integrating with existing Makefile workflow
- Need unified build/test system
- Development environment setup
- Custom VCS compilation flow
- Makefile-based project structure

## 🔧 Examples

### Quick Smoke Test
```bash
# Option 1: Direct VCS
python3 axi4_regression.py --test-list axi4_smoke_tests.list --jobs 4

# Option 2: Makefile
python3 axi4_regression_makefile.py --test-list axi4_smoke_tests.list --jobs 4
```

### Full Regression with Coverage
```bash
# Option 1: Direct VCS (Recommended)
python3 axi4_regression.py --test-list axi4_transfers_regression.list --cov --lsf --timeout 7200

# Option 2: Makefile
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --cov --lsf --timeout 7200
```

### Debug Failed Tests
```bash
# Re-run only failed tests from previous regression
python3 axi4_regression.py --test-list regression_result_*/no_pass.list --fsdb-dump
```

## 📚 Additional Information

Both regression systems share identical interfaces and capabilities. This unified documentation covers all features for both systems. For implementation-specific details, refer to the source code of each script:
- `axi4_regression.py` - Direct VCS execution implementation
- `axi4_regression_makefile.py` - Makefile-based execution implementation

## 🚦 Migration Guide

### From Manual Testing
```bash
# Old way
make TEST=my_test
make TEST=my_test SEED=123

# New way (either system)
echo "my_test" > my_test.list
echo "my_test seed=123" >> my_test.list
python3 axi4_regression.py --test-list my_test.list
```

### Between Systems
Both systems use identical test list formats and produce compatible output structures, making migration seamless:

```bash
# Run with direct VCS
python3 axi4_regression.py --test-list my_tests.list --cov

# Later run with Makefile (same test list works)
python3 axi4_regression_makefile.py --test-list my_tests.list --cov
```

---

**Recommendation**: For most users, `axi4_regression.py` is the recommended choice due to its simplicity and performance. Use `axi4_regression_makefile.py` only when Makefile integration is specifically required.
