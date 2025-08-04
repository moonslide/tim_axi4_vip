`ifndef AXI4_MASTER_USER_PARITY_PROTECTION_SEQ_INCLUDED_
`define AXI4_MASTER_USER_PARITY_PROTECTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_parity_protection_seq
// Tests USER signals for parity protection functionality
// Implements even/odd parity schemes using USER signal bits for data integrity
//--------------------------------------------------------------------------------------------
class axi4_master_user_parity_protection_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_parity_protection_seq)
  
  // Configuration parameters
  int master_id = 0;
  int slave_id = 2;
  int num_transactions = 24;
  
  // Parity protection schemes
  typedef enum bit [1:0] {
    EVEN_PARITY = 2'b00,
    ODD_PARITY  = 2'b01,
    DUAL_PARITY = 2'b10,
    NO_PARITY   = 2'b11
  } parity_scheme_e;
  
  // Test scenarios with different parity protection schemes
  typedef struct {
    string test_name;
    parity_scheme_e scheme;
    bit [7:0] test_data;
    string description;
  } parity_test_t;
  
  parity_test_t parity_tests[] = '{
    '{"even_parity_0x00", EVEN_PARITY, 8'h00, "Even parity for 0x00 (0 bits set)"},
    '{"even_parity_0xFF", EVEN_PARITY, 8'hFF, "Even parity for 0xFF (8 bits set)"},
    '{"even_parity_0xA5", EVEN_PARITY, 8'hA5, "Even parity for 0xA5 (4 bits set)"},
    '{"even_parity_0x5A", EVEN_PARITY, 8'h5A, "Even parity for 0x5A (4 bits set)"},
    '{"odd_parity_0x01", ODD_PARITY, 8'h01, "Odd parity for 0x01 (1 bit set)"},
    '{"odd_parity_0x07", ODD_PARITY, 8'h07, "Odd parity for 0x07 (3 bits set)"},
    '{"odd_parity_0x0F", ODD_PARITY, 8'h0F, "Odd parity for 0x0F (4 bits set)"},
    '{"odd_parity_0x80", ODD_PARITY, 8'h80, "Odd parity for 0x80 (1 bit set)"},
    '{"dual_parity_0x3C", DUAL_PARITY, 8'h3C, "Dual parity (even+odd) for 0x3C"},
    '{"dual_parity_0xC3", DUAL_PARITY, 8'hC3, "Dual parity (even+odd) for 0xC3"},
    '{"dual_parity_0x69", DUAL_PARITY, 8'h69, "Dual parity (even+odd) for 0x69"},
    '{"dual_parity_0x96", DUAL_PARITY, 8'h96, "Dual parity (even+odd) for 0x96"}
  };
  
  // Transaction parameters
  rand bit [ADDRESS_WIDTH-1:0] base_addr;
  
  constraint base_addr_c {
    base_addr == (slave_id == 2) ? 64'h0000_0008_8000_0000 : 64'h0000_0008_0000_0000;
  }
  
  extern function new(string name = "axi4_master_user_parity_protection_seq");
  extern virtual task body();
  extern virtual task generate_parity_transaction(int test_idx, bit is_write);
  extern virtual function bit [31:0] calculate_parity_user_bits(bit [7:0] data, parity_scheme_e scheme);
  extern virtual function bit calculate_even_parity(bit [7:0] data);
  extern virtual function bit calculate_odd_parity(bit [7:0] data);
  
