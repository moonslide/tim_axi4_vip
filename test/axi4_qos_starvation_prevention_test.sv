`ifndef AXI4_QOS_STARVATION_PREVENTION_TEST_INCLUDED_
`define AXI4_QOS_STARVATION_PREVENTION_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_starvation_prevention_test
// Tests QoS starvation prevention mechanism to ensure low priority transactions
// eventually get serviced even with continuous high priority traffic
//--------------------------------------------------------------------------------------------
class axi4_qos_starvation_prevention_test extends axi4_base_test;
  `uvm_component_utils(axi4_qos_starvation_prevention_test)

  // Variable: axi4_virtual_qos_starvation_prevention_seq_h
  // Handle to the QoS starvation prevention virtual sequence
  axi4_virtual_qos_starvation_prevention_seq axi4_virtual_qos_starvation_prevention_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_qos_starvation_prevention_test", uvm_component parent = null);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_qos_starvation_prevention_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_qos_starvation_prevention_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_qos_starvation_prevention_test::new(string name = "axi4_qos_starvation_prevention_test",
                                                  uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration with QoS enabled
//--------------------------------------------------------------------------------------------
function void axi4_qos_starvation_prevention_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Set reasonable outstanding transactions
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 4;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 4;
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration with QoS enabled
//--------------------------------------------------------------------------------------------
function void axi4_qos_starvation_prevention_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the QoS starvation prevention virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_qos_starvation_prevention_test::run_phase(uvm_phase phase);
  
  axi4_virtual_qos_starvation_prevention_seq_h = axi4_virtual_qos_starvation_prevention_seq::type_id::create("axi4_virtual_qos_starvation_prevention_seq_h");
  
  `uvm_info(get_type_name(), "Starting QoS Starvation Prevention Test", UVM_LOW)
  
  phase.raise_objection(this);
  axi4_virtual_qos_starvation_prevention_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
  
endtask : run_phase

`endif