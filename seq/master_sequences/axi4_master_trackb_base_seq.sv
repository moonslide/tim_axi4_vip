`ifndef AXI4_MASTER_TRACKB_BASE_SEQ_INCLUDED_
`define AXI4_MASTER_TRACKB_BASE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_trackb_base_seq
//
// Shared address-map knowledge for Track-B sequences, i.e. the ones that run
// against the real ARM CoreLink NIC-400 fabric DUT (+define+BUS_MATRIX_NIC400)
// instead of the 1:1 direct wiring in hdl_top.
//
// Why this exists
// ---------------
// The stock random sequences scatter addresses over the whole 64-bit space.
// With the direct 1:1 wiring that is harmless because nothing decodes the
// address. A real interconnect decodes it: every unmapped address is routed to
// the fabric's default slave and answered with DECERR, so the VIP slave agent
// never sees the transaction and the scoreboard ends the test with zero
// verified counts. Track-B sequences therefore have to stay inside the map.
//
// The region table below mirrors both claude.md (VIP ENHANCED 10x10 map) and
// the memory map compiled into the generated fabric
// (scripts/build_vip_fabric_v3.rb on the Socrates host).
//
// It also enforces the two rules the fabric will not forgive:
//   * an AXI4 burst must not cross a 4KB boundary
//   * a beat must not be wider than the data bus (256b -> awsize <= 5)
//--------------------------------------------------------------------------------------------
class axi4_master_trackb_base_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_trackb_base_seq)

  // Target slave region index, 0..9. Defaults to S2 (DDR Shared Buffer), the
  // one region every master is allowed to read and write in the access matrix.
  int unsigned target_slave = 2;

  // Largest legal awsize/arsize for the Track-B data bus (256 bits = 32 bytes).
  // Kept as a variable so a 128b/64b rebuild of the fabric only needs this
  // changed in one place.
  int unsigned max_size_log2 = 5;

  extern function new(string name = "axi4_master_trackb_base_seq");
  extern function bit [63:0] region_base(int unsigned idx);
  extern function bit [63:0] region_size(int unsigned idx);
endclass : axi4_master_trackb_base_seq

function axi4_master_trackb_base_seq::new(string name = "axi4_master_trackb_base_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: region_base
// Start address of slave region <idx> as mapped in the NIC-400 fabric.
//--------------------------------------------------------------------------------------------
function bit [63:0] axi4_master_trackb_base_seq::region_base(int unsigned idx);
`ifdef NIC400_4X4
  // The 4x4 fabric (ext/nic400_vip4x4q) carries the VIP's BASE bus-matrix map
  // in its decoder, verbatim from bm/axi4_bus_matrix_ref.sv:85-118.
  case (idx)
    0: return 64'h0000_0100_0000_0000; // S0 DDR_Memory        32GB
    1: return 64'h0000_0000_0000_0000; // S1 Boot_ROM         128KB (read-only)
    2: return 64'h0000_0010_0000_0000; // S2 Peripheral_Regs    1MB
    3: return 64'h0000_0020_0000_0000; // S3 HW_Fuse_Box        4KB (read-only)
    default: begin
      `uvm_error(get_type_name(), $sformatf("target_slave %0d out of range 0..3, using S0", idx))
      return 64'h0000_0100_0000_0000;
    end
  endcase
`else
  case (idx)
    0: return 64'h0000_0008_0000_0000; // S0 DDR Secure Kernel     1GB
    1: return 64'h0000_0008_4000_0000; // S1 DDR Non-Secure User   1GB
    2: return 64'h0000_0008_8000_0000; // S2 DDR Shared Buffer     1GB
    3: return 64'h0000_0008_C000_0000; // S3 Illegal Address Hole  1GB
    4: return 64'h0000_0009_0000_0000; // S4 XOM Instruction-Only  1GB
    5: return 64'h0000_000A_0000_0000; // S5 RO Peripheral        64KB
    6: return 64'h0000_000A_0001_0000; // S6 Privileged-Only      64KB
    7: return 64'h0000_000A_0002_0000; // S7 Secure-Only          64KB
    8: return 64'h0000_000A_0003_0000; // S8 Scratchpad           64KB
    9: return 64'h0000_000A_0004_0000; // S9 Attribute Monitor    64KB
    default: begin
      `uvm_error(get_type_name(), $sformatf("target_slave %0d out of range 0..9, using S2", idx))
      return 64'h0000_0008_8000_0000;
    end
  endcase
`endif
endfunction : region_base

//--------------------------------------------------------------------------------------------
// Function: region_size
// Size in bytes of slave region <idx>.
//--------------------------------------------------------------------------------------------
function bit [63:0] axi4_master_trackb_base_seq::region_size(int unsigned idx);
`ifdef NIC400_4X4
  case (idx)
    0: return 64'h0000_0008_0000_0000; // 32GB
    1: return 64'h0000_0000_0002_0000; // 128KB
    2: return 64'h0000_0000_0010_0000; // 1MB
    3: return 64'h0000_0000_0000_1000; // 4KB
    default: return 64'h0000_0008_0000_0000;
  endcase
`else
  return (idx <= 4) ? 64'h4000_0000 : 64'h0001_0000; // 1GB for S0-S4, 64KB for S5-S9
`endif
endfunction : region_size

`endif
