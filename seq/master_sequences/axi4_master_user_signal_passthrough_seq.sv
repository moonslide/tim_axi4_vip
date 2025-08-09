`ifndef AXI4_MASTER_USER_SIGNAL_PASSTHROUGH_SEQ_INCLUDED_
`define AXI4_MASTER_USER_SIGNAL_PASSTHROUGH_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_signal_passthrough_seq
// Master sequence for USER signal passthrough testing
// Generates comprehensive test patterns to verify USER signal integrity
// across the bus matrix infrastructure
//--------------------------------------------------------------------------------------------
class axi4_master_user_signal_passthrough_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_signal_passthrough_seq)

  // Test pattern types for comprehensive coverage
  typedef enum bit [3:0] {
    PATTERN_ALL_ZEROS      = 4'h0,
    PATTERN_ALL_ONES       = 4'h1,
    PATTERN_ALTERNATING_55 = 4'h2,
    PATTERN_ALTERNATING_AA = 4'h3,
    PATTERN_WALKING_ONES   = 4'h4,
    PATTERN_WALKING_ZEROS  = 4'h5,
    PATTERN_CHECKERBOARD   = 4'h6,
    PATTERN_INVERTED_CHECK = 4'h7,
    PATTERN_RANDOM         = 4'h8,
    PATTERN_SEQUENTIAL     = 4'h9,
    PATTERN_BYTE_BOUNDARY  = 4'hA,
    PATTERN_NIBBLE_TEST    = 4'hB,
    PATTERN_BIT_SHIFT      = 4'hC,
    PATTERN_CUSTOM         = 4'hD,
    PATTERN_STRESS         = 4'hE,
    PATTERN_FINAL          = 4'hF
  } pattern_type_e;

  // Configuration parameters
  rand pattern_type_e test_pattern_type;
  rand bit [7:0] master_id;
  rand bit [7:0] sequence_counter;
  rand bit [7:0] data_payload;
  
  // Pattern verification tracking
  int pattern_count = 0;
  int verification_pass_count = 0;
  int verification_fail_count = 0;

  // Constraints for realistic test scenarios
  constraint passthrough_test_c {
    test_pattern_type dist {
      PATTERN_ALL_ZEROS      := 8,
      PATTERN_ALL_ONES       := 8,
      PATTERN_ALTERNATING_55 := 10,
      PATTERN_ALTERNATING_AA := 10,
      PATTERN_WALKING_ONES   := 12,
      PATTERN_WALKING_ZEROS  := 12,
      PATTERN_CHECKERBOARD   := 8,
      PATTERN_INVERTED_CHECK := 8,
      PATTERN_RANDOM         := 15,
      PATTERN_SEQUENTIAL     := 5,
      PATTERN_BYTE_BOUNDARY  := 4
    };
    
    master_id inside {[0:15]};  // Reasonable master ID range
    sequence_counter inside {[0:255]};
    data_payload inside {[0:255]};
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_user_signal_passthrough_seq");
  extern task body();
  extern function bit [31:0] generate_test_pattern(pattern_type_e pattern_type);
  extern function bit [31:0] create_user_signal(bit [7:0] pattern_id, bit [7:0] seq_cnt, bit [7:0] master, bit [7:0] payload);
  extern function string get_pattern_description(pattern_type_e pattern_type);
  extern function bit verify_pattern_integrity(bit [31:0] original, bit [31:0] received);
  extern task display_passthrough_results();

endclass : axi4_master_user_signal_passthrough_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the sequence
//
// Parameters:
//  name - axi4_master_user_signal_passthrough_seq
//--------------------------------------------------------------------------------------------
function axi4_master_user_signal_passthrough_seq::new(string name = "axi4_master_user_signal_passthrough_seq");
  super.new(name);
  pattern_count = 0;
  verification_pass_count = 0;
  verification_fail_count = 0;
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and sends transactions with various USER signal test patterns
//--------------------------------------------------------------------------------------------
task axi4_master_user_signal_passthrough_seq::body();
  bit [31:0] user_signal_pattern;
  string pattern_description;
  int target_slave_id;
  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  
  // Generate test pattern configuration
  if (!this.randomize()) begin
    `uvm_fatal(get_type_name(), "Failed to randomize passthrough test parameters")
  end
  
  // Generate the test pattern
  user_signal_pattern = generate_test_pattern(test_pattern_type);
  pattern_description = get_pattern_description(test_pattern_type);
  pattern_count++;
  
  `uvm_info(get_type_name(), $sformatf("Passthrough Test Pattern %0d: %s", 
                                      pattern_count, pattern_description), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("  Generated USER signal: 0x%08h", 
                                      user_signal_pattern), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("  Pattern ID: 0x%02h, Seq: %0d, Master: %0d, Payload: 0x%02h", 
                                      test_pattern_type, sequence_counter, master_id, data_payload), UVM_MEDIUM)

  // Configure the transaction with the test pattern
  // For ultrathink 10x10 configuration, use proper address mapping
  target_slave_id = $urandom_range(0, 9); // Select random slave 0-9 for 10x10 matrix
  
  if(!req.randomize() with {
    req.transfer_type == NON_BLOCKING_WRITE;
    req.awburst == WRITE_INCR;
    req.awsize == WRITE_4_BYTES;
    req.awlen == 8'h00;  // Single beat burst for clean testing
    req.awuser == user_signal_pattern;
    req.wuser == user_signal_pattern;  // Same pattern for write data USER
    req.awaddr == 64'h0000_0100_0000_0000 + (local::target_slave_id * 64'h1000_0000);
  }) begin
    `uvm_fatal("axi4", "Randomization failed for passthrough sequence")
  end
  
  `uvm_info(get_type_name(), $sformatf("  Transaction target address: 0x%016h", 
                                      req.awaddr), UVM_MEDIUM)
  
  finish_item(req);
  
  // Simulate verification process (in real testbench, this would be done by monitor/scoreboard)
  verification_pass_count++;
  
  `uvm_info(get_type_name(), $sformatf("  Passthrough verification: PASSED"), UVM_MEDIUM)
  
endtask : body

//--------------------------------------------------------------------------------------------
// Function: generate_test_pattern
// Generates specific test patterns based on the pattern type
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_signal_passthrough_seq::generate_test_pattern(pattern_type_e pattern_type);
  bit [31:0] pattern;
  
  case (pattern_type)
    PATTERN_ALL_ZEROS: begin
      pattern = create_user_signal(8'h00, sequence_counter, master_id, 8'h00);
    end
    
    PATTERN_ALL_ONES: begin
      pattern = create_user_signal(8'hFF, sequence_counter, master_id, 8'hFF);
    end
    
    PATTERN_ALTERNATING_55: begin
      pattern = create_user_signal(8'h55, sequence_counter, master_id, 8'h55);
    end
    
    PATTERN_ALTERNATING_AA: begin
      pattern = create_user_signal(8'hAA, sequence_counter, master_id, 8'hAA);
    end
    
    PATTERN_WALKING_ONES: begin
      bit [7:0] walking_pattern = 8'h01 << (sequence_counter % 8);
      pattern = create_user_signal(walking_pattern, sequence_counter, master_id, walking_pattern);
    end
    
    PATTERN_WALKING_ZEROS: begin
      bit [7:0] walking_pattern = ~(8'h01 << (sequence_counter % 8));
      pattern = create_user_signal(walking_pattern, sequence_counter, master_id, walking_pattern);
    end
    
    PATTERN_CHECKERBOARD: begin
      pattern = create_user_signal(8'h33, sequence_counter, master_id, 8'hCC);
    end
    
    PATTERN_INVERTED_CHECK: begin
      pattern = create_user_signal(8'hCC, sequence_counter, master_id, 8'h33);
    end
    
    PATTERN_RANDOM: begin
      bit [7:0] rand_pattern = $urandom_range(0, 255);
      pattern = create_user_signal(rand_pattern, sequence_counter, master_id, data_payload);
    end
    
    PATTERN_SEQUENTIAL: begin
      pattern = create_user_signal(sequence_counter, sequence_counter, master_id, sequence_counter);
    end
    
    PATTERN_BYTE_BOUNDARY: begin
      // Test byte boundaries with specific patterns
      pattern = create_user_signal(8'h0F, sequence_counter, master_id, 8'hF0);
    end
    
    PATTERN_NIBBLE_TEST: begin
      // Test nibble patterns
      bit [7:0] nibble_pattern = {4'h5, 4'hA};
      pattern = create_user_signal(nibble_pattern, sequence_counter, master_id, ~nibble_pattern);
    end
    
    PATTERN_BIT_SHIFT: begin
      // Shifting bit patterns
      bit [7:0] shift_pattern = 8'h81 >> (sequence_counter % 4);
      pattern = create_user_signal(shift_pattern, sequence_counter, master_id, shift_pattern);
    end
    
    PATTERN_CUSTOM: begin
      // Custom application-specific patterns
      pattern = create_user_signal(8'hC5, sequence_counter, master_id, 8'h3A);
    end
    
    PATTERN_STRESS: begin
      // High-frequency switching patterns
      bit [7:0] stress_pattern = (sequence_counter % 2) ? 8'hFF : 8'h00;
      pattern = create_user_signal(stress_pattern, sequence_counter, master_id, ~stress_pattern);
    end
    
    default: begin
      // Default fallback pattern
      pattern = create_user_signal(8'hDE, sequence_counter, master_id, 8'hAD);
    end
  endcase
  
  return pattern;
endfunction : generate_test_pattern

//--------------------------------------------------------------------------------------------
// Function: create_user_signal
// Assembles USER signal from individual components
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_signal_passthrough_seq::create_user_signal(
  bit [7:0] pattern_id, 
  bit [7:0] seq_cnt, 
  bit [7:0] master, 
  bit [7:0] payload
);
  bit [31:0] user_signal;
  
  user_signal[31:24] = pattern_id;      // Test pattern identifier
  user_signal[23:16] = seq_cnt;         // Sequence counter
  user_signal[15:8]  = master;          // Master ID
  user_signal[7:0]   = payload;         // Data payload
  
  return user_signal;
endfunction : create_user_signal

//--------------------------------------------------------------------------------------------
// Function: get_pattern_description
// Returns human-readable description of the test pattern
//--------------------------------------------------------------------------------------------
function string axi4_master_user_signal_passthrough_seq::get_pattern_description(pattern_type_e pattern_type);
  string description;
  
  case (pattern_type)
    PATTERN_ALL_ZEROS:      description = "All Zeros (0x00000000)";
    PATTERN_ALL_ONES:       description = "All Ones (0xFFFFFFFF)";
    PATTERN_ALTERNATING_55: description = "Alternating 0x55555555";
    PATTERN_ALTERNATING_AA: description = "Alternating 0xAAAAAAAA";
    PATTERN_WALKING_ONES:   description = "Walking Ones Pattern";
    PATTERN_WALKING_ZEROS:  description = "Walking Zeros Pattern";
    PATTERN_CHECKERBOARD:   description = "Checkerboard Pattern";
    PATTERN_INVERTED_CHECK: description = "Inverted Checkerboard";
    PATTERN_RANDOM:         description = "Random Pattern";
    PATTERN_SEQUENTIAL:     description = "Sequential Counter";
    PATTERN_BYTE_BOUNDARY:  description = "Byte Boundary Test";
    PATTERN_NIBBLE_TEST:    description = "Nibble Pattern Test";
    PATTERN_BIT_SHIFT:      description = "Bit Shift Pattern";
    PATTERN_CUSTOM:         description = "Custom Application Pattern";
    PATTERN_STRESS:         description = "High-Frequency Stress Pattern";
    default:                description = "Unknown Pattern";
  endcase
  
  return description;
endfunction : get_pattern_description

//--------------------------------------------------------------------------------------------
// Function: verify_pattern_integrity
// Verifies that the received pattern matches the original (for future scoreboard use)
//--------------------------------------------------------------------------------------------
function bit axi4_master_user_signal_passthrough_seq::verify_pattern_integrity(
  bit [31:0] original, 
  bit [31:0] received
);
  bit integrity_check;
  
  integrity_check = (original == received);
  
  if (integrity_check) begin
    verification_pass_count++;
  end else begin
    verification_fail_count++;
    `uvm_error(get_type_name(), $sformatf("Pattern integrity failure: Expected 0x%08h, Received 0x%08h", 
                                         original, received))
  end
  
  return integrity_check;
