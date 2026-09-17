`ifndef AXI4_X_INJECT_WITNESS_BASE_TEST_INCLUDED_
`define AXI4_X_INJECT_WITNESS_BASE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_x_inject_witness_base_test
//
// BENCH-066 directed test. Master 0 runs the basic X-injection sequence for
// ONE target signal with a valid slave-0 responder and nothing else on the
// bus (record section 5, minimal isolated reproduction). The verdict is read
// from the PIN-LEVEL witness of master 0's bound master_assertions instance
// (assertions/master_assertions.sv, x_witness_q): the target signal must have
// carried X for exactly the requested number of aclk cycles, in exactly one
// event, and no other witnessed signal may have carried X at all. A
// "Configured X injection ..." log line is not evidence and is not consulted.
//
// Before the BENCH-066 repair this test fails on every target: the sequence
// cleared its request before its own item reached the driver, so the BFM's
// X-drive task was never called and the witness stays at zero.
//
// After the repair the test additionally checks the status the driver stamped
// on the injection item (accepted/started/completed, result OK, cycles driven)
// and that its start/end aclk edges are the SAME edges the witness recorded.
//
// target == X_INJ_NONE is the injection-disabled control (matrix row 2):
// ordinary write + read traffic, every witness counter must read zero.
//
// Plusargs (ad-hoc experiments; the registered tests use class defaults):
//   +XINJ_TARGET=<0..6> (x_inject_target_e value) +XINJ_CYCLES=<n>
//   +XINJ_KEEP_ARMED=1  (assertion-detection self-test: gate stays low)
//   +XINJ_EXPECT=<x_inject_result_e> (e.g. 4 = INVALID for an illegal cycle count)
//--------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------
// Class: axi4_x_inject_recovery_sub
// Collects the COMPLETED transactions master 0's monitor publishes (write
// response packets / completed read bursts) so the recovery item can be
// checked from the pins: it must have completed with an OKAY response.
//--------------------------------------------------------------------------------------------
class axi4_x_inject_recovery_sub extends uvm_subscriber #(axi4_master_tx);
  `uvm_component_utils(axi4_x_inject_recovery_sub)
  axi4_master_tx pkts[$];
  function new(string name = "axi4_x_inject_recovery_sub", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  function void write(axi4_master_tx t);
    axi4_master_tx c;
    $cast(c, t.clone());
    pkts.push_back(c);
  endfunction : write
endclass : axi4_x_inject_recovery_sub

//--------------------------------------------------------------------------------------------
// Class: axi4_x_inject_expected_assert_catcher
// Assertion-detection self-test support (matrix row 9). Demotes ONLY the
// named expected failure (id X_PROTOCOL, NO_HANDSHAKE_DURING_X's message)
// to UVM_INFO and counts it, so the harness verdict (UVM_ERROR : 0) and the
// expected-failure signature (hits == requested cycles) are recorded
// separately. Anything else passes through untouched.
//--------------------------------------------------------------------------------------------
class axi4_x_inject_expected_assert_catcher extends uvm_report_catcher;
  int    hits = 0;
  string want_id  = "X_PROTOCOL";
  string want_msg = "*Handshake occurred during X on valid signal*";
  function new(string name = "axi4_x_inject_expected_assert_catcher");
    super.new(name);
  endfunction : new
  function action_e catch();
    if(get_severity() == UVM_ERROR && get_id() == want_id && uvm_is_match(want_msg, get_message())) begin
      hits++;
      set_severity(UVM_INFO);
      set_verbosity(UVM_LOW);
      set_message({"[EXPECTED assertion failure, counted by the self-test] ", get_message()});
    end
    return THROW;
  endfunction : catch
endclass : axi4_x_inject_expected_assert_catcher

class axi4_x_inject_witness_base_test extends axi4_base_test;
  `uvm_component_utils(axi4_x_inject_witness_base_test)

  x_inject_target_e        target        = X_INJ_AWADDR;
  int                      cycles        = 4;
  x_inject_assert_policy_e assert_policy = X_INJ_SUPPRESS_CHECKS;
  // Scenario knobs used by the derived tests below.
  x_inject_result_e        expected_result = X_INJ_RESULT_OK;
  bit                      inject_reset_midway = 1'b0;   // matrix row 7
  int                      reset_after_cycles  = 20;
  int                      bg_master           = -1;     // matrix row 6
  bit                      expect_named_assert = 1'b0;   // matrix row 9
  // AWADDR PRE_TRANSACTION injection asserts AWVALID with AWADDR=X for
  // `cycles` edges; a subordinate whose AWREADY stands high (this VIP's slave
  // BFM) legally accepts one orphan address transfer per edge and then pairs
  // the following W bursts with them, so the write pipeline is unbalanced BY
  // THE STIMULUS and the scoreboard's completeness accounting would report
  // the injection itself. That test therefore runs without the scoreboard
  // and does not claim the recovery write's response (see check_phase).
  bit                      recovery_verifiable = 1'b1;
  // Slave-0 address legal for master 0 in every bus-matrix mode (same rule
  // as axi4_rready_stall_base_test): BASE 4x4 maps S0 at 0x0000_0100_0000_0000,
  // ENHANCED at 0x0000_0008_0000_0000, NONE accepts anything.
  bit [63:0]               start_addr    = 64'h0000_0008_0000_2000;

  virtual master_assertions          ma_vif;
  virtual master_assertions          ma_bg_vif;
  axi4_virtual_x_inject_witness_seq  vseq_h;
  axi4_x_inject_recovery_sub         wr_done_h;
  axi4_x_inject_recovery_sub         rd_done_h;
  axi4_x_inject_expected_assert_catcher catcher_h;

  extern function new(string name = "axi4_x_inject_witness_base_test", uvm_component parent = null);
  extern virtual function void setup_axi4_env_cfg();
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void check_phase(uvm_phase phase);
  extern function void rand_check();
