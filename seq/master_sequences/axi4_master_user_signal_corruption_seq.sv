`ifndef AXI4_MASTER_USER_SIGNAL_CORRUPTION_SEQ_INCLUDED_
`define AXI4_MASTER_USER_SIGNAL_CORRUPTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_signal_corruption_seq
// Tests USER signal corruption scenarios to verify error detection and recovery
// Implements various corruption patterns to test system resilience
//--------------------------------------------------------------------------------------------
class axi4_master_user_signal_corruption_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_signal_corruption_seq)
  
  // Configuration parameters
  int master_id = 0;
  int slave_id = 2;
  int num_transactions = 20;
  
  // Corruption types
  typedef enum bit [3:0] {
    CORRUPTION_SINGLE_BIT     = 4'b0000, // Single bit flip
    CORRUPTION_MULTIPLE_BITS  = 4'b0001, // Multiple random bit flips
    CORRUPTION_BURST_ERROR    = 4'b0010, // Burst of consecutive bit errors
    CORRUPTION_PATTERN_SHIFT  = 4'b0011, // Bit pattern shift/rotation
    CORRUPTION_STUCK_BITS     = 4'b0100, // Stuck-at-0 or stuck-at-1 faults
    CORRUPTION_INTERMITTENT   = 4'b0101, // Intermittent corruption
    CORRUPTION_GRADUAL_DECAY  = 4'b0110, // Gradual signal degradation
    CORRUPTION_CROSS_TALK     = 4'b0111, // Cross-talk between signals
    CORRUPTION_POWER_GLITCH   = 4'b1000, // Power supply glitch effects
    CORRUPTION_TEMPERATURE    = 4'b1001, // Temperature-induced errors
    CORRUPTION_EMI_NOISE      = 4'b1010, // Electromagnetic interference
    CORRUPTION_TIMING_SKEW    = 4'b1011, // Timing-related corruption
    CORRUPTION_PARTIAL_LOSS   = 4'b1100, // Partial signal loss
    CORRUPTION_COMPLETE_LOSS  = 4'b1101, // Complete signal loss
    CORRUPTION_INVERSION      = 4'b1110, // Signal inversion
    CORRUPTION_RANDOM_CHAOS   = 4'b1111  // Complete random corruption
  } corruption_type_e;
  
  // Corruption test scenarios
  typedef struct {
    string test_name;
    corruption_type_e corruption_type;
    bit [31:0] original_pattern;
    bit [31:0] corruption_mask;
    real corruption_probability;
    bit recoverable;
    string description;
  } corruption_test_t;
  
  corruption_test_t corruption_tests[] = '{
    // Single bit corruption
    '{"single_bit_0", CORRUPTION_SINGLE_BIT, 32'h12345678, 32'h00000001, 0.1, 1'b1, "Single bit 0 corruption"},
    '{"single_bit_15", CORRUPTION_SINGLE_BIT, 32'hABCDEF00, 32'h00008000, 0.1, 1'b1, "Single bit 15 corruption"},
    '{"single_bit_31", CORRUPTION_SINGLE_BIT, 32'h55555555, 32'h80000000, 0.1, 1'b1, "Single bit 31 corruption"},
    
    // Multiple bit corruption
    '{"multi_bit_3", CORRUPTION_MULTIPLE_BITS, 32'hDEADBEEF, 32'h00000007, 0.3, 1'b1, "3-bit corruption pattern"},
    '{"multi_bit_scattered", CORRUPTION_MULTIPLE_BITS, 32'hCAFEBABE, 32'h81020408, 0.2, 1'b1, "Scattered bit corruption"},
    
    // Burst error corruption
    '{"burst_low_nibble", CORRUPTION_BURST_ERROR, 32'h0F0F0F0F, 32'h0000000F, 0.5, 1'b1, "Low nibble burst error"},
    '{"burst_byte_1", CORRUPTION_BURST_ERROR, 32'hF0F0F0F0, 32'h0000FF00, 0.4, 1'b1, "Byte 1 burst error"},
    '{"burst_high_word", CORRUPTION_BURST_ERROR, 32'h12348765, 32'hFFFF0000, 0.6, 1'b0, "High word burst error"},
    
    // Pattern shift corruption
    '{"shift_left_1", CORRUPTION_PATTERN_SHIFT, 32'hA5A5A5A5, 32'h4B4B4B4B, 0.0, 1'b1, "1-bit left shift"},
    '{"shift_right_4", CORRUPTION_PATTERN_SHIFT, 32'h87654321, 32'h08765432, 0.0, 1'b1, "4-bit right shift"},
    
    // Stuck bit faults
    '{"stuck_at_0", CORRUPTION_STUCK_BITS, 32'hFFFFFFFF, 32'h00000000, 1.0, 1'b0, "All bits stuck at 0"},
    '{"stuck_at_1", CORRUPTION_STUCK_BITS, 32'h00000000, 32'hFFFFFFFF, 1.0, 1'b0, "All bits stuck at 1"},
    '{"stuck_mixed", CORRUPTION_STUCK_BITS, 32'h5A5A5A5A, 32'hF0F0F0F0, 0.7, 1'b0, "Mixed stuck bits"},
    
    // Intermittent corruption
    '{"intermittent_glitch", CORRUPTION_INTERMITTENT, 32'h33CC33CC, 32'h0C030C03, 0.15, 1'b1, "Intermittent glitches"},
    '{"power_fluctuation", CORRUPTION_POWER_GLITCH, 32'h96696969, 32'h69969696, 0.25, 1'b1, "Power glitch effects"},
    
    // Environmental corruption
    '{"temperature_drift", CORRUPTION_TEMPERATURE, 32'hAAAA5555, 32'h5555AAAA, 0.2, 1'b1, "Temperature-induced drift"},
    '{"emi_interference", CORRUPTION_EMI_NOISE, 32'hC3C3C3C3, 32'h3C3C3C3C, 0.3, 1'b1, "EMI noise corruption"},
    
    // Severe corruption
    '{"partial_loss", CORRUPTION_PARTIAL_LOSS, 32'hFEDCBA98, 32'h0000BA98, 0.5, 1'b0, "Partial signal loss"},
    '{"complete_loss", CORRUPTION_COMPLETE_LOSS, 32'h13579BDF, 32'h00000000, 1.0, 1'b0, "Complete signal loss"},
    '{"signal_inversion", CORRUPTION_INVERSION, 32'h24681357, 32'hDB97ECA8, 1.0, 1'b1, "Complete signal inversion"},
    '{"random_chaos", CORRUPTION_RANDOM_CHAOS, 32'h87654321, 32'h12345678, 0.8, 1'b0, "Random chaos corruption"}
  };
  
  // Transaction parameters
  rand bit [ADDRESS_WIDTH-1:0] base_addr;
  
  constraint base_addr_c {
    base_addr == (slave_id == 2) ? 64'h0000_0008_8000_0000 : 64'h0000_0008_0000_0000;
  }
  
  extern function new(string name = "axi4_master_user_signal_corruption_seq");
  extern virtual task body();
  extern virtual task generate_corruption_transaction(int test_idx, bit is_write);
  extern virtual function bit [31:0] apply_corruption(bit [31:0] original, corruption_test_t test_info);
  extern virtual function bit [31:0] generate_random_corruption(corruption_type_e ctype);
  
