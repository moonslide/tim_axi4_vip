`ifndef AXI4_QOS_WR_AW_ORDER_TEST_INCLUDED_
`define AXI4_QOS_WR_AW_ORDER_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_wr_aw_order_test
//  Manager write QoS must not put W bursts out of AW order (AXI4 has no WID;
//  A3.4.1). Knob under test: axi4_master_agent_config::wr_qos_arb_point
//  (EXPERIMENTAL WR_QOS_ARB_AT_AW).
//
//  Master 0 (write QoS on, as in axi4_qos_basic_priority_test) issues nine
//  single-beat writes back to back with DISTINCT AWIDs 1..9 and shuffled AWQOS
//  3,9,1,F,6,C,2,8,5. Every write's data is tagged with its own AWID
//  (axi4_master_qos_tagged_write_seq), and master 0's monitor records the AW
//  order (AWID) and the W order (tag) on the wire.
//
//  Verdict (check_phase):
//    * the k-th W burst carries the tag of the k-th AW, for every k;
//    * at AW-issue arbitration the QoS choice really happened: the AW order on
//      the wire is not the issue order and QOS_WR_AW_STATS reordered >= 1.
//    default run          : wr_qos_arb_point = WR_QOS_ARB_AT_AW. PASS.
//    +QOS_WR_AW_LEGACY    : master 0 keeps the default WR_QOS_ARB_AT_WDATA, whose
//                           W-data-phase arbitration sends the highest-AWQOS W
//                           first - W bursts out of AW order, QOS_WR_ORDER
//                           errors. This is the FAIL half and the measured
//                           behaviour of the legacy arbiter.
//  Run with +BUS_MATRIX_MODE=NONE.
//--------------------------------------------------------------------------------------------
class axi4_qos_wr_aw_order_test extends axi4_qos_basic_priority_test;
  `uvm_component_utils(axi4_qos_wr_aw_order_test)

  axi4_qos_ctrl_observer         obs_h;
  axi4_virtual_qos_wr_tagged_seq wr_vseq_h;
  time                           wr_wait_bound = 2us;
  bit                            wr_all_seen;

  extern function new(string name = "axi4_qos_wr_aw_order_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);
  extern virtual function void check_phase(uvm_phase phase);
endclass : axi4_qos_wr_aw_order_test

function axi4_qos_wr_aw_order_test::new(string name = "axi4_qos_wr_aw_order_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_qos_wr_aw_order_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(axi4_env_cfg_h.bus_matrix_mode != axi4_bus_matrix_ref::NONE)
    `uvm_fatal(get_type_name(), $sformatf("written for 1:1 wiring - run with +BUS_MATRIX_MODE=NONE (got %s)",
                                          axi4_env_cfg_h.bus_matrix_mode.name()))
  obs_h = axi4_qos_ctrl_observer::type_id::create("qos_obs_m0", this);
endfunction : build_phase

function void axi4_qos_wr_aw_order_test::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  obs_h.connect_to(axi4_env_h.axi4_master_agent_h[0].axi4_master_mon_proxy_h);
endfunction : connect_phase

function void axi4_qos_wr_aw_order_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();   // write QoS on (WRITE_READ_QOS_MODE_ENABLE)
  if($test$plusargs("QOS_WR_AW_LEGACY"))
    `uvm_info(get_type_name(), "+QOS_WR_AW_LEGACY: master 0 keeps WR_QOS_ARB_AT_WDATA - this run must FAIL", UVM_LOW)
  else
    axi4_env_cfg_h.axi4_master_agent_cfg_h[0].wr_qos_arb_point = WR_QOS_ARB_AT_AW;
endfunction : setup_axi4_master_agent_cfg

task axi4_qos_wr_aw_order_test::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  wr_vseq_h         = axi4_virtual_qos_wr_tagged_seq::type_id::create("wr_vseq_h");
  wr_vseq_h.wr_qos  = '{4'h3, 4'h9, 4'h1, 4'hF, 4'h6, 4'hC, 4'h2, 4'h8, 4'h5};
  wr_vseq_h.wr_awid = '{1, 2, 3, 4, 5, 6, 7, 8, 9};
  wr_vseq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  // Isolating fork: the disable must not reach the subordinate sequences.
  fork
    begin : wait_isolate
      fork
        begin wait(obs_h.w_tag.size() >= wr_vseq_h.wr_qos.size()); wr_all_seen = 1; end
        #(wr_wait_bound);
      join_any
      disable fork;
    end
  join
  if(!wr_all_seen)
    `uvm_error("QOS_WR_TIMEOUT", $sformatf("only %0d of %0d W bursts seen at master 0 within %0t",
                                           obs_h.w_tag.size(), wr_vseq_h.wr_qos.size(), wr_wait_bound))
  #100ns;
  phase.drop_objection(this);
endtask : run_phase

function void axi4_qos_wr_aw_order_test::check_phase(uvm_phase phase);
  axi4_master_driver_proxy p = axi4_env_h.axi4_master_agent_h[0].axi4_master_drv_proxy_h;
  int issue_order[$] = '{1, 2, 3, 4, 5, 6, 7, 8, 9};
  int bad;
  super.check_phase(phase);
  if(!wr_all_seen) return;   // already reported as QOS_WR_TIMEOUT
  foreach(obs_h.w_tag[k]) begin
    bit [31:0] exp = (k < obs_h.aw_id.size()) ? (axi4_master_qos_tagged_write_seq::TAG_BASE | obs_h.aw_id[k]) : 32'hFFFF_FFFF;
    if(obs_h.w_tag[k] != exp) begin
      bad++;
      `uvm_error("QOS_WR_ORDER", $sformatf("W burst #%0d carries tag 0x%08h but AW #%0d on the wire was awid=0x%0h (expected tag 0x%08h) - W out of AW order",
                                           k, obs_h.w_tag[k], k, (k < obs_h.aw_id.size()) ? obs_h.aw_id[k] : -1, exp))
    end
  end
  `uvm_info("QOS_WR_ORDER", $sformatf("%0d of %0d W bursts out of AW order; AW order (AWID) %p, AWQOS %p; W tags %p; arb_point=%s",
                                      bad, obs_h.w_tag.size(), obs_h.aw_id, obs_h.aw_qos, obs_h.w_tag,
                                      p.axi4_master_agent_cfg_h.wr_qos_arb_point.name()), UVM_LOW)
  if(p.axi4_master_agent_cfg_h.wr_qos_arb_point == WR_QOS_ARB_AT_AW) begin
    if(obs_h.aw_id == issue_order || p.wr_aw_reordered < 1)
      `uvm_error("QOS_WR_ORDER", $sformatf("AW-issue arbitration made no QoS choice: AW order %p, reordered=%0d - the W-order check above proves nothing",
                                           obs_h.aw_id, p.wr_aw_reordered))
  end
endfunction : check_phase

`endif
