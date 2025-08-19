`ifndef AXI4_MASTER_NBK_WRITE_RAND_SEQ_INCLUDED_
`define AXI4_MASTER_NBK_WRITE_RAND_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_nbk_write_rand_seq
// Extends the axi4_master_nbk_base_seq and randomises the req item
//--------------------------------------------------------------------------------------------
class axi4_master_nbk_write_rand_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_nbk_write_rand_seq)

  // Configuration parameters
  int use_bus_matrix_addressing = 0; // 0=NONE, 1=BASE_4x4, 2=ENHANCED_10x10
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_nbk_write_rand_seq");
  extern task body();
endclass : axi4_master_nbk_write_rand_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi4_master_nbk_write_rand_seq
//--------------------------------------------------------------------------------------------
function axi4_master_nbk_write_rand_seq::new(string name = "axi4_master_nbk_write_rand_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates the req of type master_nbk transaction and randomises the req
//--------------------------------------------------------------------------------------------
task axi4_master_nbk_write_rand_seq::body();
  bit [63:0] target_addr;
  super.body();
  
  // Set target address based on bus matrix mode
  if(use_bus_matrix_addressing == 2) begin
    // ENHANCED mode - use DDR Memory region
    target_addr = 64'h0000_0100_0000_0000;
  end else if(use_bus_matrix_addressing == 1) begin
    // BASE mode - use DDR Memory region
    target_addr = 64'h0000_0100_0000_0000;
  end else begin
    // NONE mode - use simple address
    target_addr = 64'h0000_0000_0000_0000;
  end
  
  start_item(req);
  
  // Apply proper constraints based on bus matrix mode
  if(use_bus_matrix_addressing == 2) begin
    // ENHANCED mode (10x10)
    if(!req.randomize() with { 
      req.tx_type == WRITE;
      req.transfer_type == NON_BLOCKING_WRITE;
      req.awaddr[63:16] == target_addr[63:16];
      req.awid inside {[0:9]};
      req.awlen inside {[0:15]}; // Limit burst length
    }) begin
      `uvm_fatal("axi4","Rand failed");
    end
  end else begin
    // NONE or BASE mode (4x4)
    if(!req.randomize() with { 
      req.tx_type == WRITE;
      req.transfer_type == NON_BLOCKING_WRITE;
      req.awaddr[63:16] == target_addr[63:16];
      req.awid inside {[0:3]};
      req.awlen inside {[0:15]}; // Limit burst length
    }) begin
      `uvm_fatal("axi4","Rand failed");
    end
  end
  
  req.print();
  finish_item(req);

endtask : body

`endif

