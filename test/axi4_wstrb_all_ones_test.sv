`ifndef AXI4_WSTRB_ALL_ONES_TEST_INCLUDED_
`define AXI4_WSTRB_ALL_ONES_TEST_INCLUDED_

class axi4_wstrb_all_ones_test extends axi4_base_test;
  `uvm_component_utils(axi4_wstrb_all_ones_test)

  bit [STROBE_WIDTH-1:0] pattern[$];
  bit [DATA_WIDTH-1:0]   data_words[$];

  function new(string name="axi4_wstrb_all_ones_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  function void setup_axi4_slave_agent_cfg();
    super.setup_axi4_slave_agent_cfg();
    foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].maximum_transactions = 20; // Increase for wstrb test
    end
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi4_env_cfg_h.wstrb_compare_enable = 1;
    
    // Configure for READ_AFTER_WRITE mode to verify wstrb behavior
    axi4_env_cfg_h.write_read_mode_h = WRITE_READ_DATA;
    
    pattern.delete();
    data_words.delete();
    
    // Test: wstrb=4'b1111 means ALL bytes should be written
    // Expected: Memory should contain new value (0xCAFEBABE) because all bytes are strobed
    pattern.push_back(4'b1111);
    data_words.push_back(32'hCAFEBABE);
    
    `uvm_info(get_type_name(), "WSTRB ALL ONES TEST: Testing that wstrb=4'b1111 writes all bytes (memory should contain new data)", UVM_LOW)
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
