`ifndef AXI4_BASE_TEST_INCLUDED_
`define AXI4_BASE_TEST_INCLUDED_

// Include test configuration defines
`include "axi4_test_defines.svh"

//--------------------------------------------------------------------------------------------
// Class: axi4_base_test
// axi4_base test has the test scenarios for testbench which has the env, config, etc.
// Sequences are created and started in the test
//--------------------------------------------------------------------------------------------
class axi4_base_test extends uvm_test;
  
  `uvm_component_utils(axi4_base_test)

  // Variable: test_config
  // Test configuration for dynamic bus matrix mode and interface configuration
  axi4_test_config test_config;

  // Variable: e_cfg_h
  // Declaring environment config handle
  axi4_env_config axi4_env_cfg_h;

  // Variable: axi4_env_h
  // Handle for environment 
  axi4_env axi4_env_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_base_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void setup_test_configuration();
  extern virtual function void setup_axi4_env_cfg();
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_enhanced_master_agent_cfg();
  extern virtual function void setup_base_master_agent_cfg();
  extern virtual local function void set_and_display_master_config();
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual function void setup_enhanced_slave_agent_cfg();
  extern virtual function void setup_base_slave_agent_cfg();
  extern virtual local function void set_and_display_slave_config();
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task timeout_watchdog();

endclass : axi4_base_test

//--------------------------------------------------------------------------------------------
// Construct: new
//  Initializes class object
//
// Parameters:
//  name - axi4_base_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_base_test::new(string name = "axi4_base_test",uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//  Create required ports
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_base_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  // Setup test configuration based on test name
  setup_test_configuration();
  // Setup the environment cfg 
  setup_axi4_env_cfg();
  // Create the environment
  axi4_env_h = axi4_env::type_id::create("axi4_env_h",this);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: setup_test_configuration
