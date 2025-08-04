`ifndef AXI4_MASTER_QOS_USER_COVERAGE_INCLUDED_
`define AXI4_MASTER_QOS_USER_COVERAGE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_user_coverage
// Coverage collector for QoS and USER signals in AXI4 transactions
//--------------------------------------------------------------------------------------------
class axi4_master_qos_user_coverage extends uvm_subscriber #(axi4_master_tx);
  `uvm_component_utils(axi4_master_qos_user_coverage)
  
  // Configuration handle
  axi4_master_agent_config axi4_master_agent_cfg_h;
  
  // Transaction handle for sampling
  axi4_master_tx trans;
  
  //-------------------------------------------------------
  // Covergroup: qos_coverage
  // Covers QoS signal values and transitions
  //-------------------------------------------------------
  covergroup qos_coverage;
    option.per_instance = 1;
    
    // Write QoS values
    awqos_values: coverpoint trans.awqos {
      option.comment = "Write QoS values coverage";
      bins zero = {0};
      bins low_priority = {[1:3]};
      bins med_priority = {[4:7]};
      bins high_priority = {[8:11]};
      bins critical_priority = {[12:15]};
      bins all_values[] = {[0:15]};
    }
    
    // Read QoS values
    arqos_values: coverpoint trans.arqos {
      option.comment = "Read QoS values coverage";
      bins zero = {0};
      bins low_priority = {[1:3]};
      bins med_priority = {[4:7]};
      bins high_priority = {[8:11]};
      bins critical_priority = {[12:15]};
      bins all_values[] = {[0:15]};
    }
    
    // QoS transitions for writes
    awqos_transitions: coverpoint trans.awqos {
      option.comment = "Write QoS transition coverage";
      bins low_to_high = (0 => 15);
      bins high_to_low = (15 => 0);
      bins incremental = ([0:14] => [1:15]);
      bins decremental = ([1:15] => [0:14]);
    }
    
    // QoS transitions for reads
    arqos_transitions: coverpoint trans.arqos {
      option.comment = "Read QoS transition coverage";
      bins low_to_high = (0 => 15);
      bins high_to_low = (15 => 0);
      bins incremental = ([0:14] => [1:15]);
      bins decremental = ([1:15] => [0:14]);
    }
    
    // Cross coverage: QoS vs transaction type
    qos_vs_txtype: cross trans.tx_type, trans.awqos, trans.arqos {
      option.comment = "QoS values across transaction types";
      ignore_bins ignore_write_arqos = binsof(trans.tx_type) intersect {WRITE} && binsof(trans.arqos);
      ignore_bins ignore_read_awqos = binsof(trans.tx_type) intersect {READ} && binsof(trans.awqos);
    }
    
  endgroup : qos_coverage
  
  //-------------------------------------------------------
  // Covergroup: user_coverage
  // Covers USER signal patterns and values
  //-------------------------------------------------------
  covergroup user_coverage;
    option.per_instance = 1;
    
    // AWUSER patterns
    awuser_patterns: coverpoint trans.awuser[7:0] {
      option.comment = "Write address USER signal patterns (LSB 8 bits)";
      bins zero = {8'h00};
      bins ones = {8'hFF};
      bins alternating1 = {8'hAA};
      bins alternating2 = {8'h55};
      bins walking_ones[] = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
    }
    
    // ARUSER patterns
    aruser_patterns: coverpoint trans.aruser[7:0] {
      option.comment = "Read address USER signal patterns (LSB 8 bits)";
      bins zero = {8'h00};
      bins ones = {8'hFF};
      bins alternating1 = {8'hAA};
      bins alternating2 = {8'h55};
      bins walking_ones[] = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
    }
    
    // WUSER patterns (if applicable)
    wuser_patterns: coverpoint trans.wuser[7:0] {
      option.comment = "Write data USER signal patterns (LSB 8 bits)";
      bins zero = {8'h00};
      bins ones = {8'hFF};
      bins error_codes[] = {[8'h01:8'h0F]};
      bins custom_patterns[] = {8'hA5, 8'h5A};
    }
    
    // Separate coverpoints for cross coverage
    awuser_lsb: coverpoint trans.awuser[3:0] {
      option.comment = "AWUSER LSB 4 bits for cross coverage";
      bins zero = {0};
      bins nonzero[] = {[1:15]};
    }
    
  endgroup : user_coverage
  
  //-------------------------------------------------------
  // Covergroup: qos_contention_coverage
  // Covers QoS contention scenarios
  //-------------------------------------------------------
  covergroup qos_contention_coverage;
    option.per_instance = 1;
    
    // QoS contention patterns
    qos_contention: coverpoint trans.awqos {
      option.comment = "QoS values during contention";
      bins equal_priority = {8};  // Common QoS for fairness testing
      bins different_priority[] = {[0:15]};
    }
    
  endgroup : qos_contention_coverage
  
  //-------------------------------------------------------
  // Constructor and methods
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_qos_user_coverage", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void write(axi4_master_tx t);
  extern virtual function void report_phase(uvm_phase phase);
  
endclass : axi4_master_qos_user_coverage

//--------------------------------------------------------------------------------------------
// Constructor: new
//--------------------------------------------------------------------------------------------
function axi4_master_qos_user_coverage::new(string name = "axi4_master_qos_user_coverage", uvm_component parent = null);
  super.new(name, parent);
  qos_coverage = new();
  user_coverage = new();
  qos_contention_coverage = new();
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void axi4_master_qos_user_coverage::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  if(!uvm_config_db #(axi4_master_agent_config)::get(this,"","axi4_master_agent_config",axi4_master_agent_cfg_h)) begin
    `uvm_fatal("COVERAGE", "Failed to get master agent config from config DB")
  end
  
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: write
// Samples coverage when new transaction is received
//--------------------------------------------------------------------------------------------
function void axi4_master_qos_user_coverage::write(axi4_master_tx t);
  trans = t;
  
  // Sample all covergroups
  qos_coverage.sample();
  user_coverage.sample();
  qos_contention_coverage.sample();
  
  `uvm_info(get_type_name(), $sformatf("Sampled QoS/USER coverage - TxType:%s, AWQOS:0x%0h, ARQOS:0x%0h", 
                                       t.tx_type.name(), t.awqos, t.arqos), UVM_HIGH)
  
endfunction : write

//--------------------------------------------------------------------------------------------
// Function: report_phase
// Reports coverage statistics
//--------------------------------------------------------------------------------------------
function void axi4_master_qos_user_coverage::report_phase(uvm_phase phase);
  super.report_phase(phase);
  
  `uvm_info(get_type_name(), $sformatf("QoS Coverage: %.2f%%", qos_coverage.get_coverage()), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("USER Coverage: %.2f%%", user_coverage.get_coverage()), UVM_LOW)
  `uvm_info(get_type_name(), $sformatf("QoS Contention Coverage: %.2f%%", qos_contention_coverage.get_coverage()), UVM_LOW)
  
endfunction : report_phase

`endif