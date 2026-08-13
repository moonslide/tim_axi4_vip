`ifndef AXI4_MASTER_TARGETED_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_TARGETED_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_targeted_write_seq
// Extends the axi4_master_bk_base_seq to write to a specific address
//--------------------------------------------------------------------------------------------
class axi4_master_targeted_write_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_targeted_write_seq)

  // Target address and ID
  bit [63:0] target_addr = 64'h0;
  // Typed as the enum, NOT a string.  `string awid_val = "AWID_0"` assigned
  // straight into the enum field compiled with only a VCS
  // Warning-[ENUMASSIGN] and packed the last two CHARACTERS' ASCII into the
  // value: at AXI_ID_WIDTH=4 that happened to give the right low nibble for
  // AWID_0..AWID_9 and the WRONG one for two-digit names, and at
  // AXI_ID_WIDTH=8 (Track-B) every value was wrong -- "AWID_4" drove 52.
  // See .claude/docs/known-landmines.md #41.
  awid_e awid_val = AWID_0;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_targeted_write_seq");
  extern task body();
endclass : axi4_master_targeted_write_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_master_targeted_write_seq::new(string name = "axi4_master_targeted_write_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//--------------------------------------------------------------------------------------------
task axi4_master_targeted_write_seq::body();
  super.body();
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == WRITE;
    req.transfer_type == BLOCKING_WRITE;
    req.awaddr == local::target_addr;
    req.awlen == 8'h00;  // Single beat
    req.awsize == WRITE_4_BYTES;
    req.awburst == WRITE_INCR;
  }) begin
    `uvm_fatal("axi4","Randomization failed");
  end
  
  // Set AWID after randomization
  req.awid = awid_val;
  
  `uvm_info(get_type_name(), $sformatf("Targeted write to addr=0x%016h, awid=%s", req.awaddr, req.awid.name()), UVM_MEDIUM);
  finish_item(req);

endtask : body

`endif