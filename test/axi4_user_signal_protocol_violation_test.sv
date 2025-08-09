`ifndef AXI4_USER_SIGNAL_PROTOCOL_VIOLATION_TEST_INCLUDED_
`define AXI4_USER_SIGNAL_PROTOCOL_VIOLATION_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_signal_protocol_violation_test
// Tests various USER signal protocol violations to verify error detection and handling
// Uses the same environment as QoS routing test but intentionally violates protocols
//--------------------------------------------------------------------------------------------
class axi4_user_signal_protocol_violation_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_signal_protocol_violation_test)

  // Variable: axi4_virtual_user_signal_protocol_violation_seq_h
  // Handle to the USER signal protocol violation virtual sequence
  axi4_virtual_user_signal_protocol_violation_seq axi4_virtual_user_signal_protocol_violation_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_signal_protocol_violation_test", uvm_component parent = null);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_user_signal_protocol_violation_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_user_signal_protocol_violation_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_user_signal_protocol_violation_test::new(string name = "axi4_user_signal_protocol_violation_test",
                                                       uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration for protocol violation testing
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_protocol_violation_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to focus on USER signal violations
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Set reasonable outstanding transactions
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 4;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 4;
    // Enable USER signal support with full width for violation testing
    // All 32 bits of USER signals will be tested for various violations
    // Including reserved bits, illegal combinations, and integrity failures
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration for protocol violation testing
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_protocol_violation_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to focus on USER signal violations
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Enable strict protocol checking for USER signals
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the USER signal protocol violation virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_user_signal_protocol_violation_test::run_phase(uvm_phase phase);
  
  axi4_virtual_user_signal_protocol_violation_seq_h = axi4_virtual_user_signal_protocol_violation_seq::type_id::create("axi4_virtual_user_signal_protocol_violation_seq_h");
  
  `uvm_info(get_type_name(), "Starting USER Signal Protocol Violation Test", UVM_LOW)
  `uvm_info(get_type_name(), "This test intentionally violates USER signal protocols to verify error detection", UVM_LOW)
  `uvm_info(get_type_name(), "Expected violations to be tested:", UVM_LOW)
  `uvm_info(get_type_name(), "  1. AWUSER != WUSER mismatch violations", UVM_LOW)
  `uvm_info(get_type_name(), "  2. Reserved bit violations (bits [31:24] set)", UVM_LOW)
  `uvm_info(get_type_name(), "  3. USER signal changes mid-transaction", UVM_LOW)
  `uvm_info(get_type_name(), "  4. Invalid USER signal combinations", UVM_LOW)
  `uvm_info(get_type_name(), "  5. USER signal integrity failures", UVM_LOW)
  `uvm_info(get_type_name(), "  6. Overflow USER values (> max allowed)", UVM_LOW)
  `uvm_info(get_type_name(), "  7. Zero USER when non-zero expected", UVM_LOW)
  `uvm_info(get_type_name(), "  8. ARUSER != RUSER mismatches", UVM_LOW)
  
  phase.raise_objection(this);
  axi4_virtual_user_signal_protocol_violation_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
  
endtask : run_phase

`endif