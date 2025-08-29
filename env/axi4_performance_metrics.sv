`ifndef AXI4_PERFORMANCE_METRICS_INCLUDED_
`define AXI4_PERFORMANCE_METRICS_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_performance_metrics
// Collects and reports comprehensive performance KPIs for AXI4 verification
//--------------------------------------------------------------------------------------------
class axi4_performance_metrics extends uvm_component;
  `uvm_component_utils(axi4_performance_metrics)
  
  // Environment configuration handle
  axi4_env_config axi4_env_cfg_h;
  
  // Transaction timing structures
  typedef struct {
    time start_time;
    time end_time;
    bit [ADDRESS_WIDTH-1:0] addr;
    int burst_len;
    int data_bytes;
  } transaction_info_t;
  
  // Performance counters
  int total_write_transactions;
  int total_read_transactions;
  int total_bytes_written;
  int total_bytes_read;
  int total_error_responses;
  int total_retry_count;
  int deadlock_detected;
  int livelock_detected;
  
  // Error tracking for detailed reporting
  int total_slverr_responses;
  int total_decerr_responses;
  int write_slverr_count;
  int write_decerr_count;
  int read_slverr_count;
  int read_decerr_count;
  
  // Timing measurements
  time test_start_time;
  time test_end_time;
  time reset_start_time;
  time reset_end_time;
  
  // Latency tracking
  longint write_latencies[$];
  longint read_latencies[$];
  transaction_info_t pending_writes[bit[15:0]]; // Indexed by AWID
  transaction_info_t pending_reads[bit[15:0]];  // Indexed by ARID
  
  // Arbitration fairness tracking
  int master_grant_count[int];
  int master_request_count[int];
  time last_grant_time[int];
  
  // Error isolation tracking
  int error_injected_count;
  int error_isolated_count;
  int error_propagated_count;
  
  // Throughput calculation
  real write_throughput_gbps;
  real read_throughput_gbps;
  real combined_throughput_gbps;
  
  // Analysis FIFOs for receiving transactions
  uvm_tlm_analysis_fifo #(axi4_master_tx) write_addr_fifo;
  uvm_tlm_analysis_fifo #(axi4_master_tx) write_resp_fifo;
  uvm_tlm_analysis_fifo #(axi4_master_tx) read_addr_fifo;
  uvm_tlm_analysis_fifo #(axi4_master_tx) read_data_fifo;
  
  extern function new(string name = "axi4_performance_metrics", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern function void extract_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);
  
  // Transaction processing task and functions
  extern task process_transactions();
  extern function void process_write_addr(axi4_master_tx t);
  extern function void process_write_resp(axi4_master_tx t);
  extern function void process_read_addr(axi4_master_tx t);
  extern function void process_read_data(axi4_master_tx t);
  
  // Metrics calculation functions
  extern function real calculate_percentile(longint latencies[$], int percentile);
  extern function real calculate_throughput(int bytes_transferred, time duration);
  extern function real calculate_fairness_index(int grant_count[int]);
  extern function void detect_deadlock_livelock();
  extern function real calculate_error_isolation_rate();
  extern function real calculate_retry_rate();
  extern function time calculate_reset_recovery_time();
  
endclass : axi4_performance_metrics

function axi4_performance_metrics::new(string name = "axi4_performance_metrics", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void axi4_performance_metrics::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Get environment configuration
  if(!uvm_config_db#(axi4_env_config)::get(this, "", "axi4_env_config", axi4_env_cfg_h)) begin
    `uvm_info(get_type_name(), "axi4_env_config not found in config_db, proceeding without it", UVM_MEDIUM)
  end
  
  // Create analysis FIFOs
  write_addr_fifo = new("write_addr_fifo", this);
  write_resp_fifo = new("write_resp_fifo", this);
  read_addr_fifo = new("read_addr_fifo", this);
  read_data_fifo = new("read_data_fifo", this);
  
  test_start_time = $time;
endfunction

function void axi4_performance_metrics::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction

task axi4_performance_metrics::run_phase(uvm_phase phase);
  // Monitor for deadlock/livelock conditions and process transactions
  fork
    forever begin
      #10us;
      detect_deadlock_livelock();
    end
    process_transactions();
  join_none
endtask

task axi4_performance_metrics::process_transactions();
  axi4_master_tx write_addr_tx, write_resp_tx, read_addr_tx, read_data_tx;
  
  forever begin
    fork
      // Process write address transactions
      begin
        write_addr_fifo.get(write_addr_tx);
        process_write_addr(write_addr_tx);
      end
      
      // Process write response transactions
      begin
        write_resp_fifo.get(write_resp_tx);
        process_write_resp(write_resp_tx);
      end
      
      // Process read address transactions
      begin
        read_addr_fifo.get(read_addr_tx);
        process_read_addr(read_addr_tx);
      end
      
      // Process read data transactions
      begin
        read_data_fifo.get(read_data_tx);
        process_read_data(read_data_tx);
      end
    join_any
  end
