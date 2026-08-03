`ifndef AXI4_TRACKB_COV_SWEEP_TEST_INCLUDED_
`define AXI4_TRACKB_COV_SWEEP_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_trackb_cov_sweep_test
//
// Coverage-directed Track-B test. Walks axi4_master_trackb_cov_sweep_seq across a
// range of steps on every master port, so the AXI attribute bins and their crosses
// get filled deliberately rather than by chance.
//
// The smoke tests drive one write and one read per master and leave GROUP coverage
// at 28.76% (10x10) / 24.53% (4x4). This exists to move that number.
//
// Runs on either fabric: the topology is bound by axi4_trackb_smoke_test from the
// compiled fabric (+define+NIC400_4X4 => BASE / 4x4, else ENHANCED / 10x10), and
// max_slave comes from the environment's slave count, so the 4x4 build sweeps
// S0..S3 and the 10x10 build sweeps S0..S9.
//
// Two things this class deliberately does NOT do (codex_review.md Findings 2 and 8):
//   * it does not publish its own topology -- it inherits the parent's binding, so
//     there is exactly one place where "which fabric am I driving" is decided; and
//   * it does not override run_phase() -- it overrides trackb_test_body(), which is
//     what keeps it inside the parent's watchdog race. The previous version fully
//     overrode run_phase and therefore held an objection across up to
//     2 * sweep_steps * num_masters blocking sequence.start() calls with no
//     project-scoped terminal bound at all.
//--------------------------------------------------------------------------------------------
class axi4_trackb_cov_sweep_test extends axi4_trackb_smoke_test;
  `uvm_component_utils(axi4_trackb_cov_sweep_test)

  // How many sweep points each master walks. Every step moves several attribute
  // dimensions at once (see the sequence), so this does not need to be the product
  // of the dimension sizes.
  int unsigned sweep_steps = 96;

  // Progress for the watchdog report.
  protected int trackb_sweep_steps_done;

  function new(string name = "axi4_trackb_cov_sweep_test", uvm_component parent = null);
    super.new(name, parent);

    //----------------------------------------------------------------------
    // codex_review.md Finding 8: this body is ~2 orders of magnitude longer
    // than the smoke body, so it gets its own bound rather than the inherited
    // 500us. 2ms is derived from measured runs of THIS test, not guessed:
    //
    //   10x10 (96 steps x 10 masters = 960 writes + 960 reads):
    //     ends at 20,367,510 time units, "TEST RESULT: PASS", UVM_ERROR 0
    //     -- /tmp/g10_axi4_trackb_cov_sweep_test.log
    //   4x4   (96 steps x  4 masters = 384 writes + 384 reads):
    //     ends at 20,187,810 time units, "TEST RESULT: PASS", UVM_ERROR 0
    //     -- /tmp/g4_axi4_trackb_cov_sweep_test.log
    //
    // With -override_timescale=1ps/1ps that is ~20.4us and ~20.2us, of which
    // 20us is the fixed drain at the end of the body below -- the stimulus
    // itself takes ~0.37us (10x10) and ~0.19us (4x4). So 2ms is ~98x the
    // measured end-to-end runtime and ~5000x the measured stimulus phase:
    // sweep_steps could be raised 10x and still finish two orders of
    // magnitude inside it. It is simulation time, so a loaded host cannot
    // trip it, and it sits well under the ambient DEFAULT_TEST_TIMEOUT (10ms
    // via test/axi4_test_defines.svh) so a genuine hang still ends as a UVM
    // verdict with test context rather than as an external kill.
    //----------------------------------------------------------------------
    trackb_watchdog_timeout = 2ms;
  endfunction : new

  virtual task trackb_test_body();
    int num_masters = axi4_env_cfg_h.no_of_masters;

    trackb_sweep_steps_done = 0;

    // Slave responders, one pair per slave agent, exactly as the smoke test does.
    start_slave_responders("cov");

    `uvm_info(get_type_name(),
              $sformatf("TRACK-B COVERAGE SWEEP: %0d masters x %0d steps, slaves 0..%0d (bound %s)",
                        num_masters, sweep_steps, axi4_env_cfg_h.no_of_slaves - 1,
                        axi4_env_cfg_h.bus_matrix_mode.name()), UVM_LOW)

    for (int s = 0; s < sweep_steps; s++) begin
      for (int m = 0; m < num_masters; m++) begin
        axi4_master_trackb_cov_sweep_seq sweep;
        sweep = axi4_master_trackb_cov_sweep_seq::type_id::create($sformatf("sweep_%0d_%0d", m, s));
        sweep.max_slave = axi4_env_cfg_h.no_of_slaves - 1;
        sweep.master_id = m;                       // the access matrix is per (master, slave)
        // Offset per master so the ports do not all sit on the same attribute point.
        sweep.step      = s * num_masters + m;
        sweep.do_read   = 1'b0;
        sweep.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[m]);
        trackb_masters_written++;
      end
      // Read half of the sweep. Without it every AR*/R* coverpoint and the
      // ARBURST x ARLEN x ARSIZE cross stay empty ("Total Reads : 0").
      for (int m = 0; m < num_masters; m++) begin
        axi4_master_trackb_cov_sweep_seq rsweep;
        rsweep = axi4_master_trackb_cov_sweep_seq::type_id::create($sformatf("rsweep_%0d_%0d", m, s));
        rsweep.max_slave = axi4_env_cfg_h.no_of_slaves - 1;
        rsweep.master_id = m;
        rsweep.step      = s * num_masters + m;
        rsweep.do_read   = 1'b1;
        rsweep.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h_all[m]);
        trackb_masters_read++;
      end
      trackb_sweep_steps_done = s + 1;
    end

    #20000ns;
  endtask : trackb_test_body

  virtual function string trackb_progress_str();
    return $sformatf("%0d/%0d sweep steps completed (%0d writes and %0d reads issued)",
                     trackb_sweep_steps_done, sweep_steps,
                     trackb_masters_written, trackb_masters_read);
  endfunction : trackb_progress_str

endclass : axi4_trackb_cov_sweep_test

`endif
