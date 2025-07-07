`ifndef AXI4_TC_047_WLAST_TOO_EARLY_TEST_INCLUDED_
`define AXI4_TC_047_WLAST_TOO_EARLY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_047_wlast_too_early_test
// TC_047: Protocol WLAST Too Early
// Master sends WLAST=1 before expected beat (protocol violation)
// AWLEN=0x3 (4 beats) but WLAST=1 on beat 2 instead of beat 4
//--------------------------------------------------------------------------------------------
class axi4_tc_047_wlast_too_early_test extends axi4_base_test;
  `uvm_component_utils(axi4_tc_047_wlast_too_early_test)

  axi4_virtual_tc_047_wlast_too_early_seq axi4_virtual_tc_047_seq_h;

  extern function new(string name = "axi4_tc_047_wlast_too_early_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_tc_047_wlast_too_early_test

function axi4_tc_047_wlast_too_early_test::new(string name = "axi4_tc_047_wlast_too_early_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_tc_047_wlast_too_early_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction : build_phase

task axi4_tc_047_wlast_too_early_test::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  axi4_virtual_tc_047_seq_h = axi4_virtual_tc_047_wlast_too_early_seq::type_id::create("axi4_virtual_tc_047_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi4_tc_047_wlast_too_early_test"),UVM_LOW);
  axi4_virtual_tc_047_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  #10;
  phase.drop_objection(this);
endtask : run_phase

`endif