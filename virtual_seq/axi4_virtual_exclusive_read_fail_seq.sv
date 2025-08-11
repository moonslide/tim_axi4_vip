`ifndef AXI4_VIRTUAL_EXCLUSIVE_READ_FAIL_SEQ_INCLUDED_
`define AXI4_VIRTUAL_EXCLUSIVE_READ_FAIL_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_exclusive_read_fail_seq
// EXCLUSIVE_READ_FAIL: Exclusive Read Fail Virtual Sequence
// Orchestrates write-then-read to unprivileged address to test access privilege violations
//--------------------------------------------------------------------------------------------
class axi4_virtual_exclusive_read_fail_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_exclusive_read_fail_seq)

  axi4_master_exclusive_read_fail_seq axi4_master_exclusive_read_fail_seq_h;

  extern function new(string name = "axi4_virtual_exclusive_read_fail_seq");
  extern task body();
endclass : axi4_virtual_exclusive_read_fail_seq

function axi4_virtual_exclusive_read_fail_seq::new(string name = "axi4_virtual_exclusive_read_fail_seq");
  super.new(name);
endfunction : new

task axi4_virtual_exclusive_read_fail_seq::body();
  axi4_master_exclusive_read_fail_seq_h = axi4_master_exclusive_read_fail_seq::type_id::create("axi4_master_exclusive_read_fail_seq_h");
  `uvm_info(get_type_name(), $sformatf("EXCLUSIVE_READ_FAIL: Starting Exclusive Read Fail test"), UVM_LOW);
  fork
    axi4_master_exclusive_read_fail_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  join
  `uvm_info(get_type_name(), $sformatf("EXCLUSIVE_READ_FAIL: Completed Exclusive Read Fail test"), UVM_LOW);
endtask : body

`endif