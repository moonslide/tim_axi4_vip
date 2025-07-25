`ifndef AXI4_TRANSACTION_ROUTER_INCLUDED_
`define AXI4_TRANSACTION_ROUTER_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_transaction_router
// Centralized transaction router for bench-only mode to properly distribute transactions
// to the correct slaves based on address decoding
//--------------------------------------------------------------------------------------------
class axi4_transaction_router extends uvm_component;
  `uvm_component_utils(axi4_transaction_router)
  
  // Analysis implementation to receive transactions from all slave monitors
  uvm_analysis_imp#(axi4_slave_tx, axi4_transaction_router) slave_read_addr_analysis_imp;
  
  // TLM FIFOs for each slave - separate FIFOs to avoid contention
  uvm_tlm_fifo#(axi4_slave_tx) slave_read_addr_fifo[10];
  
  // Handle to bus matrix for address decoding
  axi4_bus_matrix_ref axi4_bus_matrix_h;
  
  // Number of slaves in the system
  int num_slaves = 10;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_transaction_router", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void write(axi4_slave_tx t);
  extern virtual task route_transaction(axi4_slave_tx trans);
  
endclass : axi4_transaction_router

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_transaction_router::new(string name = "axi4_transaction_router", uvm_component parent = null);
  super.new(name, parent);
  slave_read_addr_analysis_imp = new("slave_read_addr_analysis_imp", this);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_transaction_router::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Create separate FIFOs for each slave
  for (int i = 0; i < num_slaves; i++) begin
    slave_read_addr_fifo[i] = new($sformatf("slave_read_addr_fifo[%0d]", i), this);
  end
  
  // Get bus matrix handle
  if(!uvm_config_db#(axi4_bus_matrix_ref)::get(this, "", "bus_matrix_ref", axi4_bus_matrix_h)) begin
    `uvm_error("ROUTER", "Failed to get bus matrix reference from config_db");
  end
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: connect_phase
//--------------------------------------------------------------------------------------------
function void axi4_transaction_router::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  // Nothing to connect here - analysis imp is already created
endfunction : connect_phase

//--------------------------------------------------------------------------------------------
// Function: write - Analysis imp write function
// Called when a slave monitor observes a read address transaction
//--------------------------------------------------------------------------------------------
function void axi4_transaction_router::write(axi4_slave_tx t);
  // Route transaction in a separate thread to avoid blocking
  fork
    route_transaction(t);
  join_none
endfunction : write

//--------------------------------------------------------------------------------------------
// Task: route_transaction
// Routes transaction to the correct slave based on address decoding
//--------------------------------------------------------------------------------------------
task axi4_transaction_router::route_transaction(axi4_slave_tx trans);
  int target_slave_id;
  axi4_slave_tx trans_copy;
  
  // Make a copy of the transaction
  $cast(trans_copy, trans.clone());
  
  // Decode the target slave based on address
  if (axi4_bus_matrix_h != null) begin
    target_slave_id = axi4_bus_matrix_h.decode(trans_copy.araddr);
    
    if (target_slave_id >= 0 && target_slave_id < num_slaves) begin
      `uvm_info("ROUTER", $sformatf("Routing transaction with address 0x%16h to slave %0d", 
                trans_copy.araddr, target_slave_id), UVM_HIGH);
      
      // Put transaction in the appropriate slave's FIFO
      slave_read_addr_fifo[target_slave_id].put(trans_copy);
    end else begin
      `uvm_warning("ROUTER", $sformatf("Invalid slave ID %0d decoded for address 0x%16h", 
                   target_slave_id, trans_copy.araddr));
    end
  end else begin
    `uvm_error("ROUTER", "Bus matrix handle is null");
  end
endtask : route_transaction

`endif