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
  
  // Configuration for bus matrix mode
  bit is_enhanced_mode = 0;
  int target_slave_id = 0;
  
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
  bit [63:0] base_addr;
  bit [63:0] addr_offset;
  
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
  
  // Use mode-aware address mapping
  
  if (!is_enhanced_mode) begin
    // 4x4 BASE mode addresses matching AXI_MATRIX.txt
    // S0: DDR_Memory at 0x0000_0100_0000_0000 (R/W)
    // S1: Boot_ROM at 0x0000_0000_0000_0000 (Read-Only)
    // S2: Peripheral_Regs at 0x0000_0010_0000_0000 (R/W)
    // S3: HW_Fuse_Box at 0x0000_0020_0000_0000 (Read-Only)
    // Only target writable slaves (0 and 2)
    if (target_slave_id == 1 || target_slave_id == 3) begin
      target_slave_id = (target_slave_id == 1) ? 0 : 2; // Redirect to writable slave
    end
    case(target_slave_id)
      0: base_addr = 64'h0000_0100_0000_0000; // DDR_Memory (R/W)
      2: base_addr = 64'h0000_0010_0000_0000; // Peripheral_Regs (R/W)
      default: base_addr = 64'h0000_0100_0000_0000; // Default to DDR
    endcase
  end else begin
    // 10x10 ENHANCED mode addresses
    // S3: Illegal Address Hole - NO ACCESS ALLOWED
    // S4: Instruction-only - READ-ONLY
    // S5: Read-only peripheral - READ-ONLY  
    // Redirect to writable slaves only (0, 1, 2, 6, 7, 8, 9)
    if (target_slave_id == 3 || target_slave_id == 4 || target_slave_id == 5) begin
      // Redirect to a writable slave
      case(target_slave_id)
        3: target_slave_id = 0; // S3 is illegal, use S0 instead
        4: target_slave_id = 1; // S4 is instruction-only, use S1 instead
        5: target_slave_id = 2; // S5 is read-only, use S2 instead
        default: target_slave_id = 0;
      endcase
    end
    
    case(target_slave_id)
      0: base_addr = 64'h0000_0008_0000_0000; // DDR Secure (R/W)
      1: base_addr = 64'h0000_0008_4000_0000; // DDR Non-Secure (R/W)
      2: base_addr = 64'h0000_0008_8000_0000; // DDR Shared (R/W)
      3: base_addr = 64'h0000_0008_c000_0000; // Illegal - should never reach here
      4: base_addr = 64'h0000_0009_0000_0000; // Instruction-only - should never reach here
      5: base_addr = 64'h0000_000a_0000_0000; // Read-only - should never reach here
      6: base_addr = 64'h0000_000a_0001_0000; // Privileged-Only (R/W)
      7: base_addr = 64'h0000_000a_0002_0000; // Secure-Only (R/W)
      8: base_addr = 64'h0000_000a_0003_0000; // Non-Secure (R/W)
      9: base_addr = 64'h0000_000a_0004_0000; // Exclusive Monitor (R/W)
      default: base_addr = 64'h0000_0008_0000_0000;
    endcase
  end
  
  addr_offset = $urandom() & 64'hFFF;
  
  if(!req.randomize() with {
    req.transfer_type == NON_BLOCKING_WRITE;
    req.awburst == WRITE_INCR;
    req.awsize == WRITE_4_BYTES;
    req.awlen == 8'h00;  // Single beat burst
    req.awuser == final_user_signal;
    req.wuser == final_user_signal;  // Same parity protection for write data
    req.awaddr == local::base_addr + local::addr_offset; // Add small offset within slave range
    // Constrain AWID based on bus matrix mode and access control rules
    if (!local::is_enhanced_mode) {
      // 4x4 mode: Slave 2 only allows masters 0, 1, 2
      if (local::target_slave_id == 2) {
        req.awid inside {AWID_0, AWID_1, AWID_2};
      } else {
        req.awid inside {AWID_0, AWID_1, AWID_2, AWID_3};
      }
    } else {
      // 10x10 mode: All masters allowed for writable slaves
      // Since we're redirecting slaves 3, 4, 5 to slaves 0, 1, 2
      // and those allow all masters, we can use any master ID
      req.awid inside {AWID_0, AWID_1, AWID_2, AWID_3, AWID_4, AWID_5, AWID_6, AWID_7, AWID_8, AWID_9};
    }
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