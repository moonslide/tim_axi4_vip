`ifndef AXI4_TC_058_EXCLUSIVE_READ_FAIL_TEST_INCLUDED_
`define AXI4_TC_058_EXCLUSIVE_READ_FAIL_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_tc_058_exclusive_read_fail_test
// TC_058: Optional Exclusive Read Fail
// Tests write then exclusive read (ARLOCK=1) to unprivileged address range
// Expected BRESP=SLVERR for write and RRESP=SLVERR for read indicating access privilege violation
//--------------------------------------------------------------------------------------------
class axi4_tc_058_exclusive_read_fail_test extends axi4_base_test;
  `uvm_component_utils(axi4_tc_058_exclusive_read_fail_test)

  axi4_virtual_tc_058_exclusive_read_fail_seq axi4_virtual_tc_058_seq_h;

  extern function new(string name = "axi4_tc_058_exclusive_read_fail_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_tc_058_exclusive_read_fail_test

function axi4_tc_058_exclusive_read_fail_test::new(string name = "axi4_tc_058_exclusive_read_fail_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_tc_058_exclusive_read_fail_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure for write-read test (both write and read to unprivileged address)
  axi4_env_cfg_h.write_read_mode_h = WRITE_READ_DATA;
  
  // Enable error injection mode to convert UVM_ERROR to UVM_WARNING for expected errors
  axi4_env_cfg_h.error_inject = 1;
  
  // Update the config_db with modified configuration
  uvm_config_db #(axi4_env_config)::set(this,"*","axi4_env_config",axi4_env_cfg_h);
endfunction : build_phase

task axi4_tc_058_exclusive_read_fail_test::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  axi4_virtual_tc_058_seq_h = axi4_virtual_tc_058_exclusive_read_fail_seq::type_id::create("axi4_virtual_tc_058_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi4_tc_058_exclusive_read_fail_test"),UVM_LOW);
  axi4_virtual_tc_058_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  #10;
  phase.drop_objection(this);
endtask : run_phase

`endif