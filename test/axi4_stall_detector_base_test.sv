`ifndef AXI4_STALL_DETECTOR_BASE_TEST_INCLUDED_
`define AXI4_STALL_DETECTOR_BASE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_stall_detector_base_test
//
// Shared setup for the tests that exercise axi4_performance_metrics' deadlock
// and livelock detection.
//
// Why these tests exist
// ---------------------
// The detector had no coverage at all, and could not have had any: measured
// over the 413 logs of a full regression, the median test ends at ~5us and the
// longest at 25us, while the detector's first poll was at 10us and its
// deadlock window was 100 polls == 1ms.  15 of 413 tests reached even one
// poll; none reached the window.  deadlock_detected and livelock_detected were
// therefore permanently 0, which silently reduced report_phase's acceptance
// criteria to "no error responses".  Two separate defects in the detector's
// predicate were introduced and fixed in one session without a single test
// noticing either way.
//
// Scaling the detector down (poll 100ns, windows of a few polls) puts a real
// trigger inside an ordinary microsecond-scale run.  The production defaults
// are untouched: only these tests publish the overrides.
//
// KNOWN GAP -- only the NEGATIVE direction ships.  A positive test (a genuine
// stall that the detector must report) needs a way to hold a transaction
// outstanding, and this VIP has none that works:
//   * starting no slave responder does not stall anything -- measured, four
//     writes still completed with a write-latency p50 of 2.62ns, because the
//     slave BFM answers regardless;
//   * axi4_master_tx.b_wait_states is an OBSERVED field the monitor fills in,
//     not a drive control -- setting it to 300 (6us at the 20ns clock) moved
//     the measured latency only from 2.62ns to 18.18ns.
// Closing this needs a BFM knob that suppresses or delays responses on demand.
// Until then the detector is half covered: it is proven not to fire when it
// must not, and unproven when it must.
//--------------------------------------------------------------------------------------------
class axi4_stall_detector_base_test extends axi4_base_test;
  `uvm_component_utils(axi4_stall_detector_base_test)

  // Scaled-down detector. livelock_polls < deadlock_polls keeps the intended
  // ordering (a livelock report precedes the deadlock report for one stall).
  time detector_poll            = 100ns;
  int  detector_deadlock_polls  = 10;   // deadlock after ~1us of stall
  int  detector_livelock_polls  = 5;    // livelock after ~0.5us of stall
  int  detector_pending_thresh  = 1;    // >1 outstanding is "a backlog" here

  extern function new(string name = "axi4_stall_detector_base_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern function axi4_performance_metrics metrics();
  extern function void check_detector(bit expect_deadlock, bit expect_livelock, string scenario);
endclass : axi4_stall_detector_base_test

function axi4_stall_detector_base_test::new(string name = "axi4_stall_detector_base_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_stall_detector_base_test::build_phase(uvm_phase phase);
  // Published before super.build_phase() so the metrics component picks them
  // up in its own build_phase.
  uvm_config_db#(time)::set(null, "*", "stall_poll_interval",        detector_poll);
  uvm_config_db#(int)::set (null, "*", "deadlock_stall_polls",       detector_deadlock_polls);
  uvm_config_db#(int)::set (null, "*", "livelock_stall_polls",       detector_livelock_polls);
  uvm_config_db#(int)::set (null, "*", "livelock_pending_threshold", detector_pending_thresh);
  super.build_phase(phase);
endfunction : build_phase

function axi4_performance_metrics axi4_stall_detector_base_test::metrics();
  if(axi4_env_h == null || axi4_env_h.axi4_performance_metrics_h == null)
    `uvm_fatal(get_type_name(), "Performance metrics component was not constructed")
  return axi4_env_h.axi4_performance_metrics_h;
endfunction : metrics

//--------------------------------------------------------------------------------------------
// Function: check_detector
// One place for the verdict so both directions read the same way, and so a
// wrong result names the scenario instead of just the flag.
//--------------------------------------------------------------------------------------------
function void axi4_stall_detector_base_test::check_detector(bit expect_deadlock, bit expect_livelock, string scenario);
  bit got_deadlock = (metrics().deadlock_detected != 0);
  bit got_livelock = (metrics().livelock_detected != 0);

  `uvm_info(get_type_name(),
            $sformatf("[%s] deadlock=%0d (expected %0d), livelock=%0d (expected %0d)",
                      scenario, got_deadlock, expect_deadlock, got_livelock, expect_livelock),
            UVM_LOW)

  if(got_deadlock !== expect_deadlock)
    `uvm_error(get_type_name(),
               $sformatf("[%s] deadlock_detected=%0d, expected %0d", scenario, got_deadlock, expect_deadlock))
  if(got_livelock !== expect_livelock)
    `uvm_error(get_type_name(),
               $sformatf("[%s] livelock_detected=%0d, expected %0d", scenario, got_livelock, expect_livelock))
endfunction : check_detector

`endif
