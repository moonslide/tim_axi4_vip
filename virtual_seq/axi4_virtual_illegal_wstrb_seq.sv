`ifndef AXI4_VIRTUAL_ILLEGAL_WSTRB_SEQ_INCLUDED_
`define AXI4_VIRTUAL_ILLEGAL_WSTRB_SEQ_INCLUDED_

class axi4_virtual_illegal_wstrb_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_illegal_wstrb_seq)

  // Pattern and data words for illegal testing
  bit [STROBE_WIDTH-1:0] pattern[$];
  bit [DATA_WIDTH-1:0]   data_words[$];
  awsize_e test_size = WRITE_2_BYTES;
  rand bit [ADDRESS_WIDTH-1:0] addr = 0;

  function new(string name="axi4_virtual_illegal_wstrb_seq");
    super.new(name);
  endfunction

  task body();
    axi4_master_illegal_wstrb_seq illegal_seq[];
    axi4_slave_bk_write_seq       sseq_w[];

    illegal_seq = new[p_sequencer.axi4_master_write_seqr_h_all.size()];
    sseq_w      = new[p_sequencer.axi4_slave_write_seqr_h_all.size()];

    foreach(sseq_w[i])
      sseq_w[i] = axi4_slave_bk_write_seq::type_id::create($sformatf("sseq_w[%0d]", i));

    // Use DDR memory base address for valid address
    if(addr == 0) addr = 64'h0000_0100_0000_0000;

    // Create illegal wstrb sequences
    foreach(illegal_seq[i]) begin
      illegal_seq[i] = axi4_master_illegal_wstrb_seq::type_id::create($sformatf("illegal_seq[%0d]", i));
      foreach(pattern[j]) illegal_seq[i].wstrb_q.push_back(pattern[j]);
      foreach(data_words[j]) illegal_seq[i].data_q.push_back(data_words[j]);
      illegal_seq[i].addr = addr + i*'h10;
      illegal_seq[i].test_size = test_size;
    end

    // Start slave responders
    fork
      foreach(sseq_w[i]) sseq_w[i].start(p_sequencer.axi4_slave_write_seqr_h_all[i]);
    join_none

    // Send illegal wstrb patterns and expect protocol errors
    `uvm_warning(get_type_name(), "ILLEGAL WSTRB TEST: Sending illegal wstrb patterns - expecting protocol violations")
    foreach(illegal_seq[i]) illegal_seq[i].start(p_sequencer.axi4_master_write_seqr_h_all[i]);
  endtask
endclass

`endif