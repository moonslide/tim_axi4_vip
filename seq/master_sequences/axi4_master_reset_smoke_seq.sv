`ifndef AXI4_MASTER_RESET_SMOKE_SEQ_INCLUDED_
`define AXI4_MASTER_RESET_SMOKE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_reset_smoke_seq
// Reset smoke test sequence - minimal traffic after reset release
// Verifies basic functionality after reset
//--------------------------------------------------------------------------------------------
class axi4_master_reset_smoke_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_reset_smoke_seq)

  // Number of simple transactions to send after reset
  rand int num_txns = 5;

  constraint num_txns_c {
    num_txns inside {[1:10]};
  }

  //--------------------------------------------------------------------------------------------
  // Externally defined Tasks and Functions
  //--------------------------------------------------------------------------------------------
  extern function new(string name = "axi4_master_reset_smoke_seq");
  extern task body();

endclass : axi4_master_reset_smoke_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the axi4_master_reset_smoke_seq class object
//
// Parameters:
//  name - axi4_master_reset_smoke_seq
//--------------------------------------------------------------------------------------------
function axi4_master_reset_smoke_seq::new(string name = "axi4_master_reset_smoke_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates simple read/write transactions after reset release
//--------------------------------------------------------------------------------------------
task axi4_master_reset_smoke_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), "Starting reset smoke sequence", UVM_HIGH)
  
  // Wait for reset to be released
  #100ns;
  
  // Send minimal traffic to verify basic functionality
  for(int i = 0; i < num_txns; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    start_item(req);
    if(!req.randomize() with {
      awburst == WRITE_INCR;
      arburst == READ_INCR;
      transfer_type == BLOCKING_WRITE;
      awsize == WRITE_4_BYTES;
      arsize == READ_4_BYTES;
      awlen == 0;  // Single beat
      arlen == 0;  // Single beat
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    finish_item(req);
    
    get_response(rsp);
  end
  
  `uvm_info(get_type_name(), "Reset smoke sequence completed", UVM_HIGH)
  
endtask : body

`endif