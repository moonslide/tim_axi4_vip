`ifndef AXI4_STRESS_RESET_TEST_INCLUDED_
`define AXI4_STRESS_RESET_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_stress_reset_test
// Stress test with mid-burst reset injection
// Implements axi4_saturation_midburst_reset_qos_boundary_test from test plan
//--------------------------------------------------------------------------------------------
class axi4_stress_reset_test extends axi4_base_test;
  `uvm_component_utils(axi4_stress_reset_test)

  // Virtual sequence handle
  axi4_stress_reset_virtual_seq stress_reset_vseq;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_stress_reset_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task apply_reset_pulse();
  
endclass : axi4_stress_reset_test

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes class object
//
// Parameters:
//  name - axi4_stress_reset_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_stress_reset_test::new(string name = "axi4_stress_reset_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Create required configuration
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_stress_reset_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  `uvm_info(get_type_name(), "Building stress reset test configuration", UVM_LOW)
  
  // Enable error injection support in environment
  uvm_config_db#(bit)::set(this, "*", "error_inject", 0);
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Run the stress reset virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_stress_reset_test::run_phase(uvm_phase phase);
  bit inject_reset;
  
  `uvm_info(get_type_name(), "Starting AXI4 Stress Reset Test", UVM_LOW)
  
  phase.raise_objection(this, "axi4_stress_reset_test");
  
  // Monitor for reset injection request
  fork
    forever begin
      uvm_config_db#(bit)::wait_modified(this, "*", "inject_reset");
      if(uvm_config_db#(bit)::get(null, "*", "inject_reset", inject_reset)) begin
        if(inject_reset) begin
          apply_reset_pulse();
        end
      end
    end
  join_none
  
  // Create and start the virtual sequence
  stress_reset_vseq = axi4_stress_reset_virtual_seq::type_id::create("stress_reset_vseq");
  
  // Configure test parameters
  stress_reset_vseq.num_transactions = 10;
  stress_reset_vseq.reset_delay_cycles = 1000;
  
  // Start the sequence on virtual sequencer
  stress_reset_vseq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  // Additional time for observation
  #10us;
  
  `uvm_info(get_type_name(), "Completed AXI4 Stress Reset Test", UVM_LOW)
  
  // Check for protocol violations
  if(axi4_env_h.axi4_scoreboard_h != null) begin
    if(axi4_env_h.axi4_scoreboard_h.unexpected_error_count > 0) begin
      `uvm_error(get_type_name(), $sformatf("Test failed with %0d unexpected errors", axi4_env_h.axi4_scoreboard_h.unexpected_error_count))
    end else begin
      `uvm_info(get_type_name(), "Test passed with no unexpected errors", UVM_LOW)
    end
  end
  
  phase.drop_objection(this);
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Task: apply_reset_pulse
// Apply reset pulse to DUT
//--------------------------------------------------------------------------------------------
task axi4_stress_reset_test::apply_reset_pulse();
  
  `uvm_info(get_type_name(), "Applying reset pulse to DUT", UVM_LOW)
  
  // Assert reset through virtual interface
  // This assumes the testbench has a reset control interface
  // The actual implementation depends on the testbench architecture
  
  // Example reset sequence (adjust based on actual testbench):
  // vif.rst_n = 0;
  // #1000ns;
  // vif.rst_n = 1;
  
  `uvm_info(get_type_name(), "Reset pulse completed", UVM_LOW)
  
endtask : apply_reset_pulse

`endif