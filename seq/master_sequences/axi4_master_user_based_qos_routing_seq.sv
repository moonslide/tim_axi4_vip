`ifndef AXI4_MASTER_USER_BASED_QOS_ROUTING_SEQ_INCLUDED_
`define AXI4_MASTER_USER_BASED_QOS_ROUTING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_based_qos_routing_seq
// Tests QoS routing decisions based on USER signal context
// Uses USER signal information to make intelligent QoS routing choices
//--------------------------------------------------------------------------------------------
class axi4_master_user_based_qos_routing_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_based_qos_routing_seq)
  
  // Configuration parameters
  int master_id = 0;
  int slave_id = 2;
  int num_transactions = 18;
  
  // QoS routing strategies
  typedef enum bit [2:0] {
    ROUTE_WORKLOAD_AWARE   = 3'b000, // Route based on workload characteristics
    ROUTE_BANDWIDTH_OPT    = 3'b001, // Optimize for bandwidth utilization
    ROUTE_LATENCY_OPT      = 3'b010, // Optimize for latency requirements
    ROUTE_ENERGY_AWARE     = 3'b011, // Energy-aware routing decisions
    ROUTE_THERMAL_AWARE    = 3'b100, // Thermal-aware routing
    ROUTE_FAULT_TOLERANT   = 3'b101, // Fault-tolerant routing
    ROUTE_LOAD_BALANCED    = 3'b110, // Load-balanced routing
    ROUTE_ADAPTIVE_SMART   = 3'b111  // Adaptive smart routing
  } qos_routing_strategy_e;
  
  // Application contexts for routing decisions
  typedef enum bit [3:0] {
    APP_MULTIMEDIA    = 4'b0000, // Multimedia applications
    APP_GAMING        = 4'b0001, // Gaming applications
    APP_SCIENTIFIC    = 4'b0010, // Scientific computing
    APP_DATABASE      = 4'b0011, // Database operations
    APP_WEB_SERVER    = 4'b0100, // Web server workloads
    APP_STORAGE       = 4'b0101, // Storage I/O operations
    APP_NETWORK       = 4'b0110, // Network processing
    APP_GRAPHICS      = 4'b0111, // Graphics rendering
    APP_AI_ML         = 4'b1000, // AI/ML workloads
    APP_CONTROL_SYS   = 4'b1001, // Control systems
    APP_SENSOR_DATA   = 4'b1010, // Sensor data processing
    APP_BACKGROUND    = 4'b1011, // Background tasks
    APP_SYSTEM_UTIL   = 4'b1100, // System utilities
    APP_USER_INTER    = 4'b1101, // User interface
    APP_SECURITY      = 4'b1110, // Security applications
    APP_DEBUG_TRACE   = 4'b1111  // Debug/trace applications
  } application_context_e;
  
  // USER-based QoS routing test scenarios
  typedef struct {
    string test_name;
    qos_routing_strategy_e routing_strategy;
    application_context_e app_context;
    bit [3:0] suggested_qos;
    bit [3:0] fallback_qos;
    bit [7:0] priority_hint;
    bit [7:0] resource_mask;
    string description;
  } qos_routing_test_t;
  
  qos_routing_test_t qos_routing_tests[] = '{
    // Workload-aware routing
    '{"workload_multimedia", ROUTE_WORKLOAD_AWARE, APP_MULTIMEDIA, 4'hA, 4'h8, 8'hBA, 8'h0F, "Multimedia workload-aware routing"},
    '{"workload_gaming", ROUTE_WORKLOAD_AWARE, APP_GAMING, 4'hE, 4'hC, 8'hC1, 8'h07, "Gaming workload low-latency routing"},
    '{"workload_scientific", ROUTE_WORKLOAD_AWARE, APP_SCIENTIFIC, 4'h6, 4'h4, 8'hC2, 8'h1F, "Scientific computing routing"},
    
    // Bandwidth optimization routing
    '{"bandwidth_database", ROUTE_BANDWIDTH_OPT, APP_DATABASE, 4'hC, 4'hA, 8'hBD, 8'h3F, "Database bandwidth optimization"},
    '{"bandwidth_storage", ROUTE_BANDWIDTH_OPT, APP_STORAGE, 4'hB, 4'h9, 8'h51, 8'h0F, "Storage I/O bandwidth routing"},
    
    // Latency optimization routing
    '{"latency_ui", ROUTE_LATENCY_OPT, APP_USER_INTER, 4'hF, 4'hD, 8'hD1, 8'h03, "User interface latency optimization"},
    '{"latency_control", ROUTE_LATENCY_OPT, APP_CONTROL_SYS, 4'hE, 4'hC, 8'hC3, 8'h07, "Control system latency routing"},
    '{"latency_network", ROUTE_LATENCY_OPT, APP_NETWORK, 4'hD, 4'hB, 8'hDA, 8'h0F, "Network processing latency routing"},
    
    // Energy-aware routing
    '{"energy_background", ROUTE_ENERGY_AWARE, APP_BACKGROUND, 4'h3, 4'h2, 8'hB6, 8'hFF, "Background task energy-aware"},
    '{"energy_sensor", ROUTE_ENERGY_AWARE, APP_SENSOR_DATA, 4'h5, 4'h3, 8'h5E, 8'h3F, "Sensor data energy routing"},
    
    // Thermal-aware routing
    '{"thermal_graphics", ROUTE_THERMAL_AWARE, APP_GRAPHICS, 4'h8, 4'h6, 8'h6A, 8'h1F, "Graphics thermal-aware routing"},
    '{"thermal_ai_ml", ROUTE_THERMAL_AWARE, APP_AI_ML, 4'h7, 4'h5, 8'hA1, 8'h7F, "AI/ML thermal management routing"},
    
    // Fault-tolerant routing
    '{"fault_security", ROUTE_FAULT_TOLERANT, APP_SECURITY, 4'hF, 4'hE, 8'h5C, 8'h01, "Security fault-tolerant routing"},
    '{"fault_system", ROUTE_FAULT_TOLERANT, APP_SYSTEM_UTIL, 4'hC, 4'hA, 8'h5F, 8'h03, "System utility fault routing"},
    
    // Load-balanced routing
    '{"balance_web", ROUTE_LOAD_BALANCED, APP_WEB_SERVER, 4'h9, 4'h7, 8'hDB, 8'h1F, "Web server load-balanced routing"},
    '{"balance_debug", ROUTE_LOAD_BALANCED, APP_DEBUG_TRACE, 4'h4, 4'h2, 8'hDB, 8'hFF, "Debug trace load balancing"},
    
    // Adaptive smart routing
    '{"adaptive_mixed", ROUTE_ADAPTIVE_SMART, APP_MULTIMEDIA, 4'hB, 4'h8, 8'hAD, 8'h3F, "Adaptive smart multimedia routing"},
    '{"adaptive_dynamic", ROUTE_ADAPTIVE_SMART, APP_GAMING, 4'hD, 4'hA, 8'hDF, 8'h0F, "Dynamic adaptive gaming routing"}
  };
  
  // Transaction parameters
  rand bit [ADDRESS_WIDTH-1:0] base_addr;
  
  constraint base_addr_c {
    base_addr == (slave_id == 2) ? 64'h0000_0008_8000_0000 : 64'h0000_0008_0000_0000;
  }
  
  extern function new(string name = "axi4_master_user_based_qos_routing_seq");
  extern virtual task body();
  extern virtual task generate_routing_transaction(int test_idx, bit is_write);
  extern virtual function bit [31:0] encode_routing_user_signal(qos_routing_test_t test_info);
  extern virtual function bit [3:0] calculate_routing_qos(qos_routing_test_t test_info);
  
