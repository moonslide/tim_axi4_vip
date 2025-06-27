`ifndef AXI4_MASTER_WSTRB_SEQ_INCLUDED_
`define AXI4_MASTER_WSTRB_SEQ_INCLUDED_

class axi4_master_wstrb_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_wstrb_seq)
  `uvm_declare_p_sequencer(axi4_master_write_sequencer)

  rand bit [ADDRESS_WIDTH-1:0] addr = 0;
  bit [DATA_WIDTH-1:0] data_q[$];
  bit [STROBE_WIDTH-1:0] wstrb_q[$];
  int bytes;
  function new(string name="axi4_master_wstrb_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    start_item(req);
    bytes = p_sequencer.axi4_master_agent_cfg_h.data_width/8;
    if(!req.randomize() with {req.awaddr == addr;
                              req.awlen == wstrb_q.size()-1;
                              req.awsize == awsize_e'($clog2(bytes));
                              req.awburst == WRITE_INCR;
                              req.tx_type == WRITE;
                              req.transfer_type == BLOCKING_WRITE;}) begin
      `uvm_fatal("axi4","Rand failed")
    end
    req.wdata.delete();
    foreach(data_q[i]) req.wdata.push_back(data_q[i]);
    req.wstrb.delete();
    foreach(wstrb_q[i]) req.wstrb.push_back(wstrb_q[i]);
    req.wlast = 1'b1;
    finish_item(req);
  endtask
endclass

`endif
