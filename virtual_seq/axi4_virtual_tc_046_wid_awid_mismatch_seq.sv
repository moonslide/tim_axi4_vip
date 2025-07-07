`ifndef AXI4_VIRTUAL_TC_046_WID_AWID_MISMATCH_SEQ_INCLUDED_
`define AXI4_VIRTUAL_TC_046_WID_AWID_MISMATCH_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_tc_046_wid_awid_mismatch_seq
// TC_046: Protocol violation - WID AWID Mismatch Virtual Sequence
//--------------------------------------------------------------------------------------------
class axi4_virtual_tc_046_wid_awid_mismatch_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_tc_046_wid_awid_mismatch_seq)

  axi4_master_tc_046_wid_awid_mismatch_seq axi4_master_tc_046_seq_h;

  extern function new(string name = "axi4_virtual_tc_046_wid_awid_mismatch_seq");
  extern task body();
endclass : axi4_virtual_tc_046_wid_awid_mismatch_seq

function axi4_virtual_tc_046_wid_awid_mismatch_seq::new(string name = "axi4_virtual_tc_046_wid_awid_mismatch_seq");
  super.new(name);
endfunction : new

task axi4_virtual_tc_046_wid_awid_mismatch_seq::body();
  axi4_master_tc_046_seq_h = axi4_master_tc_046_wid_awid_mismatch_seq::type_id::create("axi4_master_tc_046_seq_h");
  `uvm_info(get_type_name(), $sformatf("TC_046: Starting WID AWID Mismatch test"), UVM_LOW);
  fork
    axi4_master_tc_046_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  join
  `uvm_info(get_type_name(), $sformatf("TC_046: Completed WID AWID Mismatch test"), UVM_LOW);
endtask : body

`endif