// Setup test configuration based on test name for dynamic bus matrix mode and interface config
//--------------------------------------------------------------------------------------------
function void axi4_base_test::setup_test_configuration();
  string bus_mode_str;
  
  // Check if test_config already exists in config_db (set by derived test)
  if(!uvm_config_db#(axi4_test_config)::get(this, "*", "test_config", test_config)) begin
    // Create new test_config only if not already set
    test_config = axi4_test_config::type_id::create("test_config");
    
    // Configure based on current test name
    test_config.configure_for_test(get_type_name());
    
    // Check for command line override of bus matrix mode AFTER configuring
    if ($value$plusargs("BUS_MATRIX_MODE=%s", bus_mode_str)) begin
      `uvm_info(get_type_name(), $sformatf("Command line override: BUS_MATRIX_MODE=%s", bus_mode_str), UVM_MEDIUM)
      case (bus_mode_str)
        "NONE", "1x1": begin
          test_config.bus_matrix_mode = axi4_bus_matrix_ref::NONE;
          test_config.num_masters = 1;
          test_config.num_slaves = 1;
          `uvm_info(get_type_name(), "Overriding to NONE mode - will use 1 master/1 slave", UVM_MEDIUM)
        end
        "SIMPLE", "2x2": begin
          test_config.bus_matrix_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
          test_config.num_masters = 2;
          test_config.num_slaves = 2;
          `uvm_info(get_type_name(), "Overriding to BASE mode with 2x2 config - will use 2 masters/2 slaves", UVM_MEDIUM)
        end
        "BASE", "4x4": begin
          test_config.bus_matrix_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
          `uvm_info(get_type_name(), "Overriding to BASE mode - will use 4 masters/4 slaves", UVM_MEDIUM)
        end
        "ENHANCED", "10x10": begin
          test_config.bus_matrix_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
          `uvm_info(get_type_name(), "Overriding to ENHANCED mode - will use all 10 masters/10 slaves", UVM_MEDIUM)
        end
        default: begin
          `uvm_warning(get_type_name(), $sformatf("Unknown BUS_MATRIX_MODE: %s, keeping default", bus_mode_str))
        end
      endcase
    end
    
    // Store in config_db for use by environment and other components
    uvm_config_db#(axi4_test_config)::set(this, "*", "test_config", test_config);
    uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", test_config.bus_matrix_mode);
  end else begin
    `uvm_info(get_type_name(), "Using test_config from derived test", UVM_MEDIUM)
  end
  
  `uvm_info(get_type_name(), $sformatf("Test configuration set: %s", test_config.get_config_summary()), UVM_MEDIUM)
endfunction : setup_test_configuration

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_env_cfg
// Setup the environment configuration with the required values
// and store the handle into the config_db
//--------------------------------------------------------------------------------------------
function void axi4_base_test:: setup_axi4_env_cfg();
  axi4_env_cfg_h = axi4_env_config::type_id::create("axi4_env_cfg_h");
 
  // Initialize error handling configuration flags
  // These can be overridden by derived tests
  axi4_env_cfg_h.error_inject = 0; // default value
  axi4_env_cfg_h.allow_error_responses = 0; // default value
  
  axi4_env_cfg_h.has_scoreboard = 1;
  axi4_env_cfg_h.has_virtual_seqr = 1;
  
  // Use dynamic configuration from test_config
  axi4_env_cfg_h.no_of_masters = test_config.num_masters;
  axi4_env_cfg_h.no_of_slaves = test_config.num_slaves;
  axi4_env_cfg_h.bus_matrix_mode = test_config.bus_matrix_mode;
  
  axi4_env_cfg_h.ready_delay_cycles = 100;

  // Setup the axi4_master agent cfg 
  setup_axi4_master_agent_cfg();
  set_and_display_master_config();

  // Setup the axi4_slave agent cfg 
  setup_axi4_slave_agent_cfg();
  set_and_display_slave_config();

  axi4_env_cfg_h.write_read_mode_h = WRITE_READ_DATA;

  // set method for axi4_env_cfg
  uvm_config_db #(axi4_env_config)::set(this,"*","axi4_env_config",axi4_env_cfg_h);
  `uvm_info(get_type_name(),$sformatf("\nAXI4_ENV_CONFIG\n%s",axi4_env_cfg_h.sprint()),UVM_LOW);
endfunction: setup_axi4_env_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration with the required values
// and store the handle into the config_db
//--------------------------------------------------------------------------------------------
function void axi4_base_test::setup_axi4_master_agent_cfg();
  // Create master agent configs array based on dynamic configuration
  axi4_env_cfg_h.axi4_master_agent_cfg_h = new[axi4_env_cfg_h.no_of_masters];
  
  // Initialize common configuration for all masters
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i])begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i] =
    axi4_master_agent_config::type_id::create($sformatf("axi4_master_agent_cfg_h[%0d]",i));
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].is_active   = uvm_active_passive_enum'(UVM_ACTIVE);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].has_coverage = 1; 
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
  end
  
  // Configure address ranges based on bus matrix mode
  case(test_config.bus_matrix_mode)
    axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: setup_enhanced_master_agent_cfg();
    axi4_bus_matrix_ref::BASE_BUS_MATRIX: setup_base_master_agent_cfg();
    axi4_bus_matrix_ref::NONE: begin
      // For NONE mode, set very wide address ranges to allow any address
      for (int i = 0; i < axi4_env_cfg_h.no_of_masters; i++) begin
        for (int j = 0; j < axi4_env_cfg_h.no_of_slaves; j++) begin
          axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(j, 64'h0000_0000_0000_0000);
          axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(j, 64'hFFFF_FFFF_FFFF_FFFF);
        end
      end
      `uvm_info(get_type_name(), "Configured NONE mode master ranges - all addresses allowed", UVM_MEDIUM)
    end
  endcase
endfunction: setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_enhanced_master_agent_cfg
// Configure master address ranges for 10x10 enhanced bus matrix per claude.md
//--------------------------------------------------------------------------------------------
function void axi4_base_test::setup_enhanced_master_agent_cfg();
  // Configure address ranges per claude.md Enhanced Bus Matrix
  // S0: DDR Secure Kernel    (0x0000_0008_0000_0000 - 0x0000_0008_3FFF_FFFF) 1GB
  // S1: DDR Non-Secure User  (0x0000_0008_4000_0000 - 0x0000_0008_7FFF_FFFF) 1GB
  // S2: DDR Shared Buffer    (0x0000_0008_8000_0000 - 0x0000_0008_BFFF_FFFF) 1GB
  // S3: Illegal Address Hole (0x0000_0008_C000_0000 - 0x0000_0008_FFFF_FFFF) 1GB
  // S4: XOM Instruction-Only (0x0000_0009_0000_0000 - 0x0000_0009_3FFF_FFFF) 1GB
  // S5: RO Peripheral        (0x0000_000A_0000_0000 - 0x0000_000A_0000_FFFF) 64KB
  // S6: Privileged-Only      (0x0000_000A_0001_0000 - 0x0000_000A_0001_FFFF) 64KB
  // S7: Secure-Only          (0x0000_000A_0002_0000 - 0x0000_000A_0002_FFFF) 64KB
  // S8: Scratchpad           (0x0000_000A_0003_0000 - 0x0000_000A_0003_FFFF) 64KB
  // S9: Attribute Monitor    (0x0000_000A_0004_0000 - 0x0000_000A_0004_FFFF) 64KB

  for (int i = 0; i < axi4_env_cfg_h.no_of_masters; i++) begin
    // S0: DDR Secure Kernel
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(0, 64'h0000_0008_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(0, 64'h0000_0008_3FFF_FFFF);
    
    // S1: DDR Non-Secure User
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(1, 64'h0000_0008_4000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(1, 64'h0000_0008_7FFF_FFFF);
    
    // S2: DDR Shared Buffer
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(2, 64'h0000_0008_8000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(2, 64'h0000_0008_BFFF_FFFF);
    
    // S3: Illegal Address Hole
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(3, 64'h0000_0008_C000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(3, 64'h0000_0008_FFFF_FFFF);
    
    // S4: XOM Instruction-Only
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(4, 64'h0000_0009_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(4, 64'h0000_0009_3FFF_FFFF);
    
    // S5: RO Peripheral
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(5, 64'h0000_000A_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(5, 64'h0000_000A_0000_FFFF);
    
    // S6: Privileged-Only
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(6, 64'h0000_000A_0001_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(6, 64'h0000_000A_0001_FFFF);
    
    // S7: Secure-Only
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(7, 64'h0000_000A_0002_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(7, 64'h0000_000A_0002_FFFF);
    
    // S8: Scratchpad
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(8, 64'h0000_000A_0003_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(8, 64'h0000_000A_0003_FFFF);
    
    // S9: Attribute Monitor
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(9, 64'h0000_000A_0004_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(9, 64'h0000_000A_0004_FFFF);
  end
  
  `uvm_info(get_type_name(), "Configured Enhanced Bus Matrix master address ranges per claude.md", UVM_MEDIUM)
endfunction: setup_enhanced_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_base_master_agent_cfg
// Configure master address ranges for 4x4 base bus matrix per AXI_MATRIX.txt
//--------------------------------------------------------------------------------------------
function void axi4_base_test::setup_base_master_agent_cfg();
  // Configure address ranges per AXI_MATRIX.txt Base Bus Matrix
  // S0: DDR_Memory      (0x0000_0100_0000_0000 - 0x0000_0107_FFFF_FFFF) 32GB
  // S1: Boot_ROM        (0x0000_0000_0000_0000 - 0x0000_0000_0001_FFFF) 128KB
  // S2: Peripheral_Regs (0x0000_0010_0000_0000 - 0x0000_0010_000F_FFFF) 1MB
  // S3: HW_Fuse_Box     (0x0000_0020_0000_0000 - 0x0000_0020_0000_0FFF) 4KB

  for (int i = 0; i < axi4_env_cfg_h.no_of_masters; i++) begin
    // S0: DDR_Memory
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(0, 64'h0000_0100_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(0, 64'h0000_0107_FFFF_FFFF);
    
    // S1: Boot_ROM
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(1, 64'h0000_0000_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(1, 64'h0000_0000_0001_FFFF);
    
    // S2: Peripheral_Regs
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(2, 64'h0000_0010_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(2, 64'h0000_0010_000F_FFFF);
    
    // S3: HW_Fuse_Box
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range(3, 64'h0000_0020_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range(3, 64'h0000_0020_0000_0FFF);
  end
  
  `uvm_info(get_type_name(), "Configured Base Bus Matrix master address ranges per AXI_MATRIX.txt", UVM_MEDIUM)
endfunction: setup_base_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Using this function for setting the master config to database
//--------------------------------------------------------------------------------------------
function void axi4_base_test::set_and_display_master_config();
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i])begin
    uvm_config_db#(axi4_master_agent_config)::set(this,"*env*",
                                              $sformatf("axi4_master_agent_config_%0d",i),
                                              axi4_env_cfg_h.axi4_master_agent_cfg_h[i]);
   `uvm_info(get_type_name(),$sformatf("\nAXI4_MASTER_CONFIG[%0d]\n%s",i,axi4_env_cfg_h.axi4_master_agent_cfg_h[i].sprint()),UVM_LOW);
 end
endfunction: set_and_display_master_config

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agents_cfg
// Setup the axi4_slave agent(s) configuration with the required values
// and store the handle into the config_db
//--------------------------------------------------------------------------------------------
function void axi4_base_test::setup_axi4_slave_agent_cfg();
  // Create slave agent configs array based on dynamic configuration
  axi4_env_cfg_h.axi4_slave_agent_cfg_h = new[axi4_env_cfg_h.no_of_slaves];
  
  // Initialize common configuration for all slaves
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i])begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i] =
    axi4_slave_agent_config::type_id::create($sformatf("axi4_slave_agent_cfg_h[%0d]",i));
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_id = i;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].maximum_transactions = 3;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = RESP_IN_ORDER;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;

    if(SLAVE_AGENT_ACTIVE === 1) begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].is_active = uvm_active_passive_enum'(UVM_ACTIVE);
    end
    else begin
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].is_active = uvm_active_passive_enum'(UVM_PASSIVE);
    end 
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].has_coverage = 1; 
  end
  
  // Configure address ranges based on bus matrix mode
  case(test_config.bus_matrix_mode)
    axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: setup_enhanced_slave_agent_cfg();
    axi4_bus_matrix_ref::BASE_BUS_MATRIX: setup_base_slave_agent_cfg();
    axi4_bus_matrix_ref::NONE: begin 
      // For NONE mode, configure single slave with specific address range
      // This prevents multiple slaves from responding to the same transaction
      foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
        if(i == 0) begin
          // Primary slave handles most of the address space
          axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0000_0000_0000;
          axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0000_FFFF_FFFF;
        end else begin
          // Additional slaves get non-overlapping ranges if present
          // This prevents conflicts during testing
          axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0001_0000_0000 + (i * 64'h0000_0001_0000_0000);
          axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0001_FFFF_FFFF + (i * 64'h0000_0001_0000_0000);
        end
      end
      `uvm_info(get_type_name(), "Configured NONE mode - non-overlapping address ranges for slaves", UVM_MEDIUM)
    end
  endcase
