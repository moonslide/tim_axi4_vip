`ifndef AXI4_TEST_CONFIG_INCLUDED_
`define AXI4_TEST_CONFIG_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_test_config
// Global test configuration for dynamic bus matrix mode and interface configuration
//--------------------------------------------------------------------------------------------
class axi4_test_config extends uvm_object;
  `uvm_object_utils(axi4_test_config)

  // Bus matrix configuration
  axi4_bus_matrix_ref::bus_matrix_mode_e bus_matrix_mode;
  
  // Interface configuration  
  int num_masters;
  int num_slaves;
  
  // Test category for automatic configuration
  typedef enum {
    ENHANCED_MATRIX_TESTS,     // TC01-TC05, axi4_enhanced_bus_matrix_test: BUS_ENHANCED_MATRIX + 10M/10S
    BOUNDARY_ACCESS_TESTS,     // TC046-TC058: BASE_BUS_MATRIX + 4M/4S  
    DEFAULT_TESTS              // All others: NONE + 4M/4S
  } test_category_e;
  
  test_category_e test_category;
  
  extern function new(string name = "axi4_test_config");
  extern function void configure_for_test(string test_name);
  extern function void apply_category_config();
  extern function string get_config_summary();

  //------------------------------------------------------------------------
  // Self-binding API (codex_review.md Finding 2)
  //
  // configure_for_test() above classifies by TEST NAME. That is a heuristic:
  // a name it does not recognise lands in DEFAULT_TESTS => NONE / 4x4, with
  // no error, and the only thing that can rescue it is a +BUS_MATRIX_MODE
  // plusarg on the command line. For a test whose topology is fixed by the
  // DUT it was COMPILED against -- the Track-B NIC-400 fabrics burn their
  // port count and their address decode into RTL -- the name heuristic must
  // not be the source of truth, and a missing plusarg must not silently
  // change the map.
  //
  // Such a test instead:
  //   1. calls set_fixed_topology() and publishes the object to config_db
  //      BEFORE axi4_base_test::setup_test_configuration() runs (that
  //      function only derives a config when config_db has none), and
  //   2. calls check_bus_matrix_plusarg(), which turns a +BUS_MATRIX_MODE
  //      that disagrees with the compiled DUT into a UVM_FATAL instead of a
  //      silent re-map.
  //
  // Deliberately NOT done here: adding a ".*trackb.*" rule to
  // configure_for_test(). Both Track-B fabrics share that name stem
  // (axi4_trackb_smoke_test is 10x10, axi4_trackb_4x4_smoke_test is 4x4), so
  // a name regex could only ever be right for one of them. The compiled
  // fabric decides, and the test class states it.
  //------------------------------------------------------------------------
  extern function void set_fixed_topology(axi4_bus_matrix_ref::bus_matrix_mode_e mode,
                                          int    masters,
                                          int    slaves,
                                          string owner);
  extern function bit decode_bus_matrix_plusarg(input  string mode_str,
                                                output axi4_bus_matrix_ref::bus_matrix_mode_e mode,
                                                output int    masters,
                                                output int    slaves);
  extern function void check_bus_matrix_plusarg(string owner);

endclass : axi4_test_config

//--------------------------------------------------------------------------------------------
// Function: new
//--------------------------------------------------------------------------------------------
function axi4_test_config::new(string name = "axi4_test_config");
  super.new(name);
  
  // Default configuration (will be overridden by configure_for_test)
  test_category = DEFAULT_TESTS;
  bus_matrix_mode = axi4_bus_matrix_ref::NONE;
  num_masters = 4;
  num_slaves = 4;
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: configure_for_test
// Automatically configure based on test name
//--------------------------------------------------------------------------------------------
function void axi4_test_config::configure_for_test(string test_name);
  string lower_test_name;
  
  // Convert to lowercase for case-insensitive matching
  lower_test_name = test_name.tolower();
  
  // Enhanced matrix tests (TC01-TC05 + enhanced bus matrix test + QoS tests + concurrent tests + error injection tests)
  if (lower_test_name.match(".*tc.*00[1-5].*") || 
      lower_test_name.match(".*axi4_enhanced_bus_matrix_test.*") ||
      lower_test_name.match(".*concurrent.*") ||
      lower_test_name.match(".*sequential_mixed_ops.*") ||
      lower_test_name.match(".*exhaustive_random_reads.*") ||
      lower_test_name.match(".*qos.*") ||
      lower_test_name.match(".*user.*") ||
      lower_test_name.match(".*error_inject.*") ||
      lower_test_name.match(".*exception.*")) begin
    test_category = ENHANCED_MATRIX_TESTS;
    `uvm_info("TEST_CONFIG", $sformatf("Test %s categorized as ENHANCED_MATRIX_TESTS", test_name), UVM_MEDIUM)
  end
  
  // Boundary and access tests (TC046-TC058 + specific base matrix test)
  else if (lower_test_name.match(".*tc.*0[4-5][6-8].*") ||
           lower_test_name.match(".*tc.*04[6-9].*") ||
           lower_test_name.match(".*tc.*05[0-8].*") ||
           lower_test_name.match(".*boundary.*") ||
           lower_test_name.match(".*unaligned.*") ||
           lower_test_name.match(".*4k.*cross.*") ||
           lower_test_name.match(".*all_master_slave_access.*") ||
           lower_test_name.match(".*axi4_base_matrix_test.*")) begin
    test_category = BOUNDARY_ACCESS_TESTS;
    `uvm_info("TEST_CONFIG", $sformatf("Test %s categorized as BOUNDARY_ACCESS_TESTS", test_name), UVM_MEDIUM)
  end
  
  // Default tests (all others)
  else begin
    test_category = DEFAULT_TESTS;
    `uvm_info("TEST_CONFIG", $sformatf("Test %s categorized as DEFAULT_TESTS", test_name), UVM_MEDIUM)
  end
  
  // Apply configuration based on category
  apply_category_config();
