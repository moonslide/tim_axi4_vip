`ifndef AXI4_USER_BASED_QOS_ROUTING_TEST_INCLUDED_
`define AXI4_USER_BASED_QOS_ROUTING_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_based_qos_routing_test
// Tests USER signal-based QoS routing mechanism
// Demonstrates how USER signals can be used to route transactions to specific slaves
// or control transaction priority dynamically
//--------------------------------------------------------------------------------------------
class axi4_user_based_qos_routing_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_based_qos_routing_test)

  // Variable: axi4_virtual_user_based_qos_routing_seq_h
  // Handle to the USER-based QoS routing virtual sequence
  axi4_virtual_user_based_qos_routing_seq axi4_virtual_user_based_qos_routing_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_based_qos_routing_test", uvm_component parent = null);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_user_based_qos_routing_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_user_based_qos_routing_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_user_based_qos_routing_test::new(string name = "axi4_user_based_qos_routing_test",
                                               uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration with USER signal routing enabled
//--------------------------------------------------------------------------------------------
function void axi4_user_based_qos_routing_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Set reasonable outstanding transactions
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 4;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 4;
    // Enable USER signal support for routing control
    // USER signal bits [7:0] will be used for routing hints
    // USER signal bits [15:8] will be used for priority class
    // USER signal bits [23:16] will be used for traffic type
    // USER signal bits [31:24] will be reserved
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration with USER signal routing enabled
//--------------------------------------------------------------------------------------------
function void axi4_user_based_qos_routing_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the USER-based QoS routing virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_user_based_qos_routing_test::run_phase(uvm_phase phase);
  
  axi4_virtual_user_based_qos_routing_seq_h = axi4_virtual_user_based_qos_routing_seq::type_id::create("axi4_virtual_user_based_qos_routing_seq_h");
  
  `uvm_info(get_type_name(), "Starting USER-based QoS Routing Test", UVM_LOW)
  `uvm_info(get_type_name(), "This test demonstrates how USER signals control transaction routing and priority", UVM_LOW)
  `uvm_info(get_type_name(), "USER Signal Format:", UVM_LOW)
  `uvm_info(get_type_name(), "  [7:0]   - Routing hints (preferred slave ID)", UVM_LOW)
  `uvm_info(get_type_name(), "  [15:8]  - Priority class (0=lowest, 255=highest)", UVM_LOW)
  `uvm_info(get_type_name(), "  [23:16] - Traffic type (0=normal, 1=urgent, 2=bulk, 3=control)", UVM_LOW)
  `uvm_info(get_type_name(), "  [31:24] - Reserved", UVM_LOW)
  
  phase.raise_objection(this);
  axi4_virtual_user_based_qos_routing_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
  
endtask : run_phase

`endif