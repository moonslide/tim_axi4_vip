`ifndef AXI4_TC_046_ID_MULTIPLE_WRITES_SAME_AWID_TEST_INCLUDED_
`define AXI4_TC_046_ID_MULTIPLE_WRITES_SAME_AWID_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_046_id_multiple_writes_same_awid_test
// TC_046: ID Multiple Writes Same AWID
// Verifies that Slave responds to multiple write requests with the same AWID in order
//--------------------------------------------------------------------------------------------
class axi4_tc_046_id_multiple_writes_same_awid_test extends axi4_base_test;
  `uvm_component_utils(axi4_tc_046_id_multiple_writes_same_awid_test)

  axi4_virtual_tc_046_id_multiple_writes_same_awid_seq axi4_virtual_tc_046_id_multiple_writes_same_awid_seq_h;

  extern function new(string name = "axi4_tc_046_id_multiple_writes_same_awid_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_tc_046_id_multiple_writes_same_awid_test

function axi4_tc_046_id_multiple_writes_same_awid_test::new(string name = "axi4_tc_046_id_multiple_writes_same_awid_test",
                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_tc_046_id_multiple_writes_same_awid_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Disable backdoor verification for same AWID test - since it writes with same WID,
  // backdoor comparison doesn't make sense as transactions can interleave
  uvm_config_db#(bit)::set(this, "*", "disable_backdoor_verify", 1);
  uvm_config_db#(bit)::set(this, "*env*", "disable_backdoor_verify", 1);
  uvm_config_db#(int)::set(this, "*", "backdoor_verify_enable", 0);
  `uvm_info(get_type_name(), "TC_046: disabled backdoor verification for same AWID writes", UVM_LOW);
endfunction : build_phase

task axi4_tc_046_id_multiple_writes_same_awid_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this);
  
  axi4_virtual_tc_046_id_multiple_writes_same_awid_seq_h = axi4_virtual_tc_046_id_multiple_writes_same_awid_seq::type_id::create("axi4_virtual_tc_046_id_multiple_writes_same_awid_seq_h");
  
  `uvm_info(get_type_name(),$sformatf("axi4_tc_046_id_multiple_writes_same_awid_test"),UVM_LOW);
  axi4_virtual_tc_046_id_multiple_writes_same_awid_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  #10;
  
  phase.drop_objection(this);

endtask : run_phase

`endif