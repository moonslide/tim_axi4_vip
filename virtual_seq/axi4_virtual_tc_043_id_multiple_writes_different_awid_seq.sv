`ifndef AXI4_VIRTUAL_TC_043_ID_MULTIPLE_WRITES_DIFFERENT_AWID_SEQ_INCLUDED_
`define AXI4_VIRTUAL_TC_043_ID_MULTIPLE_WRITES_DIFFERENT_AWID_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_tc_043_id_multiple_writes_different_awid_seq
// TC_043: Verifies Slave handles different AWID writes with interleaved WDATA and out-of-order BRESP
// Address: Use DDR Memory range (0x0000_0100_0000_0000+) for all masters access
//--------------------------------------------------------------------------------------------
class axi4_virtual_tc_043_id_multiple_writes_different_awid_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_tc_043_id_multiple_writes_different_awid_seq)

  axi4_master_tc_043_id_multiple_writes_different_awid_seq axi4_master_tc_043_seq_h;

  extern function new(string name = "axi4_virtual_tc_043_id_multiple_writes_different_awid_seq");
  extern task body();
endclass : axi4_virtual_tc_043_id_multiple_writes_different_awid_seq

function axi4_virtual_tc_043_id_multiple_writes_different_awid_seq::new(string name = "axi4_virtual_tc_043_id_multiple_writes_different_awid_seq");
  super.new(name);
endfunction : new

task axi4_virtual_tc_043_id_multiple_writes_different_awid_seq::body();
  axi4_master_tc_043_seq_h = axi4_master_tc_043_id_multiple_writes_different_awid_seq::type_id::create("axi4_master_tc_043_seq_h");
  
  `uvm_info(get_type_name(), $sformatf("TC_043: Starting ID Multiple Writes Different AWID test"), UVM_LOW);
  
  // Start master sequence on Master 0
  fork
    axi4_master_tc_043_seq_h.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  join
  
  `uvm_info(get_type_name(), $sformatf("TC_043: Completed ID Multiple Writes Different AWID test"), UVM_LOW);
endtask : body

`endif