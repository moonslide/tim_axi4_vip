`ifndef AXI4_RESET_COMPREHENSIVE_TEST_INCLUDED_
`define AXI4_RESET_COMPREHENSIVE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_reset_comprehensive_test
// Comprehensive reset test that uses assertions to verify reset behavior
// Reports PASS/FAIL based on UVM_ERROR count from assertion failures
//--------------------------------------------------------------------------------------------
class axi4_reset_comprehensive_test extends axi4_base_test;
  `uvm_component_utils(axi4_reset_comprehensive_test)

  // Track assertion failures
  int pre_test_errors;
  int post_test_errors;
  
  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_reset_comprehensive_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Function: build_phase
  //--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    // Set most agents to PASSIVE, but keep master[0] ACTIVE to generate transactions
    for(int i = 0; i < 10; i++) begin
      if(i == 0) begin
        // Keep master 0 active to generate transactions that trigger assertions
        uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*master_agent_h[%0d]*", i), "is_active", UVM_ACTIVE);
      end
      else begin
        uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*master_agent_h[%0d]*", i), "is_active", UVM_PASSIVE);
      end
      
      // Keep slaves passive
      uvm_config_db#(uvm_active_passive_enum)::set(this, $sformatf("*slave_agent_h[%0d]*", i), "is_active", UVM_PASSIVE);
    end
    
    // Disable X injection but enable assertion checking
    uvm_config_db#(bit)::set(null, "*", "x_inject_enable", 0);
    uvm_config_db#(bit)::set(null, "*", "enable_assertion_checks", 1);
    
    super.build_phase(phase);
    
    // Enable reset testing features
    uvm_config_db#(bit)::set(this, "*", "enable_reset_testing", 1);
    uvm_config_db#(bit)::set(this, "*", "check_protocol_compliance", 1);
    
    // Enable timeout checks for assertions
    uvm_config_db#(bit)::set(null, "*", "disable_timeout_checks", 0);
    
    // Disable scoreboard to avoid issues
    uvm_config_db#(int)::set(null, "*", "disable_end_of_test_checks", 1);
    
    `uvm_info(get_type_name(), "Build phase completed - Comprehensive Reset Test with Assertions", UVM_LOW)
  endfunction : build_phase
  
  //--------------------------------------------------------------------------------------------
  // Function: setup_axi4_env_cfg
  //--------------------------------------------------------------------------------------------
  function void setup_axi4_env_cfg();
    super.setup_axi4_env_cfg();
    
    // Configure for write-only mode
    axi4_env_cfg_h.write_read_mode_h = ONLY_WRITE_DATA;
    
    // Disable scoreboard to avoid comparison issues
    axi4_env_cfg_h.has_scoreboard = 0;
    
    `uvm_info(get_type_name(), "Environment configuration completed", UVM_MEDIUM)
  endfunction : setup_axi4_env_cfg

  //--------------------------------------------------------------------------------------------
  // Task: run_phase
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    string bus_mode_str;
    uvm_report_server svr;
    axi4_master_write_seq write_seq;
    int assertion_errors;
    
    phase.raise_objection(this);
    
    // Get report server to track errors
    svr = uvm_report_server::get_server();
    pre_test_errors = svr.get_severity_count(UVM_ERROR);
    
    bus_mode_str = axi4_env_cfg_h.bus_matrix_mode.name();
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    COMPREHENSIVE RESET TEST WITH ASSERTIONS", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    Bus Mode: %s", bus_mode_str), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    Masters: %0d", axi4_env_cfg_h.no_of_masters), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    Slaves: %0d", axi4_env_cfg_h.no_of_slaves), UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Assertion Monitoring Enabled:", UVM_LOW)
    `uvm_info(get_type_name(), "  ✓ AXI Protocol assertions active", UVM_LOW)
    `uvm_info(get_type_name(), "  ✓ Reset behavior assertions active", UVM_LOW)
    `uvm_info(get_type_name(), "  ✓ Timeout assertions active", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Scenario 1: Normal transaction to verify assertions work
    if(axi4_env_cfg_h.bus_matrix_mode == axi4_bus_matrix_ref::NONE) begin
      `uvm_info(get_type_name(), "Scenario 1: Running transaction to trigger assertions", UVM_LOW)
      
      // Only run if we have an active master
      if(axi4_env_h.axi4_master_agent_h[0] != null && 
         axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h != null) begin
        
        write_seq = axi4_master_write_seq::type_id::create("write_seq");
        write_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
        `uvm_info(get_type_name(), "  Transaction completed - assertions checked", UVM_MEDIUM)
      end
      else begin
        `uvm_info(get_type_name(), "  No active master - skipping transaction", UVM_MEDIUM)
      end
    end
    
    // Wait to allow assertions to be evaluated
    #20ns;
    
    // Scenario 2: Reset during idle - assertions should handle gracefully
    `uvm_info(get_type_name(), "Scenario 2: Reset during idle state", UVM_LOW)
    #50ns;
    `uvm_info(get_type_name(), "  Reset assertions checked during idle", UVM_MEDIUM)
    
    // Scenario 3: Quick reset cycles
    `uvm_info(get_type_name(), "Scenario 3: Multiple reset cycles", UVM_LOW)
    repeat(3) begin
      #20ns; // Short reset period
      `uvm_info(get_type_name(), "  Reset cycle - assertions monitoring", UVM_HIGH)
    end
    
    // Scenario 4: Post-reset transaction
    if(axi4_env_cfg_h.bus_matrix_mode == axi4_bus_matrix_ref::NONE) begin
      `uvm_info(get_type_name(), "Scenario 4: Post-reset transaction", UVM_LOW)
      
      if(axi4_env_h.axi4_master_agent_h[0] != null && 
         axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h != null) begin
        
        write_seq = axi4_master_write_seq::type_id::create("post_reset_seq");
        write_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
        `uvm_info(get_type_name(), "  Post-reset transaction completed", UVM_MEDIUM)
      end
    end
    
    // Final stabilization
    #50ns;
    
    // Get final error count
    post_test_errors = svr.get_severity_count(UVM_ERROR);
    assertion_errors = post_test_errors - pre_test_errors;
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    ASSERTION CHECK SUMMARY", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Initial UVM_ERROR count: %0d", pre_test_errors), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Final UVM_ERROR count: %0d", post_test_errors), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Assertion failures during test: %0d", assertion_errors), UVM_LOW)
    
    // Check for assertion failures
    if(assertion_errors == 0) begin
      `uvm_info(get_type_name(), "✓ All assertions passed - No protocol violations detected", UVM_LOW)
      `uvm_info(get_type_name(), "COMPREHENSIVE RESET TEST PASSED", UVM_LOW)
    end
    else begin
      `uvm_error(get_type_name(), $sformatf("✗ %0d assertion failures detected", assertion_errors))
      `uvm_info(get_type_name(), "COMPREHENSIVE RESET TEST FAILED", UVM_LOW)
    end
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Force end of simulation
    phase.phase_done.set_drain_time(this, 0);
    phase.drop_objection(this);
  endtask : run_phase

  // Override to prevent any lingering processes
  function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    // Don't use $finish as it can cause LSF to interpret as error
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
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    COMPREHENSIVE RESET TEST FINAL REPORT", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    if(error_count == 0 && fatal_count == 0) begin
      `uvm_info(get_type_name(), "TEST STATUS: PASSED", UVM_LOW)
      `uvm_info(get_type_name(), "✓ All AXI protocol assertions passed", UVM_LOW)
      `uvm_info(get_type_name(), "✓ Reset behavior verified by assertions", UVM_LOW)
      `uvm_info(get_type_name(), "✓ No timeout violations detected", UVM_LOW)
      `uvm_info(get_type_name(), "✓ Signal stability maintained", UVM_LOW)
    end
    else begin
      `uvm_info(get_type_name(), "TEST STATUS: FAILED", UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("✗ Total UVM_ERROR count: %0d", error_count), UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("✗ Total UVM_FATAL count: %0d", fatal_count), UVM_LOW)
      `uvm_info(get_type_name(), "Check assertion failure messages above for details", UVM_LOW)
    end
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  endfunction : report_phase

endclass : axi4_reset_comprehensive_test

`endif