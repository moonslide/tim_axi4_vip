`ifndef AXI4_MASTER_NBK_TARGETED_WRITE_QOS_SEQ_INCLUDED_
`define AXI4_MASTER_NBK_TARGETED_WRITE_QOS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_nbk_targeted_write_qos_seq
// Extends the axi4_master_nbk_base_seq for targeted address generation with QoS
//--------------------------------------------------------------------------------------------
class axi4_master_nbk_targeted_write_qos_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_nbk_targeted_write_qos_seq)

  // Configuration parameters
  bit [63:0] target_addr = 64'h0;
  bit [63:0] target_size = 64'h100;
  string awid_val = "AWID_0";
  int master_id = 0;
  int target_slave = 0;
  bit is_enhanced_mode = 0;
  bit is_4x4_ref_mode = 0;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_nbk_targeted_write_qos_seq");
  extern task body();
endclass : axi4_master_nbk_targeted_write_qos_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi4_master_nbk_targeted_write_qos_seq
//--------------------------------------------------------------------------------------------
function axi4_master_nbk_targeted_write_qos_seq::new(string name = "axi4_master_nbk_targeted_write_qos_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates the req of type master transaction with targeted address
//--------------------------------------------------------------------------------------------
task axi4_master_nbk_targeted_write_qos_seq::body();
  super.body();

  start_item(req);
  
  // Basic transaction constraints
  if(!req.randomize() with {  
    req.tx_type == WRITE;
    req.transfer_type == NON_BLOCKING_WRITE;
    req.awaddr == target_addr;
    req.awsize == 3'b011; // 8 bytes
    req.awlen == 8'h0;    // Single transfer
    req.awburst == WRITE_INCR;
  }) begin
    `uvm_fatal("axi4","Rand failed");
  end
  
  // Set AWID after randomization
  req.awid = awid_val;
  
  // Set QoS based on master priority (higher master ID = higher priority)
  req.awqos = master_id[3:0];
  
  `uvm_info(get_type_name(), $sformatf("NBK Targeted Write: Master=%0d, Slave=%0d, Addr=0x%h, AWID=%s, QoS=%0d", 
                                       master_id, target_slave, req.awaddr, req.awid, req.awqos), UVM_MEDIUM); 
  
  finish_item(req);

endtask : body

`endif