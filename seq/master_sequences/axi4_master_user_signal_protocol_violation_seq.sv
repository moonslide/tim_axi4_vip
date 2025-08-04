`ifndef AXI4_MASTER_USER_SIGNAL_PROTOCOL_VIOLATION_SEQ_INCLUDED_
`define AXI4_MASTER_USER_SIGNAL_PROTOCOL_VIOLATION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_signal_protocol_violation_seq
// Tests USER signal protocol violations to verify error detection and handling
// Implements various violation scenarios to test system robustness
//--------------------------------------------------------------------------------------------
class axi4_master_user_signal_protocol_violation_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_signal_protocol_violation_seq)
  
  // Configuration parameters
  int master_id = 0;
  int slave_id = 2;
  int num_transactions = 16;
  
  // Violation types
  typedef enum bit [3:0] {
    VIOLATION_RESERVED_BITS     = 4'b0000, // Using reserved bit patterns
    VIOLATION_INVALID_ENCODING  = 4'b0001, // Invalid encoding schemes
    VIOLATION_INCONSISTENT_USER = 4'b0010, // Inconsistent USER across channels
    VIOLATION_SECURITY_MISMATCH = 4'b0011, // Security level mismatches
    VIOLATION_PARITY_ERROR      = 4'b0100, // Intentional parity errors
    VIOLATION_TRACE_CONFLICT    = 4'b0101, // Conflicting trace information
    VIOLATION_WIDTH_OVERFLOW    = 4'b0110, // Width constraint violations
    VIOLATION_TIMING_ERROR      = 4'b0111, // Timing constraint violations
    VIOLATION_CONTEXT_ERROR     = 4'b1000, // Context information errors
    VIOLATION_CHECKSUM_ERROR    = 4'b1001, // Checksum/hash errors
    VIOLATION_VERSION_ERROR     = 4'b1010, // Protocol version errors
    VIOLATION_ALIGNMENT_ERROR   = 4'b1011, // Alignment requirement violations
    VIOLATION_RANGE_ERROR       = 4'b1100, // Value range violations
    VIOLATION_DEPENDENCY_ERROR  = 4'b1101, // Dependency constraint violations
    VIOLATION_FORMAT_ERROR      = 4'b1110, // Format specification errors
    VIOLATION_CRITICAL_ERROR    = 4'b1111  // Critical system violations
  } violation_type_e;
  
  // Protocol violation test scenarios
  typedef struct {
    string test_name;
    violation_type_e violation_type;
    bit [31:0] awuser_violation;
    bit [31:0] aruser_violation;
    bit [31:0] wuser_violation;
    bit should_cause_error;
    string description;
  } violation_test_t;
  
  violation_test_t violation_tests[] = '{
    // Reserved bit pattern violations
    '{"reserved_bits_all_1", VIOLATION_RESERVED_BITS, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF, 1'b1, "All reserved bits set to 1"},
    '{"reserved_pattern_0xDEAD", VIOLATION_RESERVED_BITS, 32'hDEADBEEF, 32'hBEEFDEAD, 32'hDEADBEEF, 1'b1, "Reserved magic patterns"},
    
    // Invalid encoding violations
    '{"invalid_sec_level", VIOLATION_INVALID_ENCODING, 32'h0000001F, 32'h0000001F, 32'h0000001F, 1'b1, "Invalid security level encoding"},
    '{"invalid_trace_type", VIOLATION_INVALID_ENCODING, 32'h000000F0, 32'h000000F0, 32'h000000F0, 1'b1, "Invalid trace type encoding"},
    
    // Inconsistent USER signal violations
    '{"inconsistent_awuser_wuser", VIOLATION_INCONSISTENT_USER, 32'h12345678, 32'h87654321, 32'h87654321, 1'b1, "AWUSER/WUSER mismatch"},
    '{"inconsistent_contexts", VIOLATION_INCONSISTENT_USER, 32'h11111111, 32'h22222222, 32'h33333333, 1'b1, "All USER signals inconsistent"},
    
    // Security level mismatch violations
    '{"security_escalation", VIOLATION_SECURITY_MISMATCH, 32'h00000007, 32'h00000000, 32'h00000001, 1'b1, "Security level escalation"},
    '{"trust_zone_conflict", VIOLATION_SECURITY_MISMATCH, 32'h00000018, 32'h00000000, 32'h00000008, 1'b1, "Trust zone conflicts"},
    
    // Parity error violations
    '{"wrong_even_parity", VIOLATION_PARITY_ERROR, 32'h0000FF01, 32'h0000FF01, 32'h0000FF01, 1'b1, "Incorrect even parity bit"},
    '{"wrong_odd_parity", VIOLATION_PARITY_ERROR, 32'h0000FF20, 32'h0000FF20, 32'h0000FF20, 1'b1, "Incorrect odd parity bit"},
    
    // Trace information conflicts
    '{"trace_id_conflict", VIOLATION_TRACE_CONFLICT, 32'hABCD0000, 32'h1234ABCD, 32'h5678ABCD, 1'b1, "Conflicting trace IDs"},
    '{"trace_seq_error", VIOLATION_TRACE_CONFLICT, 32'hFFFF0000, 32'h0000FFFF, 32'h5555AAAA, 1'b1, "Invalid trace sequences"},
    
    // Width constraint violations
    '{"width_overflow", VIOLATION_WIDTH_OVERFLOW, 32'h80000000, 32'h80000000, 32'h80000000, 1'b1, "USER signal width overflow"},
    '{"width_underflow", VIOLATION_WIDTH_OVERFLOW, 32'h00000001, 32'h00000002, 32'h00000004, 1'b0, "Minor width constraint"},
    
    // Critical system violations
    '{"system_critical", VIOLATION_CRITICAL_ERROR, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hA5A5A5A5, 1'b1, "Critical system violation"},
    '{"protocol_corrupt", VIOLATION_CRITICAL_ERROR, 32'h5A5A5A5A, 32'hA5A5A5A5, 32'hF0F0F0F0, 1'b1, "Complete protocol corruption"}
  };
  
  // Transaction parameters
  rand bit [ADDRESS_WIDTH-1:0] base_addr;
  
  constraint base_addr_c {
    base_addr == (slave_id == 2) ? 64'h0000_0008_8000_0000 : 64'h0000_0008_0000_0000;
  }
  
  extern function new(string name = "axi4_master_user_signal_protocol_violation_seq");
  extern virtual task body();
  extern virtual task generate_violation_transaction(int test_idx, bit is_write);
  extern virtual function bit [3:0] calculate_error_severity(violation_type_e vtype);
  
