`ifndef AXI4_MASTER_QOS_EQUAL_PRIORITY_FAIRNESS_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_EQUAL_PRIORITY_FAIRNESS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_equal_priority_fairness_seq
// Sequence to verify fair arbitration for equal QoS values
// Generates continuous traffic with same QoS from this master
//--------------------------------------------------------------------------------------------
class axi4_master_qos_equal_priority_fairness_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_master_qos_equal_priority_fairness_seq)
  
  // Transaction handle
  axi4_master_tx req;
  
  // Master and slave IDs for this sequence
  int master_id;
  int slave_id;
  
  // Test parameters
  bit [3:0] qos_value = 4'h8; // All masters use same QoS
  int num_transactions = 20;   // Reduced transactions per master for 10 masters (20*10=200 total)
  int inter_transaction_delay = 200; // Increased delay to prevent congestion with 10 masters
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_qos_equal_priority_fairness_seq");
  extern virtual task body();
  extern function bit [ADDRESS_WIDTH-1:0] calculate_slave_address(int slave_id);
  
endclass : axi4_master_qos_equal_priority_fairness_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_qos_equal_priority_fairness_seq::new(string name = "axi4_master_qos_equal_priority_fairness_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Main sequence body - generates continuous traffic with equal QoS
//-----------------------------------------------------------------------------
task axi4_master_qos_equal_priority_fairness_seq::body();
  string transaction_type;
  super.body();
  
  // Get master and slave IDs from configuration
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    master_id = 0; // Default to master 0
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    slave_id = 2; // Default to slave 2
  end
  
  // Add initial delay based on master ID to stagger start times
  // With 10 masters, use smaller stagger to avoid too much spread
  #(master_id * 200ns);
  
  // Get test parameters from config if available
  void'(uvm_config_db#(bit [3:0])::get(null, get_full_name(), "qos_value", qos_value));
  void'(uvm_config_db#(int)::get(null, get_full_name(), "num_transactions", num_transactions));
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS equal priority fairness test - Master %0d to Slave %0d with QoS=0x%0h", 
                                       master_id, slave_id, qos_value), UVM_MEDIUM)
  
  // Generate continuous traffic - alternate between read and write based on master ID
  for (int i = 0; i < num_transactions; i++) begin
    // Even masters generate write transactions, odd masters generate read transactions
    if (master_id % 2 == 0) begin
      // Write transaction
      `uvm_do_with(req, {
        req.tx_type == WRITE;
        req.awaddr == calculate_slave_address(slave_id) + (i * 'h1000) + (master_id * 'h100);
        req.awid == awid_e'(master_id % 16);
        req.awlen inside {[0:7]};  // Reduced burst length to prevent congestion
        req.awsize == WRITE_8_BYTES;
        req.awburst == WRITE_INCR;
        req.awqos == qos_value;
      })
    end
    else begin
      // Read transaction  
      `uvm_do_with(req, {
        req.tx_type == READ;
        req.araddr == calculate_slave_address(slave_id) + (i * 'h1000) + (master_id * 'h100);
        req.arid == arid_e'(master_id % 16);
        req.arlen inside {[0:7]};  // Reduced burst length to prevent congestion
        req.arsize == READ_8_BYTES;
        req.arburst == READ_INCR;
        req.arqos == qos_value;
      })
    end
    
    // Adaptive delay between transactions to avoid overwhelming the bus
    // With 10 masters, we need more conservative pacing
    if (i % 5 == 0 && i > 0) begin
      // Every 5 transactions, add a longer delay for pipeline clearing
      #(inter_transaction_delay * 20ns);  // Assuming 10ns clock period
    end else begin
      // Normal inter-transaction delay with 10 masters
      #(inter_transaction_delay * 10ns);  // Assuming 10ns clock period
    end
  end
  
  `uvm_info(get_type_name(), $sformatf("QoS equal priority fairness test completed - sent %0d transactions", num_transactions), UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Function: calculate_slave_address
// Calculate base address for slave based on slave ID
//-----------------------------------------------------------------------------
function bit [ADDRESS_WIDTH-1:0] axi4_master_qos_equal_priority_fairness_seq::calculate_slave_address(int slave_id);
  case(slave_id)
    0: return 64'h0000_0000_0000_0000; // S0: Secure Kernel
    1: return 64'h0000_0004_0000_0000; // S1: Non-Secure App
    2: return 64'h0000_0008_0000_0000; // S2: DMA target
    3: return 64'h0000_000C_0000_0000; // S3: Compute Engine
    4: return 64'h0000_0010_0000_0000; // S4: XOM
    5: return 64'h0000_0014_0000_0000; // S5: Shared Memory
    6: return 64'h0000_0018_0000_0000; // S6: Privileged-Only
    7: return 64'h0000_001C_0000_0000; // S7: Secure-Only
    8: return 64'h0000_0020_0000_0000; // S8: Peripheral
    9: return 64'h0000_0024_0000_0000; // S9: Attribute Monitor
    default: return 64'h0000_0008_0000_0000; // Default to S2
  endcase
endfunction : calculate_slave_address

`endif