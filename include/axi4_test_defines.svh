`ifndef AXI4_TEST_DEFINES_INCLUDED_
`define AXI4_TEST_DEFINES_INCLUDED_

//--------------------------------------------------------------------------------------------
// AXI4 Test Configuration Defines
// This file contains configurable parameters for AXI4 testbench
//--------------------------------------------------------------------------------------------

// Test timeout configuration
// DEFAULT_TEST_TIMEOUT: Default timeout value for tests
// Usage: Can be overridden at compile time with +define+DEFAULT_TEST_TIMEOUT=<value>
// Example: +define+DEFAULT_TEST_TIMEOUT=5ms
`ifndef DEFAULT_TEST_TIMEOUT
  `define DEFAULT_TEST_TIMEOUT 10s
`endif

// Other test configuration defines can be added here
// Example:
// `ifndef MAX_OUTSTANDING_TRANSACTIONS
//   `define MAX_OUTSTANDING_TRANSACTIONS 16
// `endif

`endif