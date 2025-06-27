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
    foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i])
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi4_env_cfg_h.wstrb_compare_enable = 1;
    pattern = new[4];
    data_words = new[4];
    pattern[0] = 4'b0001;
    pattern[1] = 4'b0010;
    pattern[2] = 4'b0100;
    pattern[3] = 4'b1000;
    data_words[0] = 32'h11112222;
    data_words[1] = 32'h33334444;
    data_words[2] = 32'h55556666;
    data_words[3] = 32'h77778888;
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
