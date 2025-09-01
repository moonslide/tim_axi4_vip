`ifndef AXI4_SLAVE_INJECT_BRESP_X_TEST_INCLUDED_
`define AXI4_SLAVE_INJECT_BRESP_X_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_inject_bresp_x_test
// Test for X injection on slave BRESP signal (fixed to avoid deadlock)
//--------------------------------------------------------------------------------------------
class axi4_slave_inject_bresp_x_test extends axi4_error_inject_base_test;
  `uvm_component_utils(axi4_slave_inject_bresp_x_test)

  // Virtual sequence handles
  axi4_virtual_dummy_slave_seq dummy_slave_seq_h;
  axi4_master_bk_write_seq master_write_seq_h;

  //--------------------------------------------------------------------------------------------
  // Construct: new
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_slave_inject_bresp_x_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Function: setup_axi4_env_cfg
  // Override to configure environment for X injection test
  //--------------------------------------------------------------------------------------------
  function void setup_axi4_env_cfg();
    super.setup_axi4_env_cfg();
    
    // Set to write only mode
    axi4_env_cfg_h.write_read_mode_h = ONLY_WRITE_DATA;
    
    // Keep slaves ACTIVE for X injection - the BFM needs to be active to inject X values
  endfunction : setup_axi4_env_cfg

  //--------------------------------------------------------------------------------------------
  // Task: run_phase
  // Run the BRESP X injection test without deadlock
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting Slave BRESP X Injection Test", UVM_LOW)
    
    // Start dummy slave sequences in background to handle responses
    if(axi4_env_h.axi4_virtual_seqr_h.axi4_slave_write_seqr_h != null) begin
      `uvm_info(get_type_name(), "Starting dummy slave sequences in background", UVM_LOW)
      dummy_slave_seq_h = axi4_virtual_dummy_slave_seq::type_id::create("dummy_slave_seq_h");
      dummy_slave_seq_h.num_dummy_sequences = 50; // Enough for the test duration
      fork
        dummy_slave_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
      join_none
      #10ns; // Let dummy sequences get started
    end
    
    // Configure X injection for BRESP
    `uvm_info(get_type_name(), "Configuring BRESP X injection", UVM_LOW)
    uvm_config_db#(bit)::set(null, "*", "x_inject_slave_bresp", 1);
    uvm_config_db#(int)::set(null, "*", "x_inject_cycles", 3);
    
    // Run master write transactions
    `uvm_info(get_type_name(), "Starting master write transactions", UVM_LOW)
    repeat(5) begin
      master_write_seq_h = axi4_master_bk_write_seq::type_id::create("master_write_seq_h");
      master_write_seq_h.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h);
      #10ns;
    end
    
    // Clear X injection
    uvm_config_db#(bit)::set(null, "*", "x_inject_slave_bresp", 0);
    
    // Send recovery transactions
    #100ns;
    `uvm_info(get_type_name(), "Sending recovery transactions", UVM_LOW)
    repeat(2) begin
      master_write_seq_h = axi4_master_bk_write_seq::type_id::create("recovery_write");
      master_write_seq_h.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h);
      #10ns;
    end
    
    #100ns; // Allow time for completion
    
    `uvm_info(get_type_name(), "Completed Slave BRESP X Injection Test", UVM_LOW)
    
    phase.drop_objection(this);
  endtask : run_phase

endclass : axi4_slave_inject_bresp_x_test

`endif