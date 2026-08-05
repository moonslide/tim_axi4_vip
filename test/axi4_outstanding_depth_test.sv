`ifndef AXI4_OUTSTANDING_DEPTH_TEST_INCLUDED_
`define AXI4_OUTSTANDING_DEPTH_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_outstanding_depth_test
//
// Directed detector for AXI_ooo.md F3 / F4, and the fail-then-pass evidence for
// Phase 4 / P4.1 (making outstanding_write_tx / outstanding_read_tx live).
//
// WHAT F3/F4 SAID
//   axi4_master_agent_config::outstanding_write_tx and ::outstanding_read_tx were
//   packed into axi4_transfer_cfg_s by axi4_master_cfg_converter and handed to
//   every BFM channel task, which only ever PRINTED the struct (F3). Meanwhile the
//   manager driver proxy's three channel semaphores were hardcoded `new(1)`, so
//   the achieved depth was exactly 1 per channel regardless (F4). Nine tests set
//   these fields believing they worked; none of them ever got a depth above 1.
//
// WHAT THIS TEST MEASURES
//   It asks for depth 4 on both directions and then checks what was ACHIEVED, not
//   what was permitted. The measurement is not made by this test's own stimulus -
//   the sequence issues back to back and asserts nothing - it is read out of the
//   driver's own bookkeeping after the run:
//     wr_resp_inflight_max / rd_data_inflight_max
//        credit holders: how many transactions were simultaneously past the credit
//        gate awaiting B / awaiting R.
//     wr_wire_outstanding_max / rd_wire_outstanding_max
//        Sampled from the BFM's protocol-bound counters (AW handshakes issued
//        minus B responses accepted; AR issued minus read bursts collected).
//        These are incremented at real handshakes inside the interface, not by
//        the credit code, so they independently confirm the traffic is real.
//        MEASURED CAVEAT (2026-08-05, this test's own legacy run): they do NOT
//        discriminate depth 1 from depth 4 - both report ~9-14. The AW/AR
//        channels were never credit-gated in the first place (the proxy loop
//        calls item_done() at the address handshake and issues the next address
//        immediately), so requests always ran ahead. What the hardcoded new(1)
//        pinned was how many responses the MANAGER would claim at once, i.e.
//        wr_resp_inflight_max / rd_data_inflight_max - and those are the numbers
//        that move, 1 -> 4. This refines AXI_ooo.md F4's "at most 1 outstanding
//        transaction per channel": accurate for response claiming, not for
//        request issuance.
//
// FAIL-THEN-PASS, FROM ONE BINARY
//   +AXI4_OUTSTANDING_LEGACY forces the driver back to depth 1/1 - the exact
//   pre-P4.1 behaviour - without rebuilding. So:
//     ./simv +UVM_TESTNAME=axi4_outstanding_depth_test +AXI4_OUTSTANDING_LEGACY
//        => achieved depth 1, this test's checks FAIL (that is the F4 symptom)
//     ./simv +UVM_TESTNAME=axi4_outstanding_depth_test
//        => achieved depth up to 4, checks PASS
//   Single variable, same executable, same seed.
//
//   +AXI4_CREDIT_TRACE additionally prints every credit acquire/release with the
//   live in-flight count, for reading the interleaving by hand.
//--------------------------------------------------------------------------------------------
class axi4_outstanding_depth_test extends axi4_base_test;
  `uvm_component_utils(axi4_outstanding_depth_test)

  axi4_master_max_outstanding_seq wr_seq_h;
  axi4_master_max_outstanding_seq rd_seq_h;

  // The depth under test. Must stay <= OUTSTANDING_FIFO_DEPTH or the driver
  // clamps it (and says so).
  int unsigned req_depth = 4;

  // Minimum depth this test insists was actually reached. Deliberately 2 rather
  // than req_depth: the claim being defended is "the knob is live and more than
  // one transaction really is in flight", and the exact peak legitimately depends
  // on how fast the subordinate answers. Anything at 1 means the knob is dead
  // again.
  int unsigned min_expected_depth = 2;

  // Kept small on purpose: the depth is reached within the first few
  // transactions, and this test is registered in the regression list.
  time drain_time = 6us;

  function new(string name = "axi4_outstanding_depth_test", uvm_component parent = null);
    super.new(name, parent);
    test_timeout = 2ms;
  endfunction : new

  virtual function void setup_axi4_master_agent_cfg();
    super.setup_axi4_master_agent_cfg();
    foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
      // THE knob under test.
      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = req_depth;
      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx  = req_depth;
      // QoS off: the manager's QoS write arbitration is not re-entrant, so the
      // driver pins write depth to 1 while it is on (see
      // configure_outstanding_credits). Leaving it on here would measure the pin,
      // not the credit.
      axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    end
  endfunction : setup_axi4_master_agent_cfg

  virtual function void setup_axi4_slave_agent_cfg();
    super.setup_axi4_slave_agent_cfg();
    foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode  = SLAVE_MEM_MODE;
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type   = QOS_MODE_DISABLE;
    end
  endfunction : setup_axi4_slave_agent_cfg

  virtual task run_phase(uvm_phase phase);
    int matrix_mode;

    phase.raise_objection(this);

    fork
      timeout_watchdog();
    join_none

    case (test_config.bus_matrix_mode)
      axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: matrix_mode = 2;
      axi4_bus_matrix_ref::BASE_BUS_MATRIX:     matrix_mode = 1;
      default:                                  matrix_mode = 0;
    endcase

    `uvm_info(get_type_name(),
              $sformatf("OUTSTANDING DEPTH TEST: requesting depth %0d on both directions, matrix mode %0d",
                        req_depth, matrix_mode), UVM_LOW)

    wr_seq_h = axi4_master_max_outstanding_seq::type_id::create("wr_seq_h");
    rd_seq_h = axi4_master_max_outstanding_seq::type_id::create("rd_seq_h");
    wr_seq_h.read_direction           = 0;
    rd_seq_h.read_direction           = 1;
    wr_seq_h.use_bus_matrix_addressing = matrix_mode;
    rd_seq_h.use_bus_matrix_addressing = matrix_mode;

    // Writes first, then reads over the same address window, so the reads have
    // real memory content to return and the run exercises both credits.
    wr_seq_h.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[0]);
    #(drain_time);
    rd_seq_h.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h_all[0]);
    #(drain_time);

    phase.drop_objection(this);
  endtask : run_phase

  //--------------------------------------------------------------------------
  // check_phase
  //  The actual verdict. Reads the driver's high-water marks directly; nothing
  //  here depends on the sequence having behaved in any particular way.
  //--------------------------------------------------------------------------
  virtual function void check_phase(uvm_phase phase);
    axi4_master_driver_proxy drv;
    super.check_phase(phase);

    drv = axi4_env_h.axi4_master_agent_h[0].axi4_master_drv_proxy_h;

    `uvm_info(get_type_name(),
              $sformatf("OUTSTANDING DEPTH RESULT: credits(w/r)=%0d/%0d achieved credit-holders w=%0d r=%0d, achieved wire-outstanding w=%0d r=%0d",
                        drv.outstanding_write_credits, drv.outstanding_read_credits,
                        drv.wr_resp_inflight_max, drv.rd_data_inflight_max,
                        drv.wr_wire_outstanding_max, drv.rd_wire_outstanding_max), UVM_LOW)

    if (drv.outstanding_write_credits < min_expected_depth) begin
      `uvm_error(get_type_name(),
                 $sformatf("write credit depth is %0d - the outstanding_write_tx knob did not reach the driver (AXI_ooo.md F3)",
                           drv.outstanding_write_credits))
    end
    else if (drv.wr_resp_inflight_max < min_expected_depth) begin
      `uvm_error(get_type_name(),
                 $sformatf("write outstanding depth achieved only %0d of the %0d credits granted - transactions are still being serialised (AXI_ooo.md F4)",
                           drv.wr_resp_inflight_max, drv.outstanding_write_credits))
    end

    if (drv.outstanding_read_credits < min_expected_depth) begin
      `uvm_error(get_type_name(),
                 $sformatf("read credit depth is %0d - the outstanding_read_tx knob did not reach the driver (AXI_ooo.md F3)",
                           drv.outstanding_read_credits))
    end
    else if (drv.rd_data_inflight_max < min_expected_depth) begin
      `uvm_error(get_type_name(),
                 $sformatf("read outstanding depth achieved only %0d of the %0d credits granted - transactions are still being serialised (AXI_ooo.md F4)",
                           drv.rd_data_inflight_max, drv.outstanding_read_credits))
    end

    // The independent BFM-side counters must agree that more than one request was
    // genuinely unanswered on the wire. If the credit bookkeeping says depth > 1
    // and these say 1, the credit accounting is measuring itself and the result
    // means nothing.
    if (drv.outstanding_write_credits >= min_expected_depth &&
        drv.wr_wire_outstanding_max   <  min_expected_depth) begin
      `uvm_error(get_type_name(),
                 $sformatf("credit bookkeeping claims write depth %0d but the BFM's AW-issued minus B-accepted peaked at %0d - no real wire-level outstanding",
                           drv.wr_resp_inflight_max, drv.wr_wire_outstanding_max))
    end
    if (drv.outstanding_read_credits >= min_expected_depth &&
        drv.rd_wire_outstanding_max  <  min_expected_depth) begin
      `uvm_error(get_type_name(),
                 $sformatf("credit bookkeeping claims read depth %0d but the BFM's AR-issued minus bursts-collected peaked at %0d - no real wire-level outstanding",
                           drv.rd_data_inflight_max, drv.rd_wire_outstanding_max))
    end
  endfunction : check_phase

endclass : axi4_outstanding_depth_test

`endif
