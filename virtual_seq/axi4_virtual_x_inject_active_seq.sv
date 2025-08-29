`ifndef AXI4_VIRTUAL_X_INJECT_ACTIVE_SEQ_INCLUDED_
`define AXI4_VIRTUAL_X_INJECT_ACTIVE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_x_inject_awvalid_active_seq
// Virtual sequence for injecting X on AWVALID during active transactions
//--------------------------------------------------------------------------------------------
class axi4_virtual_x_inject_awvalid_active_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_x_inject_awvalid_active_seq)

  axi4_master_x_inject_active_seq master_x_seq;
  axi4_virtual_dummy_slave_seq dummy_slave_seq_h;

  function new(string name = "axi4_virtual_x_inject_awvalid_active_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting AWVALID Active X injection test", UVM_MEDIUM)
    
    // Start dummy slave sequences in background to handle responses
    dummy_slave_seq_h = axi4_virtual_dummy_slave_seq::type_id::create("dummy_slave_seq_h");
    dummy_slave_seq_h.num_dummy_sequences = 100; // Enough for test duration
    fork
      dummy_slave_seq_h.start(p_sequencer);
    join_none
    #10ns; // Let dummy sequences get started
    
    // Create and configure master sequence for AWVALID injection
    master_x_seq = axi4_master_x_inject_active_seq::type_id::create("master_x_seq");
    
    assert(master_x_seq.randomize() with {
      inject_on_awvalid == 1;
      inject_on_awaddr == 0;
      inject_on_wdata == 0;
      inject_on_arvalid == 0;
      inject_on_bready == 0;
      inject_on_rready == 0;
      x_inject_cycles inside {[5:20]};  // Random 5-20 cycles
      num_transactions == 10;
      inject_after_n_txn == 3;
      delay_before_inject inside {[20:50]};
    }) else `uvm_fatal(get_type_name(), "Randomization failed")
    
    // Start X injection sequence
    master_x_seq.start(p_sequencer.axi4_master_write_seqr_h);
    
    #100ns;
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_x_inject_random_seq
// Virtual sequence for random X injection during long tests
//--------------------------------------------------------------------------------------------
class axi4_virtual_x_inject_random_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_x_inject_random_seq)

  axi4_master_x_inject_random_seq master_random_seq;
  axi4_virtual_dummy_slave_seq dummy_slave_seq_h;

  function new(string name = "axi4_virtual_x_inject_random_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting Random X injection test", UVM_MEDIUM)
    
    // Start dummy slave sequences in background to handle responses
    dummy_slave_seq_h = axi4_virtual_dummy_slave_seq::type_id::create("dummy_slave_seq_h");
    dummy_slave_seq_h.num_dummy_sequences = 100; // Enough for test duration
    fork
      dummy_slave_seq_h.start(p_sequencer);
    join_none
    #10ns; // Let dummy sequences get started
    
    // Create and configure random injection sequence
    master_random_seq = axi4_master_x_inject_random_seq::type_id::create("master_random_seq");
    
    assert(master_random_seq.randomize() with {
      test_duration_ns == 20000;  // 20us test
      num_injections == 10;
      min_inject_interval == 200;
      max_inject_interval == 2000;
      x_inject_cycles inside {[2:4]};
    }) else `uvm_fatal(get_type_name(), "Randomization failed")
    
    // Start random X injection sequence
    master_random_seq.start(p_sequencer.axi4_master_write_seqr_h);
    
    #100ns;
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_x_inject_multi_signal_seq
// Virtual sequence for injecting X on multiple signals during active transactions
//--------------------------------------------------------------------------------------------
class axi4_virtual_x_inject_multi_signal_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_x_inject_multi_signal_seq)

  axi4_master_x_inject_active_seq master_x_seq[];
  axi4_virtual_dummy_slave_seq dummy_slave_seq_h;

  function new(string name = "axi4_virtual_x_inject_multi_signal_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting Multi-signal X injection test", UVM_MEDIUM)
    
    // Start dummy slave sequences in background to handle responses
    dummy_slave_seq_h = axi4_virtual_dummy_slave_seq::type_id::create("dummy_slave_seq_h");
    dummy_slave_seq_h.num_dummy_sequences = 100; // Enough for test duration
    fork
      dummy_slave_seq_h.start(p_sequencer);
    join_none
    #10ns; // Let dummy sequences get started
    
    // Create multiple injection sequences for different signals
    master_x_seq = new[3];
    
    // Test 1: AWVALID injection
    master_x_seq[0] = axi4_master_x_inject_active_seq::type_id::create("awvalid_inject");
    assert(master_x_seq[0].randomize() with {
      inject_on_awvalid == 1;
      inject_on_awaddr == 0;
      inject_on_wdata == 0;
      inject_on_arvalid == 0;
      inject_on_bready == 0;
      inject_on_rready == 0;
      x_inject_cycles inside {[5:15]};  // Random 5-15 cycles
      num_transactions == 5;
      inject_after_n_txn == 2;
    }) else `uvm_fatal(get_type_name(), "Randomization failed")
    
    master_x_seq[0].start(p_sequencer.axi4_master_write_seqr_h);
    #200ns;
    
    // Test 2: WDATA injection
    master_x_seq[1] = axi4_master_x_inject_active_seq::type_id::create("wdata_inject");
    assert(master_x_seq[1].randomize() with {
      inject_on_awvalid == 0;
      inject_on_awaddr == 0;
      inject_on_wdata == 1;
      inject_on_arvalid == 0;
      inject_on_bready == 0;
      inject_on_rready == 0;
      x_inject_cycles inside {[5:20]};  // Random 5-20 cycles
      num_transactions == 5;
      inject_after_n_txn == 2;
    }) else `uvm_fatal(get_type_name(), "Randomization failed")
    
    master_x_seq[1].start(p_sequencer.axi4_master_write_seqr_h);
    #200ns;
    
    // Test 3: ARVALID injection
    master_x_seq[2] = axi4_master_x_inject_active_seq::type_id::create("arvalid_inject");
    assert(master_x_seq[2].randomize() with {
      inject_on_awvalid == 0;
      inject_on_awaddr == 0;
      inject_on_wdata == 0;
      inject_on_arvalid == 1;
      inject_on_bready == 0;
      inject_on_rready == 0;
      x_inject_cycles inside {[5:15]};  // Random 5-15 cycles
      num_transactions == 5;
      inject_after_n_txn == 2;
    }) else `uvm_fatal(get_type_name(), "Randomization failed")
    
    master_x_seq[2].start(p_sequencer.axi4_master_read_seqr_h);
    
    #100ns;
    
  endtask
endclass

`endif