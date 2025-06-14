`ifndef AXI4_SLAVE_AW_W_CHANNEL_SEPARATION_SEQ_INCLUDED_
`define AXI4_SLAVE_AW_W_CHANNEL_SEPARATION_SEQ_INCLUDED_

class axi4_slave_aw_w_channel_separation_seq extends axi4_slave_bk_base_seq;
  `uvm_object_utils(axi4_slave_aw_w_channel_separation_seq)

  extern function new(string name = "axi4_slave_aw_w_channel_separation_seq");
  extern task body();
endclass : axi4_slave_aw_w_channel_separation_seq

function axi4_slave_aw_w_channel_separation_seq::new(string name = "axi4_slave_aw_w_channel_separation_seq");
  super.new(name);
endfunction : new

task axi4_slave_aw_w_channel_separation_seq::body();
  super.body();
  for(int ws = 0; ws <= 6; ws++) begin
    start_item(req);
    if(!req.randomize() with {req.aw_wait_states == ws;
                              req.w_wait_states == ws;
                              req.b_wait_states == 0;
                              req.awid == awid_e'(ws);
                              req.bid == bid_e'(ws);}) begin
      `uvm_fatal("axi4","Rand failed")
    end
    finish_item(req);
  end
endtask : body

`endif
