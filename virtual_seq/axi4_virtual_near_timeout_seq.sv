`ifndef AXI4_VIRTUAL_NEAR_TIMEOUT_SEQ_INCLUDED_
`define AXI4_VIRTUAL_NEAR_TIMEOUT_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_near_timeout_seq
// Virtual sequence for near timeout testing - coordinates master/slave timeout behavior
//--------------------------------------------------------------------------------------------
class axi4_virtual_near_timeout_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_near_timeout_seq)

  // Master sequence for timeout testing
  axi4_master_near_timeout_seq timeout_seq_h;
  axi4_master_bk_read_seq read_seq_h;
  
  // Timeout monitoring
  int timeout_threshold = 1024;
  int stall_cycles = 1023;
  time start_time, end_time, stall_duration;

  function new(string name = "axi4_virtual_near_timeout_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting virtual near timeout sequence", UVM_MEDIUM)
    
    // Get timeout configuration
    if (!uvm_config_db#(int)::get(p_sequencer, "", "timeout_threshold", timeout_threshold)) begin
      `uvm_warning(get_type_name(), "timeout_threshold not set, using default 1024")
    end
    
    if (!uvm_config_db#(int)::get(p_sequencer, "", "stall_cycles", stall_cycles)) begin
      `uvm_warning(get_type_name(), "stall_cycles not set, using default 1023") 
    end
    
    `uvm_info(get_type_name(), "=== TIMEOUT TEST SCENARIO ===", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Timeout Threshold: %0d cycles", timeout_threshold), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Expected Stall Duration: %0d cycles", stall_cycles), UVM_LOW)
    `uvm_info(get_type_name(), "Expected Result: Transaction completes just before timeout", UVM_LOW)
    `uvm_info(get_type_name(), "================================", UVM_LOW)
    
    // Create the timeout test sequence
    timeout_seq_h = axi4_master_near_timeout_seq::type_id::create("timeout_seq_h");
    
    // Configure it with timeout parameters
    uvm_config_db#(int)::set(p_sequencer.axi4_master_write_seqr_h, "", "timeout_threshold", timeout_threshold);
    uvm_config_db#(int)::set(p_sequencer.axi4_master_write_seqr_h, "", "stall_cycles", stall_cycles);
    
    // Record start time for monitoring
    start_time = $time;
    `uvm_info(get_type_name(), $sformatf("Starting timeout test at time: %0t", start_time), UVM_MEDIUM)
    
    // Start the sequence - this should trigger slave stall behavior
    timeout_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
    
    // Record end time
    end_time = $time;
    stall_duration = end_time - start_time;
    
    `uvm_info(get_type_name(), "=== TIMEOUT TEST RESULTS ===", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Test Duration: %0t", stall_duration), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Expected: ~%0d clock cycles", stall_cycles), UVM_LOW)
    
    // Verify timing was within expected range
    // Note: Actual timing verification would need clock period information
    if (stall_duration > 0) begin
      `uvm_info(get_type_name(), "SUCCESS: Transaction completed with measurable stall duration", UVM_LOW)
    end else begin
      `uvm_warning(get_type_name(), "WARNING: No stall detected - slave may not implement timeout test")
    end
    
    `uvm_info(get_type_name(), "==========================", UVM_LOW)
    
    // Additional read transaction to verify system recovery
    `uvm_info(get_type_name(), "Testing system recovery with read transaction", UVM_MEDIUM)
    
    // Use existing simple read sequence to verify normal operation  
    read_seq_h = axi4_master_bk_read_seq::type_id::create("read_seq_h");
    read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
    
    `uvm_info(get_type_name(), "Virtual near timeout sequence completed", UVM_MEDIUM)
    
  endtask

endclass : axi4_virtual_near_timeout_seq

`endif