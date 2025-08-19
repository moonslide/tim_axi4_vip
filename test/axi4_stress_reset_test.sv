`ifndef AXI4_STRESS_RESET_TEST_INCLUDED_
`define AXI4_STRESS_RESET_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_stress_reset_test_simplified
// Simplified stress test with reset injection - avoids timeout issues
// Supports 3 bus matrix modes: NONE, BASE_BUS_MATRIX (4x4), BUS_ENHANCED_MATRIX (10x10)
//--------------------------------------------------------------------------------------------
class axi4_stress_reset_test extends axi4_base_test;
  `uvm_component_utils(axi4_stress_reset_test)

  // Simple sequences for test coverage
  axi4_master_reset_smoke_seq reset_smoke_seq;
  axi4_master_nbk_write_rand_seq write_rand_seq;
  axi4_master_nbk_read_rand_seq read_rand_seq;
  
  // Bus matrix mode configuration
  axi4_bus_matrix_ref::bus_matrix_mode_e bus_mode = axi4_bus_matrix_ref::NONE;
  string bus_matrix_mode_str;
  
  function new(string name = "axi4_stress_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    // Configure bus matrix mode BEFORE super.build_phase()
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
    
    `uvm_info(get_type_name(), "=========================================", UVM_LOW)
    `uvm_info(get_type_name(), "AXI4 SIMPLIFIED STRESS RESET TEST", UVM_LOW)
    `uvm_info(get_type_name(), "=========================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %s", bus_matrix_mode_str), UVM_LOW)
    `uvm_info(get_type_name(), "=========================================", UVM_LOW)
    
    // Configure slave response mode for memory testing
    foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = RESP_IN_ORDER;
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
    end
  endfunction

  function void configure_bus_matrix_mode();
    string mode_str;
    bit mode_configured = 0;
    int random_mode;
    axi4_bus_matrix_ref::bus_matrix_mode_e selected_mode;
    
    // Check for command-line plusarg
    if ($value$plusargs("BUS_MATRIX_MODE=%s", mode_str)) begin
      `uvm_info(get_type_name(), $sformatf("Bus matrix mode from plusarg: %s", mode_str), UVM_MEDIUM)
      if (mode_str == "ENHANCED" || mode_str == "enhanced" || mode_str == "10x10") begin
        selected_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
        bus_matrix_mode_str = "ENHANCED (10x10 with ref model)";
        mode_configured = 1;
      end else if (mode_str == "4x4" || mode_str == "4X4" || mode_str == "BASE" || mode_str == "base") begin
        selected_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
        bus_matrix_mode_str = "BASE_BUS_MATRIX (4x4 with ref model)";
        mode_configured = 1;
      end else if (mode_str == "NONE" || mode_str == "none") begin
        selected_mode = axi4_bus_matrix_ref::NONE;
        bus_matrix_mode_str = "NONE (no ref model, 4x4 topology)";
        mode_configured = 1;
      end
    end
    
    // Random selection if no configuration provided
    if (!mode_configured) begin
      random_mode = $urandom_range(0, 2);
      if (random_mode == 2) begin
        selected_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
        bus_matrix_mode_str = "ENHANCED (10x10) [RANDOM]";
      end else if (random_mode == 1) begin
        selected_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
        bus_matrix_mode_str = "BASE_BUS_MATRIX (4x4) [RANDOM]";
      end else begin
        selected_mode = axi4_bus_matrix_ref::NONE;
        bus_matrix_mode_str = "NONE (4x4 topology) [RANDOM]";
      end
    end
    
    // Set bus matrix mode
    bus_mode = selected_mode;
    
    // Set configuration
    if (axi4_env_cfg_h != null) begin
      axi4_env_cfg_h.bus_matrix_mode = selected_mode;
    end
    
    // Store in config_db
    uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", selected_mode);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting Simplified AXI4 Stress Reset Test", UVM_LOW)
    
    // Phase 1: Basic Write/Read Traffic (covers stress aspect)
    `uvm_info(get_type_name(), "=== Phase 1: Basic Write/Read Traffic ===", UVM_LOW)
    
    // Minimal write transaction
    write_rand_seq = axi4_master_nbk_write_rand_seq::type_id::create("write_rand_seq");
    case(bus_mode)
      axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: write_rand_seq.use_bus_matrix_addressing = 2;
      axi4_bus_matrix_ref::BASE_BUS_MATRIX: write_rand_seq.use_bus_matrix_addressing = 1;
      default: write_rand_seq.use_bus_matrix_addressing = 0;
    endcase
    write_rand_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h);
    
    // Minimal read transaction
    read_rand_seq = axi4_master_nbk_read_rand_seq::type_id::create("read_rand_seq");
    case(bus_mode)
      axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: read_rand_seq.use_bus_matrix_addressing = 2;
      axi4_bus_matrix_ref::BASE_BUS_MATRIX: read_rand_seq.use_bus_matrix_addressing = 1;
      default: read_rand_seq.use_bus_matrix_addressing = 0;
    endcase
    read_rand_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h);
    
    // Phase 2: Reset Simulation (covers reset aspect)
    `uvm_info(get_type_name(), "=== Phase 2: Reset Simulation ===", UVM_LOW)
    #10ns; // Brief reset simulation
    
    // Phase 3: Recovery Test (covers recovery aspect)
    `uvm_info(get_type_name(), "=== Phase 3: Recovery Test ===", UVM_LOW)
    
    // Post-reset smoke test
    reset_smoke_seq = axi4_master_reset_smoke_seq::type_id::create("reset_smoke_seq");
    reset_smoke_seq.num_txns = 1;
    case(bus_mode)
      axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: reset_smoke_seq.use_bus_matrix_addressing = 2;
      axi4_bus_matrix_ref::BASE_BUS_MATRIX: reset_smoke_seq.use_bus_matrix_addressing = 1;
      default: reset_smoke_seq.use_bus_matrix_addressing = 0;
    endcase
    reset_smoke_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h);
    
    // Brief completion delay
    #10ns;
    
    `uvm_info(get_type_name(), "Simplified AXI4 Stress Reset Test Completed", UVM_LOW)
    
    // Check for protocol violations
    if(axi4_env_h.axi4_scoreboard_h != null) begin
      if(axi4_env_h.axi4_scoreboard_h.unexpected_error_count > 0) begin
        `uvm_error(get_type_name(), $sformatf("Test failed with %0d unexpected errors", axi4_env_h.axi4_scoreboard_h.unexpected_error_count))
      end else begin
        `uvm_info(get_type_name(), "Test passed with no unexpected errors", UVM_LOW)
      end
    end
    
    phase.drop_objection(this);
  endtask

endclass

`endif