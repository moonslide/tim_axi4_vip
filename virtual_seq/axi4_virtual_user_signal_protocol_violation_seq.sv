`ifndef AXI4_VIRTUAL_USER_SIGNAL_PROTOCOL_VIOLATION_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_SIGNAL_PROTOCOL_VIOLATION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_signal_protocol_violation_seq
// Virtual sequence to test USER signal protocol violations across multiple masters
// Verifies that protocol violations are detected and handled appropriately
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_signal_protocol_violation_seq extends axi4_virtual_base_seq;
  
  `uvm_object_utils(axi4_virtual_user_signal_protocol_violation_seq)
  
  // Sequence handles
  axi4_master_user_signal_protocol_violation_seq master_violation_seq[];
  
  // Test parameters
  int num_transactions_per_master = 8;
  int target_slave = 2; // Target slave for protocol violation testing
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_signal_protocol_violation_seq");
  extern virtual task body();
  
endclass : axi4_virtual_user_signal_protocol_violation_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_virtual_user_signal_protocol_violation_seq::new(string name = "axi4_virtual_user_signal_protocol_violation_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Coordinates USER signal protocol violation testing across multiple masters
//-----------------------------------------------------------------------------
task axi4_virtual_user_signal_protocol_violation_seq::body();
  int active_masters;
  
  super.body();
  
  // Use limited masters for protocol violation testing to isolate effects
  active_masters = (env_cfg_h.no_of_masters > 3) ? 3 : env_cfg_h.no_of_masters;
  
  `uvm_info(get_type_name(), $sformatf("Starting USER signal protocol violation test with %0d masters", active_masters), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Each master will test %0d violation scenarios targeting slave S%0d", 
                                        num_transactions_per_master, target_slave), UVM_MEDIUM)
  `uvm_info(get_type_name(), "Testing various protocol violations: Reserved bits, Invalid encodings, Inconsistencies", UVM_MEDIUM)
  `uvm_info(get_type_name(), "WARNING: This test intentionally violates USER signal protocols", UVM_LOW)
  
  // Create sequence array
  master_violation_seq = new[active_masters];
  
  // Start protocol violation sequences on selected masters sequentially
  // Sequential execution helps isolate violation effects and responses
  for (int i = 0; i < active_masters; i++) begin
    `uvm_info(get_type_name(), $sformatf("Starting USER protocol violation sequence on Master %0d", i), UVM_HIGH)
    
    // Create and configure the sequence
    master_violation_seq[i] = axi4_master_user_signal_protocol_violation_seq::type_id::create(
                              $sformatf("master_violation_seq_%0d", i));
    
    // Set configuration via config_db
    uvm_config_db#(int)::set(null, {get_full_name(), ".", master_violation_seq[i].get_name()}, 
                            "master_id", i);
    uvm_config_db#(int)::set(null, {get_full_name(), ".", master_violation_seq[i].get_name()}, 
                            "slave_id", target_slave);
    uvm_config_db#(int)::set(null, {get_full_name(), ".", master_violation_seq[i].get_name()}, 
                            "num_transactions", num_transactions_per_master);
    
    // Start on write sequencers (most protocol violations are in write transactions)
    master_violation_seq[i].start(p_sequencer.axi4_master_write_seqr_h_all[i]);
    
    // Wait between masters to observe individual violation effects
    #1000;
  end
  
  // Allow additional time for all violation effects to be processed
  #3000;
  
  `uvm_info(get_type_name(), "USER signal protocol violation test completed", UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected behavior: System should detect and handle protocol violations", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Reserved bit patterns should be flagged", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Invalid encodings should trigger error responses", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Inconsistent USER signals should be detected", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Security violations should be handled appropriately", UVM_MEDIUM)
  `uvm_info(get_type_name(), "- Critical violations should trigger system protection", UVM_MEDIUM)
  
endtask : body

`endif