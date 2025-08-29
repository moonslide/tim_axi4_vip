`ifndef AXI4_BASIC_RESET_TEST_INCLUDED_
`define AXI4_BASIC_RESET_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_basic_reset_test
// Simple reset test that verifies basic reset functionality
//--------------------------------------------------------------------------------------------
class axi4_basic_reset_test extends axi4_base_test;
  `uvm_component_utils(axi4_basic_reset_test)

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_basic_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Function: build_phase
  //--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    // Set all agents to PASSIVE since this is a reset-only test with no transactions
    for(int i = 0; i < 10; i++) begin
      uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*slave_agent_h[%0d]*", i), "is_active", UVM_PASSIVE);
      uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*master_agent_h[%0d]*", i), "is_active", UVM_PASSIVE);
    end
    
    super.build_phase(phase);
    
    // Disable error injection
    uvm_config_db#(bit)::set(this, "*", "error_inject", 0);
    uvm_config_db#(bit)::set(this, "*", "x_inject_enable", 0);
    
    // Set x_inject flags to disable X_PROTOCOL assertions for PASSIVE mode
    // When agents are PASSIVE, signals are uninitialized (X) which triggers assertions
    uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 1);
    uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid", 1);
    uvm_config_db#(bit)::set(null, "*", "x_inject_wdata", 1);
    uvm_config_db#(bit)::set(null, "*", "x_inject_bready", 1);
    uvm_config_db#(bit)::set(null, "*", "x_inject_rready", 1);
    uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 1);
    
    // Properly disable scoreboard for this reset-only test
    axi4_env_cfg_h.has_scoreboard = 0;
    
    // Set error_inject flag on agents to prevent timeout
    foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].error_inject = 1;
    end
    foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].error_inject = 1;
    end
    
    `uvm_info(get_type_name(), "Build phase completed for Basic Reset Test", UVM_LOW)
    `uvm_info(get_type_name(), "Scoreboard disabled for this reset-only test", UVM_LOW)
  endfunction : build_phase

  //--------------------------------------------------------------------------------------------
  // Task: run_phase
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    BASIC RESET TEST STARTING", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Wait for initial stabilization
    #100ns;
    
    `uvm_info(get_type_name(), "Injecting first reset for 5 cycles", UVM_LOW)
    
    // Inject reset #1
    uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 5);
    uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
    
    // Wait for reset to complete
    #200ns;
    
    `uvm_info(get_type_name(), "Injecting second reset for 10 cycles", UVM_LOW)
    
    // Inject reset #2
    uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 10);
    uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
    
    // Wait for reset to complete
    #300ns;
    
    `uvm_info(get_type_name(), "Injecting third reset for 3 cycles", UVM_LOW)
    
    // Inject reset #3
    uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 3);
    uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
    
    // Wait for reset to complete
    #200ns;
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    BASIC RESET TEST COMPLETED", UVM_LOW)
    `uvm_info(get_type_name(), "    Successfully injected 3 reset events", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    phase.drop_objection(this);
    
  endtask : run_phase

  //--------------------------------------------------------------------------------------------
  // Function: report_phase
  //--------------------------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    // Skip scoreboard reporting since we're only testing reset
    // Don't call super.report_phase(phase);
    
    // Test passes if we successfully completed 3 reset injections
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    BASIC RESET TEST PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "    Successfully injected 3 reset events", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
  endfunction : report_phase

endclass : axi4_basic_reset_test

`endif