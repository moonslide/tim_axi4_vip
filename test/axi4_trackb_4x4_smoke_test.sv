`ifndef AXI4_TRACKB_4X4_SMOKE_TEST_INCLUDED_
`define AXI4_TRACKB_4X4_SMOKE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_trackb_4x4_smoke_test
//
// Track-B smoke test against the 4x4 QoS commercial fabric IP (ext/nic400_vip4x4q).
//
// Build with:
//   +define+BUS_MATRIX_FABRIC_IP +define+FABRIC_IP_4X4
//   +define+DATA_WIDTH=256 +define+AXI_ID_WIDTH=6 +define+AXI_ID_LAST=63
//   -f ../../sim/axi4_compile_fabric_ip_4x4.f
//
// Why a separate fabric rather than `+BUS_MATRIX_MODE=4x4` on the 10x10 build
// -------------------------------------------------------------------------
// The fabric IP decodes addresses in hardware. The 10x10 fabric's decoder lists
// exactly the ten ENHANCED regions
// (nic400_asib_AXI4_Slave0_decode_vipv3b.v:97-115), so switching only the VIP's
// reference model to the BASE map left every transaction undecodable: measured
// 4/4 writes DECERR, "Protocol Issues : 4", TEST RESULT: FAIL. The fix is a
// fabric whose decoder IS the BASE map, which is what ext/nic400_vip4x4q is --
// regenerated from Socrates with four ingress, four egress, QoS from_master,
// and the offsets/ranges copied out of
// bm/axi4_bus_matrix_ref.sv::configure_base_matrix().
//
// S0 (DDR_Memory) is the target because it is the only BASE region every master
// may both read and write; S1 and S3 are read-only and S2 excludes M3.
//--------------------------------------------------------------------------------------------
class axi4_trackb_4x4_smoke_test extends axi4_trackb_smoke_test;
  `uvm_component_utils(axi4_trackb_4x4_smoke_test)

  function new(string name = "axi4_trackb_4x4_smoke_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    axi4_test_config cfg;

    // Publish the topology before axi4_base_test::setup_test_configuration()
    // runs, so it takes this instead of deriving one -- and so a stray
    // +BUS_MATRIX_MODE on the command line cannot change the map out from under
    // a fabric that has it burned into RTL.
    cfg = axi4_test_config::type_id::create("test_config");
    cfg.bus_matrix_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
    cfg.num_masters     = 4;
    cfg.num_slaves      = 4;
    uvm_config_db#(axi4_test_config)::set(null, "*", "test_config", cfg);

    // S0 DDR_Memory: read/write for all four masters in the BASE access matrix.
    target_slave = 0;

    super.build_phase(phase);

    `uvm_info(get_type_name(),
              "TRACK-B 4x4 SMOKE (ext/nic400_vip4x4q, BASE map, QoS from_master)",
              UVM_LOW)
  endfunction : build_phase

endclass : axi4_trackb_4x4_smoke_test

`endif
