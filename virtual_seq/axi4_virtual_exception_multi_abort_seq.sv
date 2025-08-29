`ifndef AXI4_VIRTUAL_EXCEPTION_MULTI_ABORT_SEQ_INCLUDED_
`define AXI4_VIRTUAL_EXCEPTION_MULTI_ABORT_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_exception_multi_abort_seq
// Virtual sequence for multiple random abort events
//--------------------------------------------------------------------------------------------
class axi4_virtual_exception_multi_abort_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_exception_multi_abort_seq)

  axi4_master_exception_multi_abort_seq master_abort_seq;
  axi4_master_bk_write_seq write_seq;
  axi4_master_bk_read_seq read_seq;
  
  // Randomization parameters
  rand int unsigned num_abort_sequences;  // Number of abort sequences to run
  rand int unsigned delays_between_sequences[];
  
  constraint c_sequences {
    num_abort_sequences inside {[1:5]};  // 1-5 abort sequences
    delays_between_sequences.size() == num_abort_sequences;
    
    foreach(delays_between_sequences[i]) {
      delays_between_sequences[i] inside {[200:1000]};
    }
  }

  function new(string name = "axi4_virtual_exception_multi_abort_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting Multi-Abort Exception test", UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Number of abort sequences: %0d", num_abort_sequences), UVM_MEDIUM)
    
    // Start background traffic
    fork
      generate_background_traffic();
    join_none
    
    // Run multiple abort sequences
    for(int seq = 0; seq < num_abort_sequences; seq++) begin
      `uvm_info(get_type_name(), $sformatf("Starting abort sequence %0d/%0d", seq+1, num_abort_sequences), UVM_MEDIUM)
      
      // Create and randomize abort sequence
      master_abort_seq = axi4_master_exception_multi_abort_seq::type_id::create($sformatf("abort_seq_%0d", seq));
      
      // Start on appropriate sequencer based on random selection
      if($urandom_range(0, 1)) begin
        master_abort_seq.start(p_sequencer.axi4_master_write_seqr_h);
      end else begin
        master_abort_seq.start(p_sequencer.axi4_master_read_seqr_h);
      end
      
      // Delay before next sequence
      #(delays_between_sequences[seq] * 1ns);
    end
    
    // Final recovery period
    #500ns;
    
  endtask
  
  // Generate continuous background traffic
  task generate_background_traffic();
    forever begin
      if($urandom_range(0, 1)) begin
        write_seq = axi4_master_bk_write_seq::type_id::create("bg_write");
        write_seq.start(p_sequencer.axi4_master_write_seqr_h);
      end else begin
        read_seq = axi4_master_bk_read_seq::type_id::create("bg_read");
        read_seq.start(p_sequencer.axi4_master_read_seqr_h);
      end
      #($urandom_range(50, 200) * 1ns);
    end
  endtask
  
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_exception_random_timeout_seq
// Virtual sequence for random near-timeout scenarios
//--------------------------------------------------------------------------------------------
class axi4_virtual_exception_random_timeout_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_exception_random_timeout_seq)

  axi4_master_exception_seq master_exc_seq;
  
  // Randomization parameters
  rand int unsigned num_timeout_events;
  rand int unsigned stall_cycles[];
  rand bit [63:0] target_addrs[];
  rand int unsigned delays_between[];
  
  constraint c_timeouts {
    num_timeout_events inside {[1:10]};  // 1-10 timeout events
    
    stall_cycles.size() == num_timeout_events;
    target_addrs.size() == num_timeout_events;
    delays_between.size() == num_timeout_events;
    
    foreach(stall_cycles[i]) {
      stall_cycles[i] inside {[500:1023]};  // Near timeout threshold
    }
    
    foreach(target_addrs[i]) {
      target_addrs[i][11:0] == 0;  // 4KB aligned
      target_addrs[i] < 64'h0001_0000_0000;
    }
    
    foreach(delays_between[i]) {
      delays_between[i] inside {[100:500]};
    }
  }

  function new(string name = "axi4_virtual_exception_random_timeout_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting Random Near-Timeout test", UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Number of timeout events: %0d", num_timeout_events), UVM_MEDIUM)
    
    for(int i = 0; i < num_timeout_events; i++) begin
      `uvm_info(get_type_name(), $sformatf("Timeout event %0d/%0d: stall=%0d cycles, addr=0x%h", 
                i+1, num_timeout_events, stall_cycles[i], target_addrs[i]), UVM_MEDIUM)
      
      // Delay before this timeout event
      #(delays_between[i] * 1ns);
      
      // Create and configure timeout sequence
      master_exc_seq = axi4_master_exception_seq::type_id::create($sformatf("timeout_seq_%0d", i));
      master_exc_seq.exception_type = axi4_master_exception_seq::NEAR_TIMEOUT;
      master_exc_seq.target_addr = target_addrs[i];
      master_exc_seq.stall_cycles = stall_cycles[i];
      
      // Randomly choose write or read channel
      if($urandom_range(0, 1)) begin
        master_exc_seq.start(p_sequencer.axi4_master_write_seqr_h);
      end else begin
        master_exc_seq.start(p_sequencer.axi4_master_read_seqr_h);
      end
      
      // Recovery time
      #($urandom_range(100, 300) * 1ns);
    end
    
  endtask
endclass

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_exception_mixed_random_seq
// Virtual sequence mixing different exception types randomly
//--------------------------------------------------------------------------------------------
class axi4_virtual_exception_mixed_random_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_exception_mixed_random_seq)

  // Exception type enum
  typedef enum int {
    EXC_ABORT,
    EXC_TIMEOUT,
    EXC_ILLEGAL_ACCESS,
    EXC_ECC_ERROR
  } exception_type_e;
  
  axi4_master_exception_seq master_exc_seq;
  axi4_master_exception_multi_abort_seq abort_seq;
  
  // Randomization parameters
  rand int unsigned num_exceptions;
  rand exception_type_e exception_types[];
  rand int unsigned delays_between[];
  
  constraint c_mixed {
    num_exceptions inside {[5:15]};  // 5-15 exception events
    
    exception_types.size() == num_exceptions;
    delays_between.size() == num_exceptions;
    
    foreach(exception_types[i]) {
      exception_types[i] inside {[EXC_ABORT:EXC_ECC_ERROR]};
    }
    
    foreach(delays_between[i]) {
      delays_between[i] inside {[50:500]};
    }
  }

  function new(string name = "axi4_virtual_exception_mixed_random_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting Mixed Random Exception test", UVM_MEDIUM)
    `uvm_info(get_type_name(), $sformatf("  Number of exceptions: %0d", num_exceptions), UVM_MEDIUM)
    
    for(int i = 0; i < num_exceptions; i++) begin
      `uvm_info(get_type_name(), $sformatf("Exception %0d/%0d: Type=%s", 
                i+1, num_exceptions, exception_types[i].name()), UVM_MEDIUM)
      
      // Delay before this exception
      #(delays_between[i] * 1ns);
      
      case(exception_types[i])
        EXC_ABORT: begin
          abort_seq = axi4_master_exception_multi_abort_seq::type_id::create($sformatf("abort_%0d", i));
          assert(abort_seq.randomize() with {
            num_aborts inside {[1:3]};  // 1-3 aborts per sequence
          });
          abort_seq.start(p_sequencer.axi4_master_write_seqr_h);
        end
        
        EXC_TIMEOUT: begin
          master_exc_seq = axi4_master_exception_seq::type_id::create($sformatf("timeout_%0d", i));
          master_exc_seq.exception_type = axi4_master_exception_seq::NEAR_TIMEOUT;
          master_exc_seq.target_addr = $urandom & 64'hFFFF_F000;
          master_exc_seq.stall_cycles = $urandom_range(800, 1023);
          master_exc_seq.start(p_sequencer.axi4_master_write_seqr_h);
        end
        
        EXC_ILLEGAL_ACCESS: begin
          master_exc_seq = axi4_master_exception_seq::type_id::create($sformatf("illegal_%0d", i));
          master_exc_seq.exception_type = axi4_master_exception_seq::ILLEGAL_ACCESS;
          master_exc_seq.protected_addr = 64'h0000_0000_0000_F000;
          master_exc_seq.unlock_key = $urandom;
          master_exc_seq.start(p_sequencer.axi4_master_write_seqr_h);
        end
        
        EXC_ECC_ERROR: begin
          master_exc_seq = axi4_master_exception_seq::type_id::create($sformatf("ecc_%0d", i));
          master_exc_seq.exception_type = axi4_master_exception_seq::ECC_ERROR_SIM;
          master_exc_seq.start(p_sequencer.axi4_master_write_seqr_h);
        end
      endcase
      
      // Recovery time
      #($urandom_range(50, 200) * 1ns);
    end
    
  endtask
endclass

`endif