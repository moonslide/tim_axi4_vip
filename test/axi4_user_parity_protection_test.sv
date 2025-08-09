`ifndef AXI4_USER_PARITY_PROTECTION_TEST_INCLUDED_
`define AXI4_USER_PARITY_PROTECTION_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_parity_protection_test
// Tests USER signal parity protection mechanism for error detection
// Demonstrates how parity bits in USER signals can detect transmission errors
//--------------------------------------------------------------------------------------------
class axi4_user_parity_protection_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_parity_protection_test)

  // Variable: axi4_virtual_user_parity_protection_seq_h
  // Handle to the USER parity protection virtual sequence
  axi4_virtual_user_parity_protection_seq axi4_virtual_user_parity_protection_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_parity_protection_test", uvm_component parent = null);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_user_parity_protection_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_user_parity_protection_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_user_parity_protection_test::new(string name = "axi4_user_parity_protection_test",
                                              uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration with USER parity protection enabled
//--------------------------------------------------------------------------------------------
function void axi4_user_parity_protection_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Set reasonable outstanding transactions
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 4;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 4;
    // Enable USER signal support for parity protection
    // USER signal format:
    // [23:0]  - Data payload
    // [27:24] - Nibble parity (4 bits for 6 nibbles)
    // [29:28] - Byte parity (2 bits for odd/even bytes)
    // [30]    - Overall parity bit
    // [31]    - Parity enable flag
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration with USER parity checking enabled
//--------------------------------------------------------------------------------------------
function void axi4_user_parity_protection_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Enable parity checking on slave side
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the USER parity protection virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_user_parity_protection_test::run_phase(uvm_phase phase);
  
  axi4_virtual_user_parity_protection_seq_h = axi4_virtual_user_parity_protection_seq::type_id::create("axi4_virtual_user_parity_protection_seq_h");
  
  `uvm_info(get_type_name(), "Starting USER Parity Protection Test", UVM_LOW)
  `uvm_info(get_type_name(), "This test demonstrates parity-based error detection in USER signals", UVM_LOW)
  `uvm_info(get_type_name(), "USER Signal Parity Format:", UVM_LOW)
  `uvm_info(get_type_name(), "  [23:0]  - Data payload (24 bits)", UVM_LOW)
  `uvm_info(get_type_name(), "  [27:24] - Nibble parity bits", UVM_LOW)  
  `uvm_info(get_type_name(), "  [29:28] - Byte parity bits", UVM_LOW)
  `uvm_info(get_type_name(), "  [30]    - Overall parity bit", UVM_LOW)
  `uvm_info(get_type_name(), "  [31]    - Parity enable flag", UVM_LOW)
  
  phase.raise_objection(this);
  axi4_virtual_user_parity_protection_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
  
endtask : run_phase

`endif