endclass : axi4_master_user_signal_protocol_violation_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_user_signal_protocol_violation_seq::new(string name = "axi4_master_user_signal_protocol_violation_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Generates transactions with USER signal protocol violations
//-----------------------------------------------------------------------------
task axi4_master_user_signal_protocol_violation_seq::body();
  
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
  
  `uvm_info(get_type_name(), $sformatf("Starting USER protocol violation sequence: Master[%0d] → Slave[%0d]",
                                        master_id, slave_id), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Testing %0d protocol violation scenarios", violation_tests.size()), UVM_MEDIUM)
  `uvm_info(get_type_name(), "WARNING: This test intentionally violates USER signal protocols", UVM_MEDIUM)
  
  // Test each protocol violation scenario
  for (int i = 0; i < violation_tests.size() && i < num_transactions; i++) begin
    `uvm_info(get_type_name(), $sformatf("Testing violation %0d: %s - %s",
                                          i, violation_tests[i].test_name, violation_tests[i].description), UVM_HIGH)
    
    // Generate write transaction with protocol violation
    generate_violation_transaction(i, 1'b1);
    #200; // Longer delay to observe error responses
    
    // Generate read transaction with protocol violation (for some scenarios)
    if ((i % 2) == 0) begin
      generate_violation_transaction(i, 1'b0);
      #200;
    end
  end
  
  `uvm_info(get_type_name(), $sformatf("USER protocol violation sequence completed: %0d violations tested",
                                        violation_tests.size()), UVM_MEDIUM)
  `uvm_info(get_type_name(), "Expected: Some violations should trigger error responses or be flagged", UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Task: generate_violation_transaction
// Creates transactions with intentional USER signal protocol violations
//-----------------------------------------------------------------------------
task axi4_master_user_signal_protocol_violation_seq::generate_violation_transaction(int test_idx, bit is_write);
  
  violation_test_t current_test = violation_tests[test_idx];
  bit [3:0] error_severity;
  int burst_len = $urandom_range(0, 1);
  
  error_severity = calculate_error_severity(current_test.violation_type);
  
  if (is_write) begin
    // Generate write transaction with protocol violation
    `uvm_do_with(req, {
      req.tx_type == WRITE;
      req.awaddr == base_addr + (test_idx * 'h300);
      req.awid == awid_e'(master_id % 16);
      req.awlen == burst_len; // Short bursts for violation testing
      req.awsize == WRITE_8_BYTES;
      req.awburst == WRITE_INCR;
      req.awqos == (error_severity > 8) ? 4'hF : 4'h4; // High QoS for severe violations
      req.awuser == current_test.awuser_violation; // Intentional violation
      req.wuser == current_test.wuser_violation;   // Intentional violation
    })
    
    `uvm_info(get_type_name(), $sformatf("WRITE VIOLATION %s: Type=%0d, Severity=%0d, AWUSER=0x%08h, WUSER=0x%08h, ExpectError=%0b",
                                          current_test.test_name, current_test.violation_type, error_severity,
                                          current_test.awuser_violation, current_test.wuser_violation, 
                                          current_test.should_cause_error), UVM_HIGH)
  end
  else begin
    // Generate read transaction with protocol violation
    `uvm_do_with(req, {
      req.tx_type == READ;
      req.araddr == base_addr + (test_idx * 'h300) + 'h4000; // Offset for reads
      req.arid == arid_e'(master_id % 16);
      req.arlen == burst_len; // Short bursts for violation testing
      req.arsize == READ_8_BYTES;
      req.arburst == READ_INCR;
      req.arqos == (error_severity > 8) ? 4'hF : 4'h4; // High QoS for severe violations
      req.aruser == current_test.aruser_violation; // Intentional violation
    })
    
    `uvm_info(get_type_name(), $sformatf("READ VIOLATION %s: Type=%0d, Severity=%0d, ARUSER=0x%08h, ExpectError=%0b",
                                          current_test.test_name, current_test.violation_type, error_severity,
                                          current_test.aruser_violation, current_test.should_cause_error), UVM_HIGH)
  end
  
endtask : generate_violation_transaction

//-----------------------------------------------------------------------------
// Function: calculate_error_severity
// Calculates error severity level for different violation types
//-----------------------------------------------------------------------------
function bit [3:0] axi4_master_user_signal_protocol_violation_seq::calculate_error_severity(violation_type_e vtype);
  bit [3:0] severity;
  
  case (vtype)
    VIOLATION_RESERVED_BITS:     severity = 4'h6; // Medium severity
    VIOLATION_INVALID_ENCODING:  severity = 4'h8; // High severity
    VIOLATION_INCONSISTENT_USER: severity = 4'h7; // Medium-high severity
    VIOLATION_SECURITY_MISMATCH: severity = 4'hA; // Very high severity
    VIOLATION_PARITY_ERROR:      severity = 4'h5; // Medium severity
    VIOLATION_TRACE_CONFLICT:    severity = 4'h4; // Low-medium severity
    VIOLATION_WIDTH_OVERFLOW:    severity = 4'h7; // Medium-high severity
    VIOLATION_TIMING_ERROR:      severity = 4'h9; // High severity
    VIOLATION_CONTEXT_ERROR:     severity = 4'h6; // Medium severity
    VIOLATION_CHECKSUM_ERROR:    severity = 4'h8; // High severity
    VIOLATION_VERSION_ERROR:     severity = 4'hB; // Very high severity
    VIOLATION_ALIGNMENT_ERROR:   severity = 4'h5; // Medium severity
    VIOLATION_RANGE_ERROR:       severity = 4'h6; // Medium severity
    VIOLATION_DEPENDENCY_ERROR:  severity = 4'h7; // Medium-high severity
    VIOLATION_FORMAT_ERROR:      severity = 4'h8; // High severity
    VIOLATION_CRITICAL_ERROR:    severity = 4'hF; // Maximum severity
    default:                     severity = 4'h5; // Default medium severity
  endcase
  
  return severity;
endfunction : calculate_error_severity

`endif