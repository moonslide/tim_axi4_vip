`ifndef AXI4_VIRTUAL_TC_054_EXCLUSIVE_READ_FAIL_SEQ_INCLUDED_
`define AXI4_VIRTUAL_TC_054_EXCLUSIVE_READ_FAIL_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_tc_054_exclusive_read_fail_seq
// TC_054: Exclusive Read Fail Virtual Sequence
// Orchestrates write-then-read to unprivileged address to test access privilege violations
//--------------------------------------------------------------------------------------------
class axi4_virtual_tc_054_exclusive_read_fail_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_tc_054_exclusive_read_fail_seq)

  axi4_master_tc_054_exclusive_read_fail_seq axi4_master_tc_054_seq_h;

  extern function new(string name = "axi4_virtual_tc_054_exclusive_read_fail_seq");
  extern task body();
endclass : axi4_virtual_tc_054_exclusive_read_fail_seq

function axi4_virtual_tc_054_exclusive_read_fail_seq::new(string name = "axi4_virtual_tc_054_exclusive_read_fail_seq");
  super.new(name);
endfunction : new

task axi4_virtual_tc_054_exclusive_read_fail_seq::body();
  axi4_master_tc_054_seq_h = axi4_master_tc_054_exclusive_read_fail_seq::type_id::create("axi4_master_tc_054_seq_h");
  `uvm_info(get_type_name(), $sformatf("TC_054: Starting Exclusive Read Fail test"), UVM_LOW);
  fork
    axi4_master_tc_054_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  join
  `uvm_info(get_type_name(), $sformatf("TC_054: Completed Exclusive Read Fail test"), UVM_LOW);
endtask : body

`endif