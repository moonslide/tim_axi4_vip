`ifndef AXI4_SLAVE_READ_SEQUENCER_INCLUDED_
`define AXI4_SLAVE_READ_SEQUENCER_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_read_sequencer
//--------------------------------------------------------------------------------------------
class axi4_slave_read_sequencer extends uvm_sequencer#(axi4_slave_tx);
  `uvm_component_utils(axi4_slave_read_sequencer)

  // Variable: axi4_slave_agent_cfg_h
  // Declaring handle for slave agent config class 
  axi4_slave_agent_config axi4_slave_agent_cfg_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_slave_read_sequencer", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual function void start_of_simulation_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_slave_read_sequencer

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_slave_read_sequencer
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_slave_read_sequencer::new(string name = "axi4_slave_read_sequencer",
                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_slave_read_sequencer::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: connect_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_slave_read_sequencer::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_slave_read_sequencer::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
endfunction  : end_of_elaboration_phase

//--------------------------------------------------------------------------------------------
// Function: start_of_simulation_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_slave_read_sequencer::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
endfunction : start_of_simulation_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_slave_read_sequencer::run_phase(uvm_phase phase);

  // Note: Slave sequences should be started by virtual sequences or tests
  // The driver proxy will handle read responses automatically in SLAVE_MEM_MODE

endtask : run_phase

`endif

