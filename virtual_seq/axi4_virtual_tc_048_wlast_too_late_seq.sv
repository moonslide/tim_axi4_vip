`ifndef AXI4_VIRTUAL_TC_048_WLAST_TOO_LATE_SEQ_INCLUDED_
`define AXI4_VIRTUAL_TC_048_WLAST_TOO_LATE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_tc_048_wlast_too_late_seq
// TC_048: Protocol WLAST Too Late Virtual Sequence
//--------------------------------------------------------------------------------------------
class axi4_virtual_tc_048_wlast_too_late_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_tc_048_wlast_too_late_seq)

  axi4_master_tc_048_wlast_too_late_seq axi4_master_tc_048_seq_h;

  extern function new(string name = "axi4_virtual_tc_048_wlast_too_late_seq");
  extern task body();
endclass : axi4_virtual_tc_048_wlast_too_late_seq

function axi4_virtual_tc_048_wlast_too_late_seq::new(string name = "axi4_virtual_tc_048_wlast_too_late_seq");
  super.new(name);
endfunction : new

task axi4_virtual_tc_048_wlast_too_late_seq::body();
  axi4_master_tc_048_seq_h = axi4_master_tc_048_wlast_too_late_seq::type_id::create("axi4_master_tc_048_seq_h");
  `uvm_info(get_type_name(), $sformatf("TC_048: Starting WLAST Too Late test"), UVM_LOW);
  fork
    axi4_master_tc_048_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  join
  `uvm_info(get_type_name(), $sformatf("TC_048: Completed WLAST Too Late test"), UVM_LOW);
endtask : body

`endif