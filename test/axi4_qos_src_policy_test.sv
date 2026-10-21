`ifndef AXI4_QOS_SRC_POLICY_TEST_INCLUDED_
`define AXI4_QOS_SRC_POLICY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_src_policy_test
//  Proves the manager agent's AxQOS value policy (axi4_master_agent_config::
//  awqos_src / arqos_src, axqos_src_e): every policy, on both channels, checked
//  against what each manager's own monitor saw on the wire.
//
//  Traffic: the equal-priority-fairness virtual sequence (4 managers, writes and
//  reads, every sequence item asking for AxQOS = 4). Run with
//  +BUS_MATRIX_MODE=4x4 (4 managers). Manager and subordinate QoS arbitration
//  are switched off here (the subordinate's write-QoS path drains a queue only
//  the manager's write-QoS path fills), so the only thing that can change AxQOS
//  is the policy.
//
//    manager | AW policy           | AR policy
//    m0      | CONST 0xC           | ZERO
//    m1      | SPAN  0x2..0x5      | CONST 0x7
//    m2      | ZERO                | SPAN  0x9..0xB
//    m3      | SEQ (expects 0x4)   | SEQ (expects 0x4)
//
//  Verdict (check_phase): per manager and channel, at least one handshake was
//  seen and every value obeys the policy; a SPAN channel with 3+ handshakes
//  must also show 2+ distinct values. The scoreboard's ARQOS compare
//  (axqos_passthrough_chk_cfg) independently confirms the subordinates saw the
//  same ARQOS. (AWQOS is compared only with awqos_chk_cfg / +AXI4_AWQOS_CHK:
//  the slave monitor does not sample AWQOS yet.)
//
//  Negative check: +QOS_SRC_POLICY_NEG makes the test expect 0xD instead of 0xC
//  on m0 AW - the run must then fail with QOS_SRC_POLICY errors.
//--------------------------------------------------------------------------------------------
class axi4_qos_src_policy_test extends axi4_qos_equal_priority_fairness_test;
  `uvm_component_utils(axi4_qos_src_policy_test)

  axi4_qos_ctrl_observer obs_h[4];

  extern function new(string name = "axi4_qos_src_policy_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual function void check_phase(uvm_phase phase);
  extern virtual function void check_channel(int m, string ch, axqos_src_e src, bit [3:0] cval,
                                             bit [3:0] lo, bit [3:0] hi, bit [3:0] q[$]);
endclass : axi4_qos_src_policy_test

function axi4_qos_src_policy_test::new(string name = "axi4_qos_src_policy_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_qos_src_policy_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(axi4_env_cfg_h.no_of_masters < 4)
    `uvm_fatal(get_type_name(), $sformatf("needs 4 managers (run with +BUS_MATRIX_MODE=4x4), have %0d", axi4_env_cfg_h.no_of_masters))
  foreach(obs_h[i]) obs_h[i] = axi4_qos_ctrl_observer::type_id::create($sformatf("qos_obs_m%0d", i), this);
endfunction : build_phase

function void axi4_qos_src_policy_test::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  foreach(obs_h[i]) obs_h[i].connect_to(axi4_env_h.axi4_master_agent_h[i].axi4_master_mon_proxy_h);
endfunction : connect_phase

