`ifndef AXI4_MASTER_USER_SIGNAL_PASSTHROUGH_SEQ_INCLUDED_
`define AXI4_MASTER_USER_SIGNAL_PASSTHROUGH_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_signal_passthrough_seq
// Tests USER signal passthrough on all AXI channels (AW, AR, W, B, R)
// Verifies that USER signals are correctly propagated from master to slave
//--------------------------------------------------------------------------------------------
class axi4_master_user_signal_passthrough_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_signal_passthrough_seq)
  
  // Configuration parameters
  int master_id = 0;
  int slave_id = 2;
  int num_transactions = 20;
  
  // USER signal test patterns
  bit [31:0] awuser_patterns[] = '{
    32'h00000000, 32'hFFFFFFFF, 32'hAAAAAAAA, 32'h55555555,
    32'h12345678, 32'h87654321, 32'hDEADBEEF, 32'hCAFEBABE,
    32'hF0F0F0F0, 32'h0F0F0F0F, 32'hC3C3C3C3, 32'h3C3C3C3C
  };
  
  bit [31:0] aruser_patterns[] = '{
    32'h11111111, 32'hEEEEEEEE, 32'hA5A5A5A5, 32'h5A5A5A5A,
    32'h9ABCDEF0, 32'h0FEDCBA9, 32'hBEEFDEAD, 32'hBABECAFE,
    32'h0F0F0F0F, 32'hF0F0F0F0, 32'h3C3C3C3C, 32'hC3C3C3C3
  };
  
  bit [31:0] wuser_patterns[] = '{
    32'h22222222, 32'hDDDDDDDD, 32'h96969696, 32'h69696969,
    32'hABCDEF12, 32'h21FEDCBA, 32'hADDEDEEF, 32'hFECABE
  };
  
  // Transaction parameters
  rand bit [ADDRESS_WIDTH-1:0] base_addr;
  
  constraint base_addr_c {
    base_addr == (slave_id == 2) ? 64'h0000_0008_8000_0000 : 64'h0000_0008_0000_0000;
  }
  
  extern function new(string name = "axi4_master_user_signal_passthrough_seq");
  extern virtual task body();
  extern virtual task generate_write_with_user_patterns(int txn_id);
  extern virtual task generate_read_with_user_patterns(int txn_id);
  
endclass : axi4_master_user_signal_passthrough_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_user_signal_passthrough_seq::new(string name = "axi4_master_user_signal_passthrough_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Generates transactions with specific USER signal patterns for passthrough testing
//-----------------------------------------------------------------------------
task axi4_master_user_signal_passthrough_seq::body();
  
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
  
  `uvm_info(get_type_name(), $sformatf("Starting USER signal passthrough sequence: Master[%0d] → Slave[%0d], %0d txns", 
                                        master_id, slave_id, num_transactions), UVM_MEDIUM)
  
  // Test write transactions with USER signal patterns
  for (int i = 0; i < num_transactions/2; i++) begin
    generate_write_with_user_patterns(i);
    #100; // Small delay between transactions
  end
  
  // Test read transactions with USER signal patterns  
  for (int i = 0; i < num_transactions/2; i++) begin
    generate_read_with_user_patterns(i);
    #100; // Small delay between transactions
  end
  
  `uvm_info(get_type_name(), $sformatf("USER signal passthrough sequence completed: %0d transactions generated", num_transactions), UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Task: generate_write_with_user_patterns
// Creates write transactions with specific USER signal patterns
//-----------------------------------------------------------------------------
task axi4_master_user_signal_passthrough_seq::generate_write_with_user_patterns(int txn_id);
  
  int awuser_idx = txn_id % awuser_patterns.size();
  int wuser_idx = txn_id % wuser_patterns.size();
  int burst_len = $urandom_range(0, 3);
  
  `uvm_do_with(req, {
    req.tx_type == WRITE;
    req.awaddr == base_addr + (txn_id * 'h100);
    req.awid == awid_e'(master_id % 16);
    req.awlen == burst_len; // Short bursts for clearer tracking
    req.awsize == WRITE_8_BYTES;
    req.awburst == WRITE_INCR;
    req.awqos == 4'h8; // Medium priority for consistent behavior
    req.awuser == awuser_patterns[awuser_idx];
    req.wuser == wuser_patterns[wuser_idx];
  })
  
  `uvm_info(get_type_name(), $sformatf("WRITE USER passthrough: TxnID=%0d, AWUSER=0x%08h, WUSER=0x%08h, Addr=0x%016h", 
                                        txn_id, awuser_patterns[awuser_idx], wuser_patterns[wuser_idx], 
                                        base_addr + (txn_id * 'h100)), UVM_HIGH)
  
endtask : generate_write_with_user_patterns

//-----------------------------------------------------------------------------
// Task: generate_read_with_user_patterns
// Creates read transactions with specific USER signal patterns
//-----------------------------------------------------------------------------
task axi4_master_user_signal_passthrough_seq::generate_read_with_user_patterns(int txn_id);
  
  int aruser_idx = txn_id % aruser_patterns.size();
  int burst_len = $urandom_range(0, 3);
  
  `uvm_do_with(req, {
    req.tx_type == READ;
    req.araddr == base_addr + (txn_id * 'h100) + 'h10000; // Offset to avoid write conflicts
    req.arid == arid_e'(master_id % 16);
    req.arlen == burst_len; // Short bursts for clearer tracking
    req.arsize == READ_8_BYTES;
    req.arburst == READ_INCR;
    req.arqos == 4'h8; // Medium priority for consistent behavior
    req.aruser == aruser_patterns[aruser_idx];
  })
  
  `uvm_info(get_type_name(), $sformatf("READ USER passthrough: TxnID=%0d, ARUSER=0x%08h, Addr=0x%016h", 
                                        txn_id, aruser_patterns[aruser_idx], 
                                        base_addr + (txn_id * 'h100) + 'h10000), UVM_HIGH)
  
endtask : generate_read_with_user_patterns

`endif