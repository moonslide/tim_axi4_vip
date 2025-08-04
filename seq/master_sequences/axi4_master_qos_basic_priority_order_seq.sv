`ifndef AXI4_MASTER_QOS_BASIC_PRIORITY_ORDER_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_BASIC_PRIORITY_ORDER_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_basic_priority_order_seq
// Sequence to verify basic QoS priority ordering
// Generates multiple read requests with different QoS values to same slave
//--------------------------------------------------------------------------------------------
class axi4_master_qos_basic_priority_order_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_master_qos_basic_priority_order_seq)
  
  // Transaction handle
  axi4_master_tx req;
  
  // Master and slave IDs for this sequence
  int master_id;
  int slave_id;
  
  // QoS values for the test
  bit [3:0] qos_values[4] = '{4'h2, 4'h8, 4'h4, 4'hC};
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_qos_basic_priority_order_seq");
  extern virtual task body();
  
endclass : axi4_master_qos_basic_priority_order_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_qos_basic_priority_order_seq::new(string name = "axi4_master_qos_basic_priority_order_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Main sequence body - generates 4 read requests with different QoS values
//-----------------------------------------------------------------------------
task axi4_master_qos_basic_priority_order_seq::body();
  super.body();
  
  // Get master and slave IDs from configuration
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    master_id = 0; // Default to master 0
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    slave_id = 2; // Default to slave 2 as per test plan
  end
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS basic priority test - Master %0d to Slave %0d", master_id, slave_id), UVM_MEDIUM)
  
  // Generate 4 simultaneous read requests with different QoS values
  for (int i = 0; i < 4; i++) begin
    `uvm_do_with(req, {
      req.tx_type == READ;
      req.araddr == (slave_id == 2) ? 64'h0000_0008_8000_0000 + (i * 'h1000) : 64'h0000_0008_0000_0000 + (i * 'h1000); // S2 address range
      req.arid == arid_e'(master_id % 16);
      req.arlen == 0; // Single beat transaction
      req.arsize == READ_8_BYTES;
      req.arburst == READ_INCR;
      req.arqos == qos_values[i];
    })
    
    `uvm_info(get_type_name(), $sformatf("Sent read request %0d: ARADDR=0x%0h, ARQOS=0x%0h", i, req.araddr, req.arqos), UVM_HIGH)
  end
  
  `uvm_info(get_type_name(), "QoS basic priority test sequence completed", UVM_MEDIUM)
  
endtask : body

`endif