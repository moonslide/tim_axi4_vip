`ifndef AXI4_READ_TEST_INCLUDED_
`define AXI4_READ_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_read_test
// Extends the base test and starts the virtual sequence of 8 bit
//--------------------------------------------------------------------------------------------
class axi4_read_test extends axi4_base_test;
  `uvm_component_utils(axi4_read_test)

  //Variable : axi4_virtual_read_seq_h
  //Instatiation of axi4_virtual_read_seq
  axi4_virtual_read_seq axi4_virtual_read_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_read_test", uvm_component parent = null);
  extern virtual function void setup_axi4_env_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_read_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_read_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_read_test::new(string name = "axi4_read_test",
                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_env_cfg
// Configure environment for read-only test
//--------------------------------------------------------------------------------------------
function void axi4_read_test::setup_axi4_env_cfg();
  super.setup_axi4_env_cfg();
  axi4_env_cfg_h.write_read_mode_h = ONLY_READ_DATA;
  
  // For read test, slaves must remain ACTIVE to provide read responses
  // The ONLY_READ_DATA mode will prevent write channel comparisons in scoreboard
  `uvm_info(get_type_name(), "Configured for ONLY_READ_DATA mode", UVM_MEDIUM)
endfunction : setup_axi4_env_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates the axi4_virtual_read_seq sequence  and starts the read virtual sequences
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_read_test::run_phase(uvm_phase phase);

  axi4_virtual_read_seq_h =axi4_virtual_read_seq::type_id::create("axi4_virtual_read_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi4_read_test"),UVM_LOW);
  phase.raise_objection(this);
  axi4_virtual_read_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);

endtask : run_phase
`endif

