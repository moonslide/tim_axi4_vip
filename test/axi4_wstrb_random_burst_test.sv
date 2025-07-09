`ifndef AXI4_WSTRB_RANDOM_BURST_TEST_INCLUDED_
`define AXI4_WSTRB_RANDOM_BURST_TEST_INCLUDED_

class axi4_wstrb_random_burst_test extends axi4_base_test;
  `uvm_component_utils(axi4_wstrb_random_burst_test)

  bit [STROBE_WIDTH-1:0] pattern[];
  bit [DATA_WIDTH-1:0]   data_words[];

  function new(string name="axi4_wstrb_random_burst_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  function void setup_axi4_slave_agent_cfg();
    super.setup_axi4_slave_agent_cfg();
    foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      // Only modify non-ROM slaves to use SLAVE_MEM_MODE
      // ROM slave (i==1) keeps its RANDOM_DATA_MODE from base configuration
      if (i != 1) begin
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
      end
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].maximum_transactions = 20; // Increase for wstrb test
    end
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi4_env_cfg_h.wstrb_compare_enable = 1;
    
    // Configure for READ_AFTER_WRITE mode to verify wstrb behavior
    axi4_env_cfg_h.write_read_mode_h = WRITE_READ_DATA;
    
    pattern = new[4];
    data_words = new[4];
    
    // Test: Random wstrb patterns in a burst (but avoid 0000 to ensure some bytes are written)
    foreach(pattern[i]) begin
      do begin
        pattern[i] = $urandom_range(1,15); // 1-15 to avoid all zeros
      end while(pattern[i] == 0);
    end
    
    data_words[0] = 32'hA0A0A0A0;
    data_words[1] = 32'hB1B1B1B1;
    data_words[2] = 32'hC2C2C2C2;
    data_words[3] = 32'hD3D3D3D3;
    
    `uvm_info(get_type_name(), "WSTRB RANDOM BURST TEST: Testing random wstrb patterns in a 4-beat burst", UVM_LOW)
    foreach(pattern[i]) begin
      `uvm_info(get_type_name(), $sformatf("  Beat[%0d]: wstrb=4'b%04b, data=0x%08h", i, pattern[i], data_words[i]), UVM_LOW)
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    axi4_virtual_wstrb_seq vseq;
    phase.raise_objection(this);
    vseq = axi4_virtual_wstrb_seq::type_id::create("vseq");
    foreach(pattern[i]) vseq.pattern.push_back(pattern[i]);
    foreach(data_words[i]) vseq.data_words.push_back(data_words[i]);
    vseq.start(axi4_env_h.axi4_virtual_seqr_h);
    phase.drop_objection(this);
  endtask
endclass

`endif
