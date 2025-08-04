# AXI4 Regression Script Patch Summary

## Problem
The original `axi4_regression.py` script did not include the random seed in log filenames. This caused issues when:
1. Multiple runs of the same test with different seeds would overwrite each other's log files
2. In regression results, only 3 fail cases were visible when actually 24 cases failed
3. It was impossible to determine which seed was used for a particular test run

## Solution
Patched `axi4_regression.py` to include the seed value in all log filenames using the format:
- `test_name_seed.log` (e.g., `axi4_qos_basic_priority_test_12345.log`)

## Changes Made

### 1. Sequential Test Execution (`_run_single_test`)
- Modified to determine log filename after seed generation
- Log file path now includes seed: `{test_name}_{seed_value}.log`

### 2. LSF Job Submission (`submit_lsf_job`)
- Updated job script generation to include seed in log filename
- Log filename determined after seed is generated or provided

### 3. LSF Job Analysis
- Updated to look for log files with seed in the name
- Properly constructs log path: `{test_name}_{seed}.log`

### 4. Log Copying Functions
- `_ensure_log_copied`: Updated to copy logs with seed in filename
- Added fallback logic to handle both new (with seed) and old (without seed) formats
- Updated all `shutil.copy2` calls to use seed-based filenames

### 5. Report Generation
- Summary reports now show log files with seeds
- Failed test listings include seed in log paths
- Pass/no-pass lists properly reference seed-named logs

### 6. Log Organization
- `pass_logs/` folder: Contains logs named `test_name_seed.log` for passed tests
- `no_pass_logs/` folder: Contains logs named `test_name_seed.log` for failed tests

## Benefits

1. **No Log Overwrites**: Each test run with a unique seed gets its own log file
2. **Full Visibility**: All 24 failed tests will now have separate log files in `no_pass_logs/`
3. **Seed Traceability**: Can identify which seed was used for any test by looking at the filename
4. **Backward Compatible**: Falls back to looking for logs without seeds for older runs

## Usage Example

Running a test multiple times with different seeds:
```
axi4_qos_basic_priority_test seed=12345
axi4_qos_basic_priority_test seed=67890
axi4_qos_basic_priority_test seed=11111
```

Will create separate log files:
```
no_pass_logs/
├── axi4_qos_basic_priority_test_12345.log
├── axi4_qos_basic_priority_test_67890.log
└── axi4_qos_basic_priority_test_11111.log
```

## Verification

Run `test_seed_logging.py` to verify the patch works correctly.