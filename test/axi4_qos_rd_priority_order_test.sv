`ifndef AXI4_QOS_RD_PRIORITY_ORDER_TEST_INCLUDED_
`define AXI4_QOS_RD_PRIORITY_ORDER_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_rd_priority_order_test
//  The subordinate read-QoS arbiter must serve queued reads strictly by ARQOS
//  when it is configured to hold before EVERY response. Knobs under test:
//  rd_qos_hold_scope = QOS_HOLD_EACH, rd_qos_hold_min, rd_qos_hold_tmo_clk, and
//  the checks qos_rd_arb_chk (rule self-check) and qos_rd_expect_reorder_min.
//
//  Master 0 issues four reads back to back in ASCENDING priority:
//      ARQOS 1, 3, 7, F   with ARID 1, 3, 7, F (distinct IDs, so AXI4 allows
//                         the subordinate to return them in any order)
//  Slave 0: QOS_HOLD_EACH, hold_min=4, tmo=32 clk, qos_rd_arb_chk=1,
//  qos_rd_expect_reorder_min=3.
//
//  Verdict (check_phase): R bursts come back in DESCENDING priority, i.e. RID
//  order F, 7, 3, 1, as seen by master 0's monitor; the arbiter's own
//  re-derivation reports no mismatch; at least 3 choices overtook an older read.
//    +QOS_RD_ORDER_LEGACY : slave 0 keeps the default knobs (hold only before
//                           the first response, until 2 reads). FAIL half: the
//                           pool is too small after the first choice, so the
//                           R order is not F,7,3,1.
//    +QOS_RD_ORDER_QOS_OFF: slave 0 read QoS disabled - responses in order,
//                           every check must fail (negative check).
//--------------------------------------------------------------------------------------------
class axi4_qos_rd_priority_order_test extends axi4_qos_rd_arb_base_test;
  `uvm_component_utils(axi4_qos_rd_priority_order_test)

  extern function new(string name = "axi4_qos_rd_priority_order_test", uvm_component parent = null);
  extern virtual function void setup_rd_qos(axi4_slave_agent_config c);
  extern virtual function void fill_reads(axi4_virtual_qos_rd_tagged_seq v);
  extern virtual function void check_phase(uvm_phase phase);
endclass : axi4_qos_rd_priority_order_test

function axi4_qos_rd_priority_order_test::new(string name = "axi4_qos_rd_priority_order_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_qos_rd_priority_order_test::setup_rd_qos(axi4_slave_agent_config c);
  c.qos_rd_arb_chk            = 1;
  c.qos_rd_expect_reorder_min = 3;
  if($test$plusargs("QOS_RD_ORDER_QOS_OFF")) begin
    c.qos_mode_type = QOS_MODE_DISABLE;
    `uvm_info(get_type_name(), "+QOS_RD_ORDER_QOS_OFF: slave 0 read QoS disabled - this run must FAIL", UVM_LOW)
  end
  else if($test$plusargs("QOS_RD_ORDER_LEGACY")) begin
    `uvm_info(get_type_name(), "+QOS_RD_ORDER_LEGACY: slave 0 keeps the default hold (first response only, 2 reads)", UVM_LOW)
  end
  else begin
    c.rd_qos_hold_scope   = QOS_HOLD_EACH;
    c.rd_qos_hold_min     = 4;
    c.rd_qos_hold_tmo_clk = 32;
  end
endfunction : setup_rd_qos

function void axi4_qos_rd_priority_order_test::fill_reads(axi4_virtual_qos_rd_tagged_seq v);
  v.rd_qos  = '{4'h1, 4'h3, 4'h7, 4'hF};
  v.rd_arid = '{1, 3, 7, 15};
endfunction : fill_reads

function void axi4_qos_rd_priority_order_test::check_phase(uvm_phase phase);
  int exp_rid[$] = '{15, 7, 3, 1};
  super.check_phase(phase);
  if(!rd_all_returned) return;   // already reported as QOS_RD_TIMEOUT
  if(obs_h.r_id != exp_rid)
    `uvm_error("QOS_RD_ORDER", $sformatf("R order by RID %p, expected %p (descending ARQOS); R ARQOS order %p",
                                         obs_h.r_id, exp_rid, obs_h.r_qos))
  else
    `uvm_info("QOS_RD_ORDER", $sformatf("R order by RID %p = descending ARQOS %p", obs_h.r_id, obs_h.r_qos), UVM_LOW)
endfunction : check_phase

`endif
