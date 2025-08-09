`ifndef AXI4_USER_TRANSACTION_TRACING_TEST_INCLUDED_
`define AXI4_USER_TRANSACTION_TRACING_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_transaction_tracing_test
// Tests USER signal-based transaction tracing mechanism
// Demonstrates how USER signals can be used to trace and debug transactions through the system
// by embedding trace IDs, timestamps, source IDs, and debug markers
//--------------------------------------------------------------------------------------------
class axi4_user_transaction_tracing_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_transaction_tracing_test)

  // Variable: axi4_virtual_user_transaction_tracing_seq_h
  // Handle to the USER-based transaction tracing virtual sequence
  axi4_virtual_user_transaction_tracing_seq axi4_virtual_user_transaction_tracing_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_transaction_tracing_test", uvm_component parent = null);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_user_transaction_tracing_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_user_transaction_tracing_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_user_transaction_tracing_test::new(string name = "axi4_user_transaction_tracing_test",
                                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration with USER signal tracing enabled
//--------------------------------------------------------------------------------------------
function void axi4_user_transaction_tracing_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Set reasonable outstanding transactions for tracing
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 8;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 8;
    // Enable USER signal support for transaction tracing
    // USER signal bits [7:0] will be used for transaction ID
    // USER signal bits [15:8] will be used for source master ID
    // USER signal bits [23:16] will be used for debug flags
    // USER signal bits [31:24] will be used for sequence number
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration with USER signal tracing enabled
//--------------------------------------------------------------------------------------------
function void axi4_user_transaction_tracing_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Enable USER signal passthrough for trace validation
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the USER-based transaction tracing virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_user_transaction_tracing_test::run_phase(uvm_phase phase);
  
  axi4_virtual_user_transaction_tracing_seq_h = axi4_virtual_user_transaction_tracing_seq::type_id::create("axi4_virtual_user_transaction_tracing_seq_h");
  
  `uvm_info(get_type_name(), "Starting USER-based Transaction Tracing Test", UVM_LOW)
  `uvm_info(get_type_name(), "This test demonstrates how USER signals enable transaction tracing and debugging", UVM_LOW)
  `uvm_info(get_type_name(), "USER Signal Trace Format:", UVM_LOW)
  `uvm_info(get_type_name(), "  [7:0]   - Transaction ID (unique trace identifier)", UVM_LOW)
  `uvm_info(get_type_name(), "  [15:8]  - Source Master ID (originator identification)", UVM_LOW)
  `uvm_info(get_type_name(), "  [23:16] - Debug Flags (bit 16=debug_en, 17=trace_en, 18=log_en)", UVM_LOW)
  `uvm_info(get_type_name(), "  [31:24] - Sequence Number (for ordering and correlation)", UVM_LOW)
  
  phase.raise_objection(this);
  axi4_virtual_user_transaction_tracing_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
  
endtask : run_phase

`endif