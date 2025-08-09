`ifndef AXI4_VIRTUAL_USER_SIGNAL_CORRUPTION_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_SIGNAL_CORRUPTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_signal_corruption_seq
// Virtual sequence for comprehensive USER signal corruption testing
// Tests various corruption scenarios and error detection/recovery mechanisms
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_signal_corruption_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_user_signal_corruption_seq)

  // Master sequence handles
  axi4_master_user_signal_corruption_seq axi4_master_user_signal_corruption_seq_h;
  
  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h;

  // Configuration parameters
  rand int unsigned num_corruption_tests;

  // Constraints
  constraint corruption_test_cfg_c {
    num_corruption_tests inside {[20:50]};
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_signal_corruption_seq");
  extern task body();
  extern task execute_corruption_tests();
  extern task display_corruption_statistics();

endclass : axi4_virtual_user_signal_corruption_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the virtual sequence
//
// Parameters:
//  name - axi4_virtual_user_signal_corruption_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_user_signal_corruption_seq::new(string name = "axi4_virtual_user_signal_corruption_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Runs comprehensive USER signal corruption testing across all masters
//--------------------------------------------------------------------------------------------
task axi4_virtual_user_signal_corruption_seq::body();

  if (!this.randomize()) begin
    `uvm_fatal(get_type_name(), "Failed to randomize corruption test configuration")
  end
  
  `uvm_info(get_type_name(), "=== Starting USER Signal Corruption Testing ===", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Configuration: %0d corruption tests", 
                                      num_corruption_tests), UVM_LOW)
  `uvm_info(get_type_name(), "Testing corruption detection and recovery mechanisms", UVM_LOW)
  `uvm_info(get_type_name(), "USER Signal Format: [31:24]=EDC, [23:16]=Control, [15:8]=Header, [7:0]=Payload", UVM_LOW)

  // Create slave sequences
  axi4_slave_write_seq_h = axi4_slave_nbk_write_seq::type_id::create("axi4_slave_write_seq_h");
  axi4_slave_read_seq_h = axi4_slave_nbk_read_seq::type_id::create("axi4_slave_read_seq_h");
  
  // Start slave sequences in forever loops
  fork
    begin : SLAVE_WRITE
      forever begin
        axi4_slave_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
      end
    end
    
    begin : SLAVE_READ
      forever begin
        axi4_slave_read_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
      end
    end
  join_none

  // Execute corruption tests
  execute_corruption_tests();
  
  `uvm_info(get_type_name(), "=== USER Signal Corruption Testing Completed ===", UVM_LOW)

endtask : body

//--------------------------------------------------------------------------------------------
// Task: execute_corruption_tests
// Executes corruption tests using master write sequencer
//--------------------------------------------------------------------------------------------
task axi4_virtual_user_signal_corruption_seq::execute_corruption_tests();
  
  `uvm_info(get_type_name(), "Executing corruption tests...", UVM_MEDIUM)
  
  repeat (num_corruption_tests) begin
    
    // Create and configure corruption sequence
    axi4_master_user_signal_corruption_seq_h = 
      axi4_master_user_signal_corruption_seq::type_id::create("corruption_seq");
    
    // Run the corruption sequence
    axi4_master_user_signal_corruption_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
    
    // Add delay between tests
    #100ns;
  end
  
  `uvm_info(get_type_name(), $sformatf("All %0d corruption tests completed successfully", 
                                      num_corruption_tests), UVM_LOW)
  
  // Display summary statistics
  display_corruption_statistics();

endtask : execute_corruption_tests

//--------------------------------------------------------------------------------------------
// Task: display_corruption_statistics
// Displays corruption testing summary
//--------------------------------------------------------------------------------------------
task axi4_virtual_user_signal_corruption_seq::display_corruption_statistics();
  int total_corruptions = 0;
  int total_detections = 0;
  int total_recoveries = 0;
  real detection_rate = 0.0;
  real recovery_rate = 0.0;
  
  `uvm_info(get_type_name(), "=== CORRUPTION TEST STATISTICS ===", UVM_LOW)
  
  // Get statistics from the last sequence run
  if (axi4_master_user_signal_corruption_seq_h != null) begin
    total_corruptions = axi4_master_user_signal_corruption_seq_h.corruption_count;
    total_detections = axi4_master_user_signal_corruption_seq_h.detection_count;
    total_recoveries = axi4_master_user_signal_corruption_seq_h.recovery_count;
    
    // Calculate rates
    if (total_corruptions > 0) begin
      detection_rate = (real'(total_detections) / real'(total_corruptions)) * 100.0;
      recovery_rate = (real'(total_recoveries) / real'(total_corruptions)) * 100.0;
    end
    
    // Display summary statistics
    `uvm_info(get_type_name(), "--- SUMMARY ---", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Total Corruptions Injected: %0d", total_corruptions), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Total Corruptions Detected: %0d", total_detections), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Total Recoveries Performed: %0d", total_recoveries), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Detection Rate: %0.2f%%", detection_rate), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Recovery Rate: %0.2f%%", recovery_rate), UVM_LOW)
    
    // Analysis and recommendations
    `uvm_info(get_type_name(), "--- ANALYSIS ---", UVM_LOW)
    if (detection_rate >= 95.0) begin
      `uvm_info(get_type_name(), "EXCELLENT: Corruption detection system is highly effective", UVM_LOW)
    end else if (detection_rate >= 85.0) begin
      `uvm_info(get_type_name(), "GOOD: Corruption detection system is working well", UVM_LOW)
    end else if (detection_rate >= 70.0) begin
      `uvm_info(get_type_name(), "FAIR: Corruption detection system needs improvement", UVM_LOW)
    end else begin
      `uvm_info(get_type_name(), "POOR: Corruption detection system requires significant enhancement", UVM_LOW)
    end
  end else begin
    `uvm_info(get_type_name(), "WARNING: No corruption sequence statistics available", UVM_LOW)
  end
  
  `uvm_info(get_type_name(), "=== END STATISTICS ===", UVM_LOW)

endtask : display_corruption_statistics

`endif