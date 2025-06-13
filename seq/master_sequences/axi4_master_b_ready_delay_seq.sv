`ifndef AXI4_MASTER_B_READY_DELAY_SEQ_INCLUDED_
`define AXI4_MASTER_B_READY_DELAY_SEQ_INCLUDED_

class axi4_master_b_ready_delay_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_b_ready_delay_seq)

  extern function new(string name = "axi4_master_b_ready_delay_seq");
  extern task body();
endclass : axi4_master_b_ready_delay_seq

function axi4_master_b_ready_delay_seq::new(string name = "axi4_master_b_ready_delay_seq");
  super.new(name);
endfunction : new

task axi4_master_b_ready_delay_seq::body();
  super.body();
  for(int ws = 0; ws <= 6; ws++) begin
    start_item(req);
    if(!req.randomize() with {req.awid == 4'h7;
                              req.awaddr == 32'h00001088;
                              req.awlen == 0;
                              req.awsize == WRITE_4_BYTES;
                              req.tx_type == WRITE;
                              req.transfer_type == BLOCKING_WRITE;
                              req.b_wait_states == ws;}) begin
      `uvm_fatal("axi4","Rand failed")
    end
    req.wdata.delete();
    req.wdata.push_back(32'hCAFEBABE);
    req.wstrb.delete();
    req.wstrb.push_back('hf);
    req.wlast = 1'b1;
    finish_item(req);
  end
endtask : body

`endif
