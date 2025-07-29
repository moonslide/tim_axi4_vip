`ifndef AXI4_SLAVE_BASE_SEQ_INCLUDED_
`define AXI4_SLAVE_BASE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_base_seq 
// creating axi4_slave_base_seq class extends from uvm_sequence
//--------------------------------------------------------------------------------------------
class axi4_slave_base_seq extends uvm_sequence #(axi4_slave_tx);
 
  //factory registration
  `uvm_object_utils(axi4_slave_base_seq)

  //-------------------------------------------------------
  // Externally defined Function
  //-------------------------------------------------------
  extern function new(string name = "axi4_slave_base_seq");
  extern virtual task body();
endclass : axi4_slave_base_seq

//-----------------------------------------------------------------------------
// Constructor: new
// Initializes the axi4_slave_sequence class object
//
// Parameters:
//  name - instance name of the config_template
//-----------------------------------------------------------------------------
function axi4_slave_base_seq::new(string name = "axi4_slave_base_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Empty body task for base sequence (to be overridden by derived sequences)
//-----------------------------------------------------------------------------
task axi4_slave_base_seq::body();
  // Base sequence body is empty - derived sequences override this
endtask : body

`endif
