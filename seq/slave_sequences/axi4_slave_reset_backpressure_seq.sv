`ifndef AXI4_SLAVE_RESET_BACKPRESSURE_SEQ_INCLUDED_
`define AXI4_SLAVE_RESET_BACKPRESSURE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_reset_backpressure_seq
// Applies backpressure followed by reset
//--------------------------------------------------------------------------------------------
class axi4_slave_reset_backpressure_seq extends axi4_slave_base_seq;
  `uvm_object_utils(axi4_slave_reset_backpressure_seq)

  rand int backpressure_cycles = 5000;
  
  constraint backpressure_c {
    backpressure_cycles inside {[1000:10000]};
  }

  extern function new(string name = "axi4_slave_reset_backpressure_seq");
  extern task body();

endclass : axi4_slave_reset_backpressure_seq

function axi4_slave_reset_backpressure_seq::new(string name = "axi4_slave_reset_backpressure_seq");
  super.new(name);
endfunction : new

task axi4_slave_reset_backpressure_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), "Starting reset backpressure sequence", UVM_HIGH)
  
  // Apply backpressure by adding wait states
  req = axi4_slave_tx::type_id::create("req");
  
  start_item(req);
  if(!req.randomize() with {
    aw_wait_states inside {[10:50]};
    w_wait_states inside {[10:50]};
    ar_wait_states inside {[10:50]};
    bresp == WRITE_OKAY;
    rresp == READ_OKAY;
  }) begin
    `uvm_fatal(get_type_name(), "Randomization failed")
  end
  finish_item(req);
  
  // Hold backpressure
  #(backpressure_cycles * 1ns);
  
  `uvm_info(get_type_name(), "Completed reset backpressure sequence", UVM_HIGH)
  
endtask : body

`endif