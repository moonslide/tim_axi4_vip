`ifndef AXI4_NON_BLOCKING_WRITE_READ_RESPONSE_OUT_OF_ORDER_TEST_INCLUDED_
`define AXI4_NON_BLOCKING_WRITE_READ_RESPONSE_OUT_OF_ORDER_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_non_blocking_write_read_response_out_of_order_test
// Extends the base test and starts the virtual sequence of fixed burst write and read sequences
//--------------------------------------------------------------------------------------------
class axi4_non_blocking_write_read_response_out_of_order_test extends axi4_base_test;
  `uvm_component_utils(axi4_non_blocking_write_read_response_out_of_order_test)

  //Variable : axi4_virtual_nbk_write_read_response_out_of_order_seq_h
  //Instatiation of axi4_virtual_nbk_write_read_response_out_of_order_seq
  axi4_virtual_nbk_write_read_response_out_of_order_seq axi4_virtual_nbk_write_read_response_out_of_order_seq_h;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern function new(string name = "axi4_non_blocking_write_read_response_out_of_order_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);

endclass : axi4_non_blocking_write_read_response_out_of_order_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_non_blocking_write_read_response_out_of_order_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_non_blocking_write_read_response_out_of_order_test::new(string name = "axi4_non_blocking_write_read_response_out_of_order_test",
                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: setup_axi4_slave_agents_cfg
// Setup the axi4_slave agent(s) configuration with the required values
// and store the handle into the config_db
//--------------------------------------------------------------------------------------------
function void axi4_non_blocking_write_read_response_out_of_order_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i])begin
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].read_data_mode = SLAVE_MEM_MODE;
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].slave_response_mode =WRITE_READ_RESP_OUT_OF_ORDER ;
    // Set minimum_transactions to 0 for out-of-order mode to avoid FIFO deadlock
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].set_minimum_transactions(0);
    
    // Override slave agent configurations to prevent address=0 transactions
    // Force all slaves to use DDR memory range for reactive transactions
    if (i == 1) begin // Boot ROM slave - force to DDR range to avoid read-only access
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].min_address = 64'h0000_0100_0000_0000;
      axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].max_address = 64'h0000_0107_FFFF_FFFF;
      `uvm_info(get_type_name(), $sformatf("Slave[%0d] configured for DDR range to avoid address=0", i), UVM_LOW);
    end
  end
endfunction: setup_axi4_slave_agent_cfg

//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates the axi4_virtual_fixed_burst_write_seq sequence and starts the write and read virtual sequences
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_non_blocking_write_read_response_out_of_order_test::run_phase(uvm_phase phase);

  axi4_virtual_nbk_write_read_response_out_of_order_seq_h=axi4_virtual_nbk_write_read_response_out_of_order_seq::type_id::create("axi4_virtual_nbk_write_read_response_out_of_order_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi4_non_blocking_write_read_response_out_of_order_test"),UVM_LOW);
  phase.raise_objection(this);
  axi4_virtual_nbk_write_read_response_out_of_order_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  phase.drop_objection(this);

endtask : run_phase

`endif

