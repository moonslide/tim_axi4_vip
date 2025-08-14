# Error Response Configuration Guide

## Overview
The AXI4 VIP provides a configuration option to control whether error responses (SLVERR, DECERR) should cause test failures in the performance metrics module.

## Configuration Option: `allow_error_responses`

### Location
The configuration is defined in `axi4_env_config.sv`:
```systemverilog
bit allow_error_responses = 0;  // Default: errors will fail the test
```

### Usage in Tests

#### For tests that intentionally generate errors:
```systemverilog
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Allow error responses for this test
  axi4_env_cfg_h.allow_error_responses = 1;
endfunction
```

#### For normal tests (default behavior):
```systemverilog
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Keep default: errors will fail the test
  // axi4_env_cfg_h.allow_error_responses = 0;  // This is the default
endfunction
```

## Behavior

### When `allow_error_responses = 1`:
- Performance metrics will NOT fail the test due to error responses
- Test will pass if there are no deadlock/livelock conditions
- Reports: "TEST RESULT: PASS - Error injection test passed (X error responses as expected)"

### When `allow_error_responses = 0` (default):
- Performance metrics WILL fail the test if any error responses occur
- Test will only pass if there are zero error responses
- Reports: "TEST RESULT: FAIL - Acceptance criteria not met" if errors occur

## Example Tests Using This Configuration

### Tests that set `allow_error_responses = 1`:
- `axi4_concurrent_writes_raw_test` - Intentionally generates SLVERR and DECERR
- Any test that intentionally tests error conditions

### Tests that keep default (`allow_error_responses = 0`):
- All normal functional tests
- Performance tests
- Regular read/write tests

## Migration from error_inject flag
The older `error_inject` flag is still supported but the new `allow_error_responses` provides clearer semantics:
- Old: `error_inject = 1` (confusing - does it inject errors or allow them?)
- New: `allow_error_responses = 1` (clear - allows error responses without failing)