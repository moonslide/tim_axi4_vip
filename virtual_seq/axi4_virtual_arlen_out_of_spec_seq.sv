`ifndef AXI4_VIRTUAL_ARLEN_OUT_OF_SPEC_SEQ_INCLUDED_
`define AXI4_VIRTUAL_ARLEN_OUT_OF_SPEC_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_arlen_out_of_spec_seq
// ARLEN_OUT_OF_SPEC: Protocol ARLEN Out Of Spec Virtual Sequence
//--------------------------------------------------------------------------------------------
class axi4_virtual_arlen_out_of_spec_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_arlen_out_of_spec_seq)

  axi4_master_arlen_out_of_spec_seq axi4_master_arlen_out_of_spec_seq_h;

  extern function new(string name = "axi4_virtual_arlen_out_of_spec_seq");
  extern task body();
endclass : axi4_virtual_arlen_out_of_spec_seq

function axi4_virtual_arlen_out_of_spec_seq::new(string name = "axi4_virtual_arlen_out_of_spec_seq");
  super.new(name);
endfunction : new

task axi4_virtual_arlen_out_of_spec_seq::body();
  axi4_master_arlen_out_of_spec_seq_h = axi4_master_arlen_out_of_spec_seq::type_id::create("axi4_master_arlen_out_of_spec_seq_h");
  `uvm_info(get_type_name(), $sformatf("ARLEN_OUT_OF_SPEC: Starting ARLEN Out Of Spec test"), UVM_LOW);
  fork
    axi4_master_arlen_out_of_spec_seq_h.start(p_sequencer.axi4_master_read_seqr_h_all[0]);
  join
  `uvm_info(get_type_name(), $sformatf("ARLEN_OUT_OF_SPEC: Completed ARLEN Out Of Spec test"), UVM_LOW);
endtask : body

`endif