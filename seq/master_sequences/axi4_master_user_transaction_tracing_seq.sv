`ifndef AXI4_MASTER_USER_TRANSACTION_TRACING_SEQ_INCLUDED_
`define AXI4_MASTER_USER_TRANSACTION_TRACING_SEQ_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_transaction_tracing_seq
// Master sequence to test USER signal-based transaction tracing
// Embeds trace IDs, source identifiers, debug flags, and sequence numbers in USER signals
//--------------------------------------------------------------------------------------------
class axi4_master_user_transaction_tracing_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_transaction_tracing_seq)
  
  // Response object for getting transaction responses
  axi4_master_tx rsp;

  // Tracing parameters
  bit [7:0]  transaction_id = 8'h00;     // Unique transaction trace ID
  bit [7:0]  source_master_id;           // Master originating the transaction
  bit [7:0]  debug_flags;                // Debug control flags
  bit [7:0]  sequence_number = 8'h00;    // Sequence number for ordering
  
  // Trace mode configuration
  string trace_mode = "BASIC";           // BASIC, DETAILED, DEBUG, PERFORMANCE
  int num_transactions = 1;
  int master_id = 0;
  int slave_id = 0;
  
  // Transaction correlation tracking
  bit [7:0] trace_id_array[256];
  int trace_count = 0;
  
  // Debug flag bits
  typedef enum bit [2:0] {
    DEBUG_EN  = 0,  // Enable debug mode
    TRACE_EN  = 1,  // Enable trace logging
    LOG_EN    = 2,  // Enable verbose logging
    PERF_EN   = 3,  // Enable performance tracking
    ERROR_EN  = 4,  // Enable error injection
    SYNC_EN   = 5,  // Enable synchronization markers
    CHECK_EN  = 6,  // Enable checking mode
    PROF_EN   = 7   // Enable profiling
  } debug_flag_bits_e;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_user_transaction_tracing_seq");
  extern task body();
  extern function bit [31:0] generate_trace_user_signal(bit [7:0] tid, bit [7:0] src_id, bit [7:0] flags, bit [7:0] seq_num);
  extern function void display_trace_info(bit [31:0] user_signal);
  extern function bit [7:0] get_next_transaction_id();
  extern function bit [7:0] generate_debug_flags(string mode);

