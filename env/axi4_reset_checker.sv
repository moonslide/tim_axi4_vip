`ifndef AXI4_RESET_CHECKER_INCLUDED_
`define AXI4_RESET_CHECKER_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_reset_checker
// Reset behavior checker - verifies reset functionality and counts errors
// Used instead of scoreboard for reset-only testing
//--------------------------------------------------------------------------------------------
class axi4_reset_checker extends uvm_component;
  `uvm_component_utils(axi4_reset_checker)
  
  // Error counters
  int unsigned uvm_error_count = 0;
  int unsigned uvm_fatal_count = 0;
  int unsigned uvm_warning_count = 0;
  
  // Reset event counters
  int unsigned master_reset_count[10];  // Track resets per master
  int unsigned slave_reset_count[10];   // Track resets per slave
  int unsigned global_reset_count = 0;
  
  // Expected reset counts (configured by test)
  int unsigned expected_master_resets[10];
  int unsigned expected_slave_resets[10];
  int unsigned expected_global_resets = 0;
  
  // Configuration
  int num_masters = 4;
  int num_slaves = 4;
  bit checker_enable = 1;
  
  // We monitor through config_db, no need for interface handles
  
  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_reset_checker", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  //--------------------------------------------------------------------------------------------
  // Function: build_phase
  //--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration
    if(!uvm_config_db#(int)::get(this, "", "num_masters", num_masters)) begin
      `uvm_info(get_type_name(), "Using default num_masters = 4", UVM_MEDIUM)
    end
    
    if(!uvm_config_db#(int)::get(this, "", "num_slaves", num_slaves)) begin
      `uvm_info(get_type_name(), "Using default num_slaves = 4", UVM_MEDIUM)
    end
    
    // Initialize counters
    for(int i = 0; i < 10; i++) begin
      master_reset_count[i] = 0;
      slave_reset_count[i] = 0;
      expected_master_resets[i] = 0;
      expected_slave_resets[i] = 0;
    end
    
    `uvm_info(get_type_name(), $sformatf("Reset Checker configured for %0d masters, %0d slaves", num_masters, num_slaves), UVM_LOW)
  endfunction : build_phase
  
  //--------------------------------------------------------------------------------------------
  // Function: connect_phase
  //--------------------------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // We monitor reset events through config_db, no interface connections needed
    `uvm_info(get_type_name(), "Reset checker will monitor reset events through config_db", UVM_MEDIUM)
  endfunction : connect_phase
  
  //--------------------------------------------------------------------------------------------
  // Task: run_phase - Monitor reset events
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    if(!checker_enable) begin
      `uvm_info(get_type_name(), "Reset checker disabled", UVM_MEDIUM)
      return;
    end
    
    `uvm_info(get_type_name(), "Starting reset event monitoring", UVM_MEDIUM)
    
    fork
      monitor_master_resets();
      monitor_slave_resets();
      monitor_global_reset();
      monitor_reset_injection_config();
    join_none
  endtask : run_phase
  
  //--------------------------------------------------------------------------------------------
  // Task: monitor_master_resets
  //--------------------------------------------------------------------------------------------
  task monitor_master_resets();
    bit reset_complete[10];
    bit prev_complete[10];
    
    forever begin
      for(int i = 0; i < num_masters; i++) begin
        // Only monitor reset completion signals (more reliable than injection flags)
        if(uvm_config_db#(bit)::get(null, "*", $sformatf("reset_complete_master_%0d", i), reset_complete[i])) begin
          if(reset_complete[i] && !prev_complete[i]) begin
            master_reset_count[i]++;
            `uvm_info(get_type_name(), $sformatf("Detected Master[%0d] reset completion #%0d", i, master_reset_count[i]), UVM_MEDIUM)
            // Clear the completion flag
            uvm_config_db#(bit)::set(null, "*", $sformatf("reset_complete_master_%0d", i), 0);
          end
          prev_complete[i] = reset_complete[i];
        end
      end
      #1ns; // Check frequently
    end
  endtask : monitor_master_resets
  
  //--------------------------------------------------------------------------------------------
  // Task: monitor_slave_resets
  //--------------------------------------------------------------------------------------------
  task monitor_slave_resets();
    bit reset_complete[10];
    bit prev_complete[10];
    
    forever begin
      for(int i = 0; i < num_slaves; i++) begin
        // Only monitor reset completion signals (more reliable than injection flags)
        if(uvm_config_db#(bit)::get(null, "*", $sformatf("reset_complete_slave_%0d", i), reset_complete[i])) begin
          if(reset_complete[i] && !prev_complete[i]) begin
            slave_reset_count[i]++;
            `uvm_info(get_type_name(), $sformatf("Detected Slave[%0d] reset completion #%0d", i, slave_reset_count[i]), UVM_MEDIUM)
            // Clear the completion flag
            uvm_config_db#(bit)::set(null, "*", $sformatf("reset_complete_slave_%0d", i), 0);
          end
          prev_complete[i] = reset_complete[i];
        end
      end
      #1ns; // Check frequently
    end
  endtask : monitor_slave_resets
  
  //--------------------------------------------------------------------------------------------
  // Task: monitor_global_reset
  //--------------------------------------------------------------------------------------------
  task monitor_global_reset();
    bit reset_complete;
    bit prev_complete;
    
    forever begin
      // Only monitor reset completion signals (more reliable than injection flags)
      if(uvm_config_db#(bit)::get(null, "*", "reset_complete_global", reset_complete)) begin
        if(reset_complete && !prev_complete) begin
          global_reset_count++;
          `uvm_info(get_type_name(), $sformatf("Detected global reset completion #%0d", global_reset_count), UVM_MEDIUM)
          // Clear the completion flag
          uvm_config_db#(bit)::set(null, "*", "reset_complete_global", 0);
        end
        prev_complete = reset_complete;
      end
      #1ns; // Check frequently
    end
  endtask : monitor_global_reset
  
  //--------------------------------------------------------------------------------------------
  // Task: monitor_reset_injection_config
  //--------------------------------------------------------------------------------------------
  task monitor_reset_injection_config();
    int reset_duration;
    
    forever begin
      // Monitor reset duration configurations
      for(int i = 0; i < num_masters; i++) begin
        if(uvm_config_db#(int)::get(null, "*", $sformatf("reset_duration_master_%0d", i), reset_duration)) begin
          if(reset_duration > 0) begin
            `uvm_info(get_type_name(), $sformatf("Master[%0d] reset duration set to %0d cycles", i, reset_duration), UVM_HIGH)
          end
        end
      end
      
      for(int i = 0; i < num_slaves; i++) begin
        if(uvm_config_db#(int)::get(null, "*", $sformatf("reset_duration_slave_%0d", i), reset_duration)) begin
          if(reset_duration > 0) begin
            `uvm_info(get_type_name(), $sformatf("Slave[%0d] reset duration set to %0d cycles", i, reset_duration), UVM_HIGH)
          end
        end
      end
      
      #100ns;
    end
  endtask : monitor_reset_injection_config
  
  //--------------------------------------------------------------------------------------------
  // Function: check_reset_behavior
  //--------------------------------------------------------------------------------------------
  function void check_reset_behavior();
    bit test_passed = 1;
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "RESET BEHAVIOR CHECK", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Check master resets
    for(int i = 0; i < num_masters; i++) begin
      if(expected_master_resets[i] > 0) begin
        if(master_reset_count[i] == expected_master_resets[i]) begin
          `uvm_info(get_type_name(), $sformatf("✓ Master[%0d]: %0d resets (PASS)", i, master_reset_count[i]), UVM_LOW)
        end else begin
          `uvm_error(get_type_name(), $sformatf("✗ Master[%0d]: Expected %0d resets, got %0d (FAIL)", 
                     i, expected_master_resets[i], master_reset_count[i]))
          uvm_error_count++;
          test_passed = 0;
        end
      end else if(master_reset_count[i] > 0) begin
        `uvm_info(get_type_name(), $sformatf("  Master[%0d]: %0d resets detected", i, master_reset_count[i]), UVM_MEDIUM)
      end
    end
    
    // Check slave resets
    for(int i = 0; i < num_slaves; i++) begin
      if(expected_slave_resets[i] > 0) begin
        if(slave_reset_count[i] == expected_slave_resets[i]) begin
          `uvm_info(get_type_name(), $sformatf("✓ Slave[%0d]: %0d resets (PASS)", i, slave_reset_count[i]), UVM_LOW)
        end else begin
          `uvm_error(get_type_name(), $sformatf("✗ Slave[%0d]: Expected %0d resets, got %0d (FAIL)", 
                     i, expected_slave_resets[i], slave_reset_count[i]))
          uvm_error_count++;
          test_passed = 0;
        end
      end else if(slave_reset_count[i] > 0) begin
        `uvm_info(get_type_name(), $sformatf("  Slave[%0d]: %0d resets detected", i, slave_reset_count[i]), UVM_MEDIUM)
      end
    end
    
    // Check global resets
    if(expected_global_resets > 0) begin
      if(global_reset_count == expected_global_resets) begin
        `uvm_info(get_type_name(), $sformatf("✓ Global: %0d resets (PASS)", global_reset_count), UVM_LOW)
      end else begin
        `uvm_error(get_type_name(), $sformatf("✗ Global: Expected %0d resets, got %0d (FAIL)", 
                   expected_global_resets, global_reset_count))
        uvm_error_count++;
        test_passed = 0;
      end
    end else if(global_reset_count > 0) begin
      `uvm_info(get_type_name(), $sformatf("  Global: %0d resets detected", global_reset_count), UVM_MEDIUM)
    end
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  endfunction : check_reset_behavior
  
  //--------------------------------------------------------------------------------------------
  // Function: set_expected_resets
  //--------------------------------------------------------------------------------------------
  function void set_expected_resets(int master_resets[10], int slave_resets[10], int global_resets);
    for(int i = 0; i < 10; i++) begin
      expected_master_resets[i] = master_resets[i];
      expected_slave_resets[i] = slave_resets[i];
    end
    expected_global_resets = global_resets;
    
    `uvm_info(get_type_name(), "Expected reset counts configured", UVM_MEDIUM)
  endfunction : set_expected_resets
  
  //--------------------------------------------------------------------------------------------
  // Function: report_phase
  //--------------------------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    if(!checker_enable) return;
    
    // Perform final checks
    check_reset_behavior();
    
    // Report final status
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "RESET CHECKER FINAL REPORT", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Total Master Resets: %0d", master_reset_count.sum()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Total Slave Resets: %0d", slave_reset_count.sum()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Total Global Resets: %0d", global_reset_count), UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Report error summary
    if(uvm_error_count == 0 && uvm_fatal_count == 0) begin
      `uvm_info(get_type_name(), "", UVM_LOW)
      `uvm_info(get_type_name(), "##########################################", UVM_LOW)
      `uvm_info(get_type_name(), "TestCase PASSED!!!", UVM_LOW)
      `uvm_info(get_type_name(), "UVM_ERROR Count: 0", UVM_LOW)
      `uvm_info(get_type_name(), "UVM_FATAL Count: 0", UVM_LOW)
      `uvm_info(get_type_name(), "##########################################", UVM_LOW)
    end else begin
      `uvm_info(get_type_name(), "", UVM_LOW)
      `uvm_info(get_type_name(), "##########################################", UVM_LOW)
      `uvm_info(get_type_name(), "TestCase ERROR!!!", UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("UVM_ERROR Count: %0d", uvm_error_count), UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("UVM_FATAL Count: %0d", uvm_fatal_count), UVM_LOW)
      `uvm_info(get_type_name(), "##########################################", UVM_LOW)
    end
  endfunction : report_phase
  
endclass : axi4_reset_checker

`endif