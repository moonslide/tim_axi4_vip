`ifndef AXI4_VIRTUAL_ERROR_INJECT_RANDOMIZED_SEQ_INCLUDED_
`define AXI4_VIRTUAL_ERROR_INJECT_RANDOMIZED_SEQ_INCLUDED_

//=============================================================================================
// File: axi4_virtual_error_inject_randomized_seq.sv
// Description: Virtual sequences for randomized X-value injection on AXI4 signals
//
// This file contains virtual sequences that implement the randomized error injection
// logic for various AXI4 signals. These sequences are used by the test cases in
// axi4_error_inject_randomized_tests.sv.
//
// SEQUENCES INCLUDED:
// 1. axi4_virtual_error_inject_awvalid_random_seq
//    - Randomizes and injects X on AWVALID during write address phase
//    - Coordinates with master write sequencer for injection timing
//
// 2. axi4_virtual_error_inject_arvalid_random_seq
//    - Randomizes and injects X on ARVALID during read address phase
//    - Coordinates with master read sequencer for injection timing
//
// 3. axi4_virtual_error_inject_awaddr_random_seq
//    - Randomizes and injects X on AWADDR signal
//    - Targets specific addresses with corruption
//
// 4. axi4_virtual_error_inject_wdata_random_seq
//    - Randomizes and injects X on WDATA during write data phase
//    - Corrupts data values during transfer
//
// 5. axi4_virtual_error_inject_bready_random_seq
//    - Randomizes and injects X on BREADY during write response
//    - Disrupts write response handshaking
//
// 6. axi4_virtual_error_inject_rready_random_seq
//    - Randomizes and injects X on RREADY during read response
//    - Disrupts read response handshaking
//
// 7. axi4_virtual_error_inject_all_signals_random_seq
//    - Randomly selects which signal to corrupt
//    - Uses signal mask to enable/disable specific signals
//
// RANDOMIZATION PARAMETERS:
// - num_x_injections: Number of injection events (1-10)
// - x_inject_cycles[]: Duration of each injection (5-20 cycles)
// - delays_between[]: Delay between injections (50-500ns)
// - target_addrs[]: Target addresses for injections (4KB aligned)
// - num_normal_txn_between[]: Normal transactions between injections (1-5)
//
// INJECTION PHASES:
// - PHASE_AW: Write address phase
// - PHASE_AR: Read address phase
// - PHASE_W: Write data phase
// - PHASE_B: Write response phase
// - PHASE_R: Read response phase
//
// INJECTION SIGNALS:
// - SIGNAL_VALID: Valid signals (AWVALID, ARVALID)
// - SIGNAL_ADDR: Address signals (AWADDR, ARADDR)
// - SIGNAL_DATA: Data signals (WDATA, RDATA)
// - SIGNAL_READY: Ready signals (BREADY, RREADY)
//=============================================================================================

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_awvalid_random_seq
// Randomized version of AWVALID X injection
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_awvalid_random_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_awvalid_random_seq)

  axi4_master_bk_write_constrained_seq axi4_master_bk_write_seq_h;
  
  // Randomization parameters for multiple injections
  rand int unsigned num_x_injections;      // Number of times to inject X
  rand int unsigned x_inject_cycles[];     // Cycles for each injection
  rand int unsigned delays_between[];      // Delays between injections
  rand bit [63:0] target_addrs[];         // Target address for each injection
  rand int unsigned num_normal_txn_between[];  // Normal transactions between injections
  
  constraint c_randomize {
    num_x_injections inside {[1:10]};  // 1-10 X injection events
    
    x_inject_cycles.size() == num_x_injections;
    delays_between.size() == num_x_injections;
    target_addrs.size() == num_x_injections;
    num_normal_txn_between.size() == num_x_injections;
    
    foreach(x_inject_cycles[i]) {
      x_inject_cycles[i] inside {[5:20]};  // 5-20 cycles per injection
    }
    
    foreach(delays_between[i]) {
      delays_between[i] inside {[50:500]};  // 50-500ns between injections
    }
    
    foreach(target_addrs[i]) {
      target_addrs[i][11:0] == 0;  // 4KB aligned
      // Use valid slave address ranges
      (target_addrs[i] inside {[64'h0000_0008_0000_0000:64'h0000_0008_BFFF_FFFF]}) ||
      (target_addrs[i] inside {[64'h0000_000A_0000_0000:64'h0000_000A_0004_FFFF]});
    }
    
    foreach(num_normal_txn_between[i]) {
      num_normal_txn_between[i] inside {[1:5]};  // 1-5 normal transactions
    }
  }

  function new(string name = "axi4_virtual_error_inject_awvalid_random_seq");
    super.new(name);
  endfunction

  task body();
    axi4_slave_bk_write_seq axi4_slave_bk_write_seq_h;
    axi4_virtual_dummy_slave_seq dummy_slave_seq_h;
    process timeout_process;
    
    super.body();
    
    `uvm_info(get_type_name(), "Starting Randomized AWVALID X injection test", UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Number of X injections: %0d", num_x_injections), UVM_MEDIUM)
    
    // Create sequences
    axi4_master_bk_write_seq_h = axi4_master_bk_write_constrained_seq::type_id::create("axi4_master_bk_write_seq_h");
    axi4_slave_bk_write_seq_h = axi4_slave_bk_write_seq::type_id::create("axi4_slave_bk_write_seq_h");
    
    // Start dummy slave sequence to handle responses during X injection
    dummy_slave_seq_h = axi4_virtual_dummy_slave_seq::type_id::create("dummy_slave_seq_h");
    dummy_slave_seq_h.num_dummy_sequences = 100; // Enough for entire test
    fork
      dummy_slave_seq_h.start(p_sequencer);
    join_none
    
    // Add overall timeout for the sequence - increased for error injection scenarios
    fork
      begin : timeout_block
        #100ms;  // 100ms timeout for entire sequence (increased from 10ms for error injection)
        `uvm_error(get_type_name(), "Sequence timeout - test taking too long")
      end : timeout_block
      
      begin : main_sequence
    
    // Perform multiple X injections
    for(int inj = 0; inj < num_x_injections; inj++) begin
      `uvm_info(get_type_name(), $sformatf("X Injection %0d/%0d: cycles=%0d, delay=%0dns, addr=0x%h", 
                inj+1, num_x_injections, x_inject_cycles[inj], 
                delays_between[inj], target_addrs[inj]), UVM_MEDIUM)
      
      // Run normal transactions between injections with timeout protection
      for(int i = 0; i < num_normal_txn_between[inj]; i++) begin
        axi4_master_bk_write_constrained_seq write_seq_tmp;
        write_seq_tmp = axi4_master_bk_write_constrained_seq::type_id::create($sformatf("write_seq_%0d_%0d", inj, i));
        
        // Start sequence with timeout protection
        fork
          begin
            write_seq_tmp.start(p_sequencer.axi4_master_write_seqr_h);
          end
          begin
            #5us;  // 5us timeout per normal transaction
            `uvm_warning(get_type_name(), "Normal transaction timeout - continuing with test")
          end
        join_any
        disable fork;
        
        #($urandom_range(10, 50) * 1ns);
      end
      
      // Random delay before this injection
      #(delays_between[inj] * 1ns);
      
      // Inject X directly using config_db - don't go through sequencer
      `uvm_info(get_type_name(), $sformatf("Injecting X on AWVALID for %0d cycles", x_inject_cycles[inj]), UVM_MEDIUM)
      
      // Set X injection mode in config_db for monitor to pick up
      uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 1);
      uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles[inj]);
      
      // Wait for the injection to complete
      #(x_inject_cycles[inj] * 10ns);
      
      // Clear X injection mode
      uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 0);
      
      // Wait for stabilization
      #(50ns);
      
      // Small recovery time after injection
      #($urandom_range(20, 100) * 1ns);
    end
    
    // Final recovery transactions
    repeat(3) begin
      axi4_master_bk_write_constrained_seq recovery_seq;
      recovery_seq = axi4_master_bk_write_constrained_seq::type_id::create("recovery_seq");
      recovery_seq.start(p_sequencer.axi4_master_write_seqr_h);
      #50ns;
    end
    
    end : main_sequence
    join_any
    disable fork;  // Kill the timeout if sequence completes
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_arvalid_random_seq
// Randomized version of ARVALID X injection
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_arvalid_random_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_arvalid_random_seq)

  axi4_master_x_inject_seq master_x_seq;
  axi4_master_bk_read_constrained_seq axi4_master_bk_read_seq_h;
  axi4_virtual_dummy_slave_seq dummy_slave_seq_h;
  
  // Randomization parameters for multiple injections
  rand int unsigned num_x_injections;      // Number of times to inject X
  rand int unsigned x_inject_cycles[];     // Cycles for each injection
  rand int unsigned delays_between[];      // Delays between injections
  rand bit [63:0] target_addrs[];         // Target address for each injection
  rand int unsigned num_normal_txn_between[];  // Normal transactions between injections
  
  constraint c_randomize {
    num_x_injections inside {[1:10]};  // 1-10 X injection events
    
    x_inject_cycles.size() == num_x_injections;
    delays_between.size() == num_x_injections;
    target_addrs.size() == num_x_injections;
    num_normal_txn_between.size() == num_x_injections;
    
    foreach(x_inject_cycles[i]) {
      x_inject_cycles[i] inside {[5:20]};  // 5-20 cycles per injection
    }
    
    foreach(delays_between[i]) {
      delays_between[i] inside {[50:500]};  // 50-500ns between injections
    }
    
    foreach(target_addrs[i]) {
      target_addrs[i][11:0] == 0;  // 4KB aligned
      // Use valid slave address ranges
      (target_addrs[i] inside {[64'h0000_0008_0000_0000:64'h0000_0008_BFFF_FFFF]}) ||
      (target_addrs[i] inside {[64'h0000_000A_0000_0000:64'h0000_000A_0004_FFFF]});
    }
    
    foreach(num_normal_txn_between[i]) {
      num_normal_txn_between[i] inside {[1:5]};  // 1-5 normal transactions
    }
  }

  function new(string name = "axi4_virtual_error_inject_arvalid_random_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting Randomized ARVALID X injection test", UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Number of X injections: %0d", num_x_injections), UVM_MEDIUM)
    // Start dummy slave sequence to handle responses during X injection
    dummy_slave_seq_h = axi4_virtual_dummy_slave_seq::type_id::create("dummy_slave_seq_h");
    dummy_slave_seq_h.num_dummy_sequences = 100;
    fork
      dummy_slave_seq_h.start(p_sequencer);
    join_none

    
    // Create sequences
    axi4_master_bk_read_seq_h = axi4_master_bk_read_constrained_seq::type_id::create("axi4_master_bk_read_seq_h");
    
    // Perform multiple X injections
    for(int inj = 0; inj < num_x_injections; inj++) begin
      `uvm_info(get_type_name(), $sformatf("X Injection %0d/%0d: cycles=%0d, delay=%0dns, addr=0x%h", 
                inj+1, num_x_injections, x_inject_cycles[inj], 
                delays_between[inj], target_addrs[inj]), UVM_MEDIUM)
      
      // Run normal transactions between injections
      for(int i = 0; i < num_normal_txn_between[inj]; i++) begin
        axi4_master_bk_read_constrained_seq read_seq_tmp;
        read_seq_tmp = axi4_master_bk_read_constrained_seq::type_id::create($sformatf("read_seq_%0d_%0d", inj, i));
        read_seq_tmp.start(p_sequencer.axi4_master_read_seqr_h);
        #($urandom_range(10, 50) * 1ns);
      end
      
      // Random delay before this injection
      #(delays_between[inj] * 1ns);
      
      // Create and configure X injection for this iteration
      master_x_seq = axi4_master_x_inject_seq::type_id::create($sformatf("master_x_seq_%0d", inj));
      master_x_seq.inject_phase = axi4_master_x_inject_seq::PHASE_AR;
      master_x_seq.inject_signal = axi4_master_x_inject_seq::SIGNAL_VALID;
      master_x_seq.x_inject_cycles = x_inject_cycles[inj];
      master_x_seq.target_addr = target_addrs[inj];
      
      // Start X injection sequence
      master_x_seq.start(p_sequencer.axi4_master_read_seqr_h);
      
      // Small recovery time after injection
      #($urandom_range(20, 100) * 1ns);
    end
    
    // Final recovery transactions
    repeat(3) begin
      axi4_master_bk_read_constrained_seq recovery_seq;
      recovery_seq = axi4_master_bk_read_constrained_seq::type_id::create("recovery_seq");
      recovery_seq.start(p_sequencer.axi4_master_read_seqr_h);
      #50ns;
    end
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_awaddr_random_seq
// Randomized version of AWADDR X injection
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_awaddr_random_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_awaddr_random_seq)

  axi4_master_x_inject_seq master_x_seq;
  axi4_virtual_dummy_slave_seq dummy_slave_seq_h;
  axi4_master_bk_write_constrained_seq axi4_master_bk_write_seq_h;
  
  // Randomization parameters for multiple injections
  rand int unsigned num_x_injections;      // Number of times to inject X
  rand int unsigned x_inject_cycles[];     // Cycles for each injection
  rand int unsigned delays_between[];      // Delays between injections
  rand bit [63:0] target_addrs[];         // Target address for each injection
  rand int unsigned num_normal_txn_between[];  // Normal transactions between injections
  
  constraint c_randomize {
    num_x_injections inside {[1:10]};  // 1-10 X injection events
    
    x_inject_cycles.size() == num_x_injections;
    delays_between.size() == num_x_injections;
    target_addrs.size() == num_x_injections;
    num_normal_txn_between.size() == num_x_injections;
    
    foreach(x_inject_cycles[i]) {
      x_inject_cycles[i] inside {[5:20]};  // 5-20 cycles per injection
    }
    
    foreach(delays_between[i]) {
      delays_between[i] inside {[50:500]};  // 50-500ns between injections
    }
    
    foreach(target_addrs[i]) {
      target_addrs[i][11:0] == 0;  // 4KB aligned
      // Use valid slave address ranges
      (target_addrs[i] inside {[64'h0000_0008_0000_0000:64'h0000_0008_BFFF_FFFF]}) ||
      (target_addrs[i] inside {[64'h0000_000A_0000_0000:64'h0000_000A_0004_FFFF]});
    }
    
    foreach(num_normal_txn_between[i]) {
      num_normal_txn_between[i] inside {[1:5]};  // 1-5 normal transactions
    }
  }

  function new(string name = "axi4_virtual_error_inject_awaddr_random_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting Randomized AWADDR X injection test", UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Number of X injections: %0d", num_x_injections), UVM_MEDIUM)
    
    // Create sequences
    axi4_master_bk_write_seq_h = axi4_master_bk_write_constrained_seq::type_id::create("axi4_master_bk_write_seq_h");
    
    // Perform multiple X injections
    
    // Start dummy slave sequence to handle responses during X injection
    dummy_slave_seq_h = axi4_virtual_dummy_slave_seq::type_id::create("dummy_slave_seq_h");
    dummy_slave_seq_h.num_dummy_sequences = 100;
    fork
      dummy_slave_seq_h.start(p_sequencer);
    join_none

    for(int inj = 0; inj < num_x_injections; inj++) begin
      `uvm_info(get_type_name(), $sformatf("X Injection %0d/%0d: cycles=%0d, delay=%0dns, addr=0x%h", 
                inj+1, num_x_injections, x_inject_cycles[inj], 
                delays_between[inj], target_addrs[inj]), UVM_MEDIUM)
      
      // Run normal transactions between injections with timeout protection
      for(int i = 0; i < num_normal_txn_between[inj]; i++) begin
        axi4_master_bk_write_constrained_seq write_seq_tmp;
        write_seq_tmp = axi4_master_bk_write_constrained_seq::type_id::create($sformatf("write_seq_%0d_%0d", inj, i));
        
        // Start sequence with timeout protection
        fork
          begin
            write_seq_tmp.start(p_sequencer.axi4_master_write_seqr_h);
          end
          begin
            #5us;  // 5us timeout per normal transaction
            `uvm_warning(get_type_name(), "Normal transaction timeout - continuing with test")
          end
        join_any
        disable fork;
        
        #($urandom_range(10, 50) * 1ns);
      end
      
      // Random delay before this injection
      #(delays_between[inj] * 1ns);
      
      // Create and configure X injection for this iteration
      master_x_seq = axi4_master_x_inject_seq::type_id::create($sformatf("master_x_seq_%0d", inj));
      master_x_seq.inject_phase = axi4_master_x_inject_seq::PHASE_AW;
      master_x_seq.inject_signal = axi4_master_x_inject_seq::SIGNAL_ADDR;
      master_x_seq.x_inject_cycles = x_inject_cycles[inj];
      master_x_seq.target_addr = target_addrs[inj];
      
      // Start X injection sequence
      master_x_seq.start(p_sequencer.axi4_master_write_seqr_h);
      
      // Small recovery time after injection
      #($urandom_range(20, 100) * 1ns);
    end
    
    // Final recovery transactions
    repeat(3) begin
      axi4_master_bk_write_constrained_seq recovery_seq;
      recovery_seq = axi4_master_bk_write_constrained_seq::type_id::create("recovery_seq");
      recovery_seq.start(p_sequencer.axi4_master_write_seqr_h);
      #50ns;
    end
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_wdata_random_seq
// Randomized version of WDATA X injection
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_wdata_random_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_wdata_random_seq)

  axi4_master_x_inject_seq master_x_seq;
  axi4_virtual_dummy_slave_seq dummy_slave_seq_h;
  axi4_master_bk_write_constrained_seq axi4_master_bk_write_seq_h;
  
  // Randomization parameters for multiple injections
  rand int unsigned num_x_injections;      // Number of times to inject X
  rand int unsigned x_inject_cycles[];     // Cycles for each injection
  rand int unsigned delays_between[];      // Delays between injections
  rand bit [63:0] target_addrs[];         // Target address for each injection
  rand int unsigned num_normal_txn_between[];  // Normal transactions between injections
  
  constraint c_randomize {
    num_x_injections inside {[1:10]};  // 1-10 X injection events
    
    x_inject_cycles.size() == num_x_injections;
    delays_between.size() == num_x_injections;
    target_addrs.size() == num_x_injections;
    num_normal_txn_between.size() == num_x_injections;
    
    foreach(x_inject_cycles[i]) {
      x_inject_cycles[i] inside {[5:20]};  // 5-20 cycles per injection
    }
    
    foreach(delays_between[i]) {
      delays_between[i] inside {[50:500]};  // 50-500ns between injections
    }
    
    foreach(target_addrs[i]) {
      target_addrs[i][11:0] == 0;  // 4KB aligned
      // Use valid slave address ranges
      (target_addrs[i] inside {[64'h0000_0008_0000_0000:64'h0000_0008_BFFF_FFFF]}) ||
      (target_addrs[i] inside {[64'h0000_000A_0000_0000:64'h0000_000A_0004_FFFF]});
    }
    
    foreach(num_normal_txn_between[i]) {
      num_normal_txn_between[i] inside {[1:5]};  // 1-5 normal transactions
    }
  }

  function new(string name = "axi4_virtual_error_inject_wdata_random_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    // Start dummy slave sequence to handle responses during X injection
    dummy_slave_seq_h = axi4_virtual_dummy_slave_seq::type_id::create("dummy_slave_seq_h");
    dummy_slave_seq_h.num_dummy_sequences = 100;
    fork
      dummy_slave_seq_h.start(p_sequencer);
    join_none

    
    `uvm_info(get_type_name(), "Starting Randomized WDATA X injection test", UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Number of X injections: %0d", num_x_injections), UVM_MEDIUM)
    
    // Create sequences
    axi4_master_bk_write_seq_h = axi4_master_bk_write_constrained_seq::type_id::create("axi4_master_bk_write_seq_h");
    
    // Perform multiple X injections
    for(int inj = 0; inj < num_x_injections; inj++) begin
      `uvm_info(get_type_name(), $sformatf("X Injection %0d/%0d: cycles=%0d, delay=%0dns, addr=0x%h", 
                inj+1, num_x_injections, x_inject_cycles[inj], 
                delays_between[inj], target_addrs[inj]), UVM_MEDIUM)
      
      // Run normal transactions between injections with timeout protection
      for(int i = 0; i < num_normal_txn_between[inj]; i++) begin
        axi4_master_bk_write_constrained_seq write_seq_tmp;
        write_seq_tmp = axi4_master_bk_write_constrained_seq::type_id::create($sformatf("write_seq_%0d_%0d", inj, i));
        
        // Start sequence with timeout protection
        fork
          begin
            write_seq_tmp.start(p_sequencer.axi4_master_write_seqr_h);
          end
          begin
            #5us;  // 5us timeout per normal transaction
            `uvm_warning(get_type_name(), "Normal transaction timeout - continuing with test")
          end
        join_any
        disable fork;
        
        #($urandom_range(10, 50) * 1ns);
      end
      
      // Random delay before this injection
      #(delays_between[inj] * 1ns);
      
      // Create and configure X injection for this iteration
      master_x_seq = axi4_master_x_inject_seq::type_id::create($sformatf("master_x_seq_%0d", inj));
      master_x_seq.inject_phase = axi4_master_x_inject_seq::PHASE_W;
      master_x_seq.inject_signal = axi4_master_x_inject_seq::SIGNAL_DATA;
      master_x_seq.x_inject_cycles = x_inject_cycles[inj];
      master_x_seq.target_addr = target_addrs[inj];
      
      // Start X injection sequence
      master_x_seq.start(p_sequencer.axi4_master_write_seqr_h);
      
      // Small recovery time after injection
      #($urandom_range(20, 100) * 1ns);
    end
    
    // Final recovery transactions
    repeat(3) begin
      axi4_master_bk_write_constrained_seq recovery_seq;
      recovery_seq = axi4_master_bk_write_constrained_seq::type_id::create("recovery_seq");
      recovery_seq.start(p_sequencer.axi4_master_write_seqr_h);
      #50ns;
    end
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_bready_random_seq
// Randomized version of BREADY X injection
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_bready_random_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_bready_random_seq)

  axi4_master_x_inject_seq master_x_seq;
  axi4_virtual_dummy_slave_seq dummy_slave_seq_h;
  axi4_master_bk_write_constrained_seq axi4_master_bk_write_seq_h;
  
  // Randomization parameters for multiple injections
  rand int unsigned num_x_injections;      // Number of times to inject X
  rand int unsigned x_inject_cycles[];     // Cycles for each injection
  rand int unsigned delays_between[];      // Delays between injections
  rand bit [63:0] target_addrs[];         // Target address for each injection
  rand int unsigned num_normal_txn_between[];  // Normal transactions between injections
  
  constraint c_randomize {
    num_x_injections inside {[1:10]};  // 1-10 X injection events
    
    x_inject_cycles.size() == num_x_injections;
    delays_between.size() == num_x_injections;
    target_addrs.size() == num_x_injections;
    num_normal_txn_between.size() == num_x_injections;
    
    foreach(x_inject_cycles[i]) {
      x_inject_cycles[i] inside {[5:20]};  // 5-20 cycles per injection
    }
    
    foreach(delays_between[i]) {
      delays_between[i] inside {[50:500]};  // 50-500ns between injections
    }
    
    foreach(target_addrs[i]) {
      target_addrs[i][11:0] == 0;  // 4KB aligned
      // Use valid slave address ranges
      (target_addrs[i] inside {[64'h0000_0008_0000_0000:64'h0000_0008_BFFF_FFFF]}) ||
      (target_addrs[i] inside {[64'h0000_000A_0000_0000:64'h0000_000A_0004_FFFF]});
    }
    
    foreach(num_normal_txn_between[i]) {
      num_normal_txn_between[i] inside {[1:5]};  // 1-5 normal transactions
    }
  }

  function new(string name = "axi4_virtual_error_inject_bready_random_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting Randomized BREADY X injection test", UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Number of X injections: %0d", num_x_injections), UVM_MEDIUM)
    
    // Start dummy slave sequence to handle responses during X injection
    dummy_slave_seq_h = axi4_virtual_dummy_slave_seq::type_id::create("dummy_slave_seq_h");
    dummy_slave_seq_h.num_dummy_sequences = 100;
    fork
      dummy_slave_seq_h.start(p_sequencer);
    join_none
    
    // Create sequences
    axi4_master_bk_write_seq_h = axi4_master_bk_write_constrained_seq::type_id::create("axi4_master_bk_write_seq_h");
    
    // Perform multiple X injections
    for(int inj = 0; inj < num_x_injections; inj++) begin
      `uvm_info(get_type_name(), $sformatf("X Injection %0d/%0d: cycles=%0d, delay=%0dns, addr=0x%h", 
                inj+1, num_x_injections, x_inject_cycles[inj], 
                delays_between[inj], target_addrs[inj]), UVM_MEDIUM)
      
      // Run normal transactions between injections with timeout protection
      for(int i = 0; i < num_normal_txn_between[inj]; i++) begin
        axi4_master_bk_write_constrained_seq write_seq_tmp;
        write_seq_tmp = axi4_master_bk_write_constrained_seq::type_id::create($sformatf("write_seq_%0d_%0d", inj, i));
        
        // Start sequence with timeout protection
        fork
          begin
            write_seq_tmp.start(p_sequencer.axi4_master_write_seqr_h);
          end
          begin
            #5us;  // 5us timeout per normal transaction
            `uvm_warning(get_type_name(), "Normal transaction timeout - continuing with test")
          end
        join_any
        disable fork;
        
        #($urandom_range(10, 50) * 1ns);
      end
      
      // Random delay before this injection
      #(delays_between[inj] * 1ns);
      
      // Create and configure X injection for this iteration
      master_x_seq = axi4_master_x_inject_seq::type_id::create($sformatf("master_x_seq_%0d", inj));
      master_x_seq.inject_phase = axi4_master_x_inject_seq::PHASE_B;
      master_x_seq.inject_signal = axi4_master_x_inject_seq::SIGNAL_READY;
      master_x_seq.x_inject_cycles = x_inject_cycles[inj];
      master_x_seq.target_addr = target_addrs[inj];
      
      // Start X injection sequence
      master_x_seq.start(p_sequencer.axi4_master_write_seqr_h);
      
      // Small recovery time after injection
      #($urandom_range(20, 100) * 1ns);
    end
    
    // Final recovery transactions
    repeat(3) begin
      axi4_master_bk_write_constrained_seq recovery_seq;
      recovery_seq = axi4_master_bk_write_constrained_seq::type_id::create("recovery_seq");
      recovery_seq.start(p_sequencer.axi4_master_write_seqr_h);
      #50ns;
    end
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_rready_random_seq
// Randomized version of RREADY X injection
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_rready_random_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_rready_random_seq)

  axi4_master_x_inject_seq master_x_seq;
  axi4_virtual_dummy_slave_seq dummy_slave_seq_h;
  axi4_master_bk_read_constrained_seq axi4_master_bk_read_seq_h;
  
  // Randomization parameters for multiple injections
  rand int unsigned num_x_injections;      // Number of times to inject X
  rand int unsigned x_inject_cycles[];     // Cycles for each injection
  rand int unsigned delays_between[];      // Delays between injections
  rand bit [63:0] target_addrs[];         // Target address for each injection
  rand int unsigned num_normal_txn_between[];  // Normal transactions between injections
  
  constraint c_randomize {
    num_x_injections inside {[1:10]};  // 1-10 X injection events
    
    x_inject_cycles.size() == num_x_injections;
    delays_between.size() == num_x_injections;
    target_addrs.size() == num_x_injections;
    num_normal_txn_between.size() == num_x_injections;
    
    foreach(x_inject_cycles[i]) {
      x_inject_cycles[i] inside {[5:20]};  // 5-20 cycles per injection
    }
    
    foreach(delays_between[i]) {
      delays_between[i] inside {[50:500]};  // 50-500ns between injections
    }
    
    foreach(target_addrs[i]) {
      target_addrs[i][11:0] == 0;  // 4KB aligned
      // Use valid slave address ranges
      (target_addrs[i] inside {[64'h0000_0008_0000_0000:64'h0000_0008_BFFF_FFFF]}) ||
      (target_addrs[i] inside {[64'h0000_000A_0000_0000:64'h0000_000A_0004_FFFF]});
    }
    
    foreach(num_normal_txn_between[i]) {
      num_normal_txn_between[i] inside {[1:5]};  // 1-5 normal transactions
    }
  }

  function new(string name = "axi4_virtual_error_inject_rready_random_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting Randomized RREADY X injection test", UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Number of X injections: %0d", num_x_injections), UVM_MEDIUM)
    
    // Start dummy slave sequence to handle responses during X injection
    dummy_slave_seq_h = axi4_virtual_dummy_slave_seq::type_id::create("dummy_slave_seq_h");
    dummy_slave_seq_h.num_dummy_sequences = 100;
    fork
      dummy_slave_seq_h.start(p_sequencer);
    join_none
    
    // Create sequences
    axi4_master_bk_read_seq_h = axi4_master_bk_read_constrained_seq::type_id::create("axi4_master_bk_read_seq_h");
    
    // Perform multiple X injections
    for(int inj = 0; inj < num_x_injections; inj++) begin
      `uvm_info(get_type_name(), $sformatf("X Injection %0d/%0d: cycles=%0d, delay=%0dns, addr=0x%h", 
                inj+1, num_x_injections, x_inject_cycles[inj], 
                delays_between[inj], target_addrs[inj]), UVM_MEDIUM)
      
      // Run normal transactions between injections
      for(int i = 0; i < num_normal_txn_between[inj]; i++) begin
        axi4_master_bk_read_constrained_seq read_seq_tmp;
        read_seq_tmp = axi4_master_bk_read_constrained_seq::type_id::create($sformatf("read_seq_%0d_%0d", inj, i));
        read_seq_tmp.start(p_sequencer.axi4_master_read_seqr_h);
        #($urandom_range(10, 50) * 1ns);
      end
      
      // Random delay before this injection
      #(delays_between[inj] * 1ns);
      
      // Create and configure X injection for this iteration
      master_x_seq = axi4_master_x_inject_seq::type_id::create($sformatf("master_x_seq_%0d", inj));
      master_x_seq.inject_phase = axi4_master_x_inject_seq::PHASE_R;
      master_x_seq.inject_signal = axi4_master_x_inject_seq::SIGNAL_READY;
      master_x_seq.x_inject_cycles = x_inject_cycles[inj];
      master_x_seq.target_addr = target_addrs[inj];
      
      // Start X injection sequence
      master_x_seq.start(p_sequencer.axi4_master_read_seqr_h);
      
      // Small recovery time after injection
      #($urandom_range(20, 100) * 1ns);
    end
    
    // Final recovery transactions
    repeat(3) begin
      axi4_master_bk_read_constrained_seq recovery_seq;
      recovery_seq = axi4_master_bk_read_constrained_seq::type_id::create("recovery_seq");
      recovery_seq.start(p_sequencer.axi4_master_read_seqr_h);
      #50ns;
    end
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_all_signals_random_seq
// Randomly inject X on different signals
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_all_signals_random_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_all_signals_random_seq)

  axi4_virtual_dummy_slave_seq dummy_slave_seq_h;
  axi4_master_bk_write_constrained_seq write_seq_h;
  axi4_master_bk_read_constrained_seq read_seq_h;
  
  // Randomization parameters
  rand int unsigned num_injections;
  rand bit [5:0] signal_mask; // Which signals to inject on
  
  constraint c_randomize {
    num_injections inside {[3:10]};
    signal_mask != 0; // At least one signal
  }

  function new(string name = "axi4_virtual_error_inject_all_signals_random_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting Multi-signal Random X injection test", UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Number of injections: %0d", num_injections), UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Signal mask: 0x%0h", signal_mask), UVM_MEDIUM)
    
    // Start dummy slave sequence to handle responses during X injection
    dummy_slave_seq_h = axi4_virtual_dummy_slave_seq::type_id::create("dummy_slave_seq_h");
    dummy_slave_seq_h.num_dummy_sequences = 150;
    fork
      dummy_slave_seq_h.start(p_sequencer);
    join_none
    
    write_seq_h = axi4_master_bk_write_constrained_seq::type_id::create("write_seq");
    read_seq_h = axi4_master_bk_read_constrained_seq::type_id::create("read_seq");
    
    for(int inj = 0; inj < num_injections; inj++) begin
      int signal_sel;
      
      // Select a random signal from enabled ones
      do begin
        signal_sel = $urandom_range(0, 5);
      end while (!signal_mask[signal_sel]);
      
      `uvm_info(get_type_name(), $sformatf("Injection %0d: Signal %0d", inj, signal_sel), UVM_MEDIUM)
      
      // Inject X directly using config_db - don't go through sequencer
      begin
        int cycles = $urandom_range(5, 20);
        
        case(signal_sel)
        0: begin // AWVALID
          `uvm_info(get_type_name(), $sformatf("Injecting X on AWVALID for %0d cycles", cycles), UVM_MEDIUM)
          uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 1);
          uvm_config_db#(int)::set(null, "*", "x_inject_cycles", cycles);
          #(cycles * 10ns);
          uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 0);
        end
        
        1: begin // AWADDR
          `uvm_info(get_type_name(), $sformatf("Injecting X on AWADDR for %0d cycles", cycles), UVM_MEDIUM)
          uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 1);
          uvm_config_db#(int)::set(null, "*", "x_inject_cycles", cycles);
          #(cycles * 10ns);
          uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 0);
        end
        
        2: begin // WDATA
          `uvm_info(get_type_name(), $sformatf("Injecting X on WDATA for %0d cycles", cycles), UVM_MEDIUM)
          uvm_config_db#(bit)::set(null, "*", "x_inject_wdata", 1);
          uvm_config_db#(int)::set(null, "*", "x_inject_cycles", cycles);
          #(cycles * 10ns);
          uvm_config_db#(bit)::set(null, "*", "x_inject_wdata", 0);
        end
        
        3: begin // ARVALID
          `uvm_info(get_type_name(), $sformatf("Injecting X on ARVALID for %0d cycles", cycles), UVM_MEDIUM)
          uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid", 1);
          uvm_config_db#(int)::set(null, "*", "x_inject_cycles", cycles);
          #(cycles * 10ns);
          uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid", 0);
        end
        
        4: begin // BREADY
          `uvm_info(get_type_name(), $sformatf("Injecting X on BREADY for %0d cycles", cycles), UVM_MEDIUM)
          uvm_config_db#(bit)::set(null, "*", "x_inject_bready", 1);
          uvm_config_db#(int)::set(null, "*", "x_inject_cycles", cycles);
          #(cycles * 10ns);
          uvm_config_db#(bit)::set(null, "*", "x_inject_bready", 0);
        end
        
        5: begin // RREADY
          `uvm_info(get_type_name(), $sformatf("Injecting X on RREADY for %0d cycles", cycles), UVM_MEDIUM)
          uvm_config_db#(bit)::set(null, "*", "x_inject_rready", 1);
          uvm_config_db#(int)::set(null, "*", "x_inject_cycles", cycles);
          #(cycles * 10ns);
          uvm_config_db#(bit)::set(null, "*", "x_inject_rready", 0);
        end
        endcase
        
        // Wait for stabilization
        #(50ns);
      end
      
      // Random delay between injections
      #($urandom_range(100, 500) * 1ns);
      
      // Run some normal transactions
      repeat($urandom_range(1, 3)) begin
        if($urandom_range(0, 1)) begin
          write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
        end else begin
          read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
        end
        #($urandom_range(10, 50) * 1ns);
      end
    end
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_adaptive_random_seq
// Adaptive random injection based on bus activity
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_adaptive_random_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_adaptive_random_seq)

  axi4_master_x_inject_random_seq random_seq;
  axi4_slave_base_seq slave_seq_h[];
  
  // Parameters
  rand int unsigned test_duration_ns;
  rand int unsigned injection_rate; // Percentage of time to inject
  
  constraint c_randomize {
    test_duration_ns inside {[1000:3000]}; // 1-3 us (reduced for faster testing)
    injection_rate inside {[5:30]}; // 5-30% injection rate
  }

  function new(string name = "axi4_virtual_error_inject_adaptive_random_seq");
    super.new(name);
  endfunction

  task body();
    axi4_virtual_dummy_slave_seq dummy_slave_seq_h;
    axi4_master_bk_write_constrained_seq write_seq;
    
    super.body();
    
    `uvm_info(get_type_name(), "Starting Adaptive Random X injection test", UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Test duration: %0d ns", test_duration_ns), UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Injection rate: %0d%%", injection_rate), UVM_MEDIUM)
    
    // Start dummy slave sequences to handle responses
    dummy_slave_seq_h = axi4_virtual_dummy_slave_seq::type_id::create("dummy_slave_seq_h");
    dummy_slave_seq_h.num_dummy_sequences = 200; // Enough for adaptive test
    fork
      dummy_slave_seq_h.start(p_sequencer);
    join_none
    
    // Generate normal write traffic in background
    write_seq = axi4_master_bk_write_constrained_seq::type_id::create("write_seq");
    fork
      repeat(20) begin
        write_seq.start(p_sequencer.axi4_master_write_seqr_h);
        #($urandom_range(50, 200));
      end
    join_none
    
    // Adaptive X injection based on bus activity
    fork
      begin
        time end_time = $time + (test_duration_ns * 1ns);
        while($time < end_time) begin
          if($urandom_range(1, 100) <= injection_rate) begin
            // Inject X
            axi4_master_x_inject_seq x_seq;
            x_seq = axi4_master_x_inject_seq::type_id::create("x_seq");
            x_seq.inject_phase = axi4_master_x_inject_seq::inject_phase_e'($urandom_range(0, 2)); // AW, AR, or W
            x_seq.inject_signal = axi4_master_x_inject_seq::SIGNAL_VALID;
            x_seq.x_inject_cycles = $urandom_range(5, 20);
            
            fork
              begin
                fork
                  x_seq.start(p_sequencer.axi4_master_write_seqr_h);
                join_any
                disable fork;
              end
            join_none
            
            #((x_seq.x_inject_cycles * 10) + 50);
          end else begin
            // Normal operation
            #($urandom_range(100, 300));
          end
        end
      end
    join
    
    #100ns;
    
  endtask
endclass

`endif