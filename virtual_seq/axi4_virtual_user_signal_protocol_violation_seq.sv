`ifndef AXI4_VIRTUAL_USER_SIGNAL_PROTOCOL_VIOLATION_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_SIGNAL_PROTOCOL_VIOLATION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_signal_protocol_violation_seq
// Virtual sequence to test various USER signal protocol violations
// Tests error detection and handling mechanisms for USER signal violations
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_signal_protocol_violation_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_user_signal_protocol_violation_seq)

  // Master sequences for different violation scenarios
  axi4_master_user_protocol_violation_seq violation_seq_h[8];
  
  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h;

  // Track violation counts for reporting
  int awuser_wuser_mismatch_count = 0;
  int reserved_bit_violation_count = 0;
  int user_signal_change_count = 0;
  int invalid_combination_count = 0;
  int integrity_failure_count = 0;
  int overflow_value_count = 0;
  int unexpected_zero_count = 0;
  int aruser_ruser_mismatch_count = 0;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_signal_protocol_violation_seq");
  extern task body();

endclass : axi4_virtual_user_signal_protocol_violation_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the object
//
// Parameters:
//  name - axi4_virtual_user_signal_protocol_violation_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_user_signal_protocol_violation_seq::new(string name = "axi4_virtual_user_signal_protocol_violation_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and starts sequences to test USER signal protocol violations
//--------------------------------------------------------------------------------------------
task axi4_virtual_user_signal_protocol_violation_seq::body();
  
  `uvm_info(get_type_name(), "Starting USER Signal Protocol Violation Virtual Sequence", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
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
  
  // Violation Test 1: AWUSER != WUSER mismatch
  `uvm_info(get_type_name(), "==== Violation Test 1: AWUSER != WUSER Mismatch ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Write address USER != Write data USER", UVM_LOW)
  
  violation_seq_h[0] = axi4_master_user_protocol_violation_seq::type_id::create("violation_seq_0");
  uvm_config_db#(string)::set(null, {get_full_name(), ".violation_seq_0"}, "violation_type", "AWUSER_WUSER_MISMATCH");
  uvm_config_db#(int)::set(null, {get_full_name(), ".violation_seq_0"}, "num_violations", 3);
  
  violation_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
  awuser_wuser_mismatch_count += 3;
  #200ns;
  
  // Violation Test 2: Reserved bits violation
  `uvm_info(get_type_name(), "==== Violation Test 2: Reserved Bits Set [31:24] ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Setting reserved USER signal bits that should be zero", UVM_LOW)
  
  violation_seq_h[1] = axi4_master_user_protocol_violation_seq::type_id::create("violation_seq_1");
  uvm_config_db#(string)::set(null, {get_full_name(), ".violation_seq_1"}, "violation_type", "RESERVED_BITS_SET");
  uvm_config_db#(int)::set(null, {get_full_name(), ".violation_seq_1"}, "num_violations", 4);
  
  violation_seq_h[1].start(p_sequencer.axi4_master_write_seqr_h);
  reserved_bit_violation_count += 4;
  #200ns;
  
  // Violation Test 3: USER signal changes mid-transaction
  `uvm_info(get_type_name(), "==== Violation Test 3: USER Signal Changes Mid-Transaction ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: USER signal value changes during multi-beat burst", UVM_LOW)
  
  violation_seq_h[2] = axi4_master_user_protocol_violation_seq::type_id::create("violation_seq_2");
  uvm_config_db#(string)::set(null, {get_full_name(), ".violation_seq_2"}, "violation_type", "USER_CHANGE_MID_BURST");
  uvm_config_db#(int)::set(null, {get_full_name(), ".violation_seq_2"}, "num_violations", 2);
  
  violation_seq_h[2].start(p_sequencer.axi4_master_write_seqr_h);
  user_signal_change_count += 2;
  #300ns;
  
  // Violation Test 4: Invalid USER signal combinations
  `uvm_info(get_type_name(), "==== Violation Test 4: Invalid USER Signal Combinations ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Conflicting or illegal USER signal bit combinations", UVM_LOW)
  
  violation_seq_h[3] = axi4_master_user_protocol_violation_seq::type_id::create("violation_seq_3");
  uvm_config_db#(string)::set(null, {get_full_name(), ".violation_seq_3"}, "violation_type", "INVALID_COMBINATION");
  uvm_config_db#(int)::set(null, {get_full_name(), ".violation_seq_3"}, "num_violations", 3);
  
  violation_seq_h[3].start(p_sequencer.axi4_master_write_seqr_h);
  invalid_combination_count += 3;
  #200ns;
  
  // Violation Test 5: USER signal integrity failures
  `uvm_info(get_type_name(), "==== Violation Test 5: USER Signal Integrity Failures ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Corruption or truncation of USER signals", UVM_LOW)
  
  violation_seq_h[4] = axi4_master_user_protocol_violation_seq::type_id::create("violation_seq_4");
  uvm_config_db#(string)::set(null, {get_full_name(), ".violation_seq_4"}, "violation_type", "INTEGRITY_FAILURE");
  uvm_config_db#(int)::set(null, {get_full_name(), ".violation_seq_4"}, "num_violations", 3);
  
  violation_seq_h[4].start(p_sequencer.axi4_master_write_seqr_h);
  integrity_failure_count += 3;
  #200ns;
  
  // Violation Test 6: Overflow USER values
  `uvm_info(get_type_name(), "==== Violation Test 6: USER Value Overflow ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: USER values exceeding maximum allowed ranges", UVM_LOW)
  
  violation_seq_h[5] = axi4_master_user_protocol_violation_seq::type_id::create("violation_seq_5");
  uvm_config_db#(string)::set(null, {get_full_name(), ".violation_seq_5"}, "violation_type", "USER_OVERFLOW");
  uvm_config_db#(int)::set(null, {get_full_name(), ".violation_seq_5"}, "num_violations", 2);
  
  violation_seq_h[5].start(p_sequencer.axi4_master_write_seqr_h);
  overflow_value_count += 2;
  #200ns;
  
  // Violation Test 7: Zero USER when non-zero expected
  `uvm_info(get_type_name(), "==== Violation Test 7: Unexpected Zero USER Values ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: USER=0 when protocol requires non-zero value", UVM_LOW)
  
  violation_seq_h[6] = axi4_master_user_protocol_violation_seq::type_id::create("violation_seq_6");
  uvm_config_db#(string)::set(null, {get_full_name(), ".violation_seq_6"}, "violation_type", "UNEXPECTED_ZERO");
  uvm_config_db#(int)::set(null, {get_full_name(), ".violation_seq_6"}, "num_violations", 2);
  
  violation_seq_h[6].start(p_sequencer.axi4_master_write_seqr_h);
  unexpected_zero_count += 2;
  #200ns;
  
  // Violation Test 8: ARUSER != RUSER mismatches (Read channel)
  `uvm_info(get_type_name(), "==== Violation Test 8: ARUSER != RUSER Mismatch (Read) ====", UVM_LOW)
  `uvm_info(get_type_name(), "Testing: Read address USER != Read data USER", UVM_LOW)
  
  violation_seq_h[7] = axi4_master_user_protocol_violation_seq::type_id::create("violation_seq_7");
  uvm_config_db#(string)::set(null, {get_full_name(), ".violation_seq_7"}, "violation_type", "ARUSER_RUSER_MISMATCH");
  uvm_config_db#(int)::set(null, {get_full_name(), ".violation_seq_7"}, "num_violations", 3);
  
  violation_seq_h[7].start(p_sequencer.axi4_master_read_seqr_h);
  aruser_ruser_mismatch_count += 3;
  #300ns;
  
  // Mixed violation scenario
  `uvm_info(get_type_name(), "==== Mixed Violation Scenario: Multiple concurrent violations ====", UVM_LOW)
  
  fork
    begin
      violation_seq_h[0] = axi4_master_user_protocol_violation_seq::type_id::create("mixed_violation_0");
      uvm_config_db#(string)::set(null, {get_full_name(), ".mixed_violation_0"}, "violation_type", "AWUSER_WUSER_MISMATCH");
      uvm_config_db#(int)::set(null, {get_full_name(), ".mixed_violation_0"}, "num_violations", 2);
      violation_seq_h[0].start(p_sequencer.axi4_master_write_seqr_h);
      awuser_wuser_mismatch_count += 2;
    end
    begin
      #50ns;
      violation_seq_h[1] = axi4_master_user_protocol_violation_seq::type_id::create("mixed_violation_1");
      uvm_config_db#(string)::set(null, {get_full_name(), ".mixed_violation_1"}, "violation_type", "RESERVED_BITS_SET");
      uvm_config_db#(int)::set(null, {get_full_name(), ".mixed_violation_1"}, "num_violations", 2);
      violation_seq_h[1].start(p_sequencer.axi4_master_write_seqr_h);
      reserved_bit_violation_count += 2;
    end
  join
  
  // Wait for all transactions to complete
  #1000ns;
  
  // Report violation summary
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "USER Signal Protocol Violation Test Summary:", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("AWUSER != WUSER mismatches:     %0d violations", awuser_wuser_mismatch_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Reserved bit violations:        %0d violations", reserved_bit_violation_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("USER changes mid-transaction:   %0d violations", user_signal_change_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Invalid combinations:           %0d violations", invalid_combination_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Integrity failures:             %0d violations", integrity_failure_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Overflow values:                %0d violations", overflow_value_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Unexpected zero values:         %0d violations", unexpected_zero_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("ARUSER != RUSER mismatches:     %0d violations", aruser_ruser_mismatch_count), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Total violations tested:        %0d", 
    awuser_wuser_mismatch_count + reserved_bit_violation_count + user_signal_change_count + 
    invalid_combination_count + integrity_failure_count + overflow_value_count + 
    unexpected_zero_count + aruser_ruser_mismatch_count), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  `uvm_info(get_type_name(), "Note: These violations were intentional for testing purposes", UVM_LOW)
  `uvm_info(get_type_name(), "Check scoreboard and monitors for proper violation detection", UVM_LOW)
  
endtask : body

`endif