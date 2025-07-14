`ifndef AXI4_TC_050_WID_AWID_MISMATCH_TEST_INCLUDED_
`define AXI4_TC_050_WID_AWID_MISMATCH_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_050_wid_awid_mismatch_test  
// TC_050: WID AWID Mismatch Violation
// Master sends AWID=0xC but WID=0xD (protocol violation)
// Verifies Slave response to WID/AWID mismatch
//--------------------------------------------------------------------------------------------
class axi4_tc_050_wid_awid_mismatch_test extends axi4_base_test;
  `uvm_component_utils(axi4_tc_050_wid_awid_mismatch_test)

  axi4_virtual_tc_050_wid_awid_mismatch_seq axi4_virtual_tc_050_seq_h;

  extern function new(string name = "axi4_tc_050_wid_awid_mismatch_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_tc_050_wid_awid_mismatch_test

function axi4_tc_050_wid_awid_mismatch_test::new(string name = "axi4_tc_050_wid_awid_mismatch_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_tc_050_wid_awid_mismatch_test::build_phase(uvm_phase phase);
  // Set error_inject for protocol violation test - disable scoreboard count checks
  // Since this test intentionally creates WID/AWID mismatch conditions
  // Must set before super.build_phase so base test can retrieve it
  uvm_config_db#(bit)::set(this, "*", "error_inject", 1);
  `uvm_info(get_type_name(), "TC_050: error_inject enabled for protocol violation test", UVM_LOW);
  
  super.build_phase(phase);
endfunction : build_phase

task axi4_tc_050_wid_awid_mismatch_test::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  
  // Set drain time to ensure all transactions complete before test ends
  phase.phase_done.set_drain_time(this, 1000);
  
  axi4_virtual_tc_050_seq_h = axi4_virtual_tc_050_wid_awid_mismatch_seq::type_id::create("axi4_virtual_tc_050_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi4_tc_050_wid_awid_mismatch_test"),UVM_LOW);
  axi4_virtual_tc_050_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Allow time for transaction to be sent and processed
  #100;
  
  phase.drop_objection(this);
endtask : run_phase

`endif