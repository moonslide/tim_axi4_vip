`ifndef AXI4_MASTER_READ_REORDER_SEQ_INCLUDED_
`define AXI4_MASTER_READ_REORDER_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_read_reorder_seq
// Tests read reordering with multiple IDs and slaves
//--------------------------------------------------------------------------------------------
class axi4_master_read_reorder_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_read_reorder_seq)

  rand int num_transactions = 50;
  rand int num_ids = 8;
  
  extern function new(string name = "axi4_master_read_reorder_seq");
  extern task body();

endclass : axi4_master_read_reorder_seq

function axi4_master_read_reorder_seq::new(string name = "axi4_master_read_reorder_seq");
  super.new(name);
endfunction : new

task axi4_master_read_reorder_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), "Starting read reorder sequence", UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    start_item(req);
    if(!req.randomize() with {
      transfer_type == NON_BLOCKING_READ;
      tx_type == READ;
      arburst == READ_INCR;
      arid inside {[0:num_ids-1]};
      arlen inside {[0:15]};
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    finish_item(req);
  end
  
  `uvm_info(get_type_name(), "Completed read reorder sequence", UVM_HIGH)
  
endtask : body

`endif