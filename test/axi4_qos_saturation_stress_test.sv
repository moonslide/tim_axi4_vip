`ifndef AXI4_QOS_SATURATION_STRESS_TEST_INCLUDED_
`define AXI4_QOS_SATURATION_STRESS_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_saturation_stress_test
// Stress tests the QoS arbitration system under heavy load with multiple priority levels
// Verifies that high priority transactions still complete under saturation conditions
// Supports all three bus matrix modes: NONE, BASE_BUS_MATRIX (4x4), BUS_ENHANCED_MATRIX (10x10)
//--------------------------------------------------------------------------------------------
class axi4_qos_saturation_stress_test extends axi4_base_test;
  `uvm_component_utils(axi4_qos_saturation_stress_test)

  // Variable: axi4_virtual_qos_saturation_stress_seq_h
  // Handle to the QoS saturation stress virtual sequence
  axi4_virtual_qos_saturation_stress_seq axi4_virtual_qos_saturation_stress_seq_h;
  
  // Configuration parameters
  int num_masters;
  int num_slaves;
  bit is_enhanced_mode;
  bit is_4x4_ref_mode;
  string bus_matrix_mode_str;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_qos_saturation_stress_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_bus_matrix_mode();
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_qos_saturation_stress_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_qos_saturation_stress_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_qos_saturation_stress_test::new(string name = "axi4_qos_saturation_stress_test",
                                              uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Build phase to configure bus matrix mode and QoS settings
//--------------------------------------------------------------------------------------------
function void axi4_qos_saturation_stress_test::build_phase(uvm_phase phase);
  int override_masters, override_slaves;
  axi4_bus_matrix_ref::bus_matrix_mode_e override_mode;
  
  // Configure bus matrix mode BEFORE calling super.build_phase()
  configure_bus_matrix_mode();
  
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
  
  // Set number of masters and slaves based on configuration
  num_masters = axi4_env_cfg_h.no_of_masters;
  num_slaves = axi4_env_cfg_h.no_of_slaves;
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), "AXI4 QOS SATURATION STRESS TEST", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "Test validates QoS under saturation conditions", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: configure_bus_matrix_mode
// Configure bus matrix mode supporting NONE, BASE_BUS_MATRIX (4x4), and BUS_ENHANCED_MATRIX (10x10)
//--------------------------------------------------------------------------------------------
function void axi4_qos_saturation_stress_test::configure_bus_matrix_mode();
  string mode_str;
  bit mode_configured = 0;
  int random_mode;
  axi4_bus_matrix_ref::bus_matrix_mode_e selected_mode;
  int selected_masters, selected_slaves;
  
  // Check for command-line plusarg
  if ($value$plusargs("BUS_MATRIX_MODE=%s", mode_str)) begin
    `uvm_info(get_type_name(), $sformatf("Bus matrix mode from plusarg: %s", mode_str), UVM_MEDIUM)
    if (mode_str == "ENHANCED" || mode_str == "enhanced" || mode_str == "10x10") begin
      selected_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
      selected_masters = 10;
      selected_slaves = 10;
      is_enhanced_mode = 1;
      is_4x4_ref_mode = 0;
      bus_matrix_mode_str = "BUS_ENHANCED_MATRIX (10x10 with ref model)";
      mode_configured = 1;
    end else if (mode_str == "4x4" || mode_str == "4X4" || mode_str == "BASE" || mode_str == "base") begin
      selected_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
      selected_masters = 4;
      selected_slaves = 4;
      is_enhanced_mode = 0;
      is_4x4_ref_mode = 1;
      bus_matrix_mode_str = "BASE_BUS_MATRIX (4x4 with ref model)";
      mode_configured = 1;
    end else if (mode_str == "NONE" || mode_str == "none") begin
      selected_mode = axi4_bus_matrix_ref::NONE;
      selected_masters = 4;
      selected_slaves = 4;
      is_enhanced_mode = 0;
      is_4x4_ref_mode = 0;
      bus_matrix_mode_str = "NONE (no ref model, 4x4 topology)";
      mode_configured = 1;
    end
  end
  
  // Random selection if no configuration provided
  if (!mode_configured) begin
    random_mode = $urandom_range(0, 2);
    if (random_mode == 2) begin
      selected_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
      selected_masters = 10;
      selected_slaves = 10;
      is_enhanced_mode = 1;
      is_4x4_ref_mode = 0;
      bus_matrix_mode_str = "BUS_ENHANCED_MATRIX (10x10) [RANDOM]";
    end else if (random_mode == 1) begin
      selected_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
      selected_masters = 4;
      selected_slaves = 4;
      is_enhanced_mode = 0;
      is_4x4_ref_mode = 1;
      bus_matrix_mode_str = "BASE_BUS_MATRIX (4x4) [RANDOM]";
    end else begin
      selected_mode = axi4_bus_matrix_ref::NONE;
      selected_masters = 4;
      selected_slaves = 4;
      is_enhanced_mode = 0;
      is_4x4_ref_mode = 0;
      bus_matrix_mode_str = "NONE (4x4 topology) [RANDOM]";
    end
  end
  
  // Create test_config if it doesn't exist
  if (test_config == null) begin
    test_config = axi4_test_config::type_id::create("test_config");
  end
  
  // Set configuration
  test_config.bus_matrix_mode = selected_mode;
  test_config.num_masters = selected_masters;
  test_config.num_slaves = selected_slaves;
  
  // Store in config_db
  uvm_config_db#(axi4_test_config)::set(null, "*", "test_config", test_config);
  uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", selected_mode);
  uvm_config_db#(int)::set(this, "*", "override_num_masters", selected_masters);
  uvm_config_db#(int)::set(this, "*", "override_num_slaves", selected_slaves);
  
endfunction : configure_bus_matrix_mode

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration with QoS enabled
//--------------------------------------------------------------------------------------------
function void axi4_qos_saturation_stress_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify testing
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Increase outstanding transactions for stress testing
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 8;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 8;
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration with QoS enabled
//--------------------------------------------------------------------------------------------
function void axi4_qos_saturation_stress_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify testing  
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the QoS saturation stress virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_qos_saturation_stress_test::run_phase(uvm_phase phase);
  
  axi4_virtual_qos_saturation_stress_seq_h = axi4_virtual_qos_saturation_stress_seq::type_id::create("axi4_virtual_qos_saturation_stress_seq_h");
  
  // Pass bus matrix configuration to virtual sequence
  axi4_virtual_qos_saturation_stress_seq_h.num_masters = num_masters;
  axi4_virtual_qos_saturation_stress_seq_h.num_slaves = num_slaves;
  if (is_enhanced_mode) begin
    axi4_virtual_qos_saturation_stress_seq_h.use_bus_matrix_addressing = 2; // ENHANCED mode
  end else if (is_4x4_ref_mode) begin
    axi4_virtual_qos_saturation_stress_seq_h.use_bus_matrix_addressing = 1; // BASE mode
  end else begin
    axi4_virtual_qos_saturation_stress_seq_h.use_bus_matrix_addressing = 0; // NONE mode
  end
  
  `uvm_info(get_type_name(), "Starting QoS Saturation Stress Test", UVM_LOW)
  
  phase.raise_objection(this);
  axi4_virtual_qos_saturation_stress_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
  
endtask : run_phase

`endif