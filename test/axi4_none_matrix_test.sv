`ifndef AXI4_NONE_MATRIX_TEST_INCLUDED_
`define AXI4_NONE_MATRIX_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_none_matrix_test
// Example test using NONE bus matrix mode for tests that don't need reference model
//--------------------------------------------------------------------------------------------
class axi4_none_matrix_test extends axi4_base_test;
  `uvm_component_utils(axi4_none_matrix_test)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_none_matrix_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void setup_axi4_env_cfg();

endclass : axi4_none_matrix_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_none_matrix_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_none_matrix_test::new(string name = "axi4_none_matrix_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates the required ports
//
// Parameters:
//  phase - stores the current phase
//--------------------------------------------------------------------------------------------
function void axi4_none_matrix_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_env_cfg
// Setup the axi4_env_cfg with NONE bus matrix mode
//--------------------------------------------------------------------------------------------
function void axi4_none_matrix_test::setup_axi4_env_cfg();
  axi4_env_cfg_h = axi4_env_config::type_id::create("axi4_env_cfg_h");
  
  // Configure for NONE bus matrix mode - no reference model
  axi4_env_cfg_h.no_of_masters = 10;  // Can still use all 10 masters
  axi4_env_cfg_h.no_of_slaves = 10;   // Can still use all 10 slaves
  axi4_env_cfg_h.bus_matrix_mode = axi4_bus_matrix_ref::NONE;
  
  // Enable other features
  axi4_env_cfg_h.has_scoreboard = 1;
  axi4_env_cfg_h.has_virtual_seqr = 1;
  axi4_env_cfg_h.axprot_chk_cfg = 1;
  axi4_env_cfg_h.axcache_chk_cfg = 1;
  
  `uvm_info(get_type_name(), "Configured environment for NONE bus matrix mode - no reference model", UVM_MEDIUM)
endfunction : setup_axi4_env_cfg

`endif