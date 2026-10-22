`ifndef AXI4_STALL_DETECTOR_RESET_TEST_INCLUDED_
`define AXI4_STALL_DETECTOR_RESET_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_stall_detector_reset_test
//
// AXI4 discards outstanding transactions across reset, so axi4_performance_metrics
// must drop the requests it is still holding. This test proves it does.
//
// Why it is needed: pending_writes/pending_reads changed from a map keyed by ID
// -- where the next same-ID request OVERWROTE a stale entry, so a missed flush
// self-healed -- to per-(port, ID) FIFOs, which accumulate. Without a flush the
// first post-reset response of a reused ID pops a PRE-reset request (reporting a
// latency for two unrelated transfers) and the real post-reset request stays
// queued for good, so pending_*_count() never returns to zero. That last part is
// not just a bad metric: detect_deadlock_livelock() uses "nothing outstanding"
// to tell IDLE from STALLED, so a permanently non-empty queue reintroduces the
// false deadlock that check was fixed to avoid.
//
// The test is written so it CANNOT pass vacuously: it asserts there really were
// outstanding transactions immediately before the reset. If the setup fails to
// create any, the test fails rather than silently checking nothing.
//--------------------------------------------------------------------------------------------
class axi4_stall_detector_reset_test extends axi4_stall_detector_base_test;
  `uvm_component_utils(axi4_stall_detector_reset_test)

  // Enough back-to-back issues that some are still unanswered when we look.
  int num_writes = 20;

  extern function new(string name = "axi4_stall_detector_reset_test", uvm_component parent = null);
  extern virtual function void setup_axi4_env_cfg();
  extern virtual task run_phase(uvm_phase phase);
endclass : axi4_stall_detector_reset_test

function axi4_stall_detector_reset_test::new(string name = "axi4_stall_detector_reset_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_stall_detector_reset_test::setup_axi4_env_cfg();
  super.setup_axi4_env_cfg();
  // A mid-test reset makes the scoreboard's own bookkeeping stale; that is its
  // own concern (it subscribes to the same event). This test is about the
  // metrics component, so keep the run focused.
  axi4_env_cfg_h.has_scoreboard = 0;
endfunction : setup_axi4_env_cfg

task axi4_stall_detector_reset_test::run_phase(uvm_phase phase);
  axi4_master_nbk_write_seq write_seq;
  axi4_stall_detector_nbk_write_seq win_write_seq;
  int pending_before;
  int pending_after_w;
  int pending_after_r;
  bit [63:0] addr_lo, addr_hi;
  bit        prot_fixed;
  bit [2:0]  prot_val;
  bit        use_window;

  phase.raise_objection(this);

  // NONE keeps the shared sequence (unchanged stimulus); 4x4 / ENHANCED write
  // inside master 0's legal window (see master0_write_window()).
  use_window = master0_write_window(addr_lo, addr_hi, prot_fixed, prot_val);
  `uvm_info(get_type_name(),
            $sformatf("Write address window: mode=%s %s", axi4_env_cfg_h.bus_matrix_mode.name(),
                      use_window ?
                        $sformatf("start 0x%016h..0x%016h awprot=%s", addr_lo, addr_hi,
                                  prot_fixed ? $sformatf("%03b", prot_val) : "random") :
                        "unconstrained (NONE decodes every address to slave 0)"), UVM_LOW)

  // ---- Get transactions in flight.
  `uvm_info(get_type_name(),
            $sformatf("Issuing %0d non-blocking writes to build a backlog", num_writes), UVM_LOW)
  for(int i = 0; i < num_writes; i++) begin
    if(use_window) begin
      win_write_seq = axi4_stall_detector_nbk_write_seq::type_id::create($sformatf("pre_reset_wr_%0d", i));
      win_write_seq.addr_lo    = addr_lo;
      win_write_seq.addr_hi    = addr_hi;
      win_write_seq.prot_fixed = prot_fixed;
      win_write_seq.prot_val   = prot_val;
      write_seq = win_write_seq;
    end else begin
      write_seq = axi4_master_nbk_write_seq::type_id::create($sformatf("pre_reset_wr_%0d", i));
    end
    write_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  end

  pending_before = metrics().pending_write_count() + metrics().pending_read_count();
  `uvm_info(get_type_name(),
            $sformatf("Outstanding immediately before reset: %0d", pending_before), UVM_LOW)

  // The whole test rests on this. Without a backlog there is nothing for the
  // reset to discard and a missing flush would look identical to a working one.
  if(pending_before == 0)
    `uvm_fatal(get_type_name(),
               "No transactions were outstanding before the reset - the flush check would pass vacuously, so this is a test-setup failure, not a pass")

  // ---- Reset. AXI4 says everything outstanding is now void.
  `uvm_info(get_type_name(), "Injecting global reset", UVM_LOW)
  uvm_config_db#(int)::set(null, "*", "reset_duration_cycles", 4);
  uvm_config_db#(bit)::set(null, "*", "inject_reset", 1);

  // Well past the reset pulse and its recovery.
  #2us;

  pending_after_w = metrics().pending_write_count();
  pending_after_r = metrics().pending_read_count();
  `uvm_info(get_type_name(),
            $sformatf("Outstanding after reset: %0d write(s), %0d read(s)",
                      pending_after_w, pending_after_r), UVM_LOW)

  if(pending_after_w != 0)
    `uvm_error(get_type_name(),
               $sformatf("%0d write(s) still queued after reset - the pre-reset requests were not discarded, so pending_write_count() can never return to zero",
                         pending_after_w))
  if(pending_after_r != 0)
    `uvm_error(get_type_name(),
               $sformatf("%0d read(s) still queued after reset - see the write-side note above", pending_after_r))

  // A reset is not a stall: neither flag may be set by any of the above.
  check_detector(.expect_deadlock(0), .expect_livelock(0),
                 .scenario("outstanding traffic discarded by reset"));

  phase.drop_objection(this);
endtask : run_phase

`endif
