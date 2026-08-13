`ifndef AXI4_PROTOCOL_COVERAGE_INCLUDED_
`define AXI4_PROTOCOL_COVERAGE_INCLUDED_

// The master monitor publishes a fresh transaction object for each channel.
// Only its completed B/R packets contain a valid response, so response
// coverage must not share the address-channel subscriber callback.
`uvm_analysis_imp_decl(_pc_addr)
`uvm_analysis_imp_decl(_pc_write_resp)
`uvm_analysis_imp_decl(_pc_read_resp)

//--------------------------------------------------------------------------------------------
// Class: axi4_protocol_coverage
// Functional coverage for AXI4 protocol compliance, ID management, and error scenarios
//--------------------------------------------------------------------------------------------
class axi4_protocol_coverage extends uvm_component;
  `uvm_component_utils(axi4_protocol_coverage)

  // Address packets and completed response packets deliberately use separate
  // analysis implementations.  Sampling a response from an AW/AR packet
  // silently records the converter default (OKAY), not a bus response.
  uvm_analysis_imp_pc_addr       #(axi4_master_tx, axi4_protocol_coverage) address_export;
  uvm_analysis_imp_pc_write_resp #(axi4_master_tx, axi4_protocol_coverage) write_resp_export;
  uvm_analysis_imp_pc_read_resp  #(axi4_master_tx, axi4_protocol_coverage) read_resp_export;

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
  
  // These groups are sampled exclusively from the completed B and R packets.
  // The monitor joins each response to its originating request before it
  // publishes the packet, preserving AXI ID correlation for the crosses.
  covergroup cg_write_responses;
    cp_bresp: coverpoint master_tx_h.bresp {
      bins okay = {WRITE_OKAY};
      bins exokay = {WRITE_EXOKAY};
      bins slverr = {WRITE_SLVERR};
      bins decerr = {WRITE_DECERR};
    }
    cp_exclusive_write_resp: cross master_tx_h.awlock, master_tx_h.bresp {
      bins exclusive_success = binsof(master_tx_h.awlock) intersect {WRITE_EXCLUSIVE_ACCESS} &&
                              binsof(master_tx_h.bresp) intersect {WRITE_EXOKAY};
      bins exclusive_fail = binsof(master_tx_h.awlock) intersect {WRITE_EXCLUSIVE_ACCESS} &&
                           binsof(master_tx_h.bresp) intersect {WRITE_OKAY};
    }
  endgroup : cg_write_responses

  covergroup cg_read_responses;
    cp_rresp: coverpoint master_tx_h.rresp {
      bins okay = {READ_OKAY};
      bins exokay = {READ_EXOKAY};
      bins slverr = {READ_SLVERR};
      bins decerr = {READ_DECERR};
    }
    cp_exclusive_read_resp: cross master_tx_h.arlock, master_tx_h.rresp {
      bins exclusive_success = binsof(master_tx_h.arlock) intersect {READ_EXCLUSIVE_ACCESS} &&
                              binsof(master_tx_h.rresp) intersect {READ_EXOKAY};
      bins exclusive_fail = binsof(master_tx_h.arlock) intersect {READ_EXCLUSIVE_ACCESS} &&
                           binsof(master_tx_h.rresp) intersect {READ_OKAY};
    }
  endgroup : cg_read_responses
  
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
    
    // Timeout stall cycles
    cp_timeout_stall: coverpoint master_tx_h.awaddr[7:0] iff (master_tx_h.awaddr[31:16] == 16'hDEAD) {
      bins under_threshold = {[0:250]};
      bins near_threshold = {[251:253]};
      bins at_threshold = {254};
      bins over_threshold = {255};
    }
    
    // Cross coverage: Error injection x Bus mode
    cx_error_bus_mode: cross cp_x_injection_scenario, cp_bus_mode_error;
    
    // Cross coverage: Timeout x Bus mode
    cx_timeout_bus_mode: cross cp_timeout_stall, cp_bus_mode_error;
  endgroup : cg_error_injection

  // A completed write packet retains the AW fields needed to associate an
  // injected exception address with its actual B response.
  // Sampled from B-channel packets only (write_pc_read_resp is the read one),
  // so the exception marker has to be read out of AWADDR and the bins have to
  // be WRITE-side markers.  `abort_arvalid` (16'hAB02) used to live here: it is
  // injected on the AR address, and to_write_addr_data_resp_class populates
  // awaddr from the write request and never touches araddr, so that bin -- and
  // every cx_exception_response cross containing it -- was unreachable by
  // construction and capped this group, and therefore Total Protocol Coverage,
  // below 100% forever.  The read-side markers now have their own group below.
  covergroup cg_write_error_injection_response;
    cp_exception_type: coverpoint master_tx_h.awaddr[15:0] {
      bins abort_awvalid = {16'hAB01};
      bins near_timeout = {16'hBEEF};
      bins illegal_access = {16'h1A00};
      bins ecc_error = {16'h1B00};
      bins special_reg = {16'h1C00};
    }
    cp_error_recovery: coverpoint master_tx_h.bresp {
      bins recovered_okay = {WRITE_OKAY};
      bins recovered_exokay = {WRITE_EXOKAY};
      bins persistent_error = {WRITE_SLVERR};
      bins decode_error = {WRITE_DECERR};
    }
    cx_exception_response: cross cp_exception_type, cp_error_recovery;
  endgroup : cg_write_error_injection_response

  // Read-side counterpart: same question ("which injected exception produced
  // which response"), asked of the channel that can actually answer it.
  // Sampled from write_pc_read_resp, so the marker comes from ARADDR and the
  // response from RRESP.
  covergroup cg_read_error_injection_response;
    cp_read_exception_type: coverpoint master_tx_h.araddr[15:0] {
      bins abort_arvalid = {16'hAB02};
      bins near_timeout = {16'hBEEF};
      bins illegal_access = {16'h1A00};
      bins ecc_error = {16'h1B00};
      bins special_reg = {16'h1C00};
    }
    cp_read_error_recovery: coverpoint master_tx_h.rresp {
      bins recovered_okay = {READ_OKAY};
      bins recovered_exokay = {READ_EXOKAY};
      bins persistent_error = {READ_SLVERR};
      bins decode_error = {READ_DECERR};
    }
    cx_read_exception_response: cross cp_read_exception_type, cp_read_error_recovery;
  endgroup : cg_read_error_injection_response
  
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
  extern virtual function void write_pc_addr(axi4_master_tx t);
  extern virtual function void write_pc_write_resp(axi4_master_tx t);
  extern virtual function void write_pc_read_resp(axi4_master_tx t);
  extern virtual function void report_phase(uvm_phase phase);
  
endclass : axi4_protocol_coverage

function axi4_protocol_coverage::new(string name = "axi4_protocol_coverage", uvm_component parent = null);
  super.new(name, parent);
  cg_id_management = new();
  cg_exclusive_access = new();
  cg_protocol_violations = new();
  cg_write_responses = new();
  cg_read_responses = new();
  cg_error_injection = new();
  cg_write_error_injection_response = new();
  cg_read_error_injection_response = new();
  cg_address_alignment = new();
  address_export = new("address_export", this);
  write_resp_export = new("write_resp_export", this);
  read_resp_export = new("read_resp_export", this);
endfunction : new

function void axi4_protocol_coverage::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db#(axi4_env_config)::get(this, "", "axi4_env_config", axi4_env_cfg_h)) begin
    `uvm_fatal("CONFIG", "Cannot get axi4_env_config from uvm_config_db")
  end
endfunction : build_phase

function void axi4_protocol_coverage::write_pc_addr(axi4_master_tx t);
  master_tx_h = t;

  // AW/AR packets do not contain a B/R response.  Keep response coverage on
  // its own callbacks so legal default enum values cannot inflate response
  // bins before a response occurs.
  cg_id_management.sample();
  cg_exclusive_access.sample();
  cg_protocol_violations.sample();
  cg_error_injection.sample();
  cg_address_alignment.sample();
endfunction : write_pc_addr

function void axi4_protocol_coverage::write_pc_write_resp(axi4_master_tx t);
  master_tx_h = t;
  cg_write_responses.sample();
  cg_write_error_injection_response.sample();
endfunction : write_pc_write_resp

function void axi4_protocol_coverage::write_pc_read_resp(axi4_master_tx t);
  master_tx_h = t;
  cg_read_responses.sample();
  cg_read_error_injection_response.sample();
endfunction : write_pc_read_resp

function void axi4_protocol_coverage::report_phase(uvm_phase phase);
  real total_coverage;
  
  total_coverage = (cg_id_management.get_coverage() + 
                   cg_exclusive_access.get_coverage() +
                   cg_protocol_violations.get_coverage() + 
                   cg_write_responses.get_coverage() +
                   cg_read_responses.get_coverage() +
                   cg_error_injection.get_coverage() +
                   cg_write_error_injection_response.get_coverage() +
                   cg_read_error_injection_response.get_coverage() +
                   cg_address_alignment.get_coverage()) / 9.0;
  
  `uvm_info(get_type_name(), $sformatf("================================"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("AXI4 Protocol Coverage Summary:"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("================================"), UVM_LOW);
  // Every group that goes into the /8.0 average above must be printed here.
  // Three of them were not (exclusive access, error injection, and the
  // write-error-injection response cross), so a drop in Total Protocol
  // Coverage showed up with five unchanged per-group numbers underneath it and
  // no way to attribute the change without opening the .vdb.
  `uvm_info(get_type_name(), $sformatf("ID Management Coverage      : %.2f%%", cg_id_management.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Exclusive Access Coverage   : %.2f%%", cg_exclusive_access.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Protocol Violations Coverage: %.2f%%", cg_protocol_violations.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Write Response Coverage     : %.2f%%", cg_write_responses.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Read Response Coverage      : %.2f%%", cg_read_responses.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Error Injection Coverage    : %.2f%%", cg_error_injection.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Write Err-Inject Resp Cov   : %.2f%%", cg_write_error_injection_response.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Read Err-Inject Resp Cov    : %.2f%%", cg_read_error_injection_response.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Address Alignment Coverage  : %.2f%%", cg_address_alignment.get_coverage()), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("================================"), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("Total Protocol Coverage     : %.2f%%", total_coverage), UVM_LOW);
  `uvm_info(get_type_name(), $sformatf("================================"), UVM_LOW);
endfunction : report_phase

`endif
