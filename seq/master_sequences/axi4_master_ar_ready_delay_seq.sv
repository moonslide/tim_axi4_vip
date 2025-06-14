`ifndef AXI4_MASTER_AR_READY_DELAY_SEQ_INCLUDED_
`define AXI4_MASTER_AR_READY_DELAY_SEQ_INCLUDED_

class axi4_master_ar_ready_delay_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_ar_ready_delay_seq)

  extern function new(string name = "axi4_master_ar_ready_delay_seq");
  extern task body();
endclass : axi4_master_ar_ready_delay_seq

function axi4_master_ar_ready_delay_seq::new(string name = "axi4_master_ar_ready_delay_seq");
  super.new(name);
endfunction : new

task axi4_master_ar_ready_delay_seq::body();
  super.body();
  for(int ws = 0; ws <= 6; ws++) begin
    start_item(req);
    if(!req.randomize() with {req.arid == arid_e'(ws);
                              req.araddr == 32'h0000108C;
                              req.arlen == 0;
                              req.arsize == READ_4_BYTES;
                              req.tx_type == READ;
                              req.transfer_type == BLOCKING_READ;
                              req.ar_wait_states == ws;}) begin
      `uvm_fatal("axi4","Rand failed")
    end
    finish_item(req);
  end
endtask : body

`endif
