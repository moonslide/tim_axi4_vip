`ifndef AXI4_SLAVE_X_INJECT_SEQ_INCLUDED_
`define AXI4_SLAVE_X_INJECT_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_x_inject_seq
// Slave sequence for injecting X values on slave response signals
//--------------------------------------------------------------------------------------------
class axi4_slave_x_inject_seq extends axi4_slave_write_seq;
  `uvm_object_utils(axi4_slave_x_inject_seq)

  // X injection control
  int x_inject_cycles = 3;
  bit enable_bvalid_x = 0;
  bit enable_bresp_x = 0;
  bit enable_rvalid_x = 0;
  bit enable_rdata_x = 0;
  
  // Constructor
  extern function new(string name ="axi4_slave_x_inject_seq");
  // Main body task
  extern virtual task body();
  
  // X injection tasks for different signals
  extern task inject_x_on_bvalid();
  extern task inject_x_on_bresp();
  extern task inject_x_on_rvalid();
  extern task inject_x_on_rdata();
  
endclass : axi4_slave_x_inject_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_slave_x_inject_seq::new(string name ="axi4_slave_x_inject_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Main sequence body
//--------------------------------------------------------------------------------------------
task axi4_slave_x_inject_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), "Starting Slave X Injection Sequence", UVM_MEDIUM)
  
  // Inject X based on enabled flags
  if(enable_bvalid_x) inject_x_on_bvalid();
  if(enable_bresp_x) inject_x_on_bresp();
  if(enable_rvalid_x) inject_x_on_rvalid();
  if(enable_rdata_x) inject_x_on_rdata();
  
  `uvm_info(get_type_name(), "Completed Slave X Injection Sequence", UVM_MEDIUM)
endtask : body

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_bvalid
// Inject X on BVALID signal
//--------------------------------------------------------------------------------------------
task axi4_slave_x_inject_seq::inject_x_on_bvalid();
  `uvm_info(get_type_name(), $sformatf("Configuring BVALID X injection for %0d cycles", x_inject_cycles), UVM_MEDIUM)
  
  // Set config_db for slave driver proxy to trigger X injection
  uvm_config_db#(bit)::set(null, "*", "x_inject_slave_bvalid", 1);
  uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles);
  
  // Wait for injection to complete
  #(x_inject_cycles * 10ns);
  
  // Clear the flag
  uvm_config_db#(bit)::set(null, "*", "x_inject_slave_bvalid", 0);
  
  `uvm_info(get_type_name(), "BVALID X injection configured", UVM_HIGH)
endtask

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_bresp
// Inject X on BRESP signal
//--------------------------------------------------------------------------------------------
task axi4_slave_x_inject_seq::inject_x_on_bresp();
  `uvm_info(get_type_name(), $sformatf("Configuring BRESP X injection for %0d cycles", x_inject_cycles), UVM_MEDIUM)
  
  // Set config_db for slave driver proxy to trigger X injection
  uvm_config_db#(bit)::set(null, "*", "x_inject_slave_bresp", 1);
  uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles);
  
  // Wait for injection to complete
  #(x_inject_cycles * 10ns);
  
  // Clear the flag
  uvm_config_db#(bit)::set(null, "*", "x_inject_slave_bresp", 0);
  
  `uvm_info(get_type_name(), "BRESP X injection configured", UVM_HIGH)
endtask

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_rvalid
// Inject X on RVALID signal
//--------------------------------------------------------------------------------------------
task axi4_slave_x_inject_seq::inject_x_on_rvalid();
  `uvm_info(get_type_name(), $sformatf("Configuring RVALID X injection for %0d cycles", x_inject_cycles), UVM_MEDIUM)
  
  // Set config_db for slave driver proxy to trigger X injection
  uvm_config_db#(bit)::set(null, "*", "x_inject_slave_rvalid", 1);
  uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles);
  
  // Wait for injection to complete
  #(x_inject_cycles * 10ns);
  
  // Clear the flag
  uvm_config_db#(bit)::set(null, "*", "x_inject_slave_rvalid", 0);
  
  `uvm_info(get_type_name(), "RVALID X injection configured", UVM_HIGH)
endtask

//--------------------------------------------------------------------------------------------
// Task: inject_x_on_rdata
// Inject X on RDATA signal
//--------------------------------------------------------------------------------------------
task axi4_slave_x_inject_seq::inject_x_on_rdata();
  `uvm_info(get_type_name(), $sformatf("Configuring RDATA X injection for %0d cycles", x_inject_cycles), UVM_MEDIUM)
  
  // Set config_db for slave driver proxy to trigger X injection
  uvm_config_db#(bit)::set(null, "*", "x_inject_slave_rdata", 1);
  uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles);
  
  // Wait for injection to complete
  #(x_inject_cycles * 10ns);
  
  // Clear the flag
  uvm_config_db#(bit)::set(null, "*", "x_inject_slave_rdata", 0);
  
  `uvm_info(get_type_name(), "RDATA X injection configured", UVM_HIGH)
endtask

`endif