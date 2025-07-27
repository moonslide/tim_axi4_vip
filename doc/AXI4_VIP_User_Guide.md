# AXI4 Verification IP (VIP) User Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Bus Matrix Configurations](#bus-matrix-configurations)
4. [Recent Updates and Fixes](#recent-updates-and-fixes)
5. [Getting Started](#getting-started)
6. [Running Tests](#running-tests)
7. [Test Cases Overview](#test-cases-overview)
8. [ID Constraint Management](#id-constraint-management)
9. [Scalability Guidelines](#scalability-guidelines)
10. [Advanced Features](#advanced-features)
11. [Troubleshooting](#troubleshooting)
12. [Best Practices](#best-practices)

## Overview

The AXI4 Verification IP (VIP) is a comprehensive UVM-based verification solution for AXI4 protocol compliance testing. It supports multiple bus matrix configurations and provides extensive test coverage for AXI4 protocol features.

### Key Features
- Full AXI4 protocol support (IHI0022D specification)
- Scalable bus matrix sizes (4x4, 10x10, 64x64, and beyond)
- Master and slave agents with monitors and drivers
- Protocol violation detection
- Comprehensive test suite (113+ test cases)
- Coverage collection and reporting
- LSF support for parallel regression runs
- Scalable ID mapping for any configuration

## Architecture

### Directory Structure
```
tim_axi4_vip/
├── agent/           # Master and slave agent BFMs
├── master/          # Master agent components
├── slave/           # Slave agent components
├── seq/             # Test sequences
├── test/            # Test cases
├── env/             # Verification environment
├── top/             # Testbench top modules
├── doc/             # Documentation
└── sim/             # Simulation directories
```

### Key Components
- **Master Agent**: Generates AXI4 transactions
- **Slave Agent**: Responds to AXI4 transactions
- **Scoreboard**: Checks transaction correctness
- **Coverage**: Collects functional coverage
- **Bus Matrix**: Configurable interconnect model

## Bus Matrix Configurations

### Supported Configurations
1. **BASE_BUS_MATRIX (4x4)**
   - 4 Masters × 4 Slaves
   - AWID/ARID range: 0-3
   - Default configuration

2. **ENHANCED_BUS_MATRIX (10x10)**
   - 10 Masters × 10 Slaves
   - AWID/ARID range: 0-9
   - Extended configuration

3. **Custom Configurations (up to 64x64 and beyond)**
   - Configurable via `axi4_bus_config.svh`
   - Scalable ID mapping using modulo operation
   - Supports any NxM matrix configuration

### Master-Slave Access Permissions (4x4 Example)
```
M0 (CPU_Core_A):    S0(R/W), S2(R/W), S3(R)
M1 (CPU_Core_B):    S0(R/W), S2(R/W)
M2 (DMA_Controller): S0(R/W), S2(R/W)
M3 (GPU):           S0(R/W), S3(R)
```

## Recent Updates and Fixes

### Scalable ID Mapping Implementation (July 2025)
Implemented a comprehensive scalable ID mapping solution that supports bus matrices from 4x4 to 64x64 and beyond:

1. **Created `axi4_bus_config.svh`**
   - Centralized configuration header
   - Scalable ID mapping macros
   - Support for any bus matrix size

2. **ID Mapping Macros**
   ```systemverilog
   `define GET_EFFECTIVE_AWID(master_id) ((master_id) % `ID_MAP_BITS)
   `define GET_AWID_ENUM(id_val) \
     ((id_val % 16) == 0  ? AWID_0  : \
      (id_val % 16) == 1  ? AWID_1  : \
      // ... maps to AWID_0 through AWID_15
   ```

3. **Updated All Test Sequences**
   - TC001-TC005: Protocol compliance tests
   - TC046-TC058: ID-specific protocol tests
   - All sequences now use scalable macros

4. **Key Changes**
   - Before: `req.awid == (master_id * 4)` (hardcoded)
   - After: `req.awid == `GET_AWID_ENUM(`GET_EFFECTIVE_AWID(master_id))`

### Results
- Regression pass rate: 100% (113/113 tests)
- Support for 4x4, 10x10, 64x64 configurations
- No hardcoded ID constraints

## Getting Started

### Prerequisites
- Synopsys VCS 2024.09 or later
- UVM 1.2
- Python 3.6+ (for regression scripts)
- LSF (optional, for distributed runs)

### Quick Start

1. **Clone the Repository**
   ```bash
   git clone <repository_url>
   cd tim_axi4_vip
   ```

2. **Set Up Environment**
   ```bash
   source setup_env.sh  # Sets VCS_HOME, UVM_HOME
   cd sim/synopsys_sim
   ```

3. **Run a Simple Test**
   ```bash
   make TEST=axi4_write_read_test
   ```

4. **Run Full Regression**
   ```bash
   python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --cov
   ```

### Changing Bus Matrix Configuration

1. Edit `include/axi4_bus_config.svh`
2. Set desired `NUM_MASTERS`, `NUM_SLAVES`, and `ID_MAP_BITS`
3. Recompile and run tests

## Running Tests

### Single Test Execution
```bash
# Compile and run a single test
make compile
./simv +UVM_TESTNAME=axi4_write_read_test
```

### Regression Execution
```bash
# Run full regression with coverage
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --cov --lsf

# Run without LSF (local execution)
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --cov
```

### Command Line Options
- `--test-list`: Specify test list file
- `--cov`: Enable coverage collection
- `--lsf`: Use LSF for parallel execution
- `--parallel-workers N`: Number of parallel jobs (default: 1)
- `--timeout S`: Test timeout in seconds (default: 600)

## Test Cases Overview

### Basic Transfer Tests
- Write/Read tests (8b, 16b, 32b, 64b)
- Blocking and non-blocking transfers
- Burst types (INCR, WRAP, FIXED)

### Protocol Tests (TC046-TC058)
- **TC046**: Multiple writes with same AWID (in-order completion)
- **TC047**: Multiple writes with different AWID (out-of-order allowed)
- **TC048**: Multiple reads with same ARID (in-order completion)
- **TC049**: Multiple reads with different ARID (out-of-order allowed)
- **TC050**: WID-AWID mismatch detection
- **TC051**: WLAST too early violation
- **TC052**: WLAST too late violation
- **TC053**: AWLEN out of spec violation
- **TC054**: ARLEN out of spec violation
- **TC055**: Exclusive write success
- **TC056**: Exclusive write fail
- **TC057**: Exclusive read success
- **TC058**: Exclusive read fail

### Boundary Tests
- Lower boundary read/write
- Upper boundary read/write
- 4K boundary crossing

### Error Tests
- Slave error responses
- Access permission violations
- Protocol violations

## ID Constraint Management

### Current Scalable Implementation

#### Configuration Header (`include/axi4_bus_config.svh`)
```systemverilog
// Bus matrix size configuration
`define NUM_MASTERS 4      // Can be 4, 10, 64, etc.
`define NUM_SLAVES 4       // Can be 4, 10, 64, etc.
`define ID_MAP_BITS 4      // Number of ID bits to use

// Scalable ID mapping macros
`define GET_EFFECTIVE_AWID(master_id) ((master_id) % `ID_MAP_BITS)
`define GET_EFFECTIVE_ARID(master_id) ((master_id) % `ID_MAP_BITS)

// Convert to enum (supports up to 16 unique IDs)
`define GET_AWID_ENUM(id_val) \
  ((id_val % 16) == 0  ? AWID_0  : \
   (id_val % 16) == 1  ? AWID_1  : \
   // ... continues for all 16 values
   AWID_0)
```

#### Usage in Sequences
```systemverilog
`include "axi4_bus_config.svh"

class my_seq extends axi4_master_base_seq;
  task body();
    start_item(req);
    assert(req.randomize() with {
      tx_type == WRITE;
      // Scalable ID assignment
      awid == `GET_AWID_ENUM(`GET_EFFECTIVE_AWID(master_id));
      // Other constraints...
    });
    finish_item(req);
  endtask
endclass
```

### Benefits of Current Approach
1. **Zero Code Changes** for different bus sizes
2. **Compile-time Optimization** using macros
3. **Clear ID Mapping** visible in code
4. **Backward Compatible** with existing tests

## Scalability Guidelines

### Configuring Different Bus Matrix Sizes

#### 1. Update Configuration Header
Edit `include/axi4_bus_config.svh`:

```systemverilog
// For 10x10 bus matrix
`define NUM_MASTERS 10
`define NUM_SLAVES 10
`define ID_MAP_BITS 16

// For 64x64 bus matrix
`define NUM_MASTERS 64
`define NUM_SLAVES 64
`define ID_MAP_BITS 64
```

#### 2. ID Mapping Strategy for Large Matrices

For matrices larger than 16x16, the VIP uses modulo mapping:

| Bus Size | Masters | ID Bits | Mapping Strategy |
|----------|---------|---------|------------------|
| 4x4      | 4       | 4       | Direct (0-3)     |
| 10x10    | 10      | 16      | Direct (0-9)     |
| 64x64    | 64      | 64      | Modulo 16        |

Example for 64 masters:
- Master 0 → AWID_0
- Master 16 → AWID_0 (16 % 16 = 0)
- Master 17 → AWID_1 (17 % 16 = 1)

#### 3. Test Adaptation

All tests automatically adapt to the configured bus size:

```systemverilog
// TC047 example - works for any bus size
int base_id = `GET_EFFECTIVE_AWID(master_id);
int num_ids = `ID_MAP_BITS;

for (int i = 0; i < num_writes; i++) begin
  int awid_offset = (base_id + i) % num_ids;
  awid_val = `GET_AWID_ENUM(awid_offset);
end
```

### Runtime Configuration (Future Enhancement)

Planned support for runtime configuration:
```bash
# Override compile-time settings
./simv +UVM_TESTNAME=my_test +NUM_MASTERS=32 +NUM_SLAVES=32
```

## Troubleshooting

### Common Issues

1. **Master ID Mismatch Errors**
   - Cause: AWID/ARID values outside valid range
   - Fix: Ensure IDs are within 0 to (num_masters-1)

2. **Response Mismatch (SLVERR)**
   - Cause: Invalid master accessing restricted slave
   - Fix: Check master-slave access permissions

3. **Protocol Violations**
   - Cause: Invalid burst length, size, or type
   - Fix: Review AXI4 specification constraints

### Debug Tips
1. Check regression logs in `regression_result_*/logs/no_pass_logs/`
2. Look for UVM_ERROR messages
3. Verify bus matrix configuration matches test assumptions
4. Use waveform debugging for protocol issues

### Log File Locations
- Pass logs: `regression_result_*/logs/pass_logs/`
- Fail logs: `regression_result_*/logs/no_pass_logs/`
- Coverage reports: `regression_result_*/coverage_collect/`

## Advanced Features

### Protocol Violation Detection

The VIP automatically detects and reports protocol violations:
- WLAST timing violations
- ID mismatches
- Burst length violations
- Exclusive access violations

### Performance Monitoring

Built-in performance metrics:
- Transaction latency
- Outstanding transaction tracking
- Bandwidth utilization
- Bus utilization statistics

### Coverage Collection

Comprehensive coverage points:
- Transaction types and sizes
- Burst types and lengths
- Address alignment patterns
- Response types
- ID usage patterns
- Error scenarios

## Best Practices

### 1. Always Include Bus Config Header
```systemverilog
`include "axi4_bus_config.svh"  // At the top of every sequence file
```

### 2. Use Scalable ID Macros
```systemverilog
// Good - scales automatically
awid == `GET_AWID_ENUM(`GET_EFFECTIVE_AWID(master_id));

// Bad - hardcoded values
awid == AWID_2;
```

### 3. Test with Multiple Configurations
```bash
# Test with different bus sizes during development
for size in 4 10 64; do
  # Update config and run tests
  echo "Testing ${size}x${size} configuration"
done
```

### 4. Check Regression Results
```bash
# Always check both summary and detailed logs
cat regression_result_*/regression_summary.txt
grep UVM_ERROR regression_result_*/logs/no_pass_logs/*.log
```

### 5. Document Configuration Dependencies
```systemverilog
// Document any assumptions about bus size
// This test assumes at least 4 masters
`ifdef NUM_MASTERS
  `assert(NUM_MASTERS >= 4)
`endif
```

## Future Enhancements

1. **Runtime Configuration Support**
   - Plusarg-based configuration override
   - Dynamic test adaptation
   - Configuration validation framework

2. **Enhanced ID Mapping Strategies**
   - Hash-based distribution
   - Priority-aware mapping
   - QoS-based ID allocation

3. **Extended Protocol Support**
   - AXI5 features
   - Cache coherency extensions
   - Atomic operations

4. **Advanced Debug Features**
   - Transaction visualization
   - Protocol state machines
   - Performance bottleneck analysis

## References

- IHI0022D AMBA AXI Protocol Specification
- UVM 1.2 Reference Manual
- Internal VIP Architecture Document
- ID Mapping Strategy Document (`doc/ID_Mapping_Strategy.md`)

---

**Version**: 2.0  
**Date**: July 26, 2025  
**Authors**: AXI4 VIP Development Team
**Major Update**: Scalable Bus Matrix Support