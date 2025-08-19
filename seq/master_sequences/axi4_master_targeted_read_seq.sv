`ifndef AXI4_MASTER_TARGETED_READ_SEQ_INCLUDED_
`define AXI4_MASTER_TARGETED_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_targeted_read_seq
// Extends the axi4_master_bk_base_seq to read from a specific address
//--------------------------------------------------------------------------------------------
class axi4_master_targeted_read_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_targeted_read_seq)

  // Target address and ID
  bit [63:0] target_addr = 64'h0;
  string arid_val = "ARID_0";
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_targeted_read_seq");
  extern task body();
endclass : axi4_master_targeted_read_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_master_targeted_read_seq::new(string name = "axi4_master_targeted_read_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//--------------------------------------------------------------------------------------------
task axi4_master_targeted_read_seq::body();
  super.body();
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == READ;
    req.transfer_type == BLOCKING_READ;
    req.araddr == local::target_addr;
    req.arlen == 8'h00;  // Single beat
    req.arsize == READ_4_BYTES;
    req.arburst == READ_INCR;
  }) begin
    `uvm_fatal("axi4","Randomization failed");
  end
  
  // Set ARID after randomization
  req.arid = arid_val;
  
  `uvm_info(get_type_name(), $sformatf("Targeted read from addr=0x%016h, arid=%s", req.araddr, req.arid), UVM_MEDIUM);
  finish_item(req);

endtask : body

`endif