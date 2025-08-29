`ifndef AXI4_MASTER_SLAVE_INJECT_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_SLAVE_INJECT_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_slave_inject_write_seq
// Write sequence specifically for slave injection testing with constrained addresses
//--------------------------------------------------------------------------------------------
class axi4_master_slave_inject_write_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_slave_inject_write_seq)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_slave_inject_write_seq");
  extern task body();
endclass : axi4_master_slave_inject_write_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_master_slave_inject_write_seq::new(string name = "axi4_master_slave_inject_write_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates write transaction with address constrained to first slave's range
//--------------------------------------------------------------------------------------------
task axi4_master_slave_inject_write_seq::body();
  super.body();
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == WRITE;
    req.transfer_type == BLOCKING_WRITE;
    // Constrain address to first slave's range for NONE mode
    req.awaddr inside {[64'h0000_0000_0000_0000:64'h0000_0000_FFFF_FFFF]};
    req.awlen == 0;  // Single beat for simplicity
    req.awsize == 3; // 8 bytes
    req.awburst == 1; // INCR
  }) begin
    `uvm_fatal("axi4","Rand failed");
  end
  
  `uvm_info(get_type_name(), $sformatf("Slave inject write: awaddr=0x%0h", req.awaddr), UVM_MEDIUM); 
  finish_item(req);

endtask : body

`endif