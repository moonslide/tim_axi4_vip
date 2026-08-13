`ifndef AXI4_TRACKB_4K_BOUNDARY_TEST_INCLUDED_
`define AXI4_TRACKB_4K_BOUNDARY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_trackb_4k_boundary_test
//
// Track-B native vehicle for the 4KB-boundary-crossing question.
//
// Why this exists
// ---------------
// axi4_4k_boundary_cross_test runs against the 1:1 direct wiring, where no RTL
// decodes an address and no arbiter exists.  Its result therefore says nothing
// about how a real interconnect handles a burst spanning two pages -- the
// env-side axi4_bus_matrix_ref is a uvm_component reference model, not a DUT.
// This test asks the same question of the real commercial fabric IP.
//
// The experiment is isolated on purpose (see axi4_master_trackb_4k_cross_seq):
// both pages the burst touches lie inside ONE mapped slave region, so a DECERR
// here cannot be blamed on the address map.  Whatever the fabric reports is
// its 4KB-crossing behaviour.
//
// Deliberately does NOT set allow_error_responses: an error response to a
// crossing burst inside a mapped region is exactly the finding this test is
// built to surface, so it must be allowed to fail the run.
//
// Build/run:
//   +define+BUS_MATRIX_FABRIC_IP +define+DATA_WIDTH=256 +define+AXI_ID_WIDTH=8 +define+AXI_ID_LAST=255
//   -f ../../sim/axi4_compile_fabric_ip.f
//   +UVM_TESTNAME=axi4_trackb_4k_boundary_test +BUS_MATRIX_MODE=ENHANCED
//--------------------------------------------------------------------------------------------
class axi4_trackb_4k_boundary_test extends axi4_trackb_smoke_test;
  `uvm_component_utils(axi4_trackb_4k_boundary_test)

  axi4_master_trackb_write_seq         inpage_write_seq;
  axi4_master_trackb_read_seq          inpage_read_seq;
  axi4_master_trackb_4k_cross_seq      cross_write_seq;
  axi4_master_trackb_4k_cross_read_seq cross_read_seq;

  // Progress markers for the inherited watchdog report.
  protected bit inpage_done;
  protected bit cross_write_done;
  protected bit cross_read_done;

  function new(string name = "axi4_trackb_4k_boundary_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //------------------------------------------------------------------------
  // Task: trackb_test_body
  // Overriding this (rather than run_phase) is what keeps the base class's
  // topology binding and watchdog attached -- see axi4_trackb_smoke_test.
  //------------------------------------------------------------------------
  virtual task trackb_test_body();
    start_slave_responders("trackb_4k");

    `uvm_info(get_type_name(),
              $sformatf("4KB-crossing experiment at slave region S%0d (both pages inside the region)",
                        target_slave), UVM_LOW)

    // ---- Control leg: an ordinary in-page burst through the same region.
    // If this fails, the crossing result means nothing -- the path itself is
    // broken and that is what the log should say.
    inpage_write_seq = axi4_master_trackb_write_seq::type_id::create("inpage_write_seq");
    inpage_write_seq.target_slave = target_slave;
    inpage_write_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[0]);

    inpage_read_seq = axi4_master_trackb_read_seq::type_id::create("inpage_read_seq");
    inpage_read_seq.target_slave = target_slave;
    inpage_read_seq.read_addr    = inpage_write_seq.last_addr;
    inpage_read_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h_all[0]);
    inpage_done = 1;
    `uvm_info(get_type_name(), "Control leg (in-page burst) completed", UVM_LOW)

    // ---- The experiment: same region, burst straddling a 4KB boundary.
    cross_write_seq = axi4_master_trackb_4k_cross_seq::type_id::create("cross_write_seq");
    cross_write_seq.target_slave = target_slave;
    cross_write_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h_all[0]);
    cross_write_done = 1;

    cross_read_seq = axi4_master_trackb_4k_cross_read_seq::type_id::create("cross_read_seq");
    cross_read_seq.target_slave = target_slave;
    cross_read_seq.read_addr    = cross_write_seq.last_addr;
    cross_read_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h_all[0]);
    cross_read_done = 1;

    // The fabric adds pipeline and arbitration latency on top of the slave
    // response time; give the responses room to drain before the test ends.
    #5000ns;
  endtask : trackb_test_body

  virtual function string trackb_progress_str();
    return $sformatf("in-page control %s, crossing write %s, crossing read %s",
                     inpage_done      ? "done" : "NOT REACHED",
                     cross_write_done ? "done" : "NOT REACHED",
                     cross_read_done  ? "done" : "NOT REACHED");
  endfunction : trackb_progress_str

endclass : axi4_trackb_4k_boundary_test

`endif
