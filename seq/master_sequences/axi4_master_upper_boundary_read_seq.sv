`ifndef AXI4_MASTER_UPPER_BOUNDARY_READ_SEQ_INCLUDED_
`define AXI4_MASTER_UPPER_BOUNDARY_READ_SEQ_INCLUDED_

class axi4_master_upper_boundary_read_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_upper_boundary_read_seq)
  int sid = 0;

  extern function new(string name="axi4_master_upper_boundary_read_seq");
  extern task body();
endclass

function axi4_master_upper_boundary_read_seq::new(string name="axi4_master_upper_boundary_read_seq");
  super.new(name);
endfunction

task axi4_master_upper_boundary_read_seq::body();
  bit [ADDRESS_WIDTH-1:0] max_addr;
  bit [ADDRESS_WIDTH-1:0] addr_list[2];
  super.body();
  max_addr = p_sequencer.axi4_master_agent_cfg_h.master_max_addr_range_array[sid];
  addr_list[0] = max_addr - 4;
  addr_list[1] = max_addr + 4;
  foreach(addr_list[i]) begin
    start_item(req);
    if(!req.randomize() with {araddr == addr_list[i];
                              arlen  == 0;
                              arsize == READ_4_BYTES;
                              arburst == READ_INCR;
                              tx_type == READ;
                              transfer_type == NON_BLOCKING_READ;})
      `uvm_fatal("axi4","Rand failed");
    finish_item(req);
  end
endtask

`endif
