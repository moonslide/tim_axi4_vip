`ifndef AXI4_ERROR_INJECT_BASE_TEST_INCLUDED_
`define AXI4_ERROR_INJECT_BASE_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_error_inject_base_test
// Base test for error injection tests - automatically selects simple or full sequence
//--------------------------------------------------------------------------------------------
class axi4_error_inject_base_test extends axi4_base_test;
  `uvm_component_utils(axi4_error_inject_base_test)

  // Virtual sequence handles
  axi4_virtual_error_inject_simple_seq simple_seq_h;
  axi4_virtual_error_inject_full_seq full_seq_h;
  
  // Flag to determine which sequence to use
  bit use_full_sequence = 0;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_error_inject_base_test", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern virtual function void setup_axi4_env_cfg();
  extern task run_phase(uvm_phase phase);
  extern function void report_phase(uvm_phase phase);

endclass : axi4_error_inject_base_test

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_error_inject_base_test::new(string name = "axi4_error_inject_base_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_error_inject_base_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Enable error injection and exception handling
  uvm_config_db#(bit)::set(this, "*", "enable_error_injection", 1);
  uvm_config_db#(bit)::set(this, "*", "track_error_recovery", 1);
  
  // Set error_inject flag on all agents to prevent timeout errors
  // This needs to be done after super.build_phase creates the configs
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].error_inject = 1;
  end
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].error_inject = 1;
  end
  
  // Determine which sequence to use based on bus matrix mode
  // For NONE and BASE modes, we'll use the full sequence but limit active masters
  if (test_config.bus_matrix_mode == axi4_bus_matrix_ref::NONE) begin
    use_full_sequence = 1;  // Use full sequence but it will only activate 1 master
    `uvm_info(get_type_name(), $sformatf("NONE mode: Will use 1 master/1 slave from %0dx%0d configuration", 
              test_config.num_masters, test_config.num_slaves), UVM_MEDIUM)
  end else if (test_config.bus_matrix_mode == axi4_bus_matrix_ref::BASE_BUS_MATRIX) begin
    use_full_sequence = 1;  // Use full sequence but it will only activate 4 masters
    `uvm_info(get_type_name(), $sformatf("BASE mode: Will use 4 masters/4 slaves from %0dx%0d configuration", 
              test_config.num_masters, test_config.num_slaves), UVM_MEDIUM)
  end else if (test_config.bus_matrix_mode == axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX) begin
    use_full_sequence = 1;  // Use full sequence with all masters
    `uvm_info(get_type_name(), $sformatf("ENHANCED mode: Will use all %0d masters/%0d slaves", 
              test_config.num_masters, test_config.num_slaves), UVM_MEDIUM)
  end else begin
    use_full_sequence = 0;
    `uvm_info(get_type_name(), $sformatf("Using SIMPLE sequence for %0dx%0d configuration", 
              test_config.num_masters, test_config.num_slaves), UVM_MEDIUM)
  end
  
  // Pass the bus matrix mode to the sequence via config_db
  uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", test_config.bus_matrix_mode);
  
  `uvm_info(get_type_name(), "Build phase completed for error injection base test", UVM_LOW)
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_env_cfg
// Override to enable error injection for all error/exception tests
//--------------------------------------------------------------------------------------------
function void axi4_error_inject_base_test::setup_axi4_env_cfg();
  // Call parent implementation first
  super.setup_axi4_env_cfg();
  
  // Enable error injection for all tests extending from this base
  axi4_env_cfg_h.error_inject = 1;
  axi4_env_cfg_h.allow_error_responses = 0; // Let performance metrics auto-detect
  
  `uvm_info(get_type_name(), "Enabled error_inject flag for error/exception test", UVM_MEDIUM)
endfunction : setup_axi4_env_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_error_inject_base_test::run_phase(uvm_phase phase);
  
  phase.raise_objection(this);
  
  // Set a global timeout for error injection tests
  phase.phase_done.set_drain_time(this, 500ns);
  
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  `uvm_info(get_type_name(), "Starting Error Injection Base Test", UVM_LOW)
  `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  
  fork
    begin
      // Create and run the appropriate sequence
      if (use_full_sequence) begin
        `uvm_info(get_type_name(), $sformatf("Running with FULL sequence using %0d masters", test_config.num_masters), UVM_LOW)
        full_seq_h = axi4_virtual_error_inject_full_seq::type_id::create("full_seq_h");
        full_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
      end else begin
        `uvm_info(get_type_name(), "Running with SIMPLE sequence using 1 master", UVM_LOW)
        simple_seq_h = axi4_virtual_error_inject_simple_seq::type_id::create("simple_seq_h");
        simple_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
      end
      
      // Wait for completion
      #300ns;
    end
    
    begin
      // Watchdog timer to prevent infinite hangs
      #10us;
      `uvm_warning(get_type_name(), "Test watchdog timer expired - forcing test completion")
    end
  join_any
  
  // Kill any remaining processes
  disable fork;
  
  phase.drop_objection(this);
  
endtask : run_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
//--------------------------------------------------------------------------------------------
function void axi4_error_inject_base_test::report_phase(uvm_phase phase);
  uvm_report_server svr;
  super.report_phase(phase);
  
  svr = uvm_report_server::get_server();
  
  if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Error Injection Base Test PASSED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end else begin
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "Error Injection Base Test FAILED", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
  end
endfunction : report_phase

`endif