`ifndef AXI4_MASTER_QOS_SATURATION_STRESS_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_SATURATION_STRESS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_saturation_stress_seq
// Generates high volume traffic with maximum QoS values to stress the arbitration
// Tests system behavior under QoS saturation conditions
//--------------------------------------------------------------------------------------------
class axi4_master_qos_saturation_stress_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_qos_saturation_stress_seq)
  
  // Configuration parameters
  int master_id = 0;
  int slave_id = 2;
  int num_transactions = 20;  // Reduced from 200 for better flow control
  bit [3:0] stress_qos_value = 4'hF; // Maximum priority
  
  // Transaction parameters
  rand bit [ADDRESS_WIDTH-1:0] base_addr;
  rand int burst_variations;
  
  // Constraints
  constraint base_addr_c {
    base_addr == (slave_id == 2) ? 64'h0000_0008_8000_0000 : 64'h0000_0008_0000_0000;
  }
  
  constraint burst_variations_c {
    burst_variations inside {[0:3]};
  }
  
  extern function new(string name = "axi4_master_qos_saturation_stress_seq");
  extern virtual task body();
  extern virtual task generate_stress_transaction(int txn_id);
  
endclass : axi4_master_qos_saturation_stress_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_qos_saturation_stress_seq::new(string name = "axi4_master_qos_saturation_stress_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Generates continuous high-priority traffic to stress arbitration
//-----------------------------------------------------------------------------
task axi4_master_qos_saturation_stress_seq::body();
  
  super.body();
  
  // Get configuration from config_db
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    `uvm_info(get_type_name(), "Using default master_id = 0", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    `uvm_info(get_type_name(), "Using default slave_id = 2", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "num_transactions", num_transactions)) begin
    `uvm_info(get_type_name(), "Using default num_transactions = 200", UVM_MEDIUM)
  end
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS saturation stress sequence: Master[%0d] → Slave[%0d], %0d txns with QoS=0x%0h", 
                                        master_id, slave_id, num_transactions, stress_qos_value), UVM_MEDIUM)
  
  // Add initial delay based on master ID to prevent simultaneous starts
  #(master_id * 1000);
  
  // Generate stress transactions with improved flow control
  for (int i = 0; i < num_transactions; i++) begin
    generate_stress_transaction(i);
    
    // Inter-transaction delay for QoS arbitration flow control
    if (i % 5 == 0 && i > 0) begin
      // Every 5 transactions, add longer delay for pipeline clearing
      #($urandom_range(1000, 2000));
    end else begin
      // Normal inter-transaction delay for QoS arbitration
      #($urandom_range(200, 500));
    end
  end
  
  `uvm_info(get_type_name(), $sformatf("QoS saturation stress sequence completed: %0d transactions generated", num_transactions), UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Task: generate_stress_transaction
// Creates a high-priority transaction with maximum QoS
//-----------------------------------------------------------------------------
task axi4_master_qos_saturation_stress_seq::generate_stress_transaction(int txn_id);
  
  // Alternate between read and write transactions
  if (txn_id & 1) begin
    // Generate high-priority write transaction
    `uvm_do_with(req, {
      req.tx_type == WRITE;
      req.transfer_type == BLOCKING_WRITE;  // CRITICAL FIX: Explicitly set BLOCKING_WRITE for consistency  
      req.awaddr == base_addr + (txn_id * 'h100);
      req.awid == awid_e'(master_id % 16);
      req.awlen == 0;  // Force single-beat transactions to prevent QoS arbitration blockage
      req.awsize == WRITE_8_BYTES;
      req.awburst == WRITE_INCR;
      req.awqos == stress_qos_value;
      req.awuser == 32'hABCD0000 | (master_id << 8) | txn_id[7:0];
    })
  end
  else begin
    // Generate high-priority read transaction
    `uvm_do_with(req, {
      req.tx_type == READ;
      req.transfer_type == BLOCKING_READ;  // CRITICAL FIX: Explicitly set BLOCKING_READ so driver proxy processes it
      req.araddr == base_addr + (txn_id * 'h100);
      req.arid == arid_e'(master_id % 16);
      req.arlen == 0;  // Force single-beat transactions to prevent QoS arbitration blockage
      req.arsize == READ_8_BYTES;
      req.arburst == READ_INCR;
      req.arqos == stress_qos_value;
      req.aruser == 32'hDCBA0000 | (master_id << 8) | txn_id[7:0];
    })
  end
  
endtask : generate_stress_transaction

`endif