`ifndef AXI4_MASTER_QOS_STARVATION_PREVENTION_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_STARVATION_PREVENTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_starvation_prevention_seq  
// Generates mixed priority traffic to verify lower priority transactions eventually complete
// Tests that QoS arbitration doesn't cause starvation of low priority traffic
//--------------------------------------------------------------------------------------------
class axi4_master_qos_starvation_prevention_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_qos_starvation_prevention_seq)
  
  // Configuration parameters
  int master_id = 0;
  int slave_id = 2;
  int num_low_priority_txns;
  int num_high_priority_txns;
  bit [3:0] low_qos_value = 4'h1;    // Low priority
  bit [3:0] high_qos_value = 4'hE;   // High priority
  
  // Transaction tracking
  int low_priority_sent = 0;
  int high_priority_sent = 0;
  
  // Transaction parameters
  rand bit [ADDRESS_WIDTH-1:0] base_addr;
  
  constraint base_addr_c {
    base_addr == (slave_id == 2) ? 64'h0000_0008_8000_0000 : 64'h0000_0008_0000_0000;
  }
  
  extern function new(string name = "axi4_master_qos_starvation_prevention_seq");
  extern virtual task body();
  extern virtual task generate_low_priority_burst();
  extern virtual task generate_high_priority_burst();
  extern virtual task generate_mixed_priority_transaction(int txn_id, bit [3:0] qos_val, string priority_str);
  
endclass : axi4_master_qos_starvation_prevention_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_qos_starvation_prevention_seq::new(string name = "axi4_master_qos_starvation_prevention_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Generates interleaved high and low priority traffic to test starvation prevention
//-----------------------------------------------------------------------------
task axi4_master_qos_starvation_prevention_seq::body();
  
  super.body();
  
  // Get configuration from config_db
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    `uvm_info(get_type_name(), "Using default master_id = 0", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    `uvm_info(get_type_name(), "Using default slave_id = 2", UVM_MEDIUM)
  end
  
  // Dynamically scale transaction counts based on system configuration
  // This prevents overload when multiple masters are active
  begin
    int total_masters;
    if (!uvm_config_db#(int)::get(null, "uvm_test_top.env", "no_of_masters", total_masters)) begin
      total_masters = 2; // Default assumption
    end
    
    // Scale down transactions as more masters participate
    case (total_masters)
      2: begin
        num_low_priority_txns = 10;
        num_high_priority_txns = 5;
      end
      3: begin
        num_low_priority_txns = 8;
        num_high_priority_txns = 4;
      end
      4: begin
        num_low_priority_txns = 6;
        num_high_priority_txns = 3;
      end
      default: begin
        num_low_priority_txns = 20 / total_masters;
        num_high_priority_txns = 10 / total_masters;
        if (num_low_priority_txns < 2) num_low_priority_txns = 2;
        if (num_high_priority_txns < 1) num_high_priority_txns = 1;
      end
    endcase
  end
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS starvation prevention sequence: Master[%0d] → Slave[%0d]", master_id, slave_id), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Low priority transactions: %0d (QoS=0x%0h), High priority: %0d (QoS=0x%0h)", 
                                        num_low_priority_txns, low_qos_value, num_high_priority_txns, high_qos_value), UVM_MEDIUM)
  
  // Generate mixed traffic pattern to test starvation prevention
  fork
    // Start with low priority background traffic
    generate_low_priority_burst();
    
    // Inject high priority bursts periodically
    begin
      repeat (4) begin
        #500; // Wait for some low priority traffic to build up
        generate_high_priority_burst();
        #200; // Brief pause between high priority bursts
      end
    end
  join
  
  `uvm_info(get_type_name(), $sformatf("QoS starvation prevention sequence completed: Low=%0d, High=%0d transactions", 
                                        low_priority_sent, high_priority_sent), UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Task: generate_low_priority_burst
// Generates continuous low priority transactions
//-----------------------------------------------------------------------------
task axi4_master_qos_starvation_prevention_seq::generate_low_priority_burst();
  
  while (low_priority_sent < num_low_priority_txns) begin
    generate_mixed_priority_transaction(low_priority_sent, low_qos_value, "LOW");
    low_priority_sent++;
    
    // Small delay between low priority transactions
    #($urandom_range(50, 100));
  end
  
endtask : generate_low_priority_burst

//-----------------------------------------------------------------------------
// Task: generate_high_priority_burst
// Generates bursts of high priority transactions
//-----------------------------------------------------------------------------
task axi4_master_qos_starvation_prevention_seq::generate_high_priority_burst();
  int burst_size = $urandom_range(3, 7);
  
  `uvm_info(get_type_name(), $sformatf("Injecting high priority burst of %0d transactions", burst_size), UVM_HIGH)
  
  for (int i = 0; i < burst_size && high_priority_sent < num_high_priority_txns; i++) begin
    generate_mixed_priority_transaction(high_priority_sent, high_qos_value, "HIGH");
    high_priority_sent++;
    
    // Rapid fire high priority transactions
    #($urandom_range(10, 30));
  end
  
endtask : generate_high_priority_burst

//-----------------------------------------------------------------------------
// Task: generate_mixed_priority_transaction
// Creates a transaction with specified QoS priority
//-----------------------------------------------------------------------------
task axi4_master_qos_starvation_prevention_seq::generate_mixed_priority_transaction(int txn_id, bit [3:0] qos_val, string priority_str);
  
  int burst_len;
  
  // Force single-beat transactions for OR-logic interconnect
  burst_len = 0;
  
  // Alternate between read and write based on transaction ID
  if (txn_id & 1) begin
    // Generate write transaction
    `uvm_do_with(req, {
      req.tx_type == WRITE;
      req.awaddr == base_addr + (txn_id * 'h200) + (qos_val << 12);
      req.awid == awid_e'(master_id % 16);
      req.awlen == burst_len;
      req.awsize == WRITE_8_BYTES;
      req.awburst == WRITE_INCR;
      req.awqos == qos_val;
      req.awuser == 32'h5A5A0000 | (qos_val << 16) | (master_id << 8) | txn_id[7:0];
    })
    
    `uvm_info(get_type_name(), $sformatf("%s priority WRITE: ID=%0d, QoS=0x%0h, Addr=0x%0h", 
                                          priority_str, txn_id, qos_val, base_addr + (txn_id * 'h200) + (qos_val << 12)), UVM_HIGH)
  end
  else begin
    // Generate read transaction  
    `uvm_do_with(req, {
      req.tx_type == READ;
      req.araddr == base_addr + (txn_id * 'h200) + (qos_val << 12);
      req.arid == arid_e'(master_id % 16);
      req.arlen == burst_len;
      req.arsize == READ_8_BYTES;
      req.arburst == READ_INCR;
      req.arqos == qos_val;
      req.aruser == 32'hA5A50000 | (qos_val << 16) | (master_id << 8) | txn_id[7:0];
    })
    
    `uvm_info(get_type_name(), $sformatf("%s priority READ: ID=%0d, QoS=0x%0h, Addr=0x%0h", 
                                          priority_str, txn_id, qos_val, base_addr + (txn_id * 'h200) + (qos_val << 12)), UVM_HIGH)
  end
  
endtask : generate_mixed_priority_transaction

`endif