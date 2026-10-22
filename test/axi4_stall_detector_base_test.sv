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
//
// Addresses (landmines #67 / #75). The shared write sequences these tests used
// put NO constraint on awaddr. In NONE every address decodes to slave 0 OKAY,
// so that was invisible; under 4x4 and ENHANCED the random 64-bit addresses hit
// no slave window, every write came back DECERR, and perf-metrics failed the
// run on "Protocol Issues". master0_write_window() gives master 0 a window it
// may write with OKAY in the active mode, and the two sequence wrappers below
// add it to the shared sequences' randomization. NONE keeps the shared
// sequences, unchanged, so its stimulus is the same as before.
//--------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------
// Class: axi4_stall_detector_write_seq
// axi4_master_write_seq with the start address held inside [addr_lo : addr_hi]
// and, when prot_fixed is set, awprot held at prot_val. The other inline
// constraints are copied from the parent's body() unchanged.
//--------------------------------------------------------------------------------------------
class axi4_stall_detector_write_seq extends axi4_master_write_seq;
  `uvm_object_utils(axi4_stall_detector_write_seq)

  bit [63:0] addr_lo;
  bit [63:0] addr_hi;
  bit        prot_fixed;
  bit [2:0]  prot_val;

  function new(string name = "axi4_stall_detector_write_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    req = axi4_master_tx::type_id::create("req");

    start_item(req);
    if(!req.randomize() with {req.awsize == WRITE_2_BYTES;
                              req.tx_type == WRITE;
                              req.awburst == WRITE_FIXED;
                              req.transfer_type == NON_BLOCKING_WRITE;
                              req.awaddr inside {[local::addr_lo : local::addr_hi]};
                              local::prot_fixed -> (req.awprot == local::prot_val);}) begin
      `uvm_fatal("axi4","Rand failed");
    end

    `uvm_info(get_type_name(), $sformatf("master_seq \n%s",req.sprint()), UVM_NONE);
    finish_item(req);
  endtask : body
endclass : axi4_stall_detector_write_seq

//--------------------------------------------------------------------------------------------
// Class: axi4_stall_detector_nbk_write_seq
// axi4_master_nbk_write_seq with the same address / awprot hold as above.
// req is created here, as axi4_master_nbk_base_seq::body() does.
//--------------------------------------------------------------------------------------------
class axi4_stall_detector_nbk_write_seq extends axi4_master_nbk_write_seq;
  `uvm_object_utils(axi4_stall_detector_nbk_write_seq)

  bit [63:0] addr_lo;
  bit [63:0] addr_hi;
  bit        prot_fixed;
  bit [2:0]  prot_val;

  function new(string name = "axi4_stall_detector_nbk_write_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    req = axi4_master_tx::type_id::create("req");

    start_item(req);
    if(!req.randomize() with {req.tx_type == WRITE;
                              req.transfer_type == NON_BLOCKING_WRITE;
                              req.awaddr inside {[local::addr_lo : local::addr_hi]};
                              local::prot_fixed -> (req.awprot == local::prot_val);}) begin
      `uvm_fatal("axi4","Rand failed");
    end
    `uvm_info(get_type_name(), $sformatf("master_seq \n%s",req.sprint()), UVM_NONE);
    finish_item(req);
  endtask : body
endclass : axi4_stall_detector_nbk_write_seq

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
  extern virtual function void setup_axi4_env_cfg();
  extern function axi4_performance_metrics metrics();
  extern function void check_detector(bit expect_deadlock, bit expect_livelock, string scenario);
  extern function bit master0_write_window(output bit [63:0] addr_lo, output bit [63:0] addr_hi,
                                           output bit prot_fixed, output bit [2:0] prot_val);
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

function void axi4_stall_detector_base_test::setup_axi4_env_cfg();
  super.setup_axi4_env_cfg();
`ifdef BUS_MATRIX_FABRIC_IP
  // Track-B (commercial fabric IP in the path). Same per-test scoreboard settings as the
  // other non-native Track-B tests (testlists/axi4_trackb_nonnative.list; TRACKB_DEBUG_NOTES.md §6).
  // Measured without them (idle test, seeds 1 / 351485697): the one write completed OKAY
  // but the scoreboard failed "awid/bid count comparisions" because the fabric re-encodes AxID.
  // axi4_stall_detector_reset_test turns the scoreboard off (its own setup_axi4_env_cfg), so
  // these settings only matter to the idle test.
  axi4_env_cfg_h.sb_keyed_pairing             = 1;   // arbiter reorders; positional pairing invalid
  axi4_env_cfg_h.axid_passthrough_chk_cfg     = 0;   // fabric re-encodes AxID (landmine 12a/27); replaced by sb_outstanding_a?id + validate_response_correctness
  axi4_env_cfg_h.axqos_passthrough_chk_cfg    = 0;   // ARQOS: EXPECTED DIFFERENCE, fabric has no egress QoS ports (hdl_top ties 0); AWQOS is never compared
  axi4_env_cfg_h.axregion_passthrough_chk_cfg = 1;   // ARREGION only; these tests issue no reads, so 0 comparisons
  axi4_env_cfg_h.axuser_passthrough_chk_cfg   = 1;   // measured forwarded by this fabric
  axi4_env_cfg_h.sb_pair_awuser_id_mask       = '0;  // one issuing manager (port 0); AxUSER=0 carries no identity
  axi4_env_cfg_h.sb_pair_aruser_id_mask       = '0;  // one issuing manager (port 0); AxUSER=0 carries no identity
  `uvm_info(get_type_name(), "Track-B scoreboard ledger: keyed=1 axid=OFF(re-encoded) arqos=OFF(not forwarded) awqos=never-compared arregion=ON(0 comparisons: no reads) awregion=never-compared axuser=ON(weak: stimulus AxUSER=0) awuser_id_mask=0 aruser_id_mask=0", UVM_LOW)
`endif
endfunction : setup_axi4_env_cfg

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

//--------------------------------------------------------------------------------------------
// Function: master0_write_window
// Start-address window that master 0 may write with OKAY in the active bus-matrix
// mode. Returns 0 in NONE: there every address decodes to slave 0 OKAY
// (axi4_bus_matrix_ref::decode / get_write_resp), and the caller keeps the shared
// sequences so the NONE stimulus does not change.
//   BASE 4x4 : S0 DDR_Memory from 0x0000_0100_0000_0000 (R/W for M0..M3,
//              axi4_bus_matrix_ref::configure_base_matrix). awprot left random:
//              the 4x4 map has no security or privilege check.
//   ENHANCED : S0 DDR Secure Kernel from 0x0000_0008_0000_0000 (claude.md address
//              map) with AxPROT = 3'b000, the access the M0 -> S0 cell of the
//              claude.md access matrix allows. Same window and AxPROT as #67's fix.
// The window is 1 MiB. Start addresses stop 4 KiB short of its end, and
// aw_4kb_boundary_c7 keeps every burst at or under 4 KiB, so the whole burst
// stays inside the window, which the slave decodes at both ends.
//--------------------------------------------------------------------------------------------
function bit axi4_stall_detector_base_test::master0_write_window(output bit [63:0] addr_lo,
                                                                  output bit [63:0] addr_hi,
                                                                  output bit prot_fixed,
                                                                  output bit [2:0] prot_val);
  bit [63:0] base;
  prot_fixed = 0;
  prot_val   = 3'b000;
  case (axi4_env_cfg_h.bus_matrix_mode)
    axi4_bus_matrix_ref::BASE_BUS_MATRIX     : base = 64'h0000_0100_0000_0000;
    axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX : begin
      base       = 64'h0000_0008_0000_0000;
      prot_fixed = 1;
    end
    default : begin
      addr_lo = '0;
      addr_hi = '1;
      return 0;
    end
  endcase
  addr_lo = base;
  addr_hi = base + 64'h0010_0000 - 64'h1000;
  return 1;
endfunction : master0_write_window

`endif
