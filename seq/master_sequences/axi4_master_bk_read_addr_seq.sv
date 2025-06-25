`ifndef AXI4_MASTER_BK_READ_ADDR_SEQ_INCLUDED_
`define AXI4_MASTER_BK_READ_ADDR_SEQ_INCLUDED_
class axi4_master_bk_read_addr_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_read_addr_seq)
  `uvm_declare_p_sequencer(axi4_master_read_sequencer)
  bit [ADDRESS_WIDTH-1:0] addr;
  int arlen = -1;
  arsize_e arsize;
  arburst_e arburst;
  bit use_size = 0;
  bit use_burst = 0;
  bit use_len = 0;
  function new(string name="axi4_master_bk_read_addr_seq");
    super.new(name);
  endfunction
  task body();
    super.body();
    if(!$cast(p_sequencer,m_sequencer))begin
      `uvm_error(get_full_name(),"seq pointer cast failed")
    end
    start_item(req);
    if(!req.randomize() with { req.tx_type == READ;
                               req.transfer_type == BLOCKING_READ; })
      `uvm_fatal("axi4","Rand failed");
    req.araddr = addr;
    if(use_len)   req.arlen  = arlen;
    if(use_size)  req.arsize = arsize;
    if(use_burst) req.arburst= arburst;
    finish_item(req);
  endtask
endclass
`endif
