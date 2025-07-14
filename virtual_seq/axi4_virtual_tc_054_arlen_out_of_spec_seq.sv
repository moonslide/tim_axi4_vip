`ifndef AXI4_VIRTUAL_TC_054_ARLEN_OUT_OF_SPEC_SEQ_INCLUDED_
`define AXI4_VIRTUAL_TC_054_ARLEN_OUT_OF_SPEC_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_tc_054_arlen_out_of_spec_seq
// TC_054: Protocol ARLEN Out Of Spec Virtual Sequence
//--------------------------------------------------------------------------------------------
class axi4_virtual_tc_054_arlen_out_of_spec_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_tc_054_arlen_out_of_spec_seq)

  axi4_master_tc_054_arlen_out_of_spec_seq axi4_master_tc_054_seq_h;

  extern function new(string name = "axi4_virtual_tc_054_arlen_out_of_spec_seq");
  extern task body();
endclass : axi4_virtual_tc_054_arlen_out_of_spec_seq

function axi4_virtual_tc_054_arlen_out_of_spec_seq::new(string name = "axi4_virtual_tc_054_arlen_out_of_spec_seq");
  super.new(name);
endfunction : new

task axi4_virtual_tc_054_arlen_out_of_spec_seq::body();
  axi4_master_tc_054_seq_h = axi4_master_tc_054_arlen_out_of_spec_seq::type_id::create("axi4_master_tc_054_seq_h");
  `uvm_info(get_type_name(), $sformatf("TC_054: Starting ARLEN Out Of Spec test"), UVM_LOW);
  fork
    axi4_master_tc_054_seq_h.start(p_sequencer.axi4_master_read_seqr_h_all[0]);
  join
  `uvm_info(get_type_name(), $sformatf("TC_054: Completed ARLEN Out Of Spec test"), UVM_LOW);
endtask : body

`endif