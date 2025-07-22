# AXI4 VIP Interface Configuration Strategy

## Overview

The AXI4 VIP testbench supports dynamic interface configuration to handle different test scenarios efficiently without requiring recompilation.

## Design Approach

### HDL Layer (hdl_top.sv)
- **Always creates 10 master and 10 slave interfaces**
- Fixed at compile time using `NO_OF_MASTERS` and `NO_OF_SLAVES` parameters
- This provides maximum flexibility without recompilation

### HVL Layer (UVM Environment)
- **Dynamically creates only the required number of agents**
- Based on test configuration:
  - Enhanced matrix tests: 10 masters, 10 slaves
  - Boundary/base tests: 4 masters, 4 slaves  
  - Default tests: 4 masters, 4 slaves

## Configuration Flow

1. **Test instantiation** → `axi4_base_test::build_phase()`
2. **Test configuration** → `axi4_test_config` determines test category
3. **Environment setup** → Creates only required agents (4 or 10)
4. **Interface mapping** → Agents connect to interfaces 0-3 or 0-9

## Test Categories

### Enhanced Matrix Tests (10x10)
- TC001-TC005
- axi4_enhanced_bus_matrix_test
- Uses all 10 master/slave interfaces

### Boundary Access Tests (4x4)
- TC046-TC058
- All boundary tests
- axi4_base_matrix_test
- Uses interfaces 0-3 only

### Default Tests (4x4)
- All other tests
- Uses interfaces 0-3 only

## Benefits

1. **No recompilation** between different test configurations
2. **Optimal resource usage** - only active agents are created
3. **Transparent to tests** - existing tests work without modification
4. **Scalable** - easy to add new configurations

## Implementation Details

### Key Files
- `axi4_test_config.sv` - Dynamic test categorization
- `axi4_base_test.sv` - Configures environment based on test type
- `hdl_top.sv` - Creates all 10x10 interfaces
- `axi4_env.sv` - Creates only required agents

### Unused Interfaces
- Interfaces not used by a test remain unconnected
- No simulation overhead for unused interfaces
- HDL generate blocks still create all BFMs for consistency

## Future Enhancements

If compile-time configuration is needed:
1. Use defines in `axi4_defines.svh`
2. Pass `+define+RUN_4X4_CONFIG` or `+define+RUN_10X10_CONFIG`
3. Rebuild with specific configuration

Currently, the dynamic approach is preferred for faster test execution without recompilation.