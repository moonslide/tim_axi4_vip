`ifndef AXI4_MASTER_USER_TRANSACTION_TRACING_SEQ_INCLUDED_
`define AXI4_MASTER_USER_TRANSACTION_TRACING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_transaction_tracing_seq
// Tests USER signals for transaction tracing functionality
// Implements trace IDs, debug markers, and performance monitoring using USER signals
//--------------------------------------------------------------------------------------------
class axi4_master_user_transaction_tracing_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_transaction_tracing_seq)
  
  // Configuration parameters
  int master_id = 0;
  int slave_id = 2;
  int num_transactions = 18;
  
  // Trace types
  typedef enum bit [2:0] {
    TRACE_DEBUG      = 3'b000, // Debug tracing
    TRACE_PERF       = 3'b001, // Performance monitoring
    TRACE_ERROR      = 3'b010, // Error tracking
    TRACE_SECURITY   = 3'b011, // Security audit
    TRACE_POWER      = 3'b100, // Power management
    TRACE_THERMAL    = 3'b101, // Thermal monitoring
    TRACE_QOS        = 3'b110, // QoS analysis
    TRACE_CUSTOM     = 3'b111  // Custom tracing
  } trace_type_e;
  
  // Trace priorities
  typedef enum bit [1:0] {
    TRACE_PRIO_LOW     = 2'b00,
    TRACE_PRIO_MEDIUM  = 2'b01,
    TRACE_PRIO_HIGH    = 2'b10,
    TRACE_PRIO_CRITICAL = 2'b11
  } trace_priority_e;
  
  // Debug markers
  typedef enum bit [3:0] {
    DEBUG_ENTRY        = 4'b0000, // Function entry
    DEBUG_EXIT         = 4'b0001, // Function exit
    DEBUG_CHECKPOINT   = 4'b0010, // Checkpoint marker
    DEBUG_ERROR        = 4'b0011, // Error condition
    DEBUG_WARNING      = 4'b0100, // Warning condition
    DEBUG_INFO         = 4'b0101, // Information marker
    DEBUG_PERF_START   = 4'b0110, // Performance measurement start
    DEBUG_PERF_END     = 4'b0111, // Performance measurement end
    DEBUG_BRANCH_TAKEN = 4'b1000, // Branch taken
    DEBUG_BRANCH_NOT   = 4'b1001, // Branch not taken
    DEBUG_LOOP_START   = 4'b1010, // Loop start
    DEBUG_LOOP_END     = 4'b1011, // Loop end
    DEBUG_INTERRUPT    = 4'b1100, // Interrupt handling
    DEBUG_CONTEXT_SW   = 4'b1101, // Context switch
    DEBUG_CACHE_MISS   = 4'b1110, // Cache miss
    DEBUG_CACHE_HIT    = 4'b1111  // Cache hit
  } debug_marker_e;
  
  // Transaction tracing test scenarios
  typedef struct {
    string test_name;
    trace_type_e trace_type;
    trace_priority_e trace_prio;
    debug_marker_e debug_marker;
    bit [7:0] trace_id;
    bit [7:0] context_id;
    string description;
  } trace_test_t;
  
  trace_test_t trace_tests[] = '{
    '{"debug_func_entry", TRACE_DEBUG, TRACE_PRIO_MEDIUM, DEBUG_ENTRY, 8'h01, 8'hA0, "Debug function entry trace"},
    '{"debug_func_exit", TRACE_DEBUG, TRACE_PRIO_MEDIUM, DEBUG_EXIT, 8'h01, 8'hA0, "Debug function exit trace"},
    '{"perf_measure_start", TRACE_PERF, TRACE_PRIO_HIGH, DEBUG_PERF_START, 8'h02, 8'hB1, "Performance measurement start"},
    '{"perf_measure_end", TRACE_PERF, TRACE_PRIO_HIGH, DEBUG_PERF_END, 8'h02, 8'hB1, "Performance measurement end"},
    '{"error_critical", TRACE_ERROR, TRACE_PRIO_CRITICAL, DEBUG_ERROR, 8'h03, 8'hC2, "Critical error trace"},
    '{"security_audit", TRACE_SECURITY, TRACE_PRIO_HIGH, DEBUG_CHECKPOINT, 8'h04, 8'hD3, "Security audit checkpoint"},
    '{"power_state_change", TRACE_POWER, TRACE_PRIO_MEDIUM, DEBUG_INFO, 8'h05, 8'hE4, "Power state change trace"},
    '{"thermal_warning", TRACE_THERMAL, TRACE_PRIO_HIGH, DEBUG_WARNING, 8'h06, 8'hF5, "Thermal warning trace"},
    '{"qos_analysis", TRACE_QOS, TRACE_PRIO_MEDIUM, DEBUG_CHECKPOINT, 8'h07, 8'h16, "QoS analysis trace"},
    '{"cache_miss_event", TRACE_PERF, TRACE_PRIO_LOW, DEBUG_CACHE_MISS, 8'h08, 8'h27, "Cache miss performance trace"},
    '{"cache_hit_event", TRACE_PERF, TRACE_PRIO_LOW, DEBUG_CACHE_HIT, 8'h08, 8'h27, "Cache hit performance trace"},
    '{"interrupt_handle", TRACE_DEBUG, TRACE_PRIO_HIGH, DEBUG_INTERRUPT, 8'h09, 8'h38, "Interrupt handling trace"},
    '{"context_switch", TRACE_DEBUG, TRACE_PRIO_MEDIUM, DEBUG_CONTEXT_SW, 8'h0A, 8'h49, "Context switch trace"},
    '{"loop_performance", TRACE_PERF, TRACE_PRIO_MEDIUM, DEBUG_LOOP_START, 8'h0B, 8'h5A, "Loop performance start"},
    '{"branch_prediction", TRACE_DEBUG, TRACE_PRIO_LOW, DEBUG_BRANCH_TAKEN, 8'h0C, 8'h6B, "Branch prediction trace"},
    '{"custom_marker", TRACE_CUSTOM, TRACE_PRIO_MEDIUM, DEBUG_INFO, 8'h0D, 8'h7C, "Custom trace marker"},
    '{"debug_checkpoint", TRACE_DEBUG, TRACE_PRIO_HIGH, DEBUG_CHECKPOINT, 8'h0E, 8'h8D, "Debug checkpoint trace"},
    '{"error_recovery", TRACE_ERROR, TRACE_PRIO_HIGH, DEBUG_WARNING, 8'h0F, 8'h9E, "Error recovery trace"}
  };
  
  // Global trace sequence counter
  static int trace_sequence_num = 0;
  
  // Transaction parameters
  rand bit [ADDRESS_WIDTH-1:0] base_addr;
  
  constraint base_addr_c {
    base_addr == (slave_id == 2) ? 64'h0000_0008_8000_0000 : 64'h0000_0008_0000_0000;
  }
  
  extern function new(string name = "axi4_master_user_transaction_tracing_seq");
  extern virtual task body();
  extern virtual task generate_trace_transaction(int test_idx, bit is_write);
  extern virtual function bit [31:0] encode_trace_user_bits(trace_test_t test_info, int seq_num);
  extern virtual function bit [15:0] generate_trace_timestamp();
  
