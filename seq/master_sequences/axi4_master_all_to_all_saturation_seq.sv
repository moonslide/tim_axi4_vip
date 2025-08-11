`ifndef AXI4_MASTER_ALL_TO_ALL_SATURATION_SEQ_INCLUDED_
`define AXI4_MASTER_ALL_TO_ALL_SATURATION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_all_to_all_saturation_seq
// All masters accessing all slaves with saturated traffic
//--------------------------------------------------------------------------------------------
class axi4_master_all_to_all_saturation_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_all_to_all_saturation_seq)

  rand int num_transactions = 100;
  rand int max_outstanding = 16;
  
  constraint num_trans_c {
    num_transactions inside {[50:200]};
  }

  extern function new(string name = "axi4_master_all_to_all_saturation_seq");
  extern task body();

endclass : axi4_master_all_to_all_saturation_seq

function axi4_master_all_to_all_saturation_seq::new(string name = "axi4_master_all_to_all_saturation_seq");
  super.new(name);
endfunction : new

task axi4_master_all_to_all_saturation_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), "Starting all-to-all saturation sequence", UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    start_item(req);
    if(!req.randomize() with {
      transfer_type == NON_BLOCKING_WRITE;
      awburst == WRITE_INCR;
      awlen inside {[0:255]};
      awsize inside {[0:3]};
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    finish_item(req);
  end
  
  `uvm_info(get_type_name(), "Completed all-to-all saturation sequence", UVM_HIGH)
  
endtask : body

`endif