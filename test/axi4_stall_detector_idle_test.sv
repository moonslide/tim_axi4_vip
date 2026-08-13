`ifndef AXI4_STALL_DETECTOR_IDLE_TEST_INCLUDED_
`define AXI4_STALL_DETECTOR_IDLE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_stall_detector_idle_test
//
// NEGATIVE direction: an idle bus is not a stalled bus.
//
// Leave the bus completely quiet for well past the deadlock window, then issue
// one ordinary write with a slave responder running.  Nothing here is stuck, so
// neither flag may be set.
//
// This is the regression test for a real defect: while the stall timer was
// based on REQUEST counts, issuing a request reset it.  Moving the timer to
// COMPLETION counts (correct, so that a normal end-of-test drain is not
// mistaken for a stall) removed that reset path, and the timer was then free to
// run all through a quiet period -- so the first transaction after >1 window of
// idle was declared deadlocked on the very next poll, before its response could
// possibly have arrived.  The fix holds the timer at zero whenever nothing is
// outstanding.
//
// Without the scaled-down thresholds from the base class this scenario is
// untestable: the real window is 1ms and no test in the suite runs past 25us.
//--------------------------------------------------------------------------------------------
class axi4_stall_detector_idle_test extends axi4_stall_detector_base_test;
  `uvm_component_utils(axi4_stall_detector_idle_test)

  extern function new(string name = "axi4_stall_detector_idle_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
endclass : axi4_stall_detector_idle_test

function axi4_stall_detector_idle_test::new(string name = "axi4_stall_detector_idle_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_stall_detector_idle_test::run_phase(uvm_phase phase);
  axi4_master_write_seq  write_seq;
  axi4_slave_bk_write_seq slave_write_seq;
  time idle_window;

  phase.raise_objection(this);

  // Three deadlock windows of complete quiet -- far more than enough to prime a
  // timer that wrongly runs while idle.
  idle_window = detector_poll * detector_deadlock_polls * 3;
  `uvm_info(get_type_name(),
            $sformatf("Idling %0t with an empty bus (deadlock window is %0t)",
                      idle_window, detector_poll * detector_deadlock_polls), UVM_LOW)
  #(idle_window);

  check_detector(.expect_deadlock(0), .expect_livelock(0),
                 .scenario("idle bus, no transactions issued yet"));

  // Now one ordinary write, with a responder so it actually completes.
  fork
    begin : slave_responder
      forever begin
        slave_write_seq = axi4_slave_bk_write_seq::type_id::create("idle_slv_wr");
        slave_write_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
      end
    end
  join_none

  `uvm_info(get_type_name(), "Idle window over - issuing one ordinary write", UVM_LOW)
  write_seq = axi4_master_write_seq::type_id::create("post_idle_write_seq");
  write_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);

  // Give the detector several more polls to misfire in.
  #(detector_poll * detector_deadlock_polls * 2);

  check_detector(.expect_deadlock(0), .expect_livelock(0),
                 .scenario("one completed write issued after a long idle"));

  disable slave_responder;
  phase.drop_objection(this);
endtask : run_phase

`endif
