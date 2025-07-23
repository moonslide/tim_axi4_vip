`ifndef AXI4_MASTER_TX_ROUTER_INCLUDED_
`define AXI4_MASTER_TX_ROUTER_INCLUDED_

import axi4_bus_matrix_pkg::*;

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tx_router
// Description: Routes master transactions to appropriate slaves based on address decoding
// This component sits between masters and slaves in the testbench
//--------------------------------------------------------------------------------------------
class axi4_master_tx_router extends uvm_component;
  `uvm_component_utils(axi4_master_tx_router)
  
  // Configuration
  axi4_env_config axi4_env_cfg_h;
  axi4_bus_matrix_ref axi4_bus_matrix_h;
  
  // Master agent configurations
  axi4_master_agent_config axi4_master_agent_cfg_h[];
  
  // Slave sequencers for direct sequence injection
  uvm_sequencer #(axi4_slave_tx) slave_write_seqr_h[];
  uvm_sequencer #(axi4_slave_tx) slave_read_seqr_h[];
  
  // Transaction tracking
  axi4_slave_tx pending_read_tx[int][int];  // [slave_id][arid] -> transaction
  axi4_slave_tx pending_write_tx[int][int]; // [slave_id][awid] -> transaction
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_tx_router", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task monitor_and_route_transactions();
  extern virtual function int get_target_slave(bit[ADDRESS_WIDTH-1:0] addr);
  
endclass : axi4_master_tx_router

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_master_tx_router::new(string name = "axi4_master_tx_router", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_master_tx_router::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Get configuration
  if(!uvm_config_db #(axi4_env_config)::get(this,"","axi4_env_config",axi4_env_cfg_h)) begin
    `uvm_fatal("FATAL_TX_ROUTER_CONFIG", "Couldn't get the env_config from config_db")
  end
  
  // Get bus matrix reference
  if(!uvm_config_db #(axi4_bus_matrix_ref)::get(this,"","axi4_bus_matrix_gm",axi4_bus_matrix_h)) begin
    `uvm_fatal("FATAL_TX_ROUTER_BUS_MATRIX", "Couldn't get the bus matrix from config_db")
  end
  
  // Get master configurations
  axi4_master_agent_cfg_h = new[axi4_env_cfg_h.no_of_masters];
  foreach(axi4_master_agent_cfg_h[i]) begin
    if(!uvm_config_db#(axi4_master_agent_config)::get(this,"",
                                  $sformatf("axi4_master_agent_config_%0d",i),
                                  axi4_master_agent_cfg_h[i])) begin
      `uvm_fatal("FATAL_TX_ROUTER_MA_CONFIG", $sformatf("Couldn't get master config %0d", i))
    end
  end
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: connect_phase
//--------------------------------------------------------------------------------------------
function void axi4_master_tx_router::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  // Connect to slave sequencers - these will be set by environment
  
endfunction : connect_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_master_tx_router::run_phase(uvm_phase phase);
  super.run_phase(phase);
  
  // Start monitoring and routing
  monitor_and_route_transactions();
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Task: monitor_and_route_transactions
//--------------------------------------------------------------------------------------------
task axi4_master_tx_router::monitor_and_route_transactions();
  // This task would monitor master transactions and route them
  // For now, we'll use a different approach
  `uvm_info("TX_ROUTER", "Transaction router started", UVM_LOW)
  
  forever begin
    #100; // Placeholder
  end
endtask : monitor_and_route_transactions

//--------------------------------------------------------------------------------------------
// Function: get_target_slave
//--------------------------------------------------------------------------------------------
function int axi4_master_tx_router::get_target_slave(bit[ADDRESS_WIDTH-1:0] addr);
  return axi4_bus_matrix_h.decode(addr);
endfunction : get_target_slave

`endif