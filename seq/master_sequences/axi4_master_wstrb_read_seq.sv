`ifndef AXI4_MASTER_WSTRB_READ_SEQ_INCLUDED_
`define AXI4_MASTER_WSTRB_READ_SEQ_INCLUDED_

class axi4_master_wstrb_read_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_wstrb_read_seq)
  `uvm_declare_p_sequencer(axi4_master_read_sequencer)

  rand bit [ADDRESS_WIDTH-1:0] addr = 0;
  rand int unsigned len = 0;

  function new(string name="axi4_master_wstrb_read_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    start_item(req);
    int bytes = p_sequencer.axi4_master_agent_cfg_h.data_width/8;
    if(!req.randomize() with {req.araddr == addr;
                              req.arlen == len;
                              req.arsize == arsize_e'($clog2(bytes));
                              req.arburst == READ_INCR;
                              req.tx_type == READ;
                              req.transfer_type == BLOCKING_READ;}) begin
      `uvm_fatal("axi4","Rand failed")
    end
    finish_item(req);
  endtask
endclass

`endif
