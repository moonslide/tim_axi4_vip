`ifndef AXI4_MASTER_BK_WRITE_WRAP_UNALIGNED_SEQ_INCLUDED_
`define AXI4_MASTER_BK_WRITE_WRAP_UNALIGNED_SEQ_INCLUDED_

class axi4_master_bk_write_wrap_unaligned_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_write_wrap_unaligned_seq)

  extern function new(string name = "axi4_master_bk_write_wrap_unaligned_seq");
  extern task body();
endclass : axi4_master_bk_write_wrap_unaligned_seq

function axi4_master_bk_write_wrap_unaligned_seq::new(string name = "axi4_master_bk_write_wrap_unaligned_seq");
  super.new(name);
endfunction : new

task axi4_master_bk_write_wrap_unaligned_seq::body();
  super.body();
  start_item(req);
  if(!req.randomize() with {req.awid   == awid_e'(1);
                            req.awaddr == 32'h0000100E;
                            req.awlen  == 8'h3;
                            req.awsize == WRITE_4_BYTES;
                            req.awburst == WRITE_WRAP;
                            req.tx_type == WRITE;
                            req.transfer_type == BLOCKING_WRITE;}) begin
    `uvm_fatal("axi4","Rand failed")
  end
  req.wdata.delete();
  req.wstrb.delete();
  req.wdata.push_back(32'hD0);
  req.wdata.push_back(32'hD1);
  req.wdata.push_back(32'hD2);
  req.wdata.push_back(32'hD3);
  foreach(req.wdata[i]) req.wstrb.push_back('hF);
  req.wlast = 1'b1;
  finish_item(req);
endtask : body

`endif
