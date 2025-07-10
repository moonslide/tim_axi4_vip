`ifndef AXI4_MASTER_WRITE_NBK_WRITE_READ_RESPONSE_OUT_OF_ORDER_SEQ_INCLUDED_
`define AXI4_MASTER_WRITE_NBK_WRITE_READ_RESPONSE_OUT_OF_ORDER_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_write_nbk_write_read_response_out_of_order_seq
// True AXI4 out-of-order write sequence with ID management and address coordination
// Follows ARM AMBA AXI4 specification for out-of-order transaction testing
//--------------------------------------------------------------------------------------------
class axi4_master_write_nbk_write_read_response_out_of_order_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_write_nbk_write_read_response_out_of_order_seq)

  // Static storage for coordinating write/read addresses and data for read-after-write verification
  static bit [63:0] write_addr_pool[8];  // Pool of addresses written to
  static bit [31:0] write_data_pool[8];  // Expected data at each address  
  static bit [3:0]  write_id_pool[8];    // AWID used for each write
  static int        write_count = 0;     // Number of writes completed
  static bit        pool_initialized = 0;

  // Transaction ID for this write (different for each transaction to enable out-of-order)
  rand bit [3:0] transaction_awid;
  
  // Address range for out-of-order testing
  constraint addr_range_c {
    transaction_awid inside {4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7};
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_write_nbk_write_read_response_out_of_order_seq");
  extern task body();
  extern function void initialize_address_pool();

endclass : axi4_master_write_nbk_write_read_response_out_of_order_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//--------------------------------------------------------------------------------------------
function axi4_master_write_nbk_write_read_response_out_of_order_seq::new(string name = "axi4_master_write_nbk_write_read_response_out_of_order_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: initialize_address_pool
// Initialize the shared address pool for coordinated write/read testing
//--------------------------------------------------------------------------------------------
function void axi4_master_write_nbk_write_read_response_out_of_order_seq::initialize_address_pool();
  if (!pool_initialized) begin
    // Initialize with specific addresses in DDR range for predictable testing
    write_addr_pool[0] = 64'h0000_0100_0000_1000;  // 4KB aligned addresses
    write_addr_pool[1] = 64'h0000_0100_0000_2000;  
    write_addr_pool[2] = 64'h0000_0100_0000_3000;
    write_addr_pool[3] = 64'h0000_0100_0000_4000;
    write_addr_pool[4] = 64'h0000_0100_0000_5000;
    write_addr_pool[5] = 64'h0000_0100_0000_6000;
    write_addr_pool[6] = 64'h0000_0100_0000_7000;
    write_addr_pool[7] = 64'h0000_0100_0000_8000;
    
    write_count = 0;
    pool_initialized = 1;
    `uvm_info("OOO_WRITE_SEQ", "Address pool initialized for out-of-order testing", UVM_LOW);
  end
endfunction : initialize_address_pool

//--------------------------------------------------------------------------------------------
// Task: body
// Creates write transaction with strategic ID assignment and address coordination
// Implements true AXI4 out-of-order behavior per ARM AMBA AXI4 specification
//--------------------------------------------------------------------------------------------
task axi4_master_write_nbk_write_read_response_out_of_order_seq::body();
  bit [63:0] target_addr;
  bit [31:0] expected_data;
  int addr_index;
  
  super.body();
  
  // Initialize address pool on first access
  initialize_address_pool();
  
  start_item(req);
  
  // Use transaction_awid directly as index to avoid race conditions
  // This ensures each AWID gets a unique, predictable address
  addr_index = transaction_awid % 8;
  target_addr = write_addr_pool[addr_index];
  
  // Create predictable data pattern: {AWID, addr[7:0], 0xDE, 0xAD}
  expected_data = {transaction_awid, target_addr[7:0], 8'hDE, 8'hAD};
  
  // Use constraint-based assignment for proper queue handling
  if(!req.randomize() with {
    req.tx_type == WRITE;
    req.transfer_type == NON_BLOCKING_WRITE;
    
    // Strategic ID assignment for out-of-order testing
    req.awid == local::transaction_awid;
    
    // Use coordinated address from pool  
    req.awaddr == local::target_addr;
    
    // Known data pattern for verification
    req.wdata.size() == 1;
    req.wdata[0] == local::expected_data;
    req.wstrb.size() == 1; 
    req.wstrb[0] == 4'hF;  // Write all bytes
    
    // Single beat transaction for simplicity
    req.awlen == 0;
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
    req.awlock == WRITE_NORMAL_ACCESS;
    req.awcache == 4'h0;
    req.awprot == 3'h0;
    req.awuser == 4'h0;
    req.wuser == 4'h0;
  }) begin
    `uvm_fatal("axi4","Randomization failed for out-of-order write sequence");
  end
  
  // Store write information for read-after-write verification
  write_data_pool[addr_index] = expected_data;
  write_id_pool[addr_index] = transaction_awid;
  write_count++;
  
  `uvm_info("OOO_WRITE_SEQ", $sformatf("OUT-OF-ORDER WRITE #%0d: AWID=0x%1h, ADDR=0x%16h, DATA=0x%8h", 
           write_count, transaction_awid, target_addr, expected_data), UVM_LOW);
  
  finish_item(req);

endtask : body

`endif