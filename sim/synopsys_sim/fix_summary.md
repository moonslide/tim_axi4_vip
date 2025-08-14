# AXI4 Throughput Test Fix Summary

## Problem
The `axi4_throughput_ordering_longtail_throttled_write_test` had 2 UVM_ERRORs:
- `wdata count comparisions are failed`
- `wstrb count comparisions are failed`

## Root Cause
The `axi4_master_max_outstanding_seq` sequence was not configured with proper bus matrix addressing for different modes (NONE/4x4/10x10). It was generating addresses that didn't match the bus matrix configuration, causing transaction mismatches in the scoreboard.

## Solution Applied

### 1. Modified `axi4_master_max_outstanding_seq.sv`
Added bus matrix addressing support:
- Added `use_bus_matrix_addressing` parameter (0=NONE, 1=4x4, 2=10x10)
- Configured target addresses based on mode:
  - 4x4 mode: DDR Memory at `0x0000_0100_0000_0000`
  - 10x10 mode: DDR Secure at `0x0000_0008_0000_0000`
  - NONE mode: Simple address at `0x0000_0000_0000_0000`

### 2. Updated `axi4_throughput_ordering_longtail_throttled_write_test.sv`
Set the addressing mode for `max_outstanding_seq` based on bus matrix mode:
```systemverilog
if (is_enhanced_mode) begin
  max_outstanding_seq.use_bus_matrix_addressing = 2;  // 10x10 enhanced
end else if (is_4x4_ref_mode) begin
  max_outstanding_seq.use_bus_matrix_addressing = 1;  // 4x4 base
end else begin
  max_outstanding_seq.use_bus_matrix_addressing = 0;  // NONE mode
end
```

## Verification Results

All three modes now run with **0 UVM_ERROR**:

| Mode | Status | UVM_ERROR Count |
|------|--------|-----------------|
| NONE (no ref model, 4x4 topology) | ✓ PASS | 0 |
| BASE_BUS_MATRIX (4x4 with ref model) | ✓ PASS | 0 |
| ENHANCED (10x10 with ref model) | ✓ PASS | 0 |

## Files Modified
1. `/seq/master_sequences/axi4_master_max_outstanding_seq.sv`
2. `/test/axi4_throughput_ordering_longtail_throttled_write_test.sv`

The fix ensures that all sequences generate addresses appropriate for their configured bus matrix mode, preventing transaction mismatches in the scoreboard.