`ifndef AXI4_MASTER_EXCEPTION_RESET_TERMINATE_SEQ_INCLUDED_
`define AXI4_MASTER_EXCEPTION_RESET_TERMINATE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_exception_reset_terminate_seq
// Description:
// This sequence injects reset assertions during active transfers to test:
// - Transfer abandonment and cleanup
// - Protocol recovery after reset
// - Multiple reset pulses with random timing
// - Reset during different transfer phases
//--------------------------------------------------------------------------------------------
class axi4_master_exception_reset_terminate_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_exception_reset_terminate_seq)
  
  // Reset termination parameters
  rand int unsigned num_reset_events;      // Number of reset events
  rand int unsigned reset_durations[];     // Reset pulse durations in cycles
  rand int unsigned reset_delays_ns[];     // Delays between resets
  
  // Transfer phase for reset injection
  typedef enum {
    RESET_ADDR_PHASE,
    RESET_DATA_PHASE,
    RESET_RESP_PHASE,
    RESET_IDLE_PHASE
  } reset_phase_e;
  
  rand reset_phase_e reset_phases[];
  
  // Randomization constraints
  constraint c_reset_params {
    num_reset_events inside {[1:8]};  // 1-8 reset events
    reset_durations.size() == num_reset_events;
    reset_delays_ns.size() == num_reset_events;
    reset_phases.size() == num_reset_events;
    
    foreach(reset_durations[i]) {
      reset_durations[i] inside {[1:10]};  // 1-10 cycle reset pulse
    }
    
    foreach(reset_delays_ns[i]) {
      reset_delays_ns[i] inside {[50:1000]};  // 50-1000ns between resets
    }
    
    foreach(reset_phases[i]) {
      reset_phases[i] dist {
        RESET_ADDR_PHASE := 25,
        RESET_DATA_PHASE := 35,
        RESET_RESP_PHASE := 25,
        RESET_IDLE_PHASE := 15
      };
    }
  }
  
  // Constructor
  extern function new(string name = "axi4_master_exception_reset_terminate_seq");
  extern task body();
  extern task inject_reset_pulse(int duration_cycles, reset_phase_e phase);
  
endclass : axi4_master_exception_reset_terminate_seq

//--------------------------------------------------------------------------------------------
// Constructor
//--------------------------------------------------------------------------------------------
function axi4_master_exception_reset_terminate_seq::new(string name = "axi4_master_exception_reset_terminate_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Main sequence body that performs reset termination
//--------------------------------------------------------------------------------------------
task axi4_master_exception_reset_terminate_seq::body();
  
  super.body();
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Starting reset termination test with %0d reset events", num_reset_events), UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  foreach(reset_phases[i]) begin
    `uvm_info(get_type_name(), $sformatf("Reset event %0d/%0d: Phase=%s, Duration=%0d cycles, Delay=%0dns", 
              i+1, num_reset_events, reset_phases[i].name(), reset_durations[i], reset_delays_ns[i]), UVM_LOW)
    
    // Inject reset at different phases
    case(reset_phases[i])
      RESET_ADDR_PHASE: begin
        // Signal reset during address phase
        #10ns;  // Small delay for any ongoing transfer
        inject_reset_pulse(reset_durations[i], RESET_ADDR_PHASE);
      end
      
      RESET_DATA_PHASE: begin
        // Signal reset during data phase
        #50ns;  // Delay for data phase
        inject_reset_pulse(reset_durations[i], RESET_DATA_PHASE);
      end
      
      RESET_RESP_PHASE: begin
        // Signal reset during response phase
        #100ns;  // Delay for response phase
        inject_reset_pulse(reset_durations[i], RESET_RESP_PHASE);
      end
      
      RESET_IDLE_PHASE: begin
        // Reset during idle - no active transfer
        #50ns;  // Ensure idle
        inject_reset_pulse(reset_durations[i], RESET_IDLE_PHASE);
      end
    endcase
    
    // Wait before next reset event
    #(reset_delays_ns[i] * 1ns);
  end
  
  `uvm_info(get_type_name(), "Reset termination exception test completed", UVM_LOW)
  
endtask : body

//--------------------------------------------------------------------------------------------
// Task: inject_reset_pulse
// Injects a reset pulse of specified duration
//--------------------------------------------------------------------------------------------
task axi4_master_exception_reset_terminate_seq::inject_reset_pulse(int duration_cycles, reset_phase_e phase);
  bit reset_done = 0;
  
  `uvm_info(get_type_name(), $sformatf("Asserting reset for %0d cycles during %s", duration_cycles, phase.name()), UVM_LOW)
  
  // Pass reset duration to hdl_top FIRST
  uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", duration_cycles);
  
  // Mark reset active in config
  uvm_config_db#(bit)::set(null, "*", "reset_active", 1);
  uvm_config_db#(string)::set(null, "*", "reset_phase", phase.name());
  
  // Signal reset assertion via config DB (to be handled by hdl_top)
  uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
  
  // Monitor for reset completion
  fork
    begin
      // Wait for hdl_top to clear the inject_reset flag
      while(1) begin
        #10ns;
        if(!uvm_config_db#(bit)::get(null, "*", "inject_reset", reset_done))
          reset_done = 0;
        if(reset_done == 0) break;  // hdl_top cleared it
      end
      `uvm_info(get_type_name(), "Reset pulse completed by hdl_top", UVM_MEDIUM)
    end
    begin
      // Timeout protection
      #((duration_cycles + 5) * 10ns);
      `uvm_warning(get_type_name(), "Reset pulse timeout")
    end
  join_any
  disable fork;
  
  // Clear reset active flag
  uvm_config_db#(bit)::set(null, "*", "reset_active", 0);
  
  // Wait for system to stabilize before next reset
  #100ns;
  
  `uvm_info(get_type_name(), $sformatf("Reset %s completed", phase.name()), UVM_LOW)
  
endtask : inject_reset_pulse

`endif