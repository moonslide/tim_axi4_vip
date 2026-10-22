`ifndef AXI4_NON_BLOCKING_WRITE_READ_TEST_INCLUDED_
`define AXI4_NON_BLOCKING_WRITE_READ_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_non_blocking_write_read_test
// Extends the base test and starts the virtual sequenceof write
//--------------------------------------------------------------------------------------------
class axi4_non_blocking_write_read_test extends axi4_base_test;
  `uvm_component_utils(axi4_non_blocking_write_read_test)

  //Variable : axi4_virtual_nbk_write_read_seq_h
  //Instatiation of axi4_virtual_nbk_write_read_seq
  axi4_virtual_nbk_write_read_seq axi4_virtual_nbk_write_read_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_non_blocking_write_read_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_non_blocking_write_read_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_non_blocking_write_read_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_non_blocking_write_read_test::new(string name = "axi4_non_blocking_write_read_test",
                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Outside NONE, constrain master 0 to its legal address window (axi4_legal_addr_window).
// NONE registers nothing, so the NONE run is unchanged.
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_non_blocking_write_read_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (axi4_env_cfg_h.bus_matrix_mode != axi4_bus_matrix_ref::NONE)
    axi4_master_tx_legal_window::enable(axi4_env_cfg_h.bus_matrix_mode, 0);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates the axi4_virtual_write_read_seq sequence and starts the write virtual sequences
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_non_blocking_write_read_test::run_phase(uvm_phase phase);

  axi4_virtual_nbk_write_read_seq_h=axi4_virtual_nbk_write_read_seq::type_id::create("axi4_virtual_nbk_write_read_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi4_non_blocking_write_read_test"),UVM_LOW);
  phase.raise_objection(this);
  axi4_virtual_nbk_write_read_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);

endtask : run_phase

`endif

