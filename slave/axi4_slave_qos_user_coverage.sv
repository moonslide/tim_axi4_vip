`ifndef AXI4_SLAVE_QOS_USER_COVERAGE_INCLUDED_
`define AXI4_SLAVE_QOS_USER_COVERAGE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_qos_user_coverage
// Coverage collector for QoS and USER signals at slave interface
//--------------------------------------------------------------------------------------------
class axi4_slave_qos_user_coverage extends uvm_subscriber #(axi4_slave_tx);
  `uvm_component_utils(axi4_slave_qos_user_coverage)
  
  // Configuration handle
  axi4_slave_agent_config axi4_slave_agent_cfg_h;
  
  // Transaction handle for sampling
  axi4_slave_tx trans;
  
  //-------------------------------------------------------
  // Covergroup: slave_qos_coverage
  // Covers QoS signal values received at slave
  //-------------------------------------------------------
  covergroup slave_qos_coverage;
    option.per_instance = 1;
    
    // Write QoS values received
    awqos_received: coverpoint trans.awqos {
      option.comment = "Write QoS values received at slave";
      bins zero = {0};
      bins low_priority = {[1:3]};
      bins med_priority = {[4:7]};
      bins high_priority = {[8:11]};
      bins critical_priority = {[12:15]};
      bins all_values[] = {[0:15]};
    }
    
    // Read QoS values received
    arqos_received: coverpoint trans.arqos {
      option.comment = "Read QoS values received at slave";
      bins zero = {0};
      bins low_priority = {[1:3]};
      bins med_priority = {[4:7]};
      bins high_priority = {[8:11]};
      bins critical_priority = {[12:15]};
      bins all_values[] = {[0:15]};
    }
    
    // QoS vs Response correlation
    qos_vs_bresp: cross trans.awqos, trans.bresp {
      option.comment = "QoS vs write response correlation";
    }
    
    qos_vs_rresp: cross trans.arqos, trans.rresp {
      option.comment = "QoS vs read response correlation";
    }
    
  endgroup : slave_qos_coverage
  
  //-------------------------------------------------------
  // Covergroup: slave_user_coverage
  // Covers USER signal values and response patterns
  //-------------------------------------------------------
  covergroup slave_user_coverage;
    option.per_instance = 1;
    
    // BUSER response patterns
    buser_patterns: coverpoint trans.buser[7:0] {
      option.comment = "Write response USER signal patterns (LSB 8 bits)";
      bins zero = {8'h00};
      bins error_codes[] = {[8'h01:8'h0F]};
      bins custom_status[] = {8'hA0, 8'hA1, 8'hA2, 8'hA3};
      bins parity_error = {8'h80};
      bins security_error = {8'h40};
    }
    
    // RUSER response patterns  
    ruser_patterns: coverpoint trans.ruser[7:0] {
      option.comment = "Read response USER signal patterns (LSB 8 bits)";
      bins zero = {8'h00};
      bins ecc_single_bit = {8'h01};
      bins ecc_double_bit = {8'h02};
      bins data_attributes[] = {[8'h10:8'h1F]};
    }
    
    // AWUSER received patterns
    awuser_received: coverpoint trans.awuser[7:0] {
      option.comment = "Write address USER patterns received (LSB 8 bits)";
      bins zero = {8'h00};
      bins security_levels[] = {[8'h00:8'h0F]};
      bins transaction_tags[] = {[8'h10:8'h1F]};
    }
    
    // ARUSER received patterns
    aruser_received: coverpoint trans.aruser[7:0] {
      option.comment = "Read address USER patterns received (LSB 8 bits)";
      bins zero = {8'h00};
      bins prefetch_hints[] = {8'h01, 8'h02, 8'h04, 8'h08};
      bins cache_hints[] = {[8'h10:8'h1F]};
    }
    
    // Separate coverpoints for cross coverage
    awuser_lsb: coverpoint trans.awuser[3:0] {
      option.comment = "AWUSER LSB 4 bits";
      bins values[] = {[0:15]};
    }
    
    buser_lsb: coverpoint trans.buser[3:0] {
      option.comment = "BUSER LSB 4 bits";
      bins values[] = {[0:15]};
    }
    
    aruser_lsb: coverpoint trans.aruser[3:0] {
      option.comment = "ARUSER LSB 4 bits";
      bins values[] = {[0:15]};
    }
    
    ruser_lsb: coverpoint trans.ruser[3:0] {
      option.comment = "RUSER LSB 4 bits";
      bins values[] = {[0:15]};
    }
    
    // USER signal correlations
    awuser_vs_buser: cross awuser_lsb, buser_lsb {
      option.comment = "AWUSER vs BUSER correlation";
    }
    
    aruser_vs_ruser: cross aruser_lsb, ruser_lsb {
      option.comment = "ARUSER vs RUSER correlation";
    }
    
  endgroup : slave_user_coverage
  
  //-------------------------------------------------------
  // Covergroup: slave_access_coverage
  // Covers slave access patterns with QoS/USER
  //-------------------------------------------------------
  covergroup slave_access_coverage;
    option.per_instance = 1;
    
    // Access type with QoS
    access_qos: coverpoint trans.awqos {
      option.comment = "QoS during slave access";
      bins qos_levels[] = {[0:15]};
    }
    
  endgroup : slave_access_coverage
  
  //-------------------------------------------------------
  // Constructor and methods
  //-------------------------------------------------------
  extern function new(string name = "axi4_slave_qos_user_coverage", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void write(axi4_slave_tx t);
  extern virtual function void report_phase(uvm_phase phase);
  
endclass : axi4_slave_qos_user_coverage

//--------------------------------------------------------------------------------------------
// Constructor: new
//--------------------------------------------------------------------------------------------
function axi4_slave_qos_user_coverage::new(string name = "axi4_slave_qos_user_coverage", uvm_component parent = null);
  super.new(name, parent);
  slave_qos_coverage = new();
  slave_user_coverage = new();
  slave_access_coverage = new();
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_slave_qos_user_coverage::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  if(!uvm_config_db #(axi4_slave_agent_config)::get(this,"","axi4_slave_agent_config",axi4_slave_agent_cfg_h)) begin
    `uvm_fatal("COVERAGE", "Failed to get slave agent config from config DB")
  end
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: write
// Samples coverage when new transaction is received
//--------------------------------------------------------------------------------------------
function void axi4_slave_qos_user_coverage::write(axi4_slave_tx t);
  trans = t;
  
  // Sample all covergroups
  slave_qos_coverage.sample();
  slave_user_coverage.sample();
  slave_access_coverage.sample();
  
  `uvm_info(get_type_name(), $sformatf("Sampled slave QoS/USER coverage - AWQOS:0x%0h, ARQOS:0x%0h, BRESP:%s, RRESP:%s", 
                                       t.awqos, t.arqos, t.bresp.name(), t.rresp.name()), UVM_HIGH)
  
endfunction : write

//--------------------------------------------------------------------------------------------
// Function: report_phase
// Reports coverage statistics
//--------------------------------------------------------------------------------------------
function void axi4_slave_qos_user_coverage::report_phase(uvm_phase phase);
  super.report_phase(phase);
  
  `uvm_info(get_type_name(), $sformatf("Slave QoS Coverage: %.2f%%", slave_qos_coverage.get_coverage()), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Slave USER Coverage: %.2f%%", slave_user_coverage.get_coverage()), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("Slave Access Coverage: %.2f%%", slave_access_coverage.get_coverage()), UVM_LOW)
  
endfunction : report_phase

`endif