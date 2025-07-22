`ifndef AXI4_TEST_DEFINES_SVH_INCLUDED_
`define AXI4_TEST_DEFINES_SVH_INCLUDED_

//--------------------------------------------------------------------------------------------
// File: axi4_test_defines.svh
// Test-specific compile-time configuration defines
//--------------------------------------------------------------------------------------------

// Default test timeout - can be overridden per test
`ifndef DEFAULT_TEST_TIMEOUT
  `define DEFAULT_TEST_TIMEOUT 10ms
`endif

// Test category specific timeouts
`define ENHANCED_MATRIX_TEST_TIMEOUT 20ms
`define BOUNDARY_TEST_TIMEOUT 15ms
`define DEFAULT_TEST_TIMEOUT_VALUE 10ms

// Debug and logging defines
`ifdef VERBOSE_DEBUG
  `define TEST_DEBUG_LEVEL UVM_HIGH
`else
  `define TEST_DEBUG_LEVEL UVM_MEDIUM
`endif

// Coverage and checking enables
`ifndef DISABLE_PROTOCOL_CHECKS
  `define ENABLE_PROTOCOL_CHECKS
`endif

`ifndef DISABLE_COVERAGE
  `define ENABLE_COVERAGE
`endif

// Scoreboard configuration
`ifndef DISABLE_SCOREBOARD
  `define ENABLE_SCOREBOARD
`endif

// Waveform dumping configuration
`ifdef DUMP_WAVES
  `ifndef DUMP_FSDB
    `define DUMP_VCD
  `endif
`endif

`endif // AXI4_TEST_DEFINES_SVH_INCLUDED_