endclass : axi4_master_user_transaction_tracing_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_user_transaction_tracing_seq::new(string name = "axi4_master_user_transaction_tracing_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Generates transactions with tracing USER signals
//-----------------------------------------------------------------------------
task axi4_master_user_transaction_tracing_seq::body();
  
  super.body();
  
  // Get configuration from config_db
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    `uvm_info(get_type_name(), "Using default master_id = 0", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    `uvm_info(get_type_name(), "Using default slave_id = 2", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "num_transactions", num_transactions)) begin
    `uvm_info(get_type_name(), "Using default num_transactions = 18", UVM_MEDIUM)
  end
  
  `uvm_info(get_type_name(), $sformatf("Starting USER transaction tracing sequence: Master[%0d] → Slave[%0d]",
                                        master_id, slave_id), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Testing %0d transaction tracing scenarios", trace_tests.size()), UVM_MEDIUM)
  
  // Test each tracing scenario - only write transactions for cleaner trace logs
  for (int i = 0; i < trace_tests.size() && i < num_transactions; i++) begin
    `uvm_info(get_type_name(), $sformatf("Testing trace scenario %0d: %s - %s",
                                          i, trace_tests[i].test_name, trace_tests[i].description), UVM_HIGH)
    
    // Generate write transaction with tracing
    generate_trace_transaction(i, 1'b1);
    #200; // Longer delay for trace processing
    
    // Generate paired read for some scenarios
    if ((i % 3) == 0) begin
      generate_trace_transaction(i, 1'b0);
      #100;
    end
  end
  
  `uvm_info(get_type_name(), $sformatf("USER transaction tracing sequence completed: %0d scenarios tested",
                                        trace_tests.size()), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Total trace sequence numbers used: %0d", trace_sequence_num), UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Task: generate_trace_transaction
// Creates transactions with tracing USER signals
//-----------------------------------------------------------------------------
task axi4_master_user_transaction_tracing_seq::generate_trace_transaction(int test_idx, bit is_write);
  
  trace_test_t current_test = trace_tests[test_idx];
  bit [31:0] trace_user_bits;
  int current_seq_num;
  int burst_len;
  
  // Increment global sequence number
  trace_sequence_num++;
  current_seq_num = trace_sequence_num;
  
  // Calculate burst length based on priority
  burst_len = (current_test.trace_prio == TRACE_PRIO_CRITICAL) ? 0 : $urandom_range(0, 1);
  
  trace_user_bits = encode_trace_user_bits(current_test, current_seq_num);
  
  if (is_write) begin
    // Generate write transaction with tracing
    `uvm_do_with(req, {
      req.tx_type == WRITE;
      req.awaddr == base_addr + (test_idx * 'h150);
      req.awid == awid_e'(master_id % 16);
      req.awlen == burst_len; // Shorter for critical
      req.awsize == WRITE_8_BYTES;
      req.awburst == WRITE_INCR;
      req.awqos == (current_test.trace_prio == TRACE_PRIO_CRITICAL) ? 4'hF : 
                   (current_test.trace_prio == TRACE_PRIO_HIGH) ? 4'hC : 4'h8;
      req.awuser == trace_user_bits;
      req.wuser == {16'h0000, current_test.context_id, current_test.trace_id}; // Context and trace ID in WUSER
    })
    
    `uvm_info(get_type_name(), $sformatf("WRITE TRACE %s: Type=%0d, Prio=%0d, Marker=%0d, TraceID=0x%02h, SeqNum=%0d, AWUSER=0x%08h",
                                          current_test.test_name, current_test.trace_type, current_test.trace_prio,
                                          current_test.debug_marker, current_test.trace_id, current_seq_num, trace_user_bits), UVM_HIGH)
  end
  else begin
    // Generate read transaction with tracing
    `uvm_do_with(req, {
      req.tx_type == READ;
      req.araddr == base_addr + (test_idx * 'h150) + 'h3000; // Offset for reads
      req.arid == arid_e'(master_id % 16);
      req.arlen == burst_len; // Shorter for critical
      req.arsize == READ_8_BYTES;
      req.arburst == READ_INCR;
      req.arqos == (current_test.trace_prio == TRACE_PRIO_CRITICAL) ? 4'hF : 
                   (current_test.trace_prio == TRACE_PRIO_HIGH) ? 4'hC : 4'h8;
      req.aruser == trace_user_bits;
    })
    
    `uvm_info(get_type_name(), $sformatf("READ TRACE %s: Type=%0d, Prio=%0d, Marker=%0d, TraceID=0x%02h, SeqNum=%0d, ARUSER=0x%08h",
                                          current_test.test_name, current_test.trace_type, current_test.trace_prio,
                                          current_test.debug_marker, current_test.trace_id, current_seq_num, trace_user_bits), UVM_HIGH)
  end
  
endtask : generate_trace_transaction

//-----------------------------------------------------------------------------
// Function: encode_trace_user_bits
// Encodes tracing information into USER signal bits
//-----------------------------------------------------------------------------
function bit [31:0] axi4_master_user_transaction_tracing_seq::encode_trace_user_bits(trace_test_t test_info, int seq_num);
  bit [31:0] user_bits = 32'h00000000;
  bit [15:0] timestamp;
  
  // Generate timestamp
  timestamp = generate_trace_timestamp();
  
  // Encode tracing information in USER bits
  user_bits[2:0]   = test_info.trace_type;     // Bits [2:0]: Trace type
  user_bits[4:3]   = test_info.trace_prio;     // Bits [4:3]: Trace priority
  user_bits[8:5]   = test_info.debug_marker;   // Bits [8:5]: Debug marker
  user_bits[12:9]  = master_id[3:0];           // Bits [12:9]: Master ID
  user_bits[15:13] = seq_num[2:0];             // Bits [15:13]: Sequence number (lower bits)
  user_bits[31:16] = timestamp;                // Bits [31:16]: Timestamp
  
  return user_bits;
endfunction : encode_trace_user_bits

//-----------------------------------------------------------------------------
// Function: generate_trace_timestamp
// Generates a 16-bit timestamp for tracing
//-----------------------------------------------------------------------------
function bit [15:0] axi4_master_user_transaction_tracing_seq::generate_trace_timestamp();
  bit [15:0] timestamp;
  
  // Use simulation time to generate timestamp
  timestamp = $time & 16'hFFFF;
  
  // Add some entropy to avoid identical timestamps
  timestamp ^= {trace_sequence_num[7:0], master_id[7:0]};
  
  return timestamp;
endfunction : generate_trace_timestamp

`endif