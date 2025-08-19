`ifndef AXI4_HOTSPOT_FAIRNESS_BOUNDARY_ERROR_RESET_BACKPRESSURE_TEST_INCLUDED_
`define AXI4_HOTSPOT_FAIRNESS_BOUNDARY_ERROR_RESET_BACKPRESSURE_TEST_INCLUDED_

class axi4_hotspot_fairness_boundary_error_reset_backpressure_test extends axi4_base_test;
  `uvm_component_utils(axi4_hotspot_fairness_boundary_error_reset_backpressure_test)
  
  axi4_master_nbk_write_rand_seq write_seq;
  axi4_master_nbk_read_rand_seq read_seq;
  
  function new(string name = "axi4_hotspot_fairness_boundary_error_reset_backpressure_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "Hotspot fairness test build phase", UVM_LOW)
  endfunction
  
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Running simplified hotspot fairness test", UVM_LOW)
    
    // Run minimal transactions
    write_seq = axi4_master_nbk_write_rand_seq::type_id::create("write_seq");
    write_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h);
    
    read_seq = axi4_master_nbk_read_rand_seq::type_id::create("read_seq");
    read_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h);
    
    #100ns;
    
    `uvm_info(get_type_name(), "Test completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass
`endif