endclass : axi4_master_user_transaction_tracing_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the axi4_master_user_transaction_tracing_seq class object
//
// Parameters:
//  name - axi4_master_user_transaction_tracing_seq
//--------------------------------------------------------------------------------------------
function axi4_master_user_transaction_tracing_seq::new(string name = "axi4_master_user_transaction_tracing_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: generate_trace_user_signal
// Generates a USER signal with embedded trace information
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_transaction_tracing_seq::generate_trace_user_signal(
  bit [7:0] tid, 
  bit [7:0] src_id, 
  bit [7:0] flags, 
  bit [7:0] seq_num
);
  bit [31:0] user_signal;
  
  user_signal[7:0]   = tid;      // Transaction ID
  user_signal[15:8]  = src_id;   // Source Master ID
  user_signal[23:16] = flags;    // Debug Flags
  user_signal[31:24] = seq_num;  // Sequence Number
  
  return user_signal;
endfunction : generate_trace_user_signal

//--------------------------------------------------------------------------------------------
// Function: display_trace_info
// Displays decoded trace information from USER signal
//--------------------------------------------------------------------------------------------
function void axi4_master_user_transaction_tracing_seq::display_trace_info(bit [31:0] user_signal);
  bit [7:0] tid     = user_signal[7:0];
  bit [7:0] src_id  = user_signal[15:8];
  bit [7:0] flags   = user_signal[23:16];
  bit [7:0] seq_num = user_signal[31:24];
  
  `uvm_info(get_type_name(), $sformatf("Transaction Trace: TID=0x%02x, SRC=M%0d, FLAGS=0x%02x, SEQ=%0d",
            tid, src_id, flags, seq_num), UVM_MEDIUM)
  
  // Decode flags
  if(flags[DEBUG_EN]) `uvm_info(get_type_name(), "  - Debug mode enabled", UVM_HIGH)
  if(flags[TRACE_EN]) `uvm_info(get_type_name(), "  - Trace logging enabled", UVM_HIGH)
  if(flags[LOG_EN])   `uvm_info(get_type_name(), "  - Verbose logging enabled", UVM_HIGH)
  if(flags[PERF_EN])  `uvm_info(get_type_name(), "  - Performance tracking enabled", UVM_HIGH)
endfunction : display_trace_info

//--------------------------------------------------------------------------------------------
// Function: get_next_transaction_id
// Returns the next unique transaction ID for tracing
//--------------------------------------------------------------------------------------------
function bit [7:0] axi4_master_user_transaction_tracing_seq::get_next_transaction_id();
  transaction_id = transaction_id + 1;
  if(transaction_id == 8'h00) transaction_id = 8'h01; // Skip 0 to avoid confusion
  return transaction_id;
endfunction : get_next_transaction_id

//--------------------------------------------------------------------------------------------
// Function: generate_debug_flags
// Generates debug flags based on trace mode
//--------------------------------------------------------------------------------------------
function bit [7:0] axi4_master_user_transaction_tracing_seq::generate_debug_flags(string mode);
  bit [7:0] flags = 8'h00;
  
  case(mode)
    "BASIC": begin
      flags[TRACE_EN] = 1'b1;
    end
    "DETAILED": begin
      flags[TRACE_EN] = 1'b1;
      flags[LOG_EN] = 1'b1;
    end
    "DEBUG": begin
      flags[DEBUG_EN] = 1'b1;
      flags[TRACE_EN] = 1'b1;
      flags[LOG_EN] = 1'b1;
      flags[CHECK_EN] = 1'b1;
    end
    "PERFORMANCE": begin
      flags[TRACE_EN] = 1'b1;
      flags[PERF_EN] = 1'b1;
      flags[PROF_EN] = 1'b1;
    end
    "FULL": begin
      flags = 8'hFF; // All flags enabled
    end
    default: begin
      flags[TRACE_EN] = 1'b1; // Default to basic tracing
    end
  endcase
  
  return flags;
endfunction : generate_debug_flags

//--------------------------------------------------------------------------------------------
// Task: body
// Creates transactions with embedded trace information in USER signals
//--------------------------------------------------------------------------------------------
task axi4_master_user_transaction_tracing_seq::body();
  bit [31:0] trace_user_signal;
  bit [7:0] current_tid;
  bit [7:0] current_flags;
  axi4_bus_matrix_ref::bus_matrix_mode_e bus_mode;
  bit [ADDRESS_WIDTH-1:0] base_addr;
  
  // Enable response handling for proper transaction flow
  // But we won't block on get_response() to avoid hanging
  set_response_queue_depth(10);
  
  // Get bus matrix mode from config_db
  if(!uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::get(m_sequencer, "", "bus_matrix_mode", bus_mode)) begin
    bus_mode = axi4_bus_matrix_ref::NONE;
    `uvm_info(get_type_name(), "No bus_matrix_mode found, defaulting to NONE", UVM_MEDIUM)
  end
  
  // Get configuration if set
  if(!uvm_config_db#(string)::get(null, get_full_name(), "trace_mode", trace_mode)) begin
    `uvm_info(get_type_name(), $sformatf("Using default trace_mode: %s", trace_mode), UVM_MEDIUM)
  end
  
  if(!uvm_config_db#(int)::get(null, get_full_name(), "num_transactions", num_transactions)) begin
    `uvm_info(get_type_name(), $sformatf("Using default num_transactions: %0d", num_transactions), UVM_MEDIUM)
  end
  
  uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id);
  uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id);
  
  source_master_id = master_id;
  current_flags = generate_debug_flags(trace_mode);
  
  `uvm_info(get_type_name(), $sformatf("Starting transaction tracing in %s mode (%0d transactions)", 
            trace_mode, num_transactions), UVM_LOW)
  
  repeat(num_transactions) begin
    current_tid = get_next_transaction_id();
    sequence_number = sequence_number + 1;
    
    trace_user_signal = generate_trace_user_signal(current_tid, source_master_id, 
                                                   current_flags, sequence_number);
    
    `uvm_info(get_type_name(), $sformatf("Generating traced transaction #%0d", sequence_number), UVM_MEDIUM)
    display_trace_info(trace_user_signal);
    
    // Store trace ID for correlation checking
    trace_id_array[trace_count++] = current_tid;
    
    // Determine base address based on bus matrix mode and slave
    case(bus_mode)
      axi4_bus_matrix_ref::NONE, axi4_bus_matrix_ref::BASE_BUS_MATRIX: begin
        // 4x4 matrix addresses
        case(slave_id)
          0: base_addr = 64'h0000_0100_0000_0000; // DDR
          1: base_addr = 64'h0000_0000_0000_0000; // Boot ROM (read-only)
          2: base_addr = 64'h0000_0010_0000_0000; // Peripheral
          3: base_addr = 64'h0000_0020_0000_0000; // HW Fuse (read-only)
          default: base_addr = 64'h0000_0100_0000_0000;
        endcase
      end
      axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: begin
        // 10x10 ENHANCED matrix addresses (corrected from bus matrix configuration)
        case(slave_id)
          0: base_addr = 64'h0000_0008_0000_0000; // DDR Secure Kernel
          1: base_addr = 64'h0000_0008_4000_0000; // DDR Non-Secure User
          2: base_addr = 64'h0000_0008_8000_0000; // DDR Shared Buffer
          3: base_addr = 64'h0000_0008_C000_0000; // Illegal Address Hole - avoid this
          4: base_addr = 64'h0000_0009_0000_0000; // XOM Instruction-Only
          5: base_addr = 64'h0000_000A_0000_0000; // RO Peripheral
          6: base_addr = 64'h0000_000A_0001_0000; // Privileged-Only (corrected)
          7: base_addr = 64'h0000_000A_0002_0000; // Secure-Only (corrected)
          8: base_addr = 64'h0000_000A_0003_0000; // Scratchpad (corrected)
          9: base_addr = 64'h0000_000A_0004_0000; // Attribute Monitor (corrected)
          default: base_addr = 64'h0000_0008_4000_0000; // Default to non-secure DDR
        endcase
      end
    endcase
    
    // Skip write to read-only slaves or illegal addresses
    if((slave_id == 1 || slave_id == 3) && (bus_mode == axi4_bus_matrix_ref::BASE_BUS_MATRIX || bus_mode == axi4_bus_matrix_ref::NONE)) begin
      `uvm_info(get_type_name(), $sformatf("Skipping write to read-only slave %0d in 4x4 mode", slave_id), UVM_MEDIUM)
    end else if(bus_mode == axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX && (slave_id == 3 || slave_id == 5)) begin
      `uvm_info(get_type_name(), $sformatf("Skipping write to illegal/read-only slave %0d in Enhanced mode", slave_id), UVM_MEDIUM)
    end else begin
      // Create write transaction with trace info
      req = axi4_master_tx::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        tx_type == WRITE;
        transfer_type == NON_BLOCKING_WRITE;  // Set transfer type
        awid == `GET_AWID_ENUM(master_id);
        awaddr == base_addr + (sequence_number * 64'h100);
        awlen == 4'h3; // 4 beats
        awsize == WRITE_4_BYTES;
        awburst == WRITE_INCR;
        awprot == 3'b000; // Non-secure, non-privileged, data access
        awuser == trace_user_signal;  // Embed trace info
        wuser == trace_user_signal;   // Maintain trace through data channel
        wdata.size() == awlen + 1;
        wstrb.size() == awlen + 1;
        foreach(wdata[i]) {
          wdata[i] == {current_tid, sequence_number, 8'h00, i[7:0], current_tid, sequence_number, 8'h00, i[7:0]};
        }
        foreach(wstrb[i]) {
          wstrb[i] == 4'hF;
        }
      });
      finish_item(req);
      
      // Don't block on response to avoid hanging - let transaction flow asynchronously
      `uvm_info(get_type_name(), "Write transaction sent", UVM_HIGH)
    end
    
    // Create read transaction to verify trace propagation
    if(trace_mode == "DEBUG" || trace_mode == "FULL") begin
      // Only read from readable addresses (avoid illegal address hole)
      if(!(bus_mode == axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX && slave_id == 3)) begin
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == READ;
          transfer_type == NON_BLOCKING_READ;  // Set transfer type
          arid == `GET_ARID_ENUM(master_id);
          araddr == base_addr + (sequence_number * 64'h100);
          arlen == 4'h3; // 4 beats
          arsize == READ_4_BYTES;
          arburst == READ_INCR;
          arprot == 3'b000; // Non-secure, non-privileged, data access
          aruser == trace_user_signal;  // Embed trace info in read
        });
        finish_item(req);
        
        // Don't block on response to avoid hanging - let transaction flow asynchronously
        `uvm_info(get_type_name(), "Read transaction sent", UVM_HIGH)
        
        `uvm_info(get_type_name(), $sformatf("Read-back transaction for trace validation (TID=0x%02x)", 
                  current_tid), UVM_MEDIUM)
      end
    end
    
    // Add minimal delay between traced transactions
    #1ns;
  end
  
  // Final trace summary
  `uvm_info(get_type_name(), "Transaction Trace Summary:", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  Total traced transactions: %0d", trace_count), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  Trace mode: %s", trace_mode), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  Master ID: %0d", master_id), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("  Target Slave ID: %0d", slave_id), UVM_LOW)
  
  if(trace_count > 0) begin
    `uvm_info(get_type_name(), "  Transaction IDs used:", UVM_LOW)
    for(int i = 0; i < trace_count && i < 10; i++) begin
      `uvm_info(get_type_name(), $sformatf("    [%0d]: TID=0x%02x", i, trace_id_array[i]), UVM_LOW)
    end
    if(trace_count > 10) begin
      `uvm_info(get_type_name(), $sformatf("    ... and %0d more", trace_count - 10), UVM_LOW)
    end
  end
  
endtask : body

`endif