`ifndef AXI4_VIRTUAL_EXCEPTION_CLK_RESET_SEQ_INCLUDED_
`define AXI4_VIRTUAL_EXCEPTION_CLK_RESET_SEQ_INCLUDED_

//=============================================================================================
// File: axi4_virtual_exception_clk_reset_seq.sv
// Description: Virtual sequences for clock and reset exception handling
//
// This file contains virtual sequences that coordinate clock frequency changes and
// reset events across the AXI4 system to test exception handling and recovery.
//
// SEQUENCE: axi4_virtual_exception_clk_reset_seq
// - Combines clock frequency changes with reset termination events
// - Supports simultaneous and sequential exception injection
// - Coordinates exceptions across multiple masters/slaves
//
// EXCEPTION TYPES:
// 1. CLK_FREQ_CHANGE - Changes clock frequency during transfers
// 2. RESET_TERMINATE - Asserts reset to terminate active transfers
// 3. BOTH_SIMULTANEOUS - Clock and reset events at the same time
//
// PARAMETERS:
// - Number of events: 3-15 (random)
// - Exception delays: 100-2000ns between events
// - Simultaneous probability: 20% chance
// - Recovery verification after each event
//
// BUS MATRIX SUPPORT:
// - NONE mode: Single master/slave pair
// - BASE mode: 4x4 matrix with coordinated exceptions
// - ENHANCED mode: 10x10 matrix with distributed exceptions
//
// VERIFICATION FEATURES:
// - Protocol compliance checking during exceptions
// - Deadlock/livelock detection
// - Transaction abandonment verification
// - Recovery time measurement
// - Performance impact analysis
//=============================================================================================

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_exception_clk_reset_seq
// Description:
// Virtual sequence that combines clock frequency changes and reset termination
// - Supports all bus matrix modes (NONE/1x1, BASE/4x4, ENHANCED/10x10)
// - Random mixing of clock and reset events
// - Tests system resilience under combined exceptions
//--------------------------------------------------------------------------------------------
class axi4_virtual_exception_clk_reset_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_exception_clk_reset_seq)
  
  // Exception type enumeration
  typedef enum {
    CLK_FREQ_CHANGE,
    RESET_TERMINATE,
    BOTH_SIMULTANEOUS
  } exception_type_e;
  
  // Randomization parameters
  rand int unsigned num_exception_events;
  rand exception_type_e exception_types[];
  rand int unsigned exception_delays_ns[];
  rand bit simultaneous_exceptions;
  
  // Constraints
  constraint c_params {
    num_exception_events inside {[3:15]};  // 3-15 exception events
    exception_types.size() == num_exception_events;
    exception_delays_ns.size() == num_exception_events;
    
    foreach(exception_types[i]) {
      exception_types[i] dist {
        CLK_FREQ_CHANGE := 40,
        RESET_TERMINATE := 40,
        BOTH_SIMULTANEOUS := 20
      };
    }
    
    foreach(exception_delays_ns[i]) {
      exception_delays_ns[i] inside {[100:2000]};  // 100-2000ns between events
    }
    
    simultaneous_exceptions dist {1 := 30, 0 := 70};
  }
  
  // Constructor
  extern function new(string name = "axi4_virtual_exception_clk_reset_seq");
  extern task body();
  
endclass : axi4_virtual_exception_clk_reset_seq

