`ifndef AXI4_EXCLUSIVE_READ_SUCCESS_TEST_INCLUDED_
`define AXI4_EXCLUSIVE_READ_SUCCESS_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_exclusive_read_success_test
// EXCLUSIVE_READ_SUCCESS: Optional Exclusive Read Success
// Tests ARLOCK=1 (exclusive read access) - expects RRESP=EXOKAY if supported
// Sets up exclusive monitor for future exclusive write operations
//--------------------------------------------------------------------------------------------
class axi4_exclusive_read_success_test extends axi4_base_test;
  `uvm_component_utils(axi4_exclusive_read_success_test)

  axi4_virtual_exclusive_read_success_seq axi4_virtual_exclusive_read_success_seq_h;

  extern function new(string name = "axi4_exclusive_read_success_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_exclusive_read_success_test

function axi4_exclusive_read_success_test::new(string name = "axi4_exclusive_read_success_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_exclusive_read_success_test::build_phase(uvm_phase phase);
  // Set error_inject for read-only test to bypass write channel count checks
  // Must set before super.build_phase so base test can retrieve it
  uvm_config_db#(bit)::set(this, "*", "error_inject", 1);
  `uvm_info(get_type_name(), "EXCLUSIVE_READ_SUCCESS: error_inject enabled to bypass write channel checks for read-only test", UVM_LOW);
  
  super.build_phase(phase);
endfunction : build_phase

task axi4_exclusive_read_success_test::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  axi4_virtual_exclusive_read_success_seq_h = axi4_virtual_exclusive_read_success_seq::type_id::create("axi4_virtual_exclusive_read_success_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi4_exclusive_read_success_test"),UVM_LOW);
  axi4_virtual_exclusive_read_success_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  #10;
  phase.drop_objection(this);
endtask : run_phase

`endif