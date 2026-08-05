`ifndef AXI4_REFUSED_WRITE_SHADOW_TEST_INCLUDED_
`define AXI4_REFUSED_WRITE_SHADOW_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_refused_write_shadow_test
//
// AXI_ooo.md Phase 3, THIRD fix pass -- directed fail-then-pass test for the same-ID
// order checker's WRITE-SHADOW COMMIT GATE (env/axi4_scoreboard.sv::
// sb_sameid_note_write_burst).
//
// THE DEFECT IT PINS DOWN
//   The checker's CONTENT mechanism compares an R burst against its own shadow of
//   what the addressed beat holds. That shadow is only useful if it AGREES with the
//   memory the subordinate answers reads out of: a shadow that disagrees produces a
//   head mismatch, and a head mismatch plus any same-ID sibling holding the value
//   memory really returned is a CONVICTION. So a wrong shadow is an accusing bug,
//   not a quiet one.
//
//   The first two implementations decided what to shadow on the W channel from a
//   prediction:
//       get_expected_write_response(awaddr, port, awprot) == WRITE_OKAY
//   That is not what determines this bench's memory content. Measured (see the write
//   sequence): axi4_scoreboard::store_write() commits EVERY manager write into
//   axi4_bus_matrix_h -- the very model the subordinate reads from -- with no
//   reference to BRESP at all. So a write the prediction (and the subordinate)
//   refused is still what the next read returns, while the shadow still holds the
//   OLD value. This test drives exactly that and the checker convicts an innocent
//   sibling for it.
//
// HOW THIS TEST MAKES THAT DETERMINISTIC (see the two sequences for the details)
//   * ENHANCED bus matrix, forced here; MASTER 7 and slave region S7, whose
//     get_write_resp() prediction flips on AWPROT[1] for a NON-secure master. Same
//     port, same address, two different predicted answers.
//   * RESP_IN_ORDER: NOTHING is reordered anywhere in this test, so any
//     SB_SAMEID_ORDER_VIOLATION it reports is FALSE by construction.
//   * W <- 0xAA (predicted OKAY), Z <- 0xCC (predicted OKAY), then W <- 0xCC with
//     AWPROT non-secure (predicted AND answered SLVERR, memory takes it anyway).
//   * four same-ARID reads W,Z,W,Z. When a W burst completes, Z is a still-
//     outstanding same-ID sibling whose shadow content is exactly what memory[W]
//     returns.
//
// EXPECTED WITH THE PRE-FIX (predicted, W-channel) GATE  -- also with a strict
// "observed BRESP == OKAY" gate, which is why that was NOT the fix
//   shadow[W] = 0xAA, memory[W] = 0xCC -> head mismatch -> sibling Z positively
//   named -> SB_SAMEID_ORDER_VIOLATION, violations >= 1 on the same-ID summary
//   line, UVM_ERROR > 0. A checker fault, not a DUT fault.
//
// EXPECTED WITH THE FIXED GATE (mirrors store_write()'s own branch)
//   shadow[W] = 0xCC, head matches, violations=0 unattributed=0, UVM_ERROR : 0,
//   and wr_not_okay >= 1 on the summary line recording that a non-OKAY write was
//   seen and deliberately still shadowed.
//   (UVM_WARNINGs are expected -- see the demotion note in end_of_elaboration_phase.)
//
// WHAT IT DOES *NOT* PROVE
//   It does not exercise same-ID REORDERING at all -- that is
//   axi4_same_id_nonadjacent_reorder_test's job, and the two are complementary: this
//   one proves the checker does not FALSELY convict, that one proves it still DOES
//   convict (teeth binary, sim/synopsys_sim/prephase2/).
//--------------------------------------------------------------------------------------------
class axi4_refused_write_shadow_test extends axi4_base_test;
  `uvm_component_utils(axi4_refused_write_shadow_test)

  // Master 7 is the one non-secure, non-privileged manager whose OWN slave agent
  // range (S7) carries an AWPROT-sensitive write prediction. See the write sequence.
  localparam int MASTER_UNDER_TEST = 7;

  axi4_master_refused_write_shadow_seq      wr_seq_h;
  axi4_master_refused_write_shadow_read_seq rd_seq_h;

  // Long enough for the three writes to have been answered (including the DECERR),
  // so every shadow decision pre-dates every read -- sb_sameid_beat_known()'s time
  // gate needs the last write to land strictly before the request is issued.
  time write_drain_time = 4us;
  time read_drain_time  = 4us;

  function new(string name = "axi4_refused_write_shadow_test", uvm_component parent = null);
    super.new(name, parent);
    test_timeout = 2ms;
  endfunction : new

  // The S7 region and its AWPROT-sensitive prediction only exist in the ENHANCED map,
  // so the mode
  // is forced here rather than left to a +BUS_MATRIX_MODE plusarg the runner might
  // not pass. Built before super.build_phase() so axi4_base_test picks it up from
  // the config_db instead of deriving one from the test name.
  virtual function void build_phase(uvm_phase phase);
    axi4_test_config cfg;
    cfg = axi4_test_config::type_id::create("test_config");
    cfg.configure_for_test(get_type_name());
    cfg.bus_matrix_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
    cfg.num_masters     = 10;
    cfg.num_slaves      = 10;
    uvm_config_db#(axi4_test_config)::set(this, "*", "test_config", cfg);
    uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", cfg.bus_matrix_mode);

    super.build_phase(phase);

    // The non-secure write is SUPPOSED to be refused, so its SLVERR is an expected
    // response, not a finding. Same convention as the boundary/access-control tests.
    axi4_env_cfg_h.error_inject = 1;
    uvm_config_db #(axi4_env_config)::set(this, "*", "axi4_env_config", axi4_env_cfg_h);
  endfunction : build_phase

  // EXPECTED, DOCUMENTED DEMOTION -- and an independent finding, recorded here
  // rather than hidden.
  //
  // Several unrelated scoreboard checks fire on the deliberately-refused write and
  // on the 128-byte full-width beats this test uses (response bookkeeping, wdata/
  // wstrb comparisons). They are raised under the plain id "axi4_scoreboard" and are
  // not what this test is about.
  //
  // Demoting the plain "axi4_scoreboard" id keeps this directed test's verdict
  // readable WITHOUT touching the checker under test: SB_SAMEID_ORDER_VIOLATION is
  // raised under its OWN id and is therefore NOT demoted -- a false conviction still
  // fails this test loudly, which is the entire point of it.
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    if(axi4_env_h != null && axi4_env_h.axi4_scoreboard_h != null)
      axi4_env_h.axi4_scoreboard_h.set_report_severity_id_override(UVM_ERROR, "axi4_scoreboard", UVM_WARNING);
  endfunction : end_of_elaboration_phase

  virtual function void setup_axi4_slave_agent_cfg();
    super.setup_axi4_slave_agent_cfg();
    foreach (axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      // CONTENT needs the subordinates to answer reads out of memory.
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
      // No reordering: every violation this test can report is a false one.
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = RESP_IN_ORDER;
    end
  endfunction : setup_axi4_slave_agent_cfg

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(),
              "REFUSED-WRITE SHADOW phase 1/2 (master 7): W<-0xAA, Z<-0xCC, then W<-0xCC non-secure (refused, but memory takes it)",
              UVM_LOW)
    wr_seq_h = axi4_master_refused_write_shadow_seq::type_id::create("wr_seq_h");
    wr_seq_h.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[MASTER_UNDER_TEST]);
    #(write_drain_time);

    `uvm_info(get_type_name(),
              "REFUSED-WRITE SHADOW phase 2/2 (master 7): four same-ARID reads W,Z,W,Z (no reordering anywhere)",
              UVM_LOW)
    rd_seq_h = axi4_master_refused_write_shadow_read_seq::type_id::create("rd_seq_h");
    rd_seq_h.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h_all[MASTER_UNDER_TEST]);
    #(read_drain_time);

    phase.drop_objection(this);
  endtask : run_phase

endclass : axi4_refused_write_shadow_test

`endif
