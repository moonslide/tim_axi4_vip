`ifndef AXI4_MASTER_QOS_MULTI_ID_ARBITRATION_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_MULTI_ID_ARBITRATION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_multi_id_arbitration_seq
// Sequence to verify QoS applies correctly across different IDs
// Issues writes with alternating IDs and QoS values
//--------------------------------------------------------------------------------------------
class axi4_master_qos_multi_id_arbitration_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_master_qos_multi_id_arbitration_seq)
  
  // Transaction handle
  axi4_master_tx req;
  
  // Master and slave IDs for this sequence
  int master_id;
  int slave_id;
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_qos_multi_id_arbitration_seq");
  extern virtual task body();
  
endclass : axi4_master_qos_multi_id_arbitration_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_qos_multi_id_arbitration_seq::new(string name = "axi4_master_qos_multi_id_arbitration_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Main sequence body - generates writes with alternating IDs and QoS
//-----------------------------------------------------------------------------
task axi4_master_qos_multi_id_arbitration_seq::body();
  bit [63:0] base_addr;
  
  super.body();
  
  // Get master and slave IDs from configuration
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    master_id = 5; // Default to master 5
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    slave_id = 8; // Default to slave 8
  end
  
  // Base address for slave
  base_addr = (slave_id == 8) ? 64'h0000_000A_0003_0000 : 64'h0000_0008_0000_0000;
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS multi-ID arbitration test - Master %0d to Slave %0d", master_id, slave_id), UVM_MEDIUM)
  
  // Transaction 1: ID=1, Low QoS (0x4)
  `uvm_do_with(req, {
    req.tx_type == WRITE;
    req.awaddr == base_addr + 'h1000;
    req.awid == awid_e'(1);
    req.awlen == 1; // 2-beat burst
    req.awsize == WRITE_8_BYTES;
    req.awburst == WRITE_INCR;
    req.awqos == 4'h4;
    foreach(req.wdata[i]) req.wdata[i] == 64'hAAAA_AAAA_0000_0001 + i;
  })
  `uvm_info(get_type_name(), $sformatf("Sent Txn1: AWID=%0d, AWQOS=0x%0h", req.awid, req.awqos), UVM_HIGH)
  
  #5;
  
  // Transaction 2: ID=2, High QoS (0xC)
  `uvm_do_with(req, {
    req.tx_type == WRITE;
    req.awaddr == base_addr + 'h2000;
    req.awid == awid_e'(2);
    req.awlen == 1; // 2-beat burst
    req.awsize == WRITE_8_BYTES;
    req.awburst == WRITE_INCR;
    req.awqos == 4'hC;
    foreach(req.wdata[i]) req.wdata[i] == 64'hBBBB_BBBB_0000_0001 + i;
  })
  `uvm_info(get_type_name(), $sformatf("Sent Txn2: AWID=%0d, AWQOS=0x%0h", req.awid, req.awqos), UVM_HIGH)
  
  #5;
  
  // Transaction 3: ID=1, Low QoS (0x4)
  `uvm_do_with(req, {
    req.tx_type == WRITE;
    req.awaddr == base_addr + 'h3000;
    req.awid == awid_e'(1);
    req.awlen == 1; // 2-beat burst
    req.awsize == WRITE_8_BYTES;
    req.awburst == WRITE_INCR;
    req.awqos == 4'h4;
    foreach(req.wdata[i]) req.wdata[i] == 64'hCCCC_CCCC_0000_0001 + i;
  })
  `uvm_info(get_type_name(), $sformatf("Sent Txn3: AWID=%0d, AWQOS=0x%0h", req.awid, req.awqos), UVM_HIGH)
  
  #5;
  
  // Transaction 4: ID=2, High QoS (0xC)
  `uvm_do_with(req, {
    req.tx_type == WRITE;
    req.awaddr == base_addr + 'h4000;
    req.awid == awid_e'(2);
    req.awlen == 1; // 2-beat burst
    req.awsize == WRITE_8_BYTES;
    req.awburst == WRITE_INCR;
    req.awqos == 4'hC;
    foreach(req.wdata[i]) req.wdata[i] == 64'hDDDD_DDDD_0000_0001 + i;
  })
  `uvm_info(get_type_name(), $sformatf("Sent Txn4: AWID=%0d, AWQOS=0x%0h", req.awid, req.awqos), UVM_HIGH)
  
  `uvm_info(get_type_name(), "QoS multi-ID arbitration test completed - ID=2 transactions should get priority", UVM_MEDIUM)
  
endtask : body

`endif