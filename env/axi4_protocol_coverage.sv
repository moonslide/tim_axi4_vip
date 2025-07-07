`ifndef AXI4_PROTOCOL_COVERAGE_INCLUDED_
`define AXI4_PROTOCOL_COVERAGE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_protocol_coverage
// Functional coverage for AXI4 protocol compliance, ID management, and error scenarios
//--------------------------------------------------------------------------------------------
class axi4_protocol_coverage extends uvm_subscriber#(axi4_master_tx);
  `uvm_component_utils(axi4_protocol_coverage)

  // Configuration handle
  axi4_env_config axi4_env_cfg_h;
  
  // Transaction handle
  axi4_master_tx master_tx_h;
  
  // Coverage groups
  covergroup cg_id_management;
    // Write ID coverage
    cp_awid: coverpoint master_tx_h.awid {
      bins awid_values[] = {[0:15]};
    }
    
    // Read ID coverage  
    cp_arid: coverpoint master_tx_h.arid {
      bins arid_values[] = {[0:15]};
    }
    
    // Same ID consecutive transactions
    cp_same_id_writes: coverpoint master_tx_h.awid {
      bins same_id_pattern = (AWID_11 => AWID_11);
    }
    
    cp_same_id_reads: coverpoint master_tx_h.arid {
      bins same_id_pattern = (ARID_14 => ARID_14);
    }
    
    // Different ID consecutive transactions
    cp_diff_id_writes: coverpoint master_tx_h.awid {
      bins diff_id_pattern = (AWID_12 => AWID_13);
    }
    
    cp_diff_id_reads: coverpoint master_tx_h.arid {
      bins diff_id_pattern = (ARID_10 => ARID_11);
    }
  endgroup : cg_id_management
  
  covergroup cg_protocol_violations;
    // AWLEN violations
    cp_awlen_violation: coverpoint master_tx_h.awlen {
      bins normal_len = {[0:255]};
      illegal_bins out_of_spec = {[256:$]};
    }
    
    // ARLEN violations
    cp_arlen_violation: coverpoint master_tx_h.arlen {
      bins normal_len = {[0:255]};
      illegal_bins out_of_spec = {[256:$]};
    }
    
    // Exclusive access coverage
    cp_exclusive_write: coverpoint master_tx_h.awlock {
      bins normal_write = {WRITE_NORMAL_ACCESS};
      bins exclusive_write = {WRITE_EXCLUSIVE_ACCESS};
    }
    
    cp_exclusive_read: coverpoint master_tx_h.arlock {
      bins normal_read = {READ_NORMAL_ACCESS};
      bins exclusive_read = {READ_EXCLUSIVE_ACCESS};
    }
    
    // Burst length and type cross coverage
    cp_burst_len_x_type: cross master_tx_h.awlen, master_tx_h.awburst {
      bins single_beat = binsof(master_tx_h.awlen) intersect {0};
      bins multi_beat = binsof(master_tx_h.awlen) intersect {[1:255]};
    }
  endgroup : cg_protocol_violations
  
  covergroup cg_error_responses;
    // Write response types
    cp_bresp: coverpoint master_tx_h.bresp {
      bins okay = {WRITE_OKAY};
      bins exokay = {WRITE_EXOKAY};
      bins slverr = {WRITE_SLVERR};
      bins decerr = {WRITE_DECERR};
    }
    
    // Read response types
    cp_rresp: coverpoint master_tx_h.rresp {
      bins okay = {READ_OKAY};
      bins exokay = {READ_EXOKAY};
      bins slverr = {READ_SLVERR};
      bins decerr = {READ_DECERR};
    }
    
    // Response cross with exclusive access
    cp_exclusive_write_resp: cross master_tx_h.awlock, master_tx_h.bresp {
      bins exclusive_success = binsof(master_tx_h.awlock) intersect {WRITE_EXCLUSIVE_ACCESS} &&
                              binsof(master_tx_h.bresp) intersect {WRITE_EXOKAY};
      bins exclusive_fail = binsof(master_tx_h.awlock) intersect {WRITE_EXCLUSIVE_ACCESS} &&
                           binsof(master_tx_h.bresp) intersect {WRITE_OKAY};
    }
    
    cp_exclusive_read_resp: cross master_tx_h.arlock, master_tx_h.rresp {
      bins exclusive_success = binsof(master_tx_h.arlock) intersect {READ_EXCLUSIVE_ACCESS} &&
                              binsof(master_tx_h.rresp) intersect {READ_EXOKAY};
      bins exclusive_fail = binsof(master_tx_h.arlock) intersect {READ_EXCLUSIVE_ACCESS} &&
                           binsof(master_tx_h.rresp) intersect {READ_OKAY};
    }
  endgroup : cg_error_responses
  
  covergroup cg_address_alignment;
    // Address alignment with size
    cp_write_addr_align: coverpoint (master_tx_h.awaddr & ((1 << master_tx_h.awsize) - 1)) {
      bins aligned = {0};
      bins unaligned = {[1:$]};
    }
    
    cp_read_addr_align: coverpoint (master_tx_h.araddr & ((1 << master_tx_h.arsize) - 1)) {
      bins aligned = {0};
      bins unaligned = {[1:$]};
    }
    
    // Address boundary crossing
    cp_4k_boundary: coverpoint ((master_tx_h.awaddr & 'hFFF) + 
                               (master_tx_h.awlen + 1) * (1 << master_tx_h.awsize)) {
      bins no_cross = {[0:'hFFF]};
      bins crosses_4k = {['h1000:$]};
    }
  endgroup : cg_address_alignment
  
  // Constructor
  extern function new(string name = "axi4_protocol_coverage", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void write(axi4_master_tx t);
  extern virtual function void report_phase(uvm_phase phase);
  
endclass : axi4_protocol_coverage

function axi4_protocol_coverage::new(string name = "axi4_protocol_coverage", uvm_component parent = null);
  super.new(name, parent);
  cg_id_management = new();
  cg_protocol_violations = new();
  cg_error_responses = new();
  cg_address_alignment = new();
endfunction : new

function void axi4_protocol_coverage::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db#(axi4_env_config)::get(this, "", "axi4_env_config", axi4_env_cfg_h)) begin
    `uvm_fatal("CONFIG", "Cannot get axi4_env_config from uvm_config_db")
  end
endfunction : build_phase

function void axi4_protocol_coverage::write(axi4_master_tx t);
  master_tx_h = t;
  
  // Sample all coverage groups
  cg_id_management.sample();
  cg_protocol_violations.sample();
  cg_error_responses.sample();
  cg_address_alignment.sample();
endfunction : write

function void axi4_protocol_coverage::report_phase(uvm_phase phase);
  real total_coverage;
  
  total_coverage = (cg_id_management.get_coverage() + 
                   cg_protocol_violations.get_coverage() + 
                   cg_error_responses.get_coverage() + 
                   cg_address_alignment.get_coverage()) / 4.0;
  
  `uvm_info(get_type_name(), $sformatf("================================"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("AXI4 Protocol Coverage Summary:"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("================================"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("ID Management Coverage      : %.2f%%", cg_id_management.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Protocol Violations Coverage: %.2f%%", cg_protocol_violations.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Error Responses Coverage    : %.2f%%", cg_error_responses.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Address Alignment Coverage  : %.2f%%", cg_address_alignment.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("================================"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Total Protocol Coverage     : %.2f%%", total_coverage), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("================================"), UVM_LOW);
endfunction : report_phase

`endif