endfunction: setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_enhanced_slave_agent_cfg
// Configure slave address ranges for 10x10 enhanced bus matrix per claude.md
//--------------------------------------------------------------------------------------------
function void axi4_base_test::setup_enhanced_slave_agent_cfg();
  // Configure address ranges per claude.md Enhanced Bus Matrix
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    case(i)
      0: begin // S0: DDR Secure Kernel
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0008_0000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0008_3FFF_FFFF;
      end
      1: begin // S1: DDR Non-Secure User
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0008_4000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0008_7FFF_FFFF;
      end
      2: begin // S2: DDR Shared Buffer
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0008_8000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0008_BFFF_FFFF;
      end
      3: begin // S3: Illegal Address Hole
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0008_C000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0008_FFFF_FFFF;
      end
      4: begin // S4: XOM Instruction-Only
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0009_0000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0009_3FFF_FFFF;
      end
      5: begin // S5: RO Peripheral
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_000A_0000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_000A_0000_FFFF;
      end
      6: begin // S6: Privileged-Only
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_000A_0001_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_000A_0001_FFFF;
      end
      7: begin // S7: Secure-Only
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_000A_0002_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_000A_0002_FFFF;
      end
      8: begin // S8: Scratchpad
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_000A_0003_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_000A_0003_FFFF;
      end
      9: begin // S9: Attribute Monitor
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_000A_0004_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_000A_0004_FFFF;
      end
      default: begin // Default case for safety
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'hFFFF_FFFF;
      end
    endcase
  end
  
  `uvm_info(get_type_name(), "Configured Enhanced Bus Matrix slave address ranges per claude.md", UVM_MEDIUM)
endfunction: setup_enhanced_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_base_slave_agent_cfg  
// Configure slave address ranges for 4x4 base bus matrix per AXI_MATRIX.txt
//--------------------------------------------------------------------------------------------
function void axi4_base_test::setup_base_slave_agent_cfg();
  // Configure address ranges per AXI_MATRIX.txt Base Bus Matrix
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    case(i)
      0: begin // S0: DDR_Memory
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0100_0000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0107_FFFF_FFFF;
      end
      1: begin // S1: Boot_ROM
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0000_0000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0000_0001_FFFF;
      end
      2: begin // S2: Peripheral_Regs
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0010_0000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0010_000F_FFFF;
      end
      3: begin // S3: HW_Fuse_Box
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0020_0000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0020_0000_0FFF;
      end
      default: begin // Default case for safety
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'hFFFF_FFFF;
      end
    endcase
  end
  
  `uvm_info(get_type_name(), "Configured Base Bus Matrix slave address ranges per AXI_MATRIX.txt", UVM_MEDIUM)