endclass : axi4_master_user_based_qos_routing_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_user_based_qos_routing_seq::new(string name = "axi4_master_user_based_qos_routing_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Generates transactions with USER-based QoS routing
//-----------------------------------------------------------------------------
task axi4_master_user_based_qos_routing_seq::body();
  
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
  
  // Randomize base_addr based on slave_id constraint - critical fix for address generation
  if (!this.randomize()) begin
    `uvm_error(get_type_name(), "Failed to randomize base_addr for USER-based QoS routing sequence")
  end
  
  `uvm_info(get_type_name(), $sformatf("Starting USER-based QoS routing sequence: Master[%0d] → Slave[%0d], base_addr=0x%16h",
                                        master_id, slave_id, base_addr), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Testing %0d QoS routing strategies", qos_routing_tests.size()), UVM_MEDIUM)
  
  // Test each QoS routing strategy
  for (int i = 0; i < qos_routing_tests.size() && i < num_transactions; i++) begin
    `uvm_info(get_type_name(), $sformatf("Testing QoS routing %0d: %s - %s",
                                          i, qos_routing_tests[i].test_name, qos_routing_tests[i].description), UVM_HIGH)
    
    // Generate write transaction with QoS routing
    generate_routing_transaction(i, 1'b1);
    #180;
  end
  
  `uvm_info(get_type_name(), $sformatf("USER-based QoS routing sequence completed: %0d strategies tested",
                                        qos_routing_tests.size()), UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Task: generate_routing_transaction
// Creates transactions with USER-based QoS routing decisions
//-----------------------------------------------------------------------------
task axi4_master_user_based_qos_routing_seq::generate_routing_transaction(int test_idx, bit is_write);
  
  qos_routing_test_t current_test = qos_routing_tests[test_idx];
  bit [31:0] routing_user_signal;
  bit [3:0] routing_qos;
  int burst_len;
  
  routing_user_signal = encode_routing_user_signal(current_test);
  routing_qos = calculate_routing_qos(current_test);
  
  // Calculate burst length based on routing strategy
  if (current_test.routing_strategy == ROUTE_BANDWIDTH_OPT) 
    burst_len = $urandom_range(2, 7);
  else if (current_test.routing_strategy == ROUTE_LATENCY_OPT) 
    burst_len = 0;
  else 
    burst_len = $urandom_range(0, 3);
  
  if (is_write) begin
    // Generate write transaction with USER-based QoS routing
    `uvm_do_with(req, {
      req.tx_type == WRITE;
      req.awaddr == base_addr + (test_idx * 'h600);
      req.awid == awid_e'(master_id % 16);
      req.awlen == burst_len;
      req.awsize == WRITE_8_BYTES;
      req.awburst == WRITE_INCR;
      req.awqos == routing_qos; // QoS based on routing decision
      req.awuser == routing_user_signal;
      req.wuser == {16'h0000, current_test.priority_hint, current_test.resource_mask}; // Routing hints in WUSER
    })
    
    `uvm_info(get_type_name(), $sformatf("WRITE QoS ROUTING %s: Strategy=%0d, AppCtx=%0d, SuggestedQoS=%0d → RoutedQoS=%0d",
                                          current_test.test_name, current_test.routing_strategy, current_test.app_context,
                                          current_test.suggested_qos, routing_qos), UVM_HIGH)
    `uvm_info(get_type_name(), $sformatf("  AWUSER=0x%08h, PriorityHint=0x%02h, ResourceMask=0x%02h",
                                          routing_user_signal, current_test.priority_hint, current_test.resource_mask), UVM_HIGH)
  end
  else begin
    // Generate read transaction with USER-based QoS routing
    `uvm_do_with(req, {
      req.tx_type == READ;
      req.araddr == base_addr + (test_idx * 'h600) + 'h7000; // Offset for reads
      req.arid == arid_e'(master_id % 16);
      req.arlen == burst_len;
      req.arsize == READ_8_BYTES;
      req.arburst == READ_INCR;
      req.arqos == routing_qos; // QoS based on routing decision
      req.aruser == routing_user_signal;
    })
    
    `uvm_info(get_type_name(), $sformatf("READ QoS ROUTING %s: Strategy=%0d, AppCtx=%0d, SuggestedQoS=%0d → RoutedQoS=%0d",
                                          current_test.test_name, current_test.routing_strategy, current_test.app_context,
                                          current_test.suggested_qos, routing_qos), UVM_HIGH)
  end
  
endtask : generate_routing_transaction

//-----------------------------------------------------------------------------
// Function: encode_routing_user_signal
// Encodes routing information into USER signal
//-----------------------------------------------------------------------------
function bit [31:0] axi4_master_user_based_qos_routing_seq::encode_routing_user_signal(qos_routing_test_t test_info);
  bit [31:0] user_bits = 32'h00000000;
  
  // Encode routing information in USER bits
  user_bits[2:0]   = test_info.routing_strategy;  // Bits [2:0]: Routing strategy
  user_bits[6:3]   = test_info.app_context;       // Bits [6:3]: Application context
  user_bits[10:7]  = test_info.suggested_qos;     // Bits [10:7]: Suggested QoS
  user_bits[14:11] = test_info.fallback_qos;      // Bits [14:11]: Fallback QoS
  user_bits[18:15] = master_id[3:0];              // Bits [18:15]: Master ID
  user_bits[26:19] = test_info.priority_hint;     // Bits [26:19]: Priority hint
  user_bits[31:27] = $time & 5'h1F;               // Bits [31:27]: Timestamp
  
  return user_bits;
endfunction : encode_routing_user_signal

//-----------------------------------------------------------------------------
// Function: calculate_routing_qos
// Calculates QoS value based on routing strategy and context
//-----------------------------------------------------------------------------
function bit [3:0] axi4_master_user_based_qos_routing_seq::calculate_routing_qos(qos_routing_test_t test_info);
  bit [3:0] calculated_qos;
  int system_load_factor;
  int resource_availability;
  
  // Simulate system conditions
  system_load_factor = $urandom_range(1, 10); // 1=low load, 10=high load
  resource_availability = $urandom_range(1, 8); // 1=low availability, 8=high availability
  
  case (test_info.routing_strategy)
    ROUTE_WORKLOAD_AWARE: begin
      // Adjust QoS based on workload characteristics
      case (test_info.app_context)
        APP_MULTIMEDIA, APP_GRAPHICS: calculated_qos = test_info.suggested_qos;
        APP_GAMING: calculated_qos = (system_load_factor < 5) ? test_info.suggested_qos : test_info.fallback_qos;
        default: calculated_qos = test_info.suggested_qos;
      endcase
    end
    
    ROUTE_BANDWIDTH_OPT: begin
      // Optimize for bandwidth - higher QoS when resources available
      calculated_qos = (resource_availability > 5) ? test_info.suggested_qos : test_info.fallback_qos;
    end
    
    ROUTE_LATENCY_OPT: begin
      // Optimize for latency - always use high QoS for latency-critical apps
      calculated_qos = test_info.suggested_qos;
    end
    
    ROUTE_ENERGY_AWARE: begin
      // Reduce QoS to save energy for non-critical apps
      calculated_qos = (test_info.app_context == APP_BACKGROUND) ? 
                       (test_info.suggested_qos > 2 ? test_info.suggested_qos - 2 : test_info.suggested_qos) :
                       test_info.suggested_qos;
    end
    
    ROUTE_THERMAL_AWARE: begin
      // Reduce QoS if thermal conditions are concerning
      calculated_qos = (system_load_factor > 7) ? test_info.fallback_qos : test_info.suggested_qos;
    end
    
    ROUTE_FAULT_TOLERANT: begin
      // Use conservative QoS for fault tolerance
      calculated_qos = test_info.fallback_qos;
    end
    
    ROUTE_LOAD_BALANCED: begin
      // Distribute load by varying QoS
      calculated_qos = (system_load_factor < 4) ? test_info.suggested_qos :
                       (system_load_factor < 7) ? ((test_info.suggested_qos + test_info.fallback_qos) / 2) :
                       test_info.fallback_qos;
    end
    
    ROUTE_ADAPTIVE_SMART: begin
      // Intelligent adaptive routing based on multiple factors
      if (test_info.app_context == APP_GAMING || test_info.app_context == APP_USER_INTER) begin
        calculated_qos = test_info.suggested_qos; // Always high for interactive apps
      end else if (resource_availability > 6 && system_load_factor < 5) begin
        calculated_qos = test_info.suggested_qos; // High when resources available
      end else begin
        calculated_qos = test_info.fallback_qos; // Conservative otherwise
      end
    end
    
    default: begin
      calculated_qos = test_info.suggested_qos;
    end
  endcase
  
  return calculated_qos;
endfunction : calculate_routing_qos

`endif