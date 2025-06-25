//----------------------------------------------------------------------
// Copyright (c) 2021, Truechip Solutions Pvt. Ltd.
// ALL RIGHTS RESERVED
//----------------------------------------------------------------------
// File name : axi4_master_bk_write_max_burst_length_test.sv
// Author    : Truechip
// Version   : 1.0
// Created   :
//----------------------------------------------------------------------

`ifndef AXI4_MASTER_BK_WRITE_MAX_BURST_LENGTH_TEST_SV
`define AXI4_MASTER_BK_WRITE_MAX_BURST_LENGTH_TEST_SV

//----------------------------------------------------------------------
// Class: axi4_master_bk_write_max_burst_length_test
// Description: Test for writing with maximum burst length
//----------------------------------------------------------------------
class axi4_master_bk_write_max_burst_length_test extends axi4_base_test;
  `uvm_component_utils(axi4_master_bk_write_max_burst_length_test)

  //--------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------
  function new(string name = "axi4_master_bk_write_max_burst_length_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //--------------------------------------------------------------------
  // Function: build_phase
  // Description: Build environment components
  //--------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction : build_phase

  //--------------------------------------------------------------------
  // Task: run_phase
  // Description: Run the test sequence
  //--------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    axi4_master_bk_write_max_burst_length_seq m_seq;

    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Starting test: axi4_master_bk_write_max_burst_length_test", UVM_LOW)

    // Create and start the master sequence
    m_seq = axi4_master_bk_write_max_burst_length_seq::type_id::create("m_seq");
    assert(m_seq.randomize()); // Basic randomization, specific constraints are in the sequence
    m_seq.start(axi4_env_h.axi4_mas_agent_h[0].m_seqr_h); // Assuming agent 0 and its master sequencer

    #100ns; // Add some delay for the test to complete
    phase.drop_objection(this);
    `uvm_info(get_type_name(), "Finished test: axi4_master_bk_write_max_burst_length_test", UVM_LOW)
  endtask : run_phase

endclass : axi4_master_bk_write_max_burst_length_test

`endif // AXI4_MASTER_BK_WRITE_MAX_BURST_LENGTH_TEST_SV
