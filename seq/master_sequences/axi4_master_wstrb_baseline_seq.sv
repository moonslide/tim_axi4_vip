`ifndef AXI4_MASTER_WSTRB_BASELINE_SEQ_INCLUDED_
`define AXI4_MASTER_WSTRB_BASELINE_SEQ_INCLUDED_

class axi4_master_wstrb_baseline_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_wstrb_baseline_seq)
  `uvm_declare_p_sequencer(axi4_master_write_sequencer)

  bit [ADDRESS_WIDTH-1:0] addr = 0; // Not randomizable - set by virtual sequence
  bit [DATA_WIDTH-1:0] baseline_data = 32'hFFFFFFFF;
  int bytes;
  
  function new(string name="axi4_master_wstrb_baseline_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    start_item(req);
    bytes = p_sequencer.axi4_master_agent_cfg_h.data_width/8;
    if(!req.randomize() with {req.awaddr == addr;
                              req.awlen == 0; // Single beat
                              req.awsize == awsize_e'($clog2(bytes));
                              req.awburst == WRITE_INCR;
                              req.tx_type == WRITE;
                              req.transfer_type == BLOCKING_WRITE;
                              req.wuser == 4'h0;}) begin
      `uvm_fatal("axi4","Rand failed")
    end
    req.wdata.delete();
    req.wdata.push_back(baseline_data);
    req.wstrb.delete();
    req.wstrb.push_back(4'b1111); // All bytes enabled for baseline
    req.wlast = 1'b1;
    `uvm_info(get_type_name(), $sformatf("Writing baseline data 0x%08h to address 0x%016h with wstrb=4'b1111", baseline_data, addr), UVM_LOW)
    finish_item(req);
  endtask
endclass

`endif