`ifndef AXI4_MASTER_QOS_BID_RACE_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_BID_RACE_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_bid_race_write_seq
//
// AXI_ooo.md F1 (Phase 1) repro stimulus.
//
// A QoS-mode write whose burst LENGTH is settable per master. That single knob is
// what turns the shared, package-scope `awid_queue_for_qos` (pkg/axi4_globals_pkg.sv)
// into a visible defect: every master PUSHES its AWID at the top of its write-data
// thread (master/axi4_master_driver_proxy.sv:450,455,460,470) but every slave POPS
// the queue FRONT when it builds its BID (slave/axi4_slave_driver_proxy.sv:422).
// The popped value is only the right one while every pair completes in exactly the
// order it pushed. Give one master a long burst and the short-burst pairs respond
// first, so they take a BID that belongs to a DIFFERENT master-slave pair.
//
// Deliberately deterministic: fixed 4KB-aligned address per (slave, index) so a
// long INCR burst can never cross a 4KB boundary and the repro does not depend on
// the seed.
//--------------------------------------------------------------------------------------------
class axi4_master_qos_bid_race_write_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_qos_bid_race_write_seq)

  // QoS value driven on AWQOS (all masters use the same value here: the point of
  // this test is the shared queue, not the priority arbitration itself).
  bit [3:0] qos_value = 4'b0100;

  // Master index; also the AWID this master drives (AWID_<master_id>).
  int master_id = 0;

  // Slave whose address range is targeted. With the 1:1 direct wiring in
  // top/hdl_top.sv this must equal master_id, otherwise the address decodes to a
  // different slave than the one physically wired to this master.
  int target_slave_id = 0;

  // Burst length knob (AWLEN, i.e. beats-1). The skew between masters is the
  // whole mechanism of this repro.
  bit [7:0] burst_len = 8'h00;

  // Which write of the sequence this is; only used to space the addresses out.
  int txn_index = 0;

  extern function new(string name = "axi4_master_qos_bid_race_write_seq");
  extern task body();

endclass : axi4_master_qos_bid_race_write_seq

function axi4_master_qos_bid_race_write_seq::new(string name = "axi4_master_qos_bid_race_write_seq");
  super.new(name);
endfunction : new

task axi4_master_qos_bid_race_write_seq::body();
  bit [63:0] slave_base;
  bit [63:0] target_addr;
  bit [2:0]  prot_value;

  super.body();

  // ENHANCED (10x10) address map, mirrored from
  // axi4_master_qos_priority_write_seq / axi4_base_test::setup_enhanced_*.
  // Only the three writable DDR regions are used.
  case(target_slave_id)
    0: begin slave_base = 64'h0000_0008_0000_0000; prot_value = 3'b000; end // S0 DDR Secure Kernel
    1: begin slave_base = 64'h0000_0008_4000_0000; prot_value = 3'b010; end // S1 DDR Non-Secure User
    2: begin slave_base = 64'h0000_0008_8000_0000; prot_value = 3'b010; end // S2 DDR Shared Buffer
    default: begin slave_base = 64'h0000_0008_0000_0000; prot_value = 3'b000; end
  endcase

  // 4KB-aligned, one page per transaction: an INCR burst of up to 256 beats x
  // 4 bytes stays inside its page, so no 4KB-crossing protocol violation.
  target_addr = slave_base + (txn_index * 64'h1000);

  start_item(req);

  if(!req.randomize() with {
    req.tx_type        == WRITE;
    req.transfer_type  == NON_BLOCKING_WRITE;
    req.awqos          == local::qos_value;
    req.awburst        == WRITE_INCR;
    req.awsize         == WRITE_4_BYTES;
    req.awlen          == local::burst_len;
    req.awaddr         == local::target_addr;
    req.awprot         == local::prot_value;
  }) begin
    `uvm_fatal("axi4", "Randomization failed for QoS BID-race write sequence")
  end

  // AWID identifies the originating master; the scoreboard's
  // "bid returned to the WRONG manager" check (env/axi4_scoreboard.sv:2860)
  // is what catches the shared-queue defect.
  req.awid = awid_e'(master_id);

  `uvm_info(get_type_name(), $sformatf(
            "QOS_BID_RACE write: master=%0d awid=%0d slave=%0d addr=0x%016h awlen=%0d",
            master_id, master_id, target_slave_id, target_addr, burst_len), UVM_MEDIUM)

  finish_item(req);

endtask : body

`endif
