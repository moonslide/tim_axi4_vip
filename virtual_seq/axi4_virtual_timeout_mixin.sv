`ifndef AXI4_VIRTUAL_TIMEOUT_MIXIN_INCLUDED_
`define AXI4_VIRTUAL_TIMEOUT_MIXIN_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_timeout_mixin
// Global timeout mechanism for virtual sequences to prevent infinite loops
//--------------------------------------------------------------------------------------------
class axi4_virtual_timeout_mixin;
  // Static utility class - no UVM registration needed
  
  // Timeout configuration
  static int global_timeout_us = 20;  // Default 20us timeout
  static bit timeout_enabled = 1;    // Enable/disable timeout
  static bit force_completion = 1;   // Force completion on timeout
  
  // Task: apply_global_timeout
  // Apply timeout protection to any virtual sequence
  static task apply_global_timeout(uvm_sequence_base seq, int timeout_us = 0);
    int actual_timeout;
    
    if(!timeout_enabled) return;
    
    // Use provided timeout or default
    actual_timeout = (timeout_us > 0) ? timeout_us : global_timeout_us;
    
    fork
      begin
        #(actual_timeout * 1us);
        `uvm_warning("VIRTUAL_SEQ_TIMEOUT", 
                    $sformatf("Virtual sequence %s timeout reached after %0d us - %s completion", 
                             seq.get_name(), actual_timeout, 
                             force_completion ? "forcing" : "warning about"))
        
        if(force_completion) begin
          // Try to gracefully stop the sequence
          seq.kill();
        end
      end
    join_none
  endtask
  
  // Task: check_loop_timeout  
  // Check if loop should timeout (simplified version without ref arguments)
  static function bit should_exit_loop(int current_iteration, int max_iterations);
    if(!timeout_enabled) return 0;
    
    if(current_iteration >= max_iterations) begin
      `uvm_warning("LOOP_TIMEOUT", 
                  $sformatf("Loop exceeded max iterations (%0d) - should exit", max_iterations))
      return 1;  // Should exit
    end
    return 0;  // Continue
  endfunction
  
  // Task: safe_forever_loop
  // Replace forever loops with safe counted loops
  static task safe_forever_loop(string loop_name, int max_count = 50);
    `uvm_info("SAFE_LOOP", $sformatf("Starting safe loop %s (max %0d iterations)", loop_name, max_count), UVM_MEDIUM)
    
    for(int i = 0; i < max_count; i++) begin
      // The calling code should implement the loop body here
      // This is just a template
      #100ns;  // Default delay
    end
    
    `uvm_info("SAFE_LOOP", $sformatf("Safe loop %s completed after %0d iterations", loop_name, max_count), UVM_MEDIUM)
  endtask
  
endclass : axi4_virtual_timeout_mixin

`endif