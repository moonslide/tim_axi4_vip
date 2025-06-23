`ifndef AXI4_MASTER_BK_READ_INCR_CROSS_4K_SEQ_INCLUDED_
`define AXI4_MASTER_BK_READ_INCR_CROSS_4K_SEQ_INCLUDED_

class axi4_master_bk_read_incr_cross_4k_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_read_incr_cross_4k_seq)

  extern function new(string name = "axi4_master_bk_read_incr_cross_4k_seq");
  extern task body();
endclass : axi4_master_bk_read_incr_cross_4k_seq

function axi4_master_bk_read_incr_cross_4k_seq::new(string name = "axi4_master_bk_read_incr_cross_4k_seq");
  super.new(name);
endfunction : new

task axi4_master_bk_read_incr_cross_4k_seq::body();
  super.body();
  req.transfer_type = BLOCKING_READ;
  start_item(req);
  if(!req.randomize() with {req.arid   == arid_e'(2);
                            req.araddr == 32'h00000FFC;
                            req.arlen  == 8'h1;
                            req.arsize == READ_4_BYTES;
                            req.arburst == READ_INCR;
                            req.tx_type == READ;}) begin
    `uvm_fatal("axi4","Rand failed")
  end
  finish_item(req);
endtask : body

`endif
