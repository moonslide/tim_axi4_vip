`ifndef AXI4_FREQ_TEST_INCLUDED_
`define AXI4_FREQ_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_freq_test
// Simple test to verify frequency checker functionality
//--------------------------------------------------------------------------------------------
class axi4_freq_test extends axi4_base_test;
  `uvm_component_utils(axi4_freq_test)

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_freq_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  //--------------------------------------------------------------------------------------------
  // Function: setup_axi4_env_cfg
  //--------------------------------------------------------------------------------------------
  virtual function void setup_axi4_env_cfg();
    super.setup_axi4_env_cfg();
    
    // Enable frequency checker for this test
    axi4_env_cfg_h.has_freq_checker = 1;
    
    // Disable scoreboard as this is a frequency monitoring test
    axi4_env_cfg_h.has_scoreboard = 0;
    
    `uvm_info(get_type_name(), "Enabled frequency checker for freq test", UVM_MEDIUM)
  endfunction : setup_axi4_env_cfg

  //--------------------------------------------------------------------------------------------
  // Task: run_phase
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    int freq_change_events = 3;
    
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    FREQUENCY CHECKER TEST", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Configure expected frequency changes
    if(axi4_env_h.axi4_freq_checker_h != null) begin
      int expected_events[string];
      expected_events["2.0x"] = 1;
      expected_events["0.5x"] = 1;
      expected_events["1.0x"] = 1;
      axi4_env_h.axi4_freq_checker_h.set_expected_events(3, expected_events);
    end
    
    // Test default frequency (should be 100MHz)
    `uvm_info(get_type_name(), "Monitoring default clock frequency...", UVM_LOW)
    #100ns;
    
    // Change frequency to 2x (200MHz)
    `uvm_info(get_type_name(), "-----------------------------------------------", UVM_LOW)
    `uvm_info(get_type_name(), "Changing to 2x frequency (200MHz)...", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 2.0);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    
    #200ns;
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    // Change frequency to 0.5x (50MHz)
    `uvm_info(get_type_name(), "-----------------------------------------------", UVM_LOW)
    `uvm_info(get_type_name(), "Changing to 0.5x frequency (50MHz)...", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 0.5);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    
    #200ns;
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    // Return to normal frequency (100MHz)
    `uvm_info(get_type_name(), "-----------------------------------------------", UVM_LOW)
    `uvm_info(get_type_name(), "Returning to 1x frequency (100MHz)...", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 1.0);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    
    #200ns;
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    #100ns;
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    FREQUENCY CHECKER TEST COMPLETED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    phase.drop_objection(this);
    
  endtask : run_phase

endclass : axi4_freq_test

`endif