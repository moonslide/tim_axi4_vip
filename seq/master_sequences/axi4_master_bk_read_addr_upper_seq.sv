`ifndef AXI4_MASTER_BK_READ_ADDR_UPPER_SEQ_INCLUDED_
`define AXI4_MASTER_BK_READ_ADDR_UPPER_SEQ_INCLUDED_

class axi4_master_bk_read_addr_upper_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_read_addr_upper_seq)

  extern function new(string name="axi4_master_bk_read_addr_upper_seq");
  extern task body();
endclass : axi4_master_bk_read_addr_upper_seq

function axi4_master_bk_read_addr_upper_seq::new(string name);
  super.new(name);
endfunction

task axi4_master_bk_read_addr_upper_seq::body();
  import axi4_config_pkg::*;
  super.body();
  req.transfer_type = BLOCKING_READ;
  start_item(req);
  if(!req.randomize() with {req.arsize == READ_4_BYTES;
                            req.tx_type == READ;
                            req.arburst == READ_INCR;
                            req.arlen == 0;
                            req.araddr == slave_addr_table[0].base_addr + slave_addr_table[0].size - 4;})
    `uvm_fatal("axi4","Rand failed");
  finish_item(req);
endtask

`endif
