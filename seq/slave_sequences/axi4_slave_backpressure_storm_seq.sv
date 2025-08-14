`ifndef AXI4_SLAVE_BACKPRESSURE_STORM_SEQ_INCLUDED_
`define AXI4_SLAVE_BACKPRESSURE_STORM_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_backpressure_storm_seq
// Applies varying backpressure patterns (storm)
//--------------------------------------------------------------------------------------------
class axi4_slave_backpressure_storm_seq extends axi4_slave_base_seq;
  `uvm_object_utils(axi4_slave_backpressure_storm_seq)

  rand int num_patterns = 10;
  
  extern function new(string name = "axi4_slave_backpressure_storm_seq");
  extern task body();

endclass : axi4_slave_backpressure_storm_seq

function axi4_slave_backpressure_storm_seq::new(string name = "axi4_slave_backpressure_storm_seq");
  super.new(name);
endfunction : new

task axi4_slave_backpressure_storm_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), "Starting backpressure storm sequence", UVM_HIGH)
  
  for(int i = 0; i < num_patterns; i++) begin
    req = axi4_slave_tx::type_id::create("req");
    
    start_item(req);
    if(!req.randomize() with {
      aw_wait_states inside {[0:6]};   // Fixed: Compatible with class constraint
      w_wait_states inside {[0:6]};    // Fixed: Compatible with class constraint
      ar_wait_states inside {[0:6]};   // Fixed: Compatible with class constraint
      b_wait_states inside {[0:6]};    // Fixed: Compatible with class constraint
      r_wait_states inside {[0:6]};    // Fixed: Compatible with class constraint
      bresp == WRITE_OKAY;
      rresp == READ_OKAY;
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    finish_item(req);
    
    // Apply pattern for some time
    #(1000ns);
  end
  
  `uvm_info(get_type_name(), "Completed backpressure storm sequence", UVM_HIGH)
  
endtask : body

`endif