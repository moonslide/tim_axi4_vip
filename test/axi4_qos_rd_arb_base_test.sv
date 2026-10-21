`ifndef AXI4_QOS_RD_ARB_BASE_TEST_INCLUDED_
`define AXI4_QOS_RD_ARB_BASE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_rd_arb_base_test
//  Common frame of the subordinate read-QoS arbitration tests
//  (axi4_qos_rd_hold_single_read_test, axi4_qos_rd_priority_order_test,
//  axi4_qos_rd_bypass_bound_test). Not registered in any list by itself.
//
//  Topology: +BUS_MATRIX_MODE=NONE (1:1 direct wiring), traffic master 0 ->
//  slave 0 only. Manager QoS off; subordinates ONLY_READ_QOS_MODE_ENABLE in
//  SLAVE_MEM_MODE, so slave 0's read-QoS arbiter answers every read. Master 0
//  may keep 8 reads outstanding, so all reads of a test reach slave 0 before
//  the first R burst is due.
//
//  A derived test supplies the reads (fill_reads) and slave 0's arbiter knobs
//  (setup_rd_qos), and judges the result in check_phase. This class waits for
//  every R burst to come back to master 0, bounded by rd_wait_bound: a read
//  that never returns ends the test as QOS_RD_TIMEOUT (UVM_ERROR) instead of a
//  hang.
//--------------------------------------------------------------------------------------------
class axi4_qos_rd_arb_base_test extends axi4_qos_basic_priority_test;
  `uvm_component_utils(axi4_qos_rd_arb_base_test)

  axi4_qos_ctrl_observer         obs_h;
  axi4_virtual_qos_rd_tagged_seq rd_vseq_h;

  // Variable: rd_wait_bound
  // How long run_phase waits for all R bursts after the last AR was issued.
  time rd_wait_bound = 2us;

  // Variable: rd_all_returned
  // 1 once every read issued by fill_reads() has come back to master 0.
  bit  rd_all_returned;

  extern function new(string name = "axi4_qos_rd_arb_base_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual function void setup_rd_qos(axi4_slave_agent_config c);
  extern virtual function void fill_reads(axi4_virtual_qos_rd_tagged_seq v);
  extern virtual task run_phase(uvm_phase phase);
  extern function axi4_slave_driver_proxy slave0_proxy();
endclass : axi4_qos_rd_arb_base_test

function axi4_qos_rd_arb_base_test::new(string name = "axi4_qos_rd_arb_base_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_qos_rd_arb_base_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(axi4_env_cfg_h.bus_matrix_mode != axi4_bus_matrix_ref::NONE)
    `uvm_fatal(get_type_name(), $sformatf("written for 1:1 wiring - run with +BUS_MATRIX_MODE=NONE (got %s)",
                                          axi4_env_cfg_h.bus_matrix_mode.name()))
  obs_h = axi4_qos_ctrl_observer::type_id::create("qos_obs_m0", this);
endfunction : build_phase

function void axi4_qos_rd_arb_base_test::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  obs_h.connect_to(axi4_env_h.axi4_master_agent_h[0].axi4_master_mon_proxy_h);
endfunction : connect_phase

function void axi4_qos_rd_arb_base_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type       = QOS_MODE_DISABLE;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 8;
  end
endfunction : setup_axi4_master_agent_cfg

function void axi4_qos_rd_arb_base_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i])
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = ONLY_READ_QOS_MODE_ENABLE;
  setup_rd_qos(axi4_env_cfg_h.axi4_slave_agent_cfg_h[0]);
endfunction : setup_axi4_slave_agent_cfg

// Function: setup_rd_qos
// Slave 0's read-QoS arbiter knobs. Default: leave every knob at its default.
function void axi4_qos_rd_arb_base_test::setup_rd_qos(axi4_slave_agent_config c);
endfunction : setup_rd_qos

// Function: fill_reads
// The reads master 0 issues, in issue order.
function void axi4_qos_rd_arb_base_test::fill_reads(axi4_virtual_qos_rd_tagged_seq v);
  v.rd_qos.push_back(4'h1);
  v.rd_arid.push_back(1);
endfunction : fill_reads

function axi4_slave_driver_proxy axi4_qos_rd_arb_base_test::slave0_proxy();
  return axi4_env_h.axi4_slave_agent_h[0].axi4_slave_drv_proxy_h;
endfunction : slave0_proxy

task axi4_qos_rd_arb_base_test::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  rd_vseq_h = axi4_virtual_qos_rd_tagged_seq::type_id::create("rd_vseq_h");
  fill_reads(rd_vseq_h);
  `uvm_info(get_type_name(), $sformatf("issuing %0d reads from master 0: arqos=%p arid=%p",
                                       rd_vseq_h.rd_qos.size(), rd_vseq_h.rd_qos, rd_vseq_h.rd_arid), UVM_LOW)
  rd_vseq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  // Isolating fork: the disable below must not reach the subordinate sequences
  // the virtual sequence left running.
  fork
    begin : wait_isolate
      fork
        begin : wait_all_r
          wait(obs_h.r_id.size() >= rd_vseq_h.rd_qos.size());
          rd_all_returned = 1;
        end
        begin : wait_bound
          #(rd_wait_bound);
        end
      join_any
      disable fork;
    end
  join
  if(!rd_all_returned)
    `uvm_error("QOS_RD_TIMEOUT", $sformatf("only %0d of %0d reads returned to master 0 within %0t (slave 0 read-QoS pool=%0d)",
                                           obs_h.r_id.size(), rd_vseq_h.rd_qos.size(), rd_wait_bound,
                                           slave0_proxy().qos_read_queue.size()))
  else
    `uvm_info(get_type_name(), $sformatf("all %0d reads returned; R order by RID: %p (ARQOS %p)",
                                         obs_h.r_id.size(), obs_h.r_id, obs_h.r_qos), UVM_LOW)
  #100ns;
  phase.drop_objection(this);
endtask : run_phase

`endif
