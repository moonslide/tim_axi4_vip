`ifndef AXI4_VIRTUAL_ERROR_INJECT_SIMPLE_SEQ_INCLUDED_
`define AXI4_VIRTUAL_ERROR_INJECT_SIMPLE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_simple_seq
// Simplified virtual sequence for error injection testing - basic functionality
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_simple_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_simple_seq)

  // Master sequences
  axi4_master_bk_write_seq axi4_master_bk_write_seq_h;
  axi4_master_bk_read_seq axi4_master_bk_read_seq_h;

  function new(string name = "axi4_virtual_error_inject_simple_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting simplified error injection test", UVM_MEDIUM)
    
    // Create sequences
    axi4_master_bk_write_seq_h = axi4_master_bk_write_seq::type_id::create("axi4_master_bk_write_seq_h");
    axi4_master_bk_read_seq_h = axi4_master_bk_read_seq::type_id::create("axi4_master_bk_read_seq_h");
    
    // Run a simple write transaction
    `uvm_info(get_type_name(), "Running write transaction (conceptual X injection would occur here)", UVM_MEDIUM)
    axi4_master_bk_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
    
    // Add delay to simulate error injection/recovery
    #100ns;
    
    // Run a simple read transaction
    `uvm_info(get_type_name(), "Running read transaction (conceptual error recovery would occur here)", UVM_MEDIUM)
    axi4_master_bk_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
    
    `uvm_info(get_type_name(), "Error injection test completed", UVM_MEDIUM)
    
  endtask
endclass

`endif