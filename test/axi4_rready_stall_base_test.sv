`ifndef AXI4_RREADY_STALL_BASE_TEST_INCLUDED_
`define AXI4_RREADY_STALL_BASE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_rready_stall_witness_sub
//
// Collects every COMPLETED read the master-0 monitor publishes so the test can
// check the pin-level witness per transaction (BENCH-065 acceptance items 2-4:
// stall observed at the requested position, exact ARLEN+1 beats, and a
// no-stall control that must show NO interior back-pressure).
//--------------------------------------------------------------------------------------------
class axi4_rready_stall_witness_sub extends uvm_subscriber #(axi4_master_tx);
  `uvm_component_utils(axi4_rready_stall_witness_sub)

  axi4_master_tx pkts[$];

  function new(string name = "axi4_rready_stall_witness_sub", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void write(axi4_master_tx t);
    axi4_master_tx c;
    $cast(c, t.clone());
    pkts.push_back(c);
  endfunction : write
endclass : axi4_rready_stall_witness_sub

//--------------------------------------------------------------------------------------------
// Class: axi4_rready_stall_base_test
//
// BENCH-065 directed test. Master 0 issues n_reads INCR reads of ARLEN=3
// (4 beats) at a legal slave-0 address; slave 0 streams RVALID gaplessly. The
// derived tests choose the back-pressure position:
//   first  : r_wait_states=exp_first_ws, no r_stall request  (pre-existing knob, must be unchanged)
//   middle : r_stall_beat=2 (interior: not first, not last)
//   last   : r_stall_beat=3 (== ARLEN, the final beat)
// Pass criteria are checked here, in check_phase, from what the MONITOR saw:
//   * exactly n_reads completed reads, each with ARLEN+1 beats and RLAST
//   * r_wait_states (beat-0 delay measured on the pins) == exp_first_ws
//   * the stamped request equals what the sequence asked for
//   * r_stall_beat_observed / r_stall_cycles_observed equal the request
//     (-1 / 0 when nothing was requested: NO incidental interior stall)
// The stability of RDATA/RRESP/RID/RLAST and the held RVALID during the stall
// are covered by the bound AXI_RD_STABLE_SIGNALS_CHECK / valid-until-ready
// assertions (assertions/master_assertions.sv, slave_assertions.sv), and the
// data itself by the scoreboard in ONLY_READ_DATA mode.
// Plusargs (ad-hoc experiments only; the registered tests use the class
// defaults): +RSTALL_BEAT=<n> +RSTALL_CYCLES=<n> +RSTALL_FIRST_WS=<n>
// +RSTALL_DIRECT=1 (bypass the constraint, exercise the BFM's validation).
//--------------------------------------------------------------------------------------------
class axi4_rready_stall_base_test extends axi4_base_test;
  `uvm_component_utils(axi4_rready_stall_base_test)

  int        n_reads        = 2;
  int        burst_len      = 3;
  int        exp_first_ws   = 0;
  int        exp_stall_beat = -1;
  int        exp_stall_cyc  = 0;
  bit        direct_assign  = 1'b0;
  // Slave-0 address legal for master 0 in the selected bus-matrix mode
  // (bm/axi4_bus_matrix_ref.sv: BASE 4x4 maps S0 at 0x0000_0100_0000_0000,
  // ENHANCED at 0x0000_0008_0000_0000, NONE accepts anything). Set in
  // build_phase once the +BUS_MATRIX_MODE override has been applied.
  bit [63:0] start_addr     = 64'h0000_0008_0000_1000;

  axi4_rready_stall_witness_sub witness_h;
  axi4_virtual_rready_stall_seq axi4_virtual_rready_stall_seq_h;

  extern function new(string name = "axi4_rready_stall_base_test", uvm_component parent = null);
  extern function void setup_axi4_env_cfg();
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void check_phase(uvm_phase phase);
endclass : axi4_rready_stall_base_test