endfunction: setup_base_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Using this function for setting the slave config to database
//--------------------------------------------------------------------------------------------
function void axi4_base_test::set_and_display_slave_config();
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i])begin
    uvm_config_db #(axi4_slave_agent_config)::set(this,"*env*",
                                              $sformatf("axi4_slave_agent_config_%0d",i),
                                              axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]);
    uvm_config_db #(read_data_type_mode_e)::set(this,"*","read_data_mode",axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode);   
   `uvm_info(get_type_name(),$sformatf("\nAXI4_SLAVE_CONFIG[%0d]\n%s",i,axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].sprint()),UVM_LOW);
 end
endfunction: set_and_display_slave_config
//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
// Used for printing the testbench topology
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_base_test::end_of_elaboration_phase(uvm_phase phase);
  uvm_top.print_topology();
  // Set drain time using the objection mechanism in UVM 1.2
  // uvm_test_done.set_drain_time(this,3000ns); // Deprecated
endfunction : end_of_elaboration_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Used for giving basic delay for simulation 
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_base_test::run_phase(uvm_phase phase);

  phase.raise_objection(this, "axi4_base_test");

  // Start timeout watchdog in parallel
  fork
    timeout_watchdog();
  join_none

  `uvm_info(get_type_name(), $sformatf("Inside BASE_TEST"), UVM_NONE);
  super.run_phase(phase);
  #100;
  `uvm_info(get_type_name(), $sformatf("Done BASE_TEST"), UVM_NONE);
  phase.drop_objection(this);

endtask : run_phase

//--------------------------------------------------------------------------------------------
// Task: timeout_watchdog
// Implements configurable timeout watchdog that generates UVM_FATAL if exceeded
// Timeout value is configurable via DEFAULT_TEST_TIMEOUT define
//--------------------------------------------------------------------------------------------
task axi4_base_test::timeout_watchdog();
  #`DEFAULT_TEST_TIMEOUT;
  `uvm_fatal(get_type_name(), $sformatf("TEST TIMEOUT: Test exceeded %0s execution time limit!", `"DEFAULT_TEST_TIMEOUT`"))
endtask : timeout_watchdog

`endif

