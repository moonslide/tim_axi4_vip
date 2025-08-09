`ifndef AXI4_MASTER_QOS_PRIORITY_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_PRIORITY_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_priority_write_seq
// Generates write transactions with configurable QoS priority values
//--------------------------------------------------------------------------------------------
class axi4_master_qos_priority_write_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_qos_priority_write_seq)

  // Variable: qos_value
  // Configurable QoS value for priority testing
  bit [3:0] qos_value = 4'b0000;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_qos_priority_write_seq");
  extern task body();

endclass : axi4_master_qos_priority_write_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi4_master_qos_priority_write_seq
//--------------------------------------------------------------------------------------------
function axi4_master_qos_priority_write_seq::new(string name = "axi4_master_qos_priority_write_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates write transaction with specific QoS value for priority testing
//--------------------------------------------------------------------------------------------
task axi4_master_qos_priority_write_seq::body();
  int target_slave_id;
  super.body();
  
  start_item(req);
  
  // For ultrathink 10x10 configuration, use proper address mapping
  // Each slave has 256MB (0x1000_0000) of address space starting from base 0x0100_0000_0000
  target_slave_id = $urandom_range(0, 9); // Select random slave 0-9 for 10x10 matrix
  
  if(!req.randomize() with {
    req.tx_type == WRITE;
    req.transfer_type == NON_BLOCKING_WRITE;
    req.awqos == local::qos_value;
    req.awburst == WRITE_INCR;
    req.awsize == WRITE_4_BYTES;
    req.awlen == 8'h00;  // Single beat burst to simplify
    req.awaddr == 64'h0000_0100_0000_0000 + (local::target_slave_id * 64'h1000_0000);
  }) begin
    `uvm_fatal("axi4", "Randomization failed for QoS priority write sequence")
  end
  
  `uvm_info(get_type_name(), $sformatf("QoS Priority Write - QoS Value: %0h, Address: %0h", 
            req.awqos, req.awaddr), UVM_MEDIUM)
  
  finish_item(req);
  
endtask : body

`endif