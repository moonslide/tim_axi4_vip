# AXI4 VIP ID Mapping Strategy for Large Bus Matrices

## Problem Statement
- AXI4 protocol supports 16 unique transaction IDs (4-bit field)
- VIP enum defines AWID_0 to AWID_15 (16 values)
- Large bus matrices (e.g., 64x64) have more masters than available IDs
- Need efficient mapping of N masters to 16 IDs

## ID Mapping Strategies

### 1. Simple Modulo (Current Implementation)
```systemverilog
effective_id = master_id % 16;
```
- **Pros**: Simple, even distribution
- **Cons**: Masters 0, 16, 32, 48 all use ID 0 (may cause contention)

### 2. Hash-Based Distribution
```systemverilog
effective_id = (master_id * 7 + 3) % 16;  // Prime number hash
```
- **Pros**: Better distribution, reduces clustering
- **Cons**: Less predictable mapping

### 3. Tiered Mapping
```systemverilog
// Group masters by function
if (master_id < 16) 
    effective_id = master_id;        // Direct map first 16
else if (master_id < 32)
    effective_id = (master_id - 16) % 8;  // Next 16 use IDs 0-7
else
    effective_id = 8 + ((master_id - 32) % 8);  // Rest use IDs 8-15
```
- **Pros**: Prioritizes important masters, reduces contention
- **Cons**: More complex, requires master classification

### 4. Dynamic Load Balancing
```systemverilog
// Track ID usage and assign least-used ID
int id_usage[16];
effective_id = get_least_used_id(id_usage);
```
- **Pros**: Optimal distribution
- **Cons**: Runtime overhead, complexity

## Recommended Approach for 64x64

Use **configurable modulo** with **prime offset**:

```systemverilog
// In axi4_bus_config.svh
`ifdef BUS_MATRIX_64X64
  `define ID_MAP_BITS 16    // Use all 16 IDs
  `define ID_HASH_PRIME 7   // Prime for better distribution
`elsif BUS_MATRIX_10X10
  `define ID_MAP_BITS 10    // Use 10 IDs
  `define ID_HASH_PRIME 3
`else
  `define ID_MAP_BITS 4     // 4x4 uses only 4 IDs
  `define ID_HASH_PRIME 1
`endif

// Enhanced mapping with optional hash
`define GET_EFFECTIVE_ID_HASH(master_id) \
  (((master_id) * `ID_HASH_PRIME + (master_id % 3)) % `ID_MAP_BITS)
```

## Usage Examples

### 4x4 Configuration
- Masters 0-3 → IDs 0-3 (direct mapping)
- No ID sharing, optimal performance

### 10x10 Configuration  
- Masters 0-9 → IDs 0-9 (direct mapping)
- No ID sharing for first 10 masters

### 64x64 Configuration
- All 16 IDs utilized
- Each ID shared by 4 masters
- Hash distribution reduces contention

## Implementation Guidelines

1. **Always use configuration macros**, never hardcode ID values
2. **Test with different bus sizes** to verify scalability
3. **Monitor ID contention** in large configurations
4. **Consider master priority** when choosing mapping strategy
5. **Document ID mapping** in test logs for debugging

## Command Line Usage

```bash
# 4x4 (default)
./simv +UVM_TESTNAME=axi4_test

# 10x10
./simv +UVM_TESTNAME=axi4_test +define+BUS_MATRIX_10X10

# 64x64
./simv +UVM_TESTNAME=axi4_test +define+BUS_MATRIX_64X64
```