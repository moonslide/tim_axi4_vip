`ifndef AXI4_MASTER_R_READY_DELAY_SEQ_INCLUDED_
`define AXI4_MASTER_R_READY_DELAY_SEQ_INCLUDED_

class axi4_master_r_ready_delay_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_r_ready_delay_seq)

  extern function new(string name = "axi4_master_r_ready_delay_seq");
  extern task body();
endclass : axi4_master_r_ready_delay_seq

function axi4_master_r_ready_delay_seq::new(string name = "axi4_master_r_ready_delay_seq");
  super.new(name);
endfunction : new

task axi4_master_r_ready_delay_seq::body();
  super.body();
  start_item(req);
  if(!req.randomize() with {req.arid == 4'h8;
                            req.araddr == 32'h00001090;
                            req.arlen == 0;
                            req.arsize == READ_4_BYTES;
                            req.tx_type == READ;
                            req.transfer_type == BLOCKING_READ;
                            req.r_wait_states == 6;}) begin
    `uvm_fatal("axi4","Rand failed")
  end
  finish_item(req);
endtask : body

`endif
