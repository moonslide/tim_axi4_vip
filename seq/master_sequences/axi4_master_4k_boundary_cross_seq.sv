`ifndef AXI4_MASTER_4K_BOUNDARY_CROSS_SEQ_INCLUDED_
`define AXI4_MASTER_4K_BOUNDARY_CROSS_SEQ_INCLUDED_

class axi4_master_4k_boundary_cross_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_4k_boundary_cross_seq)
  int sid = 0;

  extern function new(string name="axi4_master_4k_boundary_cross_seq");
  extern task body();
endclass

function axi4_master_4k_boundary_cross_seq::new(string name="axi4_master_4k_boundary_cross_seq");
  super.new(name);
endfunction

task axi4_master_4k_boundary_cross_seq::body();
  bit [ADDRESS_WIDTH-1:0] base_addr;
  bit [ADDRESS_WIDTH-1:0] start_addr;
  super.body();
  base_addr = p_sequencer.axi4_master_agent_cfg_h.master_min_addr_range_array[sid];
  start_addr = base_addr + 4096 - 4;

  // write crossing 4K boundary
  start_item(req);
  if(!req.randomize() with {awaddr == start_addr;
                            awlen  == 1;
                            awsize == WRITE_4_BYTES;
                            awburst == WRITE_INCR;
                            tx_type == WRITE;
                            transfer_type == NON_BLOCKING_WRITE;})
    `uvm_fatal("axi4","Rand failed");
  req.wdata.delete();
  req.wdata.push_back($urandom); req.wdata.push_back($urandom);
  req.wstrb.delete();
  req.wstrb.push_back('hf); req.wstrb.push_back('hf);
  req.wlast = 1'b1;
  finish_item(req);

  // read back crossing 4K boundary
  start_item(req);
  if(!req.randomize() with {araddr == start_addr;
                            arlen  == 1;
                            arsize == READ_4_BYTES;
                            arburst == READ_INCR;
                            tx_type == READ;
                            transfer_type == NON_BLOCKING_READ;})
    `uvm_fatal("axi4","Rand failed");
  finish_item(req);
endtask

`endif
