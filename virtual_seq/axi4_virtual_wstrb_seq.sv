`ifndef AXI4_VIRTUAL_WSTRB_SEQ_INCLUDED_
`define AXI4_VIRTUAL_WSTRB_SEQ_INCLUDED_

class axi4_virtual_wstrb_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_wstrb_seq)

  // Pattern and data words for all masters
  bit [STROBE_WIDTH-1:0] pattern[$];
  bit [DATA_WIDTH-1:0]   data_words[$];
  bit [ADDRESS_WIDTH-1:0] addr = 64'h0000_0100_0000_0000; // Use DDR base address

  function new(string name="axi4_virtual_wstrb_seq");
    super.new(name);
  endfunction

  task body();
    axi4_master_wstrb_baseline_seq baseline_seq[];
    axi4_master_wstrb_seq          wstrb_seq[];
    axi4_master_wstrb_read_seq     read_seq[];

    baseline_seq = new[p_sequencer.axi4_master_write_seqr_h_all.size()];
    wstrb_seq    = new[p_sequencer.axi4_master_write_seqr_h_all.size()];
    read_seq     = new[p_sequencer.axi4_master_read_seqr_h_all.size()];

    // Create baseline write sequences to establish known memory content
    foreach(baseline_seq[i]) begin
      baseline_seq[i] = axi4_master_wstrb_baseline_seq::type_id::create($sformatf("baseline_seq[%0d]", i));
      baseline_seq[i].addr = addr + i*'h10;
      baseline_seq[i].baseline_data = 32'hFFFFFFFF; // Known baseline pattern
    end

    // Create wstrb test sequences
    foreach(wstrb_seq[i]) begin
      wstrb_seq[i] = axi4_master_wstrb_seq::type_id::create($sformatf("wstrb_seq[%0d]", i));
      foreach(pattern[j]) wstrb_seq[i].wstrb_q.push_back(pattern[j]);
      foreach(data_words[j]) wstrb_seq[i].data_q.push_back(data_words[j]);
      wstrb_seq[i].addr = addr + i*'h10;
    end

    // Create read sequences
    foreach(read_seq[i]) begin
      read_seq[i] = axi4_master_wstrb_read_seq::type_id::create($sformatf("read_seq[%0d]", i));
      read_seq[i].addr = addr + i*'h10;
      read_seq[i].len  = pattern.size()-1;
    end

    // Note: Slave sequences are now automatically started by the sequencers in SLAVE_MEM_MODE

    // Step 1: Write baseline data to establish known memory content
    `uvm_info(get_type_name(), "WSTRB TEST: Writing baseline data to memory", UVM_LOW)
    foreach(baseline_seq[i]) baseline_seq[i].start(p_sequencer.axi4_master_write_seqr_h_all[i]);
    
    // Wait for baseline writes to complete
    #1000ns;

    // Step 2: Write test data with specific wstrb patterns
    `uvm_info(get_type_name(), "WSTRB TEST: Writing data with wstrb patterns", UVM_LOW)
    foreach(wstrb_seq[i]) wstrb_seq[i].start(p_sequencer.axi4_master_write_seqr_h_all[i]);
    
    // Wait for wstrb writes to complete before starting reads
    #1000ns;

    // Step 3: Read back and verify wstrb behavior
    `uvm_info(get_type_name(), "WSTRB TEST: Reading back data to verify wstrb behavior", UVM_LOW)
    foreach(read_seq[i]) read_seq[i].start(p_sequencer.axi4_master_read_seqr_h_all[i]);
  endtask
endclass

`endif
