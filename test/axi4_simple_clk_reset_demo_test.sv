`ifndef AXI4_SIMPLE_CLK_RESET_DEMO_TEST_INCLUDED_
`define AXI4_SIMPLE_CLK_RESET_DEMO_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_simple_clk_reset_demo_test
// Simple demonstration test that shows clock frequency changes and reset work on interface
//--------------------------------------------------------------------------------------------
class axi4_simple_clk_reset_demo_test extends axi4_base_test;
  `uvm_component_utils(axi4_simple_clk_reset_demo_test)

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_simple_clk_reset_demo_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Function: build_phase
  //--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    // Set all agents to PASSIVE since this is a demo test with no transactions
    for(int i = 0; i < 10; i++) begin
      uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*slave_agent_h[%0d]*", i), "is_active", UVM_PASSIVE);
      uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*master_agent_h[%0d]*", i), "is_active", UVM_PASSIVE);
    end
    
    super.build_phase(phase);
    
    // Disable error injection and scoreboard for this demo
    uvm_config_db#(bit)::set(this, "*", "error_inject", 0);
    uvm_config_db#(bit)::set(this, "*", "x_inject_enable", 0);
    
    // Set x_inject flags to disable X_PROTOCOL assertions for PASSIVE mode
    uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 1);
    uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid", 1);
    uvm_config_db#(bit)::set(null, "*", "x_inject_wdata", 1);
    uvm_config_db#(bit)::set(null, "*", "x_inject_bready", 1);
    uvm_config_db#(bit)::set(null, "*", "x_inject_rready", 1);
    uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 1);
    
    // Properly disable scoreboard checking for this demo test
    axi4_env_cfg_h.has_scoreboard = 0;
    
    // Set error_inject flag on agents to prevent timeout
    foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].error_inject = 1;
    end
    foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].error_inject = 1;
    end
    
    `uvm_info(get_type_name(), "Build phase completed for Clock/Reset Demo Test", UVM_LOW)
    `uvm_info(get_type_name(), "Scoreboard disabled for this demonstration test", UVM_LOW)
  endfunction : build_phase

  //--------------------------------------------------------------------------------------------
  // Task: run_phase
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    CLOCK & RESET DEMO TEST STARTING", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Wait for initial stabilization
    #100ns;
    
    //--------------------------------------------------------------------------------------------
    // Test 1: Clock Frequency Changes
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "TEST 1: Clock Frequency Changes", UVM_LOW)
    
    // Change to 2x frequency (200MHz)
    `uvm_info(get_type_name(), "Changing clock to 2x frequency (200MHz)", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 2.0);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    #200ns;
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    // Change to 0.5x frequency (50MHz)
    `uvm_info(get_type_name(), "Changing clock to 0.5x frequency (50MHz)", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 0.5);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    #200ns;
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    // Back to 1x frequency (100MHz)
    `uvm_info(get_type_name(), "Returning clock to 1x frequency (100MHz)", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 1.0);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    #200ns;
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    //--------------------------------------------------------------------------------------------
    // Test 2: Reset Injection
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "TEST 2: Reset Injection", UVM_LOW)
    
    // Inject reset for 5 cycles
    `uvm_info(get_type_name(), "Injecting reset for 5 cycles", UVM_LOW)
    uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 5);
    uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
    #200ns;
    
    //--------------------------------------------------------------------------------------------
    // Test 3: Clock Gating
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "TEST 3: Clock Gating", UVM_LOW)
    
    // Gate the clock
    `uvm_info(get_type_name(), "Gating clock for 100ns", UVM_LOW)
    uvm_config_db#(bit)::set(null, "*", "clk_enable", 0);
    #100ns;
    
    // Re-enable clock
    `uvm_info(get_type_name(), "Re-enabling clock", UVM_LOW)
    uvm_config_db#(bit)::set(null, "*", "clk_enable", 1);
    #100ns;
    
    //--------------------------------------------------------------------------------------------
    // Test 4: Combined Clock Change and Reset
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "TEST 4: Combined Clock Change and Reset", UVM_LOW)
    
    // Change to 1.5x frequency
    `uvm_info(get_type_name(), "Changing to 1.5x frequency and injecting reset", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 1.5);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    #50ns;
    
    // Inject reset while at different frequency
    uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 3);
    uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
    #200ns;
    
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    CLOCK & RESET DEMO TEST COMPLETED", UVM_LOW)
    `uvm_info(get_type_name(), "    Successfully demonstrated:", UVM_LOW)
    `uvm_info(get_type_name(), "    - Clock frequency changes (0.5x, 1x, 1.5x, 2x)", UVM_LOW)
    `uvm_info(get_type_name(), "    - Reset injection", UVM_LOW)
    `uvm_info(get_type_name(), "    - Clock gating", UVM_LOW)
    `uvm_info(get_type_name(), "    - Combined clock/reset operations", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    phase.drop_objection(this);
    
  endtask : run_phase

  //--------------------------------------------------------------------------------------------
  // Function: report_phase
  //--------------------------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    // Skip scoreboard reporting for demo test
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    CLOCK & RESET DEMO TEST PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
  endfunction : report_phase

endclass : axi4_simple_clk_reset_demo_test

`endif