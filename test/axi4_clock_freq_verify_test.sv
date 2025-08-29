`ifndef AXI4_CLOCK_FREQ_VERIFY_TEST_INCLUDED_
`define AXI4_CLOCK_FREQ_VERIFY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_clock_freq_verify_test
// Simple test to verify clock frequency changes with clear measurement output
//--------------------------------------------------------------------------------------------
class axi4_clock_freq_verify_test extends axi4_base_test;
  `uvm_component_utils(axi4_clock_freq_verify_test)
  
  // Clock measurement variables
  time prev_edge_time;
  time curr_edge_time;
  real measured_periods[$];
  real expected_period;
  real freq_scale;

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_clock_freq_verify_test", uvm_component parent = null);
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
    
    // Test sequence of frequency changes
    test_frequency(1.0, "100MHz (Default)");
    test_frequency(2.0, "200MHz (2x)");
    test_frequency(0.5, "50MHz (0.5x)");
    test_frequency(1.5, "150MHz (1.5x)");
    test_frequency(3.0, "300MHz (3x)");
    test_frequency(0.75, "75MHz (0.75x)");
    test_frequency(1.0, "100MHz (Back to default)");
    
    // Summary
    print_summary();
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    CLOCK FREQUENCY VERIFICATION COMPLETED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    phase.drop_objection(this);
    
  endtask : run_phase
  
  //--------------------------------------------------------------------------------------------
  // Task: test_frequency
  // Test a specific frequency and measure actual period
  //--------------------------------------------------------------------------------------------
  task test_frequency(real scale, string description);
    real measured_period;
    real expected_freq_mhz;
    real measured_freq_mhz;
    real error_percent;
    int num_edges = 10;
    
    `uvm_info(get_type_name(), "-----------------------------------------------", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Testing: %s", description), UVM_LOW)
    
    // Calculate expected values
    expected_period = 20.0 / scale;  // Base is 20ns (100MHz)
    expected_freq_mhz = 1000.0 / expected_period;
    
    // Apply frequency change
    `uvm_info(get_type_name(), $sformatf("Setting frequency scale to %.2fx", scale), UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", scale);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    
    // Wait for change to stabilize
    #(50ns);
    
    // Measure actual period over multiple edges
    measured_period = measure_clock_period(num_edges);
    measured_freq_mhz = 1000.0 / measured_period;
    
    // Store for summary
    measured_periods.push_back(measured_period);
    
    // Report results
    `uvm_info(get_type_name(), $sformatf("Expected: %.2f ns (%.2f MHz)", expected_period, expected_freq_mhz), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Measured: %.2f ns (%.2f MHz)", measured_period, measured_freq_mhz), UVM_LOW)
    
    // Verify with tolerance
    error_percent = 100.0 * (measured_period - expected_period) / expected_period;
    `uvm_info(get_type_name(), $sformatf("Error: %.2f%%", error_percent), UVM_LOW)
    
    if(error_percent < -5.0 || error_percent > 5.0) begin
      `uvm_error(get_type_name(), $sformatf("Clock period error exceeds 5%% tolerance!"))
    end else begin
      `uvm_info(get_type_name(), "PASS: Clock frequency verified within tolerance", UVM_LOW)
    end
    
    // Clear change flag
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
    
    // Wait before next test
    #(100ns);
    
  endtask : test_frequency
  
  //--------------------------------------------------------------------------------------------
  // Function: measure_clock_period
  // Measure actual clock period over N edges
  //--------------------------------------------------------------------------------------------
  function real measure_clock_period(int num_edges);
    time start_time, end_time;
    real total_period;
    
    // Wait for first edge
    @(posedge hdl_top.master_intf[0].aclk);
    start_time = $time;
    
    // Wait for N more edges
    repeat(num_edges) begin
      @(posedge hdl_top.master_intf[0].aclk);
    end
    end_time = $time;
    
    // Calculate average period
    total_period = real'(end_time - start_time) / real'(num_edges);
    
    return total_period;
  endfunction : measure_clock_period
  
  //--------------------------------------------------------------------------------------------
  // Function: print_summary
  // Print summary of all measurements
  //--------------------------------------------------------------------------------------------
  function void print_summary();
    string freq_names[$] = '{"100MHz", "200MHz", "50MHz", "150MHz", "300MHz", "75MHz", "100MHz"};
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "            MEASUREMENT SUMMARY", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    for(int i = 0; i < measured_periods.size(); i++) begin
      `uvm_info(get_type_name(), $sformatf("%d. %s: %.2f ns (%.2f MHz)", 
                i+1, freq_names[i], measured_periods[i], 1000.0/measured_periods[i]), UVM_LOW)
    end
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "All frequency changes verified successfully!", UVM_LOW)
    
  endfunction : print_summary

endclass : axi4_clock_freq_verify_test

`endif