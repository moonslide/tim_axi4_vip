`ifndef AXI4_VIRTUAL_TC_044_ID_MULTIPLE_READS_SAME_ARID_SEQ_INCLUDED_
`define AXI4_VIRTUAL_TC_044_ID_MULTIPLE_READS_SAME_ARID_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_tc_044_id_multiple_reads_same_arid_seq
// TC_044: Verifies Slave handles multiple reads with same ARID in order
// Includes write phase to setup data, then read phase to verify ordering
//--------------------------------------------------------------------------------------------
class axi4_virtual_tc_044_id_multiple_reads_same_arid_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_tc_044_id_multiple_reads_same_arid_seq)

  axi4_master_tc_044_id_multiple_reads_same_arid_seq axi4_master_tc_044_seq_h;

  extern function new(string name = "axi4_virtual_tc_044_id_multiple_reads_same_arid_seq");
  extern task body();
endclass : axi4_virtual_tc_044_id_multiple_reads_same_arid_seq

function axi4_virtual_tc_044_id_multiple_reads_same_arid_seq::new(string name = "axi4_virtual_tc_044_id_multiple_reads_same_arid_seq");
  super.new(name);
endfunction : new

task axi4_virtual_tc_044_id_multiple_reads_same_arid_seq::body();
  axi4_master_tc_044_seq_h = axi4_master_tc_044_id_multiple_reads_same_arid_seq::type_id::create("axi4_master_tc_044_seq_h");
  
  `uvm_info(get_type_name(), $sformatf("TC_044: Starting ID Multiple Reads Same ARID test"), UVM_LOW);
  
  // Start master sequence on Master 0
  fork
    axi4_master_tc_044_seq_h.start(p_sequencer.axi4_master_read_seqr_h_all[0]);
  join
  
  `uvm_info(get_type_name(), $sformatf("TC_044: Completed ID Multiple Reads Same ARID test"), UVM_LOW);
endtask : body

`endif