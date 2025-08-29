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
  
  // Exclusive Access Coverage Group
  covergroup cg_exclusive_access;
    // Exclusive read coverage
    cp_exclusive_read: coverpoint master_tx_h.arlock {
      bins normal_read = {READ_NORMAL_ACCESS};
      bins exclusive_read = {READ_EXCLUSIVE_ACCESS};
    }
    
    // Exclusive write coverage
    cp_exclusive_write: coverpoint master_tx_h.awlock {
      bins normal_write = {WRITE_NORMAL_ACCESS};
      bins exclusive_write = {WRITE_EXCLUSIVE_ACCESS};
    }
    
    // Exclusive read/write combinations
    cp_exclusive_rw_combo: cross cp_exclusive_read, cp_exclusive_write;
    
    // Exclusive access responses
    cp_exclusive_read_resp: coverpoint master_tx_h.rresp {
      bins okay_resp = {READ_OKAY};
      bins exokay_resp = {READ_EXOKAY};
      bins slverr_resp = {READ_SLVERR};
      bins decerr_resp = {READ_DECERR};
    }
    
    cp_exclusive_write_resp: coverpoint master_tx_h.bresp {
      bins okay_resp = {WRITE_OKAY};
      bins exokay_resp = {WRITE_EXOKAY};
      bins slverr_resp = {WRITE_SLVERR};
      bins decerr_resp = {WRITE_DECERR};
    }
    
    // Cross coverage: exclusive access type with response
    cp_excl_read_with_resp: cross cp_exclusive_read, cp_exclusive_read_resp {
      bins exclusive_read_exokay = binsof(cp_exclusive_read.exclusive_read) && binsof(cp_exclusive_read_resp.exokay_resp);
      bins exclusive_read_okay = binsof(cp_exclusive_read.exclusive_read) && binsof(cp_exclusive_read_resp.okay_resp);
      bins normal_read_okay = binsof(cp_exclusive_read.normal_read) && binsof(cp_exclusive_read_resp.okay_resp);
    }
    
    cp_excl_write_with_resp: cross cp_exclusive_write, cp_exclusive_write_resp {
      bins exclusive_write_exokay = binsof(cp_exclusive_write.exclusive_write) && binsof(cp_exclusive_write_resp.exokay_resp);
      bins exclusive_write_okay = binsof(cp_exclusive_write.exclusive_write) && binsof(cp_exclusive_write_resp.okay_resp);
      bins normal_write_okay = binsof(cp_exclusive_write.normal_write) && binsof(cp_exclusive_write_resp.okay_resp);
    }
    
    // Exclusive access addresses
    cp_exclusive_addr: coverpoint master_tx_h.awaddr {
      bins ddr_range = {[64'h0000_0100_0000_0000:64'h0000_0107_FFFF_FFFF]};
      bins peripheral_range = {[64'h0000_0010_0000_0000:64'h0000_0010_000F_FFFF]};
      bins fuse_range = {[64'h0000_0020_0000_0000:64'h0000_0020_0000_0FFF]};
    }
    
    // Cross coverage: exclusive access with address ranges
    cp_excl_write_addr: cross cp_exclusive_write, cp_exclusive_addr {
      bins exclusive_ddr = binsof(cp_exclusive_write.exclusive_write) && binsof(cp_exclusive_addr.ddr_range);
      bins exclusive_peripheral = binsof(cp_exclusive_write.exclusive_write) && binsof(cp_exclusive_addr.peripheral_range);
    }
  endgroup : cg_exclusive_access
  
  covergroup cg_protocol_violations;
    // AWLEN violations
    cp_awlen_violation: coverpoint master_tx_h.awlen {
      bins normal_len = {[0:255]};
      // Fixed: Removed illegal bin as awlen is 8 bits, max value is 255 which is legal
      // illegal_bins out_of_spec = {[256:$]};
    }
    
    // ARLEN violations
    cp_arlen_violation: coverpoint master_tx_h.arlen {
      bins normal_len = {[0:255]};
      // Fixed: Removed illegal bin as arlen is 8 bits, max value is 255 which is legal
      // illegal_bins out_of_spec = {[256:$]};
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
  
  //--------------------------------------------------------------------------------------------
  // Covergroup: cg_error_injection
  // Coverage for error injection and exception handling scenarios
  //--------------------------------------------------------------------------------------------
  covergroup cg_error_injection;
    // X-value injection scenarios
    cp_x_injection_scenario: coverpoint master_tx_h.awaddr[31:24] {
      bins awvalid_x = {8'hAA};  // X on AWVALID
      bins awaddr_x = {8'hBB};   // X on AWADDR
      bins wdata_x = {8'hCC};    // X on WDATA
      bins arvalid_x = {8'hDD};  // X on ARVALID
      bins bready_x = {8'hEE};   // X on BREADY
      bins rready_x = {8'hFF};   // X on RREADY
      bins no_injection = default;
    }
    
    // Exception scenarios
    cp_exception_type: coverpoint master_tx_h.awaddr[15:0] {
      bins abort_awvalid = {16'hAB01};
      bins abort_arvalid = {16'hAB02};
      bins near_timeout = {16'hBEEF};
      bins illegal_access = {16'h1A00};
      bins ecc_error = {16'h1B00};
      bins special_reg = {16'h1C00};
    }
    
    // Bus matrix mode during error injection
    cp_bus_mode_error: coverpoint axi4_env_cfg_h.bus_matrix_mode {
      bins none_mode = {axi4_bus_matrix_ref::NONE};
      bins base_4x4 = {axi4_bus_matrix_ref::BASE_BUS_MATRIX};
      bins enhanced = {axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX};
    }
    
    // Error recovery status
    cp_error_recovery: coverpoint master_tx_h.bresp {
      bins recovered_okay = {WRITE_OKAY};
      bins recovered_exokay = {WRITE_EXOKAY};
      bins persistent_error = {WRITE_SLVERR};
      bins decode_error = {WRITE_DECERR};
    }
    
    // Timeout stall cycles
    cp_timeout_stall: coverpoint master_tx_h.awaddr[7:0] iff (master_tx_h.awaddr[31:16] == 16'hDEAD) {
      bins under_threshold = {[0:250]};
      bins near_threshold = {[251:253]};
      bins at_threshold = {254};
      bins over_threshold = {255};
    }
    
    // Cross coverage: Error injection x Bus mode
    cx_error_bus_mode: cross cp_x_injection_scenario, cp_bus_mode_error;
    
    // Cross coverage: Exception x Response
    cx_exception_response: cross cp_exception_type, master_tx_h.bresp;
    
    // Cross coverage: Timeout x Bus mode
    cx_timeout_bus_mode: cross cp_timeout_stall, cp_bus_mode_error;
  endgroup : cg_error_injection
  
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
  cg_exclusive_access = new();
  cg_protocol_violations = new();
  cg_error_responses = new();
  cg_error_injection = new();
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
  cg_exclusive_access.sample();
  cg_protocol_violations.sample();
  cg_error_responses.sample();
  cg_error_injection.sample();
  cg_address_alignment.sample();
endfunction : write

function void axi4_protocol_coverage::report_phase(uvm_phase phase);
  real total_coverage;
  
  total_coverage = (cg_id_management.get_coverage() + 
                   cg_exclusive_access.get_coverage() +
                   cg_protocol_violations.get_coverage() + 
                   cg_error_responses.get_coverage() + 
                   cg_error_injection.get_coverage() +
                   cg_address_alignment.get_coverage()) / 6.0;
  
  `uvm_info(get_type_name(), $sformatf("================================"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("AXI4 Protocol Coverage Summary:"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("================================"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("ID Management Coverage      : %.2f%%", cg_id_management.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Protocol Violations Coverage: %.2f%%", cg_protocol_violations.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Response Status Coverage    : %.2f%%", cg_error_responses.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Address Alignment Coverage  : %.2f%%", cg_address_alignment.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("================================"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Total Protocol Coverage     : %.2f%%", total_coverage), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("================================"), UVM_LOW);
endfunction : report_phase

`endif