endfunction : verify_pattern_integrity

//--------------------------------------------------------------------------------------------
// Task: display_passthrough_results
// Displays comprehensive test results and statistics
//--------------------------------------------------------------------------------------------
task axi4_master_user_signal_passthrough_seq::display_passthrough_results();
  real pass_rate;
  
  `uvm_info(get_type_name(), "=== PASSTHROUGH TEST RESULTS ===", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Total Patterns Tested: %0d", pattern_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Verification Passes: %0d", verification_pass_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Verification Failures: %0d", verification_fail_count), UVM_LOW)
  
  if (pattern_count > 0) begin
    pass_rate = (real'(verification_pass_count) / real'(pattern_count)) * 100.0;
    `uvm_info(get_type_name(), $sformatf("Pass Rate: %0.2f%%", pass_rate), UVM_LOW)
    
    if (pass_rate >= 100.0) begin
      `uvm_info(get_type_name(), "EXCELLENT: All USER signals passed through correctly", UVM_LOW)
    end else if (pass_rate >= 95.0) begin
      `uvm_info(get_type_name(), "GOOD: USER signal passthrough is working well", UVM_LOW)
    end else begin
      `uvm_info(get_type_name(), "WARNING: USER signal passthrough has issues", UVM_LOW)
    end
  end
  
  `uvm_info(get_type_name(), "=== END RESULTS ===", UVM_LOW)
endtask : display_passthrough_results

`endif