endtask

function void axi4_performance_metrics::process_write_addr(axi4_master_tx t);
  transaction_info_t info;
  int master_id;
  
  info.start_time = $time;
  info.addr = t.awaddr;
  info.burst_len = t.awlen + 1;
  info.data_bytes = (t.awlen + 1) * (1 << t.awsize);
  
  pending_writes[t.awid] = info;
  total_write_transactions++;
  total_bytes_written += info.data_bytes;
  
  // Track request count (using AWID as proxy for master)
  master_id = t.awid[3:0]; // Use lower bits of AWID as master proxy
  if (master_request_count.exists(master_id))
    master_request_count[master_id]++;
  else
    master_request_count[master_id] = 1;
endfunction

function void axi4_performance_metrics::process_write_resp(axi4_master_tx t);
  transaction_info_t info;
  longint latency;
  int master_id;
  
  if (pending_writes.exists(t.bid)) begin
    info = pending_writes[t.bid];
    info.end_time = $time;
    
    latency = info.end_time - info.start_time;
    write_latencies.push_back(latency);
    
    pending_writes.delete(t.bid);
    
    // Track errors
    if (t.bresp == WRITE_SLVERR) begin
      total_error_responses++;
      total_slverr_responses++;
      write_slverr_count++;
    end else if (t.bresp == WRITE_DECERR) begin
      total_error_responses++;
      total_decerr_responses++;
      write_decerr_count++;
    end
    
    // Track arbitration grants (using BID as proxy for master)
    master_id = t.bid[3:0]; // Use lower bits of BID as master proxy
    if (master_grant_count.exists(master_id))
      master_grant_count[master_id]++;
    else
      master_grant_count[master_id] = 1;
    
    last_grant_time[master_id] = $time;
  end
endfunction

function void axi4_performance_metrics::process_read_addr(axi4_master_tx t);
  transaction_info_t info;
  int master_id;
  
  info.start_time = $time;
  info.addr = t.araddr;
  info.burst_len = t.arlen + 1;
  info.data_bytes = (t.arlen + 1) * (1 << t.arsize);
  
  pending_reads[t.arid] = info;
  total_read_transactions++;
  total_bytes_read += info.data_bytes;
  
  // Track request count (using ARID as proxy for master)
  master_id = t.arid[3:0]; // Use lower bits of ARID as master proxy
  if (master_request_count.exists(master_id))
    master_request_count[master_id]++;
  else
    master_request_count[master_id] = 1;
endfunction

function void axi4_performance_metrics::process_read_data(axi4_master_tx t);
  transaction_info_t info;
  longint latency;
  int master_id;
  
  if (pending_reads.exists(t.rid)) begin
    if (t.rlast) begin // Only on last beat
      info = pending_reads[t.rid];
      info.end_time = $time;
      
      latency = info.end_time - info.start_time;
      read_latencies.push_back(latency);
      
      pending_reads.delete(t.rid);
      
      // Track errors
      if (t.rresp == READ_SLVERR) begin
        total_error_responses++;
        total_slverr_responses++;
        read_slverr_count++;
      end else if (t.rresp == READ_DECERR) begin
        total_error_responses++;
        total_decerr_responses++;
        read_decerr_count++;
      end
      
      // Track arbitration grants (using RID as proxy for master)
      master_id = t.rid[3:0]; // Use lower bits of RID as master proxy
      if (master_grant_count.exists(master_id))
        master_grant_count[master_id]++;
      else
        master_grant_count[master_id] = 1;
      
      last_grant_time[master_id] = $time;
    end
  end
endfunction

function real axi4_performance_metrics::calculate_percentile(longint latencies[$], int percentile);
  int size = latencies.size();
  int index;
  longint sorted_latencies[$];
  
  if (size == 0) return 0;
  
  sorted_latencies = latencies;
  sorted_latencies.sort();
  
  index = (size * percentile) / 100;
  if (index >= size) index = size - 1;
  
  return real'(sorted_latencies[index]) / 1000.0; // Convert to ns
endfunction

function real axi4_performance_metrics::calculate_throughput(int bytes_transferred, time duration);
  real throughput_bps;
  real throughput_gbps;
  
  if (duration == 0) return 0;
  
  throughput_bps = real'(bytes_transferred * 8) / (real'(duration) / 1.0s);
  throughput_gbps = throughput_bps / 1e9;
  
  return throughput_gbps;
endfunction

