`ifndef AXI4_TC_053_AWLEN_OUT_OF_SPEC_TEST_INCLUDED_
`define AXI4_TC_053_AWLEN_OUT_OF_SPEC_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_053_awlen_out_of_spec_test
// TC_053: Protocol AWLEN Out Of Spec
// Master sends AWLEN=0x100 (257 beats) which exceeds AXI4 specification limit of 256 beats
// Verifies Slave response to out-of-spec burst length
//--------------------------------------------------------------------------------------------
class axi4_tc_053_awlen_out_of_spec_test extends axi4_base_test;
  `uvm_component_utils(axi4_tc_053_awlen_out_of_spec_test)

  axi4_virtual_tc_053_awlen_out_of_spec_seq axi4_virtual_tc_053_seq_h;

  extern function new(string name = "axi4_tc_053_awlen_out_of_spec_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_tc_053_awlen_out_of_spec_test

function axi4_tc_053_awlen_out_of_spec_test::new(string name = "axi4_tc_053_awlen_out_of_spec_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_tc_053_awlen_out_of_spec_test::build_phase(uvm_phase phase);
  // Set error_inject for protocol violation test - AWLEN out of spec
  // Must be set BEFORE super.build_phase() so base test can retrieve it
  uvm_config_db#(bit)::set(this, "*", "error_inject", 1);
  `uvm_info(get_type_name(), "TC_053: error_inject enabled for AWLEN out of spec protocol violation", UVM_LOW);
  
  super.build_phase(phase);
endfunction : build_phase

task axi4_tc_053_awlen_out_of_spec_test::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  axi4_virtual_tc_053_seq_h = axi4_virtual_tc_053_awlen_out_of_spec_seq::type_id::create("axi4_virtual_tc_053_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi4_tc_053_awlen_out_of_spec_test"),UVM_LOW);
  axi4_virtual_tc_053_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  #10;
  phase.drop_objection(this);
endtask : run_phase

`endif