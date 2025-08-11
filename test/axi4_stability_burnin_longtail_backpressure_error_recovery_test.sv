`ifndef AXI4_STABILITY_BURNIN_LONGTAIL_BACKPRESSURE_ERROR_RECOVERY_TEST_INCLUDED_
`define AXI4_STABILITY_BURNIN_LONGTAIL_BACKPRESSURE_ERROR_RECOVERY_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_stability_burnin_longtail_backpressure_error_recovery_test
// Long-running stability test with error recovery
//--------------------------------------------------------------------------------------------
class axi4_stability_burnin_longtail_backpressure_error_recovery_test extends axi4_base_test;
  `uvm_component_utils(axi4_stability_burnin_longtail_backpressure_error_recovery_test)

  // Sequence handles
  axi4_master_all_to_all_saturation_seq saturation_seq[];
  axi4_master_one_to_many_fanout_seq fanout_seq[];
  axi4_slave_backpressure_storm_seq backpressure_seq[];
  axi4_slave_long_tail_latency_seq longtail_seq;
  axi4_slave_sparse_error_injection_seq error_seq;
  axi4_master_reset_smoke_seq smoke_seq;

  extern function new(string name = "axi4_stability_burnin_longtail_backpressure_error_recovery_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_stability_burnin_longtail_backpressure_error_recovery_test

function axi4_stability_burnin_longtail_backpressure_error_recovery_test::new(string name = "axi4_stability_burnin_longtail_backpressure_error_recovery_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_stability_burnin_longtail_backpressure_error_recovery_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Starting stability_burnin_longtail_backpressure_error_recovery test", UVM_LOW)
  
  phase.raise_objection(this);
  
  saturation_seq = new[axi4_env_cfg_h.no_of_masters];
  fanout_seq = new[axi4_env_cfg_h.no_of_masters];
  backpressure_seq = new[axi4_env_cfg_h.no_of_slaves];
  
  // Step 1: Parallel saturation, fanout, and backpressure (long burn-in)
  `uvm_info(get_type_name(), "Step 1: Parallel saturation, fanout, and backpressure", UVM_MEDIUM)
  fork
    begin
      for(int m = 0; m < axi4_env_cfg_h.no_of_masters; m++) begin
        automatic int master_id = m;
        fork
          begin
            saturation_seq[master_id] = axi4_master_all_to_all_saturation_seq::type_id::create($sformatf("saturation_seq_%0d", master_id));
            saturation_seq[master_id].num_transactions = 200;
            saturation_seq[master_id].start(axi4_env_h.axi4_master_agent_h[master_id].axi4_master_write_seqr_h);
          end
          begin
            fanout_seq[master_id] = axi4_master_one_to_many_fanout_seq::type_id::create($sformatf("fanout_seq_%0d", master_id));
            fanout_seq[master_id].start(axi4_env_h.axi4_master_agent_h[master_id].axi4_master_read_seqr_h);
          end
        join_none
      end
    end
    begin
      for(int s = 0; s < axi4_env_cfg_h.no_of_slaves; s++) begin
        automatic int slave_id = s;
        fork
          begin
            backpressure_seq[slave_id] = axi4_slave_backpressure_storm_seq::type_id::create($sformatf("backpressure_seq_%0d", slave_id));
            backpressure_seq[slave_id].start(axi4_env_h.axi4_slave_agent_h[slave_id].axi4_slave_write_seqr_h);
          end
        join_none
      end
    end
    begin
      #200us;  // Long burn-in period
    end
  join_any
  disable fork;
  
  // Step 2: Long tail latency
  `uvm_info(get_type_name(), "Step 2: Long tail latency", UVM_MEDIUM)
  longtail_seq = axi4_slave_long_tail_latency_seq::type_id::create("longtail_seq");
  longtail_seq.long_delay = 75000;
  longtail_seq.start(axi4_env_h.axi4_slave_agent_h[8].axi4_slave_write_seqr_h);
  
  // Step 3: Sparse error injection
  `uvm_info(get_type_name(), "Step 3: Sparse error injection", UVM_MEDIUM)
  error_seq = axi4_slave_sparse_error_injection_seq::type_id::create("error_seq");
  error_seq.error_rate = 1;
  error_seq.num_transactions = 200;
  error_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
  
  // Step 4: Reset smoke (error recovery)
  `uvm_info(get_type_name(), "Step 4: Reset smoke - error recovery", UVM_MEDIUM)
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  smoke_seq.num_txns = 10;
  smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  #20us;
  
  `uvm_info(get_type_name(), "Completed stability_burnin_longtail_backpressure_error_recovery test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif