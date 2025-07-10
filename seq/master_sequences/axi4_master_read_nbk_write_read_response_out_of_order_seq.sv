`ifndef AXI4_MASTER_READ_NBK_WRITE_READ_RESPONSE_OUT_OF_ORDER_SEQ_INCLUDED_
`define AXI4_MASTER_READ_NBK_WRITE_READ_RESPONSE_OUT_OF_ORDER_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_read_nbk_write_read_response_out_of_order_seq
// True AXI4 out-of-order read sequence with address coordination for read-after-write verification
// Follows ARM AMBA AXI4 specification for out-of-order transaction testing
//--------------------------------------------------------------------------------------------
class axi4_master_read_nbk_write_read_response_out_of_order_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_read_nbk_write_read_response_out_of_order_seq)

  // Import static storage from write sequence for address coordination
  static bit [63:0] write_addr_pool[8];  // Pool of addresses to read from
  static bit [31:0] write_data_pool[8];  // Expected data at each address
  static bit [3:0]  write_id_pool[8];    // Original AWID used for each write
  static int        read_count = 0;      // Number of reads completed

  // Transaction ID for this read (different for each transaction to enable out-of-order)
  rand bit [3:0] transaction_arid;
  
  // Address range for out-of-order testing  
  constraint addr_range_c {
    transaction_arid inside {4'h8, 4'h9, 4'hA, 4'hB, 4'hC, 4'hD, 4'hE, 4'hF};
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_read_nbk_write_read_response_out_of_order_seq");
  extern task body();
  extern function void import_write_pool();

endclass : axi4_master_read_nbk_write_read_response_out_of_order_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//--------------------------------------------------------------------------------------------
function axi4_master_read_nbk_write_read_response_out_of_order_seq::new(string name = "axi4_master_read_nbk_write_read_response_out_of_order_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: import_write_pool
// Import the address pool from write sequence for coordinated read-after-write testing
//--------------------------------------------------------------------------------------------
function void axi4_master_read_nbk_write_read_response_out_of_order_seq::import_write_pool();
  // Import from write sequence static variables
  write_addr_pool = axi4_master_write_nbk_write_read_response_out_of_order_seq::write_addr_pool;
  write_data_pool = axi4_master_write_nbk_write_read_response_out_of_order_seq::write_data_pool; 
  write_id_pool = axi4_master_write_nbk_write_read_response_out_of_order_seq::write_id_pool;
  
  `uvm_info("OOO_READ_SEQ", "Imported address pool from write sequence for read-after-write verification", UVM_LOW);
endfunction : import_write_pool

//--------------------------------------------------------------------------------------------
// Task: body
// Creates read transaction targeting previously written addresses with strategic ID assignment  
// Implements true AXI4 out-of-order behavior per ARM AMBA AXI4 specification
//--------------------------------------------------------------------------------------------
task axi4_master_read_nbk_write_read_response_out_of_order_seq::body();
  bit [63:0] target_addr;
  bit [31:0] expected_data;
  bit [3:0]  original_awid;
  int addr_index;
  
  super.body();
  
  // Import address pool from write sequence
  import_write_pool();
  
  start_item(req);
  
  // Use (transaction_arid - 8) to map read IDs (8-F) to write addresses (0-7)
  // This ensures read-after-write to same addresses
  addr_index = (transaction_arid - 8) % 8;
  target_addr = write_addr_pool[addr_index];
  expected_data = write_data_pool[addr_index];
  original_awid = write_id_pool[addr_index];
  
  // Use constraint-based assignment 
  if(!req.randomize() with {
    req.tx_type == READ;
    req.transfer_type == NON_BLOCKING_READ;
    
    // Strategic ID assignment for out-of-order testing (different from write IDs)
    req.arid == local::transaction_arid;
    
    // Target address from coordinated write pool (read-after-write)
    req.araddr == local::target_addr;
    
    // Single beat transaction matching write pattern
    req.arlen == 0;
    req.arsize == READ_4_BYTES;
    req.arburst == READ_INCR;
    req.arlock == READ_NORMAL_ACCESS;
    req.arcache == 4'h0;
    req.arprot == 3'h0;
    req.aruser == 4'h0;
  }) begin
    `uvm_fatal("axi4","Randomization failed for out-of-order read sequence");
  end
  
  read_count++;
  
  `uvm_info("OOO_READ_SEQ", $sformatf("OUT-OF-ORDER READ #%0d: ARID=0x%1h, ADDR=0x%16h, EXPECTED_DATA=0x%8h (was AWID=0x%1h)", 
           read_count, transaction_arid, target_addr, expected_data, original_awid), UVM_LOW);
  
  finish_item(req);

endtask : body

`endif