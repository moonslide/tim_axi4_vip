`ifndef AXI4_VIRTUAL_BK_BOUNDARY_SINGLE_SEQ_INCLUDED_
`define AXI4_VIRTUAL_BK_BOUNDARY_SINGLE_SEQ_INCLUDED_
class axi4_virtual_bk_boundary_single_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_bk_boundary_single_seq)

  bit is_write = 1;
  bit [ADDRESS_WIDTH-1:0] addr;
  int len = -1;
  bit len_valid = 0;
  bit size_valid = 0;
  bit burst_valid = 0;
  awsize_e size;
  awburst_e burst;
  int slave_idx = 0;

  function new(string name="axi4_virtual_bk_boundary_single_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    axi4_slave_bk_write_incr_burst_seq sl_wr_seq;
    axi4_slave_bk_read_incr_burst_seq  sl_rd_seq;
    axi4_master_bk_write_addr_seq      m_wr_seq;
    axi4_master_bk_read_addr_seq       m_rd_seq;

    if(is_write) begin
      sl_wr_seq = axi4_slave_bk_write_incr_burst_seq::type_id::create("sl_wr_seq");
      fork
        forever sl_wr_seq.start(p_sequencer.axi4_slave_write_seqr_h_all[slave_idx]);
      join_none
      m_wr_seq = axi4_master_bk_write_addr_seq::type_id::create("m_wr_seq");
      m_wr_seq.addr = addr;
      if(len_valid) begin m_wr_seq.use_len = 1; m_wr_seq.awlen = len; end
      if(size_valid) begin m_wr_seq.use_size = 1; m_wr_seq.awsize = size; end
      if(burst_valid) begin m_wr_seq.use_burst = 1; m_wr_seq.awburst = burst; end
      m_wr_seq.start(p_sequencer.axi4_master_write_seqr_h);
    end
    else begin
      sl_rd_seq = axi4_slave_bk_read_incr_burst_seq::type_id::create("sl_rd_seq");
      fork
        forever sl_rd_seq.start(p_sequencer.axi4_slave_read_seqr_h_all[slave_idx]);
      join_none
      m_rd_seq = axi4_master_bk_read_addr_seq::type_id::create("m_rd_seq");
      m_rd_seq.addr = addr;
      if(len_valid) begin m_rd_seq.use_len = 1; m_rd_seq.arlen = len; end
      if(size_valid) begin m_rd_seq.use_size = 1; m_rd_seq.arsize = size; end
      if(burst_valid) begin m_rd_seq.use_burst = 1; m_rd_seq.arburst = burst; end
      m_rd_seq.start(p_sequencer.axi4_master_read_seqr_h);
    end
  endtask
endclass
`endif

