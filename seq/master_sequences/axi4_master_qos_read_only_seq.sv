`ifndef AXI4_MASTER_QOS_READ_ONLY_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_READ_ONLY_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_read_only_seq
// Dedicated read-only sequence for QoS equal priority fairness test
// This sequence ONLY generates READ transactions
//--------------------------------------------------------------------------------------------
class axi4_master_qos_read_only_seq extends axi4_master_base_seq;

  `uvm_object_utils(axi4_master_qos_read_only_seq)
  
  // Transaction handle
  axi4_master_tx req;
  
  // Master and slave IDs for this sequence
  int master_id;
  int slave_id;
  
  // Test parameters
  bit [3:0] qos_value = 4'h8; // All masters use same QoS
  int num_transactions = 10;   // Further reduced for proper response handling (10*10=100 total)
  int inter_transaction_delay = 500; // Much longer delay to allow read response processing
  
  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_qos_read_only_seq");
  extern virtual task body();
  extern function bit [ADDRESS_WIDTH-1:0] calculate_slave_address(int slave_id);
  
endclass : axi4_master_qos_read_only_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_qos_read_only_seq::new(string name = "axi4_master_qos_read_only_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Main sequence body - generates READ transactions ONLY
//-----------------------------------------------------------------------------
task axi4_master_qos_read_only_seq::body();
  super.body();
  
  // Get master and slave IDs from configuration
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    master_id = 1; // Default to odd master ID for read
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    slave_id = 2; // Default to slave 2
  end
  
  // Add initial delay based on master ID to stagger start times
  #(master_id * 200ns);
  
  // Get test parameters from config if available
  void'(uvm_config_db#(bit [3:0])::get(null, get_full_name(), "qos_value", qos_value));
  void'(uvm_config_db#(int)::get(null, get_full_name(), "num_transactions", num_transactions));
  
  `uvm_info(get_type_name(), $sformatf("Starting READ-ONLY QoS sequence - Master %0d to Slave %0d with QoS=0x%0h", 
                                       master_id, slave_id, qos_value), UVM_MEDIUM)
  
  // Generate READ transactions ONLY
  for (int i = 0; i < num_transactions; i++) begin
    // Create and send read transaction using proper UVM sequence protocol
    req = axi4_master_tx::type_id::create("req");
    
    start_item(req);
    if(!req.randomize() with {
      req.tx_type == READ;
      req.araddr == calculate_slave_address(slave_id) + (i * 'h1000) + (master_id * 'h100);
      req.arid == arid_e'(master_id % 16);
      req.arlen == 0;  // Force single-beat transactions only
      req.arsize == READ_8_BYTES;
      req.arburst == READ_INCR;
      req.arqos == qos_value;
    }) begin
      `uvm_error(get_type_name(), "Failed to randomize read transaction")
    end
    
    finish_item(req);
    
    // Inter-transaction delay for flow control
    if (i % 5 == 0 && i > 0) begin
      // Every 5 transactions, add a longer delay for pipeline clearing
      #(inter_transaction_delay * 20ns);
    end else begin
      // Normal inter-transaction delay
      #(inter_transaction_delay * 10ns);
    end
  end
  
  `uvm_info(get_type_name(), $sformatf("READ-ONLY QoS sequence completed - sent %0d read transactions", num_transactions), UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Function: calculate_slave_address
// Calculate base address for slave based on slave ID
//-----------------------------------------------------------------------------
function bit [ADDRESS_WIDTH-1:0] axi4_master_qos_read_only_seq::calculate_slave_address(int slave_id);
  // Enhanced bus matrix address mapping - must match axi4_bus_matrix_ref.sv configuration
  case(slave_id)
    0: return 64'h0000_0008_0000_0000; // S0: DDR Secure Kernel
    1: return 64'h0000_0008_4000_0000; // S1: DDR Non-Secure User
    2: return 64'h0000_0008_8000_0000; // S2: DDR Shared Buffer
    3: return 64'h0000_0008_C000_0000; // S3: Illegal Address Hole (will return DECERR)
    4: return 64'h0000_0009_0000_0000; // S4: XOM Instruction-Only
    5: return 64'h0000_000A_0000_0000; // S5: RO Peripheral
    6: return 64'h0000_000A_0001_0000; // S6: Privileged-Only
    7: return 64'h0000_000A_0002_0000; // S7: Secure-Only
    8: return 64'h0000_000A_0003_0000; // S8: Scratchpad
    9: return 64'h0000_000A_0004_0000; // S9: Attribute Monitor (write-only, will return SLVERR on read)
    default: return 64'h0000_0008_8000_0000; // Default to S2: DDR Shared Buffer
  endcase
endfunction : calculate_slave_address

`endif