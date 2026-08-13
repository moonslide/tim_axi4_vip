`ifndef AXI4_4K_BOUNDARY_CROSS_TEST_INCLUDED_
`define AXI4_4K_BOUNDARY_CROSS_TEST_INCLUDED_

class axi4_4k_boundary_cross_test extends axi4_base_test;
  `uvm_component_utils(axi4_4k_boundary_cross_test)

  axi4_virtual_4k_boundary_cross_seq vseq;

  extern function new(string name="axi4_4k_boundary_cross_test", uvm_component parent=null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
endclass

function axi4_4k_boundary_cross_test::new(string name, uvm_component parent=null);
  super.new(name,parent);
endfunction

//--------------------------------------------------------------------------------------------
// Function: build_phase
// The unmapped-space leg of the sequence deliberately provokes DECERR, and the
// test name matches none of the auto-detect patterns axi4_performance_metrics
// uses (*error*, *fail*, *illegal*, *violation*, *raw*, *slave_error*,
// *exception*).  Without this the deliberate DECERR is scored as a protocol
// issue and report_phase raises "TEST RESULT: FAIL".
//--------------------------------------------------------------------------------------------
function void axi4_4k_boundary_cross_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  axi4_env_cfg_h.allow_error_responses = 1;
  `uvm_info(get_type_name(),
            "Setting allow_error_responses=1: the unmapped-space crossing burst must return DECERR",
            UVM_LOW)
endfunction : build_phase

task axi4_4k_boundary_cross_test::run_phase(uvm_phase phase);
  vseq = axi4_virtual_4k_boundary_cross_seq::type_id::create("vseq");
  phase.raise_objection(this);
  vseq.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
endtask

`endif
