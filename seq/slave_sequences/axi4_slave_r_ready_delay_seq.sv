`ifndef AXI4_SLAVE_R_READY_DELAY_SEQ_INCLUDED_
`define AXI4_SLAVE_R_READY_DELAY_SEQ_INCLUDED_

class axi4_slave_r_ready_delay_seq extends axi4_slave_bk_base_seq;
  `uvm_object_utils(axi4_slave_r_ready_delay_seq)

  extern function new(string name = "axi4_slave_r_ready_delay_seq");
  extern task body();
endclass : axi4_slave_r_ready_delay_seq

function axi4_slave_r_ready_delay_seq::new(string name = "axi4_slave_r_ready_delay_seq");
  super.new(name);
endfunction : new

task axi4_slave_r_ready_delay_seq::body();
  super.body();
  for(int ws = 0; ws <= 6; ws++) begin
    start_item(req);
    if(!req.randomize() with {req.ar_wait_states == 0;
                              req.r_wait_states == ws;
                              req.arid == arid_e'(ws);
                              req.rid == rid_e'(ws);}) begin

      `uvm_fatal("axi4","Rand failed")
    end
    req.rdata.delete();
    req.rdata.push_back(32'hEEEEFFFF);
    finish_item(req);
  end
endtask : body

`endif
