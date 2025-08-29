`ifndef AXI4_FREQ_CHECKER_INCLUDED_
`define AXI4_FREQ_CHECKER_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_freq_checker
// Clock frequency behavior checker - verifies clock frequency changes and counts events
// Monitors clock period changes and validates against expected frequency scaling
//--------------------------------------------------------------------------------------------
class axi4_freq_checker extends uvm_component;
  `uvm_component_utils(axi4_freq_checker)
  
  // Error counters
  int unsigned uvm_error_count = 0;
  int unsigned uvm_fatal_count = 0;
  int unsigned uvm_warning_count = 0;
  
  // Frequency change event counters
  int unsigned freq_change_count = 0;
  int unsigned freq_scale_events[string];  // Track events by scale factor
  
  // Expected frequency changes (configured by test)
  int unsigned expected_freq_changes = 0;
  int unsigned expected_scale_events[string];
  
  // Current and previous frequency measurements
  real current_freq_mhz = 100.0;  // Default 100MHz
  real previous_freq_mhz = 100.0;
  real current_period_ns = 10.0;  // Default 10ns
  real nominal_freq_mhz = 100.0;  // Nominal frequency
  
  // Configuration
  bit checker_enable = 1;
  real tolerance_percent = 5.0;  // Frequency measurement tolerance
  
  // Virtual interface for clock monitoring
  virtual axi4_if vif;
  
  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_freq_checker", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  //--------------------------------------------------------------------------------------------
  // Function: build_phase
  //--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface
    if(!uvm_config_db#(virtual axi4_if)::get(this, "", "vif", vif)) begin
      `uvm_info(get_type_name(), "No virtual interface provided, will monitor through config_db", UVM_MEDIUM)
    end
    
    // Get configuration
    if(!uvm_config_db#(real)::get(this, "", "nominal_freq_mhz", nominal_freq_mhz)) begin
      `uvm_info(get_type_name(), "Using default nominal frequency = 100MHz", UVM_MEDIUM)
    end
    
    if(!uvm_config_db#(real)::get(this, "", "tolerance_percent", tolerance_percent)) begin
      `uvm_info(get_type_name(), "Using default tolerance = 5%", UVM_MEDIUM)
    end
    
    // Initialize frequency scale event counters
    freq_scale_events["0.5x"] = 0;
    freq_scale_events["0.75x"] = 0;
    freq_scale_events["1.0x"] = 0;
    freq_scale_events["1.25x"] = 0;
    freq_scale_events["1.5x"] = 0;
    freq_scale_events["2.0x"] = 0;
    freq_scale_events["3.0x"] = 0;
    
    expected_scale_events["0.5x"] = 0;
    expected_scale_events["0.75x"] = 0;
    expected_scale_events["1.0x"] = 0;
    expected_scale_events["1.25x"] = 0;
    expected_scale_events["1.5x"] = 0;
    expected_scale_events["2.0x"] = 0;
    expected_scale_events["3.0x"] = 0;
    
    `uvm_info(get_type_name(), $sformatf("Frequency Checker configured with nominal freq = %.1fMHz, tolerance = %.1f%%", 
              nominal_freq_mhz, tolerance_percent), UVM_LOW)
  endfunction : build_phase
  
  //--------------------------------------------------------------------------------------------
  // Function: connect_phase
  //--------------------------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    `uvm_info(get_type_name(), "Frequency checker will monitor clock frequency changes", UVM_MEDIUM)
  endfunction : connect_phase
  
  //--------------------------------------------------------------------------------------------
  // Task: run_phase - Monitor frequency changes
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    if(!checker_enable) begin
      `uvm_info(get_type_name(), "Frequency checker disabled", UVM_MEDIUM)
      return;
    end
    
    `uvm_info(get_type_name(), "Starting frequency change monitoring", UVM_MEDIUM)
    
    fork
      monitor_freq_changes();
      monitor_clock_period();
    join_none
  endtask : run_phase
  
  //--------------------------------------------------------------------------------------------
  // Task: monitor_freq_changes
  //--------------------------------------------------------------------------------------------
  task monitor_freq_changes();
    bit freq_change_active;
    bit prev_active;
    real freq_scale;
    string scale_str;
    real expected_freq;
    
    forever begin
      // Check config_db for frequency change events
      if(uvm_config_db#(bit)::get(null, "*", "clk_freq_change_active", freq_change_active)) begin
        if(freq_change_active && !prev_active) begin
          // Frequency change started
          if(uvm_config_db#(real)::get(null, "*", "clk_freq_scale", freq_scale)) begin
            freq_change_count++;
            scale_str = get_scale_string(freq_scale);
            freq_scale_events[scale_str]++;
            
            `uvm_info(get_type_name(), $sformatf("Detected frequency change #%0d to %s (%.2fx)", 
                      freq_change_count, scale_str, freq_scale), UVM_MEDIUM)
            
            // Calculate expected frequency
            expected_freq = nominal_freq_mhz * freq_scale;
            
            // Wait for frequency to stabilize
            #100ns;
            
            // Verify actual frequency matches expected
            if(vif != null) begin
              measure_clock_frequency();
              check_frequency_accuracy(expected_freq);
            end
          end
        end
        prev_active = freq_change_active;
      end
      #10ns;
    end
  endtask : monitor_freq_changes
  
  //--------------------------------------------------------------------------------------------
  // Task: monitor_clock_period
  //--------------------------------------------------------------------------------------------
  task monitor_clock_period();
    if(vif == null) begin
      `uvm_info(get_type_name(), "No virtual interface, skipping period monitoring", UVM_MEDIUM)
      return;
    end
    
    forever begin
      measure_clock_frequency();
      #1us;  // Measure every microsecond
    end
  endtask : monitor_clock_period
  
  //--------------------------------------------------------------------------------------------
  // Task: measure_clock_frequency
  //--------------------------------------------------------------------------------------------
  task measure_clock_frequency();
    time t1, t2;
    real period_ns;
    real freq_mhz;
    
    if(vif == null) return;
    
    // Measure clock period
    @(posedge vif.aclk);
    t1 = $time;
    @(posedge vif.aclk);
    t2 = $time;
    
    period_ns = real'(t2 - t1) / 1000.0;  // Convert to ns
    freq_mhz = 1000.0 / period_ns;  // Convert to MHz
    
    // Update current measurements
    previous_freq_mhz = current_freq_mhz;
    current_freq_mhz = freq_mhz;
    current_period_ns = period_ns;
    
    `uvm_info(get_type_name(), $sformatf("Measured: Period = %.2f ns, Frequency = %.2f MHz", 
              period_ns, freq_mhz), UVM_HIGH)
  endtask : measure_clock_frequency
  
  //--------------------------------------------------------------------------------------------
  // Function: check_frequency_accuracy
  //--------------------------------------------------------------------------------------------
  function void check_frequency_accuracy(real expected_freq_mhz);
    real error_percent;
    
    error_percent = 100.0 * (current_freq_mhz - expected_freq_mhz) / expected_freq_mhz;
    
    if(error_percent < 0) error_percent = -error_percent;  // Absolute value
    
    if(error_percent <= tolerance_percent) begin
      `uvm_info(get_type_name(), $sformatf("✓ Frequency accurate: Expected %.2f MHz, Got %.2f MHz (%.1f%% error)", 
                expected_freq_mhz, current_freq_mhz, error_percent), UVM_LOW)
    end else begin
      `uvm_error(get_type_name(), $sformatf("✗ Frequency inaccurate: Expected %.2f MHz, Got %.2f MHz (%.1f%% error > %.1f%% tolerance)", 
                 expected_freq_mhz, current_freq_mhz, error_percent, tolerance_percent))
      uvm_error_count++;
    end
  endfunction : check_frequency_accuracy
  
  //--------------------------------------------------------------------------------------------
  // Function: get_scale_string
  //--------------------------------------------------------------------------------------------
  function string get_scale_string(real scale);
    if(scale <= 0.6) return "0.5x";
    else if(scale <= 0.85) return "0.75x";
    else if(scale <= 1.15) return "1.0x";
    else if(scale <= 1.35) return "1.25x";
    else if(scale <= 1.75) return "1.5x";
    else if(scale <= 2.5) return "2.0x";
    else return "3.0x";
  endfunction : get_scale_string
  
  //--------------------------------------------------------------------------------------------
  // Function: check_freq_behavior
  //--------------------------------------------------------------------------------------------
  function void check_freq_behavior();
    bit test_passed = 1;
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "FREQUENCY BEHAVIOR CHECK", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Check total frequency changes
    if(expected_freq_changes > 0) begin
      if(freq_change_count == expected_freq_changes) begin
        `uvm_info(get_type_name(), $sformatf("✓ Total frequency changes: %0d (PASS)", freq_change_count), UVM_LOW)
      end else begin
        `uvm_error(get_type_name(), $sformatf("✗ Total frequency changes: Expected %0d, got %0d (FAIL)", 
                   expected_freq_changes, freq_change_count))
        uvm_error_count++;
        test_passed = 0;
      end
    end else if(freq_change_count > 0) begin
      `uvm_info(get_type_name(), $sformatf("  Total frequency changes detected: %0d", freq_change_count), UVM_MEDIUM)
    end
    
    // Check individual scale events
    foreach(expected_scale_events[scale]) begin
      if(expected_scale_events[scale] > 0) begin
        if(freq_scale_events[scale] == expected_scale_events[scale]) begin
          `uvm_info(get_type_name(), $sformatf("✓ %s events: %0d (PASS)", scale, freq_scale_events[scale]), UVM_LOW)
        end else begin
          `uvm_error(get_type_name(), $sformatf("✗ %s events: Expected %0d, got %0d (FAIL)", 
                     scale, expected_scale_events[scale], freq_scale_events[scale]))
          uvm_error_count++;
          test_passed = 0;
        end
      end else if(freq_scale_events[scale] > 0) begin
        `uvm_info(get_type_name(), $sformatf("  %s events detected: %0d", scale, freq_scale_events[scale]), UVM_MEDIUM)
      end
    end
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  endfunction : check_freq_behavior
  
  //--------------------------------------------------------------------------------------------
  // Function: set_expected_events
  //--------------------------------------------------------------------------------------------
  function void set_expected_events(int total_changes, int scale_events[string]);
    expected_freq_changes = total_changes;
    foreach(scale_events[scale]) begin
      expected_scale_events[scale] = scale_events[scale];
    end
    
    `uvm_info(get_type_name(), "Expected frequency change counts configured", UVM_MEDIUM)
  endfunction : set_expected_events
  
  //--------------------------------------------------------------------------------------------
  // Function: report_phase
  //--------------------------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    if(!checker_enable) return;
    
    // Perform final checks
    check_freq_behavior();
    
    // Report final status
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "FREQUENCY CHECKER FINAL REPORT", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Total Frequency Changes: %0d", freq_change_count), UVM_LOW)
    
    // Report scale events
    foreach(freq_scale_events[scale]) begin
      if(freq_scale_events[scale] > 0) begin
        `uvm_info(get_type_name(), $sformatf("  %s scale events: %0d", scale, freq_scale_events[scale]), UVM_LOW)
      end
    end
    
    `uvm_info(get_type_name(), $sformatf("Final Frequency: %.2f MHz", current_freq_mhz), UVM_LOW)
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
  
endclass : axi4_freq_checker

`endif