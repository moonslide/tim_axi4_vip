# BUS_MATRIX_MODE Command Line Override Fix Summary

## Issue
The user wanted the ability to override the bus matrix mode via command line:
- `+BUS_MATRIX_MODE=NONE` should use only 1 master and 1 slave
- `+BUS_MATRIX_MODE=BASE` should use 4 masters and 4 slaves  
- `+BUS_MATRIX_MODE=ENHANCED` should use all 10 masters and 10 slaves

## Root Cause
The command line override using `$value$plusargs` was in the wrong location:
1. Originally in `axi4_test_config::apply_category_config()` - evaluated too early
2. Needed to be in `axi4_base_test::setup_test_configuration()` after test_config is created

## Solution Implemented

### 1. Modified axi4_base_test.sv
- Moved `$value$plusargs` check to `setup_test_configuration()` function
- Override happens AFTER test configuration is created based on test name
- This ensures command line takes precedence over automatic configuration

```systemverilog
// Check for command line override of bus matrix mode AFTER configuring
if ($value$plusargs("BUS_MATRIX_MODE=%s", bus_mode_str)) begin
  case (bus_mode_str)
    "NONE": test_config.bus_matrix_mode = axi4_bus_matrix_ref::NONE;
    "BASE", "4x4": test_config.bus_matrix_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
    "ENHANCED", "10x10": test_config.bus_matrix_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
  endcase
end
```

### 2. Updated axi4_virtual_error_inject_full_seq.sv
- Sequence now checks bus matrix mode and adjusts active master count
- NONE mode: Uses 1 master/1 slave
- BASE mode: Uses 4 masters/4 slaves
- ENHANCED mode: Uses all available masters/slaves

```systemverilog
case (bus_mode)
  axi4_bus_matrix_ref::NONE: begin
    num_masters_to_use = 1;
    num_slaves_to_use = 1;
  end
  axi4_bus_matrix_ref::BASE_BUS_MATRIX: begin
    num_masters_to_use = 4;
    num_slaves_to_use = 4;
  end
  axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: begin
    num_masters_to_use = env_cfg_h.no_of_masters;
    num_slaves_to_use = env_cfg_h.no_of_slaves;
  end
endcase
```

### 3. Updated axi4_error_inject_base_test.sv
- Base test automatically selects full sequence for all modes
- Passes bus matrix mode to sequence via config_db
- Full sequence handles the dynamic master/slave count

## Usage Examples

```bash
# Run with NONE mode (1 master/1 slave)
./run_test.csh axi4_error_inject_x_drive_test +BUS_MATRIX_MODE=NONE

# Run with BASE mode (4 masters/4 slaves)  
./run_test.csh axi4_error_inject_x_drive_test +BUS_MATRIX_MODE=BASE

# Run with ENHANCED mode (10 masters/10 slaves)
./run_test.csh axi4_error_inject_x_drive_test +BUS_MATRIX_MODE=ENHANCED

# Use default mode based on test category
./run_test.csh axi4_error_inject_x_drive_test
```

## Test Verification
Created `test_bus_mode_override.sh` script to verify all three modes work correctly.

## Key Benefits
1. Command line override works for any test
2. Tests can still create their full interface arrays (10x10)
3. Only the specified subset of masters/slaves are activated
4. Allows flexible testing without recompilation
5. Maintains backward compatibility with existing tests

## Files Modified
1. `/test/axi4_base_test.sv` - Added command line override in setup_test_configuration()
2. `/test/axi4_test_config.sv` - Removed duplicate plusargs check
3. `/virtual_seq/axi4_virtual_error_inject_full_seq.sv` - Dynamic master/slave usage
4. `/test/axi4_error_inject_base_test.sv` - Always uses full sequence with mode control