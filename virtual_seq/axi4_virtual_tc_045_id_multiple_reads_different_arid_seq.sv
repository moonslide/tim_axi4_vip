`ifndef AXI4_VIRTUAL_TC_045_ID_MULTIPLE_READS_DIFFERENT_ARID_SEQ_INCLUDED_
`define AXI4_VIRTUAL_TC_045_ID_MULTIPLE_READS_DIFFERENT_ARID_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_tc_045_id_multiple_reads_different_arid_seq
// TC_045: Verifies Slave handles different ARID reads with out-of-order RDATA responses
// Includes write phase to setup data, then read phase to verify ordering
//--------------------------------------------------------------------------------------------
class axi4_virtual_tc_045_id_multiple_reads_different_arid_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_tc_045_id_multiple_reads_different_arid_seq)

  axi4_master_tc_045_write_setup_seq axi4_master_tc_045_write_seq_h;
  axi4_master_tc_045_read_test_seq axi4_master_tc_045_read_seq_h;

  extern function new(string name = "axi4_virtual_tc_045_id_multiple_reads_different_arid_seq");
  extern task body();
endclass : axi4_virtual_tc_045_id_multiple_reads_different_arid_seq

function axi4_virtual_tc_045_id_multiple_reads_different_arid_seq::new(string name = "axi4_virtual_tc_045_id_multiple_reads_different_arid_seq");
  super.new(name);
endfunction : new

task axi4_virtual_tc_045_id_multiple_reads_different_arid_seq::body();
  axi4_master_tc_045_write_seq_h = axi4_master_tc_045_write_setup_seq::type_id::create("axi4_master_tc_045_write_seq_h");
  axi4_master_tc_045_read_seq_h = axi4_master_tc_045_read_test_seq::type_id::create("axi4_master_tc_045_read_seq_h");
  
  `uvm_info(get_type_name(), $sformatf("TC_045: Starting ID Multiple Reads Different ARID test"), UVM_LOW);
  
  // Phase 1: Setup data using write sequencer
  fork
    axi4_master_tc_045_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  join
  
  // Wait for writes to complete
  #50;
  
  // Phase 2: Perform reads using read sequencer
  fork
    axi4_master_tc_045_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h_all[0]);
  join
  
  `uvm_info(get_type_name(), $sformatf("TC_045: Completed ID Multiple Reads Different ARID test"), UVM_LOW);
endtask : body

`endif