`ifndef AXI4_SMOKE_TEST_ENHANCED_INCLUDED_
`define AXI4_SMOKE_TEST_ENHANCED_INCLUDED_

class axi4_smoke_test_enhanced extends axi4_base_test;
  `uvm_component_utils(axi4_smoke_test_enhanced)
  
  axi4_master_nbk_write_rand_seq write_seq;
  axi4_master_nbk_read_rand_seq read_seq;
  
  function new(string name = "axi4_smoke_test_enhanced", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Enhanced configuration but with minimal scope
    axi4_env_cfg_h.no_of_masters = 2;  // Limit masters
    axi4_env_cfg_h.no_of_slaves = 2;   // Limit slaves
  endfunction
  
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Running enhanced smoke test", UVM_LOW)
    
    // Basic smoke test
    write_seq = axi4_master_nbk_write_rand_seq::type_id::create("write_seq");
    write_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h);
    
    read_seq = axi4_master_nbk_read_rand_seq::type_id::create("read_seq");
    read_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h);
    
    `uvm_info(get_type_name(), "Smoke test completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass
`endif
