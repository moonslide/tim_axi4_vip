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

  // Variable: master_address_width
  // Array storing address width for each master. Default value is ADDRESS_WIDTH
  int master_address_width[];

  // Variable: master_data_width
  // Array storing data width for each master. Default value is DATA_WIDTH
  int master_data_width[];

  // Variable: slave_address_width
  // Array storing address width for each slave. Default value is ADDRESS_WIDTH
  int slave_address_width[];

  // Variable: slave_data_width
  // Array storing data width for each slave. Default value is DATA_WIDTH
  int slave_data_width[];

  // constraint : width_limit_c
  // Restrict widths for master and slave based on AMBA4 specification
  constraint width_limit_c {
    foreach(master_address_width[i]) master_address_width[i] <= 64;
    foreach(slave_address_width[i])  slave_address_width[i]  <= 64;
    foreach(master_data_width[i])    master_data_width[i]    inside {32,64,128,256,512,1024};
    foreach(slave_data_width[i])     slave_data_width[i]     inside {32,64,128,256,512,1024};
  }


  // Variable: master_agent_cfg_h
  // Handle for axi4 master agent configuration
  axi4_master_agent_config axi4_master_agent_cfg_h[];

  // Variable: slave_agent_cfg_h
  // axi4 slave agent configuration handles
  axi4_slave_agent_config axi4_slave_agent_cfg_h[];

  // Variable: write_read_mode_h
  write_read_data_mode_e write_read_mode_h;

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

  // Set default number of masters and slaves from globals
  no_of_masters = NO_OF_MASTERS;
  no_of_slaves  = NO_OF_SLAVES;

  // Allocate width arrays and initialize with default globals
  master_address_width = new[no_of_masters];
  master_data_width    = new[no_of_masters];
  foreach(master_address_width[i]) begin
    master_address_width[i] = ADDRESS_WIDTH;
    master_data_width[i]    = DATA_WIDTH;
  end

  slave_address_width  = new[no_of_slaves];
  slave_data_width     = new[no_of_slaves];
  foreach(slave_address_width[i]) begin
    slave_address_width[i] = ADDRESS_WIDTH;
    slave_data_width[i]    = DATA_WIDTH;
  end
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
  foreach(master_address_width[i]) begin
    printer.print_field($sformatf("master_address_width[%0d]",i), master_address_width[i], $bits(master_address_width[i]), UVM_DEC);
    printer.print_field($sformatf("master_data_width[%0d]",i), master_data_width[i], $bits(master_data_width[i]), UVM_DEC);
  end
  foreach(slave_address_width[i]) begin
    printer.print_field($sformatf("slave_address_width[%0d]",i), slave_address_width[i], $bits(slave_address_width[i]), UVM_DEC);
    printer.print_field($sformatf("slave_data_width[%0d]",i), slave_data_width[i], $bits(slave_data_width[i]), UVM_DEC);
  end
  printer.print_string ("transfer_type",   write_read_mode_h.name());

endfunction : do_print

`endif

