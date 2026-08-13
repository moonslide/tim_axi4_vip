`ifndef AXI4_TRACKB_RESET_TEST_INCLUDED_
`define AXI4_TRACKB_RESET_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_trackb_reset_test
//
// Track-B native vehicle for the "where does the verdict live" question.
//
// Why this exists
// ---------------
// axi4_reset_comprehensive_test and axi4_independent_reset_test gate their
// stimulus on bus_matrix_mode == NONE, so on a Track-B run they drive zero
// transactions (measured: Total Writes 0 / Total Reads 0 with
// +BUS_MATRIX_MODE=ENHANCED).  A green run there proves only that nothing
// exploded, not that the verdict logic was exercised.
//
// This test does two things those cannot:
//   1. it resets a real interconnect -- one with arbiters, outstanding-
//      transaction FIFOs and internal state that must survive reset while
//      traffic is in flight, which is where hdl_top's 16-cycle asserted-reset
//      requirement comes from (top/hdl_top.sv:291); and
//   2. it renders its PASS/FAIL verdict in report_phase, the pattern the two
//      reset tests were corrected to use.
//
// On Track-B the second point is not academic.  Late-phase errors OCCUR HERE
// NATURALLY: axi4_scoreboard's end-of-test accounting reports unmatched
// master transactions ("... ended with a master transaction still awaiting its
// slave partner.  The comparison never happened - this is NOT a pass") and
// axi4_performance_metrics::report_phase can raise "TEST RESULT: FAIL".  Both
// land after run_phase has ended.  A run_phase verdict cannot see either, and
// cannot see UVM_FATAL at all, so it would print PASSED into a log whose UVM
// summary reports errors -- with no plusarg or scaffold needed to provoke it.
//
// Build/run:
//   +define+BUS_MATRIX_FABRIC_IP +define+DATA_WIDTH=256 +define+AXI_ID_WIDTH=8 +define+AXI_ID_LAST=255
//   -f ../../sim/axi4_compile_fabric_ip.f
//   +UVM_TESTNAME=axi4_trackb_reset_test +BUS_MATRIX_MODE=ENHANCED
//--------------------------------------------------------------------------------------------
class axi4_trackb_reset_test extends axi4_trackb_smoke_test;
  `uvm_component_utils(axi4_trackb_reset_test)

  // UVM_ERROR count at the start of run_phase, so the verdict measures what
  // THIS test caused rather than anything inherited from build/connect.
  int pre_test_errors;

  int expected_global_resets;

  protected bit pre_reset_traffic_done;
  protected bit resets_done;
  protected bit post_reset_traffic_done;

  function new(string name = "axi4_trackb_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //------------------------------------------------------------------------
  // Task: wait_for_global_reset
  // Same completion protocol the baseline reset tests use: the reset checker
  // counts completed global reset cycles.  Bounded, so a fabric that never
  // releases reset fails with a message instead of hanging (the inherited
  // Track-B watchdog is the outer bound).
  //------------------------------------------------------------------------
  virtual task wait_for_global_reset(int expected_count);
    // Same idiom as the baseline reset tests (deadline + #1ns poll), but with a
    // longer deadline: hdl_top holds ARESETn for 16 cycles on a fabric build
    // (top/hdl_top.sv:291) and then idles 8 more before traffic, where the
    // direct-wiring path needs a single edge.
    time deadline = $time + 5000ns;
    while (axi4_env_h.axi4_reset_checker_h.global_reset_count < expected_count && $time < deadline) #1ns;
    if (axi4_env_h.axi4_reset_checker_h.global_reset_count != expected_count)
      `uvm_error(get_type_name(),
                 $sformatf("TIMEOUT: global reset completion %0d was not observed through the fabric (saw %0d)",
                           expected_count, axi4_env_h.axi4_reset_checker_h.global_reset_count))
  endtask : wait_for_global_reset

  //------------------------------------------------------------------------
  // Function: setup_axi4_env_cfg
  // The reset checker is not on by default; this test needs it.  The
  // scoreboard is deliberately KEPT (unlike axi4_reset_comprehensive_test,
  // which disables it): its end-of-test accounting is one of the late-phase
  // error sources this vehicle exists to expose to the report_phase verdict.
  //------------------------------------------------------------------------
  function void setup_axi4_env_cfg();
    super.setup_axi4_env_cfg();
    axi4_env_cfg_h.has_reset_checker = 1;
  endfunction : setup_axi4_env_cfg

  virtual task trackb_test_body();
    int num_masters = axi4_env_cfg_h.no_of_masters;

    if (axi4_env_h.axi4_reset_checker_h == null)
      `uvm_fatal(get_type_name(), "Reset checker was not constructed")

    write_seq     = new[num_masters];
    read_seq      = new[num_masters];
    slv_write_seq = new[axi4_env_cfg_h.no_of_slaves];
    slv_read_seq  = new[axi4_env_cfg_h.no_of_slaves];

    start_slave_responders("trackb_rst");

    // ---- Traffic through the fabric BEFORE the reset, so the reset lands on
    // an interconnect that has actually carried transactions.
    for (int m = 0; m < num_masters; m++) begin
      write_seq[m] = axi4_master_trackb_write_seq::type_id::create($sformatf("pre_rst_wr_%0d", m));
      write_seq[m].target_slave = target_slave;
      write_seq[m].start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[m]);
      trackb_masters_written++;
    end
    pre_reset_traffic_done = 1;

    // ---- Global reset cycles.  The fabric needs a multi-cycle assertion to
    // leave X (top/hdl_top.sv:291), so ask for more than the 2 cycles the
    // direct-wiring tests use.
    expected_global_resets = 0;
    repeat (2) begin
      expected_global_resets++;
      uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 16);
      uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);
      wait_for_global_reset(expected_global_resets);
    end
    resets_done = 1;

    // ---- Traffic AFTER the reset: the fabric must still route.
    for (int m = 0; m < num_masters; m++) begin
      read_seq[m] = axi4_master_trackb_read_seq::type_id::create($sformatf("post_rst_rd_%0d", m));
      read_seq[m].target_slave = target_slave;
      read_seq[m].read_addr    = write_seq[m].last_addr;
      read_seq[m].start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h_all[m]);
      trackb_masters_read++;
    end
    post_reset_traffic_done = 1;

    #5000ns;
  endtask : trackb_test_body

  virtual function string trackb_progress_str();
    return $sformatf("pre-reset traffic %s, %0d global resets %s, post-reset traffic %s",
                     pre_reset_traffic_done  ? "done" : "NOT REACHED",
                     expected_global_resets,
                     resets_done             ? "done" : "NOT REACHED",
                     post_reset_traffic_done ? "done" : "NOT REACHED");
  endfunction : trackb_progress_str

  task run_phase(uvm_phase phase);
    uvm_report_server svr;
    svr = uvm_report_server::get_server();
    pre_test_errors = svr.get_severity_count(UVM_ERROR);
    super.run_phase(phase);
  endtask : run_phase

  //------------------------------------------------------------------------
  // Function: report_phase
  // The verdict MUST live here.  See the class header: on Track-B the
  // scoreboard's end-of-test accounting and axi4_performance_metrics both
  // raise their errors after run_phase has ended, and UVM_FATAL is not
  // visible to a run_phase check at all.
  //------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    int final_errors;
    int final_fatals;

    super.report_phase(phase);

    svr          = uvm_report_server::get_server();
    final_errors = svr.get_severity_count(UVM_ERROR);
    final_fatals = svr.get_severity_count(UVM_FATAL);

    if (final_errors == pre_test_errors && final_fatals == 0)
      `uvm_info(get_type_name(), "TRACK-B RESET TEST PASSED", UVM_LOW)
    else
      `uvm_error(get_type_name(),
                 $sformatf("TRACK-B RESET TEST FAILED (UVM_ERROR %0d -> %0d, UVM_FATAL %0d)",
                           pre_test_errors, final_errors, final_fatals))
  endfunction : report_phase

endclass : axi4_trackb_reset_test

`endif
