`ifndef AXI4_MASTER_USER_PARITY_SEQ_INCLUDED_
`define AXI4_MASTER_USER_PARITY_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_parity_seq
// Master sequence for USER signal parity protection testing
// Generates transactions with parity-protected USER signals
//--------------------------------------------------------------------------------------------
class axi4_master_user_parity_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_parity_seq)

  // Parity configuration
  rand bit parity_enable;
  rand bit inject_error;
  rand bit [1:0] error_type; // 0=no error, 1=single bit, 2=double bit, 3=burst
  rand bit [23:0] user_data_payload;
  
  // Error injection location
  rand bit [4:0] error_bit_position;
  
  // Constraints
  constraint parity_cfg_c {
    parity_enable dist {1 := 90, 0 := 10};
    inject_error dist {0 := 70, 1 := 30};
    error_type dist {0 := 60, 1 := 25, 2 := 10, 3 := 5};
    error_bit_position inside {[0:23]};
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_user_parity_seq");
  extern task body();
  extern function bit [31:0] encode_user_with_parity(bit [23:0] data, bit enable);
  extern function bit calculate_parity(bit [31:0] data, int start_bit, int end_bit);
  extern function bit [31:0] inject_parity_error(bit [31:0] data);
  extern function bit verify_parity(bit [31:0] user_signal);

endclass : axi4_master_user_parity_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the sequence
//
// Parameters:
//  name - axi4_master_user_parity_seq
//--------------------------------------------------------------------------------------------
function axi4_master_user_parity_seq::new(string name = "axi4_master_user_parity_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and sends transactions with parity-protected USER signals
//--------------------------------------------------------------------------------------------
task axi4_master_user_parity_seq::body();
  bit [31:0] protected_user_signal;
  bit [31:0] final_user_signal;
  bit parity_valid;
  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  
  // Generate protected USER signal with parity
  protected_user_signal = encode_user_with_parity(user_data_payload, parity_enable);
  
  // Optionally inject errors for testing
  if (inject_error && parity_enable) begin
    final_user_signal = inject_parity_error(protected_user_signal);
    `uvm_info(get_type_name(), $sformatf("Injecting parity error - Original: 0x%08h, Corrupted: 0x%08h", 
              protected_user_signal, final_user_signal), UVM_MEDIUM)
  end
  else begin
    final_user_signal = protected_user_signal;
  end
  
  // Verify parity (for demonstration)
  if (parity_enable) begin
    parity_valid = verify_parity(final_user_signal);
    `uvm_info(get_type_name(), $sformatf("USER Parity Check: %s (Data: 0x%06h, Full: 0x%08h)", 
              parity_valid ? "PASS" : "FAIL", user_data_payload, final_user_signal), UVM_MEDIUM)
  end
  
  if(!req.randomize() with {
    req.transfer_type == NON_BLOCKING_WRITE;
    req.awburst == WRITE_INCR;
    req.awsize == WRITE_4_BYTES;
    req.awlen == 8'h00;  // Single beat burst
    req.awuser == final_user_signal;
    req.wuser == final_user_signal;  // Same parity protection for write data
    req.awaddr inside {[64'h8_0000_0000:64'h8_3FFF_FFF0],  // Slave 0
                       [64'h8_4000_0000:64'h8_7FFF_FFF0],  // Slave 1
                       [64'h8_8000_0000:64'h8_BFFF_FFF0]};  // Slave 2
  }) begin
    `uvm_fatal("axi4", "Randomization failed for USER parity sequence")
  end
  
  finish_item(req);
  
endtask : body

//--------------------------------------------------------------------------------------------
// Function: encode_user_with_parity
// Encodes USER signal with multiple levels of parity protection
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_parity_seq::encode_user_with_parity(bit [23:0] data, bit enable);
  bit [31:0] user_signal;
  bit [3:0] nibble_parity;
  bit [1:0] byte_parity;
  bit overall_parity;
  
  // Start with data payload
  user_signal[23:0] = data;
  
  if (enable) begin
    // Calculate nibble parity (6 nibbles in 24 bits, use 4 parity bits)
    nibble_parity[0] = calculate_parity({28'h0, data[3:0]}, 0, 3);
    nibble_parity[1] = calculate_parity({28'h0, data[7:4]}, 0, 3);
    nibble_parity[2] = calculate_parity({28'h0, data[11:8]}, 0, 3);
    nibble_parity[3] = calculate_parity({28'h0, data[15:12]}, 0, 3);
    
    // Calculate byte parity
    byte_parity[0] = calculate_parity({24'h0, data[7:0]}, 0, 7);
    byte_parity[1] = calculate_parity({24'h0, data[15:8]}, 0, 7);
    
    // Calculate overall parity for entire data payload
    overall_parity = calculate_parity({8'h0, data}, 0, 23);
    
    // Assemble the USER signal
    user_signal[27:24] = nibble_parity;
    user_signal[29:28] = byte_parity;
    user_signal[30] = overall_parity;
    user_signal[31] = 1'b1; // Parity enable flag
  end
  else begin
    user_signal[31:24] = 8'h00; // No parity protection
  end
  
  return user_signal;
endfunction : encode_user_with_parity

//--------------------------------------------------------------------------------------------
// Function: calculate_parity
// Calculates even parity for specified bit range
//--------------------------------------------------------------------------------------------
function bit axi4_master_user_parity_seq::calculate_parity(bit [31:0] data, int start_bit, int end_bit);
  bit parity = 0;
  
  for (int i = start_bit; i <= end_bit; i++) begin
    parity ^= data[i];
  end
  
  return parity;
endfunction : calculate_parity

//--------------------------------------------------------------------------------------------
// Function: inject_parity_error
// Injects errors into the USER signal for testing
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_parity_seq::inject_parity_error(bit [31:0] data);
  bit [31:0] corrupted_data;
  
  corrupted_data = data;
  
  case (error_type)
    1: begin // Single bit error
      corrupted_data[error_bit_position] = ~corrupted_data[error_bit_position];
    end
    
    2: begin // Double bit error
      corrupted_data[error_bit_position] = ~corrupted_data[error_bit_position];
      corrupted_data[(error_bit_position + 7) % 24] = ~corrupted_data[(error_bit_position + 7) % 24];
    end
    
    3: begin // Burst error (3 consecutive bits)
      for (int i = 0; i < 3; i++) begin
        int bit_pos = (error_bit_position + i) % 24;
        corrupted_data[bit_pos] = ~corrupted_data[bit_pos];
      end
    end
    
    default: begin
      // No error injection
    end
  endcase
  
  return corrupted_data;
endfunction : inject_parity_error

//--------------------------------------------------------------------------------------------
// Function: verify_parity
// Verifies parity protection in USER signal
//--------------------------------------------------------------------------------------------
function bit axi4_master_user_parity_seq::verify_parity(bit [31:0] user_signal);
  bit [23:0] data;
  bit [3:0] nibble_parity;
  bit [1:0] byte_parity;
  bit overall_parity;
  bit parity_enable;
  bit all_checks_pass;
  
  // Extract fields
  data = user_signal[23:0];
  nibble_parity = user_signal[27:24];
  byte_parity = user_signal[29:28];
  overall_parity = user_signal[30];
  parity_enable = user_signal[31];
  
  if (!parity_enable) begin
    return 1'b1; // No parity checking if disabled
  end
  
  all_checks_pass = 1'b1;
  
  // Verify nibble parity
  if (nibble_parity[0] != calculate_parity({28'h0, data[3:0]}, 0, 3)) all_checks_pass = 0;
  if (nibble_parity[1] != calculate_parity({28'h0, data[7:4]}, 0, 3)) all_checks_pass = 0;
  if (nibble_parity[2] != calculate_parity({28'h0, data[11:8]}, 0, 3)) all_checks_pass = 0;
  if (nibble_parity[3] != calculate_parity({28'h0, data[15:12]}, 0, 3)) all_checks_pass = 0;
  
  // Verify byte parity
  if (byte_parity[0] != calculate_parity({24'h0, data[7:0]}, 0, 7)) all_checks_pass = 0;
  if (byte_parity[1] != calculate_parity({24'h0, data[15:8]}, 0, 7)) all_checks_pass = 0;
  
  // Verify overall parity
  if (overall_parity != calculate_parity({8'h0, data}, 0, 23)) all_checks_pass = 0;
  
  return all_checks_pass;
endfunction : verify_parity

`endif