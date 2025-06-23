`ifndef AXI4_MASTER_BK_READ_WRAP_UNALIGNED_SEQ_INCLUDED_
`define AXI4_MASTER_BK_READ_WRAP_UNALIGNED_SEQ_INCLUDED_

class axi4_master_bk_read_wrap_unaligned_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_read_wrap_unaligned_seq)

  extern function new(string name = "axi4_master_bk_read_wrap_unaligned_seq");
  extern task body();
endclass : axi4_master_bk_read_wrap_unaligned_seq

function axi4_master_bk_read_wrap_unaligned_seq::new(string name = "axi4_master_bk_read_wrap_unaligned_seq");
  super.new(name);
endfunction : new

task axi4_master_bk_read_wrap_unaligned_seq::body();
  super.body();
  req.transfer_type = BLOCKING_READ;
  start_item(req);
  if(!req.randomize() with {req.arid   == arid_e'(2);
                            req.araddr == 32'h0000100E;
                            req.arlen  == 8'h3;
                            req.arsize == READ_4_BYTES;
                            req.arburst == READ_WRAP;
                            req.tx_type == READ;}) begin
    `uvm_fatal("axi4","Rand failed")
  end
  finish_item(req);
endtask : body

`endif
