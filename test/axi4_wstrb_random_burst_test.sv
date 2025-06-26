`ifndef AXI4_WSTRB_RANDOM_BURST_TEST_INCLUDED_
`define AXI4_WSTRB_RANDOM_BURST_TEST_INCLUDED_

class axi4_wstrb_random_burst_test extends axi4_base_test;
  `uvm_component_utils(axi4_wstrb_random_burst_test)

  bit [STROBE_WIDTH-1:0] pattern[];
  bit [DATA_WIDTH-1:0]   data_words[];

  function new(string name="axi4_wstrb_random_burst_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axi4_env_cfg_h.wstrb_compare_enable = 1;
    pattern = new[4];
    data_words = new[4];
    foreach(pattern[i]) pattern[i] = $urandom_range(0,15);
    data_words[0] = 32'hA0A0A0A0;
    data_words[1] = 32'hB1B1B1B1;
    data_words[2] = 32'hC2C2C2C2;
    data_words[3] = 32'hD3D3D3D3;
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
