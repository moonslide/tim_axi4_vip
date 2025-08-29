`ifndef AXI4_MASTER_BK_WRITE_CONSTRAINED_SEQ_INCLUDED_
`define AXI4_MASTER_BK_WRITE_CONSTRAINED_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_bk_write_constrained_seq
// Extends the axi4_master_bk_write_seq with proper address constraints for valid slave ranges
//--------------------------------------------------------------------------------------------
class axi4_master_bk_write_constrained_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_write_constrained_seq)

  // Valid address ranges for enhanced bus matrix
  // S0-S2: DDR regions
  parameter bit [63:0] DDR_BASE  = 64'h0000_0008_0000_0000;
  parameter bit [63:0] DDR_END   = 64'h0000_0008_BFFF_FFFF;
  
  // S5-S9: Peripheral regions  
  parameter bit [63:0] PERIPH_BASE = 64'h0000_000A_0000_0000;
  parameter bit [63:0] PERIPH_END  = 64'h0000_000A_0004_FFFF;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_bk_write_constrained_seq");
  extern task body();
endclass : axi4_master_bk_write_constrained_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_master_bk_write_constrained_seq::new(string name = "axi4_master_bk_write_constrained_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates the req with proper address constraints for valid slave ranges
//--------------------------------------------------------------------------------------------
task axi4_master_bk_write_constrained_seq::body();
  super.body();
  `uvm_info(get_type_name(), "Starting constrained write sequence with valid addresses", UVM_HIGH); 

  start_item(req);
  if(!req.randomize() with {
    req.tx_type == WRITE;
    req.transfer_type == BLOCKING_WRITE;
    
    // Constrain to valid slave address ranges
    // Either in DDR region (S0-S2) or Peripheral region (S5-S9)
    (req.awaddr >= DDR_BASE && req.awaddr <= DDR_END) ||
    (req.awaddr >= PERIPH_BASE && req.awaddr <= PERIPH_END);
    
    // Prefer DDR region (80% probability)
    req.awaddr dist {
      [DDR_BASE:DDR_END] := 80,
      [PERIPH_BASE:PERIPH_END] := 20
    };
    
    // Keep transactions aligned and reasonable size
    req.awsize inside {[0:3]};  // 1 to 8 bytes
    req.awlen inside {[0:15]};  // Max 16 beats
    req.awburst == WRITE_INCR;  // Use INCR burst
  }) begin
    `uvm_fatal("axi4","Randomization failed for constrained write sequence");
  end
  
  `uvm_info(get_type_name(), $sformatf("Generated write to address 0x%h, size=%0d, len=%0d", 
                                        req.awaddr, req.awsize, req.awlen), UVM_HIGH); 
  finish_item(req);

endtask : body

`endif