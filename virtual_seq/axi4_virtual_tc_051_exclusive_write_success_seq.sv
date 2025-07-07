`ifndef AXI4_VIRTUAL_TC_051_EXCLUSIVE_WRITE_SUCCESS_SEQ_INCLUDED_
`define AXI4_VIRTUAL_TC_051_EXCLUSIVE_WRITE_SUCCESS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_tc_051_exclusive_write_success_seq
// TC_051: Exclusive Write Success Virtual Sequence
//--------------------------------------------------------------------------------------------
class axi4_virtual_tc_051_exclusive_write_success_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_tc_051_exclusive_write_success_seq)

  axi4_master_tc_051_exclusive_write_success_seq axi4_master_tc_051_seq_h;

  extern function new(string name = "axi4_virtual_tc_051_exclusive_write_success_seq");
  extern task body();
endclass : axi4_virtual_tc_051_exclusive_write_success_seq

function axi4_virtual_tc_051_exclusive_write_success_seq::new(string name = "axi4_virtual_tc_051_exclusive_write_success_seq");
  super.new(name);
endfunction : new

task axi4_virtual_tc_051_exclusive_write_success_seq::body();
  axi4_master_tc_051_seq_h = axi4_master_tc_051_exclusive_write_success_seq::type_id::create("axi4_master_tc_051_seq_h");
  `uvm_info(get_type_name(), $sformatf("TC_051: Starting Exclusive Write Success test"), UVM_LOW);
  fork
    axi4_master_tc_051_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  join
  `uvm_info(get_type_name(), $sformatf("TC_051: Completed Exclusive Write Success test"), UVM_LOW);
endtask : body

`endif