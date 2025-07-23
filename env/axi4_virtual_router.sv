`ifndef AXI4_VIRTUAL_ROUTER_INCLUDED_
`define AXI4_VIRTUAL_ROUTER_INCLUDED_

import axi4_bus_matrix_pkg::*;

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_router
// Description: Virtual router to handle transaction routing based on address decoding
// This component intercepts transactions and routes them to the correct slave
//--------------------------------------------------------------------------------------------
class axi4_virtual_router extends uvm_component;
  `uvm_component_utils(axi4_virtual_router)
  
  // Configuration handle
  axi4_env_config axi4_env_cfg_h;
  
  // Bus matrix reference for address decoding
  axi4_bus_matrix_ref axi4_bus_matrix_h;
  
  // Analysis exports for intercepting master transactions
  uvm_analysis_export #(axi4_master_tx) master_read_addr_export[10];
  uvm_analysis_export #(axi4_master_tx) master_write_addr_export[10];
  
  // Analysis ports to forward to correct slaves
  uvm_analysis_port #(axi4_master_tx) slave_read_addr_port[10];
  uvm_analysis_port #(axi4_master_tx) slave_write_addr_port[10];
  
  // FIFOs for storing intercepted transactions
  uvm_tlm_analysis_fifo #(axi4_master_tx) master_read_fifo[10];
  uvm_tlm_analysis_fifo #(axi4_master_tx) master_write_fifo[10];
  
  // Transaction routing map (master_id -> slave_id for pending transactions)
  int read_routing_map[int][int];  // [master_id][transaction_id] -> slave_id
  int write_routing_map[int][int]; // [master_id][transaction_id] -> slave_id
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_router", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task route_read_transactions();
  extern virtual task route_write_transactions();
  extern virtual function int decode_slave_id(bit[63:0] addr);
  
endclass : axi4_virtual_router

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_virtual_router::new(string name = "axi4_virtual_router", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_virtual_router::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Get configuration and bus matrix
  if(!uvm_config_db #(axi4_env_config)::get(this,"","axi4_env_config",axi4_env_cfg_h)) begin
    `uvm_fatal("FATAL_ROUTER_CONFIG", "Couldn't get the env_config from config_db")
  end
  
  if(!uvm_config_db #(axi4_bus_matrix_ref)::get(this,"","axi4_bus_matrix_gm",axi4_bus_matrix_h)) begin
    `uvm_fatal("FATAL_ROUTER_BUS_MATRIX", "Couldn't get the bus matrix from config_db")
  end
  
  // Create analysis components for all possible masters/slaves
  foreach(master_read_addr_export[i]) begin
    master_read_addr_export[i] = new($sformatf("master_read_addr_export[%0d]", i), this);
    master_read_fifo[i] = new($sformatf("master_read_fifo[%0d]", i), this);
    slave_read_addr_port[i] = new($sformatf("slave_read_addr_port[%0d]", i), this);
  end
  
  foreach(master_write_addr_export[i]) begin
    master_write_addr_export[i] = new($sformatf("master_write_addr_export[%0d]", i), this);
    master_write_fifo[i] = new($sformatf("master_write_fifo[%0d]", i), this);
    slave_write_addr_port[i] = new($sformatf("slave_write_addr_port[%0d]", i), this);
  end
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: connect_phase
//--------------------------------------------------------------------------------------------
function void axi4_virtual_router::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  // Connect exports to FIFOs
  foreach(master_read_addr_export[i]) begin
    master_read_addr_export[i].connect(master_read_fifo[i].analysis_export);
  end
  
  foreach(master_write_addr_export[i]) begin
    master_write_addr_export[i].connect(master_write_fifo[i].analysis_export);
  end
  
endfunction : connect_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_virtual_router::run_phase(uvm_phase phase);
  super.run_phase(phase);
  
  fork
    route_read_transactions();
    route_write_transactions();
  join
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Task: route_read_transactions
//--------------------------------------------------------------------------------------------
task axi4_virtual_router::route_read_transactions();
  axi4_master_tx read_tx;
  int target_slave_id;
  
  forever begin
    // Check all master FIFOs
    for(int m = 0; m < axi4_env_cfg_h.no_of_masters; m++) begin
      if(master_read_fifo[m].try_get(read_tx)) begin
        // Decode target slave based on address
        target_slave_id = decode_slave_id(read_tx.araddr);
        
        `uvm_info("VIRTUAL_ROUTER", $sformatf("Routing read from Master %0d (addr=0x%16h) to Slave %0d", 
                  m, read_tx.araddr, target_slave_id), UVM_MEDIUM)
        
        if(target_slave_id >= 0 && target_slave_id < axi4_env_cfg_h.no_of_slaves) begin
          // Store routing info for response tracking
          read_routing_map[m][read_tx.arid] = target_slave_id;
          
          // Forward to target slave
          slave_read_addr_port[target_slave_id].write(read_tx);
        end else begin
          `uvm_error("VIRTUAL_ROUTER", $sformatf("Invalid slave decode %0d for address 0x%16h", 
                     target_slave_id, read_tx.araddr))
        end
      end
    end
    #1; // Small delay to prevent infinite loop
  end
endtask : route_read_transactions

//--------------------------------------------------------------------------------------------
// Task: route_write_transactions
//--------------------------------------------------------------------------------------------
task axi4_virtual_router::route_write_transactions();
  axi4_master_tx write_tx;
  int target_slave_id;
  
  forever begin
    // Check all master FIFOs
    for(int m = 0; m < axi4_env_cfg_h.no_of_masters; m++) begin
      if(master_write_fifo[m].try_get(write_tx)) begin
        // Decode target slave based on address
        target_slave_id = decode_slave_id(write_tx.awaddr);
        
        `uvm_info("VIRTUAL_ROUTER", $sformatf("Routing write from Master %0d (addr=0x%16h) to Slave %0d", 
                  m, write_tx.awaddr, target_slave_id), UVM_MEDIUM)
        
        if(target_slave_id >= 0 && target_slave_id < axi4_env_cfg_h.no_of_slaves) begin
          // Store routing info for response tracking
          write_routing_map[m][write_tx.awid] = target_slave_id;
          
          // Forward to target slave
          slave_write_addr_port[target_slave_id].write(write_tx);
        end else begin
          `uvm_error("VIRTUAL_ROUTER", $sformatf("Invalid slave decode %0d for address 0x%16h", 
                     target_slave_id, write_tx.awaddr))
        end
      end
    end
    #1; // Small delay to prevent infinite loop
  end
endtask : route_write_transactions

//--------------------------------------------------------------------------------------------
// Function: decode_slave_id
//--------------------------------------------------------------------------------------------
function int axi4_virtual_router::decode_slave_id(bit[63:0] addr);
  return axi4_bus_matrix_h.decode(addr);
endfunction : decode_slave_id

`endif