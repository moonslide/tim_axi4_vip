`ifndef AXI4_QOS_RD_BYPASS_BOUND_TEST_INCLUDED_
`define AXI4_QOS_RD_BYPASS_BOUND_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_rd_bypass_bound_test
//  A low-priority read must not be overtaken without limit by a stream of
//  higher-priority reads. Knob under test: rd_qos_max_bypass (starvation
//  bound), with qos_rd_expect_bypass_max and qos_rd_arb_chk as the checks.
//
//  Master 0 issues, back to back: one read ARQOS 0 (ARID 1), then eight reads
//  ARQOS F (ARID 2..9). Slave 0: QOS_HOLD_EACH, hold_min=2, tmo=16 clk,
//  rd_qos_max_bypass=2, qos_rd_expect_bypass_max=2, qos_rd_arb_chk=1.
//
//  Verdict: no queued read overtaken more than twice (report_phase,
//  QOS_ARB_EXPECT); at least one choice was forced by the bound; the ARQOS-0
//  read (RID 1) is among the first three R bursts (check_phase).
//    +QOS_RD_NO_BYPASS_BOUND : rd_qos_max_bypass left at 0 (no bound). FAIL
//                              half: the ARQOS-0 read is overtaken by all eight
//                              and comes back last; this is also the negative
//                              check that the expectation can fail.
//--------------------------------------------------------------------------------------------
class axi4_qos_rd_bypass_bound_test extends axi4_qos_rd_arb_base_test;
  `uvm_component_utils(axi4_qos_rd_bypass_bound_test)

  extern function new(string name = "axi4_qos_rd_bypass_bound_test", uvm_component parent = null);
  extern virtual function void setup_rd_qos(axi4_slave_agent_config c);
  extern virtual function void fill_reads(axi4_virtual_qos_rd_tagged_seq v);
  extern virtual function void check_phase(uvm_phase phase);
endclass : axi4_qos_rd_bypass_bound_test

function axi4_qos_rd_bypass_bound_test::new(string name = "axi4_qos_rd_bypass_bound_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_qos_rd_bypass_bound_test::setup_rd_qos(axi4_slave_agent_config c);
  c.rd_qos_hold_scope        = QOS_HOLD_EACH;
  c.rd_qos_hold_min          = 2;
  c.rd_qos_hold_tmo_clk      = 16;
  c.qos_rd_arb_chk           = 1;
  c.qos_rd_expect_bypass_max = 2;
  if($test$plusargs("QOS_RD_NO_BYPASS_BOUND"))
    `uvm_info(get_type_name(), "+QOS_RD_NO_BYPASS_BOUND: rd_qos_max_bypass stays 0 - this run must FAIL", UVM_LOW)
  else
    c.rd_qos_max_bypass = 2;
endfunction : setup_rd_qos

function void axi4_qos_rd_bypass_bound_test::fill_reads(axi4_virtual_qos_rd_tagged_seq v);
  v.rd_qos.push_back(4'h0);
  v.rd_arid.push_back(1);
  for(int i = 2; i <= 9; i++) begin
    v.rd_qos.push_back(4'hF);
    v.rd_arid.push_back(i);
  end
endfunction : fill_reads

function void axi4_qos_rd_bypass_bound_test::check_phase(uvm_phase phase);
  axi4_slave_driver_proxy p = slave0_proxy();
  int pos[$];
  super.check_phase(phase);
  if(!rd_all_returned) return;   // already reported as QOS_RD_TIMEOUT
  pos = obs_h.r_id.find_first_index with (item == 1);
  if(p.qos_rd_forced_bypass < 1)
    `uvm_error("QOS_RD_BYPASS", $sformatf("no read-QoS choice was forced by the bypass bound (max_bypass_seen=%0d)", p.qos_rd_max_bypass_seen))
  if(pos.size() == 0 || pos[0] > 2)
    `uvm_error("QOS_RD_BYPASS", $sformatf("the ARQOS-0 read (RID 1) came back at position %0d of %0d, expected within the first 3; R order %p",
                                          (pos.size() ? pos[0] : -1), obs_h.r_id.size(), obs_h.r_id))
  else
    `uvm_info("QOS_RD_BYPASS", $sformatf("ARQOS-0 read returned at position %0d; forced_bypass=%0d max_bypass_seen=%0d; R order %p",
                                         pos[0], p.qos_rd_forced_bypass, p.qos_rd_max_bypass_seen, obs_h.r_id), UVM_LOW)
endfunction : check_phase

`endif
