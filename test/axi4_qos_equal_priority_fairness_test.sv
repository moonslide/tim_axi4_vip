`ifndef AXI4_QOS_EQUAL_PRIORITY_FAIRNESS_TEST_INCLUDED_
`define AXI4_QOS_EQUAL_PRIORITY_FAIRNESS_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_qos_equal_priority_fairness_test
// Tests fairness when multiple transactions have equal QoS priority values
// Verifies that equal priority transactions are serviced fairly without starvation
// Supports all three bus matrix modes: NONE, BASE_BUS_MATRIX (4x4), BUS_ENHANCED_MATRIX (10x10)
//--------------------------------------------------------------------------------------------
class axi4_qos_equal_priority_fairness_test extends axi4_base_test;
  `uvm_component_utils(axi4_qos_equal_priority_fairness_test)

  // Variable: axi4_virtual_qos_equal_priority_fairness_seq_h
  // Handle to the QoS equal priority fairness virtual sequence
  axi4_virtual_qos_equal_priority_fairness_seq axi4_virtual_qos_equal_priority_fairness_seq_h;
  
  // Configuration parameters
  int num_masters;
  int num_slaves;
  bit is_enhanced_mode;
  bit is_4x4_ref_mode;
  string bus_matrix_mode_str;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_qos_equal_priority_fairness_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_bus_matrix_mode();
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_qos_equal_priority_fairness_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_qos_equal_priority_fairness_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_qos_equal_priority_fairness_test::new(string name = "axi4_qos_equal_priority_fairness_test",
                                                    uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Build phase to configure bus matrix mode and QoS settings
//--------------------------------------------------------------------------------------------
function void axi4_qos_equal_priority_fairness_test::build_phase(uvm_phase phase);
  int override_masters, override_slaves;
  axi4_bus_matrix_ref::bus_matrix_mode_e override_mode;
  axi4_bus_matrix_ref::bus_matrix_mode_e selected_mode;
  int selected_masters, selected_slaves;
  
  // Configure bus matrix mode BEFORE calling super.build_phase()
  // This ensures our configuration takes priority over test_config
  configure_bus_matrix_mode();
  
  // Get the selected mode from config_db (set by configure_bus_matrix_mode)
  if (uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::get(this, "*", "bus_matrix_mode", selected_mode)) begin
    // Create and configure test_config BEFORE super.build_phase()
    test_config = axi4_test_config::type_id::create("test_config");
    test_config.bus_matrix_mode = selected_mode;
    
    // Get number of masters/slaves from config_db
    if (uvm_config_db#(int)::get(this, "*", "override_num_masters", selected_masters)) begin
      test_config.num_masters = selected_masters;
    end else begin
      test_config.num_masters = (selected_mode == axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX) ? 10 : 4;
    end
    
    if (uvm_config_db#(int)::get(this, "*", "override_num_slaves", selected_slaves)) begin
      test_config.num_slaves = selected_slaves;
    end else begin
      test_config.num_slaves = (selected_mode == axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX) ? 10 : 4;
    end
    
    // Set in config_db so base test can get it
    uvm_config_db#(axi4_test_config)::set(this, "*", "test_config", test_config);
  end
  
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
  `uvm_info(get_type_name(), "AXI4 QOS EQUAL PRIORITY FAIRNESS TEST", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "Test validates fairness when all masters have equal QoS priority", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: configure_bus_matrix_mode
// Configure bus matrix mode supporting NONE, BASE_BUS_MATRIX (4x4), and BUS_ENHANCED_MATRIX (10x10)
//--------------------------------------------------------------------------------------------
function void axi4_qos_equal_priority_fairness_test::configure_bus_matrix_mode();
  string mode_str;
  bit mode_configured = 0;
  int random_mode;
  axi4_bus_matrix_ref::bus_matrix_mode_e selected_mode;
  int selected_masters, selected_slaves;
  
  // Priority 1: Check for command-line plusarg
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
    end else if (mode_str == "RANDOM" || mode_str == "random") begin
      // User explicitly requested random selection
      mode_configured = 0;
    end else begin
      `uvm_warning(get_type_name(), $sformatf("Invalid BUS_MATRIX_MODE: %s. Valid: NONE, 4x4/BASE, ENHANCED/10x10, RANDOM. Using random selection.", mode_str))
      mode_configured = 0;
    end
  end
  
  // Priority 2: Random selection if no configuration provided (3-way random)
  if (!mode_configured) begin
    random_mode = $urandom_range(0, 2); // 0=NONE, 1=BASE_BUS_MATRIX, 2=BUS_ENHANCED_MATRIX
    `uvm_info(get_type_name(), $sformatf("Randomly selecting bus matrix mode. Random value: %0d", random_mode), UVM_MEDIUM)
    
    if (random_mode == 2) begin
      selected_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
      selected_masters = 10;
      selected_slaves = 10;
      is_enhanced_mode = 1;
      is_4x4_ref_mode = 0;
      bus_matrix_mode_str = "BUS_ENHANCED_MATRIX (10x10 with ref model) [RANDOM]";
      `uvm_info(get_type_name(), "Random selection: BUS_ENHANCED_MATRIX mode", UVM_LOW)
    end else if (random_mode == 1) begin
      selected_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
      selected_masters = 4;
      selected_slaves = 4;
      is_enhanced_mode = 0;
      is_4x4_ref_mode = 1;
      bus_matrix_mode_str = "BASE_BUS_MATRIX (4x4 with ref model) [RANDOM]";
      `uvm_info(get_type_name(), "Random selection: BASE_BUS_MATRIX mode", UVM_LOW)
    end else begin
      selected_mode = axi4_bus_matrix_ref::NONE;
      selected_masters = 4;
      selected_slaves = 4;
      is_enhanced_mode = 0;
      is_4x4_ref_mode = 0;
      bus_matrix_mode_str = "NONE (no ref model, 4x4 topology) [RANDOM]";
      `uvm_info(get_type_name(), "Random selection: NONE mode", UVM_LOW)
    end
  end
  
  // Create test_config if it doesn't exist and set our values
  if (test_config == null) begin
    test_config = axi4_test_config::type_id::create("test_config");
  end
  
  // Override test_config settings to ensure our mode takes priority
  test_config.bus_matrix_mode = selected_mode;
  test_config.num_masters = selected_masters;
  test_config.num_slaves = selected_slaves;
  `uvm_info(get_type_name(), "Setting test_config with selected bus matrix mode", UVM_MEDIUM)
  
  // Store in config_db for base test to use - use parent context to ensure base test gets it
  uvm_config_db#(axi4_test_config)::set(null, "*", "test_config", test_config);
  
  // Store configuration for use after super.build_phase()
  // These will be applied to axi4_env_cfg_h after it's created
  uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", selected_mode);
  uvm_config_db#(int)::set(this, "*", "override_num_masters", selected_masters);
  uvm_config_db#(int)::set(this, "*", "override_num_slaves", selected_slaves);
  
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), "BUS MATRIX MODE CONFIGURATION", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Final Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), "Configuration Priority:", UVM_LOW)
  `uvm_info(get_type_name(), "  1. Command line: +BUS_MATRIX_MODE=NONE/4x4/BASE/ENHANCED/10x10/RANDOM", UVM_LOW)
  `uvm_info(get_type_name(), "  2. test_config (if available)", UVM_LOW)
  `uvm_info(get_type_name(), "  3. Random selection (default)", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
endfunction : configure_bus_matrix_mode

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration with QoS enabled
//--------------------------------------------------------------------------------------------
function void axi4_qos_equal_priority_fairness_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Enable QoS mode for both write and read priority-based arbitration
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = WRITE_READ_QOS_MODE_ENABLE;
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration with QoS enabled
//--------------------------------------------------------------------------------------------
function void axi4_qos_equal_priority_fairness_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Enable QoS mode for priority-based response
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = WRITE_READ_QOS_MODE_ENABLE;
    // Enable memory mode for proper data handling
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the QoS equal priority fairness virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_qos_equal_priority_fairness_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "  QOS EQUAL PRIORITY FAIRNESS TEST STARTING", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Running with mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Test start time: %0t", $time), UVM_LOW)
  
  phase.raise_objection(this);
  
  // Create and start the QoS equal priority fairness virtual sequence
  axi4_virtual_qos_equal_priority_fairness_seq_h = axi4_virtual_qos_equal_priority_fairness_seq::type_id::create("axi4_virtual_qos_equal_priority_fairness_seq_h");
  
  // Pass configuration to the sequence
  axi4_virtual_qos_equal_priority_fairness_seq_h.num_masters = num_masters;
  axi4_virtual_qos_equal_priority_fairness_seq_h.num_slaves = num_slaves;
  axi4_virtual_qos_equal_priority_fairness_seq_h.is_enhanced_mode = is_enhanced_mode;
  axi4_virtual_qos_equal_priority_fairness_seq_h.is_4x4_ref_mode = is_4x4_ref_mode;
  
  `uvm_info(get_type_name(), "Starting QoS equal priority fairness virtual sequence", UVM_LOW)
  axi4_virtual_qos_equal_priority_fairness_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "  QOS EQUAL PRIORITY FAIRNESS TEST COMPLETED", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif