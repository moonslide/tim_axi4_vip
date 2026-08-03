`ifndef AXI4_TRACKB_SMOKE_TEST_INCLUDED_
`define AXI4_TRACKB_SMOKE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_trackb_smoke_test
//
// Minimum viable Track-B test: proves the VIP's UVM stack (sequences, driver
// BFMs, monitors, scoreboard) works end to end through the real ARM CoreLink
// commercial fabric IP DUT, not just through the 1:1 direct wiring.
//
// Build with:
//   +define+BUS_MATRIX_FABRIC_IP +define+DATA_WIDTH=256 +define+AXI_ID_WIDTH=8 +define+AXI_ID_LAST=255
//   -f ../../sim/axi4_compile_fabric_ip.f
//
// It differs from the stock tests only in that its addresses are constrained
// to a region the fabric actually maps (see axi4_master_trackb_base_seq).
// Running a stock random test against the fabric fails with zero verified
// scoreboard counts, because every randomly scattered 64-bit address decodes
// to the fabric's default slave and is answered with DECERR.
//
// This class is also the Track-B BASE class: axi4_trackb_4x4_smoke_test and
// axi4_trackb_cov_sweep_test extend it, and it owns two things on their behalf
//   * the TOPOLOGY BINDING (codex_review.md Finding 2) -- see
//     bind_trackb_topology() below, and
//   * the test-scoped WATCHDOG (codex_review.md Finding 8) -- see
//     run_trackb_body_with_watchdog(). A derived test supplies its stimulus by
//     overriding trackb_test_body(), NOT by overriding run_phase(); that is
//     what keeps the watchdog attached.
//--------------------------------------------------------------------------------------------
class axi4_trackb_smoke_test extends axi4_base_test;
  `uvm_component_utils(axi4_trackb_smoke_test)

  axi4_master_trackb_write_seq write_seq[];
  axi4_master_trackb_read_seq  read_seq[];
  // Slave-side responders. Without these the slave agents never source read
  // data, so ARVALID reaches the slave BFM but RVALID is never driven and the
  // master driver times out ("timeout waiting for rvalid").
  axi4_slave_nbk_write_seq     slv_write_seq[];
  axi4_slave_nbk_read_seq      slv_read_seq[];

  // Slave region every master may read and write in the access matrix.
  // Defaulted per fabric in new(); a derived test may override it.
  int unsigned target_slave = 2;   // S2 DDR Shared Buffer (ENHANCED map)

  //------------------------------------------------------------------------
  // codex_review.md Finding 2: the topology this test is BOUND to.
  //
  // Before this fix the Track-B tests published no topology of their own, and
  // axi4_test_config::configure_for_test() has no Track-B rule, so they were
  // classified DEFAULT_TESTS => NONE / 4 masters / 4 slaves and depended
  // entirely on +BUS_MATRIX_MODE=ENHANCED to become 10x10. Measured, not
  // theorised: /tmp/g4_axi4_trackb_cov_sweep_test.log:80-81 shows the 4x4
  // fabric being swept with "Bus_Matrix=NONE, Masters=4, Slaves=4", i.e.
  // against a reference model that routes every address to slave 0 and always
  // answers OKAY (bm/axi4_bus_matrix_ref.sv:220,287) -- a green run that
  // proved nothing about the fabric's decode.
  //
  // The topology of a Track-B run is not a runtime choice: the fabric has
  // its port count and address decode burned into RTL, and which fabric is in
  // the design is decided at COMPILE time by +define+FABRIC_IP_4X4. So the same
  // define selects the bound topology here (identical precedent:
  // seq/master_sequences/axi4_master_trackb_base_seq.sv:54,92 and
  // include/axi4_bus_config.svh:140 already switch on it), and a
  // +BUS_MATRIX_MODE that disagrees is fatal rather than ignored.
  //------------------------------------------------------------------------
  axi4_bus_matrix_ref::bus_matrix_mode_e trackb_bus_matrix_mode;
  int trackb_num_masters;
  int trackb_num_slaves;

  //------------------------------------------------------------------------
  // codex_review.md Finding 8: test-scoped watchdog bound.
  //
  // This class overrides run_phase and never calls super.run_phase(), so
  // axi4_base_test::timeout_watchdog() is never forked -- without the race
  // below, a sequence that fails to return would hold the objection until an
  // external kill, producing no UVM verdict at all.
  //
  // 500us is chosen from measurement, not habit: the whole smoke body
  // (10 writes + 10 reads through the fabric, plus its #5000ns drain) ends at
  // 5,001,130 time units on the 10x10 build and 5,000,650 on the 4x4 build
  // (/tmp/g10_axi4_trackb_smoke_test.log and
  // /tmp/g4_axi4_trackb_4x4_smoke_test.log, both "TEST RESULT: PASS",
  // UVM_ERROR 0). With -override_timescale=1ps/1ps that is ~5.0us, so 500us
  // is ~100x the measured runtime -- far above anything a legitimate run
  // needs, far below the ambient DEFAULT_TEST_TIMEOUT (10ms via
  // test/axi4_test_defines.svh, 10s via include/ -- doubly defined, and not
  // armed here anyway), and it stays a SIMULATION-time bound so a slow host
  // cannot trip it. A derived test may raise it (the coverage sweep does).
  //------------------------------------------------------------------------
  time trackb_watchdog_timeout = 500us;

  // Progress bookkeeping, so a watchdog report says how far the test got
  // instead of just "it hung". Protected: derived bodies update these too.
  protected bit trackb_body_done;
  protected int trackb_masters_written;
  protected int trackb_masters_read;

  function new(string name = "axi4_trackb_smoke_test", uvm_component parent = null);
    super.new(name, parent);
`ifdef FABRIC_IP_4X4
    // ext/nic400_vip4x4q: four ingress, four egress, VIP BASE map.
    trackb_bus_matrix_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
    trackb_num_masters     = 4;
    trackb_num_slaves      = 4;
    // S0 DDR_Memory is the only BASE region every master may both read and
    // write (S1/S3 are read-only, S2 excludes M3).
    target_slave           = 0;
