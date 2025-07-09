`ifndef AXI4_MASTER_ILLEGAL_WSTRB_SEQ_INCLUDED_
`define AXI4_MASTER_ILLEGAL_WSTRB_SEQ_INCLUDED_

class axi4_master_illegal_wstrb_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_illegal_wstrb_seq)
  `uvm_declare_p_sequencer(axi4_master_write_sequencer)

  bit [ADDRESS_WIDTH-1:0] addr = 0; // Not randomizable - set by virtual sequence
  bit [DATA_WIDTH-1:0] data_q[$];
  bit [STROBE_WIDTH-1:0] wstrb_q[$];
  rand awsize_e test_size;
  int bytes;
  
  function new(string name="axi4_master_illegal_wstrb_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    start_item(req);
    bytes = p_sequencer.axi4_master_agent_cfg_h.data_width/8;
    if(!req.randomize() with {req.awaddr == addr;
                              req.awlen == wstrb_q.size()-1;
                              req.awsize == test_size;
                              req.awburst == WRITE_INCR;
                              req.tx_type == WRITE;
                              req.transfer_type == BLOCKING_WRITE;
                              req.wuser == 4'h0;}) begin
      `uvm_fatal("axi4","Rand failed")
    end
    req.wdata.delete();
    foreach(data_q[i]) req.wdata.push_back(data_q[i]);
    req.wstrb.delete();
    foreach(wstrb_q[i]) req.wstrb.push_back(wstrb_q[i]);
    req.wlast = 1'b1;
    
    // Log the illegal wstrb test details
    `uvm_warning(get_type_name(), $sformatf("ILLEGAL WSTRB TEST: Writing data 0x%08h to address 0x%016h with ILLEGAL wstrb=4'b%04b for size=%0s", data_q[0], addr, wstrb_q[0], test_size.name()))
    foreach(wstrb_q[i]) begin
      `uvm_warning(get_type_name(), $sformatf("  ILLEGAL Beat[%0d]: data=0x%08h, wstrb=4'b%04b (size=%0s)", i, data_q[i], wstrb_q[i], test_size.name()))
    end
    
    finish_item(req);
  endtask
endclass

`endif