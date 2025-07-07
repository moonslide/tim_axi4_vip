`ifndef AXI4_TC_052_EXCLUSIVE_WRITE_FAIL_TEST_INCLUDED_
`define AXI4_TC_052_EXCLUSIVE_WRITE_FAIL_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_052_exclusive_write_fail_test
// TC_052: Optional Exclusive Write Fail
// Tests AWLOCK=1 when exclusive monitor has been invalidated
// Expected BRESP=OKAY (not EXOKAY) indicating exclusive access failed
//--------------------------------------------------------------------------------------------
class axi4_tc_052_exclusive_write_fail_test extends axi4_base_test;
  `uvm_component_utils(axi4_tc_052_exclusive_write_fail_test)

  axi4_virtual_tc_052_exclusive_write_fail_seq axi4_virtual_tc_052_seq_h;

  extern function new(string name = "axi4_tc_052_exclusive_write_fail_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_tc_052_exclusive_write_fail_test

function axi4_tc_052_exclusive_write_fail_test::new(string name = "axi4_tc_052_exclusive_write_fail_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_tc_052_exclusive_write_fail_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction : build_phase

task axi4_tc_052_exclusive_write_fail_test::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  axi4_virtual_tc_052_seq_h = axi4_virtual_tc_052_exclusive_write_fail_seq::type_id::create("axi4_virtual_tc_052_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi4_tc_052_exclusive_write_fail_test"),UVM_LOW);
  axi4_virtual_tc_052_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  #10;
  phase.drop_objection(this);
endtask : run_phase

`endif