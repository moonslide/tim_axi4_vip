`ifndef AXI4_MASTER_ALL_SLAVE_ACCESS_SEQ_INCLUDED_
`define AXI4_MASTER_ALL_SLAVE_ACCESS_SEQ_INCLUDED_

class axi4_master_all_slave_access_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_all_slave_access_seq)

  extern function new(string name="axi4_master_all_slave_access_seq");
  extern task body();
endclass

function axi4_master_all_slave_access_seq::new(string name="axi4_master_all_slave_access_seq");
  super.new(name);
endfunction

// Generate a simple write then read for each slave range
// Assumes address ranges are stored in the master configuration

task axi4_master_all_slave_access_seq::body();
  bit [ADDRESS_WIDTH-1:0] min_addr;
  bit [ADDRESS_WIDTH-1:0] max_addr;
  super.body();
  foreach(p_sequencer.axi4_master_agent_cfg_h.master_min_addr_range_array[i]) begin
    min_addr = p_sequencer.axi4_master_agent_cfg_h.master_min_addr_range_array[i];
    max_addr = p_sequencer.axi4_master_agent_cfg_h.master_max_addr_range_array[i];

    // write inside allowed range
    start_item(req);
    if(!req.randomize() with {awaddr inside {[min_addr:max_addr]};
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

    // read back
    start_item(req);
    if(!req.randomize() with {araddr == awaddr;
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
