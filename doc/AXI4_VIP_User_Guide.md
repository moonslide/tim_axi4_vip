# AXI4 Verification IP (VIP) User Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Bus Matrix Configurations](#bus-matrix-configurations)
4. [Recent Updates and Fixes](#recent-updates-and-fixes)
5. [Running Tests](#running-tests)
6. [Test Cases Overview](#test-cases-overview)
7. [ID Constraint Management](#id-constraint-management)
8. [Scalability Guidelines](#scalability-guidelines)
9. [Troubleshooting](#troubleshooting)

## Overview

The AXI4 Verification IP (VIP) is a comprehensive UVM-based verification solution for AXI4 protocol compliance testing. It supports multiple bus matrix configurations and provides extensive test coverage for AXI4 protocol features.

### Key Features
- Full AXI4 protocol support (IHI0022D specification)
- Configurable bus matrix sizes (4x4, 10x10, up to 64x64)
- Master and slave agents with monitors and drivers
- Protocol violation detection
- Comprehensive test suite (113+ test cases)
- Coverage collection and reporting
- LSF support for regression runs

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

3. **Custom Configurations (up to 64x64)**
   - Configurable via runtime parameters
   - AWID/ARID range: 0-(N-1) for N×N matrix

### Master-Slave Access Permissions (4x4 Example)
```
M0 (CPU_Core_A):    S0(R/W), S2(R/W), S3(R)
M1 (CPU_Core_B):    S0(R/W), S2(R/W)
M2 (DMA_Controller): S0(R/W), S2(R/W)
M3 (GPU):           S0(R/W), S3(R)
```

## Recent Updates and Fixes

### ID Constraint Fixes (July 2025)
Fixed critical issues with AWID/ARID constraints for 4x4 bus matrix configuration:

1. **TC046**: Fixed ARID calculation
   - Before: `req.arid == (master_id * 4)`
   - After: `req.arid == master_id`

2. **TC047**: Fixed maximum AWID range test
   - Before: `awid_val = 15 - i` (invalid for 4x4)
   - After: `awid_val = (3 - i) % 4`

3. **TC048**: Fixed ARID usage
   - Before: `req.arid = ARID_14` (invalid)
   - After: `req.arid = ARID_2`

4. **TC057**: Fixed exclusive read ARID
   - Before: `req.arid == ARID_14`
   - After: `req.arid == ARID_2`

5. **TC058**: Fixed exclusive read fail ARID
   - Before: `req.arid == ARID_15`
   - After: `req.arid == ARID_3`

### Results
- Regression pass rate improved from 91.2% to 100%
- All 113 tests now pass for 4x4 configuration

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

### Current Implementation (4x4 Configuration)
```systemverilog
// In axi4_master_tx.sv
constraint awid_c1 { 
  awid inside {[AWID_0:AWID_15]};  // Enum allows 0-15
}

// In test sequences - must further constrain
req.awid == master_id;  // Valid range 0-3 for 4x4
```

### Scalable Approach (Recommended)
```systemverilog
// Configuration class
class axi4_bus_config extends uvm_object;
  int num_masters = 4;
  int num_slaves = 4;
  
  function int get_max_awid();
    return num_masters - 1;
  endfunction
endclass

// Dynamic constraint
constraint awid_c1 { 
  bus_cfg != null -> awid inside {[0:bus_cfg.get_max_awid()]};
}
```

## Scalability Guidelines

### Making Tests Configuration-Aware

1. **Get Configuration in Test**
```systemverilog
axi4_bus_config bus_cfg;
if (!uvm_config_db#(axi4_bus_config)::get(null, "", "bus_cfg", bus_cfg)) begin
  bus_cfg = axi4_bus_config::type_id::create("default_cfg");
end
```

2. **Use Configuration for ID Generation**
```systemverilog
// Instead of hardcoded values
req.awid == master_id % bus_cfg.num_masters;

// For different ID patterns
awid_val = (bus_cfg.get_max_awid() - i) % bus_cfg.num_masters;
```

3. **Runtime Configuration**
```bash
# Run with 64x64 bus matrix
./simv +UVM_TESTNAME=tc_046 +BUS_MATRIX_SIZE=64
```

### Benefits
- Single codebase for all configurations
- No hardcoded ID values
- Runtime flexibility
- Clear configuration intent
- Easier maintenance

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

## Future Enhancements

1. **Parameterized VIP Package**
   - Compile-time configuration options
   - Optimized for specific bus sizes

2. **Enhanced Scalability**
   - Automatic test adaptation
   - Configuration validation
   - Dynamic constraint generation

3. **Advanced Features**
   - QoS testing improvements
   - Cache coherency tests
   - Security feature verification

## References

- IHI0022D AMBA AXI Protocol Specification
- UVM 1.2 Reference Manual
- Internal VIP Architecture Document

---

**Version**: 1.0  
**Date**: July 25, 2025  
**Authors**: AXI4 VIP Development Team