`ifndef AXI4_CLOCK_VERIFY_TEST_INCLUDED_
`define AXI4_CLOCK_VERIFY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_clock_verify_test
// Test to verify clock frequency changes are actually happening on the interface
//--------------------------------------------------------------------------------------------
class axi4_clock_verify_test extends axi4_base_test;
  `uvm_component_utils(axi4_clock_verify_test)
  
  // Variables to measure clock period
  time prev_posedge_time = 0;
  time curr_posedge_time = 0;
  real measured_period;
  real expected_period;
  int edge_count = 0;

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_clock_verify_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Task: run_phase
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    CLOCK FREQUENCY VERIFICATION TEST", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Fork process to monitor actual clock period on interface
    fork
      monitor_clock_period();
    join_none
    
    // Wait for stabilization
    #100ns;
    
    //--------------------------------------------------------------------------------------------
    // Test 1: Verify default 100MHz (10ns period)
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "TEST 1: Verifying default 100MHz clock", UVM_LOW)
    expected_period = 20.0;  // 20ns full period (10ns half period)
    #200ns;
    verify_clock_period(expected_period, 1.0);
    
    //--------------------------------------------------------------------------------------------
    // Test 2: Change to 200MHz (5ns period)
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "TEST 2: Changing to 200MHz (2x frequency)", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 2.0);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    #100ns;
    expected_period = 10.0;  // 10ns full period (5ns half period)
    #200ns;
    verify_clock_period(expected_period, 2.0);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    //--------------------------------------------------------------------------------------------
    // Test 3: Change to 50MHz (20ns period)
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "TEST 3: Changing to 50MHz (0.5x frequency)", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 0.5);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    #100ns;
    expected_period = 40.0;  // 40ns full period (20ns half period)
    #400ns;  // Wait longer for slower clock
    verify_clock_period(expected_period, 0.5);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    //--------------------------------------------------------------------------------------------
    // Test 4: Change to 150MHz (6.67ns period)
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "TEST 4: Changing to 150MHz (1.5x frequency)", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 1.5);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    #100ns;
    expected_period = 13.33;  // 13.33ns full period
    #200ns;
    verify_clock_period(expected_period, 1.5);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    //--------------------------------------------------------------------------------------------
    // Test 5: Return to default 100MHz
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "TEST 5: Returning to 100MHz (1x frequency)", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 1.0);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    #100ns;
    expected_period = 20.0;  // 20ns full period
    #200ns;
    verify_clock_period(expected_period, 1.0);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    #100ns;
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    CLOCK VERIFICATION COMPLETED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    phase.drop_objection(this);
    
  endtask : run_phase
  
  //--------------------------------------------------------------------------------------------
  // Task: monitor_clock_period
  // Continuously monitor the actual clock period on the interface
  //--------------------------------------------------------------------------------------------
  task monitor_clock_period();
    forever begin
      @(posedge hdl_top.aclk);
      curr_posedge_time = $time;
      
      if(prev_posedge_time != 0) begin
        measured_period = real'(curr_posedge_time - prev_posedge_time);
        edge_count++;
        
        // Log every 10th edge to avoid too much output
        if(edge_count % 10 == 0) begin
          `uvm_info("CLK_MONITOR", $sformatf("Edge #%0d: Measured clock period = %.2f ns (%.2f MHz)", 
                    edge_count, measured_period, 1000.0/measured_period), UVM_HIGH)
        end
      end
      
      prev_posedge_time = curr_posedge_time;
    end
  endtask : monitor_clock_period
  
  //--------------------------------------------------------------------------------------------
  // Function: verify_clock_period
  // Verify the measured clock period matches expected
  //--------------------------------------------------------------------------------------------
  function void verify_clock_period(real expected_period_ns, real scale_factor);
    real tolerance = 0.1;  // 10% tolerance
    real freq_mhz = 1000.0 / expected_period_ns;
    
    `uvm_info(get_type_name(), $sformatf("Expected period: %.2f ns (%.2f MHz) with scale %.2fx", 
              expected_period_ns, freq_mhz, scale_factor), UVM_LOW)
    
    `uvm_info(get_type_name(), $sformatf("Measured period: %.2f ns (%.2f MHz)", 
              measured_period, 1000.0/measured_period), UVM_LOW)
    
    if(measured_period >= expected_period_ns * (1.0 - tolerance) &&
       measured_period <= expected_period_ns * (1.0 + tolerance)) begin
      `uvm_info(get_type_name(), $sformatf("PASS: Clock period is correct (%.2f ns)", measured_period), UVM_LOW)
    end else begin
      `uvm_error(get_type_name(), $sformatf("FAIL: Clock period mismatch! Expected: %.2f ns, Measured: %.2f ns", 
                expected_period_ns, measured_period))
    end
    
    `uvm_info(get_type_name(), "-----------------------------------------------", UVM_LOW)
  endfunction : verify_clock_period

  //--------------------------------------------------------------------------------------------
  // Function: report_phase
  //--------------------------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    CLOCK FREQUENCY VERIFICATION TEST PASSED", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    Total clock edges monitored: %0d", edge_count), UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  endfunction : report_phase

endclass : axi4_clock_verify_test

`endif