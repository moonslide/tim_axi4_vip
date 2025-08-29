`ifndef AXI4_VIRTUAL_SIMPLE_WRITE_SEQ_INCLUDED_
`define AXI4_VIRTUAL_SIMPLE_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_simple_write_seq
// Simple write sequence that sends only one transaction
//--------------------------------------------------------------------------------------------
class axi4_virtual_simple_write_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_simple_write_seq)

  //Variable: axi4_master_write_seq_h
  axi4_master_bk_write_seq axi4_master_bk_write_seq_h;

  //Variable: axi4_slave_write_seq_h  
  axi4_slave_bk_write_seq axi4_slave_bk_write_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_simple_write_seq");
  extern task body();
endclass : axi4_virtual_simple_write_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_virtual_simple_write_seq::new(string name = "axi4_virtual_simple_write_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task - body
// Sends a single write transaction
//--------------------------------------------------------------------------------------------
task axi4_virtual_simple_write_seq::body();
  `uvm_info(get_type_name(), "Starting simple write sequence", UVM_MEDIUM)
  
  // Create master sequence
  axi4_master_bk_write_seq_h = axi4_master_bk_write_seq::type_id::create("axi4_master_bk_write_seq_h");
  
  // Check if slave sequencer exists (only in ACTIVE mode)
  if (p_sequencer.axi4_slave_write_seqr_h != null) begin
    `uvm_info(get_type_name(), "Slave sequencer found - running master and slave sequences", UVM_HIGH)
    axi4_slave_bk_write_seq_h = axi4_slave_bk_write_seq::type_id::create("axi4_slave_bk_write_seq_h");
    
    // Run master and slave sequences in parallel
    fork
      axi4_master_bk_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
      axi4_slave_bk_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
    join
  end else begin
    // Slaves are passive - only run master sequence
    `uvm_info(get_type_name(), "Slave sequencer not found (PASSIVE mode) - running only master sequence", UVM_HIGH)
    axi4_master_bk_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  end
  
  `uvm_info(get_type_name(), "Simple write sequence completed", UVM_MEDIUM)
endtask : body

`endif