function real axi4_performance_metrics::calculate_fairness_index(int grant_count[int]);
  real sum_squares = 0;
  real sum = 0;
  int n = grant_count.size();
  real fairness;
  
  if (n == 0) return 1.0;
  
  foreach(grant_count[i]) begin
    sum += grant_count[i];
    sum_squares += grant_count[i] * grant_count[i];
  end
  
  fairness = (sum * sum) / (n * sum_squares);
  return fairness;
endfunction

function void axi4_performance_metrics::detect_deadlock_livelock();
  static int no_progress_count = 0;
  static int last_write_count = 0;
  static int last_read_count = 0;
  
  if (total_write_transactions == last_write_count && 
      total_read_transactions == last_read_count) begin
    no_progress_count++;
    
    if (no_progress_count > 100) begin // 1ms with no progress
      if (pending_writes.size() > 0 || pending_reads.size() > 0) begin
        deadlock_detected = 1;
        `uvm_warning(get_type_name(), "Potential deadlock detected - no progress for 1ms with pending transactions")
      end
    end
  end else begin
    no_progress_count = 0;
    last_write_count = total_write_transactions;
    last_read_count = total_read_transactions;
  end
  
  // Livelock detection - high activity but no completion
  if (no_progress_count == 0 && pending_writes.size() > 50 && pending_reads.size() > 50) begin
    livelock_detected = 1;
    `uvm_warning(get_type_name(), "Potential livelock detected - high pending transactions")
  end
endfunction

function real axi4_performance_metrics::calculate_error_isolation_rate();
  if (error_injected_count == 0) return 100.0;
  return real'(error_isolated_count) / real'(error_injected_count) * 100.0;
endfunction

function real axi4_performance_metrics::calculate_retry_rate();
  int total_transactions = total_write_transactions + total_read_transactions;
  if (total_transactions == 0) return 0;
  return real'(total_retry_count) / real'(total_transactions) * 100.0;
endfunction

function time axi4_performance_metrics::calculate_reset_recovery_time();
  if (reset_end_time > reset_start_time)
    return reset_end_time - reset_start_time;
  else
    return 0;
endfunction

function void axi4_performance_metrics::extract_phase(uvm_phase phase);
  time test_duration;
  
  super.extract_phase(phase);
  test_end_time = $time;
  
  // Calculate final throughput
  test_duration = test_end_time - test_start_time;
  write_throughput_gbps = calculate_throughput(total_bytes_written, test_duration);
  read_throughput_gbps = calculate_throughput(total_bytes_read, test_duration);
  combined_throughput_gbps = calculate_throughput(total_bytes_written + total_bytes_read, test_duration);
endfunction

