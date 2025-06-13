`ifndef AXI4_SLAVE_W_READY_DELAY_SEQ_INCLUDED_
`define AXI4_SLAVE_W_READY_DELAY_SEQ_INCLUDED_

class axi4_slave_w_ready_delay_seq extends axi4_slave_bk_base_seq;
  `uvm_object_utils(axi4_slave_w_ready_delay_seq)

  extern function new(string name = "axi4_slave_w_ready_delay_seq");
  extern task body();
endclass : axi4_slave_w_ready_delay_seq

function axi4_slave_w_ready_delay_seq::new(string name = "axi4_slave_w_ready_delay_seq");
  super.new(name);
endfunction : new

task axi4_slave_w_ready_delay_seq::body();
  super.body();
  for(int ws = 0; ws <= 6; ws++) begin
    start_item(req);
    if(!req.randomize() with {req.aw_wait_states == 0;
                              req.w_wait_states == ws;
                              req.b_wait_states == 0;}) begin
      `uvm_fatal("axi4","Rand failed")
    end
    finish_item(req);
  end
endtask : body

`endif
