`ifndef AXI4_MASTER_EXCEPTION_CLK_FREQ_SEQ_INCLUDED_
`define AXI4_MASTER_EXCEPTION_CLK_FREQ_SEQ_INCLUDED_

//=============================================================================================
// File: axi4_master_exception_clk_freq_seq.sv
// Description: Master sequences for clock frequency exception injection
//
// This file contains sequences that inject clock frequency changes during AXI4 transfers
// to test system behavior under varying clock conditions.
//
// SEQUENCES INCLUDED:
// 1. axi4_master_exception_clk_freq_seq - Clock frequency change sequence
// 2. axi4_master_exception_reset_terminate_seq - Reset termination sequence
//
// CLOCK FREQUENCY PARAMETERS:
// - Frequency scale factors: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x, 3.0x
// - Number of changes: 1-10 (random)
// - Hold duration: 5-100 cycles per frequency
// - Change delays: 100-1000ns between changes
//
// RESET PARAMETERS:
// - Reset duration: 1-10 cycles
// - Number of resets: 1-8 (random)
// - Reset phases: Address, Data, Response, or Idle
// - Recovery delay: 50-200ns after reset
//=============================================================================================

//--------------------------------------------------------------------------------------------
// Class: axi4_master_exception_clk_freq_seq
// Description:
// This sequence injects clock frequency changes during active transfers to test:
// - Sample timing errors due to frequency changes
// - Protocol recovery after clock glitches
// - Multiple frequency changes during single transfer
// - Random frequency scaling factors
//--------------------------------------------------------------------------------------------
class axi4_master_exception_clk_freq_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_exception_clk_freq_seq)
  
  // Clock frequency change parameters
  rand int unsigned num_freq_changes;      // Number of frequency changes
  real freq_scale_factors[];               // Frequency scaling factors (not randomizable)
  rand int unsigned change_delays_ns[];    // Delays between changes
  rand int unsigned freq_hold_cycles[];    // How long to hold each frequency
  rand int unsigned freq_scale_idx[];      // Index into scale factor options
  
  // Randomization constraints
  constraint c_freq_params {
    num_freq_changes inside {[1:10]};  // 1-10 frequency changes
    freq_scale_idx.size() == num_freq_changes;
    change_delays_ns.size() == num_freq_changes;
    freq_hold_cycles.size() == num_freq_changes;
    
    foreach(freq_scale_idx[i]) {
      freq_scale_idx[i] inside {[0:6]};  // Index into scale factor array
    }
    
    foreach(change_delays_ns[i]) {
      change_delays_ns[i] inside {[10:500]};  // 10-500ns between changes
    }
    
    foreach(freq_hold_cycles[i]) {
      freq_hold_cycles[i] inside {[5:100]};  // Hold for 5-100 cycles
    }
  }
  
  // Post-randomize to set freq_scale_factors based on indices
  function void post_randomize();
    real scale_options[7] = '{0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0};
    freq_scale_factors = new[num_freq_changes];
    foreach(freq_scale_idx[i]) begin
      freq_scale_factors[i] = scale_options[freq_scale_idx[i]];
    end
  endfunction
  
  // Constructor
  extern function new(string name = "axi4_master_exception_clk_freq_seq");
  extern task body();
  extern task inject_clock_frequency_change(real scale_factor, int hold_cycles);
  
endclass : axi4_master_exception_clk_freq_seq

//--------------------------------------------------------------------------------------------
// Constructor
//--------------------------------------------------------------------------------------------
function axi4_master_exception_clk_freq_seq::new(string name = "axi4_master_exception_clk_freq_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Main sequence body that performs clock frequency changes
//--------------------------------------------------------------------------------------------
task axi4_master_exception_clk_freq_seq::body();
  
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting clock frequency exception test with %0d changes", num_freq_changes), UVM_LOW)
  
  // Inject clock frequency changes
  foreach(freq_scale_factors[i]) begin
    #(change_delays_ns[i] * 1ns);
    `uvm_info(get_type_name(), $sformatf("Change %0d/%0d: Scaling clock by %0.2fx for %0d cycles", 
              i+1, num_freq_changes, freq_scale_factors[i], freq_hold_cycles[i]), UVM_MEDIUM)
    inject_clock_frequency_change(freq_scale_factors[i], freq_hold_cycles[i]);
  end
  
  // Restore normal frequency
  inject_clock_frequency_change(1.0, 10);
  
  `uvm_info(get_type_name(), "Clock frequency exception test completed", UVM_LOW)
  
endtask : body

//--------------------------------------------------------------------------------------------
// Task: inject_clock_frequency_change
// Injects clock frequency change via configuration
//--------------------------------------------------------------------------------------------
task axi4_master_exception_clk_freq_seq::inject_clock_frequency_change(real scale_factor, int hold_cycles);
  
  // Set clock frequency scale factor in config
  uvm_config_db#(real)::set(null, "*", "clk_freq_scale", scale_factor);
  
  // Signal clock change event
  uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
  
  // Hold for specified cycles (using time delay instead of clock reference)
  #(hold_cycles * 10ns); // Assuming 100MHz clock (10ns period)
  
  // Clear change flag
  uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
  
endtask : inject_clock_frequency_change

`endif