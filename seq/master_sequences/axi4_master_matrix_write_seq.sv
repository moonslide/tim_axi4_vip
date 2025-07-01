`ifndef AXI4_MASTER_MATRIX_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_MATRIX_WRITE_SEQ_INCLUDED_

class axi4_master_matrix_write_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_matrix_write_seq)

  rand bit [ADDRESS_WIDTH-1:0] addr;
  bit [DATA_WIDTH-1:0] data;

  extern function new(string name="axi4_master_matrix_write_seq");
  extern task body();
endclass : axi4_master_matrix_write_seq

function axi4_master_matrix_write_seq::new(string name);
  super.new(name);
endfunction

task axi4_master_matrix_write_seq::body();
  super.body();
  start_item(req);
  if(!req.randomize() with {req.awsize == WRITE_4_BYTES;
                            req.tx_type == WRITE;
                            req.transfer_type == BLOCKING_WRITE;
                            req.awburst == WRITE_INCR;
                            req.awlen == 0;
                            req.awaddr == addr;
                            req.wdata.size() == 1;
                            req.wdata[0] == data;
                            req.wstrb.size() == 1;
                            req.wstrb[0] == 'hf;})
    `uvm_fatal("axi4","Rand failed");
  finish_item(req);
endtask

`endif