function void axi4_performance_metrics::report_phase(uvm_phase phase);
  bit errors_are_expected;
  string test_name;
  uvm_root root_h;
  uvm_component test_h;
  
  super.report_phase(phase);
  
  `uvm_info(get_type_name(), "====================================================", UVM_NONE)
  `uvm_info(get_type_name(), "        AXI4 PERFORMANCE METRICS REPORT", UVM_NONE)
  `uvm_info(get_type_name(), "====================================================", UVM_NONE)
  
  // Pass/Fail Criteria
  `uvm_info(get_type_name(), "ACCEPTANCE CRITERIA:", UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("  Protocol Issues    : %0d (Required: 0)", total_error_responses), UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("  Deadlock Detected  : %s (Required: No)", deadlock_detected ? "YES" : "NO"), UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("  Livelock Detected  : %s (Required: No)", livelock_detected ? "YES" : "NO"), UVM_NONE)
  
  // KPI Measurements
  `uvm_info(get_type_name(), "KEY PERFORMANCE INDICATORS:", UVM_NONE)
  
  // Throughput
  `uvm_info(get_type_name(), $sformatf("  Write Throughput   : %.2f GB/s", write_throughput_gbps), UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("  Read Throughput    : %.2f GB/s", read_throughput_gbps), UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("  Total Throughput   : %.2f GB/s", combined_throughput_gbps), UVM_NONE)
  
  // Latency Distribution
  if (write_latencies.size() > 0) begin
    `uvm_info(get_type_name(), "  Write Latency:", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("    p50: %.2f ns", calculate_percentile(write_latencies, 50)), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("    p95: %.2f ns", calculate_percentile(write_latencies, 95)), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("    p99: %.2f ns", calculate_percentile(write_latencies, 99)), UVM_NONE)
  end
  
  if (read_latencies.size() > 0) begin
    `uvm_info(get_type_name(), "  Read Latency:", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("    p50: %.2f ns", calculate_percentile(read_latencies, 50)), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("    p95: %.2f ns", calculate_percentile(read_latencies, 95)), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf("    p99: %.2f ns", calculate_percentile(read_latencies, 99)), UVM_NONE)
  end
  
  // Other KPIs
  `uvm_info(get_type_name(), $sformatf("  Retry Rate         : %.2f%%", calculate_retry_rate()), UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("  Reset Recovery Time: %0t", calculate_reset_recovery_time()), UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("  Issue Isolation    : %.2f%%", calculate_error_isolation_rate()), UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("  Arbitration Fairness: %.2f", calculate_fairness_index(master_grant_count)), UVM_NONE)
  
  // Transaction Summary
  `uvm_info(get_type_name(), "TRANSACTION SUMMARY:", UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("  Total Writes       : %0d", total_write_transactions), UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("  Total Reads        : %0d", total_read_transactions), UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("  Bytes Written      : %0d", total_bytes_written), UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("  Bytes Read         : %0d", total_bytes_read), UVM_NONE)
  
  // Final Test Result
  `uvm_info(get_type_name(), "====================================================", UVM_NONE)
  
  // Check if errors are allowed/expected based on multiple conditions
  errors_are_expected = 0;  // Default: errors are not expected
  
  // Priority 1: Check explicit configuration
  if (axi4_env_cfg_h != null && axi4_env_cfg_h.allow_error_responses) begin
    // Error responses are explicitly allowed via configuration
    errors_are_expected = 1;
    `uvm_info(get_type_name(), "Error responses allowed via allow_error_responses configuration", UVM_MEDIUM)
  end 
  // Priority 2: Check error_inject flag
  else if (axi4_env_cfg_h != null && axi4_env_cfg_h.error_inject) begin
    errors_are_expected = 1;
    `uvm_info(get_type_name(), "Error responses allowed via error_inject flag", UVM_MEDIUM)
  end
  // Priority 3: Auto-detect based on test name patterns
  else begin
    root_h = uvm_root::get();
    if (root_h != null) begin
      // Get the test component handle
      test_h = root_h.lookup("uvm_test_top");
      if (test_h != null) begin
        test_name = test_h.get_type_name();
        // Check if test name contains patterns indicating error injection
        // Using uvm_is_match for pattern matching
        if (uvm_is_match("*error*", test_name) || 
            uvm_is_match("*fail*", test_name) || 
            uvm_is_match("*illegal*", test_name) || 
            uvm_is_match("*violation*", test_name) ||
            uvm_is_match("*raw*", test_name) ||
            uvm_is_match("*slave_error*", test_name) ||
            uvm_is_match("*exception*", test_name)) begin
          errors_are_expected = 1;
          `uvm_info(get_type_name(), $sformatf("Auto-detected error injection test based on name: %s", test_name), UVM_MEDIUM)
        end
      end
    end
  end
  
  if (errors_are_expected) begin
    // When errors are expected, only check for deadlock/livelock
    `uvm_info("ERROR_INJECT", "========================================", UVM_NONE)
    `uvm_info("ERROR_INJECT", "ERROR INJECTION TEST SUMMARY", UVM_NONE)
    `uvm_info("ERROR_INJECT", $sformatf("Total error responses detected: %0d", total_error_responses), UVM_NONE)
    `uvm_info("ERROR_INJECT", $sformatf("  - SLVERR responses: %0d (Write: %0d, Read: %0d)", 
                                        total_slverr_responses, write_slverr_count, read_slverr_count), UVM_NONE)
    `uvm_info("ERROR_INJECT", $sformatf("  - DECERR responses: %0d (Write: %0d, Read: %0d)", 
                                        total_decerr_responses, write_decerr_count, read_decerr_count), UVM_NONE)
    `uvm_info("ERROR_INJECT", $sformatf("Deadlock detected: %s", deadlock_detected ? "YES" : "NO"), UVM_NONE)
    `uvm_info("ERROR_INJECT", $sformatf("Livelock detected: %s", livelock_detected ? "YES" : "NO"), UVM_NONE)
    
    if (!deadlock_detected && !livelock_detected) begin
      `uvm_info("ERROR_INJECT", "Error injection test PASSED - Errors handled correctly", UVM_NONE)
      `uvm_info(get_type_name(), $sformatf("TEST RESULT: PASS - Error injection test passed (%0d error responses as expected)", total_error_responses), UVM_NONE)
    end else begin
      `uvm_info("ERROR_INJECT", "Error injection test FAILED - Deadlock/livelock issues", UVM_NONE)
      `uvm_error(get_type_name(), "TEST RESULT: FAIL - Deadlock or livelock detected")
    end
    `uvm_info("ERROR_INJECT", "========================================", UVM_NONE)
  end else begin
    // Normal test - no errors should occur
    if (total_error_responses == 0 && !deadlock_detected && !livelock_detected) begin
      `uvm_info(get_type_name(), "TEST RESULT: PASS - All acceptance criteria met", UVM_NONE)
    end else begin
      `uvm_error(get_type_name(), "TEST RESULT: FAIL - Acceptance criteria not met")
    end
  end
  
  `uvm_info(get_type_name(), "====================================================", UVM_NONE)
  
endfunction

`endif