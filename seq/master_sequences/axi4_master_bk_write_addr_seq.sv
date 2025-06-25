`ifndef AXI4_MASTER_BK_WRITE_ADDR_SEQ_INCLUDED_
`define AXI4_MASTER_BK_WRITE_ADDR_SEQ_INCLUDED_
class axi4_master_bk_write_addr_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_master_bk_write_addr_seq)
  `uvm_declare_p_sequencer(axi4_master_write_sequencer)
  bit [ADDRESS_WIDTH-1:0] addr;
  int awlen = -1;
  awsize_e awsize;
  awburst_e awburst;
  bit use_size = 0;
  bit use_burst = 0;
  bit use_len = 0;
  function new(string name="axi4_master_bk_write_addr_seq");
    super.new(name);
  endfunction
  task body();
    super.body();
    if(!$cast(p_sequencer,m_sequencer))begin
      `uvm_error(get_full_name(),"seq pointer cast failed")
    end
    start_item(req);
    if(!req.randomize() with { req.tx_type == WRITE;
                               req.transfer_type == BLOCKING_WRITE; })
      `uvm_fatal("axi4","Rand failed");
    req.awaddr = addr;
    if(use_len)   req.awlen  = awlen;
    if(use_size)  req.awsize = awsize;
    if(use_burst) req.awburst= awburst;
    finish_item(req);
  endtask
endclass
`endif
