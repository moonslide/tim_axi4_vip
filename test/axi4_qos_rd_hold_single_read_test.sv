`ifndef AXI4_QOS_RD_HOLD_SINGLE_READ_TEST_INCLUDED_
`define AXI4_QOS_RD_HOLD_SINGLE_READ_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_rd_hold_single_read_test
//  The subordinate read-QoS hold must not deadlock when only ONE read ever
//  reaches the subordinate - the situation an interconnect that forwards one
//  read at a time creates. Knob under test: axi4_slave_agent_config::
//  rd_qos_hold_tmo_clk, and the global +AXI4_QOS_HOLD_TMO=<clk>.
//
//  Master 0 issues exactly one read. Slave 0 is in read-QoS mode with the
//  default hold (wait for 2 reads before the first response).
//    default run             : rd_qos_hold_tmo_clk = 64 -> the hold ends by
//                              timeout, the read returns; QOS_ARB_STATS
//                              hold_tmo=1. PASS.
//    +QOS_RD_HOLD_NO_TMO     : the test leaves rd_qos_hold_tmo_clk at 0 (the
//                              legacy unbounded hold). The read never returns:
//                              QOS_RD_TIMEOUT. This is the FAIL half, and the
//                              behaviour every slave had before the knob.
//    +QOS_RD_HOLD_NO_TMO +AXI4_QOS_HOLD_TMO=32
//                            : same test, bound supplied by the plusarg. PASS.
//  Add +AXI4_QOS_HOLD_WATCH=<clk> to any of them to see the QOS_HOLD_STALL
//  diagnostic on a hold that lasts that long.
//
//  Verdict (check_phase): the read came back, and slave 0 reports exactly one
//  read-QoS choice that was ended by the timeout.
//--------------------------------------------------------------------------------------------
class axi4_qos_rd_hold_single_read_test extends axi4_qos_rd_arb_base_test;
  `uvm_component_utils(axi4_qos_rd_hold_single_read_test)

  extern function new(string name = "axi4_qos_rd_hold_single_read_test", uvm_component parent = null);
  extern virtual function void setup_rd_qos(axi4_slave_agent_config c);
  extern virtual function void fill_reads(axi4_virtual_qos_rd_tagged_seq v);
  extern virtual function void check_phase(uvm_phase phase);
endclass : axi4_qos_rd_hold_single_read_test

function axi4_qos_rd_hold_single_read_test::new(string name = "axi4_qos_rd_hold_single_read_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_qos_rd_hold_single_read_test::setup_rd_qos(axi4_slave_agent_config c);
  if($test$plusargs("QOS_RD_HOLD_NO_TMO")) begin
    `uvm_info(get_type_name(), "+QOS_RD_HOLD_NO_TMO: slave 0 keeps rd_qos_hold_tmo_clk=0 (unbounded hold)", UVM_LOW)
  end
  else c.rd_qos_hold_tmo_clk = 64;
endfunction : setup_rd_qos

function void axi4_qos_rd_hold_single_read_test::fill_reads(axi4_virtual_qos_rd_tagged_seq v);
  v.rd_qos.push_back(4'h5);
  v.rd_arid.push_back(1);
endfunction : fill_reads

function void axi4_qos_rd_hold_single_read_test::check_phase(uvm_phase phase);
  axi4_slave_driver_proxy p = slave0_proxy();
  super.check_phase(phase);
  if(!rd_all_returned) return;   // already reported as QOS_RD_TIMEOUT
  if(p.qos_rd_picks != 1 || p.qos_rd_hold_tmo != 1)
    `uvm_error("QOS_RD_HOLD", $sformatf("expected 1 read-QoS choice ended by the hold timeout, slave 0 reports picks=%0d hold_tmo=%0d",
                                        p.qos_rd_picks, p.qos_rd_hold_tmo))
  else
    `uvm_info("QOS_RD_HOLD", $sformatf("single read returned after the hold timed out (bound %0d clk)", p.rd_qos_hold_tmo_eff), UVM_LOW)
endfunction : check_phase

`endif
