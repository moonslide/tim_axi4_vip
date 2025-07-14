`ifndef AXI4_TC_052_WLAST_TOO_LATE_TEST_INCLUDED_
`define AXI4_TC_052_WLAST_TOO_LATE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_052_wlast_too_late_test
// TC_052: Protocol WLAST Too Late Or Missing
// Master sends WLAST=0 when it should be WLAST=1 or continues with extra beats
// AWLEN=0x1 (2 beats) but WLAST=0 on beat 2, and potentially sends beat 3
//--------------------------------------------------------------------------------------------
class axi4_tc_052_wlast_too_late_test extends axi4_base_test;
  `uvm_component_utils(axi4_tc_052_wlast_too_late_test)

  axi4_virtual_tc_052_wlast_too_late_seq axi4_virtual_tc_052_seq_h;

  extern function new(string name = "axi4_tc_052_wlast_too_late_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_tc_052_wlast_too_late_test

function axi4_tc_052_wlast_too_late_test::new(string name = "axi4_tc_052_wlast_too_late_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_tc_052_wlast_too_late_test::build_phase(uvm_phase phase);
  // Set error_inject for protocol violation test - WLAST too late
  // Must set before super.build_phase so base test can retrieve it
  uvm_config_db#(bit)::set(this, "*", "error_inject", 1);
  `uvm_info(get_type_name(), "TC_052: error_inject enabled for WLAST too late protocol violation", UVM_LOW);
  
  super.build_phase(phase);
endfunction : build_phase

task axi4_tc_052_wlast_too_late_test::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  axi4_virtual_tc_052_seq_h = axi4_virtual_tc_052_wlast_too_late_seq::type_id::create("axi4_virtual_tc_052_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi4_tc_052_wlast_too_late_test"),UVM_LOW);
  axi4_virtual_tc_052_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  #10;
  phase.drop_objection(this);
endtask : run_phase

`endif