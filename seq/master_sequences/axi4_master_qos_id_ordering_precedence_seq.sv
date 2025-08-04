`ifndef AXI4_MASTER_QOS_ID_ORDERING_PRECEDENCE_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_ID_ORDERING_PRECEDENCE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_id_ordering_precedence_seq
// Sequence to verify that AxID ordering overrides QoS
// Issues multiple writes with same AWID but different QoS values
//--------------------------------------------------------------------------------------------
class axi4_master_qos_id_ordering_precedence_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_master_qos_id_ordering_precedence_seq)
  
  // Transaction handle
  axi4_master_tx req;
  
  // Master and slave IDs for this sequence
  int master_id;
  int slave_id;
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_qos_id_ordering_precedence_seq");
  extern virtual task body();
  
endclass : axi4_master_qos_id_ordering_precedence_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_qos_id_ordering_precedence_seq::new(string name = "axi4_master_qos_id_ordering_precedence_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Main sequence body - generates 3 writes with same AWID but different QoS
//-----------------------------------------------------------------------------
task axi4_master_qos_id_ordering_precedence_seq::body();
  super.body();
  
  // Get master and slave IDs from configuration
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    master_id = 5; // Default to master 5 as per test plan
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    slave_id = 8; // Default to slave 8 as per test plan
  end
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS ID ordering precedence test - Master %0d to Slave %0d", master_id, slave_id), UVM_MEDIUM)
  
  // Transaction 1: Low QoS (0x2)
  `uvm_do_with(req, {
    req.tx_type == WRITE;
    req.awaddr == 64'h0000_000A_0003_1000; // S8 address as per test plan
    req.awid == awid_e'(5);
    req.awlen == 3; // 4-beat burst
    req.awsize == WRITE_8_BYTES;
    req.awburst == WRITE_INCR;
    req.awqos == 4'h2;
    foreach(req.wdata[i]) req.wdata[i] == 64'h1111_1111_1111_0000 + i;
  })
  `uvm_info(get_type_name(), $sformatf("Sent Txn1: AWADDR=0x%0h, AWID=%0d, AWQOS=0x%0h", req.awaddr, req.awid, req.awqos), UVM_HIGH)
  
  // Small delay to ensure transactions are distinguishable
  #10;
  
  // Transaction 2: Highest QoS (0xF)
  `uvm_do_with(req, {
    req.tx_type == WRITE;
    req.awaddr == 64'h0000_000A_0003_2000; // S8 address as per test plan
    req.awid == awid_e'(5);
    req.awlen == 3; // 4-beat burst
    req.awsize == WRITE_8_BYTES;
    req.awburst == WRITE_INCR;
    req.awqos == 4'hF;
    foreach(req.wdata[i]) req.wdata[i] == 64'h2222_2222_2222_0000 + i;
  })
  `uvm_info(get_type_name(), $sformatf("Sent Txn2: AWADDR=0x%0h, AWID=%0d, AWQOS=0x%0h", req.awaddr, req.awid, req.awqos), UVM_HIGH)
  
  // Small delay
  #10;
  
  // Transaction 3: Medium QoS (0x8)
  `uvm_do_with(req, {
    req.tx_type == WRITE;
    req.awaddr == 64'h0000_000A_0003_3000; // S8 address as per test plan
    req.awid == awid_e'(5);
    req.awlen == 3; // 4-beat burst
    req.awsize == WRITE_8_BYTES;
    req.awburst == WRITE_INCR;
    req.awqos == 4'h8;
    foreach(req.wdata[i]) req.wdata[i] == 64'h3333_3333_3333_0000 + i;
  })
  `uvm_info(get_type_name(), $sformatf("Sent Txn3: AWADDR=0x%0h, AWID=%0d, AWQOS=0x%0h", req.awaddr, req.awid, req.awqos), UVM_HIGH)
  
  `uvm_info(get_type_name(), "QoS ID ordering precedence test completed - Expected order: Txn1, Txn2, Txn3", UVM_MEDIUM)
  
endtask : body

`endif