`ifndef AXI4_BASE_MATRIX_TEST_INCLUDED_
`define AXI4_BASE_MATRIX_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_base_matrix_test
// Example test using 4x4 base matrix configuration for backward compatibility
//--------------------------------------------------------------------------------------------
class axi4_base_matrix_test extends axi4_base_test;
  `uvm_component_utils(axi4_base_matrix_test)

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_base_matrix_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void setup_axi4_env_cfg();
  extern virtual function void setup_axi4_master_agent_cfg();
  extern virtual function void setup_axi4_slave_agent_cfg();

endclass : axi4_base_matrix_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_base_matrix_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_base_matrix_test::new(string name = "axi4_base_matrix_test", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Creates the required ports
//
// Parameters:
//  phase - stores the current phase
//--------------------------------------------------------------------------------------------
function void axi4_base_matrix_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_env_cfg
// Setup the axi4_env_cfg with the required values for 4x4 base matrix
//--------------------------------------------------------------------------------------------
function void axi4_base_matrix_test::setup_axi4_env_cfg();
  axi4_env_cfg_h = axi4_env_config::type_id::create("axi4_env_cfg_h");
  
  // Configure for 4x4 base matrix mode
  axi4_env_cfg_h.no_of_masters = 4;
  axi4_env_cfg_h.no_of_slaves = 4;
  axi4_env_cfg_h.bus_matrix_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
  
  // Enable other features
  axi4_env_cfg_h.has_scoreboard = 1;
  axi4_env_cfg_h.has_virtual_seqr = 1;
  axi4_env_cfg_h.axprot_chk_cfg = 1;
  axi4_env_cfg_h.axcache_chk_cfg = 1;
  
  `uvm_info(get_type_name(), "Configured environment for 4x4 base matrix mode", UVM_MEDIUM)
endfunction : setup_axi4_env_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration for 4 masters
//--------------------------------------------------------------------------------------------
function void axi4_base_matrix_test::setup_axi4_master_agent_cfg();
  axi4_env_cfg_h.axi4_master_agent_cfg_h = new[4];
  
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i]) begin
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i] = axi4_master_agent_config::type_id::create($sformatf("axi4_master_agent_cfg_h[%0d]", i));
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].is_active = uvm_active_passive_enum'(UVM_ACTIVE);
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].read_data_mode = RANDOM_DATA_MODE;
    
    // Configure master address ranges for 4x4 base matrix
    // S0: DDR_Memory (0x0100_0000 - 0x0107_FFFF)
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range_array[0] = 64'h0000_0100_0000_0000;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range_array[0] = 64'h0000_0107_FFFF_FFFF;
    
    // S1: Boot_ROM (0x0000_0000 - 0x0001_FFFF)
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range_array[1] = 64'h0000_0000_0000_0000;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range_array[1] = 64'h0000_0000_0001_FFFF;
    
    // S2: Peripheral_Regs (0x0010_0000 - 0x0010_FFFF)
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range_array[2] = 64'h0000_0010_0000_0000;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range_array[2] = 64'h0000_0010_000F_FFFF;
    
    // S3: HW_Fuse_Box (0x0020_0000 - 0x0020_0FFF)
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_min_addr_range_array[3] = 64'h0000_0020_0000_0000;
    axi4_env_cfg_h.axi4_master_agent_cfg_h[i].master_max_addr_range_array[3] = 64'h0000_0020_0000_0FFF;
  end
  
  `uvm_info(get_type_name(), "Configured 4 master agents for base matrix mode", UVM_MEDIUM)
endfunction : setup_axi4_master_agent_cfg

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agent_cfg
// Setup the axi4_slave agent configuration for 4 slaves
//--------------------------------------------------------------------------------------------
function void axi4_base_matrix_test::setup_axi4_slave_agent_cfg();
  axi4_env_cfg_h.axi4_slave_agent_cfg_h = new[4];
  
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i] = axi4_slave_agent_config::type_id::create($sformatf("axi4_slave_agent_cfg_h[%0d]", i));
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_id = i;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].is_active = uvm_active_passive_enum'(UVM_ACTIVE);
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode = RESP_IN_ORDER;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = RANDOM_DATA_MODE;
    
    // Configure slave address ranges
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
    endcase
  end
  
  `uvm_info(get_type_name(), "Configured 4 slave agents for base matrix mode", UVM_MEDIUM)
endfunction : setup_axi4_slave_agent_cfg

`endif