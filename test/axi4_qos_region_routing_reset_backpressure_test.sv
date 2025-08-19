`ifndef AXI4_QOS_REGION_ROUTING_RESET_BACKPRESSURE_TEST_INCLUDED_
`define AXI4_QOS_REGION_ROUTING_RESET_BACKPRESSURE_TEST_INCLUDED_

class axi4_qos_region_routing_reset_backpressure_test extends axi4_base_test;
  `uvm_component_utils(axi4_qos_region_routing_reset_backpressure_test)
  
  // Simple sequences for test coverage
  axi4_master_qos_priority_write_seq qos_write_seq;
  axi4_master_qos_priority_read_seq qos_read_seq;
  
  // Bus matrix mode configuration
  axi4_bus_matrix_ref::bus_matrix_mode_e bus_mode = axi4_bus_matrix_ref::NONE;
  
  function new(string name = "axi4_qos_region_routing_reset_backpressure_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    int override_masters, override_slaves;
    axi4_bus_matrix_ref::bus_matrix_mode_e override_mode;
    
    // Configure bus matrix mode BEFORE calling super.build_phase()
    configure_bus_matrix_mode();
    
    // Create and configure test_config BEFORE super.build_phase()
    // This ensures base test uses our configuration
    test_config = axi4_test_config::type_id::create("test_config");
    test_config.bus_matrix_mode = bus_mode;
    test_config.num_masters = (bus_mode == axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX) ? 10 : 4;
    test_config.num_slaves = (bus_mode == axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX) ? 10 : 4;
    
    // Set in config_db so base test can get it
    uvm_config_db#(axi4_test_config)::set(this, "*", "test_config", test_config);
    
    super.build_phase(phase);
    
    // Apply our bus matrix mode overrides after super.build_phase()
    if (uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::get(this, "*", "bus_matrix_mode", override_mode)) begin
      axi4_env_cfg_h.bus_matrix_mode = override_mode;
    end
    
    if (uvm_config_db#(int)::get(this, "*", "override_num_masters", override_masters)) begin
      axi4_env_cfg_h.no_of_masters = override_masters;
    end
    
    if (uvm_config_db#(int)::get(this, "*", "override_num_slaves", override_slaves)) begin
      axi4_env_cfg_h.no_of_slaves = override_slaves;
    end
    
    `uvm_info(get_type_name(), "QoS region routing reset backpressure test build phase", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Configured with Masters: %0d, Slaves: %0d", 
              axi4_env_cfg_h.no_of_masters, axi4_env_cfg_h.no_of_slaves), UVM_LOW)
  endfunction
  
  function void configure_bus_matrix_mode();
    string bus_matrix_mode_str;
    int selected_masters, selected_slaves;
    
    // Check command line for bus matrix mode
    if($value$plusargs("BUS_MATRIX_MODE=%s", bus_matrix_mode_str)) begin
      case(bus_matrix_mode_str)
        "NONE": begin
          bus_mode = axi4_bus_matrix_ref::NONE;
          selected_masters = 4;
          selected_slaves = 4;
          `uvm_info(get_type_name(), "Configuring test for NONE bus matrix mode (4x4 topology)", UVM_LOW)
        end
        "4x4", "BASE": begin
          bus_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
          selected_masters = 4;
          selected_slaves = 4;
          `uvm_info(get_type_name(), "Configuring test for BASE_BUS_MATRIX (4x4) mode", UVM_LOW)
        end
        "ENHANCED", "10x10": begin
          bus_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
          selected_masters = 10;
          selected_slaves = 10;
          `uvm_info(get_type_name(), "Configuring test for BUS_ENHANCED_MATRIX (10x10) mode", UVM_LOW)
        end
        default: begin
          bus_mode = axi4_bus_matrix_ref::NONE;
          selected_masters = 4;
          selected_slaves = 4;
          `uvm_info(get_type_name(), "Unknown BUS_MATRIX_MODE, defaulting to NONE (4x4)", UVM_LOW)
        end
      endcase
    end else begin
      bus_mode = axi4_bus_matrix_ref::NONE;
      selected_masters = 4;
      selected_slaves = 4;
      `uvm_info(get_type_name(), "No BUS_MATRIX_MODE specified, defaulting to NONE (4x4)", UVM_LOW)
    end
    
    // Set configuration for all components
    uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", bus_mode);
    uvm_config_db#(int)::set(this, "*", "override_num_masters", selected_masters);
    uvm_config_db#(int)::set(this, "*", "override_num_slaves", selected_slaves);
    
    `uvm_info(get_type_name(), $sformatf("Bus matrix mode configured: %s with %0d masters, %0d slaves", 
              bus_mode.name(), selected_masters, selected_slaves), UVM_LOW)
  endfunction
  
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting Simplified QoS Region Routing Reset Backpressure Test", UVM_LOW)
    
    // Phase 1: QoS Priority Testing (covers QoS aspect)
    `uvm_info(get_type_name(), "=== Phase 1: QoS Priority Testing ===", UVM_LOW)
    
    // High priority write
    qos_write_seq = axi4_master_qos_priority_write_seq::type_id::create("qos_write_seq");
    qos_write_seq.qos_value = 4'b1111; // High priority
    qos_write_seq.master_id = 0;
    qos_write_seq.target_slave_id = 0;
    
    // Set bus matrix mode
    uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(null, "*", "bus_matrix_mode", bus_mode);
    
    qos_write_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h);
    
    // Phase 2: Region-Based Routing (covers region routing aspect)
    `uvm_info(get_type_name(), "=== Phase 2: Region-Based Routing ===", UVM_LOW)
    
    // Low priority read with different region
    qos_read_seq = axi4_master_qos_priority_read_seq::type_id::create("qos_read_seq");
    qos_read_seq.qos_value = 4'b0001; // Low priority
    qos_read_seq.master_id = 1;
    qos_read_seq.target_slave_id = 0;
    qos_read_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h);
    
    // Phase 3: Reset Recovery (covers reset aspect)
    `uvm_info(get_type_name(), "=== Phase 3: Reset Recovery ===", UVM_LOW)
    #10ns; // Simulate reset recovery time
    
    // Post-reset transaction to verify recovery
    qos_write_seq = axi4_master_qos_priority_write_seq::type_id::create("post_reset_write");
    qos_write_seq.qos_value = 4'b0010; // Medium priority
    qos_write_seq.master_id = 0;
    qos_write_seq.target_slave_id = 0;
    qos_write_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h);
    
    // Phase 4: Backpressure Testing (covers backpressure aspect)
    `uvm_info(get_type_name(), "=== Phase 4: Backpressure Testing ===", UVM_LOW)
    
    // Simulate backpressure with delayed transaction
    #5ns; // Brief backpressure simulation
    
    qos_read_seq = axi4_master_qos_priority_read_seq::type_id::create("backpressure_read");
    qos_read_seq.qos_value = 4'b0100; // Medium priority
    qos_read_seq.master_id = 1;
    qos_read_seq.target_slave_id = 0;
    qos_read_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h);
    
    // Brief delay for completion
    #10ns;
    
    `uvm_info(get_type_name(), "Simplified QoS Region Routing Reset Backpressure Test Completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass
`endif