endfunction : configure_for_test

//--------------------------------------------------------------------------------------------
// Function: apply_category_config
// Apply bus matrix mode and interface configuration based on test category
//--------------------------------------------------------------------------------------------
function void axi4_test_config::apply_category_config();
  // Set defaults based on test category
  case(test_category)
    ENHANCED_MATRIX_TESTS: begin
      bus_matrix_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
      num_masters = 10;
      num_slaves = 10;
    end
    
    BOUNDARY_ACCESS_TESTS: begin
      bus_matrix_mode = axi4_bus_matrix_ref::NONE;
      num_masters = 4;
      num_slaves = 4;
    end
    
    DEFAULT_TESTS: begin
      bus_matrix_mode = axi4_bus_matrix_ref::NONE;
      num_masters = 4;
      num_slaves = 4;
    end
  endcase
  
  // Note: Command line override is now handled in axi4_base_test::setup_test_configuration()
  // This ensures the override happens at the correct time in the build phase
  
  `uvm_info("TEST_CONFIG", get_config_summary(), UVM_MEDIUM)
endfunction : apply_category_config

//--------------------------------------------------------------------------------------------
// Function: get_config_summary
// Return a summary string of current configuration
//--------------------------------------------------------------------------------------------
function string axi4_test_config::get_config_summary();
  string summary;
  summary = $sformatf("Test Configuration: Category=%s, Bus_Matrix=%s, Masters=%0d, Slaves=%0d",
                     test_category.name(), bus_matrix_mode.name(), num_masters, num_slaves);
  return summary;
endfunction : get_config_summary

//--------------------------------------------------------------------------------------------
// Function: set_fixed_topology
// Bind a topology that comes from the compiled DUT rather than from the test name.
// test_category is intentionally left alone: it is a label for the name-based
// classifier only (apply_category_config() is NOT called from here), and no category
// spells "BASE_BUS_MATRIX with 4 agents", so setting one would only make
// get_config_summary() lie.
//--------------------------------------------------------------------------------------------
function void axi4_test_config::set_fixed_topology(axi4_bus_matrix_ref::bus_matrix_mode_e mode,
                                                   int    masters,
                                                   int    slaves,
                                                   string owner);
  bus_matrix_mode = mode;
  num_masters     = masters;
  num_slaves      = slaves;
  `uvm_info("TEST_CONFIG",
            $sformatf("%s bound a FIXED topology (not derived from the test name): %s",
                      owner, get_config_summary()), UVM_LOW)
endfunction : set_fixed_topology

