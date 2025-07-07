`ifndef AXI4_LOWER_BOUNDARY_READ_TEST_INCLUDED_
`define AXI4_LOWER_BOUNDARY_READ_TEST_INCLUDED_

class axi4_lower_boundary_read_test extends axi4_base_test;
  `uvm_component_utils(axi4_lower_boundary_read_test)

  axi4_virtual_lower_boundary_read_seq vseq;

  extern function new(string name="axi4_lower_boundary_read_test", uvm_component parent=null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
endclass

function axi4_lower_boundary_read_test::new(string name, uvm_component parent=null);
  super.new(name,parent);
endfunction

function void axi4_lower_boundary_read_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Override write_read_mode for read-only test
  axi4_env_cfg_h.write_read_mode_h = ONLY_READ_DATA;
  
  // Enable error injection mode to convert UVM_ERROR to UVM_WARNING for expected errors
  axi4_env_cfg_h.error_inject = 1;
  
  // Update the config_db with modified configuration
  uvm_config_db #(axi4_env_config)::set(this,"*","axi4_env_config",axi4_env_cfg_h);
endfunction

task axi4_lower_boundary_read_test::run_phase(uvm_phase phase);
  vseq = axi4_virtual_lower_boundary_read_seq::type_id::create("vseq");
  phase.raise_objection(this);
  vseq.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
endtask

`endif
