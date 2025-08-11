`ifndef AXI4_MASTER_REGION_ROUTING_SEQ_INCLUDED_
`define AXI4_MASTER_REGION_ROUTING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_region_routing_seq
// Tests REGION-based routing to different slaves
//--------------------------------------------------------------------------------------------
class axi4_master_region_routing_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_region_routing_seq)

  rand int num_transactions = 40;
  
  extern function new(string name = "axi4_master_region_routing_seq");
  extern task body();

endclass : axi4_master_region_routing_seq

function axi4_master_region_routing_seq::new(string name = "axi4_master_region_routing_seq");
  super.new(name);
endfunction : new

task axi4_master_region_routing_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), "Starting REGION routing sequence", UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_master_tx::type_id::create("req");
    
    start_item(req);
    if(!req.randomize() with {
      transfer_type inside {BLOCKING_WRITE, BLOCKING_READ};
      awregion inside {[0:15]};  // Test different regions
      arregion inside {[0:15]};
      awburst == WRITE_INCR;
      arburst == READ_INCR;
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    finish_item(req);
    
    get_response(rsp);
  end
  
  `uvm_info(get_type_name(), "Completed REGION routing sequence", UVM_HIGH)
  
endtask : body

`endif