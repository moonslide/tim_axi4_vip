`ifndef AXI4_MASTER_BK_READ_INCR_CROSS_4K_SEQ_INCLUDED_
`define AXI4_MASTER_BK_READ_INCR_CROSS_4K_SEQ_INCLUDED_

class axi4_master_bk_read_incr_cross_4k_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_read_incr_cross_4k_seq)

  extern function new(string name="axi4_master_bk_read_incr_cross_4k_seq");
  extern task body();
endclass : axi4_master_bk_read_incr_cross_4k_seq

function axi4_master_bk_read_incr_cross_4k_seq::new(string name);
  super.new(name);
endfunction

task axi4_master_bk_read_incr_cross_4k_seq::body();
  import axi4_config_pkg::*;
  super.body();
  req.transfer_type = BLOCKING_READ;
  start_item(req);
  if(!req.randomize() with {req.arsize == READ_2_BYTES;
                            req.tx_type == READ;
                            req.arburst == READ_INCR;
                            req.arlen == 4;
                            req.araddr == slave_addr_table[0].base_addr + 12'hFFC;})
    `uvm_fatal("axi4","Rand failed");
  finish_item(req);
endtask

`endif
