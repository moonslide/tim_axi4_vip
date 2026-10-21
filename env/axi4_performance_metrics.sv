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
  
  //-------------------------------------------------------
  // Stall-detector tuning.
  //
  // These were localparams, and that made the whole detector DEAD CODE in this
  // suite.  Measured over the 413 logs of a full regression: the median test
  // ends at ~5us and the longest at 25us, while the first poll is at 10us and
  // the deadlock window is 100 polls == 1ms.  Only 15 of 413 tests reached even
  // ONE poll, and none came within 40x of the window, so deadlock_detected and
  // livelock_detected were permanently 0 -- which quietly reduced
  // report_phase's acceptance criteria to "no error responses".
  //
  // As variables read from the config DB in build_phase, a directed test can
  // scale the whole detector down to microseconds and actually exercise it,
  // while every existing test keeps the historical numbers untouched.
  //
  // LIVELOCK_STALL_POLLS stays half of DEADLOCK_STALL_POLLS by default so a
  // livelock report precedes the deadlock report for the same stall rather
  // than racing it.
  //-------------------------------------------------------
  time stall_poll_interval        = 10us;
  int  deadlock_stall_polls       = 100;
  int  livelock_stall_polls       = 50;
  // Backlog depth that makes a stall interesting. Unlike the previous magic
  // 50, this is compared against sums over every (sb_src_index, ID) FIFO,
  // which are unbounded, so it is named and documented rather than inline.
  int  livelock_pending_threshold = 50;

  // Completion counters.  total_write_transactions/total_read_transactions
  // are incremented in process_write_addr/process_read_addr, i.e. they count
  // REQUESTS, not completions.  Stall detection must not be based on those: a
  // test that issues a burst of requests and then stops issuing while the
  // responses drain normally has a frozen request count and a deep backlog,
  // which is healthy behaviour, not a stall.
  int completed_write_count;
  int completed_read_count;

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
  // AXI permits multiple outstanding transactions with the same ID, and each
  // master port has its own ID namespace. Keep an issue-order FIFO for every
  // (observing master port, ID) pair so response latency is never correlated
  // with a different request or overwritten by a later same-ID request.
  transaction_info_t pending_writes[int][int][$]; // [sb_src_index][AWID]
  transaction_info_t pending_reads[int][int][$];  // [sb_src_index][ARID]
  
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
  extern task watch_reset();
  extern function void flush_pending_on_reset(int src_index);
  extern function void detect_deadlock_livelock();
  extern function int pending_write_count();
  extern function int pending_read_count();
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
  
  // Optional stall-detector overrides.  Absent => the historical values above.
  // A directed test sets these before the env is built so it can trigger the
  // detector inside a microsecond-scale run; see the class-level comment.
  void'(uvm_config_db#(time)::get(this, "", "stall_poll_interval",        stall_poll_interval));
  void'(uvm_config_db#(int)::get (this, "", "deadlock_stall_polls",       deadlock_stall_polls));
  void'(uvm_config_db#(int)::get (this, "", "livelock_stall_polls",       livelock_stall_polls));
  void'(uvm_config_db#(int)::get (this, "", "livelock_pending_threshold", livelock_pending_threshold));
  `uvm_info(get_type_name(),
            $sformatf("Stall detector: poll=%0t deadlock=%0d polls livelock=%0d polls pending_threshold=%0d",
                      stall_poll_interval, deadlock_stall_polls, livelock_stall_polls,
                      livelock_pending_threshold), UVM_MEDIUM)

  test_start_time = $time;
endfunction

function void axi4_performance_metrics::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction

task axi4_performance_metrics::run_phase(uvm_phase phase);
  // Monitor for deadlock/livelock conditions and process transactions
  fork
    forever begin
      #(stall_poll_interval);
      detect_deadlock_livelock();
    end
    process_transactions();
    watch_reset();
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
  
  pending_writes[t.sb_src_index][int'(t.awid)].push_back(info);
  total_write_transactions++;
  total_bytes_written += info.data_bytes;
  
  // sb_src_index is the observing master port; AWID is not a master identity.
  master_id = t.sb_src_index;
  if (master_request_count.exists(master_id))
    master_request_count[master_id]++;
  else
    master_request_count[master_id] = 1;
endfunction

function void axi4_performance_metrics::process_write_resp(axi4_master_tx t);
  transaction_info_t info;
  longint latency;
  int master_id;

  // Every B beat is one completed write, whatever its response.
  completed_write_count++;
  
  // Count every observed error response, even if its matching request was
  // flushed or otherwise unavailable for latency correlation. Metrics must
  // never turn a real SLVERR/DECERR into a passing acceptance result.
  if (t.bresp == WRITE_SLVERR) begin
    total_error_responses++;
    total_slverr_responses++;
    write_slverr_count++;
  end else if (t.bresp == WRITE_DECERR) begin
    total_error_responses++;
    total_decerr_responses++;
    write_decerr_count++;
  end

  if (pending_writes.exists(t.sb_src_index) &&
      pending_writes[t.sb_src_index].exists(int'(t.bid)) &&
      pending_writes[t.sb_src_index][int'(t.bid)].size() > 0) begin
    info = pending_writes[t.sb_src_index][int'(t.bid)].pop_front();
    info.end_time = $time;
    
    latency = info.end_time - info.start_time;
    write_latencies.push_back(latency);
    
    if (pending_writes[t.sb_src_index][int'(t.bid)].size() == 0) begin
      pending_writes[t.sb_src_index].delete(int'(t.bid));
      if (pending_writes[t.sb_src_index].num() == 0)
        pending_writes.delete(t.sb_src_index);
    end
    
    // Attribute the grant to the source master port, not to BID bits.
    master_id = t.sb_src_index;
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
  
  pending_reads[t.sb_src_index][int'(t.arid)].push_back(info);
  total_read_transactions++;
  total_bytes_read += info.data_bytes;
  
  // sb_src_index is the observing master port; ARID is not a master identity.
  master_id = t.sb_src_index;
  if (master_request_count.exists(master_id))
    master_request_count[master_id]++;
  else
    master_request_count[master_id] = 1;
endfunction

function void axi4_performance_metrics::process_read_data(axi4_master_tx t);
  transaction_info_t info;
  longint latency;
  int master_id;
  
  // The monitor publishes one completed read burst at RLAST.
  if (t.rlast) completed_read_count++;

  // Count an error response before attempting latency correlation so an
  // unmatched response still fails a normal test.
  if (t.rlast && t.rresp == READ_SLVERR) begin
    total_error_responses++;
    total_slverr_responses++;
    read_slverr_count++;
  end else if (t.rlast && t.rresp == READ_DECERR) begin
    total_error_responses++;
    total_decerr_responses++;
    read_decerr_count++;
  end

  if (t.rlast && pending_reads.exists(t.sb_src_index) &&
      pending_reads[t.sb_src_index].exists(int'(t.rid)) &&
      pending_reads[t.sb_src_index][int'(t.rid)].size() > 0) begin
      info = pending_reads[t.sb_src_index][int'(t.rid)].pop_front();
      info.end_time = $time;
      
      latency = info.end_time - info.start_time;
      read_latencies.push_back(latency);
      
      if (pending_reads[t.sb_src_index][int'(t.rid)].size() == 0) begin
        pending_reads[t.sb_src_index].delete(int'(t.rid));
        if (pending_reads[t.sb_src_index].num() == 0)
          pending_reads.delete(t.sb_src_index);
      end
      
      // Attribute the grant to the source master port, not to RID bits.
      master_id = t.sb_src_index;
      if (master_grant_count.exists(master_id))
        master_grant_count[master_id]++;
      else
        master_grant_count[master_id] = 1;
      
      last_grant_time[master_id] = $time;
  end
endfunction

function int axi4_performance_metrics::pending_write_count();
  int count = 0;
  int id;
  // The inner walk is an explicit first()/next() over THIS src's IDs, NOT
  // foreach(pending_writes[src][id]): identifiers inside foreach brackets are new
  // loop variables (IEEE 1800 12.7.3), so on a strict simulator that inner form
  // re-iterates every src under each outer src and multiplies the count, which
  // feeds the deadlock/livelock verdict in detect_deadlock_livelock().
  foreach (pending_writes[src]) begin
    if (pending_writes[src].first(id)) do
      count += pending_writes[src][id].size();
    while (pending_writes[src].next(id));
  end
  return count;
endfunction

function int axi4_performance_metrics::pending_read_count();
  int count = 0;
  int id;
  // The inner walk is an explicit first()/next() over THIS src's IDs, NOT
  // foreach(pending_reads[src][id]): identifiers inside foreach brackets are new
  // loop variables (IEEE 1800 12.7.3), so on a strict simulator that inner form
  // re-iterates every src under each outer src and multiplies the count, which
  // feeds the deadlock/livelock verdict in detect_deadlock_livelock().
  foreach (pending_reads[src]) begin
    if (pending_reads[src].first(id)) do
      count += pending_reads[src][id].size();
    while (pending_reads[src].next(id));
  end
  return count;
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

//--------------------------------------------------------------------------------------------
// Task: watch_reset
// AXI4 discards outstanding transactions across reset, so every request this
// component is still holding becomes unanswerable the moment ARESETn drops.
// env/axi4_scoreboard.sv:759 already subscribes to the same global event for
// the same reason; this component did not, and that only became a defect when
// pending_writes/pending_reads changed from a map keyed by ID -- where the next
// same-ID request OVERWROTE the stale entry, so it self-healed -- to per-(port,
// ID) FIFOs, which accumulate.
//--------------------------------------------------------------------------------------------
task axi4_performance_metrics::watch_reset();
  // One watcher per master port, listening to that port's OWN reset event.
  // The global "axi4_sb_reset_e" is deliberately NOT used here: every master
  // interface triggers it from its own aresetn (see
  // agent/master_agent_bfm/axi4_master_monitor_bfm.sv), so an INDEPENDENT reset
  // of one master would look identical to a reset of all of them. Flushing
  // every source on that would drop the outstanding requests of masters that
  // are still mid-transaction -- zeroing their pending count and letting
  // detect_deadlock_livelock() read a busy bus as idle, which is the exact
  // inverse of the stale-entry problem the flush exists to solve.
  int num_masters = (axi4_env_cfg_h != null) ? axi4_env_cfg_h.no_of_masters : NO_OF_MASTERS;

  for (int i = 0; i < num_masters; i++) begin
    automatic int idx = i;
    fork
      forever begin
        uvm_event_pool::get_global($sformatf("axi4_sb_reset_e_%0d", idx)).wait_trigger();
        flush_pending_on_reset(idx);
      end
    join_none
  end
endtask

//--------------------------------------------------------------------------------------------
// Function: flush_pending_on_reset
// Two things have to go, not one:
//  * the pending FIFOs, or the first post-reset response of a reused ID pops a
//    pre-reset request and reports a latency for two unrelated transfers, while
//    the real post-reset request stays queued for good -- so
//    pending_*_count() never returns to 0 again. That last part matters beyond
//    the metric: detect_deadlock_livelock() uses "nothing outstanding" to
//    decide the bus is IDLE rather than STALLED, so a permanently non-empty
//    queue reintroduces exactly the false deadlock that check was fixed to
//    avoid.
//  * the completion baselines, because dropping the queues does not change
//    completed_*_count, and leaving last_*_count behind would make the next
//    poll read as progress that never happened.
//--------------------------------------------------------------------------------------------
function void axi4_performance_metrics::flush_pending_on_reset(int src_index);
  int dropped_w = 0;
  int dropped_r = 0;
  int id;

  // Explicit first()/next() walks over THIS port's IDs, NOT
  // foreach(pending_writes[src_index][id]): identifiers inside foreach brackets
  // are new loop variables (IEEE 1800 12.7.3), so on a strict simulator that form
  // iterates every port, not src_index, and over-counts dropped_w/dropped_r.
  if (pending_writes.exists(src_index)) begin
    if (pending_writes[src_index].first(id)) do
      dropped_w += pending_writes[src_index][id].size();
    while (pending_writes[src_index].next(id));
    pending_writes.delete(src_index);
  end
  if (pending_reads.exists(src_index)) begin
    if (pending_reads[src_index].first(id)) do
      dropped_r += pending_reads[src_index][id].size();
    while (pending_reads[src_index].next(id));
    pending_reads.delete(src_index);
  end

  if (dropped_w != 0 || dropped_r != 0)
    `uvm_info(get_type_name(),
              $sformatf("Reset of master port %0d: discarded %0d outstanding write(s) and %0d outstanding read(s) from its latency FIFOs",
                        src_index, dropped_w, dropped_r), UVM_MEDIUM)
