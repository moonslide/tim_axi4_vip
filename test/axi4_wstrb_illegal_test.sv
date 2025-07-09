`ifndef AXI4_WSTRB_ILLEGAL_TEST_INCLUDED_
`define AXI4_WSTRB_ILLEGAL_TEST_INCLUDED_

class axi4_wstrb_illegal_test extends axi4_base_test;
  `uvm_component_utils(axi4_wstrb_illegal_test)

  bit [STROBE_WIDTH-1:0] pattern[];
  bit [DATA_WIDTH-1:0]   data_words[];

  function new(string name="axi4_wstrb_illegal_test", uvm_component parent=null);
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
    
    pattern = new[3];
    data_words = new[3];
    
    // Test illegal wstrb patterns for awsize=WRITE_2BYTES (2 byte transfers)
    // Legal patterns for 2-byte: 4'b0011, 4'b1100, 4'b1111
    // Illegal patterns: 4'b0101, 4'b1010, 4'b0110 (non-contiguous)
    pattern[0] = 4'b0101; // Illegal: non-contiguous for 2-byte transfer
    pattern[1] = 4'b1010; // Illegal: non-contiguous for 2-byte transfer  
    pattern[2] = 4'b0110; // Illegal: non-contiguous for 2-byte transfer
    data_words[0] = 32'hFEEDFACE;
    data_words[1] = 32'hDEADBEEF;
    data_words[2] = 32'hCAFEBABE;
    
    `uvm_warning(get_type_name(), "WSTRB ILLEGAL TEST: Testing illegal wstrb patterns for 2-byte transfers (expecting protocol violations)")
  endfunction

  virtual task run_phase(uvm_phase phase);
    axi4_virtual_illegal_wstrb_seq vseq;
    phase.raise_objection(this);
    vseq = axi4_virtual_illegal_wstrb_seq::type_id::create("vseq");
    foreach(pattern[i]) vseq.pattern.push_back(pattern[i]);
    foreach(data_words[i]) vseq.data_words.push_back(data_words[i]);
    vseq.test_size = WRITE_2_BYTES; // 2-byte transfers
    vseq.start(axi4_env_h.axi4_virtual_seqr_h);
    phase.drop_objection(this);
  endtask
endclass

`endif
