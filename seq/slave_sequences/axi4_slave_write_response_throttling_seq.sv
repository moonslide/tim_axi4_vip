`ifndef AXI4_SLAVE_WRITE_RESPONSE_THROTTLING_SEQ_INCLUDED_
`define AXI4_SLAVE_WRITE_RESPONSE_THROTTLING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_write_response_throttling_seq
// Throttles write response channel
//--------------------------------------------------------------------------------------------
class axi4_slave_write_response_throttling_seq extends axi4_slave_base_seq;
  `uvm_object_utils(axi4_slave_write_response_throttling_seq)

  rand int throttle_delay = 100;
  rand int num_responses = 20;
  
  constraint throttle_c {
    throttle_delay inside {[10:500]};
  }

  extern function new(string name = "axi4_slave_write_response_throttling_seq");
  extern task body();

endclass : axi4_slave_write_response_throttling_seq

function axi4_slave_write_response_throttling_seq::new(string name = "axi4_slave_write_response_throttling_seq");
  super.new(name);
endfunction : new

task axi4_slave_write_response_throttling_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), "Starting write response throttling sequence", UVM_HIGH)
  
  for(int i = 0; i < num_responses; i++) begin
    req = axi4_slave_tx::type_id::create("req");
    
    start_item(req);
    if(!req.randomize() with {
      b_wait_states == throttle_delay/10;
      bresp == WRITE_OKAY;
      aw_wait_states == 0;
      w_wait_states == 0;
    }) begin
      `uvm_fatal(get_type_name(), "Randomization failed")
    end
    finish_item(req);
  end
  
  `uvm_info(get_type_name(), "Completed write response throttling sequence", UVM_HIGH)
  
endtask : body

`endif