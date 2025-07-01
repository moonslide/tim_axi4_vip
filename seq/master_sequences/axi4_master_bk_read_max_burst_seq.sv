`ifndef AXI4_MASTER_BK_READ_MAX_BURST_SEQ_INCLUDED_
`define AXI4_MASTER_BK_READ_MAX_BURST_SEQ_INCLUDED_

class axi4_master_bk_read_max_burst_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_read_max_burst_seq)

  extern function new(string name="axi4_master_bk_read_max_burst_seq");
  extern task body();
endclass : axi4_master_bk_read_max_burst_seq

function axi4_master_bk_read_max_burst_seq::new(string name="axi4_master_bk_read_max_burst_seq");
  super.new(name);
endfunction

task axi4_master_bk_read_max_burst_seq::body();
  import axi4_config_pkg::*;
  super.body();
  req.transfer_type=BLOCKING_READ;
  start_item(req);
  if(!req.randomize() with {req.arsize == READ_4_BYTES;
                            req.tx_type == READ;
                            req.arburst == READ_INCR;
                            req.arlen == 8'hFF;
                            req.araddr == slave_addr_table[0].base_addr;})
    `uvm_fatal("axi4","Rand failed");
  finish_item(req);
endtask

`endif