endclass : axi4_master_user_parity_protection_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_user_parity_protection_seq::new(string name = "axi4_master_user_parity_protection_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Generates transactions with parity protection USER signals
//-----------------------------------------------------------------------------
task axi4_master_user_parity_protection_seq::body();
  
  super.body();
  
  // Get configuration from config_db
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    `uvm_info(get_type_name(), "Using default master_id = 0", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    `uvm_info(get_type_name(), "Using default slave_id = 2", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "num_transactions", num_transactions)) begin
    `uvm_info(get_type_name(), "Using default num_transactions = 24", UVM_MEDIUM)
  end
  
  `uvm_info(get_type_name(), $sformatf("Starting USER parity protection sequence: Master[%0d] → Slave[%0d]",
                                        master_id, slave_id), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Testing %0d parity protection schemes", parity_tests.size()), UVM_MEDIUM)
  
  // Test each parity protection scheme with both write and read transactions
  for (int i = 0; i < parity_tests.size() && i < num_transactions; i++) begin
    `uvm_info(get_type_name(), $sformatf("Testing parity scheme %0d: %s - %s",
                                          i, parity_tests[i].test_name, parity_tests[i].description), UVM_HIGH)
    
    // Generate write transaction with parity protection
    generate_parity_transaction(i, 1'b1);
    #100;
    
    // Generate read transaction with parity protection
    generate_parity_transaction(i, 1'b0);
    #100;
  end
  
  `uvm_info(get_type_name(), $sformatf("USER parity protection sequence completed: %0d schemes tested",
                                        parity_tests.size()), UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Task: generate_parity_transaction
// Creates transactions with parity protection USER signals
//-----------------------------------------------------------------------------
task axi4_master_user_parity_protection_seq::generate_parity_transaction(int test_idx, bit is_write);
  
  parity_test_t current_test = parity_tests[test_idx];
  bit [31:0] parity_user_bits;
  
  parity_user_bits = calculate_parity_user_bits(current_test.test_data, current_test.scheme);
  
  if (is_write) begin
    // Generate write transaction with parity protection
    `uvm_do_with(req, {
      req.tx_type == WRITE;
      req.awaddr == base_addr + (test_idx * 'h100);
      req.awid == awid_e'(master_id % 16);
      req.awlen == 0; // Single transfer for parity testing
      req.awsize == WRITE_8_BYTES;
      req.awburst == WRITE_INCR;
      req.awqos == 4'h6; // Medium-high priority for parity protection
      req.awuser == parity_user_bits;
      req.wuser == {24'h000000, current_test.test_data}; // Embed test data in lower bits
    })
    
    `uvm_info(get_type_name(), $sformatf("WRITE %s: Data=0x%02h, AWUSER=0x%08h (parity bits), WUSER=0x%08h",
                                          current_test.test_name, current_test.test_data, 
                                          parity_user_bits, {24'h000000, current_test.test_data}), UVM_HIGH)
  end
  else begin
    // Generate read transaction with parity protection
    `uvm_do_with(req, {
      req.tx_type == READ;
      req.araddr == base_addr + (test_idx * 'h100) + 'h1000; // Offset for reads
      req.arid == arid_e'(master_id % 16);
      req.arlen == 0; // Single transfer for parity testing
      req.arsize == READ_8_BYTES;
      req.arburst == READ_INCR;
      req.arqos == 4'h6; // Medium-high priority for parity protection
      req.aruser == parity_user_bits;
    })
    
    `uvm_info(get_type_name(), $sformatf("READ %s: Expected data=0x%02h, ARUSER=0x%08h (parity bits)",
                                          current_test.test_name, current_test.test_data, parity_user_bits), UVM_HIGH)
  end
  
endtask : generate_parity_transaction

//-----------------------------------------------------------------------------
// Function: calculate_parity_user_bits
// Calculates USER signal bits for parity protection based on scheme
//-----------------------------------------------------------------------------
function bit [31:0] axi4_master_user_parity_protection_seq::calculate_parity_user_bits(bit [7:0] data, parity_scheme_e scheme);
  bit [31:0] user_bits = 32'h00000000;
  
  case (scheme)
    EVEN_PARITY: begin
      // Use bit [0] for even parity, rest for protection info
      user_bits[0] = calculate_even_parity(data);
      user_bits[7:4] = 4'b0001; // Scheme identifier
      user_bits[15:8] = data;   // Data copy for verification
    end
    
    ODD_PARITY: begin
      // Use bit [0] for odd parity, rest for protection info
      user_bits[0] = calculate_odd_parity(data);
      user_bits[7:4] = 4'b0010; // Scheme identifier
      user_bits[15:8] = data;   // Data copy for verification
    end
    
    DUAL_PARITY: begin
      // Use bits [1:0] for even and odd parity
      user_bits[0] = calculate_even_parity(data);
      user_bits[1] = calculate_odd_parity(data);
      user_bits[7:4] = 4'b0011; // Scheme identifier
      user_bits[15:8] = data;   // Data copy for verification
    end
    
    NO_PARITY: begin
      // No parity protection, just data identification
      user_bits[7:4] = 4'b0000; // Scheme identifier
      user_bits[15:8] = data;   // Data copy for verification
    end
  endcase
  
  // Add timestamp and master ID in upper bits
  user_bits[19:16] = master_id[3:0];
  user_bits[31:20] = $time & 12'hFFF; // 12-bit timestamp
  
  return user_bits;
endfunction : calculate_parity_user_bits

//-----------------------------------------------------------------------------
// Function: calculate_even_parity
// Calculates even parity bit for given data
//-----------------------------------------------------------------------------
function bit axi4_master_user_parity_protection_seq::calculate_even_parity(bit [7:0] data);
  bit parity = 1'b0;
  
  for (int i = 0; i < 8; i++) begin
    parity ^= data[i];
  end
  
  return parity; // XOR of all bits gives even parity
endfunction : calculate_even_parity

//-----------------------------------------------------------------------------
// Function: calculate_odd_parity
// Calculates odd parity bit for given data
//-----------------------------------------------------------------------------
function bit axi4_master_user_parity_protection_seq::calculate_odd_parity(bit [7:0] data);
  bit parity = 1'b0;
  
  for (int i = 0; i < 8; i++) begin
    parity ^= data[i];
  end
  
  return ~parity; // Invert even parity to get odd parity
endfunction : calculate_odd_parity

`endif