function axi4_rready_stall_base_test::new(string name = "axi4_rready_stall_base_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_rready_stall_base_test::setup_axi4_env_cfg();
  super.setup_axi4_env_cfg();
  axi4_env_cfg_h.write_read_mode_h = ONLY_READ_DATA;
endfunction : setup_axi4_env_cfg

function void axi4_rready_stall_base_test::build_phase(uvm_phase phase);
  int v;
  super.build_phase(phase);
  if($value$plusargs("RSTALL_BEAT=%d", v))     exp_stall_beat = v;
  if($value$plusargs("RSTALL_CYCLES=%d", v))   exp_stall_cyc  = v;
  if($value$plusargs("RSTALL_FIRST_WS=%d", v)) exp_first_ws   = v;
  if($value$plusargs("RSTALL_DIRECT=%d", v))   direct_assign  = (v != 0);
  if(test_config.bus_matrix_mode == axi4_bus_matrix_ref::BASE_BUS_MATRIX) begin
    start_addr = 64'h0000_0100_0000_1000;
  end
  witness_h = axi4_rready_stall_witness_sub::type_id::create("witness_h", this);
endfunction : build_phase

function void axi4_rready_stall_base_test::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  axi4_env_h.axi4_master_agent_h[0].axi4_master_mon_proxy_h.axi4_master_read_data_analysis_port.connect(witness_h.analysis_export);
endfunction : connect_phase

task axi4_rready_stall_base_test::run_phase(uvm_phase phase);
  axi4_virtual_rready_stall_seq_h = axi4_virtual_rready_stall_seq::type_id::create("axi4_virtual_rready_stall_seq_h");
  axi4_virtual_rready_stall_seq_h.n_reads       = n_reads;
  axi4_virtual_rready_stall_seq_h.burst_len     = burst_len;
  axi4_virtual_rready_stall_seq_h.first_beat_ws = exp_first_ws;
  axi4_virtual_rready_stall_seq_h.stall_beat    = exp_stall_beat;
  axi4_virtual_rready_stall_seq_h.stall_cycles  = exp_stall_cyc;
  axi4_virtual_rready_stall_seq_h.direct_assign = direct_assign;
  axi4_virtual_rready_stall_seq_h.start_addr    = start_addr;
  `uvm_info(get_type_name(),$sformatf("BENCH-065 run: n_reads=%0d arlen=%0d first_ws=%0d stall_beat=%0d stall_cycles=%0d direct=%0d addr=0x%016h",
                                      n_reads,burst_len,exp_first_ws,exp_stall_beat,exp_stall_cyc,direct_assign,start_addr),UVM_LOW)
  phase.raise_objection(this);
  axi4_virtual_rready_stall_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  // Let the monitor publish the last burst and the scoreboard consume it.
  #10ns;
  phase.drop_objection(this);
endtask : run_phase

function void axi4_rready_stall_base_test::check_phase(uvm_phase phase);
  int exp_obs_beat;
  int exp_obs_cyc;
  super.check_phase(phase);

  // What the pins must have shown, given a LEGAL request. An invalid request
  // (direct-assign experiments) is applied as no stall by the driver BFM.
  if(exp_stall_beat >= 1 && exp_stall_beat <= burst_len && exp_stall_cyc >= 1 && exp_stall_cyc <= R_BEAT_STALL_MAX) begin
    exp_obs_beat = exp_stall_beat;
    exp_obs_cyc  = exp_stall_cyc;
  end
  else begin
    exp_obs_beat = -1;
    exp_obs_cyc  = 0;
  end

  if(witness_h.pkts.size() != n_reads) begin
    `uvm_error(get_type_name(),$sformatf("BENCH-065: master-0 monitor published %0d completed reads, expected %0d",witness_h.pkts.size(),n_reads))
  end

  foreach(witness_h.pkts[i]) begin
    axi4_master_tx p = witness_h.pkts[i];
    `uvm_info(get_type_name(),$sformatf("BENCH-065 witness[%0d]: arid=%s arlen=%0d beats=%0d rlast=%0d r_wait_states=%0d request(beat=%0d,cycles=%0d) observed(beat=%0d,cycles=%0d)",
                                        i,p.arid.name(),p.arlen,p.rdata.size(),p.rlast,p.r_wait_states,
                                        p.r_stall_beat,p.r_stall_cycles,p.r_stall_beat_observed,p.r_stall_cycles_observed),UVM_LOW)
    if(p.rdata.size() != burst_len + 1 || p.rlast !== 1'b1) begin
      `uvm_error(get_type_name(),$sformatf("BENCH-065 witness[%0d]: expected exactly %0d beats ending in RLAST, got %0d beats rlast=%0d",i,burst_len+1,p.rdata.size(),p.rlast))
    end
    if(p.r_wait_states != exp_first_ws) begin
      `uvm_error(get_type_name(),$sformatf("BENCH-065 witness[%0d]: first-beat RREADY delay measured %0d, requested r_wait_states=%0d",i,p.r_wait_states,exp_first_ws))
    end
    if(p.r_stall_beat != exp_obs_beat || p.r_stall_cycles != exp_obs_cyc) begin
      `uvm_error(get_type_name(),$sformatf("BENCH-065 witness[%0d]: stamped request (beat=%0d,cycles=%0d) does not match the applied request (beat=%0d,cycles=%0d)",
                                           i,p.r_stall_beat,p.r_stall_cycles,exp_obs_beat,exp_obs_cyc))
    end
    if(p.r_stall_beat_observed != exp_obs_beat || p.r_stall_cycles_observed != exp_obs_cyc) begin
      if(exp_obs_beat == -1) begin
        `uvm_error(get_type_name(),$sformatf("BENCH-065 witness[%0d]: no interior stall was requested but the monitor saw RREADY low for %0d cycle(s) in front of beat %0d",
                                             i,p.r_stall_cycles_observed,p.r_stall_beat_observed))
      end
      else begin
        `uvm_error(get_type_name(),$sformatf("BENCH-065 witness[%0d]: requested RREADY low for %0d cycle(s) in front of beat %0d, monitor observed beat=%0d cycles=%0d (-1 = no interior stall seen)",
                                             i,exp_obs_cyc,exp_obs_beat,p.r_stall_beat_observed,p.r_stall_cycles_observed))
      end
    end
  end
endfunction : check_phase

//--------------------------------------------------------------------------------------------
// The three BENCH-065 positions (first / middle / last), each its own test so
// the regression list can run them separately in every bus-matrix mode.
//--------------------------------------------------------------------------------------------
class axi4_rready_stall_first_beat_test extends axi4_rready_stall_base_test;
  `uvm_component_utils(axi4_rready_stall_first_beat_test)
  function new(string name = "axi4_rready_stall_first_beat_test", uvm_component parent = null);
    super.new(name, parent);
    exp_first_ws   = 4;    // pre-existing knob: beat-0 delay via r_wait_states
    exp_stall_beat = -1;
    exp_stall_cyc  = 0;
  endfunction : new
endclass : axi4_rready_stall_first_beat_test

class axi4_rready_stall_mid_burst_test extends axi4_rready_stall_base_test;
  `uvm_component_utils(axi4_rready_stall_mid_burst_test)
  function new(string name = "axi4_rready_stall_mid_burst_test", uvm_component parent = null);
    super.new(name, parent);
    exp_first_ws   = 0;
    exp_stall_beat = 2;    // interior: beats 0 and 1 accepted, beat 2 back-pressured, beat 3 (RLAST) follows
    exp_stall_cyc  = 3;
  endfunction : new
endclass : axi4_rready_stall_mid_burst_test

class axi4_rready_stall_last_beat_test extends axi4_rready_stall_base_test;
  `uvm_component_utils(axi4_rready_stall_last_beat_test)
  function new(string name = "axi4_rready_stall_last_beat_test", uvm_component parent = null);
    super.new(name, parent);
    exp_first_ws   = 0;
    exp_stall_beat = 3;    // == ARLEN: the RLAST beat itself is back-pressured
    exp_stall_cyc  = 3;
  endfunction : new
endclass : axi4_rready_stall_last_beat_test

`endif
