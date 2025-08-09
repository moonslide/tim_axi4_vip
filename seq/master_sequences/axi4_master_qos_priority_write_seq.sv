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
  super.body();
  
  start_item(req);
  
  if(!req.randomize() with {
    req.tx_type == WRITE;
    req.transfer_type == NON_BLOCKING_WRITE;
    req.awqos == local::qos_value;
    req.awburst == WRITE_INCR;
    req.awsize == WRITE_4_BYTES;
    req.awlen == 8'h00;  // Single beat burst to simplify
    req.awaddr inside {[64'h8_0000_0000:64'h8_3FFF_FFF0],  // Slave 0 (General Purpose 0) - aligned
                        [64'h8_4000_0000:64'h8_7FFF_FFF0],  // Slave 1 (General Purpose 1) - aligned
                        [64'h8_8000_0000:64'h8_BFFF_FFF0],  // Slave 2 (High Speed) - aligned
                        [64'hA_0001_0000:64'hA_0001_FFF0],  // Slave 6 (Control Reg 0) - aligned
                        [64'hA_0002_0000:64'hA_0002_FFF0],  // Slave 7 (Control Reg 1) - aligned
                        [64'hA_0003_0000:64'hA_0003_FFF0]};  // Slave 8 (Control Reg 2) - aligned
  }) begin
    `uvm_fatal("axi4", "Randomization failed for QoS priority write sequence")
  end
  
  `uvm_info(get_type_name(), $sformatf("QoS Priority Write - QoS Value: %0h, Address: %0h", 
            req.awqos, req.awaddr), UVM_MEDIUM)
  
  finish_item(req);
  
endtask : body

`endif