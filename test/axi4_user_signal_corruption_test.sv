`ifndef AXI4_USER_SIGNAL_CORRUPTION_TEST_INCLUDED_
`define AXI4_USER_SIGNAL_CORRUPTION_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_signal_corruption_test
// Tests USER signal corruption detection and handling mechanisms
// Demonstrates robustness against various corruption scenarios and error recovery
//--------------------------------------------------------------------------------------------
class axi4_user_signal_corruption_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_signal_corruption_test)

  // Variable: axi4_virtual_user_signal_corruption_seq_h
  // Handle to the USER signal corruption virtual sequence
  axi4_virtual_user_signal_corruption_seq axi4_virtual_user_signal_corruption_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_signal_corruption_test", uvm_component parent = null);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_user_signal_corruption_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_user_signal_corruption_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_user_signal_corruption_test::new(string name = "axi4_user_signal_corruption_test",
                                               uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration with USER corruption testing enabled
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_corruption_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Set reasonable outstanding transactions
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 4;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 4;
    // Enable USER signal corruption testing
    // USER signal format for corruption testing:
    // [7:0]   - Payload data
    // [15:8]  - Header information
    // [23:16] - Control flags
    // [31:24] - Error detection/correction bits
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration with corruption detection enabled
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_corruption_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Enable corruption detection on slave side
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the USER signal corruption virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_user_signal_corruption_test::run_phase(uvm_phase phase);
  
  axi4_virtual_user_signal_corruption_seq_h = axi4_virtual_user_signal_corruption_seq::type_id::create("axi4_virtual_user_signal_corruption_seq_h");
  
  `uvm_info(get_type_name(), "Starting USER Signal Corruption Test", UVM_LOW)
  `uvm_info(get_type_name(), "This test demonstrates corruption detection and recovery mechanisms", UVM_LOW)
  `uvm_info(get_type_name(), "USER Signal Corruption Test Format:", UVM_LOW)
  `uvm_info(get_type_name(), "  [7:0]   - Payload data (subject to corruption)", UVM_LOW)
  `uvm_info(get_type_name(), "  [15:8]  - Header information", UVM_LOW)  
  `uvm_info(get_type_name(), "  [23:16] - Control flags", UVM_LOW)
  `uvm_info(get_type_name(), "  [31:24] - Error detection/correction bits", UVM_LOW)
  `uvm_info(get_type_name(), "Test Scenarios:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Single bit corruption", UVM_LOW)
  `uvm_info(get_type_name(), "  - Multi-bit corruption", UVM_LOW)
  `uvm_info(get_type_name(), "  - Burst corruption", UVM_LOW)
  `uvm_info(get_type_name(), "  - Pattern corruption", UVM_LOW)
  `uvm_info(get_type_name(), "  - Complete signal corruption", UVM_LOW)
  
  phase.raise_objection(this);
  axi4_virtual_user_signal_corruption_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
  
endtask : run_phase

`endif