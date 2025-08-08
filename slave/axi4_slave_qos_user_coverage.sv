`ifndef AXI4_SLAVE_QOS_USER_COVERAGE_INCLUDED_
`define AXI4_SLAVE_QOS_USER_COVERAGE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_qos_user_coverage  
// Description: Coverage for AXI4 QoS and USER signals on slave side
//--------------------------------------------------------------------------------------------
class axi4_slave_qos_user_coverage extends uvm_subscriber#(axi4_slave_tx);
  `uvm_component_utils(axi4_slave_qos_user_coverage)

  //Variable: axi4_slave_agent_cfg_h
  //Declaring handle for axi4_slave_agent_config_c class 
  axi4_slave_agent_config axi4_slave_agent_cfg_h;

  //-------------------------------------------------------
  // Covergroup: axi4_slave_qos_cg
  // QoS (Quality of Service) signal coverage for slave
  //-------------------------------------------------------
  covergroup axi4_slave_qos_cg with function sample(axi4_slave_tx packet);
    option.per_instance = 1;
    
    // Write address QoS coverage
    AWQOS_CP: coverpoint packet.awqos {
      bins qos_values[] = {[0:15]};
      bins qos_low = {[0:3]};
      bins qos_medium_low = {[4:7]};
      bins qos_medium_high = {[8:11]};
      bins qos_high = {[12:15]};
    }
    
    // Read address QoS coverage
    ARQOS_CP: coverpoint packet.arqos {
      bins qos_values[] = {[0:15]};
      bins qos_low = {[0:3]};
      bins qos_medium_low = {[4:7]};
      bins qos_medium_high = {[8:11]};
      bins qos_high = {[12:15]};
    }
    
    // Cross coverage for write and read QoS
    AWQOS_ARQOS_CROSS: cross AWQOS_CP, ARQOS_CP {
      bins same_qos = binsof(AWQOS_CP) intersect {[0:15]} && 
                      binsof(ARQOS_CP) intersect {[0:15]} with (AWQOS_CP == ARQOS_CP);
    }
    
    // QoS vs transaction type
    TX_TYPE_CP: coverpoint packet.tx_type {
      bins write = {WRITE};
      bins read = {READ};
    }
    
    AWQOS_TX_TYPE: cross AWQOS_CP, TX_TYPE_CP {
      ignore_bins read_awqos = binsof(TX_TYPE_CP.read);
    }
    
    ARQOS_TX_TYPE: cross ARQOS_CP, TX_TYPE_CP {
      ignore_bins write_arqos = binsof(TX_TYPE_CP.write);
    }
    
  endgroup : axi4_slave_qos_cg

  //-------------------------------------------------------
  // Covergroup: axi4_slave_user_cg
  // USER signal coverage for slave
  //-------------------------------------------------------
  covergroup axi4_slave_user_cg with function sample(axi4_slave_tx packet);
    option.per_instance = 1;
    
    // Write address user coverage
    AWUSER_CP: coverpoint packet.awuser {
      bins user_zero = {0};
      bins user_one = {1};
      bins user_values[] = {[0:$]};
    }
    
    // Write data user coverage  
    WUSER_CP: coverpoint packet.wuser {
      bins user_zero = {0};
      bins user_values[] = {[0:$]};
    }
    
    // Write response user coverage
    BUSER_CP: coverpoint packet.buser {
      bins user_zero = {0};
      bins user_values[] = {[0:$]};
    }
    
    // Read address user coverage
    ARUSER_CP: coverpoint packet.aruser {
      bins user_zero = {0};
      bins user_one = {1};
      bins user_values[] = {[0:$]};
    }
    
    // Read data user coverage
    RUSER_CP: coverpoint packet.ruser {
      bins user_zero = {0};
      bins user_values[] = {[0:$]};
    }
    
    // Transaction type for USER coverage
    TX_TYPE_USER_CP: coverpoint packet.tx_type {
      bins write = {WRITE};
      bins read = {READ};
    }
    
    // Cross coverage for USER signals with transaction type
    AWUSER_TX_TYPE: cross AWUSER_CP, TX_TYPE_USER_CP {
      ignore_bins read_awuser = binsof(TX_TYPE_USER_CP.read);
    }
    
    ARUSER_TX_TYPE: cross ARUSER_CP, TX_TYPE_USER_CP {
      ignore_bins write_aruser = binsof(TX_TYPE_USER_CP.write);
    }
    
  endgroup : axi4_slave_user_cg

  //-------------------------------------------------------
  // Covergroup: axi4_slave_qos_user_combination_cg
  // Combined QoS and USER signal coverage for slave
  //-------------------------------------------------------
  covergroup axi4_slave_qos_user_combination_cg with function sample(axi4_slave_tx packet);
    option.per_instance = 1;
    
    // Write QoS with USER
    AWQOS_AWUSER: cross packet.awqos, packet.awuser {
      bins qos_high_user_set = binsof(packet.awqos) intersect {[12:15]} &&
                                binsof(packet.awuser) intersect {[1:$]};
      bins qos_low_user_zero = binsof(packet.awqos) intersect {[0:3]} &&
                                binsof(packet.awuser) intersect {0};
    }
    
    // Read QoS with USER
    ARQOS_ARUSER: cross packet.arqos, packet.aruser {
      bins qos_high_user_set = binsof(packet.arqos) intersect {[12:15]} &&
                                binsof(packet.aruser) intersect {[1:$]};
      bins qos_low_user_zero = binsof(packet.arqos) intersect {[0:3]} &&
                                binsof(packet.aruser) intersect {0};
    }
    
  endgroup : axi4_slave_qos_user_combination_cg

  //-------------------------------------------------------
  // Externally defined tasks and functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_slave_qos_user_coverage", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void write(axi4_slave_tx t);
  extern virtual function void report_phase(uvm_phase phase);

endclass : axi4_slave_qos_user_coverage

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the axi4_slave_qos_user_coverage class object
//
// Parameters:
//  name - axi4_slave_qos_user_coverage
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_slave_qos_user_coverage::new(string name = "axi4_slave_qos_user_coverage", uvm_component parent = null);
  super.new(name, parent);
  axi4_slave_qos_cg = new();
  axi4_slave_user_cg = new();
  axi4_slave_qos_user_combination_cg = new();
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// Get the configuration object
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_slave_qos_user_coverage::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  if(!uvm_config_db #(axi4_slave_agent_config)::get(this,"","axi4_slave_agent_config",axi4_slave_agent_cfg_h)) begin
    `uvm_info("COVERAGE","axi4_slave_agent_config is not set",UVM_LOW)
  end
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: write  
// Samples the coverage values
//
// Parameters:
//  t - axi4_slave_tx transaction handle
//--------------------------------------------------------------------------------------------
function void axi4_slave_qos_user_coverage::write(axi4_slave_tx t);
  
  // Sample coverage based on transaction type
  if(t.tx_type == WRITE) begin
    `uvm_info(get_type_name(), $sformatf("Sampling WRITE QoS=%0d, AWUSER=%0h", t.awqos, t.awuser), UVM_HIGH)
  end
  else if(t.tx_type == READ) begin
    `uvm_info(get_type_name(), $sformatf("Sampling READ QoS=%0d, ARUSER=%0h", t.arqos, t.aruser), UVM_HIGH)
  end
  
  // Sample all covergroups
  axi4_slave_qos_cg.sample(t);
  axi4_slave_user_cg.sample(t);
  axi4_slave_qos_user_combination_cg.sample(t);
  
endfunction : write

//--------------------------------------------------------------------------------------------
// Function: report_phase
// Reports the coverage percentage
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_slave_qos_user_coverage::report_phase(uvm_phase phase);
  `uvm_info(get_type_name(), $sformatf("AXI4 Slave QoS Coverage = %.2f %%", axi4_slave_qos_cg.get_coverage()), UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("AXI4 Slave USER Coverage = %.2f %%", axi4_slave_user_cg.get_coverage()), UVM_NONE)
  `uvm_info(get_type_name(), $sformatf("AXI4 Slave QoS-USER Combination Coverage = %.2f %%", axi4_slave_qos_user_combination_cg.get_coverage()), UVM_NONE)
endfunction : report_phase

`endif