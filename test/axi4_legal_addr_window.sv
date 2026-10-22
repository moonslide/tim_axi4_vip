`ifndef AXI4_LEGAL_ADDR_WINDOW_INCLUDED_
`define AXI4_LEGAL_ADDR_WINDOW_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_legal_addr_window
//
// One place that answers "where may master N legally go in bus-matrix mode M?".
// The core master sequences (bk_/nbk_ write/read and friends) randomize awaddr /
// araddr with no address term at all; axi4_master_tx only has a SOFT alignment
// constraint on them. In NONE every address decodes to slave 0 with OKAY, so the
// tests pass there by luck. In BASE 4x4 and ENHANCED a uniformly random 64-bit
// address lands outside every slave window and gets DECERR, which
// axi4_performance_metrics counts as a protocol issue (TEST RESULT: FAIL).
//
// legal_window() returns the window as the intersection of what the reference
// model answers with OKAY (bm/axi4_bus_matrix_ref.sv, the baseline judge) and what
// the claude.md access matrix allows (the spec):
//
//   mode     | master        | dir | slave                 | base
//   ---------+---------------+-----+-----------------------+-----------------------
//   NONE     | any           | any | -                     | returns 0 (no window;
//            |               |     |                       | caller changes nothing)
//   BASE 4x4 | M0..M3        | R/W | S0 DDR_Memory         | 0x0000_0100_0000_0000
//   BASE 4x4 | M4+           | -   | -                     | returns 0
//   ENHANCED | M0,M1,M3..M7,M9 | R/W | S2 DDR Shared Buffer | 0x0000_0008_8000_0000
//   ENHANCED | M2, M8        | R   | S2 DDR Shared Buffer  | 0x0000_0008_8000_0000
//   ENHANCED | M2, M8        | W   | -                     | returns 0 (claude.md
//            |               |     |                       | gives them R only)
//
//   * 4x4 S0: configure_base_matrix() gives M0..M3 read and write; the 4x4 map has
//     no security or privilege check (get_write_resp / get_read_resp only run
//     those in BUS_ENHANCED_MATRIX). claude.md does not define the 4x4 map.
//   * ENHANCED S2: configure_enhanced_matrix() gives all ten masters read and
//     write, and get_write_resp / get_read_resp run no AxPROT check on slave 2.
//     claude.md section 3 lists S2 as "Shared R/W". So AxPROT is NOT pinned:
//     prot_fixed is always 0 and awprot / arprot stay random.
//   * AxPROT rules of the other ENHANCED slaves, for a future caller that needs
//     one of them (they are not used here):
//       S0, S4, S7 : AxPROT[1] == 0 (secure request) unless the master is secure
//                    (M0, M2, M5) -- check_security_access()
//       S4 read    : additionally ARPROT[2] == 1 (instruction) --
//                    check_instruction_access()
//       S6         : AxPROT[0] == 0 (privileged request) unless the master is
//                    privileged (M0, M2, M4, M5, M6, M9) -- check_privilege_access()
//     Such a caller would set prot_fixed / prot_val; the signature already has them.
//
// Sub-window: lo = base + master * 1 MiB, hi = lo + 1 MiB - 4 KiB. Each master gets
// its own 1 MiB, so two masters never pair on the same address. Start addresses
// stop 4 KiB short of the end of that 1 MiB, and axi4_master_tx's 4 KB-boundary
// constraints (aw_4kb_boundary_c7 / ar_4kb_boundary_c7) keep every burst inside
// one 4 KiB page, so the whole burst stays in the window.
//
// Pure function: no object is created, nothing is randomized, nothing is printed.
//--------------------------------------------------------------------------------------------
class axi4_legal_addr_window;

  static function bit legal_window(axi4_bus_matrix_ref::bus_matrix_mode_e mode,
                                   int unsigned master,
                                   bit is_write,
                                   output bit [ADDRESS_WIDTH-1:0] lo,
                                   output bit [ADDRESS_WIDTH-1:0] hi,
                                   output bit prot_fixed,
                                   output bit [2:0] prot_val);
    bit [ADDRESS_WIDTH-1:0] base;
    lo         = '0;
    hi         = '1;
    prot_fixed = 0;
    prot_val   = 3'b000;
    case (mode)
      axi4_bus_matrix_ref::BASE_BUS_MATRIX: begin
        if (master > 3) return 0;
        base = 64'h0000_0100_0000_0000;   // S0 DDR_Memory
      end
      axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: begin
        if (master > 9) return 0;
        if (is_write && (master == 2 || master == 8)) return 0;
        base = 64'h0000_0008_8000_0000;   // S2 DDR Shared Buffer
      end
      default: return 0;                  // NONE: no window
    endcase
    lo = base + (ADDRESS_WIDTH'(master) << 20);
    hi = lo + 64'h0010_0000 - 64'h1000;
    return 1;
  endfunction : legal_window

endclass : axi4_legal_addr_window

//--------------------------------------------------------------------------------------------
// Class: axi4_master_tx_legal_window
//
// axi4_master_tx with one extra HARD constraint: awaddr and araddr inside
// [win_lo:win_hi]. A test opts in by calling enable() in its build_phase, which
// registers this class as a factory type override of axi4_master_tx. Every
// `axi4_master_tx::type_id::create` in that test then builds this type, so the
// window merges with the inline `with {}` of every master sequence and no
// sequence has to repeat it. A sequence that pins an address outside the window
// fails randomize (loud "Rand failed"), never silently.
//
// Call enable() ONLY when the mode is not NONE: in NONE the override is never
// registered, this class is never instantiated, and the run is the same as
// without this file.
//
// win_lo / win_hi are static state variables, not rand: the class adds no random
// variable. No pre/post_randomize. The only clone() users (driver / monitor
// proxies) do not randomize, so there only the type name changes.
//--------------------------------------------------------------------------------------------
class axi4_master_tx_legal_window extends axi4_master_tx;
  `uvm_object_utils(axi4_master_tx_legal_window)

  // One window for the whole run: these statics are shared by every instance, so
  // enable() supports ONE master per run. A second enable() for another master would
  // silently replace this window for all masters.
  // ENHANCED note: on the 1:1 direct wiring the M0 -> S2 window is not inside the memory
  // range of slave agent 0 (S0), so the slave answers through the bus-matrix path and the
  // read data is not read back from slave memory; the scoreboard still pairs and compares
  // the data seen on the wires. 4x4 reads do come from slave memory.
  static bit [ADDRESS_WIDTH-1:0] win_lo;
  static bit [ADDRESS_WIDTH-1:0] win_hi;

  constraint legal_window_c {
    awaddr inside {[win_lo:win_hi]};
    araddr inside {[win_lo:win_hi]};
  }

  function new(string name = "axi4_master_tx_legal_window");
    super.new(name);
  endfunction : new

  extern static function void enable(axi4_bus_matrix_ref::bus_matrix_mode_e mode,
                                     int unsigned master);

endclass : axi4_master_tx_legal_window

//--------------------------------------------------------------------------------------------
// Function: enable
// Looks up master's write window for mode (the read window is the same slave),
// stores it and registers the factory override. No window -> fatal, so a test
// cannot run believing it is constrained when it is not.
// Static context: the report calls go through uvm_pkg directly because the
// `uvm_* macros would resolve to the (non-static) uvm_sequence_item report methods.
//--------------------------------------------------------------------------------------------
function void axi4_master_tx_legal_window::enable(axi4_bus_matrix_ref::bus_matrix_mode_e mode,
                                                  int unsigned master);
  bit [ADDRESS_WIDTH-1:0] lo, hi;
  bit                     prot_fixed;
  bit [2:0]               prot_val;

  if (!axi4_legal_addr_window::legal_window(mode, master, 1'b1, lo, hi, prot_fixed, prot_val)) begin
    uvm_pkg::uvm_report_fatal("ADDR_WINDOW",
      $sformatf("no legal write window for master %0d in mode %s", master, mode.name()),
      UVM_NONE, `__FILE__, `__LINE__);
    return;
  end
  win_lo = lo;
  win_hi = hi;
  axi4_master_tx::type_id::set_type_override(axi4_master_tx_legal_window::get_type());
  uvm_pkg::uvm_report_info("ADDR_WINDOW",
    $sformatf("mode=%s master=%0d window=[0x%016h:0x%016h]", mode.name(), master, lo, hi),
    UVM_LOW, `__FILE__, `__LINE__);
endfunction : enable

`endif
