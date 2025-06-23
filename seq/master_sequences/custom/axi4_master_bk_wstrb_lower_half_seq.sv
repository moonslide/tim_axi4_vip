`ifndef AXI4_MASTER_BK_WSTRB_LOWER_HALF_SEQ_INCLUDED_
`define AXI4_MASTER_BK_WSTRB_LOWER_HALF_SEQ_INCLUDED_
class axi4_master_bk_wstrb_lower_half_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_wstrb_lower_half_seq)
  extern function new(string name = "axi4_master_bk_wstrb_lower_half_seq");
  extern task body();
endclass : axi4_master_bk_wstrb_lower_half_seq

function axi4_master_bk_wstrb_lower_half_seq::new(string name = "axi4_master_bk_wstrb_lower_half_seq");
  super.new(name);
endfunction : new

task axi4_master_bk_wstrb_lower_half_seq::body();
  super.body();
  start_item(req);
  if(!req.randomize() with {req.awid==awid_e'(1);
                            req.awaddr==32'h00004008;
                            req.awlen==0;
                            req.awsize==WRITE_4_BYTES;
                            req.awburst==WRITE_INCR;
                            req.tx_type==WRITE;
                            req.transfer_type==BLOCKING_WRITE;}) begin
    `uvm_fatal("axi4","Rand failed")
  end
  req.wdata.delete();
  req.wstrb.delete();
  req.wdata.push_back(32'hAABBCCDD);
  req.wstrb.push_back('h3);
  req.wlast=1'b1;
  finish_item(req);
endtask : body

`endif
