`ifndef AXI4_MASTER_BK_WRITE_MAX_BURST_SEQ_INCLUDED_
`define AXI4_MASTER_BK_WRITE_MAX_BURST_SEQ_INCLUDED_

class axi4_master_bk_write_max_burst_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_write_max_burst_seq)

  extern function new(string name = "axi4_master_bk_write_max_burst_seq");
  extern task body();
endclass : axi4_master_bk_write_max_burst_seq

function axi4_master_bk_write_max_burst_seq::new(string name = "axi4_master_bk_write_max_burst_seq");
  super.new(name);
endfunction : new

task axi4_master_bk_write_max_burst_seq::body();
  super.body();
  start_item(req);
  if(!req.randomize() with {req.awid   == awid_e'(10);
                            req.awaddr == 32'h00001100;
                            req.awlen  == 8'hFF;
                            req.awsize == WRITE_4_BYTES;
                            req.awburst == WRITE_INCR;
                            req.tx_type == WRITE;
                            req.transfer_type == BLOCKING_WRITE;}) begin
    `uvm_fatal("axi4","Rand failed")
  end
  req.wdata.delete();
  req.wstrb.delete();
  for(int i=0;i<256;i++) begin
    req.wdata.push_back(32'hAABB0000 + i);
    req.wstrb.push_back('hF);
  end
  req.wlast = 1'b1;
  finish_item(req);
endtask : body

`endif