//--------------------------------------------------------------------------------------------
// Function: decode_bus_matrix_plusarg
// Decode one +BUS_MATRIX_MODE=<str> spelling into (mode, masters, slaves).
// Returns 0 for an unrecognised spelling. The accepted spellings mirror the legacy
// override case in axi4_base_test::setup_test_configuration() -- that path still owns
// APPLYING the plusarg for tests that derive their config from their name; this
// function exists so a self-binding test can CHECK the plusarg against what it bound.
//--------------------------------------------------------------------------------------------
function bit axi4_test_config::decode_bus_matrix_plusarg(
    input  string mode_str,
    output axi4_bus_matrix_ref::bus_matrix_mode_e mode,
    output int    masters,
    output int    slaves);

  case (mode_str)
    "NONE", "1x1": begin
      mode = axi4_bus_matrix_ref::NONE;                masters = 1;  slaves = 1;
    end
    "SIMPLE", "2x2": begin
      mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;     masters = 2;  slaves = 2;
    end
    "BASE", "4x4": begin
      mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;     masters = 4;  slaves = 4;
    end
    "ENHANCED", "10x10": begin
      mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX; masters = 10; slaves = 10;
    end
    default: begin
      mode = bus_matrix_mode;  masters = num_masters;  slaves = num_slaves;
      return 0;
    end
  endcase
  return 1;
endfunction : decode_bus_matrix_plusarg

//--------------------------------------------------------------------------------------------
// Function: check_bus_matrix_plusarg
// Fail fast when the command line asks for a topology this test cannot honour.
// A self-binding test ignores +BUS_MATRIX_MODE by construction (axi4_base_test only
// applies the plusarg when IT creates the config). Silently ignoring it is how a run
// ends up measuring a topology nobody selected, so a contradiction -- or a spelling
// this project does not recognise -- is fatal here, at time 0, before any traffic.
//--------------------------------------------------------------------------------------------
function void axi4_test_config::check_bus_matrix_plusarg(string owner);
  string bus_mode_str;
  axi4_bus_matrix_ref::bus_matrix_mode_e want_mode;
  int    want_masters;
  int    want_slaves;

  if (!$value$plusargs("BUS_MATRIX_MODE=%s", bus_mode_str)) begin
    `uvm_info("TEST_CONFIG",
              $sformatf("%s: no +BUS_MATRIX_MODE on the command line; using the bound topology %s",
                        owner, get_config_summary()), UVM_LOW)
    return;
  end

  if (!decode_bus_matrix_plusarg(bus_mode_str, want_mode, want_masters, want_slaves)) begin
    `uvm_fatal("TEST_CONFIG",
      $sformatf({"+BUS_MATRIX_MODE=%s is not a spelling this project recognises (accepted: ",
                 "NONE|1x1, SIMPLE|2x2, BASE|4x4, ENHANCED|10x10). %s binds its own topology ",
                 "(%s), so an unrecognised value would have been ignored without a word -- ",
                 "which is exactly how a run ends up measuring a topology nobody chose."},
                bus_mode_str, owner, get_config_summary()))
  end
  else if ((want_mode    != bus_matrix_mode) ||
           (want_masters != num_masters)     ||
           (want_slaves  != num_slaves)) begin
    `uvm_fatal("TEST_CONFIG",
      $sformatf({"+BUS_MATRIX_MODE=%s asks for Bus_Matrix=%s, Masters=%0d, Slaves=%0d, but %s is ",
                 "bound to Bus_Matrix=%s, Masters=%0d, Slaves=%0d by the DUT it was compiled ",
                 "against. The bound topology wins and the plusarg would have been ignored; ",
                 "failing here instead of running against a reference model that does not match ",
                 "the fabric. Drop the plusarg, or run the test class that matches it."},
                bus_mode_str, want_mode.name(), want_masters, want_slaves,
                owner, bus_matrix_mode.name(), num_masters, num_slaves))
  end
  else begin
    `uvm_info("TEST_CONFIG",
              $sformatf("%s: +BUS_MATRIX_MODE=%s agrees with the bound topology %s",
                        owner, bus_mode_str, get_config_summary()), UVM_LOW)
  end
endfunction : check_bus_matrix_plusarg

`endif