//----------------------------------------------------------------------
// Copyright (c) 2021, Truechip Solutions Pvt. Ltd.
// ALL RIGHTS RESERVED
//----------------------------------------------------------------------
// File name : axi4_master_bk_read_max_burst_length_test.sv
// Author    : Truechip
// Version   : 1.0
// Created   :
//----------------------------------------------------------------------

`ifndef AXI4_MASTER_BK_READ_MAX_BURST_LENGTH_TEST_SV
`define AXI4_MASTER_BK_READ_MAX_BURST_LENGTH_TEST_SV

//----------------------------------------------------------------------
// Class: axi4_master_bk_read_max_burst_length_test
// Description: Test for reading with maximum burst length
//----------------------------------------------------------------------
class axi4_master_bk_read_max_burst_length_test extends axi4_base_test;
  `uvm_component_utils(axi4_master_bk_read_max_burst_length_test)

  //--------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------
  function new(string name = "axi4_master_bk_read_max_burst_length_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //--------------------------------------------------------------------
  // Task: run_phase
  // Description: Run the max burst length read test sequence
  //--------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    axi4_master_bk_read_max_burst_length_seq m_seq;

    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Starting test: axi4_master_bk_read_max_burst_length_test", UVM_LOW)

    // Pre-fill memory region for the read operation if necessary
    // This might involve running a write sequence or using a backdoor write.
    // For this example, we assume the memory region [0x1600 : 0x19FC] has known data.

    // TODO: Implement robust pre-fill for this test.
    // This could involve:
    // 1. Creating a generic write sequence that can be parameterized with address, data, length, etc.
    // 2. Using that generic sequence here to write a known pattern to memory range 0x1600-0x19FC.
    // 3. Alternatively, using a backdoor write mechanism (e.g., env.slave_mem_model.write_burst(...))
    //    if the slave memory model supports it and is accessible from the test.
    // For now, proceeding with the assumption that the memory has a predictable state (e.g., all zeros,
    // or the slave model provides a default pattern for uninitialized reads) that the scoreboard can check against.
    `uvm_info(get_type_name(), "Skipping explicit pre-fill for TC_Boundary_Read_Max_Burst_Length. Scoreboard will verify against actual slave data.", UVM_MEDIUM)

    // Create and start the master read sequence
    m_seq = axi4_master_bk_read_max_burst_length_seq::type_id::create("m_seq");
    // In axi4_master_bk_read_max_burst_length_seq, we should ensure that it expects
    // data that matches what the slave will return (e.g. 32'hDEAD0000 + i if pre-filled).
    // The scoreboard will do the actual comparison.
    assert(m_seq.randomize());
    m_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_read_seqr_h);

    #500ns; // Adjust delay as needed
    phase.drop_objection(this);
    `uvm_info(get_type_name(), "Finished test: axi4_master_bk_read_max_burst_length_test", UVM_LOW)
  endtask : run_phase

endclass : axi4_master_bk_read_max_burst_length_test

`endif // AXI4_MASTER_BK_READ_MAX_BURST_LENGTH_TEST_SV
