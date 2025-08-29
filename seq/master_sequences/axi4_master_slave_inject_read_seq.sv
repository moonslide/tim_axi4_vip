`ifndef AXI4_MASTER_SLAVE_INJECT_READ_SEQ_INCLUDED_
`define AXI4_MASTER_SLAVE_INJECT_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_slave_inject_read_seq
// Read sequence specifically for slave injection testing with constrained addresses
//--------------------------------------------------------------------------------------------
class axi4_master_slave_inject_read_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_slave_inject_read_seq)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_slave_inject_read_seq");
  extern task body();
endclass : axi4_master_slave_inject_read_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_master_slave_inject_read_seq::new(string name = "axi4_master_slave_inject_read_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates read transaction with address constrained to first slave's range
//--------------------------------------------------------------------------------------------
task axi4_master_slave_inject_read_seq::body();
  super.body();
  
  start_item(req);
  if(!req.randomize() with {
    req.tx_type == READ;
    req.transfer_type == BLOCKING_READ;
    // Constrain address to first slave's range for NONE mode
    req.araddr inside {[64'h0000_0000_0000_0000:64'h0000_0000_FFFF_FFFF]};
    req.arlen == 0;  // Single beat for simplicity
    req.arsize == 3; // 8 bytes
    req.arburst == 1; // INCR
  }) begin
    `uvm_fatal("axi4","Rand failed");
  end
  
  `uvm_info(get_type_name(), $sformatf("Slave inject read: araddr=0x%0h", req.araddr), UVM_MEDIUM); 
  finish_item(req);

endtask : body

`endif