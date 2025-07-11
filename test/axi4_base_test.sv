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
  extern virtual function void setup_axi4_env_cfg();
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual local function void set_and_display_master_config();
  extern virtual function void setup_axi4_slave_agent_cfg();
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
  // Setup the environemnt cfg 
  setup_axi4_env_cfg();
  // Create the environment
  axi4_env_h = axi4_env::type_id::create("axi4_env_h",this);
endfunction : build_phase


//--------------------------------------------------------------------------------------------
// Function: setup_axi4_env_cfg
// Setup the environment configuration with the required values
// and store the handle into the config_db
//--------------------------------------------------------------------------------------------
function void axi4_base_test:: setup_axi4_env_cfg();
  axi4_env_cfg_h = axi4_env_config::type_id::create("axi4_env_cfg_h");
 
  // Get error_inject flag from config_db if set by test
  if (!uvm_config_db#(bit)::get(this, "*", "error_inject", axi4_env_cfg_h.error_inject)) begin
    axi4_env_cfg_h.error_inject = 0; // default value
  end
  
  axi4_env_cfg_h.has_scoreboard = 1;
  axi4_env_cfg_h.has_virtual_seqr = 1;
  axi4_env_cfg_h.no_of_masters = NO_OF_MASTERS;
  axi4_env_cfg_h.no_of_slaves = NO_OF_SLAVES;
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
  bit [63:0]local_min_address;
  bit [63:0]local_max_address;
  axi4_env_cfg_h.axi4_master_agent_cfg_h = new[axi4_env_cfg_h.no_of_masters];
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i])begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i] =
    axi4_master_agent_config::type_id::create($sformatf("axi4_master_agent_cfg_h[%0d]",i));
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].is_active   = uvm_active_passive_enum'(UVM_ACTIVE);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].has_coverage = 1; 
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
  end

  // Configure address ranges for each master based on bus matrix configuration
  // S0: DDR_Memory (0x0000_0100_0000_0000 - 0x0000_0107_FFFF_FFFF) - R/W for all masters
  // S1: Boot_ROM (0x0000_0000_0000_0000 - 0x0000_0000_0001_FFFF) - R only, no masters have access
  // S2: Peripheral_Regs (0x0000_0010_0000_0000 - 0x0000_0010_000F_FFFF) - R/W for M0,M1,M2
  // S3: HW_Fuse_Box (0x0000_0020_0000_0000 - 0x0000_0020_0000_0FFF) - R only for M0,M3
  
  // Master 0 (CPU_Core_A) - accesses S0, S2, S3(read-only)
  if (axi4_env_cfg_h.no_of_masters > 0) begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_min_addr_range(0, 64'h0000_0100_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_max_addr_range(0, 64'h0000_0107_FFFF_FFFF);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_min_addr_range(1, 64'h0000_0010_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_max_addr_range(1, 64'h0000_0010_000F_FFFF);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_min_addr_range(2, 64'h0000_0020_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[0].master_max_addr_range(2, 64'h0000_0020_0000_0FFF);
  end
  
  // Master 1 (CPU_Core_B) - accesses S0, S2
  if (axi4_env_cfg_h.no_of_masters > 1) begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[1].master_min_addr_range(0, 64'h0000_0100_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[1].master_max_addr_range(0, 64'h0000_0107_FFFF_FFFF);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[1].master_min_addr_range(1, 64'h0000_0010_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[1].master_max_addr_range(1, 64'h0000_0010_000F_FFFF);
  end
  
  // Master 2 (DMA_Controller) - accesses S0, S2
  if (axi4_env_cfg_h.no_of_masters > 2) begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[2].master_min_addr_range(0, 64'h0000_0100_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[2].master_max_addr_range(0, 64'h0000_0107_FFFF_FFFF);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[2].master_min_addr_range(1, 64'h0000_0010_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[2].master_max_addr_range(1, 64'h0000_0010_000F_FFFF);
  end
  
  // Master 3 (GPU) - accesses S0, S3(read-only)
  if (axi4_env_cfg_h.no_of_masters > 3) begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[3].master_min_addr_range(0, 64'h0000_0100_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[3].master_max_addr_range(0, 64'h0000_0107_FFFF_FFFF);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[3].master_min_addr_range(1, 64'h0000_0020_0000_0000);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[3].master_max_addr_range(1, 64'h0000_0020_0000_0FFF);
  end
endfunction: setup_axi4_master_agent_cfg

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
  axi4_env_cfg_h.axi4_slave_agent_cfg_h = new[axi4_env_cfg_h.no_of_slaves];
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i])begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i] =
    axi4_slave_agent_config::type_id::create($sformatf("axi4_slave_agent_cfg_h[%0d]",i));
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_id = i;
    
    // Configure slave address ranges based on bus matrix configuration
    case(i)
      0: begin // S0: DDR_Memory
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0100_0000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0107_FFFF_FFFF;
      end
      1: begin // S1: Boot_ROM (read-only)
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0000_0000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0000_0001_FFFF;
      end
      2: begin // S2: Peripheral_Regs
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0010_0000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0010_000F_FFFF;
      end
      3: begin // S3: HW_Fuse_Box (read-only)
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0020_0000_0000;
        axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0020_0000_0FFF;
      end
    endcase
    
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
endfunction: setup_axi4_slave_agent_cfg

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
  uvm_test_done.set_drain_time(this,3000ns);
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

