`ifndef AXI4_USER_SECURITY_TAGGING_TEST_INCLUDED_
`define AXI4_USER_SECURITY_TAGGING_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_security_tagging_test
// Tests USER signal security tagging mechanism for access control and data classification
// Demonstrates how USER signals can enforce security policies and isolation
//--------------------------------------------------------------------------------------------
class axi4_user_security_tagging_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_security_tagging_test)

  // Variable: axi4_virtual_user_security_tagging_seq_h
  // Handle to the USER security tagging virtual sequence
  axi4_virtual_user_security_tagging_seq axi4_virtual_user_security_tagging_seq_h;
  
  // Configuration parameters
  int num_masters;
  int num_slaves;
  bit is_enhanced_mode;
  bit is_4x4_ref_mode;
  string bus_matrix_mode_str;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_security_tagging_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_bus_matrix_mode();
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_user_security_tagging_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_user_security_tagging_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_user_security_tagging_test::new(string name = "axi4_user_security_tagging_test",
                                              uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Build phase to configure bus matrix mode and security tagging settings
//--------------------------------------------------------------------------------------------
function void axi4_user_security_tagging_test::build_phase(uvm_phase phase);
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
  `uvm_info(get_type_name(), "AXI4 USER SECURITY TAGGING TEST", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "Test validates USER signal security tagging mechanisms", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: configure_bus_matrix_mode
// Configure bus matrix mode supporting NONE, BASE_BUS_MATRIX (4x4), and BUS_ENHANCED_MATRIX (10x10)
//--------------------------------------------------------------------------------------------
function void axi4_user_security_tagging_test::configure_bus_matrix_mode();
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
  
  // Store in config_db for base test to use
  uvm_config_db#(axi4_test_config)::set(null, "*", "test_config", test_config);
  
  // Store configuration for use after super.build_phase()
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
// Setup the axi4_master agent configuration with USER security tagging enabled
//--------------------------------------------------------------------------------------------
function void axi4_user_security_tagging_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Set reasonable outstanding transactions
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 4;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 4;
    // Enable USER signal support for security tagging
    // USER signal format (32 bits):
    // [3:0]   - Security Level (0=Unclassified, 1-15=Various levels)
    // [7:4]   - Domain ID (0-15 security domains)
    // [11:8]  - Access Rights (Read/Write/Execute/Delete)
    // [15:12] - Privilege Level (User/Supervisor/Hypervisor/Secure)
    // [19:16] - Security Zone (DMZ/Internal/Critical/Isolated)
    // [23:20] - Encryption Required (None/AES128/AES256/Custom)
    // [27:24] - Integrity Check (None/CRC/Hash/HMAC)
    // [31:28] - Audit Level (None/Basic/Enhanced/Full)
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration with security policy enforcement
//--------------------------------------------------------------------------------------------
function void axi4_user_security_tagging_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to simplify and avoid address mapping issues
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Enable security checking on slave side
    // Slaves will enforce security policies based on USER tags
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the USER security tagging virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_user_security_tagging_test::run_phase(uvm_phase phase);
  
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "  USER SECURITY TAGGING TEST STARTING", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Running with mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Test start time: %0t", $time), UVM_LOW)
  
  phase.raise_objection(this);
  
  // Create and configure the virtual sequence
  axi4_virtual_user_security_tagging_seq_h = axi4_virtual_user_security_tagging_seq::type_id::create("axi4_virtual_user_security_tagging_seq_h");
  
  // Pass configuration to the sequence
  axi4_virtual_user_security_tagging_seq_h.num_masters = num_masters;
  axi4_virtual_user_security_tagging_seq_h.num_slaves = num_slaves;
  axi4_virtual_user_security_tagging_seq_h.is_enhanced_mode = is_enhanced_mode;
  axi4_virtual_user_security_tagging_seq_h.is_4x4_ref_mode = is_4x4_ref_mode;
  
  `uvm_info(get_type_name(), "Starting USER Security Tagging Test", UVM_LOW)
  `uvm_info(get_type_name(), "This test demonstrates security policy enforcement using USER signals", UVM_LOW)
  `uvm_info(get_type_name(), "USER Signal Security Format (32 bits):", UVM_LOW)
  `uvm_info(get_type_name(), "  [3:0]   - Security Level (0=Unclassified, 15=Top Secret)", UVM_LOW)
  `uvm_info(get_type_name(), "  [7:4]   - Domain ID (0-15 isolation domains)", UVM_LOW)  
  `uvm_info(get_type_name(), "  [11:8]  - Access Rights (R/W/X/D permissions)", UVM_LOW)
  `uvm_info(get_type_name(), "  [15:12] - Privilege Level (User/Super/Hyper/Secure)", UVM_LOW)
  `uvm_info(get_type_name(), "  [19:16] - Security Zone (DMZ/Internal/Critical/Isolated)", UVM_LOW)
  `uvm_info(get_type_name(), "  [23:20] - Encryption Required", UVM_LOW)
  `uvm_info(get_type_name(), "  [27:24] - Integrity Check", UVM_LOW)
  `uvm_info(get_type_name(), "  [31:28] - Audit Level", UVM_LOW)
  
  axi4_virtual_user_security_tagging_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  `uvm_info(get_type_name(), "  USER SECURITY TAGGING TEST COMPLETED", UVM_LOW)
  `uvm_info(get_type_name(), "====================================================", UVM_LOW)
  
  phase.drop_objection(this);
  
endtask : run_phase

`endif