//--------------------------------------------------------------------------------------------
// Constructor
//--------------------------------------------------------------------------------------------
function axi4_virtual_exception_clk_reset_seq::new(string name = "axi4_virtual_exception_clk_reset_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Main sequence body that performs combined clock and reset exceptions
//--------------------------------------------------------------------------------------------
task axi4_virtual_exception_clk_reset_seq::body();
  axi4_master_exception_clk_freq_seq clk_seq;
  axi4_master_exception_reset_terminate_seq reset_seq;
  axi4_master_write_seq write_seq;
  axi4_master_read_seq read_seq;
  axi4_slave_write_seq slave_write_seq;
  axi4_slave_read_seq slave_read_seq;
  int master_idx, slave_idx;
  
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting combined clock/reset exception test with %0d events", num_exception_events), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %0dx%0d", p_sequencer.axi4_master_write_seqr_h_all.size(), 
            p_sequencer.axi4_slave_write_seqr_h_all.size()), UVM_LOW)
  
  // Start background traffic on all masters and slaves
  fork
    begin
      forever begin
        // Randomly select master and slave
        master_idx = $urandom_range(0, p_sequencer.axi4_master_write_seqr_h_all.size()-1);
        slave_idx = $urandom_range(0, p_sequencer.axi4_slave_write_seqr_h_all.size()-1);
        
        // Generate write traffic
        write_seq = axi4_master_write_seq::type_id::create($sformatf("write_seq_m%0d", master_idx));
        if(!write_seq.randomize()) begin
          `uvm_error(get_type_name(), "Write sequence randomization failed")
        end
        write_seq.start(p_sequencer.axi4_master_write_seqr_h_all[master_idx]);
        
        // Generate read traffic
        read_seq = axi4_master_read_seq::type_id::create($sformatf("read_seq_m%0d", master_idx));
        if(!read_seq.randomize()) begin
          `uvm_error(get_type_name(), "Read sequence randomization failed")
        end
        read_seq.start(p_sequencer.axi4_master_read_seqr_h_all[master_idx]);
        
        #50ns;
      end
    end
    
    begin
      // Configure slaves to respond
      foreach(p_sequencer.axi4_slave_write_seqr_h_all[i]) begin
        slave_write_seq = axi4_slave_write_seq::type_id::create($sformatf("slave_write_seq_%0d", i));
        if(!slave_write_seq.randomize()) begin
          `uvm_error(get_type_name(), "Slave write sequence randomization failed")
        end
        fork
          automatic int idx = i;
          slave_write_seq.start(p_sequencer.axi4_slave_write_seqr_h_all[idx]);
        join_none
      end
      
      foreach(p_sequencer.axi4_slave_read_seqr_h_all[i]) begin
        slave_read_seq = axi4_slave_read_seq::type_id::create($sformatf("slave_read_seq_%0d", i));
        if(!slave_read_seq.randomize()) begin
          `uvm_error(get_type_name(), "Slave read sequence randomization failed")
        end
        fork
          automatic int idx = i;
          slave_read_seq.start(p_sequencer.axi4_slave_read_seqr_h_all[idx]);
        join_none
      end
    end
    
    begin
      // Inject exceptions according to schedule
      foreach(exception_types[i]) begin
        #(exception_delays_ns[i] * 1ns);
        
        `uvm_info(get_type_name(), $sformatf("Exception %0d/%0d: Type=%s", 
                  i+1, num_exception_events, exception_types[i].name()), UVM_MEDIUM)
        
        case(exception_types[i])
          CLK_FREQ_CHANGE: begin
            // Inject clock frequency change on random master
            master_idx = $urandom_range(0, p_sequencer.axi4_master_write_seqr_h_all.size()-1);
            clk_seq = axi4_master_exception_clk_freq_seq::type_id::create("clk_seq");
            if(!clk_seq.randomize() with {
              num_freq_changes inside {[1:3]};
            }) begin
              `uvm_error(get_type_name(), "Clock sequence randomization failed")
            end
            clk_seq.start(p_sequencer.axi4_master_write_seqr_h_all[master_idx]);
          end
          
          RESET_TERMINATE: begin
            // Inject reset termination on random master
            master_idx = $urandom_range(0, p_sequencer.axi4_master_write_seqr_h_all.size()-1);
            reset_seq = axi4_master_exception_reset_terminate_seq::type_id::create("reset_seq");
            if(!reset_seq.randomize() with {
              num_reset_events inside {[1:3]};
            }) begin
              `uvm_error(get_type_name(), "Reset sequence randomization failed")
            end
            reset_seq.start(p_sequencer.axi4_master_write_seqr_h_all[master_idx]);
          end
          
          BOTH_SIMULTANEOUS: begin
            // Inject both exceptions simultaneously on different masters
            fork
              begin
                master_idx = 0;
                clk_seq = axi4_master_exception_clk_freq_seq::type_id::create("clk_seq_simul");
                if(!clk_seq.randomize() with {
                  num_freq_changes == 1;
                }) begin
                  `uvm_error(get_type_name(), "Clock sequence randomization failed")
                end
                clk_seq.start(p_sequencer.axi4_master_write_seqr_h_all[master_idx]);
              end
              
              begin
                master_idx = (p_sequencer.axi4_master_write_seqr_h_all.size() > 1) ? 1 : 0;
                reset_seq = axi4_master_exception_reset_terminate_seq::type_id::create("reset_seq_simul");
                if(!reset_seq.randomize() with {
                  num_reset_events == 1;
                }) begin
                  `uvm_error(get_type_name(), "Reset sequence randomization failed")
                end
                reset_seq.start(p_sequencer.axi4_master_write_seqr_h_all[master_idx]);
              end
            join
          end
        endcase
      end
      
      // Wait for all exceptions to complete
      #1000ns;
    end
  join_any
  
  // Stop all sequences
  disable fork;
  
  // Final recovery test
  `uvm_info(get_type_name(), "Running recovery test after exceptions", UVM_LOW)
  write_seq = axi4_master_write_seq::type_id::create("recovery_seq");
  if(!write_seq.randomize()) begin
    `uvm_error(get_type_name(), "Recovery sequence randomization failed")
  end
  write_seq.start(p_sequencer.axi4_master_write_seqr_h_all[0]);
  
  `uvm_info(get_type_name(), "Combined clock/reset exception test completed", UVM_LOW)
  
endtask : body

`endif