# AXI4 Verification IP User Guide
Version 2.0 - July 2025

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Architecture Overview](#architecture-overview)
4. [Configuration Guide](#configuration-guide)
5. [Running Tests](#running-tests)
6. [Test Development](#test-development)
7. [Scalability Features](#scalability-features)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

## Introduction

The AXI4 Verification IP (VIP) is a comprehensive UVM-based verification solution for AXI4 protocol compliance testing. It supports scalable bus matrix configurations from 4x4 to 64x64 and beyond.

### Key Features

- **Scalable Architecture**: Supports any bus matrix size without code changes
- **Comprehensive Coverage**: 113+ test cases covering all protocol aspects
- **Full Protocol Support**: IHI0022D specification compliant
- **Performance Optimized**: Parallel test execution with LSF support
- **Advanced Features**: QoS, exclusive access, protocol violation detection

### Supported Configurations

| Feature | Specification |
|---------|--------------|
| Protocol Version | AXI4 (IHI0022D) |
| Data Width | 8, 16, 32, 64, 128, 256, 512, 1024 bits |
| Address Width | Up to 64 bits |
| Burst Types | FIXED, INCR, WRAP |
| Bus Matrix | 4x4 to 64x64 and beyond |

## Getting Started

### System Requirements

- **OS**: Linux (RHEL 7+, Ubuntu 18.04+, CentOS 7+)
- **Simulator**: Synopsys VCS 2024.09 or later
- **UVM**: Version 1.2
- **Memory**: 16GB minimum (32GB recommended)
- **Python**: 3.6 or later

### Installation

```bash
# Clone repository
git clone https://github.com/your-org/axi4_vip.git
cd axi4_vip

# Set up environment
source setup_env.sh

# Navigate to simulation directory
cd sim/synopsys_sim
```

### Quick Test

```bash
# Run simple test
make TEST=axi4_write_read_test

# Check results
grep "TEST PASSED" axi4_write_read_test.log
```

## Configuration Guide

### Bus Matrix Configuration

Edit `include/axi4_bus_config.svh`:

```systemverilog
// Configure bus size
`define NUM_MASTERS 4      // Number of masters
`define NUM_SLAVES 4       // Number of slaves
`define ID_MAP_BITS 4      // ID width

// ID mapping macros (automatic)
`define GET_EFFECTIVE_AWID(master_id) ((master_id) % `ID_MAP_BITS)
```

### Configuration Examples

| Configuration | Masters | Slaves | Use Case |
|--------------|---------|---------|----------|
| BASE_BUS_MATRIX | 4 | 4 | IoT, Small SoCs |
| ENHANCED_BUS_MATRIX | 10 | 10 | Medium SoCs |
| LARGE_BUS_MATRIX | 64 | 64 | Data Centers |

## Running Tests

### Single Test

```bash
# Basic run
make TEST=axi4_write_read_test

# With waveforms
make TEST=axi4_write_read_test WAVES=1

# With seed
make TEST=axi4_write_read_test SEED=12345
```

### Regression Testing

```bash
# Local regression
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list

# With coverage
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --cov

# Using LSF (parallel)
python3 axi4_regression_makefile.py --test-list axi4_transfers_regression.list --lsf --parallel 10
```

## Test Development

### Creating New Test

```systemverilog
`include "axi4_bus_config.svh"

class my_test extends axi4_base_test;
  `uvm_component_utils(my_test)
  
  task run_phase(uvm_phase phase);
    my_seq seq;
    seq = my_seq::type_id::create("seq");
    seq.start(env.master[0].sequencer);
  endtask
endclass
```

### Using Scalable IDs

```systemverilog
class my_seq extends axi4_master_base_seq;
  task body();
    start_item(req);
    assert(req.randomize() with {
      tx_type == WRITE;
      // Scalable ID - works for any bus size
      awid == `GET_AWID_ENUM(`GET_EFFECTIVE_AWID(master_id));
      awaddr inside {[START_ADDR:END_ADDR]};
    });
    finish_item(req);
  endtask
endclass
```

## Best Practices

1. **Always use scalable ID macros** - Never hardcode ID values
2. **Include bus config header** - Add to all sequence files
3. **Test multiple configurations** - Verify with different bus sizes
4. **Check regression results** - Review logs for failures
5. **Document test intent** - Add clear comments

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| ID mismatch errors | Check ID is within valid range |
| SLVERR responses | Verify access permissions |
| Compilation errors | Include axi4_bus_config.svh |
| Test timeouts | Check for sequence deadlocks |

### Debug Options

```bash
+UVM_VERBOSITY=UVM_HIGH
+UVM_PHASE_TRACE
+UVM_OBJECTION_TRACE
```

---
**Support**: axi4_vip_support@company.com  
**Version**: 2.0 (July 2025)
