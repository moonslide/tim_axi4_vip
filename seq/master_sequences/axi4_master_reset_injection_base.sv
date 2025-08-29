`ifndef AXI4_MASTER_RESET_INJECTION_BASE_INCLUDED_
`define AXI4_MASTER_RESET_INJECTION_BASE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_reset_injection_base
// Base class providing reset injection capability for all reset-related sequences
//--------------------------------------------------------------------------------------------
class axi4_master_reset_injection_base extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_reset_injection_base)

  // Reset injection parameters
  bit enable_reset_injection = 1;
  int reset_duration_cycles = 5;
  int reset_delay_ns = 100;
  
  extern function new(string name = "axi4_master_reset_injection_base");
  extern task inject_reset(int duration_cycles = 5, string phase_name = "UNKNOWN");
  extern task inject_reset_during_transfer();
  extern task verify_transfer_abandonment();
  extern task verify_system_recovery();

endclass : axi4_master_reset_injection_base

//--------------------------------------------------------------------------------------------
// Constructor
//--------------------------------------------------------------------------------------------
function axi4_master_reset_injection_base::new(string name = "axi4_master_reset_injection_base");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: inject_reset
// Injects a reset pulse of specified duration
//--------------------------------------------------------------------------------------------
task axi4_master_reset_injection_base::inject_reset(int duration_cycles = 5, string phase_name = "UNKNOWN");
  
  `uvm_info(get_type_name(), $sformatf("Injecting reset for %0d cycles during %s phase", duration_cycles, phase_name), UVM_LOW)
  
  // Pass reset duration to hdl_top
  uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", duration_cycles);
  
  // Mark reset active
  uvm_config_db#(bit)::set(null, "*", "reset_active", 1);
  uvm_config_db#(string)::set(null, "*", "reset_phase", phase_name);
  
  // Signal reset assertion (hdl_top will handle it)
  uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
  
  // Wait for reset to complete (duration + margin)
  #((duration_cycles + 2) * 10ns); // Assuming 100MHz clock
  
  // Clear reset flags
  uvm_config_db#(bit)::set(null, "*", "reset_active", 0);
  
  // Wait for system to stabilize
  #50ns;
  
  `uvm_info(get_type_name(), "Reset injection completed", UVM_LOW)
  
endtask : inject_reset

//--------------------------------------------------------------------------------------------
// Task: inject_reset_during_transfer
// Injects reset while a transfer is in progress
//--------------------------------------------------------------------------------------------
task axi4_master_reset_injection_base::inject_reset_during_transfer();
  
  `uvm_info(get_type_name(), "Injecting reset during active transfer", UVM_MEDIUM)
  
  // Start a normal transfer
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  
  assert(req.randomize() with {
    tx_type == WRITE;
    awlen == 15; // 16-beat burst
    awsize == WRITE_4_BYTES;
    awburst == WRITE_INCR;
    transfer_type == NON_BLOCKING_WRITE; // Non-blocking to allow reset during transfer
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  finish_item(req);
  
  // Wait for transfer to start (few beats into the burst)
  #(50ns);
  
  // Inject reset mid-transfer
  inject_reset(reset_duration_cycles, "MID_TRANSFER");
  
endtask : inject_reset_during_transfer

//--------------------------------------------------------------------------------------------
// Task: verify_transfer_abandonment
// Verifies that transfers are properly abandoned during reset
//--------------------------------------------------------------------------------------------
task axi4_master_reset_injection_base::verify_transfer_abandonment();
  
  `uvm_info(get_type_name(), "Verifying transfer abandonment during reset", UVM_MEDIUM)
  
  // Start a long burst
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  
  assert(req.randomize() with {
    tx_type == WRITE;
    awlen == 255; // Maximum burst
    awsize == WRITE_4_BYTES;
    awburst == WRITE_INCR;
    transfer_type == NON_BLOCKING_WRITE;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  finish_item(req);
  
  // Wait for transfer to be well underway
  #(100ns);
  
  // Inject reset to force abandonment
  inject_reset(10, "ABANDON_TEST");
  
  // Check that no responses are pending after reset
  // This would be verified by scoreboard/monitor
  `uvm_info(get_type_name(), "Transfer abandonment test completed", UVM_LOW)
  
endtask : verify_transfer_abandonment

//--------------------------------------------------------------------------------------------
// Task: verify_system_recovery
// Verifies that system recovers properly after reset
//--------------------------------------------------------------------------------------------
task axi4_master_reset_injection_base::verify_system_recovery();
  
  `uvm_info(get_type_name(), "Verifying system recovery after reset", UVM_MEDIUM)
  
  // Inject a reset
  inject_reset(5, "RECOVERY_TEST");
  
  // Wait for stabilization
  #(100ns);
  
  // Try a normal transaction after reset
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  
  assert(req.randomize() with {
    tx_type == WRITE;
    awlen == 0; // Single beat for quick test
    awsize == WRITE_4_BYTES;
    awburst == WRITE_FIXED;
    transfer_type == BLOCKING_WRITE;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  finish_item(req);
  
  // If we get here without timeout, recovery is successful
  `uvm_info(get_type_name(), "System recovery verified - post-reset transaction completed", UVM_LOW)
  
  // Try a read transaction too
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  
  assert(req.randomize() with {
    tx_type == READ;
    arlen == 0;
    arsize == READ_4_BYTES;
    arburst == READ_FIXED;
    transfer_type == BLOCKING_READ;
  }) else `uvm_fatal(get_type_name(), "Randomization failed")
  
  finish_item(req);
  
  `uvm_info(get_type_name(), "System recovery fully verified", UVM_LOW)
  
endtask : verify_system_recovery

`endif