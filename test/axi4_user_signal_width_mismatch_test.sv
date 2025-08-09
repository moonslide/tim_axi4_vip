`ifndef AXI4_USER_SIGNAL_WIDTH_MISMATCH_TEST_INCLUDED_
`define AXI4_USER_SIGNAL_WIDTH_MISMATCH_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_signal_width_mismatch_test
// Tests USER signal width mismatch scenarios to verify proper handling of width differences
// Uses the same environment as QoS routing test but focuses on width compatibility issues
//--------------------------------------------------------------------------------------------
class axi4_user_signal_width_mismatch_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_signal_width_mismatch_test)

  // Variable: axi4_virtual_user_signal_width_mismatch_seq_h
  // Handle to the USER signal width mismatch virtual sequence
  axi4_virtual_user_signal_width_mismatch_seq axi4_virtual_user_signal_width_mismatch_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_signal_width_mismatch_test", uvm_component parent = null);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_user_signal_width_mismatch_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_user_signal_width_mismatch_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_user_signal_width_mismatch_test::new(string name = "axi4_user_signal_width_mismatch_test",
                                                   uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration for width mismatch testing
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_width_mismatch_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to focus on USER signal width testing
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Set reasonable outstanding transactions
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 4;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 4;
    // USER signal width configuration will be tested with different values
    // The testbench uses 32-bit USER signals by default per axi4_bus_config.svh
    // We'll test scenarios where components expect different widths
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration for width mismatch testing
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_width_mismatch_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to focus on USER signal width testing
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Enable checks for USER signal width consistency
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the USER signal width mismatch virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_user_signal_width_mismatch_test::run_phase(uvm_phase phase);
  
  axi4_virtual_user_signal_width_mismatch_seq_h = axi4_virtual_user_signal_width_mismatch_seq::type_id::create("axi4_virtual_user_signal_width_mismatch_seq_h");
  
  `uvm_info(get_type_name(), "Starting USER Signal Width Mismatch Test", UVM_LOW)
  `uvm_info(get_type_name(), "This test verifies handling of USER signal width differences", UVM_LOW)
  `uvm_info(get_type_name(), "Width mismatch scenarios to be tested:", UVM_LOW)
  `uvm_info(get_type_name(), "  1. 32-bit USER truncated to lower widths (16, 8, 4, 1-bit)", UVM_LOW)
  `uvm_info(get_type_name(), "  2. Narrow USER zero-padded to wider interfaces", UVM_LOW)
  `uvm_info(get_type_name(), "  3. MSB preservation vs LSB preservation truncation", UVM_LOW)
  `uvm_info(get_type_name(), "  4. Width mismatches between channels (AWUSER vs WUSER)", UVM_LOW)
  `uvm_info(get_type_name(), "  5. Different widths for different masters/slaves", UVM_LOW)
  `uvm_info(get_type_name(), "  6. Dynamic width adaptation testing", UVM_LOW)
  `uvm_info(get_type_name(), "  7. Boundary value testing (all 1s, alternating patterns)", UVM_LOW)
  `uvm_info(get_type_name(), "  8. Width mismatch impact on QoS/routing information", UVM_LOW)
  
  `uvm_info(get_type_name(), "Expected USER signal widths per axi4_bus_config.svh:", UVM_LOW)
  `uvm_info(get_type_name(), "  AWUSER: 32-bit", UVM_LOW)
  `uvm_info(get_type_name(), "  ARUSER: 32-bit", UVM_LOW)
  `uvm_info(get_type_name(), "  WUSER:  32-bit", UVM_LOW)
  `uvm_info(get_type_name(), "  BUSER:  16-bit", UVM_LOW)
  `uvm_info(get_type_name(), "  RUSER:  16-bit", UVM_LOW)
  
  phase.raise_objection(this);
  axi4_virtual_user_signal_width_mismatch_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
  
endtask : run_phase

`endif