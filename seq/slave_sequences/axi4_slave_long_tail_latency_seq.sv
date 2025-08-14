`ifndef AXI4_SLAVE_LONG_TAIL_LATENCY_SEQ_INCLUDED_
`define AXI4_SLAVE_LONG_TAIL_LATENCY_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_long_tail_latency_seq
// Introduces very long latency on specific slave
//--------------------------------------------------------------------------------------------
class axi4_slave_long_tail_latency_seq extends axi4_slave_base_seq;
  `uvm_object_utils(axi4_slave_long_tail_latency_seq)

  rand int long_delay = 50000;
  
  constraint delay_c {
    long_delay inside {[10000:100000]};
  }

  extern function new(string name = "axi4_slave_long_tail_latency_seq");
  extern task body();

endclass : axi4_slave_long_tail_latency_seq

function axi4_slave_long_tail_latency_seq::new(string name = "axi4_slave_long_tail_latency_seq");
  super.new(name);
endfunction : new

task axi4_slave_long_tail_latency_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting long tail latency sequence with delay=%0d", long_delay), UVM_HIGH)
  
  req = axi4_slave_tx::type_id::create("req");
  
  start_item(req);
  
  // Disable the class constraint for wait states since we need long delays
  req.wait_states_c1.constraint_mode(0);
  
  if(!req.randomize() with {
    aw_wait_states == long_delay/100;
    ar_wait_states == long_delay/100;
    b_wait_states == long_delay/1000;
    r_wait_states == long_delay/1000;
    w_wait_states == 0;
    bresp == WRITE_OKAY;
    rresp == READ_OKAY;
  }) begin
    `uvm_fatal(get_type_name(), "Randomization failed")
  end
  finish_item(req);
  
  // Hold the long latency
  #(long_delay * 1ns);
  
  `uvm_info(get_type_name(), "Completed long tail latency sequence", UVM_HIGH)
  
endtask : body

`endif