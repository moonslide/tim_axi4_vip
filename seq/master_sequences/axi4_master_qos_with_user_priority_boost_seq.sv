`ifndef AXI4_MASTER_QOS_WITH_USER_PRIORITY_BOOST_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_WITH_USER_PRIORITY_BOOST_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_with_user_priority_boost_seq
// Tests QoS priority boosting based on USER signal information
// Combines QoS and USER signals for enhanced priority management
//--------------------------------------------------------------------------------------------
class axi4_master_qos_with_user_priority_boost_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_qos_with_user_priority_boost_seq)
  
  // Configuration parameters
  int master_id = 0;
  int slave_id = 2;
  int num_transactions = 16;
  
  // Priority boost types
  typedef enum bit [2:0] {
    BOOST_SECURITY_CRITICAL = 3'b000, // Security-critical transactions get priority boost
    BOOST_REAL_TIME        = 3'b001, // Real-time requirements boost
    BOOST_EMERGENCY        = 3'b010, // Emergency/interrupt context boost
    BOOST_PERFORMANCE      = 3'b011, // Performance-critical path boost
    BOOST_POWER_SAVING     = 3'b100, // Power-efficient operations boost
    BOOST_DEADLINE_URGENT  = 3'b101, // Deadline-urgent transactions boost
    BOOST_BANDWIDTH_HIGH   = 3'b110, // High bandwidth requirements boost
    BOOST_LATENCY_CRITICAL = 3'b111  // Latency-critical operations boost
  } priority_boost_type_e;
  
  // Combined QoS and USER test scenarios
  typedef struct {
    string test_name;
    priority_boost_type_e boost_type;
    bit [3:0] base_qos;
    bit [3:0] boosted_qos;
    bit [31:0] user_signal_pattern;
    bit [7:0] context_info;
    string description;
  } qos_user_test_t;
  
  qos_user_test_t qos_user_tests[] = '{
    // Security-critical priority boosts
    '{"sec_critical_boost", BOOST_SECURITY_CRITICAL, 4'h4, 4'hF, 32'h80000001, 8'h5C, "Security critical → Max priority"},
    '{"sec_moderate_boost", BOOST_SECURITY_CRITICAL, 4'h6, 4'hD, 32'h80000002, 8'h5D, "Security moderate → High priority"},
    
    // Real-time priority boosts
    '{"rt_hard_deadline", BOOST_REAL_TIME, 4'h5, 4'hE, 32'h40000001, 8'hA1, "Hard real-time deadline boost"},
    '{"rt_soft_deadline", BOOST_REAL_TIME, 4'h7, 4'hB, 32'h40000002, 8'hA2, "Soft real-time deadline boost"},
    
    // Emergency/interrupt priority boosts
    '{"emergency_irq", BOOST_EMERGENCY, 4'h3, 4'hF, 32'h20000001, 8'hE1, "Emergency interrupt → Max priority"},
    '{"emergency_fault", BOOST_EMERGENCY, 4'h5, 4'hE, 32'h20000002, 8'hEF, "Emergency fault handler boost"},
    
    // Performance-critical path boosts
    '{"perf_hotpath", BOOST_PERFORMANCE, 4'h6, 4'hC, 32'h10000001, 8'hB1, "Performance hot path boost"},
    '{"perf_cache_miss", BOOST_PERFORMANCE, 4'h4, 4'hA, 32'h10000002, 8'hB2, "Performance cache miss boost"},
    
    // Power-saving priority adjustments
    '{"power_efficient", BOOST_POWER_SAVING, 4'h8, 4'h6, 32'h08000001, 8'hC1, "Power efficient → Lower priority"},
    '{"power_idle", BOOST_POWER_SAVING, 4'h9, 4'h5, 32'h08000002, 8'hC2, "Power idle → Background priority"},
    
    // Deadline-urgent boosts
    '{"deadline_miss", BOOST_DEADLINE_URGENT, 4'h7, 4'hF, 32'h04000001, 8'hD3, "Deadline miss → Max priority"},
    '{"deadline_warn", BOOST_DEADLINE_URGENT, 4'h8, 4'hC, 32'h04000002, 8'hD4, "Deadline warning boost"},
    
    // High bandwidth requirement boosts
    '{"bandwidth_dma", BOOST_BANDWIDTH_HIGH, 4'h5, 4'hB, 32'h02000001, 8'hBD, "High bandwidth DMA boost"},
    '{"bandwidth_stream", BOOST_BANDWIDTH_HIGH, 4'h6, 4'hA, 32'h02000002, 8'hB5, "Streaming bandwidth boost"},
    
    // Latency-critical operation boosts
    '{"latency_ui", BOOST_LATENCY_CRITICAL, 4'h4, 4'hD, 32'h01000001, 8'hD1, "UI latency-critical boost"},
    '{"latency_control", BOOST_LATENCY_CRITICAL, 4'h7, 4'hE, 32'h01000002, 8'hD2, "Control loop latency boost"}
  };
  
  // Transaction parameters
  rand bit [ADDRESS_WIDTH-1:0] base_addr;
  
  constraint base_addr_c {
    base_addr == (slave_id == 2) ? 64'h0000_0008_8000_0000 : 64'h0000_0008_0000_0000;
  }
  
  extern function new(string name = "axi4_master_qos_with_user_priority_boost_seq");
  extern virtual task body();
  extern virtual task generate_qos_user_transaction(int test_idx, bit is_write);
  extern virtual function bit [31:0] encode_boost_user_signal(qos_user_test_t test_info);
  extern virtual function bit [3:0] calculate_dynamic_qos(qos_user_test_t test_info);
  
endclass : axi4_master_qos_with_user_priority_boost_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_qos_with_user_priority_boost_seq::new(string name = "axi4_master_qos_with_user_priority_boost_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Generates transactions with QoS priority boosting based on USER signals
//-----------------------------------------------------------------------------
task axi4_master_qos_with_user_priority_boost_seq::body();
  
  super.body();
  
  // Get configuration from config_db
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    `uvm_info(get_type_name(), "Using default master_id = 0", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    `uvm_info(get_type_name(), "Using default slave_id = 2", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "num_transactions", num_transactions)) begin
    `uvm_info(get_type_name(), "Using default num_transactions = 16", UVM_MEDIUM)
  end
  
  `uvm_info(get_type_name(), $sformatf("Starting QoS with USER priority boost sequence: Master[%0d] → Slave[%0d]",
                                        master_id, slave_id), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Testing %0d QoS priority boost scenarios", qos_user_tests.size()), UVM_MEDIUM)
  
  // Test each QoS priority boost scenario
  for (int i = 0; i < qos_user_tests.size() && i < num_transactions; i++) begin
    `uvm_info(get_type_name(), $sformatf("Testing QoS boost %0d: %s - %s",
                                          i, qos_user_tests[i].test_name, qos_user_tests[i].description), UVM_HIGH)
    
    // Generate write transaction with QoS priority boost
    generate_qos_user_transaction(i, 1'b1);
    #150;
    
    // Generate read transaction with QoS priority boost
    generate_qos_user_transaction(i, 1'b0);
    #150;
  end
  
  `uvm_info(get_type_name(), $sformatf("QoS with USER priority boost sequence completed: %0d scenarios tested",
                                        qos_user_tests.size()), UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Task: generate_qos_user_transaction
// Creates transactions with QoS priority boosting based on USER signals
//-----------------------------------------------------------------------------
task axi4_master_qos_with_user_priority_boost_seq::generate_qos_user_transaction(int test_idx, bit is_write);
  
  qos_user_test_t current_test = qos_user_tests[test_idx];
  bit [31:0] boost_user_signal;
  bit [3:0] dynamic_qos;
  int burst_len = $urandom_range(0, 3);
  
  boost_user_signal = encode_boost_user_signal(current_test);
  dynamic_qos = calculate_dynamic_qos(current_test);
  
  if (is_write) begin
    // Generate write transaction with QoS priority boost
    `uvm_do_with(req, {
      req.tx_type == WRITE;
      req.awaddr == base_addr + (test_idx * 'h500);
      req.awid == awid_e'(master_id % 16);
      req.awlen == burst_len; // Variable burst lengths
      req.awsize == WRITE_8_BYTES;
      req.awburst == WRITE_INCR;
      req.awqos == dynamic_qos; // Dynamic QoS based on USER signal context
      req.awuser == boost_user_signal;
      req.wuser == {16'h0000, current_test.context_info, 8'h80 + (test_idx[7:0] & 8'h7F)}; // Context in WUSER, prevent overflow
    })
    
    `uvm_info(get_type_name(), $sformatf("WRITE QoS BOOST %s: BaseQoS=%0d → BoostedQoS=%0d, BoostType=%0d, AWUSER=0x%08h",
                                          current_test.test_name, current_test.base_qos, current_test.boosted_qos,
                                          current_test.boost_type, boost_user_signal), UVM_HIGH)
  end
  else begin
    // Generate read transaction with QoS priority boost
    `uvm_do_with(req, {
      req.tx_type == READ;
      req.araddr == base_addr + (test_idx * 'h500) + 'h6000; // Offset for reads
      req.arid == arid_e'(master_id % 16);
      req.arlen == burst_len; // Variable burst lengths
      req.arsize == READ_8_BYTES;
      req.arburst == READ_INCR;
      req.arqos == dynamic_qos; // Dynamic QoS based on USER signal context
      req.aruser == boost_user_signal;
    })
    
    `uvm_info(get_type_name(), $sformatf("READ QoS BOOST %s: BaseQoS=%0d → BoostedQoS=%0d, BoostType=%0d, ARUSER=0x%08h",
                                          current_test.test_name, current_test.base_qos, current_test.boosted_qos,
                                          current_test.boost_type, boost_user_signal), UVM_HIGH)
  end
  
endtask : generate_qos_user_transaction

//-----------------------------------------------------------------------------
// Function: encode_boost_user_signal
// Encodes priority boost information into USER signal
//-----------------------------------------------------------------------------
function bit [31:0] axi4_master_qos_with_user_priority_boost_seq::encode_boost_user_signal(qos_user_test_t test_info);
  bit [31:0] user_bits = 32'h00000000;
  
  // Encode boost information in USER bits
  user_bits[2:0]   = test_info.boost_type;      // Bits [2:0]: Boost type
  user_bits[6:3]   = test_info.base_qos;        // Bits [6:3]: Original QoS
  user_bits[10:7]  = test_info.boosted_qos;     // Bits [10:7]: Target boosted QoS
  user_bits[14:11] = master_id[3:0];            // Bits [14:11]: Master ID
  user_bits[22:15] = test_info.context_info;    // Bits [22:15]: Context information
  user_bits[31:23] = $time & 9'h1FF;            // Bits [31:23]: Timestamp
  
  // OR with the base pattern
  user_bits |= test_info.user_signal_pattern;
  
  return user_bits;
endfunction : encode_boost_user_signal

//-----------------------------------------------------------------------------
// Function: calculate_dynamic_qos
// Calculates dynamic QoS value based on boost requirements
//-----------------------------------------------------------------------------
function bit [3:0] axi4_master_qos_with_user_priority_boost_seq::calculate_dynamic_qos(qos_user_test_t test_info);
  bit [3:0] calculated_qos;
  
  case (test_info.boost_type)
    BOOST_SECURITY_CRITICAL: begin
      // Security-critical always gets maximum priority
      calculated_qos = test_info.boosted_qos;
    end
    
    BOOST_REAL_TIME: begin
      // Real-time gets high priority but may be adjusted based on system load
      calculated_qos = test_info.boosted_qos;
    end
    
    BOOST_EMERGENCY: begin
      // Emergency always gets maximum priority
      calculated_qos = 4'hF;
    end
    
    BOOST_PERFORMANCE: begin
      // Performance boost depends on current utilization
      calculated_qos = test_info.boosted_qos;
    end
    
    BOOST_POWER_SAVING: begin
      // Power saving reduces priority to save energy
      calculated_qos = (test_info.base_qos > 2) ? test_info.base_qos - 2 : test_info.base_qos;
    end
    
    BOOST_DEADLINE_URGENT: begin
      // Deadline urgent gets maximum priority to avoid deadline miss
      calculated_qos = test_info.boosted_qos;
    end
    
    BOOST_BANDWIDTH_HIGH: begin
      // High bandwidth requirements get elevated priority
      calculated_qos = test_info.boosted_qos;
    end
    
    BOOST_LATENCY_CRITICAL: begin
      // Latency-critical gets high priority for responsiveness
      calculated_qos = test_info.boosted_qos;
    end
    
    default: begin
      calculated_qos = test_info.base_qos;
    end
  endcase
  
  return calculated_qos;
endfunction : calculate_dynamic_qos

`endif