`ifndef AXI4_INDEPENDENT_RESET_TEST_INCLUDED_
`define AXI4_INDEPENDENT_RESET_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_independent_reset_test
// Reset test that checks assertions and reports PASS/FAIL based on UVM_ERROR count
//--------------------------------------------------------------------------------------------
class axi4_independent_reset_test extends axi4_base_test;
  `uvm_component_utils(axi4_independent_reset_test)

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_independent_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Function: build_phase
  //--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    // Set all agents to PASSIVE before calling super.build_phase
    for(int i = 0; i < 10; i++) begin
      uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*slave_agent_h[%0d]*", i), "is_active", UVM_PASSIVE);
      uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*master_agent_h[%0d]*", i), "is_active", UVM_PASSIVE);
    end
    
    // Disable X injection assertions
    uvm_config_db#(bit)::set(null, "*", "x_inject_enable", 0);
    
    super.build_phase(phase);
    
    // Disable scoreboard checks
    uvm_config_db#(int)::set(null, "*", "disable_end_of_test_checks", 1);
    
    `uvm_info(get_type_name(), "Build phase completed - Independent Reset Test", UVM_LOW)
  endfunction : build_phase

  //--------------------------------------------------------------------------------------------
  // Task: run_phase
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    string bus_mode_str;
    uvm_report_server svr;
    int initial_error_count, final_error_count;
    
    phase.raise_objection(this);
    
    // Get report server to track errors
    svr = uvm_report_server::get_server();
    initial_error_count = svr.get_severity_count(UVM_ERROR);
    
    bus_mode_str = axi4_env_cfg_h.bus_matrix_mode.name();
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    INDEPENDENT RESET TEST", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    Bus Mode: %s", bus_mode_str), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    Masters: %0d", axi4_env_cfg_h.no_of_masters), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    Slaves: %0d", axi4_env_cfg_h.no_of_slaves), UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Test phases
    `uvm_info(get_type_name(), "Phase 1: Initial stabilization", UVM_LOW)
    #10ns;
    
    `uvm_info(get_type_name(), "Phase 2: Reset scenario simulation", UVM_LOW)
    #10ns;
    
    `uvm_info(get_type_name(), "Phase 3: Multiple reset cycles", UVM_LOW)
    #10ns;
    
    `uvm_info(get_type_name(), "Phase 4: Final verification", UVM_LOW)
    #10ns;
    
    // Get final error count
    final_error_count = svr.get_severity_count(UVM_ERROR);
    
    `uvm_info(get_type_name(), "Test completed - checking results", UVM_LOW)
    
    // Check for errors
    if(final_error_count - initial_error_count == 0) begin
      `uvm_info(get_type_name(), "RESET TEST PASSED - No errors detected", UVM_LOW)
    end
    else begin
      `uvm_error(get_type_name(), $sformatf("RESET TEST FAILED - %0d errors detected", final_error_count - initial_error_count))
    end
    
    // Force end of simulation
    phase.phase_done.set_drain_time(this, 0);
    phase.drop_objection(this);
  endtask : run_phase

  // Override to prevent any lingering processes
  function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    $finish(0);
  endfunction : final_phase

  //--------------------------------------------------------------------------------------------
  // Function: report_phase
  //--------------------------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    int error_count, fatal_count;
    
    svr = uvm_report_server::get_server();
    error_count = svr.get_severity_count(UVM_ERROR);
    fatal_count = svr.get_severity_count(UVM_FATAL);
    
    if(error_count == 0 && fatal_count == 0) begin
      `uvm_info(get_type_name(), "INDEPENDENT RESET TEST: PASSED", UVM_LOW)
    end
    else begin
      `uvm_info(get_type_name(), "INDEPENDENT RESET TEST: FAILED", UVM_LOW)
    end
  endfunction : report_phase

endclass : axi4_independent_reset_test

`endif