`ifndef AXI4_MASTER_WSTRB_READ_SEQ_INCLUDED_
`define AXI4_MASTER_WSTRB_READ_SEQ_INCLUDED_

class axi4_master_wstrb_read_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_wstrb_read_seq)
  `uvm_declare_p_sequencer(axi4_master_read_sequencer)

  bit [ADDRESS_WIDTH-1:0] addr = 0; // Not randomizable - set by virtual sequence
  rand int unsigned len = 0;
  int bytes;
  function new(string name="axi4_master_wstrb_read_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    start_item(req);
    bytes = p_sequencer.axi4_master_agent_cfg_h.data_width/8;
    if(!req.randomize() with {req.araddr == addr;
                              req.arlen == len;
                              req.arsize == arsize_e'($clog2(bytes));
                              req.arburst == READ_INCR;
                              req.tx_type == READ;
                              req.transfer_type == BLOCKING_READ;}) begin
      `uvm_fatal("axi4","Rand failed")
    end
    
    `uvm_info(get_type_name(), $sformatf("WSTRB TEST: Reading from address 0x%016h, len=%0d", addr, len), UVM_LOW)
    
    finish_item(req);
    
    // Log the read data for verification
    foreach(req.rdata[i]) begin
      `uvm_info(get_type_name(), $sformatf("  Read Beat[%0d]: data=0x%08h", i, req.rdata[i]), UVM_LOW)
    end
  endtask
endclass

`endif
