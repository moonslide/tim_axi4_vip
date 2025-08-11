`ifndef AXI4_WRITE_HEAVY_MIDBURST_RESET_RW_CONTENTION_TEST_INCLUDED_
`define AXI4_WRITE_HEAVY_MIDBURST_RESET_RW_CONTENTION_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_write_heavy_midburst_reset_rw_contention_test
// Write-heavy test with mid-burst reset and read-write contention
//--------------------------------------------------------------------------------------------
class axi4_write_heavy_midburst_reset_rw_contention_test extends axi4_base_test;
  `uvm_component_utils(axi4_write_heavy_midburst_reset_rw_contention_test)

  // Sequence handles
  axi4_master_mixed_burst_lengths_seq mixed_burst_seq;
  axi4_slave_write_response_throttling_seq throttle_seq;
  axi4_master_all_to_all_saturation_seq saturation_seq[];
  axi4_master_midburst_reset_write_seq midburst_reset_seq;
  axi4_master_read_write_contention_seq contention_seq;
  axi4_master_reset_smoke_seq smoke_seq;

  extern function new(string name = "axi4_write_heavy_midburst_reset_rw_contention_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_write_heavy_midburst_reset_rw_contention_test

function axi4_write_heavy_midburst_reset_rw_contention_test::new(string name = "axi4_write_heavy_midburst_reset_rw_contention_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_write_heavy_midburst_reset_rw_contention_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Starting write_heavy_midburst_reset_rw_contention test", UVM_LOW)
  
  phase.raise_objection(this);
  
  saturation_seq = new[axi4_env_cfg_h.no_of_masters];
  
  // Step 1: Mixed burst lengths
  `uvm_info(get_type_name(), "Step 1: Mixed burst lengths", UVM_MEDIUM)
  mixed_burst_seq = axi4_master_mixed_burst_lengths_seq::type_id::create("mixed_burst_seq");
  mixed_burst_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  // Step 2: Write response throttling
  `uvm_info(get_type_name(), "Step 2: Write response throttling", UVM_MEDIUM)
  throttle_seq = axi4_slave_write_response_throttling_seq::type_id::create("throttle_seq");
  throttle_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
  
  // Step 3: Parallel saturation and mid-burst reset write
  `uvm_info(get_type_name(), "Step 3: Parallel saturation and mid-burst reset", UVM_MEDIUM)
  fork
    begin
      for(int m = 0; m < axi4_env_cfg_h.no_of_masters; m++) begin
        automatic int master_id = m;
        fork
          begin
            saturation_seq[master_id] = axi4_master_all_to_all_saturation_seq::type_id::create($sformatf("saturation_seq_%0d", master_id));
            saturation_seq[master_id].start(axi4_env_h.axi4_master_agent_h[master_id].axi4_master_write_seqr_h);
          end
        join_none
      end
    end
    begin
      #10us;
      midburst_reset_seq = axi4_master_midburst_reset_write_seq::type_id::create("midburst_reset_seq");
      midburst_reset_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
    end
  join
  
  // Step 4: Read-write contention
  `uvm_info(get_type_name(), "Step 4: Read-write contention", UVM_MEDIUM)
  contention_seq = axi4_master_read_write_contention_seq::type_id::create("contention_seq");
  contention_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  // Step 5: Reset smoke
  `uvm_info(get_type_name(), "Step 5: Reset smoke", UVM_MEDIUM)
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  #10us;
  
  `uvm_info(get_type_name(), "Completed write_heavy_midburst_reset_rw_contention test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif