`ifndef AXI4_ROUTING_SEQUENCE_INCLUDED_
`define AXI4_ROUTING_SEQUENCE_INCLUDED_

import axi4_bus_matrix_pkg::*;

//--------------------------------------------------------------------------------------------
// Class: axi4_routing_sequence
// Description: Virtual sequence that handles transaction routing for bench-only interconnect
// This sequence runs on virtual sequencer and coordinates master/slave transactions
//--------------------------------------------------------------------------------------------
class axi4_routing_sequence extends uvm_sequence;
  `uvm_object_utils(axi4_routing_sequence)
  
  // Bus matrix reference for address decoding
  axi4_bus_matrix_ref axi4_bus_matrix_h;
  
  // Number of masters and slaves
  int num_masters = 10;
  int num_slaves = 10;
  
  // Sequencer handles
  `uvm_declare_p_sequencer(axi4_virtual_sequencer)
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_routing_sequence");
  extern virtual task body();
  extern virtual task route_master_transactions();
  extern virtual task handle_master_read(int master_id);
  extern virtual task handle_master_write(int master_id);
  
endclass : axi4_routing_sequence

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_routing_sequence::new(string name = "axi4_routing_sequence");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//--------------------------------------------------------------------------------------------
task axi4_routing_sequence::body();
  
  // Get bus matrix reference
  if(!uvm_config_db #(axi4_bus_matrix_ref)::get(p_sequencer,"","axi4_bus_matrix_gm",axi4_bus_matrix_h)) begin
    `uvm_fatal("FATAL_ROUTING_SEQ", "Couldn't get the bus matrix from config_db")
  end
  
  `uvm_info("ROUTING_SEQ", "Starting transaction routing sequence", UVM_LOW)
  
  // Start routing transactions
  route_master_transactions();
  
endtask : body

//--------------------------------------------------------------------------------------------
// Task: route_master_transactions
//--------------------------------------------------------------------------------------------
task axi4_routing_sequence::route_master_transactions();
  
  // Fork parallel handlers for all masters
  fork
    forever handle_master_read(0);
    forever handle_master_read(1);
    forever handle_master_read(2);
    forever handle_master_read(3);
    forever handle_master_read(4);
    forever handle_master_read(5);
    forever handle_master_read(6);
    forever handle_master_read(7);
    forever handle_master_read(8);
    forever handle_master_read(9);
    
    forever handle_master_write(0);
    forever handle_master_write(1);
    forever handle_master_write(2);
    forever handle_master_write(3);
    forever handle_master_write(4);
    forever handle_master_write(5);
    forever handle_master_write(6);
    forever handle_master_write(7);
    forever handle_master_write(8);
    forever handle_master_write(9);
  join
  
endtask : route_master_transactions

//--------------------------------------------------------------------------------------------
// Task: handle_master_read
//--------------------------------------------------------------------------------------------
task axi4_routing_sequence::handle_master_read(int master_id);
  // This would monitor master read transactions and route them
  // For now, this is a placeholder
  #100;
endtask : handle_master_read

//--------------------------------------------------------------------------------------------
// Task: handle_master_write
//--------------------------------------------------------------------------------------------
task axi4_routing_sequence::handle_master_write(int master_id);
  // This would monitor master write transactions and route them
  // For now, this is a placeholder
  #100;
endtask : handle_master_write

`endif