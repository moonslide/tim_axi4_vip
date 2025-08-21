# All Error Injection & Exception Tests Configuration Verification

## ✅ ALL TESTS PROPERLY CONFIGURED

### Test Inheritance Hierarchy
All 13 error injection and exception tests are properly configured to work with bus mode override:

```
axi4_base_test (supports +BUS_MATRIX_MODE command line override)
    └── axi4_error_inject_base_test (uses full sequence with dynamic master/slave count)
            ├── axi4_error_inject_x_drive_test ✓
            ├── axi4_error_inject_awvalid_x_test ✓
            ├── axi4_error_inject_awaddr_x_test ✓
            ├── axi4_error_inject_wdata_x_test ✓
            ├── axi4_error_inject_arvalid_x_test ✓
            ├── axi4_error_inject_bready_x_test ✓
            ├── axi4_error_inject_rready_x_test ✓
            ├── axi4_exception_abort_awvalid_test ✓
            ├── axi4_exception_abort_arvalid_test ✓
            ├── axi4_exception_near_timeout_test ✓
            ├── axi4_exception_illegal_access_test ✓
            ├── axi4_exception_ecc_error_test ✓
            └── axi4_exception_special_reg_test ✓
```

## How Configuration Works

### 1. Command Line Override (axi4_base_test.sv)
```systemverilog
if ($value$plusargs("BUS_MATRIX_MODE=%s", bus_mode_str)) begin
  case (bus_mode_str)
    "NONE": test_config.bus_matrix_mode = axi4_bus_matrix_ref::NONE;
    "BASE": test_config.bus_matrix_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
    "ENHANCED": test_config.bus_matrix_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
  endcase
end
```

### 2. Base Test Configuration (axi4_error_inject_base_test.sv)
- Determines sequence type based on bus mode
- Passes bus mode to sequence via config_db
- All tests create 10x10 interfaces but only use the configured subset

### 3. Sequence Adaptation (axi4_virtual_error_inject_full_seq.sv)
```systemverilog
case (bus_mode)
  NONE: num_masters_to_use = 1;  // 1x1
  BASE_BUS_MATRIX: num_masters_to_use = 4;  // 4x4
  BUS_ENHANCED_MATRIX: num_masters_to_use = env_cfg_h.no_of_masters;  // 10x10
endcase
```

## Running Any Test with Different Modes

All 13 tests can be run with any bus mode:

```bash
# Example: Run any test with NONE mode (1x1)
make sim test=axi4_error_inject_awvalid_x_test COMMAND_ADD="+BUS_MATRIX_MODE=NONE"
make sim test=axi4_exception_illegal_access_test COMMAND_ADD="+BUS_MATRIX_MODE=NONE"

# Example: Run any test with BASE mode (4x4)
make sim test=axi4_error_inject_wdata_x_test COMMAND_ADD="+BUS_MATRIX_MODE=BASE"
make sim test=axi4_exception_ecc_error_test COMMAND_ADD="+BUS_MATRIX_MODE=BASE"

# Example: Run any test with ENHANCED mode (10x10)
make sim test=axi4_error_inject_rready_x_test COMMAND_ADD="+BUS_MATRIX_MODE=ENHANCED"
make sim test=axi4_exception_special_reg_test COMMAND_ADD="+BUS_MATRIX_MODE=ENHANCED"
```

## Test Categories in axi4_test_config.sv

These tests are categorized as ENHANCED_MATRIX_TESTS by default:
```systemverilog
if (lower_test_name.match(".*error_inject.*") ||
    lower_test_name.match(".*exception.*")) begin
  test_category = ENHANCED_MATRIX_TESTS;
end
```

But the command line override takes precedence, allowing you to run them in any mode.

## Verification Status

| Test Name | Extends Base Test | Supports NONE | Supports BASE | Supports ENHANCED |
|-----------|------------------|---------------|---------------|-------------------|
| axi4_error_inject_x_drive_test | ✅ | ✅ | ✅ | ✅ |
| axi4_error_inject_awvalid_x_test | ✅ | ✅ | ✅ | ✅ |
| axi4_error_inject_awaddr_x_test | ✅ | ✅ | ✅ | ✅ |
| axi4_error_inject_wdata_x_test | ✅ | ✅ | ✅ | ✅ |
| axi4_error_inject_arvalid_x_test | ✅ | ✅ | ✅ | ✅ |
| axi4_error_inject_bready_x_test | ✅ | ✅ | ✅ | ✅ |
| axi4_error_inject_rready_x_test | ✅ | ✅ | ✅ | ✅ |
| axi4_exception_abort_awvalid_test | ✅ | ✅ | ✅ | ✅ |
| axi4_exception_abort_arvalid_test | ✅ | ✅ | ✅ | ✅ |
| axi4_exception_near_timeout_test | ✅ | ✅ | ✅ | ✅ |
| axi4_exception_illegal_access_test | ✅ | ✅ | ✅ | ✅ |
| axi4_exception_ecc_error_test | ✅ | ✅ | ✅ | ✅ |
| axi4_exception_special_reg_test | ✅ | ✅ | ✅ | ✅ |

## Summary

✅ **ALL 13 TEST CASES ARE PROPERLY CONFIGURED**

- All tests extend from `axi4_error_inject_base_test`
- Base test extends from `axi4_base_test` which supports command line override
- Full sequence dynamically adjusts master/slave count based on bus mode
- Tests can run with any bus mode via `+BUS_MATRIX_MODE=` override
- No additional changes needed - all tests are ready to use