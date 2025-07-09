`ifndef AXI4_VIRTUAL_TC_053_EXCLUSIVE_READ_SUCCESS_SEQ_INCLUDED_
`define AXI4_VIRTUAL_TC_053_EXCLUSIVE_READ_SUCCESS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_tc_053_exclusive_read_success_seq
// TC_053: Exclusive Read Success Virtual Sequence
//--------------------------------------------------------------------------------------------
class axi4_virtual_tc_053_exclusive_read_success_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_tc_053_exclusive_read_success_seq)

  axi4_master_tc_053_exclusive_read_success_seq axi4_master_tc_053_seq_h;

  extern function new(string name = "axi4_virtual_tc_053_exclusive_read_success_seq");
  extern task body();
endclass : axi4_virtual_tc_053_exclusive_read_success_seq

function axi4_virtual_tc_053_exclusive_read_success_seq::new(string name = "axi4_virtual_tc_053_exclusive_read_success_seq");
  super.new(name);
endfunction : new

task axi4_virtual_tc_053_exclusive_read_success_seq::body();
  axi4_master_tc_053_seq_h = axi4_master_tc_053_exclusive_read_success_seq::type_id::create("axi4_master_tc_053_seq_h");
  `uvm_info(get_type_name(), $sformatf("TC_053: Starting Exclusive Read Success test"), UVM_LOW);
  
  // Start sequence on master 0 - uses write sequencer since it does both write and read
  axi4_master_tc_053_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  
  // Wait for transactions to propagate through system
  #100;
  
  `uvm_info(get_type_name(), $sformatf("TC_053: Completed Exclusive Read Success test"), UVM_LOW);
endtask : body

`endif