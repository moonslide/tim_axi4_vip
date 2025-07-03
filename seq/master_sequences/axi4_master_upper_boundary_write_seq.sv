`ifndef AXI4_MASTER_UPPER_BOUNDARY_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_UPPER_BOUNDARY_WRITE_SEQ_INCLUDED_

class axi4_master_upper_boundary_write_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_upper_boundary_write_seq)
  `uvm_declare_p_sequencer(axi4_master_write_sequencer)
  int sid = 0;

  extern function new(string name="axi4_master_upper_boundary_write_seq");
  extern task body();
endclass

function axi4_master_upper_boundary_write_seq::new(string name="axi4_master_upper_boundary_write_seq");
  super.new(name);
endfunction

task axi4_master_upper_boundary_write_seq::body();
  bit [ADDRESS_WIDTH-1:0] min_addr;
  bit [ADDRESS_WIDTH-1:0] max_addr;
  bit [ADDRESS_WIDTH-1:0] addr_list[2];
  super.body();
  min_addr = p_sequencer.axi4_master_agent_cfg_h.master_min_addr_range_array[sid];
  max_addr = p_sequencer.axi4_master_agent_cfg_h.master_max_addr_range_array[sid];
  addr_list[0] = max_addr - 4;
  addr_list[1] = max_addr + 4;
  foreach(addr_list[i]) begin
    start_item(req);
    if(!req.randomize() with {awaddr == addr_list[i];
                              awlen  == 0;
                              awsize == WRITE_4_BYTES;
                              awburst == WRITE_INCR;
                              tx_type == WRITE;
                              transfer_type == NON_BLOCKING_WRITE;})
      `uvm_fatal("axi4","Rand failed");
    req.wdata.delete();
    req.wdata.push_back($urandom);
    req.wstrb.delete();
    req.wstrb.push_back('hf);
    req.wlast = 1'b1;
    finish_item(req);
  end
endtask

`endif
