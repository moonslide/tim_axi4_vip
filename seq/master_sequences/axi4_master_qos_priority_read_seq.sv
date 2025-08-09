`ifndef AXI4_MASTER_QOS_PRIORITY_READ_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_PRIORITY_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_priority_read_seq
// Generates read transactions with configurable QoS priority values
//--------------------------------------------------------------------------------------------
class axi4_master_qos_priority_read_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_qos_priority_read_seq)

  // Variable: qos_value
  // Configurable QoS value for priority testing
  bit [3:0] qos_value = 4'b0000;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_qos_priority_read_seq");
  extern task body();

endclass : axi4_master_qos_priority_read_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi4_master_qos_priority_read_seq
//--------------------------------------------------------------------------------------------
function axi4_master_qos_priority_read_seq::new(string name = "axi4_master_qos_priority_read_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates read transaction with specific QoS value for priority testing
//--------------------------------------------------------------------------------------------
task axi4_master_qos_priority_read_seq::body();
  super.body();
  
  start_item(req);
  
  if(!req.randomize() with {
    req.tx_type == READ;
    req.transfer_type == NON_BLOCKING_READ;
    req.arqos == local::qos_value;
    req.arburst == READ_INCR;
    req.arsize == READ_4_BYTES;
    req.arlen == 8'h00;  // Single beat burst to simplify
    req.araddr inside {[64'h8_0000_0000:64'h8_3FFF_FFF0],  // Slave 0 (General Purpose 0) - aligned
                        [64'h8_4000_0000:64'h8_7FFF_FFF0],  // Slave 1 (General Purpose 1) - aligned
                        [64'h8_8000_0000:64'h8_BFFF_FFF0],  // Slave 2 (High Speed) - aligned
                        [64'h9_0000_0000:64'h9_3FFF_FFF0],  // Slave 4 (Instruction ROM) - aligned
                        [64'hA_0000_0000:64'hA_0000_FFF0],  // Slave 5 (Boot ROM) - aligned
                        [64'hA_0001_0000:64'hA_0001_FFF0],  // Slave 6 (Control Reg 0) - aligned
                        [64'hA_0002_0000:64'hA_0002_FFF0],  // Slave 7 (Control Reg 1) - aligned
                        [64'hA_0003_0000:64'hA_0003_FFF0]};  // Slave 8 (Control Reg 2) - aligned
  }) begin
    `uvm_fatal("axi4", "Randomization failed for QoS priority read sequence")
  end
  
  `uvm_info(get_type_name(), $sformatf("QoS Priority Read - QoS Value: %0h, Address: %0h", 
            req.arqos, req.araddr), UVM_MEDIUM)
  
  finish_item(req);
  
endtask : body

`endif