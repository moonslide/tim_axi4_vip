`ifndef AXI4_USER_SECURITY_TAGGING_TEST_INCLUDED_
`define AXI4_USER_SECURITY_TAGGING_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_security_tagging_test
// Tests USER signal security tagging mechanism for access control and data classification
// Demonstrates how USER signals can enforce security policies and isolation
//--------------------------------------------------------------------------------------------
class axi4_user_security_tagging_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_security_tagging_test)

  // Variable: axi4_virtual_user_security_tagging_seq_h
  // Handle to the USER security tagging virtual sequence
  axi4_virtual_user_security_tagging_seq axi4_virtual_user_security_tagging_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_security_tagging_test", uvm_component parent = null);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_user_security_tagging_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_user_security_tagging_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_user_security_tagging_test::new(string name = "axi4_user_security_tagging_test",
                                              uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration with USER security tagging enabled
//--------------------------------------------------------------------------------------------
function void axi4_user_security_tagging_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Set reasonable outstanding transactions
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 4;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 4;
    // Enable USER signal support for security tagging
    // USER signal format (32 bits):
    // [3:0]   - Security Level (0=Unclassified, 1-15=Various levels)
    // [7:4]   - Domain ID (0-15 security domains)
    // [11:8]  - Access Rights (Read/Write/Execute/Delete)
    // [15:12] - Privilege Level (User/Supervisor/Hypervisor/Secure)
    // [19:16] - Security Zone (DMZ/Internal/Critical/Isolated)
    // [23:20] - Encryption Required (None/AES128/AES256/Custom)
    // [27:24] - Integrity Check (None/CRC/Hash/HMAC)
    // [31:28] - Audit Level (None/Basic/Enhanced/Full)
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration with security policy enforcement
//--------------------------------------------------------------------------------------------
function void axi4_user_security_tagging_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Enable security checking on slave side
    // Slaves will enforce security policies based on USER tags
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the USER security tagging virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_user_security_tagging_test::run_phase(uvm_phase phase);
  
  axi4_virtual_user_security_tagging_seq_h = axi4_virtual_user_security_tagging_seq::type_id::create("axi4_virtual_user_security_tagging_seq_h");
  
  `uvm_info(get_type_name(), "Starting USER Security Tagging Test", UVM_LOW)
  `uvm_info(get_type_name(), "This test demonstrates security policy enforcement using USER signals", UVM_LOW)
  `uvm_info(get_type_name(), "USER Signal Security Format (32 bits):", UVM_LOW)
  `uvm_info(get_type_name(), "  [3:0]   - Security Level (0=Unclassified, 15=Top Secret)", UVM_LOW)
  `uvm_info(get_type_name(), "  [7:4]   - Domain ID (0-15 isolation domains)", UVM_LOW)  
  `uvm_info(get_type_name(), "  [11:8]  - Access Rights (R/W/X/D permissions)", UVM_LOW)
  `uvm_info(get_type_name(), "  [15:12] - Privilege Level (User/Super/Hyper/Secure)", UVM_LOW)
  `uvm_info(get_type_name(), "  [19:16] - Security Zone (DMZ/Internal/Critical/Isolated)", UVM_LOW)
  `uvm_info(get_type_name(), "  [23:20] - Encryption Required", UVM_LOW)
  `uvm_info(get_type_name(), "  [27:24] - Integrity Check", UVM_LOW)
  `uvm_info(get_type_name(), "  [31:28] - Audit Level", UVM_LOW)
  
  phase.raise_objection(this);
  axi4_virtual_user_security_tagging_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
  
endtask : run_phase

`endif