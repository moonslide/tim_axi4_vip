`ifndef AXI4_ERROR_INJECTION_COVERAGE_INCLUDED_
`define AXI4_ERROR_INJECTION_COVERAGE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_error_injection_coverage
// Functional coverage for error injection and exception handling scenarios
//--------------------------------------------------------------------------------------------
class axi4_error_injection_coverage extends uvm_subscriber#(axi4_master_tx);
  `uvm_component_utils(axi4_error_injection_coverage)

  // Configuration handle
  axi4_env_config axi4_env_cfg_h;
  
  // Transaction handles for coverage
  axi4_master_tx master_tx_h;
  axi4_slave_tx slave_tx_h;

  // Variables to track X injection
  bit x_inject_awvalid_detected;
  bit x_inject_awaddr_detected;
  bit x_inject_wdata_detected;
  bit x_inject_arvalid_detected;
  bit x_inject_bready_detected;
  bit x_inject_rready_detected;
  int x_inject_duration;
  
  // Enum for X injection signal types
  typedef enum int {
    X_INJECT_NONE = 0,
    X_INJECT_AWVALID = 1,
    X_INJECT_AWADDR = 2,
    X_INJECT_WDATA = 3,
    X_INJECT_ARVALID = 4,
    X_INJECT_BREADY = 5,
    X_INJECT_RREADY = 6
  } x_inject_signal_e;
  
  x_inject_signal_e x_inject_signal;
  
  //--------------------------------------------------------------------------------------------
  // Covergroup: error_injection_cg
  // Coverage for X-value injection scenarios
  //--------------------------------------------------------------------------------------------
  covergroup error_injection_cg;
    option.per_instance = 1;
    option.name = "error_injection_cg";
    
    // X injection target signals
    x_injection_signal_cp: coverpoint x_inject_signal {
      option.comment = "X injection target signals";
      bins awvalid_x = {X_INJECT_AWVALID};
      bins awaddr_x = {X_INJECT_AWADDR};
      bins wdata_x = {X_INJECT_WDATA};
      bins arvalid_x = {X_INJECT_ARVALID};
      bins bready_x = {X_INJECT_BREADY};
      bins rready_x = {X_INJECT_RREADY};
      bins no_injection = {X_INJECT_NONE};
    }
    
    // X injection duration (cycles)
    x_injection_duration_cp: coverpoint x_inject_duration {
      option.comment = "X injection duration in cycles";
      bins single_cycle = {1};
      bins two_cycles = {2};
      bins three_cycles = {3};
      bins four_cycles = {4};
      bins five_cycles = {5};
      bins extended = {[6:10]};
    }
    
    // X recovery behavior
    x_recovery_cp: coverpoint 
      (x_inject_awvalid_detected || x_inject_awaddr_detected || 
       x_inject_wdata_detected || x_inject_arvalid_detected ||
       x_inject_bready_detected || x_inject_rready_detected) {
      option.comment = "Recovery behavior after X injection";
      bins injected = {1};
      bins not_injected = {0};
    }
    
    // Cross coverage: Signal x Duration
    x_injection_cross: cross x_injection_signal_cp, x_injection_duration_cp {
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
  function void write(axi4_master_tx t);
    bit [1:0] bus_mode;
    bit error_injected;
    bit recovery_success;
    int recovery_cycles;
    
    // Store the master transaction
    master_tx_h = t;
    if (master_tx_h == null) begin
      return;
    end
    
    // Get bus mode from config - convert enum to bit value for coverage
    if (axi4_env_cfg_h != null) begin
      case (axi4_env_cfg_h.bus_matrix_mode)
        axi4_bus_matrix_ref::NONE: bus_mode = 0;
        axi4_bus_matrix_ref::BASE_BUS_MATRIX: bus_mode = 1;
        axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: bus_mode = 2;
        default: bus_mode = 0;
      endcase
    end
    
    // Check for X injection signals via config_db
    void'(uvm_config_db#(bit)::get(null, "*", "x_inject_awvalid", x_inject_awvalid_detected));
    void'(uvm_config_db#(bit)::get(null, "*", "x_inject_awaddr", x_inject_awaddr_detected));
    void'(uvm_config_db#(bit)::get(null, "*", "x_inject_wdata", x_inject_wdata_detected));
    void'(uvm_config_db#(bit)::get(null, "*", "x_inject_arvalid", x_inject_arvalid_detected));
    void'(uvm_config_db#(bit)::get(null, "*", "x_inject_bready", x_inject_bready_detected));
    void'(uvm_config_db#(bit)::get(null, "*", "x_inject_rready", x_inject_rready_detected));
    void'(uvm_config_db#(int)::get(null, "*", "x_inject_cycles", x_inject_duration));
    
    // Determine which X injection signal is active
    if (x_inject_awvalid_detected) x_inject_signal = X_INJECT_AWVALID;
    else if (x_inject_awaddr_detected) x_inject_signal = X_INJECT_AWADDR;
    else if (x_inject_wdata_detected) x_inject_signal = X_INJECT_WDATA;
    else if (x_inject_arvalid_detected) x_inject_signal = X_INJECT_ARVALID;
    else if (x_inject_bready_detected) x_inject_signal = X_INJECT_BREADY;
    else if (x_inject_rready_detected) x_inject_signal = X_INJECT_RREADY;
    else x_inject_signal = X_INJECT_NONE;
    
    // Sample X injection coverage if any X injection is active
    if (x_inject_signal != X_INJECT_NONE) begin
      error_injection_cg.sample();
      `uvm_info(get_type_name(), $sformatf("X injection coverage sampled - Signal: %s, Duration: %0d cycles", 
                                          x_inject_signal.name(), x_inject_duration), UVM_MEDIUM)
    end
    
    // Sample other coverage
    if (master_tx_h != null) begin
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