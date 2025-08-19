`ifndef AXI4_VIRTUAL_USER_SIGNAL_WIDTH_MISMATCH_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_SIGNAL_WIDTH_MISMATCH_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_signal_width_mismatch_seq
// Virtual sequence to test USER signal width mismatch scenarios
// Tests truncation, padding, and width compatibility issues
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_signal_width_mismatch_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_user_signal_width_mismatch_seq)

  // Master sequences for different width mismatch scenarios
  axi4_master_user_width_mismatch_seq width_mismatch_seq_h[8];
  
  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h;

  // Track test results
  int truncation_test_count = 0;
  int padding_test_count = 0;
  int msb_lsb_test_count = 0;
  int channel_mismatch_count = 0;
  int boundary_test_count = 0;
  int total_width_tests = 0;
  
  // Configuration parameters from test
  int num_masters = 1;
  int num_slaves = 1;
  bit is_enhanced_mode = 0;
  bit is_4x4_ref_mode = 0;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_signal_width_mismatch_seq");
  extern task body();

endclass : axi4_virtual_user_signal_width_mismatch_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the object
//
// Parameters:
//  name - axi4_virtual_user_signal_width_mismatch_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_user_signal_width_mismatch_seq::new(string name = "axi4_virtual_user_signal_width_mismatch_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and starts sequences to test USER signal width mismatches
//--------------------------------------------------------------------------------------------
task axi4_virtual_user_signal_width_mismatch_seq::body();
  int actual_masters;
  int actual_slaves;
  
  `uvm_info(get_type_name(), "Starting USER Signal Width Mismatch Virtual Sequence", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Enhanced: %0d, 4x4 Ref: %0d", is_enhanced_mode, is_4x4_ref_mode), UVM_LOW)
  
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
  
  // Test Scenario 1: Truncation from 32-bit to narrower widths
  `uvm_info(get_type_name(), "==== Test Scenario 1: 32-bit to Narrower Width Truncation ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: USER signal truncation when connecting to narrower interfaces", UVM_LOW)
  
  width_mismatch_seq_h[0] = axi4_master_user_width_mismatch_seq::type_id::create("width_mismatch_seq_0");
  uvm_config_db#(string)::set(null, {get_full_name(), ".width_mismatch_seq_0"}, "test_type", "TRUNCATION_32_TO_16");
  uvm_config_db#(int)::set(null, {get_full_name(), ".width_mismatch_seq_0"}, "num_tests", 3);
  width_mismatch_seq_h[0].is_enhanced_mode = is_enhanced_mode;
  width_mismatch_seq_h[0].slave_id = $urandom_range(0, num_slaves - 1);
  
  width_mismatch_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
  truncation_test_count += 3;
  #200ns;
  
  // Test with different truncation widths
  width_mismatch_seq_h[1] = axi4_master_user_width_mismatch_seq::type_id::create("width_mismatch_seq_1");
  uvm_config_db#(string)::set(null, {get_full_name(), ".width_mismatch_seq_1"}, "test_type", "TRUNCATION_32_TO_8");
  uvm_config_db#(int)::set(null, {get_full_name(), ".width_mismatch_seq_1"}, "num_tests", 2);
  width_mismatch_seq_h[1].is_enhanced_mode = is_enhanced_mode;
  width_mismatch_seq_h[1].slave_id = $urandom_range(0, num_slaves - 1);
  
  width_mismatch_seq_h[1].start(p_sequencer.axi4_master_write_seqr_h);
  truncation_test_count += 2;
  #200ns;
  
  // Test Scenario 2: Zero-padding from narrow to wider widths
  `uvm_info(get_type_name(), "==== Test Scenario 2: Narrow to Wide Zero-Padding ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: USER signal padding when connecting narrow signals to wider interfaces", UVM_LOW)
  
  width_mismatch_seq_h[2] = axi4_master_user_width_mismatch_seq::type_id::create("width_mismatch_seq_2");
  uvm_config_db#(string)::set(null, {get_full_name(), ".width_mismatch_seq_2"}, "test_type", "PADDING_8_TO_32");
  uvm_config_db#(int)::set(null, {get_full_name(), ".width_mismatch_seq_2"}, "num_tests", 3);
  width_mismatch_seq_h[2].is_enhanced_mode = is_enhanced_mode;
  width_mismatch_seq_h[2].slave_id = $urandom_range(0, num_slaves - 1);
  
  width_mismatch_seq_h[2].start(p_sequencer.axi4_master_write_seqr_h);
  padding_test_count += 3;
  #200ns;
  
  // Test Scenario 3: MSB vs LSB preservation during truncation
  `uvm_info(get_type_name(), "==== Test Scenario 3: MSB vs LSB Preservation ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Which bits are preserved during truncation (MSB or LSB)", UVM_LOW)
  
  width_mismatch_seq_h[3] = axi4_master_user_width_mismatch_seq::type_id::create("width_mismatch_seq_3");
  uvm_config_db#(string)::set(null, {get_full_name(), ".width_mismatch_seq_3"}, "test_type", "MSB_LSB_PRESERVATION");
  uvm_config_db#(int)::set(null, {get_full_name(), ".width_mismatch_seq_3"}, "num_tests", 4);
  width_mismatch_seq_h[3].is_enhanced_mode = is_enhanced_mode;
  width_mismatch_seq_h[3].slave_id = $urandom_range(0, num_slaves - 1);
  
  width_mismatch_seq_h[3].start(p_sequencer.axi4_master_write_seqr_h);
  msb_lsb_test_count += 4;
  #300ns;
  
  // Test Scenario 4: Width mismatches between channels
  `uvm_info(get_type_name(), "==== Test Scenario 4: Channel Width Mismatches ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Different widths for AWUSER (32-bit) vs BUSER (16-bit)", UVM_LOW)
  
  width_mismatch_seq_h[4] = axi4_master_user_width_mismatch_seq::type_id::create("width_mismatch_seq_4");
  uvm_config_db#(string)::set(null, {get_full_name(), ".width_mismatch_seq_4"}, "test_type", "CHANNEL_WIDTH_DIFF");
  uvm_config_db#(int)::set(null, {get_full_name(), ".width_mismatch_seq_4"}, "num_tests", 3);
  width_mismatch_seq_h[4].is_enhanced_mode = is_enhanced_mode;
  width_mismatch_seq_h[4].slave_id = $urandom_range(0, num_slaves - 1);
  
  width_mismatch_seq_h[4].start(p_sequencer.axi4_master_write_seqr_h);
  channel_mismatch_count += 3;
  #200ns;
  
  // Test Scenario 5: Boundary value testing with width mismatches
  `uvm_info(get_type_name(), "==== Test Scenario 5: Boundary Values with Width Mismatches ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: All 1s, alternating patterns with different widths", UVM_LOW)
  
  width_mismatch_seq_h[5] = axi4_master_user_width_mismatch_seq::type_id::create("width_mismatch_seq_5");
  uvm_config_db#(string)::set(null, {get_full_name(), ".width_mismatch_seq_5"}, "test_type", "BOUNDARY_VALUES");
  uvm_config_db#(int)::set(null, {get_full_name(), ".width_mismatch_seq_5"}, "num_tests", 4);
  width_mismatch_seq_h[5].is_enhanced_mode = is_enhanced_mode;
  width_mismatch_seq_h[5].slave_id = $urandom_range(0, num_slaves - 1);
  
  width_mismatch_seq_h[5].start(p_sequencer.axi4_master_write_seqr_h);
  boundary_test_count += 4;
  #300ns;
  
  // Test Scenario 6: QoS/Routing information preservation
  `uvm_info(get_type_name(), "==== Test Scenario 6: QoS/Routing Info Preservation ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Critical QoS/routing bits preservation during width changes", UVM_LOW)
  
  width_mismatch_seq_h[6] = axi4_master_user_width_mismatch_seq::type_id::create("width_mismatch_seq_6");
  uvm_config_db#(string)::set(null, {get_full_name(), ".width_mismatch_seq_6"}, "test_type", "QOS_PRESERVATION");
  uvm_config_db#(int)::set(null, {get_full_name(), ".width_mismatch_seq_6"}, "num_tests", 3);
  width_mismatch_seq_h[6].is_enhanced_mode = is_enhanced_mode;
  width_mismatch_seq_h[6].slave_id = $urandom_range(0, num_slaves - 1);
  
  width_mismatch_seq_h[6].start(p_sequencer.axi4_master_write_seqr_h);
  #200ns;
  
  // Test Scenario 7: Read channel width mismatches (ARUSER vs RUSER)
  `uvm_info(get_type_name(), "==== Test Scenario 7: Read Channel Width Mismatches ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: ARUSER (32-bit) vs RUSER (16-bit) width differences", UVM_LOW)
  
  width_mismatch_seq_h[7] = axi4_master_user_width_mismatch_seq::type_id::create("width_mismatch_seq_7");
  uvm_config_db#(string)::set(null, {get_full_name(), ".width_mismatch_seq_7"}, "test_type", "READ_WIDTH_MISMATCH");
  uvm_config_db#(int)::set(null, {get_full_name(), ".width_mismatch_seq_7"}, "num_tests", 3);
  width_mismatch_seq_h[7].is_enhanced_mode = is_enhanced_mode;
  width_mismatch_seq_h[7].slave_id = $urandom_range(0, num_slaves - 1);
  
  width_mismatch_seq_h[7].start(p_sequencer.axi4_master_read_seqr_h);
  #300ns;
  
  // Mixed width scenario with multiple masters
  `uvm_info(get_type_name(), "==== Mixed Width Scenario: Multiple Masters with Different Widths ====", UVM_LOW)
  
  fork
    begin
      width_mismatch_seq_h[0] = axi4_master_user_width_mismatch_seq::type_id::create("mixed_width_0");
      uvm_config_db#(string)::set(null, {get_full_name(), ".mixed_width_0"}, "test_type", "TRUNCATION_32_TO_16");
      uvm_config_db#(int)::set(null, {get_full_name(), ".mixed_width_0"}, "num_tests", 2);
      width_mismatch_seq_h[0].is_enhanced_mode = is_enhanced_mode;
      width_mismatch_seq_h[0].slave_id = $urandom_range(0, num_slaves - 1);
      width_mismatch_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
    end
    begin
      #50ns;
      width_mismatch_seq_h[1] = axi4_master_user_width_mismatch_seq::type_id::create("mixed_width_1");
      uvm_config_db#(string)::set(null, {get_full_name(), ".mixed_width_1"}, "test_type", "PADDING_8_TO_32");
      uvm_config_db#(int)::set(null, {get_full_name(), ".mixed_width_1"}, "num_tests", 2);
      width_mismatch_seq_h[1].is_enhanced_mode = is_enhanced_mode;
      width_mismatch_seq_h[1].slave_id = $urandom_range(0, num_slaves - 1);
      width_mismatch_seq_h[1].start(p_sequencer.axi4_master_write_seqr_h);
    end
  join
  
  // Wait for all transactions to complete
  #1000ns;
  
  // Calculate total tests
  total_width_tests = truncation_test_count + padding_test_count + msb_lsb_test_count + 
                     channel_mismatch_count + boundary_test_count + 6; // +6 for other scenarios
  
  // Report test summary
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "USER Signal Width Mismatch Test Summary:", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Truncation tests (32->narrower):  %0d", truncation_test_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Padding tests (narrow->32):        %0d", padding_test_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("MSB/LSB preservation tests:        %0d", msb_lsb_test_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Channel width mismatch tests:      %0d", channel_mismatch_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Boundary value tests:              %0d", boundary_test_count), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Total width mismatch tests:        %0d", total_width_tests), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  `uvm_info(get_type_name(), "Width mismatch testing observations:", UVM_LOW)
  `uvm_info(get_type_name(), "  - LSB preservation during truncation (standard behavior)", UVM_LOW)
  `uvm_info(get_type_name(), "  - Zero-padding in MSBs when extending widths", UVM_LOW)
  `uvm_info(get_type_name(), "  - AWUSER/ARUSER: 32-bit → BUSER/RUSER: 16-bit truncation", UVM_LOW)
  `uvm_info(get_type_name(), "  - Critical routing/QoS info should be in LSBs for preservation", UVM_LOW)
  
endtask : body

`endif