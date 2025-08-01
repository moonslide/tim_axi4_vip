`ifndef AXI4_ENV_CONFIG_INCLUDED_
`define AXI4_ENV_CONFIG_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4 env_config
// This class is used as configuration class for environment and its components
//--------------------------------------------------------------------------------------------
class axi4_env_config extends uvm_object;
  `uvm_object_utils(axi4_env_config)
  

  // Variable: has_scoreboard
  // Enables the scoreboard. Default value is 1
  bit has_scoreboard = 1;

  // Variable: has_virtual_sqr
  // Enables the virtual sequencer. Default value is 1
  bit has_virtual_seqr = 1;

  // Variable: no_of_slaves
  // Number of slaves connected to the AXI interface
  int no_of_slaves;
  
  // Variable: no_of_masters
  // Number of masters connected to the AXI interface
  int no_of_masters;

  // Variable: master_agent_cfg_h
  // Handle for axi4 master agent configuration
  axi4_master_agent_config axi4_master_agent_cfg_h[];

  // Variable: slave_agent_cfg_h
  // axi4 slave agent configuration handles
  axi4_slave_agent_config axi4_slave_agent_cfg_h[];

  // Variable: write_read_mode_h
  write_read_data_mode_e write_read_mode_h;

  // Variable: check_wait_states
  // Enable wait state comparison in scoreboard
  bit check_wait_states = 0;

  // Variable: wstrb_compare_enable
  // Enable scoreboard memory model for WSTRB tests
  bit wstrb_compare_enable = 0;

  // Variable: ready_delay_cycles
  // Maximum cycles allowed between VALID and READY handshake
  int ready_delay_cycles = 100;

  // Variable: error_inject
  // Enable error injection mode - converts UVM_ERROR to UVM_WARNING for expected errors
  bit error_inject = 0;

  // Variable: axprot_chk_cfg
  // Enable AxPROT attribute checking and monitoring (Claude.md requirement)
  bit axprot_chk_cfg = 1;

  // Variable: axcache_chk_cfg  
  // Enable AxCACHE attribute checking and monitoring (Claude.md requirement)
  bit axcache_chk_cfg = 1;

  // Variable: bus_matrix_mode
  // Bus matrix reference model mode: BASE_BUS_MATRIX (4x4), BUS_ENHANCED_MATRIX (10x10), NONE
  // Import the enum type from bus matrix package
  axi4_bus_matrix_ref::bus_matrix_mode_e bus_matrix_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;

//-------------------------------------------------------
// Externally defined Tasks and Functions
//-------------------------------------------------------
  extern function new(string name = "axi4_env_config");
  extern function void do_print(uvm_printer printer);

endclass : axi4_env_config

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_env_config
//--------------------------------------------------------------------------------------------
function axi4_env_config::new(string name = "axi4_env_config");
  super.new(name);
endfunction : new


//--------------------------------------------------------------------------------------------
// Function: do_print method
// Print method can be added to display the data members values
//--------------------------------------------------------------------------------------------
function void axi4_env_config::do_print(uvm_printer printer);
  super.do_print(printer);
  
  printer.print_field ("has_scoreboard",has_scoreboard,1, UVM_DEC);
  printer.print_field ("has_virtual_sqr",has_virtual_seqr,1, UVM_DEC);
  printer.print_field ("no_of_masters",no_of_masters,$bits(no_of_masters), UVM_HEX);
  printer.print_field ("no_of_slaves",no_of_slaves,$bits(no_of_slaves), UVM_HEX);
  printer.print_string ("transfer_type",   write_read_mode_h.name());
  printer.print_field ("check_wait_states",check_wait_states,1, UVM_DEC);
  printer.print_field ("wstrb_compare_enable",wstrb_compare_enable,1, UVM_DEC);
  printer.print_field ("ready_delay_cycles",ready_delay_cycles,32, UVM_DEC);
  printer.print_field ("error_inject",error_inject,1, UVM_DEC);
  printer.print_field ("axprot_chk_cfg",axprot_chk_cfg,1, UVM_DEC);
  printer.print_field ("axcache_chk_cfg",axcache_chk_cfg,1, UVM_DEC);
  printer.print_string ("bus_matrix_mode",bus_matrix_mode.name());

endfunction : do_print

`endif

