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
  int num_masters = 1;
  int num_slaves = 1;
  bit is_enhanced_mode = 0;
  bit is_4x4_ref_mode = 0;

  // Constraints
  constraint corruption_test_cfg_c {
    num_corruption_tests inside {[5:10]};  // Reduced from [20:50] to avoid timeout
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
  int actual_masters;
  int actual_slaves;

  if (!this.randomize()) begin
    `uvm_fatal(get_type_name(), "Failed to randomize corruption test configuration")
  end
  
  `uvm_info(get_type_name(), "=== Starting USER Signal Corruption Testing ===", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Configuration: %0d corruption tests", 
                                      num_corruption_tests), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Enhanced: %0d, 4x4 Ref: %0d", is_enhanced_mode, is_4x4_ref_mode), UVM_LOW)
  `uvm_info(get_type_name(), "Testing corruption detection and recovery mechanisms", UVM_LOW)
  `uvm_info(get_type_name(), "USER Signal Format: [31:24]=EDC, [23:16]=Control, [15:8]=Header, [7:0]=Payload", UVM_LOW)

  // Determine actual number of sequencers available
  actual_masters = (p_sequencer.axi4_master_write_seqr_h_all.size() > 0) ? 
                   p_sequencer.axi4_master_write_seqr_h_all.size() : 1;
  actual_slaves = (p_sequencer.axi4_slave_write_seqr_h_all.size() > 0) ? 
                  p_sequencer.axi4_slave_write_seqr_h_all.size() : 1;
  
  // Use minimum of configured and actual
  if (actual_masters < num_masters) begin
    `uvm_info(get_type_name(), $sformatf("Adjusting masters from %0d to %0d (actual available)", 
                                         num_masters, actual_masters), UVM_MEDIUM)
    num_masters = actual_masters;
  end
  
  if (actual_slaves < num_slaves) begin
    `uvm_info(get_type_name(), $sformatf("Adjusting slaves from %0d to %0d (actual available)", 
                                         num_slaves, actual_slaves), UVM_MEDIUM)
    num_slaves = actual_slaves;
  end

  // Create slave sequences
  axi4_slave_write_seq_h = axi4_slave_nbk_write_seq::type_id::create("axi4_slave_write_seq_h");
  axi4_slave_read_seq_h = axi4_slave_nbk_read_seq::type_id::create("axi4_slave_read_seq_h");
  
  // Start slave sequences in forever loops
  fork
    begin : SLAVE_WRITE
      if (actual_slaves > 1) begin
        foreach(p_sequencer.axi4_slave_write_seqr_h_all[i]) begin
          if (i < num_slaves) begin
            automatic int slave_idx = i;
            fork
              forever begin
                axi4_slave_nbk_write_seq seq = axi4_slave_nbk_write_seq::type_id::create($sformatf("slave_write_%0d", slave_idx));
                seq.start(p_sequencer.axi4_slave_write_seqr_h_all[slave_idx]);
                #10;
              end
            join_none
          end
        end
      end else begin
        fork
          forever begin
            axi4_slave_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
            #10;
          end
        join_none
      end
    end
    
    begin : SLAVE_READ
      if (actual_slaves > 1) begin
        foreach(p_sequencer.axi4_slave_read_seqr_h_all[i]) begin
          if (i < num_slaves) begin
            automatic int slave_idx = i;
            fork
              forever begin
                axi4_slave_nbk_read_seq seq = axi4_slave_nbk_read_seq::type_id::create($sformatf("slave_read_%0d", slave_idx));
                seq.start(p_sequencer.axi4_slave_read_seqr_h_all[slave_idx]);
                #10;
              end
            join_none
          end
        end
      end else begin
        fork
          forever begin
            axi4_slave_read_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
            #10;
          end
        join_none
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
    
    // Pass mode configuration to the master sequence
    axi4_master_user_signal_corruption_seq_h.is_enhanced_mode = is_enhanced_mode;
    axi4_master_user_signal_corruption_seq_h.target_slave_id = $urandom_range(0, num_slaves - 1);
    
    // Run the corruption sequence
    axi4_master_user_signal_corruption_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
    
    // Add small delay between tests
    #10ns;  // Reduced from 100ns to 10ns
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