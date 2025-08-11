`ifndef AXI4_MASTER_MIXED_BURST_LENGTHS_SEQ_INCLUDED_
`define AXI4_MASTER_MIXED_BURST_LENGTHS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_mixed_burst_lengths_seq
// Transactions with various burst lengths (1 to 256)
//--------------------------------------------------------------------------------------------
class axi4_master_mixed_burst_lengths_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_mixed_burst_lengths_seq)

  rand int num_transactions = 50;
  
  extern function new(string name = "axi4_master_mixed_burst_lengths_seq");
  extern task body();

endclass : axi4_master_mixed_burst_lengths_seq

function axi4_master_mixed_burst_lengths_seq::new(string name = "axi4_master_mixed_burst_lengths_seq");
  super.new(name);
endfunction : new

task axi4_master_mixed_burst_lengths_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), "Starting mixed burst lengths sequence", UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    start_item(req);
    if(!req.randomize() with {
      transfer_type inside {BLOCKING_WRITE, BLOCKING_READ};
      awburst == WRITE_INCR;
      arburst == READ_INCR;
      awlen inside {0, 1, 3, 7, 15, 31, 63, 127, 255};  // Various burst lengths
      arlen inside {0, 1, 3, 7, 15, 31, 63, 127, 255};
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    finish_item(req);
    
    get_response(rsp);
  end
  
  `uvm_info(get_type_name(), "Completed mixed burst lengths sequence", UVM_HIGH)
  
endtask : body

`endif