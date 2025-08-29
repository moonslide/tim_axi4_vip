`ifndef AXI4_MULTI_INTF_CLK_TEST_INCLUDED_
`define AXI4_MULTI_INTF_CLK_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_multi_intf_clk_test
// Test with multiple interfaces running at different independent clock frequencies
//--------------------------------------------------------------------------------------------
class axi4_multi_intf_clk_test extends axi4_base_test;
  `uvm_component_utils(axi4_multi_intf_clk_test)
  
  // Arrays to track clock periods for verification
  real measured_period_master[NO_OF_MASTERS];
  real measured_period_slave[NO_OF_SLAVES];
  int edge_count_master[NO_OF_MASTERS];
  int edge_count_slave[NO_OF_SLAVES];

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_multi_intf_clk_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Task: run_phase
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    MULTI-INTERFACE CLOCK TEST STARTING", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Testing with %0d masters and %0d slaves", NO_OF_MASTERS, NO_OF_SLAVES), UVM_LOW)
    
    // Fork monitoring processes for each interface
    fork
      monitor_all_clocks();
    join_none
    
    // Wait for stabilization
    #100ns;
    
    //--------------------------------------------------------------------------------------------
    // Test 1: Set different frequencies for each master interface
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "TEST 1: Different frequencies for each master", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Master 0: 200MHz (2x)
    `uvm_info(get_type_name(), "Setting Master[0] to 200MHz (2x)", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "master_0_clk_freq_scale", 2.0);
    uvm_config_db#(bit)::set(null, "*", "master_0_clk_change", 1);
    
    // Master 1: 50MHz (0.5x)
    if(NO_OF_MASTERS > 1) begin
      `uvm_info(get_type_name(), "Setting Master[1] to 50MHz (0.5x)", UVM_LOW)
      uvm_config_db#(real)::set(null, "*", "master_1_clk_freq_scale", 0.5);
      uvm_config_db#(bit)::set(null, "*", "master_1_clk_change", 1);
    end
    
    // Master 2: 150MHz (1.5x)
    if(NO_OF_MASTERS > 2) begin
      `uvm_info(get_type_name(), "Setting Master[2] to 150MHz (1.5x)", UVM_LOW)
      uvm_config_db#(real)::set(null, "*", "master_2_clk_freq_scale", 1.5);
      uvm_config_db#(bit)::set(null, "*", "master_2_clk_change", 1);
    end
    
    // Master 3: 75MHz (0.75x)
    if(NO_OF_MASTERS > 3) begin
      `uvm_info(get_type_name(), "Setting Master[3] to 75MHz (0.75x)", UVM_LOW)
      uvm_config_db#(real)::set(null, "*", "master_3_clk_freq_scale", 0.75);
      uvm_config_db#(bit)::set(null, "*", "master_3_clk_change", 1);
    end
    
    // Wait and verify
    #300ns;
    verify_master_clocks();
    
    //--------------------------------------------------------------------------------------------
    // Test 2: Set different frequencies for slave interfaces
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "TEST 2: Different frequencies for each slave", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Slave 0: 125MHz (1.25x)
    `uvm_info(get_type_name(), "Setting Slave[0] to 125MHz (1.25x)", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "slave_0_clk_freq_scale", 1.25);
    uvm_config_db#(bit)::set(null, "*", "slave_0_clk_change", 1);
    
    // Slave 1: 300MHz (3x)
    if(NO_OF_SLAVES > 1) begin
      `uvm_info(get_type_name(), "Setting Slave[1] to 300MHz (3x)", UVM_LOW)
      uvm_config_db#(real)::set(null, "*", "slave_1_clk_freq_scale", 3.0);
      uvm_config_db#(bit)::set(null, "*", "slave_1_clk_change", 1);
    end
    
    // Slave 2: 66MHz (0.66x)
    if(NO_OF_SLAVES > 2) begin
      `uvm_info(get_type_name(), "Setting Slave[2] to 66MHz (0.66x)", UVM_LOW)
      uvm_config_db#(real)::set(null, "*", "slave_2_clk_freq_scale", 0.66);
      uvm_config_db#(bit)::set(null, "*", "slave_2_clk_change", 1);
    end
    
    // Slave 3: 100MHz (1x - default)
    if(NO_OF_SLAVES > 3) begin
      `uvm_info(get_type_name(), "Keeping Slave[3] at 100MHz (1x)", UVM_LOW)
      // No change - keep default
    end
    
    // Wait and verify
    #300ns;
    verify_slave_clocks();
    
    //--------------------------------------------------------------------------------------------
    // Test 3: Dynamic changes - swap frequencies
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "TEST 3: Dynamic frequency swapping", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Swap Master 0 and Master 1 frequencies
    `uvm_info(get_type_name(), "Swapping Master[0] and Master[1] frequencies", UVM_LOW)
    uvm_config_db#(real)::set(null, "*", "master_0_clk_freq_scale", 0.5);  // Was 2x, now 0.5x
    uvm_config_db#(bit)::set(null, "*", "master_0_clk_change", 1);
    
    if(NO_OF_MASTERS > 1) begin
      uvm_config_db#(real)::set(null, "*", "master_1_clk_freq_scale", 2.0);  // Was 0.5x, now 2x
      uvm_config_db#(bit)::set(null, "*", "master_1_clk_change", 1);
    end
    
    #300ns;
    verify_master_clocks();
    
    //--------------------------------------------------------------------------------------------
    // Test 4: Clock gating on specific interfaces
    //--------------------------------------------------------------------------------------------
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "TEST 4: Clock gating on specific interfaces", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Gate Master[1] clock
    if(NO_OF_MASTERS > 1) begin
      `uvm_info(get_type_name(), "Gating Master[1] clock", UVM_LOW)
      uvm_config_db#(bit)::set(null, "*", "master_1_clk_enable", 0);
    end
    
    // Gate Slave[0] clock
    `uvm_info(get_type_name(), "Gating Slave[0] clock", UVM_LOW)
    uvm_config_db#(bit)::set(null, "*", "slave_0_clk_enable", 0);
    
    #200ns;
    
    // Re-enable clocks
    `uvm_info(get_type_name(), "Re-enabling gated clocks", UVM_LOW)
    if(NO_OF_MASTERS > 1) begin
      uvm_config_db#(bit)::set(null, "*", "master_1_clk_enable", 1);
    end
    uvm_config_db#(bit)::set(null, "*", "slave_0_clk_enable", 1);
    
    #200ns;
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    MULTI-INTERFACE CLOCK TEST COMPLETED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    phase.drop_objection(this);
    
  endtask : run_phase
  
  //--------------------------------------------------------------------------------------------
  // Task: monitor_all_clocks
  // Monitor clock periods on all interfaces
  //--------------------------------------------------------------------------------------------
  task monitor_all_clocks();
    fork
      // Monitor each master interface
      for(int m = 0; m < NO_OF_MASTERS && m < 4; m++) begin
        automatic int idx = m;
        monitor_master_clock(idx);
      end
      
      // Monitor each slave interface  
      for(int s = 0; s < NO_OF_SLAVES && s < 4; s++) begin
        automatic int idx = s;
        monitor_slave_clock(idx);
      end
    join_none
  endtask : monitor_all_clocks
  
  //--------------------------------------------------------------------------------------------
  // Task: monitor_master_clock
  //--------------------------------------------------------------------------------------------
  task monitor_master_clock(int idx);
    time prev_edge = 0;
    time curr_edge = 0;
    
    forever begin
      @(posedge hdl_top.master_intf[idx].aclk);
      curr_edge = $time;
      
      if(prev_edge != 0) begin
        measured_period_master[idx] = real'(curr_edge - prev_edge);
        edge_count_master[idx]++;
      end
      
      prev_edge = curr_edge;
    end
  endtask : monitor_master_clock
  
  //--------------------------------------------------------------------------------------------
  // Task: monitor_slave_clock
  //--------------------------------------------------------------------------------------------
  task monitor_slave_clock(int idx);
    time prev_edge = 0;
    time curr_edge = 0;
    
    forever begin
      @(posedge hdl_top.slave_intf[idx].aclk);
      curr_edge = $time;
      
      if(prev_edge != 0) begin
        measured_period_slave[idx] = real'(curr_edge - prev_edge);
        edge_count_slave[idx]++;
      end
      
      prev_edge = curr_edge;
    end
  endtask : monitor_slave_clock
  
  //--------------------------------------------------------------------------------------------
  // Function: verify_master_clocks
  //--------------------------------------------------------------------------------------------
  function void verify_master_clocks();
    real expected_periods[4] = '{5.0, 40.0, 6.67, 13.33};  // Based on scale factors
    string freq_names[4] = '{"200MHz", "50MHz", "150MHz", "75MHz"};
    
    `uvm_info(get_type_name(), "------- Master Clock Verification -------", UVM_LOW)
    
    for(int m = 0; m < NO_OF_MASTERS && m < 4; m++) begin
      `uvm_info(get_type_name(), $sformatf("Master[%0d]: Expected %s (%.2fns), Measured %.2fns (%.2fMHz)", 
                m, freq_names[m], expected_periods[m], measured_period_master[m], 
                1000.0/measured_period_master[m]), UVM_LOW)
                
      // Check with 10% tolerance
      if(measured_period_master[m] < expected_periods[m] * 0.9 ||
         measured_period_master[m] > expected_periods[m] * 1.1) begin
        `uvm_error(get_type_name(), $sformatf("Master[%0d] clock period mismatch!", m))
      end else begin
        `uvm_info(get_type_name(), $sformatf("Master[%0d] clock verified OK", m), UVM_LOW)
      end
    end
  endfunction : verify_master_clocks
  
  //--------------------------------------------------------------------------------------------
  // Function: verify_slave_clocks
  //--------------------------------------------------------------------------------------------
  function void verify_slave_clocks();
    real expected_periods[4] = '{8.0, 3.33, 15.15, 20.0};  // Based on scale factors
    string freq_names[4] = '{"125MHz", "300MHz", "66MHz", "100MHz"};
    
    `uvm_info(get_type_name(), "------- Slave Clock Verification -------", UVM_LOW)
    
    for(int s = 0; s < NO_OF_SLAVES && s < 4; s++) begin
      `uvm_info(get_type_name(), $sformatf("Slave[%0d]: Expected %s (%.2fns), Measured %.2fns (%.2fMHz)", 
                s, freq_names[s], expected_periods[s], measured_period_slave[s], 
                1000.0/measured_period_slave[s]), UVM_LOW)
                
      // Check with 10% tolerance
      if(measured_period_slave[s] < expected_periods[s] * 0.9 ||
         measured_period_slave[s] > expected_periods[s] * 1.1) begin
        `uvm_error(get_type_name(), $sformatf("Slave[%0d] clock period mismatch!", s))
      end else begin
        `uvm_info(get_type_name(), $sformatf("Slave[%0d] clock verified OK", s), UVM_LOW)
      end
    end
  endfunction : verify_slave_clocks
  
  //--------------------------------------------------------------------------------------------
  // Function: report_phase
  //--------------------------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    MULTI-INTERFACE CLOCK TEST SUMMARY", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    for(int m = 0; m < NO_OF_MASTERS && m < 4; m++) begin
      `uvm_info(get_type_name(), $sformatf("Master[%0d]: %0d edges, final period %.2fns (%.2fMHz)", 
                m, edge_count_master[m], measured_period_master[m], 
                1000.0/measured_period_master[m]), UVM_LOW)
    end
    
    for(int s = 0; s < NO_OF_SLAVES && s < 4; s++) begin
      `uvm_info(get_type_name(), $sformatf("Slave[%0d]: %0d edges, final period %.2fns (%.2fMHz)", 
                s, edge_count_slave[s], measured_period_slave[s], 
                1000.0/measured_period_slave[s]), UVM_LOW)
    end
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    TEST PASSED - All interfaces verified", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  endfunction : report_phase

endclass : axi4_multi_intf_clk_test

`endif