`ifndef AXI4_MASTER_USER_SIGNAL_WIDTH_MISMATCH_SEQ_INCLUDED_
`define AXI4_MASTER_USER_SIGNAL_WIDTH_MISMATCH_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_signal_width_mismatch_seq
// Tests USER signal behavior with different width patterns
// Verifies system handles USER signals of various effective widths correctly
//--------------------------------------------------------------------------------------------
class axi4_master_user_signal_width_mismatch_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_signal_width_mismatch_seq)
  
  // Configuration parameters
  int master_id = 0;
  int slave_id = 2;
  int num_transactions = 16;
  
  // USER signal width test scenarios
  typedef struct {
    string test_name;
    bit [31:0] awuser_pattern;
    bit [31:0] aruser_pattern;
    bit [31:0] wuser_pattern;
    string description;
  } user_width_test_t;
  
  user_width_test_t width_tests[] = '{
    // Test different effective widths by using specific bit patterns
    '{"8bit_effective", 32'h000000FF, 32'h000000AA, 32'h00000055, "8-bit effective width"},
    '{"16bit_effective", 32'h0000FFFF, 32'h0000AAAA, 32'h00005555, "16-bit effective width"},
    '{"24bit_effective", 32'h00FFFFFF, 32'h00AAAAAA, 32'h00555555, "24-bit effective width"},
    '{"32bit_full", 32'hFFFFFFFF, 32'hAAAAAAAA, 32'h55555555, "Full 32-bit width"},
    '{"sparse_bits", 32'h80402010, 32'h40201008, 32'h20100804, "Sparse bit patterns"},
    '{"alternating", 32'hA5A5A5A5, 32'h5A5A5A5A, 32'hC3C3C3C3, "Alternating patterns"},
    '{"boundary_max", 32'hFFFFFFFE, 32'hFFFFFFFD, 32'hFFFFFFFB, "Near maximum values"},
    '{"boundary_min", 32'h00000001, 32'h00000002, 32'h00000004, "Near minimum values"},
    '{"walking_ones", 32'h00000001, 32'h00000010, 32'h00000100, "Walking ones pattern"},
    '{"walking_zeros", 32'hFFFFFFFE, 32'hFFFFFFEF, 32'hFFFFFEFF, "Walking zeros pattern"},
    '{"mixed_density", 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFF00FF00, "Mixed bit density"},
    '{"random_like", 32'h9A7B5C3D, 32'h6E4F2A1B, 32'h8D6C4B2A, "Random-like patterns"}
  };
  
  // Transaction parameters
  rand bit [ADDRESS_WIDTH-1:0] base_addr;
  
  constraint base_addr_c {
    base_addr == (slave_id == 2) ? 64'h0000_0008_8000_0000 : 64'h0000_0008_0000_0000;
  }
  
  extern function new(string name = "axi4_master_user_signal_width_mismatch_seq");
  extern virtual task body();
  extern virtual task generate_width_test_transaction(int test_idx, bit is_write);
  
endclass : axi4_master_user_signal_width_mismatch_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_user_signal_width_mismatch_seq::new(string name = "axi4_master_user_signal_width_mismatch_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Generates transactions with various USER signal width patterns
//-----------------------------------------------------------------------------
task axi4_master_user_signal_width_mismatch_seq::body();
  
  super.body();
  
  // Get configuration from config_db
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    `uvm_info(get_type_name(), "Using default master_id = 0", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    `uvm_info(get_type_name(), "Using default slave_id = 2", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "num_transactions", num_transactions)) begin
    `uvm_info(get_type_name(), "Using default num_transactions = 16", UVM_MEDIUM)
  end
  
  // Set base_addr based on the slave_id configuration
  base_addr = (slave_id == 2) ? 64'h0000_0008_8000_0000 : 64'h0000_0008_0000_0000;
  
  `uvm_info(get_type_name(), $sformatf("Starting USER signal width mismatch sequence: Master[%0d] → Slave[%0d], Base addr=0x%016h", 
                                        master_id, slave_id, base_addr), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Testing %0d different width patterns", width_tests.size()), UVM_MEDIUM)
  
  // Test each width pattern with both write and read transactions
  for (int i = 0; i < width_tests.size() && i < num_transactions; i++) begin
    `uvm_info(get_type_name(), $sformatf("Testing pattern %0d: %s - %s", 
                                          i, width_tests[i].test_name, width_tests[i].description), UVM_HIGH)
    
    // Generate write transaction with this pattern
    generate_width_test_transaction(i, 1'b1);
    #50;
    
    // Generate read transaction with this pattern  
    generate_width_test_transaction(i, 1'b0);
    #50;
  end
  
  `uvm_info(get_type_name(), $sformatf("USER signal width mismatch sequence completed: %0d patterns tested", 
                                        width_tests.size()), UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Task: generate_width_test_transaction
// Creates transactions with specific USER width patterns
//-----------------------------------------------------------------------------
task axi4_master_user_signal_width_mismatch_seq::generate_width_test_transaction(int test_idx, bit is_write);
  
  user_width_test_t current_test = width_tests[test_idx];
  
  if (is_write) begin
    // Generate write transaction
    `uvm_do_with(req, {
      req.tx_type == WRITE;
      req.awaddr == base_addr + (test_idx * 'h200);
      req.awid == awid_e'(master_id % 16);
      req.awlen == 1; // Use burst of 2 for width testing
      req.awsize == WRITE_8_BYTES;
      req.awburst == WRITE_INCR;
      req.awqos == 4'h4; // Low priority to avoid interference
      req.awuser == current_test.awuser_pattern;
      req.wuser == current_test.wuser_pattern;
    })
    
    `uvm_info(get_type_name(), $sformatf("WRITE %s: AWUSER=0x%08h, WUSER=0x%08h, Addr=0x%016h", 
                                          current_test.test_name, current_test.awuser_pattern, 
                                          current_test.wuser_pattern, base_addr + (test_idx * 'h200)), UVM_HIGH)
  end
  else begin
    // Generate read transaction
    `uvm_do_with(req, {
      req.tx_type == READ;
      req.araddr == base_addr + (test_idx * 'h200) + 'h20000; // Offset for reads
      req.arid == arid_e'(master_id % 16);
      req.arlen == 1; // Use burst of 2 for width testing
      req.arsize == READ_8_BYTES;
      req.arburst == READ_INCR;
      req.arqos == 4'h4; // Low priority to avoid interference
      req.aruser == current_test.aruser_pattern;
    })
    
    `uvm_info(get_type_name(), $sformatf("READ %s: ARUSER=0x%08h, Addr=0x%016h", 
                                          current_test.test_name, current_test.aruser_pattern, 
                                          base_addr + (test_idx * 'h200) + 'h20000), UVM_HIGH)
  end
  
endtask : generate_width_test_transaction

`endif