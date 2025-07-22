`ifndef AXI4_DEFINES_SVH_INCLUDED_
`define AXI4_DEFINES_SVH_INCLUDED_

//--------------------------------------------------------------------------------------------
// File: axi4_defines.svh
// Compile-time defines for configurable testbench parameters
//--------------------------------------------------------------------------------------------

// Interface configuration defines
// These can be overridden at compile time using +define+
`ifndef AXI4_NUM_MASTERS
  `define AXI4_NUM_MASTERS 10  // Default to 10x10 for maximum flexibility
`endif

`ifndef AXI4_NUM_SLAVES
  `define AXI4_NUM_SLAVES 10   // Default to 10x10 for maximum flexibility
`endif

// Bus matrix configuration modes
`define BUS_MATRIX_MODE_NONE     0
`define BUS_MATRIX_MODE_BASE     1
`define BUS_MATRIX_MODE_ENHANCED 2

// Test configuration modes for different test categories
`ifdef RUN_4X4_CONFIG
  // Override for 4x4 configuration (boundary tests, default tests)
  `undef AXI4_NUM_MASTERS
  `undef AXI4_NUM_SLAVES
  `define AXI4_NUM_MASTERS 4
  `define AXI4_NUM_SLAVES 4
`elsif RUN_10X10_CONFIG
  // Explicit 10x10 configuration (enhanced matrix tests)
  `undef AXI4_NUM_MASTERS
  `undef AXI4_NUM_SLAVES
  `define AXI4_NUM_MASTERS 10
  `define AXI4_NUM_SLAVES 10
`endif

`endif // AXI4_DEFINES_SVH_INCLUDED_