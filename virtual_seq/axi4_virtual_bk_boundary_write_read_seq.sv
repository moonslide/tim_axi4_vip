`ifndef AXI4_VIRTUAL_BK_BOUNDARY_WRITE_READ_SEQ_INCLUDED_
`define AXI4_VIRTUAL_BK_BOUNDARY_WRITE_READ_SEQ_INCLUDED_
class axi4_virtual_bk_boundary_write_read_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_bk_boundary_write_read_seq)

  axi4_master_bk_write_addr_seq master_wr_seq;
  axi4_master_bk_read_addr_seq  master_rd_seq;
  axi4_slave_bk_write_incr_burst_seq slave_wr_seq;
  axi4_slave_bk_read_incr_burst_seq  slave_rd_seq;
  int slave_idx = 0;

  function new(string name="axi4_virtual_bk_boundary_write_read_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    master_wr_seq = axi4_master_bk_write_addr_seq::type_id::create("master_wr_seq");
    master_rd_seq = axi4_master_bk_read_addr_seq::type_id::create("master_rd_seq");
    slave_wr_seq  = axi4_slave_bk_write_incr_burst_seq::type_id::create("slave_wr_seq");
    slave_rd_seq  = axi4_slave_bk_read_incr_burst_seq::type_id::create("slave_rd_seq");

    bit [ADDRESS_WIDTH-1:0] min_addr = env_cfg_h.axi4_master_agent_cfg_h[0].master_min_addr_range_array[slave_idx];
    bit [ADDRESS_WIDTH-1:0] max_addr = env_cfg_h.axi4_master_agent_cfg_h[0].master_max_addr_range_array[slave_idx];

    fork
      begin : T1_SL_WR
        forever slave_wr_seq.start(p_sequencer.axi4_slave_write_seqr_h_all[slave_idx]);
      end
      begin : T2_SL_RD
        forever slave_rd_seq.start(p_sequencer.axi4_slave_read_seqr_h_all[slave_idx]);
      end
    join_none

    master_wr_seq.addr = min_addr;
    master_wr_seq.start(p_sequencer.axi4_master_write_seqr_h);
    master_wr_seq.addr = max_addr;
    master_wr_seq.start(p_sequencer.axi4_master_write_seqr_h);
    master_wr_seq.addr = max_addr + 4;
    master_wr_seq.start(p_sequencer.axi4_master_write_seqr_h);

    master_rd_seq.addr = min_addr;
    master_rd_seq.start(p_sequencer.axi4_master_read_seqr_h);
    master_rd_seq.addr = max_addr;
    master_rd_seq.start(p_sequencer.axi4_master_read_seqr_h);
    master_rd_seq.addr = max_addr + 4;
    master_rd_seq.start(p_sequencer.axi4_master_read_seqr_h);
  endtask
endclass
`endif