function void axi4_qos_src_policy_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i])
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
  if(axi4_env_cfg_h.axi4_master_agent_cfg_h.size() < 4) return;   // build_phase reports it
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].awqos_src     = AXQOS_SRC_CONST;
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].awqos_const   = 4'hC;
  axi4_env_cfg_h.axi4_master_agent_cfg_h[0].arqos_src     = AXQOS_SRC_ZERO;
  axi4_env_cfg_h.axi4_master_agent_cfg_h[1].awqos_src     = AXQOS_SRC_SPAN;
  axi4_env_cfg_h.axi4_master_agent_cfg_h[1].awqos_span_lo = 4'h2;
  axi4_env_cfg_h.axi4_master_agent_cfg_h[1].awqos_span_hi = 4'h5;
  axi4_env_cfg_h.axi4_master_agent_cfg_h[1].arqos_src     = AXQOS_SRC_CONST;
  axi4_env_cfg_h.axi4_master_agent_cfg_h[1].arqos_const   = 4'h7;
  axi4_env_cfg_h.axi4_master_agent_cfg_h[2].awqos_src     = AXQOS_SRC_ZERO;
  axi4_env_cfg_h.axi4_master_agent_cfg_h[2].arqos_src     = AXQOS_SRC_SPAN;
  axi4_env_cfg_h.axi4_master_agent_cfg_h[2].arqos_span_lo = 4'h9;
  axi4_env_cfg_h.axi4_master_agent_cfg_h[2].arqos_span_hi = 4'hB;
  // m3 stays AXQOS_SRC_SEQ on both channels: the control case.
endfunction : setup_axi4_master_agent_cfg

function void axi4_qos_src_policy_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i])
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
endfunction : setup_axi4_slave_agent_cfg

function void axi4_qos_src_policy_test::check_channel(int m, string ch, axqos_src_e src, bit [3:0] cval,
                                                      bit [3:0] lo, bit [3:0] hi, bit [3:0] q[$]);
  int bad;
  if(q.size() == 0) begin
    `uvm_error("QOS_SRC_POLICY", $sformatf("m%0d %s: no handshake observed - nothing was checked", m, ch))
    return;
  end
  foreach(q[i]) begin
    case(src)
      AXQOS_SRC_CONST : if(q[i] != cval) bad++;
      AXQOS_SRC_ZERO  : if(q[i] != 4'h0) bad++;
      AXQOS_SRC_SPAN  : if(q[i] < lo || q[i] > hi) bad++;
      default         : if(q[i] != 4'h4) bad++;   // what every sequence item of this traffic asks for
    endcase
  end
  if(bad > 0)
    `uvm_error("QOS_SRC_POLICY", $sformatf("m%0d %s %s (const=%0h span=%0h..%0h): %0d of %0d handshakes broke the policy, observed %p",
                                           m, ch, src.name(), cval, lo, hi, bad, q.size(), q))
  else if(src == AXQOS_SRC_SPAN && q.size() >= 3 && axi4_qos_ctrl_observer::distinct(q) < 2)
    `uvm_error("QOS_SRC_POLICY", $sformatf("m%0d %s SPAN %0h..%0h: %0d handshakes all carried one value %p - not spread",
                                           m, ch, lo, hi, q.size(), q))
  else
    `uvm_info("QOS_SRC_POLICY", $sformatf("m%0d %s %s: %0d handshakes, %0d distinct value(s), all obey the policy %p",
                                          m, ch, src.name(), q.size(), axi4_qos_ctrl_observer::distinct(q), q), UVM_LOW)
endfunction : check_channel

function void axi4_qos_src_policy_test::check_phase(uvm_phase phase);
  super.check_phase(phase);
  foreach(obs_h[m]) begin
    axi4_master_agent_config c = axi4_env_cfg_h.axi4_master_agent_cfg_h[m];
    bit [3:0] aw_const = c.awqos_const;
    if(m == 0 && $test$plusargs("QOS_SRC_POLICY_NEG")) begin
      aw_const = c.awqos_const + 1;
      `uvm_info("QOS_SRC_POLICY", "+QOS_SRC_POLICY_NEG: expecting m0 AW one above its configured constant - this run must FAIL", UVM_LOW)
    end
    check_channel(m, "AW", c.awqos_src, aw_const,      c.awqos_span_lo, c.awqos_span_hi, obs_h[m].aw_qos);
    check_channel(m, "AR", c.arqos_src, c.arqos_const, c.arqos_span_lo, c.arqos_span_hi, obs_h[m].ar_qos);
  end
endfunction : check_phase

`endif
