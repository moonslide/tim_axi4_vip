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

`endif