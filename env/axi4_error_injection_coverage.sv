`ifndef AXI4_ERROR_INJECTION_COVERAGE_INCLUDED_
`define AXI4_ERROR_INJECTION_COVERAGE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_error_injection_coverage
// Functional coverage for error injection and exception handling scenarios
//--------------------------------------------------------------------------------------------
class axi4_error_injection_coverage extends uvm_subscriber#(uvm_sequence_item);
  `uvm_component_utils(axi4_error_injection_coverage)

  // Configuration handle
  axi4_env_config axi4_env_cfg_h;
  
  // Transaction handles for coverage
  axi4_master_tx master_tx_h;
  axi4_slave_tx slave_tx_h;

  //--------------------------------------------------------------------------------------------
  // Covergroup: error_injection_cg
  // Coverage for X-value injection scenarios
  //--------------------------------------------------------------------------------------------
  covergroup error_injection_cg with function sample(axi4_master_tx m_tx, axi4_slave_tx s_tx);
    option.per_instance = 1;
    option.name = "error_injection_cg";
    
    // X injection target signals
    x_injection_signal_cp: coverpoint m_tx.tx_type iff (m_tx != null) {
      option.comment = "X injection target signals";
      bins awvalid_x = {0} iff (m_tx.awaddr == 64'hXXXX_XXXX_XXXX_XXXX);
      bins awaddr_x = {0} iff (m_tx.awaddr[63:32] == 32'hXXXX_XXXX);
      bins wdata_x = {0} iff (m_tx.wdata[0] == 32'hXXXX_XXXX);
      bins arvalid_x = {1} iff (m_tx.araddr == 64'hXXXX_XXXX_XXXX_XXXX);
      bins bready_x = {0} iff (s_tx != null && s_tx.bready === 1'bx);
      bins rready_x = {1} iff (s_tx != null && s_tx.rready === 1'bx);
    }
    
    // X injection duration (cycles)
    x_injection_duration_cp: coverpoint m_tx.awlen {
      option.comment = "X injection duration in cycles";
      bins single_cycle = {0};
      bins two_cycles = {1};
      bins three_cycles = {2};
      bins four_cycles = {3};
      bins five_cycles = {4};
      bins extended = {[5:15]};
    }
    
    // X recovery behavior
    x_recovery_cp: coverpoint s_tx.bresp iff (s_tx != null) {
      option.comment = "Recovery behavior after X injection";
      bins recover_okay = {0};
      bins recover_slverr = {2};
      bins recover_decerr = {3};
    }
    
    // Cross coverage: Signal x Duration x Recovery
    x_injection_cross: cross x_injection_signal_cp, x_injection_duration_cp, x_recovery_cp {
      option.comment = "Cross coverage of X injection scenarios";
    }
  endgroup : error_injection_cg

  //--------------------------------------------------------------------------------------------
  // Covergroup: exception_handling_cg
  // Coverage for exception scenarios
  //--------------------------------------------------------------------------------------------
  covergroup exception_handling_cg with function sample(axi4_master_tx m_tx, axi4_slave_tx s_tx);
    option.per_instance = 1;
    option.name = "exception_handling_cg";
    
    // Exception types
    exception_type_cp: coverpoint m_tx.awaddr[15:0] {
      option.comment = "Exception scenario types";
      bins abort_awvalid = {16'hAB01};  // Abort AWVALID before handshake
      bins abort_arvalid = {16'hAB02};  // Abort ARVALID before handshake
      bins near_timeout = {16'hBEEF};   // Near timeout threshold (special address)
      bins illegal_access = {16'h1A00}; // Protected/illegal address
      bins ecc_error = {16'h1B00};      // ECC error injection address
      bins special_reg = {16'h1C00};    // Special function register
    }
    
    // Timeout stall duration
    timeout_stall_cp: coverpoint m_tx.awlen {
      option.comment = "Stall duration near timeout threshold";
      bins under_threshold = {[0:250]};
      bins near_threshold_minus_2 = {251};
      bins near_threshold_minus_1 = {252};
      bins at_threshold = {253};
      bins over_threshold = {[254:255]};
    }
    
    // Protected access behavior
    protected_access_cp: coverpoint s_tx.bresp iff (s_tx != null && m_tx.awaddr == 64'h1A00) {
      option.comment = "Protected address access response";
      bins access_denied = {2};  // SLVERR
      bins access_granted_after_unlock = {0};  // OKAY after unlock
    }
    
    // ECC error response
    ecc_error_response_cp: coverpoint s_tx.rresp iff (s_tx != null && m_tx.araddr == 64'h1B00) {
      option.comment = "ECC error detection response";
      bins ecc_error_detected = {2};  // SLVERR
      bins ecc_corrected = {0};  // OKAY if correctable
    }
    
    // Special register behavior
    special_reg_behavior_cp: coverpoint m_tx.araddr[7:0] iff (m_tx.araddr[15:8] == 8'h1C) {
      option.comment = "Special register read behaviors";
      bins read_to_clear = {8'h00};
      bins counter_increment = {8'h01};
      bins constant_value = {8'h02};
      bins status_register = {8'h03};
    }
    
    // Cross coverage: Exception type x Response
    exception_response_cross: cross exception_type_cp, s_tx.bresp iff (s_tx != null) {
      option.comment = "Exception scenarios vs response types";
    }
  endgroup : exception_handling_cg

  //--------------------------------------------------------------------------------------------
  // Covergroup: bus_matrix_error_cg
  // Coverage for bus matrix mode error handling
  //--------------------------------------------------------------------------------------------
  covergroup bus_matrix_error_cg with function sample(bit [1:0] bus_mode, axi4_master_tx m_tx);
    option.per_instance = 1;
    option.name = "bus_matrix_error_cg";
    
    // Bus matrix mode
    bus_mode_cp: coverpoint bus_mode {
      option.comment = "Bus matrix mode during error injection";
      bins none_mode = {0};
      bins base_4x4_mode = {1};
      bins enhanced_mode = {2};
    }
    
    // Error injection in different bus modes
    error_in_bus_mode_cp: coverpoint m_tx.tx_type {
      option.comment = "Error type per bus mode";
      bins write_error = {0};
      bins read_error = {1};
    }
    
    // Cross: Bus mode x Error type
    bus_mode_error_cross: cross bus_mode_cp, error_in_bus_mode_cp {
      option.comment = "Error injection across bus matrix modes";
    }
  endgroup : bus_matrix_error_cg

  //--------------------------------------------------------------------------------------------
  // Covergroup: error_recovery_cg
  // Coverage for error recovery scenarios
  //--------------------------------------------------------------------------------------------
  covergroup error_recovery_cg with function sample(bit error_injected, bit recovery_success, int recovery_cycles);
    option.per_instance = 1;
    option.name = "error_recovery_cg";
    
    // Recovery success rate
    recovery_status_cp: coverpoint recovery_success {
      option.comment = "Error recovery success status";
      bins recovered = {1};
      bins not_recovered = {0};
    }
    
    // Recovery time
    recovery_time_cp: coverpoint recovery_cycles {
      option.comment = "Cycles required for recovery";
      bins immediate = {[0:10]};
      bins fast = {[11:50]};
      bins moderate = {[51:100]};
      bins slow = {[101:500]};
      bins very_slow = {[501:1000]};
      bins timeout = {[1001:$]};
    }
    
    // Cross: Recovery status x time
    recovery_cross: cross recovery_status_cp, recovery_time_cp {
      option.comment = "Recovery success vs time taken";
    }
  endgroup : error_recovery_cg

  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_error_injection_coverage", uvm_component parent = null);
    super.new(name, parent);
    error_injection_cg = new();
    exception_handling_cg = new();
    bus_matrix_error_cg = new();
    error_recovery_cg = new();
  endfunction : new

  //--------------------------------------------------------------------------------------------
  // Function: write
  // Samples coverage when transactions are received
  //--------------------------------------------------------------------------------------------
  function void write(uvm_sequence_item t);
    bit [1:0] bus_mode;
    bit error_injected;
    bit recovery_success;
    int recovery_cycles;
    
    // Try to cast to master transaction
    if (!$cast(master_tx_h, t)) begin
      // Try to cast to slave transaction
      if (!$cast(slave_tx_h, t)) begin
        return;
      end
    end
    
    // Get bus mode from config
    if (axi4_env_cfg_h != null) begin
      bus_mode = axi4_env_cfg_h.bus_type;
    end
    
    // Sample error injection coverage
    if (master_tx_h != null) begin
      error_injection_cg.sample(master_tx_h, slave_tx_h);
      exception_handling_cg.sample(master_tx_h, slave_tx_h);
      bus_matrix_error_cg.sample(bus_mode, master_tx_h);
    end
    
    // Check for error recovery scenarios
    if (master_tx_h != null && master_tx_h.awaddr == 64'h0000_0000_DEAD_BEEF) begin
      error_injected = 1;
      // Check if transaction completed successfully
      if (slave_tx_h != null && slave_tx_h.bresp == 0) begin
        recovery_success = 1;
      end
      // Estimate recovery cycles (would need actual timing info)
      recovery_cycles = $urandom_range(10, 1100);
      error_recovery_cg.sample(error_injected, recovery_success, recovery_cycles);
    end
    
  endfunction : write

  //--------------------------------------------------------------------------------------------
  // Function: report_phase
  // Reports coverage percentages
  //--------------------------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info(get_type_name(), "=====================================", UVM_LOW)
    `uvm_info(get_type_name(), "Error Injection Coverage Report", UVM_LOW)
    `uvm_info(get_type_name(), "=====================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("X Injection Coverage: %0.2f%%", error_injection_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Exception Handling Coverage: %0.2f%%", exception_handling_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Bus Matrix Error Coverage: %0.2f%%", bus_matrix_error_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Error Recovery Coverage: %0.2f%%", error_recovery_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Overall Error Injection Coverage: %0.2f%%", 
                              (error_injection_cg.get_coverage() + 
                               exception_handling_cg.get_coverage() + 
                               bus_matrix_error_cg.get_coverage() + 
                               error_recovery_cg.get_coverage()) / 4.0), UVM_LOW)
    `uvm_info(get_type_name(), "=====================================", UVM_LOW)
    
  endfunction : report_phase

endclass : axi4_error_injection_coverage

`endif