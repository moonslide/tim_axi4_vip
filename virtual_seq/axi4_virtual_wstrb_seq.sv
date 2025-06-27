`ifndef AXI4_VIRTUAL_WSTRB_SEQ_INCLUDED_
`define AXI4_VIRTUAL_WSTRB_SEQ_INCLUDED_

class axi4_virtual_wstrb_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_wstrb_seq)

  // Pattern and data words for all masters
  bit [STROBE_WIDTH-1:0] pattern[$];
  bit [DATA_WIDTH-1:0]   data_words[$];
  rand bit [ADDRESS_WIDTH-1:0] addr = 0;

  function new(string name="axi4_virtual_wstrb_seq");
    super.new(name);
  endfunction

  task body();
    axi4_master_wstrb_seq      mseq[];
    axi4_master_wstrb_read_seq rseq[];
    axi4_slave_bk_write_16b_transfer_seq sseq_w[];
    axi4_slave_bk_read_32b_transfer_seq  sseq_r[];

    mseq   = new[p_sequencer.axi4_master_write_seqr_h_all.size()];
    rseq   = new[p_sequencer.axi4_master_read_seqr_h_all.size()];
    sseq_w = new[p_sequencer.axi4_slave_write_seqr_h_all.size()];
    sseq_r = new[p_sequencer.axi4_slave_read_seqr_h_all.size()];

    foreach(sseq_w[i])
      sseq_w[i] = axi4_slave_bk_write_16b_transfer_seq::type_id::create($sformatf("sseq_w[%0d]", i));
    foreach(sseq_r[i])
      sseq_r[i] = axi4_slave_bk_read_32b_transfer_seq::type_id::create($sformatf("sseq_r[%0d]", i));
    foreach(mseq[i]) begin
      mseq[i] = axi4_master_wstrb_seq::type_id::create($sformatf("mseq[%0d]", i));
      foreach(pattern[j]) mseq[i].wstrb_q.push_back(pattern[j]);
      foreach(data_words[j]) mseq[i].data_q.push_back(data_words[j]);
      mseq[i].addr = addr + i*'h10;
    end
    foreach(rseq[i]) begin
      rseq[i] = axi4_master_wstrb_read_seq::type_id::create($sformatf("rseq[%0d]", i));
      rseq[i].addr = addr + i*'h10;
      rseq[i].len  = pattern.size()-1;
    end

    // start slave write sequences
    fork
      foreach(sseq_w[i]) sseq_w[i].start(p_sequencer.axi4_slave_write_seqr_h_all[i]);
    join_none
    // start master write sequences
    foreach(mseq[i]) mseq[i].start(p_sequencer.axi4_master_write_seqr_h_all[i]);

    // start slave read sequences
    fork
      foreach(sseq_r[i]) sseq_r[i].start(p_sequencer.axi4_slave_read_seqr_h_all[i]);
    join_none
    // start master read sequences
    foreach(rseq[i]) rseq[i].start(p_sequencer.axi4_master_read_seqr_h_all[i]);
  endtask
endclass

`endif