endfunction

function void axi4_performance_metrics::detect_deadlock_livelock();
  static int no_progress_count = 0;
  static int last_write_count = 0;
  static int last_read_count = 0;

  // Compare COMPLETIONS, not requests.  total_write_transactions and
  // total_read_transactions are bumped in the address callbacks, so a test
  // that has stopped issuing while its responses drain would look frozen here
  // even though the bus is emptying normally -- and with the livelock arm
  // below now requiring a stall (rather than the old, inverted
  // no_progress_count == 0), that would have turned every end-of-test drain
  // longer than LIVELOCK_STALL_POLLS into a livelock failure.
  // An IDLE bus is not a stalled one.  With nothing outstanding there is
  // nothing that could be stuck, so the timer is held at zero rather than
  // being allowed to run.  Without this the counter climbs freely through any
  // quiet period -- the `pending > 0` guard below only suppresses the REPORT,
  // not the counting -- and the first transaction issued after >1ms of quiet
  // is declared deadlocked on the very next poll, before its response has had
  // any chance to arrive.  (The previous request-based comparison hid this:
  // issuing a request changed total_*_transactions and so reset the timer.
  // Moving to completions removed that reset path and made the idle period
  // prime a false deadlock.)
  if (pending_write_count() == 0 && pending_read_count() == 0) begin
    no_progress_count = 0;
    last_write_count  = completed_write_count;
    last_read_count   = completed_read_count;
  end
  else if (completed_write_count == last_write_count &&
           completed_read_count == last_read_count) begin
    no_progress_count++;

    if (no_progress_count > deadlock_stall_polls) begin
      deadlock_detected = 1;
      `uvm_warning(get_type_name(),
                   $sformatf("Potential deadlock detected - no completion for %0d polls with %0d writes / %0d reads outstanding",
                             no_progress_count, pending_write_count(), pending_read_count()))
    end
  end else begin
    no_progress_count = 0;
    last_write_count = completed_write_count;
    last_read_count = completed_read_count;
  end
  
  // Livelock detection - the bus is busy but completions have stalled.
  //
  // Two things were wrong with the previous predicate
  // (`no_progress_count == 0 && pending_write_count() > 50 && pending_read_count() > 50`):
  //
  //  1. `no_progress_count == 0` is only true when completions DID advance on
  //     this poll. Requiring it made the check fire on a bus that is making
  //     progress and merely has a deep backlog -- i.e. a healthy
  //     high-outstanding bus, which AXI explicitly permits. That is the
  //     opposite of livelock, and report_phase turns the flag into
  //     "TEST RESULT: FAIL", so it is a false failure waiting to happen.
  //  2. The counts changed from map sizes (keyed by AxID, so bounded by the
  //     4-bit ID space at 16 -- the arm could never fire at all) to sums over
  //     every (sb_src_index, ID) FIFO, which are unbounded. The magic 50 was
  //     calibrated against the first meaning and carried over to the second.
  //
  // What it now means: completions have been stalled for a sustained window --
  // long enough to be more than jitter, short of the deadlock threshold -- while
  // a large backlog is outstanding. Either direction alone is enough; requiring
  // BOTH to exceed the threshold meant a read-only or write-only stall was
  // invisible.
  //
  // Honest limitation: distinguishing livelock from deadlock properly needs
  // evidence that work is being retried while not completing.  This VIP has no
  // such signal -- `total_retry_count` is declared and read by
  // calculate_retry_rate() but is never incremented anywhere, so it is
  // permanently 0.  Until retry accounting exists, this check is "a sustained
  // stall with a deep backlog", which is a subset of deadlock rather than a
  // truly independent condition.
  if (no_progress_count >= livelock_stall_polls && no_progress_count <= deadlock_stall_polls &&
      (pending_write_count() > livelock_pending_threshold ||
       pending_read_count()  > livelock_pending_threshold)) begin
    livelock_detected = 1;
    `uvm_warning(get_type_name(),
                 $sformatf("Potential livelock detected - completions stalled for %0d polls with %0d writes / %0d reads outstanding",
                           no_progress_count, pending_write_count(), pending_read_count()))
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
