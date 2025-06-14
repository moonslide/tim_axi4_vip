`ifndef AXI4_MASTER_W_READY_DELAY_SEQ_INCLUDED_
`define AXI4_MASTER_W_READY_DELAY_SEQ_INCLUDED_

class axi4_master_w_ready_delay_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_w_ready_delay_seq)

  extern function new(string name = "axi4_master_w_ready_delay_seq");
  extern task body();
endclass : axi4_master_w_ready_delay_seq

function axi4_master_w_ready_delay_seq::new(string name = "axi4_master_w_ready_delay_seq");
  super.new(name);
endfunction : new

task axi4_master_w_ready_delay_seq::body();
  super.body();
  for(int ws = 0; ws <= 6; ws++) begin
    start_item(req);
    if(!req.randomize() with {req.awid == awid_e'(ws);
                              req.awaddr == 32'h00001084;
                              req.awlen == 0;
                              req.awsize == WRITE_4_BYTES;
                              req.tx_type == WRITE;
                              req.transfer_type == BLOCKING_WRITE;
                              req.w_wait_states == ws;}) begin
      `uvm_fatal("axi4","Rand failed")
    end
    req.wdata.delete();
    req.wdata.push_back(32'hDDDDCCCC);
    req.wstrb.delete();
    req.wstrb.push_back('hf);
    req.wlast = 1'b1;
    finish_item(req);
  end
endtask : body

`endif
