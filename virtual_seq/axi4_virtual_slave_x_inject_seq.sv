`ifndef AXI4_VIRTUAL_SLAVE_X_INJECT_SEQ_INCLUDED_
`define AXI4_VIRTUAL_SLAVE_X_INJECT_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_slave_x_inject_seq
// Virtual sequence for slave X injection testing
//--------------------------------------------------------------------------------------------
class axi4_virtual_slave_x_inject_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_slave_x_inject_seq)
  
  axi4_master_slave_inject_write_seq axi4_master_slave_inject_write_seq_h;
  axi4_master_slave_inject_read_seq axi4_master_slave_inject_read_seq_h;
  
  extern function new(string name = "axi4_virtual_slave_x_inject_seq");
  extern task body();
  
endclass : axi4_virtual_slave_x_inject_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_virtual_slave_x_inject_seq::new(string name = "axi4_virtual_slave_x_inject_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body  
// Runs master and slave sequences for X injection testing
//--------------------------------------------------------------------------------------------
task axi4_virtual_slave_x_inject_seq::body();
  `uvm_info(get_type_name(), "Starting Virtual Slave X Injection Sequence", UVM_LOW)
  
  // Create sequences
  axi4_master_slave_inject_write_seq_h = axi4_master_slave_inject_write_seq::type_id::create("axi4_master_slave_inject_write_seq_h");
  axi4_master_slave_inject_read_seq_h = axi4_master_slave_inject_read_seq::type_id::create("axi4_master_slave_inject_read_seq_h");
  
  // This will be overridden by specific test sequences
  `uvm_info(get_type_name(), "Base virtual sequence - override in specific tests", UVM_LOW)
  
endtask : body

`endif

//--------------------------------------------------------------------------------------------
// Specific virtual sequences for each slave X injection signal
//--------------------------------------------------------------------------------------------

`ifndef AXI4_VIRTUAL_SLAVE_BVALID_X_SEQ_INCLUDED_
`define AXI4_VIRTUAL_SLAVE_BVALID_X_SEQ_INCLUDED_

class axi4_virtual_slave_bvalid_x_seq extends axi4_virtual_slave_x_inject_seq;
  `uvm_object_utils(axi4_virtual_slave_bvalid_x_seq)
  
  function new(string name = "axi4_virtual_slave_bvalid_x_seq");
    super.new(name);
  endfunction
  
  task body();
    `uvm_info(get_type_name(), "Starting BVALID X Injection Virtual Sequence", UVM_LOW)
    
    // Simple X injection without complex sequencing
    `uvm_info(get_type_name(), "Injecting X on BVALID", UVM_LOW)
    uvm_config_db#(bit)::set(null, "*", "x_inject_slave_bvalid", 1);
    uvm_config_db#(int)::set(null, "*", "x_inject_cycles", 3);
    
    // Wait for injection
    #100ns;
    
    // Clear injection
    uvm_config_db#(bit)::set(null, "*", "x_inject_slave_bvalid", 0);
    
    // Wait a bit more
    #100ns;
    
    `uvm_info(get_type_name(), "Completed BVALID X Injection Virtual Sequence", UVM_LOW)
  endtask
endclass

`endif

`ifndef AXI4_VIRTUAL_SLAVE_BRESP_X_SEQ_INCLUDED_
`define AXI4_VIRTUAL_SLAVE_BRESP_X_SEQ_INCLUDED_

class axi4_virtual_slave_bresp_x_seq extends axi4_virtual_slave_x_inject_seq;
  `uvm_object_utils(axi4_virtual_slave_bresp_x_seq)
  
  function new(string name = "axi4_virtual_slave_bresp_x_seq");
    super.new(name);
  endfunction
  
  task body();
    `uvm_info(get_type_name(), "Starting BRESP X Injection Virtual Sequence", UVM_LOW)
    
    // Simple X injection
    `uvm_info(get_type_name(), "Injecting X on BRESP", UVM_LOW)
    uvm_config_db#(bit)::set(null, "*", "x_inject_slave_bresp", 1);
    uvm_config_db#(int)::set(null, "*", "x_inject_cycles", 3);
    
    // Wait for injection
    #100ns;
    
    // Clear injection
    uvm_config_db#(bit)::set(null, "*", "x_inject_slave_bresp", 0);
    
    // Wait a bit more
    #100ns;
    
    `uvm_info(get_type_name(), "Completed BRESP X Injection Virtual Sequence", UVM_LOW)
  endtask
endclass

`endif

`ifndef AXI4_VIRTUAL_SLAVE_RVALID_X_SEQ_INCLUDED_
`define AXI4_VIRTUAL_SLAVE_RVALID_X_SEQ_INCLUDED_

class axi4_virtual_slave_rvalid_x_seq extends axi4_virtual_slave_x_inject_seq;
  `uvm_object_utils(axi4_virtual_slave_rvalid_x_seq)
  
  function new(string name = "axi4_virtual_slave_rvalid_x_seq");
    super.new(name);
  endfunction
  
  task body();
    `uvm_info(get_type_name(), "Starting RVALID X Injection Virtual Sequence", UVM_LOW)
    
    // Simple X injection
    `uvm_info(get_type_name(), "Injecting X on RVALID", UVM_LOW)
    uvm_config_db#(bit)::set(null, "*", "x_inject_slave_rvalid", 1);
    uvm_config_db#(int)::set(null, "*", "x_inject_cycles", 3);
    
    // Wait for injection
    #100ns;
    
    // Clear injection
    uvm_config_db#(bit)::set(null, "*", "x_inject_slave_rvalid", 0);
    
    // Wait a bit more
    #100ns;
    
    `uvm_info(get_type_name(), "Completed RVALID X Injection Virtual Sequence", UVM_LOW)
  endtask
endclass

`endif

`ifndef AXI4_VIRTUAL_SLAVE_RDATA_X_SEQ_INCLUDED_
`define AXI4_VIRTUAL_SLAVE_RDATA_X_SEQ_INCLUDED_

class axi4_virtual_slave_rdata_x_seq extends axi4_virtual_slave_x_inject_seq;
  `uvm_object_utils(axi4_virtual_slave_rdata_x_seq)
  
  function new(string name = "axi4_virtual_slave_rdata_x_seq");
    super.new(name);
  endfunction
  
  task body();
    `uvm_info(get_type_name(), "Starting RDATA X Injection Virtual Sequence", UVM_LOW)
    
    // Simple X injection
    `uvm_info(get_type_name(), "Injecting X on RDATA", UVM_LOW)
    uvm_config_db#(bit)::set(null, "*", "x_inject_slave_rdata", 1);
    uvm_config_db#(int)::set(null, "*", "x_inject_cycles", 3);
    
    // Wait for injection
    #100ns;
    
    // Clear injection
    uvm_config_db#(bit)::set(null, "*", "x_inject_slave_rdata", 0);
    
    // Wait a bit more
    #100ns;
    
    `uvm_info(get_type_name(), "Completed RDATA X Injection Virtual Sequence", UVM_LOW)
  endtask
endclass

`endif