`else
    // ext/nic400_vipv3b: ten ingress, ten egress, VIP ENHANCED map.
    trackb_bus_matrix_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
    trackb_num_masters     = 10;
    trackb_num_slaves      = 10;
`endif
  endfunction : new

  //------------------------------------------------------------------------
  // Function: bind_trackb_topology
  // Publish the fixed topology BEFORE axi4_base_test::setup_test_configuration()
  // runs. That function creates and configures a test_config only when
  // config_db has none (test/axi4_base_test.sv:86), and it applies
  // +BUS_MATRIX_MODE only inside that same branch -- so publishing here both
  // wins and disarms the plusarg, which is why the plusarg is then CHECKED.
  //------------------------------------------------------------------------
  virtual function void bind_trackb_topology();
    axi4_test_config trackb_cfg;

    // A derived test (axi4_trackb_4x4_smoke_test) may have published its own
    // topology before calling super.build_phase(). Respect it; do not clobber.
    if (uvm_config_db#(axi4_test_config)::get(this, "*", "test_config", trackb_cfg)) begin
      `uvm_info(get_type_name(),
                $sformatf("Track-B topology already published by a derived test: %s",
                          trackb_cfg.get_config_summary()), UVM_LOW)
    end
    else begin
      trackb_cfg = axi4_test_config::type_id::create("test_config");
      trackb_cfg.set_fixed_topology(trackb_bus_matrix_mode,
                                    trackb_num_masters,
                                    trackb_num_slaves,
                                    get_type_name());
      uvm_config_db#(axi4_test_config)::set(null, "*", "test_config", trackb_cfg);
      // axi4_base_test publishes "bus_matrix_mode" only on the branch we just
      // pre-empted (test/axi4_base_test.sv:137), so publish it here with the
      // same context/scope to keep every consumer seeing what it saw before.
      uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode",
                                                                 trackb_cfg.bus_matrix_mode);
    end

    // Contradicting or misspelled +BUS_MATRIX_MODE => UVM_FATAL at time 0.
    trackb_cfg.check_bus_matrix_plusarg(get_type_name());

`ifndef BUS_MATRIX_FABRIC_IP
    // Warning, not fatal: the Track-B classes still run against the baseline
    // 1:1 wiring (that is a useful A/B), but a "Track-B" result quoted from a
    // build with no fabric in it is not a fabric result.
    `uvm_warning(get_type_name(),
      {"compiled WITHOUT +define+BUS_MATRIX_FABRIC_IP: there is no fabric IP in this ",
       "design, so this run exercises the 1:1 direct wiring, not the Track-B DUT."})
`endif
  endfunction : bind_trackb_topology

  function void build_phase(uvm_phase phase);
    // Must precede super.build_phase(): that is where the base test derives
    // (or accepts) the topology and then builds the env from it.
    bind_trackb_topology();

    super.build_phase(phase);

    // A real interconnect sits between the master and slave agents, so the
    // scoreboard's 1:1 assumptions have to be switched off and replaced:
    //  * pairing by arrival order is invalid once an arbiter can reorder
    //  * AxID is remapped by the fabric ({ingress-port, original-id}); what
    //    remains checkable, and now IS checked, is that each manager gets its
    //    own BID/RID back
    //  * the generated fabric has QoS ports on the ingress side only, and
    //    drives REGION/USER from its own decode, so those cannot pass through
    axi4_env_cfg_h.sb_keyed_pairing             = 1;
    axi4_env_cfg_h.axid_passthrough_chk_cfg     = 0;
    axi4_env_cfg_h.axqos_passthrough_chk_cfg    = 0;
    axi4_env_cfg_h.axregion_passthrough_chk_cfg = 0;
    axi4_env_cfg_h.axuser_passthrough_chk_cfg   = 0;
    `uvm_info(get_type_name(), "==========================================", UVM_LOW)
    `uvm_info(get_type_name(), "AXI4 TRACK-B SMOKE TEST (commercial fabric IP DUT)", UVM_LOW)
    `uvm_info(get_type_name(),
              $sformatf("Bound topology: %s / %0d masters / %0d slaves",
                        axi4_env_cfg_h.bus_matrix_mode.name(),
                        axi4_env_cfg_h.no_of_masters, axi4_env_cfg_h.no_of_slaves), UVM_LOW)
    `uvm_info(get_type_name(), "==========================================", UVM_LOW)
  endfunction : build_phase

  //------------------------------------------------------------------------
  // Task: start_slave_responders
  // One responder pair per slave agent, kept running for the whole test.
  // A transaction addressed to S<n> is routed by the fabric to egress port n,
  // so slave agent n must be the one sourcing the response. Driving only
  // slave 0 leaves every other region unanswered ("timeout waiting for
  // rvalid"). These are forever loops on purpose: they are descendants of the
  // body branch and are torn down by the `disable fork` in
  // run_trackb_body_with_watchdog().
  //------------------------------------------------------------------------
  virtual task start_slave_responders(string tag);
    for (int sv = 0; sv < axi4_env_cfg_h.no_of_slaves; sv++) begin
      automatic int s_idx = sv;
      fork
        begin
          forever begin
            axi4_slave_nbk_write_seq wseq;
            wseq = axi4_slave_nbk_write_seq::type_id::create($sformatf("%s_slv_wr_%0d", tag, s_idx));
            wseq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_slave_write_seqr_h_all[s_idx]);
          end
        end
        begin
          forever begin
            axi4_slave_nbk_read_seq rseq;
            rseq = axi4_slave_nbk_read_seq::type_id::create($sformatf("%s_slv_rd_%0d", tag, s_idx));
            rseq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_slave_read_seqr_h_all[s_idx]);
          end
        end
      join_none
    end
  endtask : start_slave_responders

  //------------------------------------------------------------------------
  // Task: trackb_test_body
  // THE stimulus hook. Derived Track-B tests override this and inherit the
  // watchdog; they must not override run_phase().
  //------------------------------------------------------------------------
  virtual task trackb_test_body();
    int num_masters = axi4_env_cfg_h.no_of_masters;

    write_seq     = new[num_masters];
    read_seq      = new[num_masters];
    slv_write_seq = new[axi4_env_cfg_h.no_of_slaves];
    slv_read_seq  = new[axi4_env_cfg_h.no_of_slaves];

    start_slave_responders("trackb");

    `uvm_info(get_type_name(),
              $sformatf("Driving %0d masters at slave region S%0d", num_masters, target_slave),
              UVM_LOW)

    // Write from every master into the mapped region ...
    for (int m = 0; m < num_masters; m++) begin
      write_seq[m] = axi4_master_trackb_write_seq::type_id::create($sformatf("trackb_wr_%0d", m));
      write_seq[m].target_slave = target_slave;
      write_seq[m].start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[m]);
      trackb_masters_written++;
    end

    // ... then read the same address back through the fabric.
    for (int m = 0; m < num_masters; m++) begin
      read_seq[m] = axi4_master_trackb_read_seq::type_id::create($sformatf("trackb_rd_%0d", m));
      read_seq[m].target_slave = target_slave;
      read_seq[m].read_addr    = write_seq[m].last_addr;
      read_seq[m].start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h_all[m]);
      trackb_masters_read++;
    end

    // The fabric adds pipeline and arbitration latency on top of the slave
    // response time, so give responses room to drain before ending the test.
    #5000ns;
  endtask : trackb_test_body

  //------------------------------------------------------------------------
  // Function: trackb_progress_str
  // What the watchdog reports when it fires. Overridden by derived tests
  // whose body has a different notion of progress.
  //------------------------------------------------------------------------
  virtual function string trackb_progress_str();
    return $sformatf("%0d/%0d masters completed their write phase, %0d/%0d completed their read phase",
                     trackb_masters_written, axi4_env_cfg_h.no_of_masters,
                     trackb_masters_read,    axi4_env_cfg_h.no_of_masters);
  endfunction : trackb_progress_str

  //------------------------------------------------------------------------
  // Task: run_trackb_body_with_watchdog
  // The reusable terminal bound (codex_review.md Finding 8). The whole test
  // body runs as one forked branch, raced against a watchdog branch.
  // Whichever finishes first wins the join_any; `disable fork` then tears down
  // whatever is left -- either the idle watchdog timer (normal completion) or
  // the still-blocked body plus its forever-running slave responder loops
  // (watchdog fired). Either way the caller always reaches
  // phase.drop_objection() with a real, test-context-carrying verdict instead
  // of holding the objection for an external kill.
  //------------------------------------------------------------------------
  virtual task run_trackb_body_with_watchdog();
    trackb_body_done       = 0;
    trackb_masters_written = 0;
    trackb_masters_read    = 0;

    fork
      begin : trackb_body_branch
        trackb_test_body();
        trackb_body_done = 1;
      end : trackb_body_branch
      begin : trackb_watchdog_branch
        #(trackb_watchdog_timeout);
      end : trackb_watchdog_branch
    join_any
    disable fork;

    if (!trackb_body_done) begin
      `uvm_error(get_type_name(),
        $sformatf({"TRACK-B WATCHDOG FIRED after %0t without the test body completing ",
                   "(codex_review.md Finding 8). Progress at the bound: %s. A blocking ",
                   "sequence failed to return; forcing a bounded FAIL verdict here instead of ",
                   "holding the objection for an external kill."},
                  trackb_watchdog_timeout, trackb_progress_str()))
    end
    else begin
      `uvm_info(get_type_name(),
                $sformatf("Track-B body completed inside its %0t watchdog bound (%s)",
                          trackb_watchdog_timeout, trackb_progress_str()), UVM_LOW)
    end
  endtask : run_trackb_body_with_watchdog

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    run_trackb_body_with_watchdog();
    phase.drop_objection(this);
  endtask : run_phase

endclass : axi4_trackb_smoke_test

`endif
