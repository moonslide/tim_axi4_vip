`ifndef AXI4_QOS_REGION_ROUTING_RESET_BACKPRESSURE_TEST_INCLUDED_
`define AXI4_QOS_REGION_ROUTING_RESET_BACKPRESSURE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_region_routing_reset_backpressure_test
// Test focusing on QoS, region routing, reset, and backpressure
//--------------------------------------------------------------------------------------------
class axi4_qos_region_routing_reset_backpressure_test extends axi4_base_test;
  `uvm_component_utils(axi4_qos_region_routing_reset_backpressure_test)

  // Sequence handles
  axi4_master_region_routing_seq region_seq;
  axi4_master_qos_arbitration_seq qos_seq[];
  axi4_master_all_to_all_saturation_seq saturation_seq[];
  axi4_master_midburst_reset_read_seq midburst_reset_seq;
  axi4_slave_backpressure_storm_seq backpressure_seq;
  axi4_master_reset_smoke_seq smoke_seq;

  extern function new(string name = "axi4_qos_region_routing_reset_backpressure_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_qos_region_routing_reset_backpressure_test

function axi4_qos_region_routing_reset_backpressure_test::new(string name = "axi4_qos_region_routing_reset_backpressure_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

task axi4_qos_region_routing_reset_backpressure_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "Starting qos_region_routing_reset_backpressure test", UVM_LOW)
  
  phase.raise_objection(this);
  
  qos_seq = new[axi4_env_cfg_h.no_of_masters];
  saturation_seq = new[axi4_env_cfg_h.no_of_masters];
  
  // Step 1: Region routing
  `uvm_info(get_type_name(), "Step 1: Region routing", UVM_MEDIUM)
  region_seq = axi4_master_region_routing_seq::type_id::create("region_seq");
  region_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  // Step 2: Parallel QoS arbitration and saturation
  `uvm_info(get_type_name(), "Step 2: Parallel QoS and saturation", UVM_MEDIUM)
  fork
    begin
      for(int m = 0; m < axi4_env_cfg_h.no_of_masters; m++) begin
        automatic int master_id = m;
        fork
          begin
            qos_seq[master_id] = axi4_master_qos_arbitration_seq::type_id::create($sformatf("qos_seq_%0d", master_id));
            qos_seq[master_id].qos_value = (master_id * 4) % 16;
            qos_seq[master_id].start(axi4_env_h.axi4_master_agent_h[master_id].axi4_master_write_seqr_h);
          end
          begin
            saturation_seq[master_id] = axi4_master_all_to_all_saturation_seq::type_id::create($sformatf("saturation_seq_%0d", master_id));
            saturation_seq[master_id].start(axi4_env_h.axi4_master_agent_h[master_id].axi4_master_read_seqr_h);
          end
        join_none
      end
      #50us;
    end
  join_any
  disable fork;
  
  // Step 3: Mid-burst reset read
  `uvm_info(get_type_name(), "Step 3: Mid-burst reset read", UVM_MEDIUM)
  midburst_reset_seq = axi4_master_midburst_reset_read_seq::type_id::create("midburst_reset_seq");
  midburst_reset_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_read_seqr_h);
  
  // Step 4: Backpressure storm
  `uvm_info(get_type_name(), "Step 4: Backpressure storm", UVM_MEDIUM)
  backpressure_seq = axi4_slave_backpressure_storm_seq::type_id::create("backpressure_seq");
  backpressure_seq.start(axi4_env_h.axi4_slave_agent_h[0].axi4_slave_write_seqr_h);
  
  // Step 5: Reset smoke
  `uvm_info(get_type_name(), "Step 5: Reset smoke", UVM_MEDIUM)
  smoke_seq = axi4_master_reset_smoke_seq::type_id::create("smoke_seq");
  smoke_seq.start(axi4_env_h.axi4_master_agent_h[0].axi4_master_write_seqr_h);
  
  #10us;
  
  `uvm_info(get_type_name(), "Completed qos_region_routing_reset_backpressure test", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif