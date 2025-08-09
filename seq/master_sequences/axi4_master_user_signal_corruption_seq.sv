`ifndef AXI4_MASTER_USER_SIGNAL_CORRUPTION_SEQ_INCLUDED_
`define AXI4_MASTER_USER_SIGNAL_CORRUPTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_signal_corruption_seq
// Master sequence for USER signal corruption testing
// Injects various types of corruption to test robustness and error handling
//--------------------------------------------------------------------------------------------
class axi4_master_user_signal_corruption_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_signal_corruption_seq)

  // Corruption type definitions
  typedef enum bit [3:0] {
    CORRUPT_NONE           = 4'h0,
    CORRUPT_SINGLE_BIT     = 4'h1,
    CORRUPT_DOUBLE_BIT     = 4'h2,
    CORRUPT_NIBBLE         = 4'h3,
    CORRUPT_BYTE           = 4'h4,
    CORRUPT_BURST          = 4'h5,
    CORRUPT_PATTERN_INVERT = 4'h6,
    CORRUPT_PATTERN_SHIFT  = 4'h7,
    CORRUPT_RANDOM         = 4'h8,
    CORRUPT_COMPLETE       = 4'h9,
    CORRUPT_INTERMITTENT   = 4'hA,
    CORRUPT_STUCK_AT       = 4'hB,
    CORRUPT_BRIDGING       = 4'hC,
    CORRUPT_AGING          = 4'hD,
    CORRUPT_EMI            = 4'hE,
    CORRUPT_SYSTEMATIC     = 4'hF
  } corruption_type_e;
  
  // Corruption severity levels
  typedef enum bit [2:0] {
    SEVERITY_BENIGN        = 3'h0,
    SEVERITY_MINOR         = 3'h1,
    SEVERITY_MODERATE      = 3'h2,
    SEVERITY_MAJOR         = 3'h3,
    SEVERITY_CRITICAL      = 3'h4,
    SEVERITY_CATASTROPHIC  = 3'h7
  } corruption_severity_e;
  
  // Configuration parameters
  rand corruption_type_e     corruption_type;
  rand corruption_severity_e corruption_severity;
  rand bit [31:0]           original_user_data;
  rand bit [4:0]            corruption_position;
  rand bit [3:0]            corruption_width;
  rand bit [7:0]            corruption_pattern;
  
  // Corruption statistics
  int corruption_count;
  int detection_count;
  int recovery_count;
  
  // Constraints
  constraint corruption_cfg_c {
    corruption_type dist {
      CORRUPT_SINGLE_BIT     := 25,
      CORRUPT_DOUBLE_BIT     := 15,
      CORRUPT_NIBBLE         := 10,
      CORRUPT_BYTE           := 10,
      CORRUPT_BURST          := 10,
      CORRUPT_PATTERN_INVERT := 8,
      CORRUPT_RANDOM         := 7,
      CORRUPT_COMPLETE       := 5,
      CORRUPT_INTERMITTENT   := 5,
      CORRUPT_STUCK_AT       := 3,
      CORRUPT_BRIDGING       := 2
    };
    
    corruption_severity dist {
      SEVERITY_BENIGN   := 30,
      SEVERITY_MINOR    := 25,
      SEVERITY_MODERATE := 20,
      SEVERITY_MAJOR    := 15,
      SEVERITY_CRITICAL := 8,
      SEVERITY_CATASTROPHIC := 2
    };
    
    corruption_position inside {[0:31]};
    corruption_width inside {[1:8]};
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_user_signal_corruption_seq");
  extern task body();
  extern function bit [31:0] inject_corruption(bit [31:0] original_data);
  extern function bit [31:0] apply_single_bit_corruption(bit [31:0] data);
  extern function bit [31:0] apply_multi_bit_corruption(bit [31:0] data);
  extern function bit [31:0] apply_pattern_corruption(bit [31:0] data);
  extern function bit [31:0] apply_systematic_corruption(bit [31:0] data);
  extern function bit detect_corruption(bit [31:0] original, bit [31:0] corrupted);
  extern function string describe_corruption(corruption_type_e ctype, corruption_severity_e sev);
  extern function bit [31:0] generate_error_detection_bits(bit [31:0] data);

endclass : axi4_master_user_signal_corruption_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the sequence
//
// Parameters:
//  name - axi4_master_user_signal_corruption_seq
//--------------------------------------------------------------------------------------------
function axi4_master_user_signal_corruption_seq::new(string name = "axi4_master_user_signal_corruption_seq");
  super.new(name);
  corruption_count = 0;
  detection_count = 0;
  recovery_count = 0;
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and sends transactions with corrupted USER signals
//--------------------------------------------------------------------------------------------
task axi4_master_user_signal_corruption_seq::body();
  bit [31:0] corrupted_user_signal;
  bit corruption_detected;
  string corruption_desc;
  int target_slave_id;
  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  
  // Generate original clean USER data
  if (!this.randomize()) begin
    `uvm_fatal(get_type_name(), "Failed to randomize corruption parameters")
  end
  
  // Add error detection bits to original data
  original_user_data[31:24] = generate_error_detection_bits(original_user_data[23:0]);
  
  // Apply corruption
  corrupted_user_signal = inject_corruption(original_user_data);
  corruption_count++;
  
  // Detect corruption
  corruption_detected = detect_corruption(original_user_data, corrupted_user_signal);
  if (corruption_detected) detection_count++;
  
  corruption_desc = describe_corruption(corruption_type, corruption_severity);
  
  `uvm_info(get_type_name(), $sformatf("Corruption Test: %s", corruption_desc), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("  Original:  0x%08h", original_user_data), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("  Corrupted: 0x%08h", corrupted_user_signal), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("  Detection: %s", corruption_detected ? "DETECTED" : "MISSED"), UVM_MEDIUM)
  
  // For ultrathink 10x10 configuration, use proper address mapping
  target_slave_id = $urandom_range(0, 9); // Select random slave 0-9 for 10x10 matrix
  
  if(!req.randomize() with {
    req.transfer_type == NON_BLOCKING_WRITE;
    req.awburst == WRITE_INCR;
    req.awsize == WRITE_4_BYTES;
    req.awlen == 8'h00;  // Single beat burst
    req.awuser == corrupted_user_signal;
    req.wuser == corrupted_user_signal;  // Same corrupted signal for write data
    req.awaddr == 64'h0000_0100_0000_0000 + (local::target_slave_id * 64'h1000_0000);
  }) begin
    `uvm_fatal("axi4", "Randomization failed for corruption sequence")
  end
  
  finish_item(req);
  
endtask : body

//--------------------------------------------------------------------------------------------
// Function: inject_corruption
// Main corruption injection dispatcher
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_signal_corruption_seq::inject_corruption(bit [31:0] original_data);
  bit [31:0] corrupted_data;
  
  case (corruption_type)
    CORRUPT_NONE: begin
      corrupted_data = original_data;
    end
    
    CORRUPT_SINGLE_BIT,
    CORRUPT_DOUBLE_BIT: begin
      corrupted_data = apply_single_bit_corruption(original_data);
    end
    
    CORRUPT_NIBBLE,
    CORRUPT_BYTE,
    CORRUPT_BURST: begin
      corrupted_data = apply_multi_bit_corruption(original_data);
    end
    
    CORRUPT_PATTERN_INVERT,
    CORRUPT_PATTERN_SHIFT,
    CORRUPT_RANDOM: begin
      corrupted_data = apply_pattern_corruption(original_data);
    end
    
    CORRUPT_COMPLETE: begin
      corrupted_data = ~original_data; // Complete inversion
    end
    
    CORRUPT_INTERMITTENT: begin
      // Simulate intermittent corruption (50% chance)
      corrupted_data = ($urandom() % 2) ? apply_single_bit_corruption(original_data) : original_data;
    end
    
    CORRUPT_STUCK_AT,
    CORRUPT_BRIDGING,
    CORRUPT_AGING,
    CORRUPT_EMI,
    CORRUPT_SYSTEMATIC: begin
      corrupted_data = apply_systematic_corruption(original_data);
    end
    
    default: begin
      corrupted_data = apply_single_bit_corruption(original_data);
    end
  endcase
  
  return corrupted_data;
endfunction : inject_corruption

//--------------------------------------------------------------------------------------------
// Function: apply_single_bit_corruption
// Applies single or double bit corruption
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_signal_corruption_seq::apply_single_bit_corruption(bit [31:0] data);
  bit [31:0] result = data;
  int num_bits;
  
  num_bits = (corruption_type == CORRUPT_SINGLE_BIT) ? 1 : 2;
  
  for (int i = 0; i < num_bits; i++) begin
    int bit_pos = $urandom_range(0, 31);
    result[bit_pos] = ~result[bit_pos];
  end
  
  return result;
endfunction : apply_single_bit_corruption

//--------------------------------------------------------------------------------------------
// Function: apply_multi_bit_corruption
// Applies nibble, byte, or burst corruption
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_signal_corruption_seq::apply_multi_bit_corruption(bit [31:0] data);
  bit [31:0] result = data;
  int start_pos = corruption_position;
  int width;
  
  case (corruption_type)
    CORRUPT_NIBBLE: width = 4;
    CORRUPT_BYTE:   width = 8;
    CORRUPT_BURST:  width = corruption_width;
    default:        width = 4;
  endcase
  
  // Ensure corruption doesn't exceed bit boundaries
  if (start_pos + width > 32) begin
    width = 32 - start_pos;
  end
  
  // Apply corruption mask
  for (int i = 0; i < width; i++) begin
    if (start_pos + i < 32) begin
      result[start_pos + i] = ~result[start_pos + i];
    end
  end
  
  return result;
endfunction : apply_multi_bit_corruption

//--------------------------------------------------------------------------------------------
// Function: apply_pattern_corruption
// Applies pattern-based corruption (invert, shift, random)
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_signal_corruption_seq::apply_pattern_corruption(bit [31:0] data);
  bit [31:0] result;
  
  case (corruption_type)
    CORRUPT_PATTERN_INVERT: begin
      result = data ^ corruption_pattern;
    end
    
    CORRUPT_PATTERN_SHIFT: begin
      // Circular shift corruption
      result = (data << corruption_pattern[2:0]) | (data >> (32 - corruption_pattern[2:0]));
    end
    
    CORRUPT_RANDOM: begin
      // Apply random corruption pattern
      bit [31:0] random_mask = $urandom();
      result = data ^ (random_mask & {{24{1'b0}}, corruption_pattern});
    end
    
    default: begin
      result = data ^ corruption_pattern;
    end
  endcase
  
  return result;
endfunction : apply_pattern_corruption

//--------------------------------------------------------------------------------------------
// Function: apply_systematic_corruption
// Applies systematic corruption patterns (stuck-at, bridging, aging, EMI)
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_signal_corruption_seq::apply_systematic_corruption(bit [31:0] data);
  bit [31:0] result = data;
  
  case (corruption_type)
    CORRUPT_STUCK_AT: begin
      // Simulate stuck-at-0 or stuck-at-1 fault
      if (corruption_pattern[0]) begin
        result[corruption_position] = 1'b1; // Stuck-at-1
      end else begin
        result[corruption_position] = 1'b0; // Stuck-at-0
      end
    end
    
    CORRUPT_BRIDGING: begin
      // Simulate bridging fault between adjacent bits
      if (corruption_position < 31) begin
        bit bridge_value = result[corruption_position] & result[corruption_position + 1];
        result[corruption_position] = bridge_value;
        result[corruption_position + 1] = bridge_value;
      end
    end
    
    CORRUPT_AGING: begin
      // Simulate aging-related bit degradation
      for (int i = 0; i < 4; i++) begin
        int pos = (corruption_position + i) % 32;
        if ($urandom_range(0, 100) < 15) begin // 15% degradation probability
          result[pos] = ~result[pos];
        end
      end
    end
    
    CORRUPT_EMI: begin
      // Simulate EMI-induced corruption (high frequency noise)
      bit [31:0] emi_pattern = 32'hAAAAAAAA; // Alternating pattern
      result = data ^ (emi_pattern & corruption_pattern);
    end
    
    CORRUPT_SYSTEMATIC: begin
      // Systematic corruption affecting specific bit positions
      for (int i = 0; i < 32; i += 4) begin
        result[i] = ~result[i]; // Corrupt every 4th bit
      end
    end
    
    default: begin
      result[corruption_position] = ~result[corruption_position];
    end
  endcase
  
  return result;
endfunction : apply_systematic_corruption

//--------------------------------------------------------------------------------------------
// Function: detect_corruption
// Detects corruption by comparing original and corrupted data
//--------------------------------------------------------------------------------------------
function bit axi4_master_user_signal_corruption_seq::detect_corruption(bit [31:0] original, bit [31:0] corrupted);
  bit [31:0] diff = original ^ corrupted;
  return (diff != 32'h0);
endfunction : detect_corruption

//--------------------------------------------------------------------------------------------
// Function: describe_corruption
// Provides human-readable description of corruption type and severity
//--------------------------------------------------------------------------------------------
function string axi4_master_user_signal_corruption_seq::describe_corruption(corruption_type_e ctype, corruption_severity_e sev);
  string type_str, severity_str;
  
  case (ctype)
    CORRUPT_NONE:           type_str = "NO_CORRUPTION";
    CORRUPT_SINGLE_BIT:     type_str = "SINGLE_BIT";
    CORRUPT_DOUBLE_BIT:     type_str = "DOUBLE_BIT";
    CORRUPT_NIBBLE:         type_str = "NIBBLE_CORRUPT";
    CORRUPT_BYTE:           type_str = "BYTE_CORRUPT";
    CORRUPT_BURST:          type_str = "BURST_CORRUPT";
    CORRUPT_PATTERN_INVERT: type_str = "PATTERN_INVERT";
    CORRUPT_PATTERN_SHIFT:  type_str = "PATTERN_SHIFT";
    CORRUPT_RANDOM:         type_str = "RANDOM_CORRUPT";
    CORRUPT_COMPLETE:       type_str = "COMPLETE_CORRUPT";
    CORRUPT_INTERMITTENT:   type_str = "INTERMITTENT";
    CORRUPT_STUCK_AT:       type_str = "STUCK_AT_FAULT";
    CORRUPT_BRIDGING:       type_str = "BRIDGING_FAULT";
    CORRUPT_AGING:          type_str = "AGING_DEGRADATION";
    CORRUPT_EMI:            type_str = "EMI_INTERFERENCE";
    CORRUPT_SYSTEMATIC:     type_str = "SYSTEMATIC_FAULT";
    default:                type_str = "UNKNOWN_CORRUPT";
  endcase
  
  case (sev)
    SEVERITY_BENIGN:        severity_str = "BENIGN";
    SEVERITY_MINOR:         severity_str = "MINOR";
    SEVERITY_MODERATE:      severity_str = "MODERATE";
    SEVERITY_MAJOR:         severity_str = "MAJOR";
    SEVERITY_CRITICAL:      severity_str = "CRITICAL";
    SEVERITY_CATASTROPHIC:  severity_str = "CATASTROPHIC";
    default:                severity_str = "UNKNOWN";
  endcase
  
  return $sformatf("%s (%s severity)", type_str, severity_str);
endfunction : describe_corruption

//--------------------------------------------------------------------------------------------
// Function: generate_error_detection_bits
// Generates simple error detection bits for the data
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_signal_corruption_seq::generate_error_detection_bits(bit [31:0] data);
  bit [7:0] edc_bits;
  
  // Simple parity and checksum for error detection
  edc_bits[0] = ^data[7:0];    // Byte 0 parity
  edc_bits[1] = ^data[15:8];   // Byte 1 parity
  edc_bits[2] = ^data[23:16];  // Byte 2 parity
  edc_bits[3] = ^data[31:24];  // Byte 3 parity
  edc_bits[7:4] = data[3:0] + data[7:4] + data[11:8] + data[15:12]; // Simple checksum
  
  return {edc_bits, data[23:0]};
endfunction : generate_error_detection_bits

`endif