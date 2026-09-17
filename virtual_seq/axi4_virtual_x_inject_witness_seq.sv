`ifndef AXI4_VIRTUAL_X_INJECT_WITNESS_SEQ_INCLUDED_
`define AXI4_VIRTUAL_X_INJECT_WITNESS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_x_inject_witness_seq
//
// BENCH-066 isolated reproduction (record section 5, "Minimal isolated
// reproduction"): ONE active master (master 0), a valid responder (slave 0
// running its ordinary blocking write/read sequences forever), no background
// traffic and no other pending item. The basic X-injection sequence
// axi4_master_x_inject_seq is then run for exactly one target signal, so the
// only way X can reach master 0's interface is through that sequence's own
// request. target == X_INJ_NONE is the injection-disabled control: the same
// responder, ordinary directed write + read traffic, and the witness must
// stay at zero.
//--------------------------------------------------------------------------------------------
class axi4_virtual_x_inject_witness_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_x_inject_witness_seq)

  x_inject_target_e        target        = X_INJ_AWADDR;
  int                      cycles        = 4;
  x_inject_assert_policy_e assert_policy = X_INJ_SUPPRESS_CHECKS;
  bit [63:0]               start_addr    = 64'h0000_0008_0000_2000;
  x_inject_result_e        expected_result = X_INJ_RESULT_OK;
  // Concurrent-traffic scenario (matrix row 6): while master 0 injects,
  // master bg_master keeps issuing ordinary blocking writes (-1 = none). The
  // test then checks that master bg_master's own witness stayed at zero -
  // no cross-agent injection, no request theft.
  int                      bg_master     = -1;
  bit [63:0]               bg_addr       = 64'h0000_0008_4000_3000;
  bit [2:0]                bg_prot       = 3'b111;
  int                      bg_writes_done = 0;

  // The basic sequence that was run, kept so the test can read back the
  // status the driver stamped on its injection item.
  axi4_master_x_inject_seq  master_x_seq_h;
  axi4_slave_bk_write_seq   axi4_slave_bk_write_seq_h;
  axi4_slave_bk_read_seq    axi4_slave_bk_read_seq_h;

  extern function new(string name = "axi4_virtual_x_inject_witness_seq");
  extern task body();
endclass : axi4_virtual_x_inject_witness_seq

function axi4_virtual_x_inject_witness_seq::new(string name = "axi4_virtual_x_inject_witness_seq");
  super.new(name);
endfunction : new

task axi4_virtual_x_inject_witness_seq::body();
  axi4_slave_bk_write_seq_h = axi4_slave_bk_write_seq::type_id::create("axi4_slave_bk_write_seq_h");
  axi4_slave_bk_read_seq_h  = axi4_slave_bk_read_seq::type_id::create("axi4_slave_bk_read_seq_h");

  fork
    begin : SL_WR
      forever axi4_slave_bk_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
    end
    begin : SL_RD
      forever axi4_slave_bk_read_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
    end
  join_none

  if(bg_master >= 0) begin
    // Responders for whatever the background master reaches, and the
    // background traffic itself.
    foreach(p_sequencer.axi4_slave_write_seqr_h_all[i]) begin
      automatic int si = i;
      if(si == 0 || p_sequencer.axi4_slave_write_seqr_h_all[si] == null) continue;
      fork
        begin
          axi4_slave_bk_write_seq sw = axi4_slave_bk_write_seq::type_id::create($sformatf("bg_slave_wr_%0d", si));
          forever sw.start(p_sequencer.axi4_slave_write_seqr_h_all[si]);
        end
      join_none
    end
    if(p_sequencer.axi4_master_write_seqr_h_all.size() <= bg_master || p_sequencer.axi4_master_write_seqr_h_all[bg_master] == null) begin
      `uvm_fatal(get_type_name(), $sformatf("background master %0d has no write sequencer", bg_master))
    end
    fork
      begin : BG_WR
        // Directed single-beat writes at an address legal for the background
        // master (random addresses would draw DECERRs that the performance
        // metrics count as protocol issues) - the same send_write_item() path
        // as the injection items, descriptor NONE.
        forever begin
          axi4_master_x_inject_seq bw = axi4_master_x_inject_seq::type_id::create("bg_master_wr");
          bw.control_only       = 1'b1;
          bw.control_prot_fixed = 1'b1;
          bw.control_prot       = bg_prot;
          bw.target_addr        = bg_addr;
          bw.test_id            = 4'h7;
          bw.start(p_sequencer.axi4_master_write_seqr_h_all[bg_master]);
          bg_writes_done++;
        end
      end
    join_none
  end

  if(target == X_INJ_NONE) begin
    // Control: the same directed write and read the injection tasks send as
    // their recovery items, with descriptor NONE, through the same path.
    axi4_master_x_inject_seq cw = axi4_master_x_inject_seq::type_id::create("ctrl_wr");
    axi4_master_x_inject_seq cr = axi4_master_x_inject_seq::type_id::create("ctrl_rd");
    cw.control_only = 1'b1; cw.target_addr = start_addr;      cw.test_id = 4'h3;
    cr.control_only = 1'b1; cr.target_addr = start_addr + 32; cr.test_id = 4'h3; cr.control_is_read = 1'b1;
    cw.start(p_sequencer.axi4_master_write_seqr_h);
    cr.start(p_sequencer.axi4_master_read_seqr_h);
    return;
  end

  master_x_seq_h = axi4_master_x_inject_seq::type_id::create("master_x_seq_h");
  master_x_seq_h.x_inject_cycles = cycles;
  master_x_seq_h.target_addr     = start_addr;
  master_x_seq_h.test_id         = 4'h3;
  master_x_seq_h.assert_policy   = assert_policy;
  master_x_seq_h.expected_result = expected_result;
  case(target)
    X_INJ_AWVALID: begin master_x_seq_h.inject_phase = axi4_master_x_inject_seq::PHASE_AW; master_x_seq_h.inject_signal = axi4_master_x_inject_seq::SIGNAL_VALID; end
    X_INJ_AWADDR : begin master_x_seq_h.inject_phase = axi4_master_x_inject_seq::PHASE_AW; master_x_seq_h.inject_signal = axi4_master_x_inject_seq::SIGNAL_ADDR;  end
    X_INJ_WDATA  : begin master_x_seq_h.inject_phase = axi4_master_x_inject_seq::PHASE_W;  master_x_seq_h.inject_signal = axi4_master_x_inject_seq::SIGNAL_DATA;  end
    X_INJ_ARVALID: begin master_x_seq_h.inject_phase = axi4_master_x_inject_seq::PHASE_AR; master_x_seq_h.inject_signal = axi4_master_x_inject_seq::SIGNAL_VALID; end
    X_INJ_BREADY : begin master_x_seq_h.inject_phase = axi4_master_x_inject_seq::PHASE_B;  master_x_seq_h.inject_signal = axi4_master_x_inject_seq::SIGNAL_READY; end
    X_INJ_RREADY : begin master_x_seq_h.inject_phase = axi4_master_x_inject_seq::PHASE_R;  master_x_seq_h.inject_signal = axi4_master_x_inject_seq::SIGNAL_READY; end
    default      : `uvm_fatal(get_type_name(), $sformatf("unsupported target %s", target.name()))
  endcase

  `uvm_info(get_type_name(), $sformatf("BENCH-066 witness run: target=%s cycles=%0d policy=%s addr=0x%016h",
                                       target.name(), cycles, assert_policy.name(), start_addr), UVM_LOW)

  if(target inside {X_INJ_ARVALID, X_INJ_RREADY})
    master_x_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
  else
    master_x_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
endtask : body

`endif
