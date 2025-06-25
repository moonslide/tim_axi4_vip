//----------------------------------------------------------------------
// Copyright (c) 2021, Truechip Solutions Pvt. Ltd.
// ALL RIGHTS RESERVED
//----------------------------------------------------------------------
// File name : axi4_master_bk_write_wrap_various_lengths_test.sv
// Author    : Truechip
// Version   : 1.0
// Created   :
//----------------------------------------------------------------------

`ifndef AXI4_MASTER_BK_WRITE_WRAP_VARIOUS_LENGTHS_TEST_SV
`define AXI4_MASTER_BK_WRITE_WRAP_VARIOUS_LENGTHS_TEST_SV

//----------------------------------------------------------------------
// Class: axi4_master_bk_write_wrap_various_lengths_test
// Description: Test for WRAP burst writes
//----------------------------------------------------------------------
class axi4_master_bk_write_wrap_various_lengths_test extends axi4_base_test;
  `uvm_component_utils(axi4_master_bk_write_wrap_various_lengths_test)

  //--------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------
  function new(string name = "axi4_master_bk_write_wrap_various_lengths_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //--------------------------------------------------------------------
  // Task: run_phase
  // Description: Run the WRAP burst test sequence
  //--------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    axi4_master_bk_write_wrap_various_lengths_seq m_seq;

    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Starting test: axi4_master_bk_write_wrap_various_lengths_test", UVM_LOW)

    m_seq = axi4_master_bk_write_wrap_various_lengths_seq::type_id::create("m_seq");
    // No specific randomization needed at test level, sequence handles parameters
    assert(m_seq.randomize());
    m_seq.start(axi4_env_h.axi4_mas_agent_h[0].m_seqr_h);

    #200ns; // Adjust delay as needed for transaction completion
    phase.drop_objection(this);
    `uvm_info(get_type_name(), "Finished test: axi4_master_bk_write_wrap_various_lengths_test", UVM_LOW)
  endtask : run_phase

endclass : axi4_master_bk_write_wrap_various_lengths_test

`endif // AXI4_MASTER_BK_WRITE_WRAP_VARIOUS_LENGTHS_TEST_SV
