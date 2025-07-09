`ifndef AXI4_WSTRB_UPPER_HALF_TEST_INCLUDED_
`define AXI4_WSTRB_UPPER_HALF_TEST_INCLUDED_

class axi4_wstrb_upper_half_test extends axi4_base_test;
  `uvm_component_utils(axi4_wstrb_upper_half_test)

  bit [STROBE_WIDTH-1:0] pattern[];
  bit [DATA_WIDTH-1:0]   data_words[];

  function new(string name="axi4_wstrb_upper_half_test", uvm_component parent=null);
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
    
    pattern = new[1];
    data_words = new[1];
    
    // Test: wstrb=4'b1100 means upper 2 bytes (bytes 3,2) should be written
    // Baseline: 0xFFFFFFFF, Writing: 0x11223344
    // Expected: 0x1122FFFF (upper bytes 0x1122, lower bytes preserve 0xFFFF)
    pattern[0] = 4'b1100;
    data_words[0] = 32'h11223344;
    
    `uvm_info(get_type_name(), "WSTRB UPPER HALF TEST: Testing that wstrb=4'b1100 writes only upper 2 bytes (bytes 3,2)", UVM_LOW)
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
