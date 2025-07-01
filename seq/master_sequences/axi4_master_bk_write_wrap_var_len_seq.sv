`ifndef AXI4_MASTER_BK_WRITE_WRAP_VAR_LEN_SEQ_INCLUDED_
`define AXI4_MASTER_BK_WRITE_WRAP_VAR_LEN_SEQ_INCLUDED_

class axi4_master_bk_write_wrap_var_len_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_write_wrap_var_len_seq)

  extern function new(string name="axi4_master_bk_write_wrap_var_len_seq");
  extern task body();
endclass : axi4_master_bk_write_wrap_var_len_seq

function axi4_master_bk_write_wrap_var_len_seq::new(string name);
  super.new(name);
endfunction

task axi4_master_bk_write_wrap_var_len_seq::body();
  import axi4_config_pkg::*;
  super.body();
  start_item(req);
  if(!req.randomize() with {req.awsize == WRITE_4_BYTES;
                            req.tx_type == WRITE;
                            req.transfer_type == BLOCKING_WRITE;
                            req.awburst == WRITE_WRAP;
                            (req.awlen == 3 || req.awlen == 7);
                            req.awaddr == slave_addr_table[0].base_addr;})
    `uvm_fatal("axi4","Rand failed");
  finish_item(req);
endtask

`endif