endclass : axi4_x_inject_witness_base_test

//--------------------------------------------------------------------------------------------
// Function: rand_check (+B066_RAND_CHECK)
// Empirical check (BENCH-065 lesson): a plain randomize() must never
// request an injection, and an attached request is not disturbed by
// randomize(). Illegal cycle counts are rejected by the BFM (invalid_cyc*).
//--------------------------------------------------------------------------------------------
function void axi4_x_inject_witness_base_test::rand_check();
  axi4_master_tx t = axi4_master_tx::type_id::create("rc");
  int n_default_inject = 0, n_default_cycles = 0, n_default_policy = 0, n_fail = 0;
  for(int i = 0; i < 2000; i++) begin
    if(!t.randomize()) n_fail++;
    if(t.x_inject_target != X_INJ_NONE) n_default_inject++;
    if(t.x_inject_cycles != 0)          n_default_cycles++;
    if(t.x_inject_assert_policy != X_INJ_SUPPRESS_CHECKS) n_default_policy++;
  end
  // The descriptor is not a solved variable: an attached request must
  // survive a subsequent randomize() of the item unchanged.
  t.x_inject_target = X_INJ_AWADDR; t.x_inject_cycles = 5;
  if(!t.randomize()) n_fail++;
  if(t.x_inject_target != X_INJ_AWADDR || t.x_inject_cycles != 5) n_fail++;
  if(n_default_inject || n_default_cycles || n_default_policy || n_fail) begin
    `uvm_error(get_type_name(), $sformatf("B066_RAND_CHECK FAILED: default_inject=%0d default_cycles=%0d default_policy=%0d failures=%0d",
                                          n_default_inject, n_default_cycles, n_default_policy, n_fail))
  end
  else begin
    `uvm_info(get_type_name(), "B066_RAND_CHECK PASSED: 2000 plain randomize() -> 0 injections/0 cycles/0 policy flips; an attached request survives randomize() unchanged (validation is the BFM's, see invalid_cyc*.log)", UVM_LOW)
  end
endfunction : rand_check

