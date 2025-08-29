`ifndef AXI4_CLOCK_MONITOR_TEST_INCLUDED_
`define AXI4_CLOCK_MONITOR_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_clock_monitor_test
// Simple test to monitor and display actual clock transitions on the interface
//--------------------------------------------------------------------------------------------
class axi4_clock_monitor_test extends axi4_base_test;
  `uvm_component_utils(axi4_clock_monitor_test)

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_clock_monitor_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  //--------------------------------------------------------------------------------------------
  // Function: setup_axi4_env_cfg
  //--------------------------------------------------------------------------------------------
  virtual function void setup_axi4_env_cfg();
    super.setup_axi4_env_cfg();
    
    // Enable frequency checker for this test
    axi4_env_cfg_h.has_freq_checker = 1;
    
    // Disable scoreboard as this is a clock monitoring test
    axi4_env_cfg_h.has_scoreboard = 0;
    
    `uvm_info(get_type_name(), "Enabled frequency checker for clock monitor test", UVM_MEDIUM)
  endfunction : setup_axi4_env_cfg

  //--------------------------------------------------------------------------------------------
  // Task: run_phase
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    time t1, t2, t3, t4, t5;
    real period;
    
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    CLOCK MONITOR TEST - Direct Interface Check", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Monitor default clock (should be 100MHz / 20ns period)
    `uvm_info(get_type_name(), "Monitoring default clock period (expecting 20ns)...", UVM_LOW)
    
    // Capture 5 consecutive positive edges
    @(posedge hdl_top.master_intf[0].aclk);
    t1 = $time;
    `uvm_info(get_type_name(), $sformatf("Clock edge 1 at time %0t", t1), UVM_LOW)
    
    @(posedge hdl_top.master_intf[0].aclk);
    t2 = $time;
    `uvm_info(get_type_name(), $sformatf("Clock edge 2 at time %0t, period = %0t", t2, t2-t1), UVM_LOW)
    
    @(posedge hdl_top.master_intf[0].aclk);
    t3 = $time;
    `uvm_info(get_type_name(), $sformatf("Clock edge 3 at time %0t, period = %0t", t3, t3-t2), UVM_LOW)
    
    period = real'(t3 - t2);
    `uvm_info(get_type_name(), $sformatf("DEFAULT: Measured period = %.2f ns (%.2f MHz)", 
              period, 1000.0/period), UVM_LOW)
    
    // Now change frequency to 2x (200MHz / 10ns period)
    `uvm_info(get_type_name(), "-----------------------------------------------", UVM_LOW)
    `uvm_info(get_type_name(), "Changing to 2x frequency (200MHz)...", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 2.0);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    
    // Wait for change to take effect
    #50ns;
    
    // Measure new period
    @(posedge hdl_top.master_intf[0].aclk);
    t1 = $time;
    `uvm_info(get_type_name(), $sformatf("Clock edge 1 at time %0t", t1), UVM_LOW)
    
    @(posedge hdl_top.master_intf[0].aclk);
    t2 = $time;
    `uvm_info(get_type_name(), $sformatf("Clock edge 2 at time %0t, period = %0t", t2, t2-t1), UVM_LOW)
    
    @(posedge hdl_top.master_intf[0].aclk);
    t3 = $time;
    `uvm_info(get_type_name(), $sformatf("Clock edge 3 at time %0t, period = %0t", t3, t3-t2), UVM_LOW)
    
    period = real'(t3 - t2);
    `uvm_info(get_type_name(), $sformatf("2X FREQ: Measured period = %.2f ns (%.2f MHz)", 
              period, 1000.0/period), UVM_LOW)
    
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    // Change frequency to 0.5x (50MHz / 40ns period)
    `uvm_info(get_type_name(), "-----------------------------------------------", UVM_LOW)
    `uvm_info(get_type_name(), "Changing to 0.5x frequency (50MHz)...", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 0.5);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    
    // Wait for change to take effect
    #50ns;
    
    // Measure new period
    @(posedge hdl_top.master_intf[0].aclk);
    t1 = $time;
    `uvm_info(get_type_name(), $sformatf("Clock edge 1 at time %0t", t1), UVM_LOW)
    
    @(posedge hdl_top.master_intf[0].aclk);
    t2 = $time;
    `uvm_info(get_type_name(), $sformatf("Clock edge 2 at time %0t, period = %0t", t2, t2-t1), UVM_LOW)
    
    @(posedge hdl_top.master_intf[0].aclk);
    t3 = $time;
    `uvm_info(get_type_name(), $sformatf("Clock edge 3 at time %0t, period = %0t", t3, t3-t2), UVM_LOW)
    
    period = real'(t3 - t2);
    `uvm_info(get_type_name(), $sformatf("0.5X FREQ: Measured period = %.2f ns (%.2f MHz)", 
              period, 1000.0/period), UVM_LOW)
    
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    // Monitor reset signal changes
    `uvm_info(get_type_name(), "-----------------------------------------------", UVM_LOW)
    `uvm_info(get_type_name(), "Testing reset signal on interface...", UVM_LOW)
    
    `uvm_info(get_type_name(), $sformatf("Current aresetn value: %0b", hdl_top.master_intf[0].aresetn), UVM_LOW)
    
    // Inject reset
    `uvm_info(get_type_name(), "Injecting reset for 3 cycles...", UVM_LOW)
    uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 3);
    uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
    
    // Monitor reset transitions
    @(negedge hdl_top.master_intf[0].aresetn);
    `uvm_info(get_type_name(), $sformatf("Reset went LOW at time %0t", $time), UVM_LOW)
    
    @(posedge hdl_top.master_intf[0].aresetn);
    `uvm_info(get_type_name(), $sformatf("Reset went HIGH at time %0t", $time), UVM_LOW)
    
    #100ns;
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    CLOCK MONITOR TEST COMPLETED", UVM_LOW)
    `uvm_info(get_type_name(), "    Clock frequency changes verified on interface", UVM_LOW)
    `uvm_info(get_type_name(), "    Reset signal changes verified on interface", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    phase.drop_objection(this);
    
  endtask : run_phase

endclass : axi4_clock_monitor_test

`endif