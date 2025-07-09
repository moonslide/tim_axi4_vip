`ifndef AXI4_WSTRB_SINGLE_BIT_TEST_INCLUDED_
`define AXI4_WSTRB_SINGLE_BIT_TEST_INCLUDED_

class axi4_wstrb_single_bit_test extends axi4_base_test;
  `uvm_component_utils(axi4_wstrb_single_bit_test)

  bit [STROBE_WIDTH-1:0] pattern[];
  bit [DATA_WIDTH-1:0]   data_words[];

  function new(string name="axi4_wstrb_single_bit_test", uvm_component parent=null);
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
    
    // Test: Single bit wstrb patterns - each beat writes only one byte
    // Beat 0: wstrb=4'b0001 - write only byte 0
    // Beat 1: wstrb=4'b0010 - write only byte 1
    // Beat 2: wstrb=4'b0100 - write only byte 2
    // Beat 3: wstrb=4'b1000 - write only byte 3
    pattern[0] = 4'b0001;
    pattern[1] = 4'b0010;
    pattern[2] = 4'b0100;
    pattern[3] = 4'b1000;
    data_words[0] = 32'h11112222;
    data_words[1] = 32'h33334444;
    data_words[2] = 32'h55556666;
    data_words[3] = 32'h77778888;
    
    `uvm_info(get_type_name(), "WSTRB SINGLE BIT TEST: Testing single bit wstrb patterns (0001, 0010, 0100, 1000)", UVM_LOW)
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
