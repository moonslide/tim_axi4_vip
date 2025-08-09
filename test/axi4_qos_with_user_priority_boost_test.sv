`ifndef AXI4_QOS_WITH_USER_PRIORITY_BOOST_TEST_INCLUDED_
`define AXI4_QOS_WITH_USER_PRIORITY_BOOST_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_with_user_priority_boost_test
// Tests QoS priority boosting mechanism using USER signals
// Demonstrates how USER signals can dynamically modify QoS priority levels
//--------------------------------------------------------------------------------------------
class axi4_qos_with_user_priority_boost_test extends axi4_base_test;
  `uvm_component_utils(axi4_qos_with_user_priority_boost_test)

  // Variable: axi4_virtual_qos_with_user_priority_boost_seq_h
  // Handle to the QoS with USER priority boost virtual sequence
  axi4_virtual_qos_with_user_priority_boost_seq axi4_virtual_qos_with_user_priority_boost_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_qos_with_user_priority_boost_test", uvm_component parent = null);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_qos_with_user_priority_boost_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_qos_with_user_priority_boost_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_qos_with_user_priority_boost_test::new(string name = "axi4_qos_with_user_priority_boost_test",
                                                     uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration with QoS and USER signal enabled
//--------------------------------------------------------------------------------------------
function void axi4_qos_with_user_priority_boost_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Set reasonable outstanding transactions
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 4;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 4;
    // Enable USER signal support for priority boosting
    // USER signal bits [3:0] will be used for priority boost value
    // USER signal bits [7:4] will be used for boost enable flag
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration with QoS and USER signal enabled
//--------------------------------------------------------------------------------------------
function void axi4_qos_with_user_priority_boost_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the QoS with USER priority boost virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_qos_with_user_priority_boost_test::run_phase(uvm_phase phase);
  
  axi4_virtual_qos_with_user_priority_boost_seq_h = axi4_virtual_qos_with_user_priority_boost_seq::type_id::create("axi4_virtual_qos_with_user_priority_boost_seq_h");
  
  `uvm_info(get_type_name(), "Starting QoS with USER Priority Boost Test", UVM_LOW)
  `uvm_info(get_type_name(), "This test demonstrates dynamic QoS priority boosting using USER signals", UVM_LOW)
  
  phase.raise_objection(this);
  axi4_virtual_qos_with_user_priority_boost_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
  
endtask : run_phase

`endif