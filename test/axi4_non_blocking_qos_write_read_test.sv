`ifndef AXI4_NON_BLOCKING_QOS_WRITE_READ_TEST_INCLUDED_
`define AXI4_NON_BLOCKING_QOS_WRITE_READ_TEST_INCLUDED_ 

//--------------------------------------------------------------------------------------------
// Class axi4_non_blocking_qos_write_read_test
// Extends the base test and starts the virtual sequenceof write
//--------------------------------------------------------------------------------------------
class axi4_non_blocking_qos_write_read_test extends axi4_base_test;
  `uvm_component_utils(axi4_non_blocking_qos_write_read_test)

  //Variable : axi4_virtual_nbk_qos_write_read_seq_h
  //Instatiation of axi4_virtual_nbk_qos_write_read_seq
  axi4_virtual_nbk_qos_write_read_seq  axi4_virtual_nbk_qos_write_read_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_non_blocking_qos_write_read_test", uvm_component parent = null);
  extern virtual function void setup_axi4_master_agent_cfg();  
  extern virtual function void setup_axi4_slave_agent_cfg();
  extern virtual task run_phase(uvm_phase phase);
endclass : axi4_non_blocking_qos_write_read_test

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_non_blocking_qos_write_read_test
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_non_blocking_qos_write_read_test::new(string name = "axi4_non_blocking_qos_write_read_test",
                                 uvm_component parent = null);
  super.new(name, parent);
endfunction : new


//--------------------------------------------------------------------------------------------
// Function: setup_axi4_master_agent_cfg
// Setup the axi4_master agent configuration with the required values
// and store the handle into the config_db
//--------------------------------------------------------------------------------------------

function void axi4_non_blocking_qos_write_read_test::setup_axi4_master_agent_cfg();
super.setup_axi4_master_agent_cfg();
  foreach(axi4_env_cfg_h.axi4_master_agent_cfg_h[i])begin
// Disable QoS mode to prevent timeout issues in qos loop
axi4_env_cfg_h.axi4_master_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE;
end
endfunction: setup_axi4_master_agent_cfg


// Function: setup_axi4_slave_agents_cfg
// Setup the axi4_slave agent(s) configuration with the required values
// and store the handle into the config_db
//--------------------------------------------------------------------------------------------
function void axi4_non_blocking_qos_write_read_test::setup_axi4_slave_agent_cfg();
  super.setup_axi4_slave_agent_cfg();
 //  axi4_env_cfg_h.axi4_slave_agent_cfg_h = new[axi4_env_cfg_h.no_of_slaves];
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i])begin
    // Disable QoS mode to prevent timeout issues in qos loop
    axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].qos_mode_type = QOS_MODE_DISABLE; 
  end
endfunction: setup_axi4_slave_agent_cfg


//--------------------------------------------------------------------------------------------
// Task: run_phase
// Creates the axi4_virtual_nbk_qos_write_read_seq sequence and starts the write and read virtual sequences
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_non_blocking_qos_write_read_test::run_phase(uvm_phase phase);

  axi4_virtual_nbk_qos_write_read_seq_h = axi4_virtual_nbk_qos_write_read_seq::type_id::create("axi4_virtual_nbk_qos_write_read_seq_h");
  `uvm_info(get_type_name(),$sformatf("axi4_non_blocking_qos_write_read_test"),UVM_LOW);
  phase.raise_objection(this);
  axi4_virtual_nbk_qos_write_read_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
  
  phase.drop_objection(this);

endtask : run_phase

`endif