function axi4_x_inject_witness_base_test::new(string name = "axi4_x_inject_witness_base_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

// The scoreboard's count comparisons expect traffic on the channel the mode
// names, so a read-side target runs in ONLY_READ_DATA and a write-side one
// in ONLY_WRITE_DATA (same rule as axi4_rready_stall_base_test); the control
// sends both and keeps the default WRITE_READ_DATA. The plusarg override is
// read here too because this runs before build_phase.
function void axi4_x_inject_witness_base_test::setup_axi4_env_cfg();
  int v;
  super.setup_axi4_env_cfg();
  if($value$plusargs("XINJ_TARGET=%d", v)) target = x_inject_target_e'(v);
  case(target)
    X_INJ_ARVALID, X_INJ_RREADY: axi4_env_cfg_h.write_read_mode_h = ONLY_READ_DATA;
    X_INJ_NONE:                  ;
    default:                     axi4_env_cfg_h.write_read_mode_h = ONLY_WRITE_DATA;
  endcase
  if(target == X_INJ_AWADDR) begin
    axi4_env_cfg_h.has_scoreboard = 0;   // see recovery_verifiable
    recovery_verifiable = 1'b0;
    // The orphan X-address transfers decode to DECERR/SLVERR at the
    // subordinate; the performance metrics count those as protocol issues
    // unless the environment declares it is injecting errors (exactly what
    // axi4_error_inject_base_test declares for the registered X tests).
    axi4_env_cfg_h.error_inject = 1;
  end
  if(inject_reset_midway || bg_master >= 0) begin
    // A mid-run global reset / random background traffic are outside what
    // the scoreboard's count accounting can be asked to balance; these two
    // scenarios prove ownership and restore, not data integrity (precedent:
    // axi4_basic_reset_test).
    axi4_env_cfg_h.has_scoreboard = 0;
  end
  if(inject_reset_midway) begin
    // A reset that lands while a BLOCKING read is between its AR and R
    // phases leaves that read's data phase waiting out the claim escape
    // (the AR was dropped on the reset edge and the subordinate may or may
    // not have accepted it in the same time step) - pre-existing reset
    // behaviour of the master BFM, reported as a landmine candidate, outside
    // what this scenario proves (restore / result / release). The
    // environment's error_inject flag (which axi4_env copies onto every
    // agent config - a per-agent setting made here would be overwritten)
    // demotes those two abandon reports to warnings, exactly as every
    // registered error-injection test already runs.
    axi4_env_cfg_h.error_inject = 1;
  end
endfunction : setup_axi4_env_cfg

function void axi4_x_inject_witness_base_test::build_phase(uvm_phase phase);
  int v;
  super.build_phase(phase);
  if($value$plusargs("XINJ_TARGET=%d", v))     target        = x_inject_target_e'(v);
  if($value$plusargs("XINJ_CYCLES=%d", v))     cycles        = v;
  if($value$plusargs("XINJ_KEEP_ARMED=%d", v)) assert_policy = (v != 0) ? X_INJ_KEEP_ARMED : X_INJ_SUPPRESS_CHECKS;
  if($value$plusargs("XINJ_EXPECT=%d", v))     expected_result = x_inject_result_e'(v);
  if($test$plusargs("B066_RAND_CHECK")) rand_check();
  if(test_config.bus_matrix_mode == axi4_bus_matrix_ref::BASE_BUS_MATRIX) begin
    start_addr = 64'h0000_0100_0000_2000;
  end
  // The bound assertion interface of master 0 is exported by
  // axi4_master_agent_bfm under "*axi4_master_agent_h[0]*".
  if(!uvm_config_db#(virtual master_assertions)::get(null, "uvm_test_top.axi4_env_h.axi4_master_agent_h[0]", "master_assertions", ma_vif)) begin
    `uvm_fatal(get_type_name(), "cannot get() master 0's master_assertions handle - the witness is unreachable")
  end
  if(bg_master >= 0) begin
    if(!uvm_config_db#(virtual master_assertions)::get(null, $sformatf("uvm_test_top.axi4_env_h.axi4_master_agent_h[%0d]", bg_master), "master_assertions", ma_bg_vif)) begin
      `uvm_fatal(get_type_name(), $sformatf("cannot get() master %0d's master_assertions handle", bg_master))
    end
  end
  if(expect_named_assert) begin
    catcher_h = new("catcher_h");
    uvm_report_cb::add(null, catcher_h);
  end
  wr_done_h = axi4_x_inject_recovery_sub::type_id::create("wr_done_h", this);
  rd_done_h = axi4_x_inject_recovery_sub::type_id::create("rd_done_h", this);
endfunction : build_phase

function void axi4_x_inject_witness_base_test::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  axi4_env_h.axi4_master_agent_h[0].axi4_master_mon_proxy_h.axi4_master_write_response_analysis_port.connect(wr_done_h.analysis_export);
  axi4_env_h.axi4_master_agent_h[0].axi4_master_mon_proxy_h.axi4_master_read_data_analysis_port.connect(rd_done_h.analysis_export);
endfunction : connect_phase

task axi4_x_inject_witness_base_test::run_phase(uvm_phase phase);
  vseq_h = axi4_virtual_x_inject_witness_seq::type_id::create("vseq_h");
  vseq_h.target        = target;
  vseq_h.cycles        = cycles;
  vseq_h.assert_policy = assert_policy;
  vseq_h.start_addr    = start_addr;
  vseq_h.expected_result = expected_result;
  vseq_h.bg_master     = bg_master;
  // Background master 1 (NS CPU) is only answered OKAY at S1 (DDR
  // non-secure user, 0x0000_0008_4000_0000) with PROT=111 (claude.md access
  // matrix); NONE mode keeps the ENHANCED address map for that region.
  vseq_h.bg_addr       = 64'h0000_0008_4000_3000;
  vseq_h.bg_prot       = 3'b111;
  `uvm_info(get_type_name(), $sformatf("BENCH-066 run: target=%s cycles=%0d policy=%s addr=0x%016h expected=%s reset_midway=%0d bg_master=%0d",
                                       target.name(), cycles, assert_policy.name(), start_addr, expected_result.name(), inject_reset_midway, bg_master), UVM_LOW)
  phase.raise_objection(this);
  if(inject_reset_midway) begin
    // Matrix row 7: pull ARESETn low once the injection has been driving
    // for reset_after_cycles edges (read straight off the witness's open
    // run), through hdl_top's global reset injector.
    fork
      begin
        wait(ma_vif.x_run_cnt[int'(target)] >= reset_after_cycles);
        `uvm_info(get_type_name(), $sformatf("BENCH-066: X on %s has been visible for %0d edges - injecting a 3-cycle global reset now (%0t)",
                                             target.name(), ma_vif.x_run_cnt[int'(target)], $time), UVM_LOW)
        uvm_config_db#(int)::set(null, "*", "global_reset_duration_cycles", 3);
        uvm_config_db#(bit)::set(null, "*", "inject_global_reset", 1);
      end
    join_none
  end
  vseq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  // Let the witness close its last event and the monitor publish the last
  // transaction.
  #100ns;
  phase.drop_objection(this);
endtask : run_phase

function void axi4_x_inject_witness_base_test::check_phase(uvm_phase phase);
  super.check_phase(phase);

  // 0. Whatever the scenario, nothing may still own a wire at the end and
  //    the assertion gate must be low (no stale X drive, no disabled-check
  //    leakage - matrix row 7).
  if(ma_vif.x_drive_active !== 1'b0 || ma_vif.x_inject_mode !== 1'b0) begin
    `uvm_error(get_type_name(), $sformatf("BENCH-066: at end of test master 0 still reports x_drive_active=%0b x_inject_mode=%0b - ownership / assertion gate not released",
                                          ma_vif.x_drive_active, ma_vif.x_inject_mode))
  end

  // 1. Pin-level witness on the target signal.
  if(target != X_INJ_NONE && expected_result == X_INJ_RESULT_INVALID) begin
    // Rejected request: nothing may have been driven, and the status must
    // say so (accepted=0, completed=1, INVALID). The BFM's own uvm_error on
    // the rejection is the expected signature of this ad-hoc run.
    axi4_master_tx it = vseq_h.master_x_seq_h.last_inject_item;
    if(ma_vif.x_witness_event_count(target) != 0)
      `uvm_error(get_type_name(), $sformatf("BENCH-066 invalid-request: X observed on %s although the request was to be rejected", target.name()))
    if(it == null || it.x_inject_accepted || it.x_inject_started || !it.x_inject_completed || it.x_inject_result != X_INJ_RESULT_INVALID)
      `uvm_error(get_type_name(), "BENCH-066 invalid-request: status does not read accepted=0 started=0 completed=1 result=INVALID")
    else
      `uvm_info(get_type_name(), $sformatf("BENCH-066 invalid-request: rejected as expected (cycles=%0d), nothing driven, witness 0", it.x_inject_cycles), UVM_LOW)
  end
  else if(target != X_INJ_NONE && inject_reset_midway) begin
    // Reset case: exactly one event, shorter than requested, closed by the
    // reset (counting stops while ARESETn is low), and the driver's status
    // says ABORTED_BY_RESET with the same edge count.
    int ev  = ma_vif.x_witness_event_count(target);
    int cyc = ma_vif.x_witness_cycle_total(target);
    if(ev != 1 || cyc < reset_after_cycles || cyc >= cycles) begin
      `uvm_error(get_type_name(), $sformatf("BENCH-066 reset: expected one X event on %s cut short by reset (>= %0d and < %0d edges), witness saw %0d event(s) totalling %0d",
                                            target.name(), reset_after_cycles, cycles, ev, cyc))
    end
    else begin
      `uvm_info(get_type_name(), $sformatf("BENCH-066 reset witness: X on %s for %0d of %0d requested edges, cut by ARESETn", target.name(), cyc, cycles), UVM_LOW)
    end
  end
  else if(target != X_INJ_NONE) begin
    int ev  = ma_vif.x_witness_event_count(target);
    int cyc = ma_vif.x_witness_cycle_total(target);
    if(ev == 0) begin
      `uvm_error(get_type_name(), $sformatf("BENCH-066: no X was observed on %s at master 0 - the requested %0d-cycle injection never reached the interface",
                                            target.name(), cycles))
    end
    else if(ev != 1 || cyc != cycles) begin
      `uvm_error(get_type_name(), $sformatf("BENCH-066: expected exactly one X event of %0d aclk cycle(s) on %s, the witness saw %0d event(s) totalling %0d cycle(s)",
                                            cycles, target.name(), ev, cyc))
    end
    else begin
      foreach(ma_vif.x_witness_q[i]) begin
        if(ma_vif.x_witness_q[i].sig == target) begin
          `uvm_info(get_type_name(), $sformatf("BENCH-066 witness: X on %s for %0d aclk cycle(s), %0t .. %0t",
                                               target.name(), ma_vif.x_witness_q[i].cycles,
                                               ma_vif.x_witness_q[i].start_time, ma_vif.x_witness_q[i].end_time), UVM_LOW)
        end
      end
    end
  end

  // 2. No X on any signal that was not asked for (control: none at all).
  for(int s = 1; s < X_INJ_NUM_TARGETS; s++) begin
    x_inject_target_e sig = x_inject_target_e'(s);
    if(sig == target) continue;
    if(ma_vif.x_witness_event_count(sig) != 0) begin
      `uvm_error(get_type_name(), $sformatf("BENCH-066: X observed on %s (%0d event(s), %0d cycle(s)) which was NOT requested (target=%s)",
                                            sig.name(), ma_vif.x_witness_event_count(sig), ma_vif.x_witness_cycle_total(sig), target.name()))
    end
  end

  // 3. The driver-stamped status of the request must agree with the pins:
  //    accepted+started+completed, result OK, the requested number of cycles
  //    driven, and its first/last aclk edges are the SAME edges the witness
  //    recorded (request / consume / complete timestamps agree - matrix row 1).
  if(target != X_INJ_NONE && vseq_h.master_x_seq_h != null && expected_result != X_INJ_RESULT_INVALID) begin
    bit               acc, st, cmp;
    x_inject_result_e res;
    time              t0, t1;
    int               drv;
    string            src;
    if(target == X_INJ_AWVALID) begin
      axi4_master_x_inject_idle_req r = vseq_h.master_x_seq_h.last_idle_req;
      if(r == null) begin `uvm_error(get_type_name(), "BENCH-066: no idle request object was created for AWVALID") return; end
      acc = r.x_inject_accepted; st = r.x_inject_started; cmp = r.x_inject_completed; res = r.x_inject_result;
      t0 = r.x_inject_start_time; t1 = r.x_inject_end_time; drv = r.x_inject_cycles_driven; src = "idle request";
    end
    else begin
      axi4_master_tx it = vseq_h.master_x_seq_h.last_inject_item;
      if(it == null) begin `uvm_error(get_type_name(), "BENCH-066: no injection item was returned") return; end
      acc = it.x_inject_accepted; st = it.x_inject_started; cmp = it.x_inject_completed; res = it.x_inject_result;
      t0 = it.x_inject_start_time; t1 = it.x_inject_end_time; drv = it.x_inject_cycles_driven; src = "injection item";
    end
    `uvm_info(get_type_name(), $sformatf("BENCH-066 %s status: accepted=%0d started=%0d completed=%0d result=%s driven=%0d %0t .. %0t",
                                         src, acc, st, cmp, res.name(), drv, t0, t1), UVM_LOW)
    if(inject_reset_midway) begin
      // hdl_top's global reset injector lowers ARESETn with a BLOCKING
      // assignment on a posedge; the driver's hold loop and the witness's
      // always block sample ARESETn on that same posedge in whatever order
      // the scheduler picks, so the reset edge itself is counted by one side
      // and not the other. Either is a legitimate reading of "the edge on
      // which reset fell"; the driven count may exceed the witnessed one by
      // at most that single edge (landmine candidate, see the handoff).
      int wit = ma_vif.x_witness_cycle_total(target);
      if(!(acc && st && cmp) || res != X_INJ_RESULT_ABORTED_BY_RESET || drv < wit || drv > wit + 1) begin
        `uvm_error(get_type_name(), $sformatf("BENCH-066 reset: %s status should be ABORTED_BY_RESET with driven == witnessed (%0d) or witnessed+1: accepted=%0d started=%0d completed=%0d result=%s driven=%0d",
                                              src, wit, acc, st, cmp, res.name(), drv))
      end
    end
    else if(!(acc && st && cmp) || res != X_INJ_RESULT_OK || drv != cycles) begin
      `uvm_error(get_type_name(), $sformatf("BENCH-066: %s status does not say OK for %0d cycles (accepted=%0d started=%0d completed=%0d result=%s driven=%0d)",
                                            src, cycles, acc, st, cmp, res.name(), drv))
    end
    else begin
      bit matched = 0;
      foreach(ma_vif.x_witness_q[i]) begin
        if(ma_vif.x_witness_q[i].sig == target && ma_vif.x_witness_q[i].start_time == t0 && ma_vif.x_witness_q[i].end_time == t1 && ma_vif.x_witness_q[i].cycles == drv)
          matched = 1;
      end
      if(!matched) begin
        `uvm_error(get_type_name(), $sformatf("BENCH-066: the %s says X on %s %0t .. %0t (%0d cycles) but no witness event on that signal has those edges",
                                              src, target.name(), t0, t1, drv))
      end
    end
  end

  // 4. Recovery: the separate recovery item (descriptor NONE) completed with
  //    an OKAY response, as seen by master 0's monitor.
  if(expected_result == X_INJ_RESULT_INVALID) begin
    // no recovery expectation for a rejected request
  end
  else if(target != X_INJ_NONE && vseq_h.master_x_seq_h != null && !recovery_verifiable) begin
    `uvm_info(get_type_name(), $sformatf("BENCH-066: recovery response after a %s injection is NOT claimable in this VIP - the subordinate accepted %0d orphan address transfer(s) with AWADDR=X and pairs the following W bursts with them (see recovery_verifiable)",
                                         target.name(), cycles), UVM_LOW)
  end
  else if(target != X_INJ_NONE && vseq_h.master_x_seq_h != null) begin
    axi4_master_tx rec = vseq_h.master_x_seq_h.last_recovery_item;
    bit found = 0;
    if(rec == null) begin
      `uvm_error(get_type_name(), "BENCH-066: no recovery item was sent")
    end
    else if(rec.tx_type == WRITE) begin
      foreach(wr_done_h.pkts[i]) begin
        if(wr_done_h.pkts[i].awaddr == rec.awaddr && wr_done_h.pkts[i].bresp == WRITE_OKAY) found = 1;
      end
      if(!found) `uvm_error(get_type_name(), $sformatf("BENCH-066: recovery write at 0x%016h was not seen completing with OKAY by master 0's monitor (%0d write responses seen)", rec.awaddr, wr_done_h.pkts.size()))
    end
    else begin
      foreach(rd_done_h.pkts[i]) begin
        if(rd_done_h.pkts[i].araddr == rec.araddr && rd_done_h.pkts[i].rresp == READ_OKAY && rd_done_h.pkts[i].rlast) found = 1;
      end
      if(!found) `uvm_error(get_type_name(), $sformatf("BENCH-066: recovery read at 0x%016h was not seen completing with OKAY by master 0's monitor (%0d completed reads seen)", rec.araddr, rd_done_h.pkts.size()))
    end
    if(found) `uvm_info(get_type_name(), "BENCH-066 recovery item completed with OKAY (pin-level, master 0 monitor)", UVM_LOW)
  end

  // 5. Concurrent traffic on another master (matrix row 6): that master's own
  //    interface saw no X at all, and it actually was busy.
  if(bg_master >= 0) begin
    for(int s = 1; s < X_INJ_NUM_TARGETS; s++) begin
      x_inject_target_e sig = x_inject_target_e'(s);
      if(ma_bg_vif.x_witness_event_count(sig) != 0) begin
        `uvm_error(get_type_name(), $sformatf("BENCH-066: master %0d (background traffic only) saw X on %s (%0d event(s)) - cross-agent injection / request theft",
                                              bg_master, sig.name(), ma_bg_vif.x_witness_event_count(sig)))
      end
    end
    if(vseq_h.bg_writes_done == 0) begin
      `uvm_error(get_type_name(), $sformatf("BENCH-066: background master %0d completed no writes - the concurrent-traffic scenario was not exercised", bg_master))
    end
    else begin
      `uvm_info(get_type_name(), $sformatf("BENCH-066 concurrent: master %0d completed %0d background writes and witnessed no X on any signal", bg_master, vseq_h.bg_writes_done), UVM_LOW)
    end
  end

  // 6. Assertion-detection self-test (matrix row 9): with KEEP_ARMED the
  //    named assertion must have fired once per X edge (AWREADY stands high
  //    at this subordinate), and the catcher is the only thing that demoted
  //    it. The expected signature is stated here, apart from the harness
  //    verdict.
  if(expect_named_assert) begin
    if(catcher_h.hits != cycles) begin
      `uvm_error(get_type_name(), $sformatf("BENCH-066 assertion self-test: expected NO_HANDSHAKE_DURING_X (id X_PROTOCOL) to fire %0d time(s) with the gate KEPT ARMED, caught %0d",
                                            cycles, catcher_h.hits))
    end
    else begin
      `uvm_info(get_type_name(), $sformatf("BENCH-066 assertion self-test: NO_HANDSHAKE_DURING_X fired %0d time(s) as expected (gate kept armed by X_INJ_KEEP_ARMED); those %0d reports were demoted by the test's catcher and are the expected-failure signature",
                                           catcher_h.hits, catcher_h.hits), UVM_LOW)
    end
  end
endfunction : check_phase

//--------------------------------------------------------------------------------------------
// One test per target signal plus the injection-disabled control, so the
// regression list can run them separately in every bus-matrix mode.
//--------------------------------------------------------------------------------------------
class axi4_x_inject_awvalid_witness_test extends axi4_x_inject_witness_base_test;
  `uvm_component_utils(axi4_x_inject_awvalid_witness_test)
  function new(string name = "axi4_x_inject_awvalid_witness_test", uvm_component parent = null);
    super.new(name, parent); target = X_INJ_AWVALID; cycles = 4;
  endfunction : new
endclass : axi4_x_inject_awvalid_witness_test

class axi4_x_inject_awaddr_witness_test extends axi4_x_inject_witness_base_test;
  `uvm_component_utils(axi4_x_inject_awaddr_witness_test)
  function new(string name = "axi4_x_inject_awaddr_witness_test", uvm_component parent = null);
    super.new(name, parent); target = X_INJ_AWADDR; cycles = 4;
  endfunction : new
endclass : axi4_x_inject_awaddr_witness_test

class axi4_x_inject_wdata_witness_test extends axi4_x_inject_witness_base_test;
  `uvm_component_utils(axi4_x_inject_wdata_witness_test)
  function new(string name = "axi4_x_inject_wdata_witness_test", uvm_component parent = null);
    super.new(name, parent); target = X_INJ_WDATA; cycles = 4;
  endfunction : new
endclass : axi4_x_inject_wdata_witness_test

class axi4_x_inject_arvalid_witness_test extends axi4_x_inject_witness_base_test;
  `uvm_component_utils(axi4_x_inject_arvalid_witness_test)
  function new(string name = "axi4_x_inject_arvalid_witness_test", uvm_component parent = null);
    super.new(name, parent); target = X_INJ_ARVALID; cycles = 4;
  endfunction : new
endclass : axi4_x_inject_arvalid_witness_test

class axi4_x_inject_bready_witness_test extends axi4_x_inject_witness_base_test;
  `uvm_component_utils(axi4_x_inject_bready_witness_test)
  function new(string name = "axi4_x_inject_bready_witness_test", uvm_component parent = null);
    super.new(name, parent); target = X_INJ_BREADY; cycles = 4;
  endfunction : new
endclass : axi4_x_inject_bready_witness_test

class axi4_x_inject_rready_witness_test extends axi4_x_inject_witness_base_test;
  `uvm_component_utils(axi4_x_inject_rready_witness_test)
  function new(string name = "axi4_x_inject_rready_witness_test", uvm_component parent = null);
    super.new(name, parent); target = X_INJ_RREADY; cycles = 4;
  endfunction : new
endclass : axi4_x_inject_rready_witness_test

// Matrix row 9: the same AWVALID idle injection with the assertion gate kept
// armed - NO_HANDSHAKE_DURING_X must fire (expected signature) and nothing else.
class axi4_x_inject_assert_detect_test extends axi4_x_inject_witness_base_test;
  `uvm_component_utils(axi4_x_inject_assert_detect_test)
  function new(string name = "axi4_x_inject_assert_detect_test", uvm_component parent = null);
    super.new(name, parent); target = X_INJ_AWVALID; cycles = 4;
    assert_policy = X_INJ_KEEP_ARMED; expect_named_assert = 1'b1;
  endfunction : new
endclass : axi4_x_inject_assert_detect_test

// Matrix row 7: a global reset lands while a long ARVALID injection is in
// progress; the driver must restore the wire on the reset edge, report
// ABORTED_BY_RESET, release ownership, and the recovery read must complete.
class axi4_x_inject_reset_abort_test extends axi4_x_inject_witness_base_test;
  `uvm_component_utils(axi4_x_inject_reset_abort_test)
  function new(string name = "axi4_x_inject_reset_abort_test", uvm_component parent = null);
    super.new(name, parent); target = X_INJ_ARVALID; cycles = 200;
    expected_result = X_INJ_RESULT_ABORTED_BY_RESET; inject_reset_midway = 1'b1; reset_after_cycles = 20;
  endfunction : new
endclass : axi4_x_inject_reset_abort_test

// Matrix row 6: master 1 keeps writing while master 0 injects on WDATA;
// master 1's interface must never see X.
class axi4_x_inject_concurrent_test extends axi4_x_inject_witness_base_test;
  `uvm_component_utils(axi4_x_inject_concurrent_test)
  function new(string name = "axi4_x_inject_concurrent_test", uvm_component parent = null);
    super.new(name, parent); target = X_INJ_WDATA; cycles = 4; bg_master = 1;
  endfunction : new
endclass : axi4_x_inject_concurrent_test

class axi4_x_inject_none_control_test extends axi4_x_inject_witness_base_test;
  `uvm_component_utils(axi4_x_inject_none_control_test)
  function new(string name = "axi4_x_inject_none_control_test", uvm_component parent = null);
    super.new(name, parent); target = X_INJ_NONE; cycles = 0;
  endfunction : new
endclass : axi4_x_inject_none_control_test

`endif