endclass : axi4_master_user_signal_corruption_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_user_signal_corruption_seq::new(string name = "axi4_master_user_signal_corruption_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Generates transactions with USER signal corruption
//-----------------------------------------------------------------------------
task axi4_master_user_signal_corruption_seq::body();
  
  super.body();
  
  // Get configuration from config_db
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    `uvm_info(get_type_name(), "Using default master_id = 0", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    `uvm_info(get_type_name(), "Using default slave_id = 2", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "num_transactions", num_transactions)) begin
    `uvm_info(get_type_name(), "Using default num_transactions = 20", UVM_MEDIUM)
  end
  
  `uvm_info(get_type_name(), $sformatf("Starting USER signal corruption sequence: Master[%0d] → Slave[%0d]",
                                        master_id, slave_id), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Testing %0d corruption scenarios", corruption_tests.size()), UVM_MEDIUM)
  `uvm_info(get_type_name(), "WARNING: This test intentionally corrupts USER signals", UVM_MEDIUM)
  
  // Test each corruption scenario
  for (int i = 0; i < corruption_tests.size() && i < num_transactions; i++) begin
    `uvm_info(get_type_name(), $sformatf("Testing corruption %0d: %s - %s",
                                          i, corruption_tests[i].test_name, corruption_tests[i].description), UVM_HIGH)
    
    // Generate write transaction with corruption
    generate_corruption_transaction(i, 1'b1);
    #250; // Longer delay to observe corruption effects
  end
  
  `uvm_info(get_type_name(), $sformatf("USER signal corruption sequence completed: %0d corruptions tested",
                                        corruption_tests.size()), UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected: System should detect and handle corrupted USER signals appropriately", UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Task: generate_corruption_transaction
// Creates transactions with intentional USER signal corruption
//-----------------------------------------------------------------------------
task axi4_master_user_signal_corruption_seq::generate_corruption_transaction(int test_idx, bit is_write);
  
  corruption_test_t current_test = corruption_tests[test_idx];
  bit [31:0] corrupted_awuser, corrupted_aruser, corrupted_wuser;
  int burst_len = $urandom_range(0, 2);
  
  // Apply corruption to USER signals
  corrupted_awuser = apply_corruption(current_test.original_pattern, current_test);
  corrupted_aruser = apply_corruption(current_test.original_pattern ^ 32'h11111111, current_test); // Slight variation
  corrupted_wuser  = apply_corruption(current_test.original_pattern ^ 32'h22222222, current_test); // Slight variation
  
  if (is_write) begin
    // Generate write transaction with corrupted USER signals
    `uvm_do_with(req, {
      req.tx_type == WRITE;
      req.awaddr == base_addr + (test_idx * 'h400);
      req.awid == awid_e'(master_id % 16);
      req.awlen == burst_len; // Short to medium bursts
      req.awsize == WRITE_8_BYTES;
      req.awburst == WRITE_INCR;
      req.awqos == current_test.recoverable ? 4'h6 : 4'hE; // Higher QoS for non-recoverable errors
      req.awuser == corrupted_awuser; // Intentionally corrupted
      req.wuser == corrupted_wuser;   // Intentionally corrupted
    })
    
    `uvm_info(get_type_name(), $sformatf("WRITE CORRUPTION %s: Type=%0d, Recoverable=%0b, Prob=%0.2f",
                                          current_test.test_name, current_test.corruption_type,
                                          current_test.recoverable, current_test.corruption_probability), UVM_HIGH)
    `uvm_info(get_type_name(), $sformatf("  Original=0x%08h → AWUSER=0x%08h, WUSER=0x%08h",
                                          current_test.original_pattern, corrupted_awuser, corrupted_wuser), UVM_HIGH)
  end
  else begin
    // Generate read transaction with corrupted USER signals
    `uvm_do_with(req, {
      req.tx_type == READ;
      req.araddr == base_addr + (test_idx * 'h400) + 'h5000; // Offset for reads
      req.arid == arid_e'(master_id % 16);
      req.arlen == burst_len; // Short to medium bursts
      req.arsize == READ_8_BYTES;
      req.arburst == READ_INCR;
      req.arqos == current_test.recoverable ? 4'h6 : 4'hE; // Higher QoS for non-recoverable errors
      req.aruser == corrupted_aruser; // Intentionally corrupted
    })
    
    `uvm_info(get_type_name(), $sformatf("READ CORRUPTION %s: Type=%0d, Recoverable=%0b",
                                          current_test.test_name, current_test.corruption_type,
                                          current_test.recoverable), UVM_HIGH)
    `uvm_info(get_type_name(), $sformatf("  Original=0x%08h → ARUSER=0x%08h",
                                          current_test.original_pattern, corrupted_aruser), UVM_HIGH)
  end
  
endtask : generate_corruption_transaction

//-----------------------------------------------------------------------------
// Function: apply_corruption
// Applies corruption pattern to original USER signal value
//-----------------------------------------------------------------------------
function bit [31:0] axi4_master_user_signal_corruption_seq::apply_corruption(bit [31:0] original, corruption_test_t test_info);
  bit [31:0] corrupted;
  bit [31:0] random_mask;
  
  case (test_info.corruption_type)
    CORRUPTION_SINGLE_BIT: begin
      // Single bit flip at specified position
      corrupted = original ^ test_info.corruption_mask;
    end
    
    CORRUPTION_MULTIPLE_BITS: begin
      // Multiple bit flips at specified positions
      corrupted = original ^ test_info.corruption_mask;
    end
    
    CORRUPTION_BURST_ERROR: begin
      // Burst error in consecutive bits
      corrupted = (original & ~test_info.corruption_mask) | 
                  (test_info.corruption_mask & generate_random_corruption(CORRUPTION_BURST_ERROR));
    end
    
    CORRUPTION_PATTERN_SHIFT: begin
      // Use corruption_mask as the shifted pattern directly
      corrupted = test_info.corruption_mask;
    end
    
    CORRUPTION_STUCK_BITS: begin
      // Force certain bits to stuck values
      random_mask = $urandom() & test_info.corruption_mask;
      corrupted = (original & ~test_info.corruption_mask) | random_mask;
    end
    
    CORRUPTION_INTERMITTENT: begin
      // Probabilistic bit corruption
      random_mask = $urandom();
      if ($urandom_range(0, 99) < int'(test_info.corruption_probability * 100.0)) begin
        corrupted = original ^ (test_info.corruption_mask & random_mask);
      end else begin
        corrupted = original;
      end
    end
    
    CORRUPTION_GRADUAL_DECAY: begin
      // Gradual signal degradation
      corrupted = original & ~($urandom() & test_info.corruption_mask);
    end
    
    CORRUPTION_CROSS_TALK: begin
      // Cross-talk corruption (mix with neighboring signals)
      corrupted = (original & ~test_info.corruption_mask) | 
                  (test_info.corruption_mask & ($urandom() ^ original));
    end
    
    CORRUPTION_POWER_GLITCH: begin
      // Power glitch effects
      corrupted = test_info.corruption_mask; // Direct replacement
    end
    
    CORRUPTION_TEMPERATURE: begin
      // Temperature-induced errors
      corrupted = test_info.corruption_mask; // Direct replacement
    end
    
    CORRUPTION_EMI_NOISE: begin
      // EMI noise corruption
      corrupted = test_info.corruption_mask; // Direct replacement
    end
    
    CORRUPTION_TIMING_SKEW: begin
      // Timing-related corruption
      corrupted = original ^ test_info.corruption_mask;
    end
    
    CORRUPTION_PARTIAL_LOSS: begin
      // Partial signal loss
      corrupted = test_info.corruption_mask; // Direct replacement
    end
    
    CORRUPTION_COMPLETE_LOSS: begin
      // Complete signal loss (all zeros)
      corrupted = 32'h00000000;
    end
    
    CORRUPTION_INVERSION: begin
      // Signal inversion
      corrupted = test_info.corruption_mask; // Direct replacement
    end
    
    CORRUPTION_RANDOM_CHAOS: begin
      // Complete random corruption
      corrupted = $urandom();
    end
    
    default: begin
      // Default to XOR with corruption mask
      corrupted = original ^ test_info.corruption_mask;
    end
  endcase
  
  return corrupted;
endfunction : apply_corruption

//-----------------------------------------------------------------------------
// Function: generate_random_corruption
// Generates random corruption patterns for specific corruption types
//-----------------------------------------------------------------------------
function bit [31:0] axi4_master_user_signal_corruption_seq::generate_random_corruption(corruption_type_e ctype);
  bit [31:0] random_pattern;
  
  case (ctype)
    CORRUPTION_BURST_ERROR: begin
      // Generate burst error pattern
      random_pattern = $urandom() | ($urandom() << 8) | ($urandom() << 16);
    end
    
    CORRUPTION_INTERMITTENT: begin
      // Generate intermittent error pattern
      random_pattern = $urandom() & $urandom(); // Reduce bit density
    end
    
    default: begin
      random_pattern = $urandom();
    end
  endcase
  
  return random_pattern;
endfunction : generate_random_corruption

`endif