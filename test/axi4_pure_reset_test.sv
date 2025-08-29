`ifndef AXI4_PURE_RESET_TEST_INCLUDED_
`define AXI4_PURE_RESET_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_pure_reset_test
// Pure reset test - tests ONLY reset functionality, no transactions at all
// Works with all bus matrix modes
//--------------------------------------------------------------------------------------------
class axi4_pure_reset_test extends axi4_base_test;
  `uvm_component_utils(axi4_pure_reset_test)

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_pure_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Function: build_phase
  //--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Disable all error injection
    uvm_config_db#(bit)::set(this, "*", "error_inject", 0);
    uvm_config_db#(bit)::set(this, "*", "x_inject_enable", 0);
    
    `uvm_info(get_type_name(), "Build phase completed - Pure Reset Test", UVM_LOW)
  endfunction : build_phase

  //--------------------------------------------------------------------------------------------
  // Function: setup_axi4_env_cfg
  //--------------------------------------------------------------------------------------------
  function void setup_axi4_env_cfg();
    super.setup_axi4_env_cfg();
    
    // No transactions at all - just test reset
    axi4_env_cfg_h.write_read_mode_h = ONLY_WRITE_DATA;
    
    // Keep all agents ACTIVE for proper initialization
    // But we won't run any sequences
    
    `uvm_info(get_type_name(), "Pure reset test - no transactions will be run", UVM_MEDIUM)
  endfunction : setup_axi4_env_cfg

  //--------------------------------------------------------------------------------------------
  // Task: run_phase
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    string bus_mode_str;
    int num_masters, num_slaves;
    
    phase.raise_objection(this);
    
    // Get configuration
    bus_mode_str = axi4_env_cfg_h.bus_matrix_mode.name();
    num_masters = axi4_env_cfg_h.no_of_masters;
    num_slaves = axi4_env_cfg_h.no_of_slaves;
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "  PURE RESET TEST STARTING", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Configuration:"), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Bus Mode: %s", bus_mode_str), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Masters: %0d", num_masters), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Slaves: %0d", num_slaves), UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Initial stabilization
    #100ns;
    
    //--------------------------------------------------------------------------------------------
    // Test 1: Individual master resets
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "Test 1: Individual master resets", UVM_LOW)
    
    for(int i = 0; i < num_masters; i++) begin
      `uvm_info(get_type_name(), $sformatf("Resetting Master[%0d]", i), UVM_LOW)
      uvm_config_db#(int)::set(null, "*", $sformatf("reset_duration_master_%0d", i), 5);
      uvm_config_db#(bit)::set(null, "*", $sformatf("inject_reset_master_%0d", i), 1);
      #100ns;
    end
    
    //--------------------------------------------------------------------------------------------
    // Test 2: Individual slave resets (if not NONE mode)
    //--------------------------------------------------------------------------------------------
    if(axi4_env_cfg_h.bus_matrix_mode != axi4_bus_matrix_ref::NONE) begin
      `uvm_info(get_type_name(), "Test 2: Individual slave resets", UVM_LOW)
      
      for(int i = 0; i < num_slaves; i++) begin
        `uvm_info(get_type_name(), $sformatf("Resetting Slave[%0d]", i), UVM_LOW)
        uvm_config_db#(int)::set(null, "*", $sformatf("reset_duration_slave_%0d", i), 5);
        uvm_config_db#(bit)::set(null, "*", $sformatf("inject_reset_slave_%0d", i), 1);
        #100ns;
      end
    end
    
    //--------------------------------------------------------------------------------------------
    // Test 3: Simultaneous resets
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "Test 3: Simultaneous master resets", UVM_LOW)
    
    for(int i = 0; i < num_masters; i++) begin
      uvm_config_db#(int)::set(null, "*", $sformatf("reset_duration_master_%0d", i), 10);
      uvm_config_db#(bit)::set(null, "*", $sformatf("inject_reset_master_%0d", i), 1);
    end
    #200ns;
    
    //--------------------------------------------------------------------------------------------
    // Test 4: Global reset
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "Test 4: Global reset", UVM_LOW)
    
    uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 10);
    uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
    #200ns;
    
    //--------------------------------------------------------------------------------------------
    // Complete
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "  PURE RESET TEST COMPLETED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    phase.drop_objection(this);
    
  endtask : run_phase

  //--------------------------------------------------------------------------------------------
  // Function: report_phase
  //--------------------------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "PURE RESET TEST PASSED", UVM_LOW)
  endfunction : report_phase

endclass : axi4_pure_reset_test

`endif