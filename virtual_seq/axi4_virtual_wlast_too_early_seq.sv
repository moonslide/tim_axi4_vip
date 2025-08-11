`ifndef AXI4_VIRTUAL_WLAST_TOO_EARLY_SEQ_INCLUDED_
`define AXI4_VIRTUAL_WLAST_TOO_EARLY_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_wlast_too_early_seq
// WLAST_TOO_EARLY: Protocol WLAST Too Early Virtual Sequence
//--------------------------------------------------------------------------------------------
class axi4_virtual_wlast_too_early_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_wlast_too_early_seq)

  axi4_master_wlast_too_early_seq axi4_master_wlast_too_early_seq_h;

  extern function new(string name = "axi4_virtual_wlast_too_early_seq");
  extern task body();
endclass : axi4_virtual_wlast_too_early_seq

function axi4_virtual_wlast_too_early_seq::new(string name = "axi4_virtual_wlast_too_early_seq");
  super.new(name);
endfunction : new

task axi4_virtual_wlast_too_early_seq::body();
  axi4_master_wlast_too_early_seq_h = axi4_master_wlast_too_early_seq::type_id::create("axi4_master_wlast_too_early_seq_h");
  `uvm_info(get_type_name(), $sformatf("WLAST_TOO_EARLY: Starting WLAST Too Early test"), UVM_LOW);
  fork
    axi4_master_wlast_too_early_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  join
  `uvm_info(get_type_name(), $sformatf("WLAST_TOO_EARLY: Completed WLAST Too Early test"), UVM_LOW);
endtask : body

`endif