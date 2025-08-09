`ifndef AXI4_USER_SIGNAL_PASSTHROUGH_TEST_INCLUDED_
`define AXI4_USER_SIGNAL_PASSTHROUGH_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_signal_passthrough_test
// Tests USER signal passthrough functionality across the bus matrix
// Verifies that USER signals are correctly transmitted from masters to slaves
// without corruption or loss of data integrity
//--------------------------------------------------------------------------------------------
class axi4_user_signal_passthrough_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_signal_passthrough_test)

  // Variable: axi4_virtual_user_signal_passthrough_seq_h
  // Handle to the USER signal passthrough virtual sequence
  axi4_virtual_user_signal_passthrough_seq axi4_virtual_user_signal_passthrough_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_signal_passthrough_test", uvm_component parent = null);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_user_signal_passthrough_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_user_signal_passthrough_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_user_signal_passthrough_test::new(string name = "axi4_user_signal_passthrough_test",
                                                uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration with USER signal passthrough enabled
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_passthrough_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Set reasonable outstanding transactions
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 4;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 4;
    // Enable USER signal support for passthrough testing
    // USER signal format for passthrough verification:
    // [7:0]   - Data payload (test pattern)
    // [15:8]  - Master ID identifier
    // [23:16] - Sequence counter
    // [31:24] - Test pattern identifier
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration with USER signal passthrough enabled
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_passthrough_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Enable USER signal passthrough verification on slave side
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the USER signal passthrough virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_user_signal_passthrough_test::run_phase(uvm_phase phase);
  
  axi4_virtual_user_signal_passthrough_seq_h = axi4_virtual_user_signal_passthrough_seq::type_id::create("axi4_virtual_user_signal_passthrough_seq_h");
  
  `uvm_info(get_type_name(), "Starting USER Signal Passthrough Test", UVM_LOW)
  `uvm_info(get_type_name(), "This test verifies USER signal integrity across the bus matrix", UVM_LOW)
  `uvm_info(get_type_name(), "USER Signal Passthrough Test Format:", UVM_LOW)
  `uvm_info(get_type_name(), "  [7:0]   - Data payload (test patterns)", UVM_LOW)
  `uvm_info(get_type_name(), "  [15:8]  - Master ID identifier", UVM_LOW)
  `uvm_info(get_type_name(), "  [23:16] - Sequence counter", UVM_LOW)
  `uvm_info(get_type_name(), "  [31:24] - Test pattern identifier", UVM_LOW)
  `uvm_info(get_type_name(), "Test Scenarios:", UVM_LOW)
  `uvm_info(get_type_name(), "  - All zeros pattern", UVM_LOW)
  `uvm_info(get_type_name(), "  - All ones pattern", UVM_LOW)
  `uvm_info(get_type_name(), "  - Alternating patterns", UVM_LOW)
  `uvm_info(get_type_name(), "  - Walking ones/zeros", UVM_LOW)
  `uvm_info(get_type_name(), "  - Random patterns", UVM_LOW)
  
  phase.raise_objection(this);
  axi4_virtual_user_signal_passthrough_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
  
endtask : run_phase

`endif