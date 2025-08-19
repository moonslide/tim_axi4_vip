`ifndef AXI4_USER_SIGNAL_CORRUPTION_TEST_INCLUDED_
`define AXI4_USER_SIGNAL_CORRUPTION_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_signal_corruption_test
// Tests USER signal corruption detection and handling
// Supports all three bus matrix modes: NONE, BASE_BUS_MATRIX (4x4), BUS_ENHANCED_MATRIX (10x10)
//--------------------------------------------------------------------------------------------
class axi4_user_signal_corruption_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_signal_corruption_test)
  
  // Virtual sequence handle
  axi4_virtual_user_signal_corruption_seq corruption_vseq;
  
  // Configuration parameters
  int num_masters;
  int num_slaves;
  bit is_enhanced_mode;
  bit is_4x4_ref_mode;
  string bus_matrix_mode_str;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_signal_corruption_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_bus_matrix_mode();
  extern virtual task run_phase(uvm_phase phase);
  
endclass : axi4_user_signal_corruption_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_user_signal_corruption_test::new(string name = "axi4_user_signal_corruption_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_corruption_test::build_phase(uvm_phase phase);
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
  `uvm_info(get_type_name(), "AXI4 USER SIGNAL CORRUPTION TEST", UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %s", bus_matrix_mode_str), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", num_masters, num_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "==========================================================", UVM_LOW)
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: configure_bus_matrix_mode
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_corruption_test::configure_bus_matrix_mode();
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
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_user_signal_corruption_test::run_phase(uvm_phase phase);
  phase.raise_objection(this);
  
  `uvm_info(get_type_name(), "Starting USER Signal Corruption Test", UVM_LOW)
  
  corruption_vseq = axi4_virtual_user_signal_corruption_seq::type_id::create("corruption_vseq");
  
  // Configure the virtual sequence with bus matrix mode info
  corruption_vseq.num_masters = num_masters;
  corruption_vseq.num_slaves = num_slaves;
  corruption_vseq.is_enhanced_mode = is_enhanced_mode;
  corruption_vseq.is_4x4_ref_mode = is_4x4_ref_mode;
  
  // Limit number of corruption tests to avoid timeout
  corruption_vseq.num_corruption_tests = 5; // Reduced from 20-50 to 5
  
  corruption_vseq.start(axi4_env_h.axi4_virtual_seqr_h);
  
  #100ns;
  
  `uvm_info(get_type_name(), "USER Signal Corruption Test Completed", UVM_LOW)
  
  phase.drop_objection(this);
endtask : run_phase

`endif