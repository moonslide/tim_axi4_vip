`ifndef AXI4_SATURATION_MIDBURST_RESET_QOS_BOUNDARY_TEST_INCLUDED_
`define AXI4_SATURATION_MIDBURST_RESET_QOS_BOUNDARY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_saturation_midburst_reset_qos_boundary_test
// Test combining saturation, mid-burst reset, QoS, and boundary testing
//--------------------------------------------------------------------------------------------
class axi4_saturation_midburst_reset_qos_boundary_test extends axi4_base_test;
  `uvm_component_utils(axi4_saturation_midburst_reset_qos_boundary_test)

  // Sequence handles
  axi4_master_all_to_all_saturation_seq saturation_seq[];
  axi4_master_qos_arbitration_seq qos_seq[];
  axi4_master_midburst_reset_read_seq midburst_reset_seq;
  axi4_slave_backpressure_storm_seq backpressure_seq[];
  axi4_master_4kb_boundary_seq boundary_seq;
  axi4_slave_sparse_error_injection_seq error_seq;
  axi4_master_reset_smoke_seq smoke_seq;

  extern function new(string name = "axi4_saturation_midburst_reset_qos_boundary_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_saturation_midburst_reset_qos_boundary_test

function axi4_saturation_midburst_reset_qos_boundary_test::new(string name = "axi4_saturation_midburst_reset_qos_boundary_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_saturation_midburst_reset_qos_boundary_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Starting saturation_midburst_reset_qos_boundary test", UVM_LOW)
  
  phase.raise_objection(this);
  
  saturation_seq = new[axi4_env_cfg_h.no_of_masters];
  qos_seq = new[axi4_env_cfg_h.no_of_masters];
  backpressure_seq = new[axi4_env_cfg_h.no_of_slaves];
  
  // Phase 1: Parallel saturation and QoS (120k cycles)
  `uvm_info(get_type_name(), "Phase 1: Starting parallel saturation and QoS", UVM_MEDIUM)
  fork
    begin
      for(int m = 0; m < axi4_env_cfg_h.no_of_masters; m++) begin
        automatic int master_id = m;
        fork
          begin
            saturation_seq[master_id] = axi4_master_all_to_all_saturation_seq::type_id::create($sformatf("saturation_seq_%0d", master_id));
            saturation_seq[master_id].start(axi4_env_h.axi4_master_agent_h[master_id].axi4_master_write_seqr_h);
          end
          begin
            qos_seq[master_id] = axi4_master_qos_arbitration_seq::type_id::create($sformatf("qos_seq_%0d", master_id));
            qos_seq[master_id].qos_value = master_id % 16;
            qos_seq[master_id].start(axi4_env_h.axi4_master_agent_h[master_id].axi4_master_write_seqr_h);
          end
        join_none
      end
    end
    begin
      #120us;  // 120k cycles at 1GHz
    end
  join_any
  
  // Hook: Inject mid-burst reset at 80k cycles
  fork
    begin
      #80us;
      `uvm_info(get_type_name(), "Injecting mid-burst reset", UVM_LOW)
      midburst_reset_seq = axi4_master_midburst_reset_read_seq::type_id::create("midburst_reset_seq");
      midburst_reset_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_read_seqr_h);
    end
  join_none
  
  disable fork;
  
  // Phase 2: Backpressure storm (100k cycles)
  `uvm_info(get_type_name(), "Phase 2: Starting backpressure storm", UVM_MEDIUM)
  fork
    for(int s = 0; s < axi4_env_cfg_h.no_of_slaves; s++) begin
      automatic int slave_id = s;
      fork
        begin
          backpressure_seq[slave_id] = axi4_slave_backpressure_storm_seq::type_id::create($sformatf("backpressure_seq_%0d", slave_id));
          backpressure_seq[slave_id].start(axi4_env_h.axi4_slave_agent_h[slave_id].axi4_slave_write_seqr_h);
        end
      join_none
    end
    begin
      #100us;
    end
  join_any
  disable fork;
  
  // Phase 3: 4KB boundary testing
  `uvm_info(get_type_name(), "Phase 3: Starting 4KB boundary testing", UVM_MEDIUM)
  boundary_seq = axi4_master_4kb_boundary_seq::type_id::create("boundary_seq");
  boundary_seq.num_transactions = 100;
  boundary_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  // Phase 4: Sparse error injection
  `uvm_info(get_type_name(), "Phase 4: Starting sparse error injection", UVM_MEDIUM)
  error_seq = axi4_slave_sparse_error_injection_seq::type_id::create("error_seq");
  error_seq.error_rate = 1;
  error_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
  
  // Phase 5: Reset smoke cleanup
  `uvm_info(get_type_name(), "Phase 5: Starting reset smoke cleanup", UVM_MEDIUM)
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  smoke_seq.num_txns = 5;
  smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  #10us;
  
  `uvm_info(get_type_name(), "Completed saturation_midburst_reset_qos_boundary test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif