`ifndef AXI4_USER_SIGNAL_WIDTH_MISMATCH_TEST_INCLUDED_
`define AXI4_USER_SIGNAL_WIDTH_MISMATCH_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_user_signal_width_mismatch_test
// Tests USER signal width mismatch scenarios to verify proper handling of width differences
// Uses the same environment as QoS routing test but focuses on width compatibility issues
//--------------------------------------------------------------------------------------------
class axi4_user_signal_width_mismatch_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_signal_width_mismatch_test)

  // Variable: axi4_virtual_user_signal_width_mismatch_seq_h
  // Handle to the USER signal width mismatch virtual sequence
  axi4_virtual_user_signal_width_mismatch_seq axi4_virtual_user_signal_width_mismatch_seq_h;

  // Bus matrix mode configuration
  axi4_bus_matrix_ref::bus_matrix_mode_e selected_mode = axi4_bus_matrix_ref::NONE;
  int selected_masters = 1;
  int selected_slaves = 1;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_user_signal_width_mismatch_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_bus_matrix_mode();
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_user_signal_width_mismatch_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_user_signal_width_mismatch_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_user_signal_width_mismatch_test::new(string name = "axi4_user_signal_width_mismatch_test",
                                                   uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Sets up bus matrix mode configuration
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_width_mismatch_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Configure bus matrix mode based on plusarg
  configure_bus_matrix_mode();
  
  // Update environment configuration
  axi4_env_cfg_h.bus_matrix_mode = selected_mode;
  axi4_env_cfg_h.no_of_masters = selected_masters;
  axi4_env_cfg_h.no_of_slaves = selected_slaves;
  
  // Allow error responses for width mismatch testing
  // This is necessary because width mismatches and address mapping issues may cause protocol errors
  axi4_env_cfg_h.allow_error_responses = 1;
  
  `uvm_info(get_type_name(), $sformatf("Bus Matrix Mode: %s", selected_mode.name()), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Masters: %0d, Slaves: %0d", selected_masters, selected_slaves), UVM_LOW)
  `uvm_info(get_type_name(), "Error responses allowed for width mismatch testing", UVM_LOW)
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: configure_bus_matrix_mode
// Configures bus matrix mode based on plusargs
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_width_mismatch_test::configure_bus_matrix_mode();
  string mode_str;
  
  if ($value$plusargs("BUS_MATRIX_MODE=%s", mode_str)) begin
    if (mode_str == "ENHANCED" || mode_str == "enhanced" || mode_str == "10x10") begin
      selected_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
      selected_masters = 10;
      selected_slaves = 10;
      `uvm_info(get_type_name(), "Configuring BUS_ENHANCED_MATRIX (10x10) mode", UVM_LOW)
    end else if (mode_str == "BASE" || mode_str == "base" || mode_str == "4x4") begin
      selected_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
      selected_masters = 4;
      selected_slaves = 4;
      `uvm_info(get_type_name(), "Configuring BASE_BUS_MATRIX (4x4) mode", UVM_LOW)
    end else if (mode_str == "NONE" || mode_str == "none") begin
      selected_mode = axi4_bus_matrix_ref::NONE;
      selected_masters = 1;
      selected_slaves = 1;
      `uvm_info(get_type_name(), "Configuring NONE (no ref model) mode", UVM_LOW)
    end else begin
      `uvm_warning(get_type_name(), $sformatf("Unknown BUS_MATRIX_MODE: %s, using NONE", mode_str))
      selected_mode = axi4_bus_matrix_ref::NONE;
      selected_masters = 1;
      selected_slaves = 1;
    end
  end else begin
    // Default to NONE mode
    selected_mode = axi4_bus_matrix_ref::NONE;
    selected_masters = 1;
    selected_slaves = 1;
    `uvm_info(get_type_name(), "No BUS_MATRIX_MODE specified, defaulting to NONE", UVM_LOW)
  end
endfunction : configure_bus_matrix_mode

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration for width mismatch testing
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_width_mismatch_test::setup_axi4_master_agent_cfg();
  super.setup_axi4_master_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    // Disable QoS mode to focus on USER signal width testing
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Set reasonable outstanding transactions
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_write_tx = 4;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].outstanding_read_tx = 4;
    // USER signal width configuration will be tested with different values
    // The testbench uses 32-bit USER signals by default per axi4_bus_config.svh
    // We'll test scenarios where components expect different widths
  end
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration for width mismatch testing
//--------------------------------------------------------------------------------------------
function void axi4_user_signal_width_mismatch_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    // Disable QoS mode to focus on USER signal width testing
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
    // Enable checks for USER signal width consistency
  end
endfunction : setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates and starts the USER signal width mismatch virtual sequence
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_user_signal_width_mismatch_test::run_phase(uvm_phase phase);
  
  axi4_virtual_user_signal_width_mismatch_seq_h = axi4_virtual_user_signal_width_mismatch_seq::type_id::create("axi4_virtual_user_signal_width_mismatch_seq_h");
  
  // Pass configuration to virtual sequence
  axi4_virtual_user_signal_width_mismatch_seq_h.num_masters = selected_masters;
  axi4_virtual_user_signal_width_mismatch_seq_h.num_slaves = selected_slaves;
  axi4_virtual_user_signal_width_mismatch_seq_h.is_enhanced_mode = (selected_mode == axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX);
  axi4_virtual_user_signal_width_mismatch_seq_h.is_4x4_ref_mode = (selected_mode == axi4_bus_matrix_ref::BASE_BUS_MATRIX);
  
  `uvm_info(get_type_name(), "Starting USER Signal Width Mismatch Test", UVM_LOW)
  `uvm_info(get_type_name(), "This test verifies handling of USER signal width differences", UVM_LOW)
  `uvm_info(get_type_name(), "Width mismatch scenarios to be tested:", UVM_LOW)
  `uvm_info(get_type_name(), "  1. 32-bit USER truncated to lower widths (16, 8, 4, 1-bit)", UVM_LOW)
  `uvm_info(get_type_name(), "  2. Narrow USER zero-padded to wider interfaces", UVM_LOW)
  `uvm_info(get_type_name(), "  3. MSB preservation vs LSB preservation truncation", UVM_LOW)
  `uvm_info(get_type_name(), "  4. Width mismatches between channels (AWUSER vs WUSER)", UVM_LOW)
  `uvm_info(get_type_name(), "  5. Different widths for different masters/slaves", UVM_LOW)
  `uvm_info(get_type_name(), "  6. Dynamic width adaptation testing", UVM_LOW)
  `uvm_info(get_type_name(), "  7. Boundary value testing (all 1s, alternating patterns)", UVM_LOW)
  `uvm_info(get_type_name(), "  8. Width mismatch impact on QoS/routing information", UVM_LOW)
  
  `uvm_info(get_type_name(), "Expected USER signal widths per axi4_bus_config.svh:", UVM_LOW)
  `uvm_info(get_type_name(), "  AWUSER: 32-bit", UVM_LOW)
  `uvm_info(get_type_name(), "  ARUSER: 32-bit", UVM_LOW)
  `uvm_info(get_type_name(), "  WUSER:  32-bit", UVM_LOW)
  `uvm_info(get_type_name(), "  BUSER:  16-bit", UVM_LOW)
  `uvm_info(get_type_name(), "  RUSER:  16-bit", UVM_LOW)
  
  phase.raise_objection(this);
  axi4_virtual_user_signal_width_mismatch_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);
  
endtask : run_phase

`endif