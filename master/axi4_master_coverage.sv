`ifndef AXI4_MASTER_COVERAGE_INCLUDED_
`define AXI4_MASTER_COVERAGE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: master_coverage
// master_coverage determines the how much code is covered for better functionality of the TB.
//--------------------------------------------------------------------------------------------
class axi4_master_coverage extends uvm_subscriber #(axi4_master_tx);
  `uvm_component_utils(axi4_master_coverage)

  // Variable: axi4_master_agent_cfg_h
  // Declaring handle for master agent configuration class 
  axi4_master_agent_config axi4_master_agent_cfg_h;

  // Functional coverage for WSTRB patterns
  bit [3:0] cov_wstrb;
  
  // Variables to track X injection detection
  bit x_inject_awvalid_detected;
  bit x_inject_awaddr_detected;
  bit x_inject_wdata_detected;
  bit x_inject_arvalid_detected;
  bit x_inject_bready_detected;
  bit x_inject_rready_detected;
  int x_inject_duration;
  
  // Variables for clock and reset exception tracking
  real clk_freq_scale_factor;
  int clk_freq_scale_idx;  // Integer index for coverage
  int clk_freq_change_count;
  bit reset_active;
  int reset_duration_cycles;
  int reset_count;
  
  // Enhanced frequency tracking variables
  real prev_freq_scale_factor = 1.0;
  int freq_transition_pattern;  // 0=steady, 1=up, 2=down, 3=oscillating
  int consecutive_freq_changes;
  int freq_change_interval_cycles;
  int freq_hold_duration_cycles;
  bit freq_change_during_transfer;
  int master_interface_id;  // Which master interface experienced freq change
  
  // Enum for reset phase
  typedef enum int {
    RESET_NONE = 0,
    RESET_ADDR_PHASE = 1,
    RESET_DATA_PHASE = 2,
    RESET_RESP_PHASE = 3,
    RESET_IDLE_PHASE = 4
  } reset_phase_e;
  reset_phase_e reset_phase_enum;
  
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
  covergroup wstrb_cg;
    option.per_instance = 1;
    cp_wstrb : coverpoint cov_wstrb {
      bins zero        = {4'b0000};
      bins all_ones    = {4'b1111};
      bins upper_half  = {4'b1100};
      bins lower_half  = {4'b0011};
      bins alt_0101    = {4'b0101};
      bins alt_1010    = {4'b1010};
      bins single_bit[] = {4'b0001,4'b0010,4'b0100,4'b1000};
      bins others      = default;
    }
  endgroup
 
  //-------------------------------------------------------
  // Covergroup: axi4_master_covergroup
  // Covergroup consists of the various coverpoints based on
  // no. of the variables used to improve the coverage.
  //-------------------------------------------------------
  covergroup axi4_master_covergroup with function sample (axi4_master_agent_config cfg, axi4_master_tx packet);
    option.per_instance = 1;

    //-------------------------------------------------------
    // Write channel signals 
    //-------------------------------------------------------
   
    AWLEN_CP : coverpoint packet.awlen {
      option.comment = "Write Address Length values";
      bins AWLEN_1      = {0};
      bins AWLEN_2      = {1};
      bins AWLEN_4      = {3};
      bins AWLEN_8      = {7};
      bins AWLEN_16     = {15};
      bins AWLEN_32     = {31};
      bins AWLEN_64     = {63};
      bins AWLEN_128    = {127};
      bins AWLEN_256    = {255};
      bins AWLEN_DEFAULT = default ;
    }

    AWBURST_CP : coverpoint packet.awburst {
      option.comment = "Write Address Burst values";
      bins READ_FIXED = {0};
      bins WRITE_INCR = {1}; 
      bins READ_WRAP  = {2};     
      illegal_bins ILLEGAL_BIN_OF_AWBURST = {3};     
    }

    AWSIZE_CP : coverpoint packet.awsize {
      option.comment = "Write Address size values";
      bins AWSIZE_1BYTE    = {0};
      bins AWSIZE_2BYTES   = {1};
      bins AWSIZE_4BYTES   = {2};
      bins AWSIZE_8BYTES   = {3};
      bins AWSIZE_16BYTES  = {4};
      bins AWSIZE_32BYTES  = {5};
      bins AWSIZE_64BYTES  = {6};
      bins AWSIZE_128BYTES = {7};
    }

    AWLOCK_CP :coverpoint packet.awlock {
      option.comment= "Write Address Lock values";
      bins AWLOCK[] = {0,1};
    }

    AWCACHE_CP : coverpoint packet.awcache {
      option.comment = "Write Address Cache values";
      bins WRITE_BUFFERABLE     = {0};
      bins WRITE_MODIFIABLE     = {1};
      bins WRITE_OTHER_ALLOCATE = {2}; 
      bins WRITE_ALLOCATE       = {3};
    }

    AWPROT_CP : coverpoint packet.awprot {
      option.comment = "Write Address Protection values";
      bins AWPROT[] = {[0:$]};
    }

    AWID_CP : coverpoint packet.awid {
      option.comment = "Write Address ID values";
      bins AWID[] = {[0:$]};
    }

    BRESP_CP : coverpoint packet.bresp {
      option.comment    = "Write Response values";
      bins WRITE_OKAY   = {0};
      bins WRITE_EXOKAY = {1};
      bins WRITE_SLVERR = {2};
      bins WRITE_DECERR = {3};
    }

    //-------------------------------------------------------
    // Read channel signals 
    //-------------------------------------------------------
    
    ARLEN_CP : coverpoint packet.arlen {
      option.comment = "Read Address Length values";
      bins ARLEN_1   = {0};
      bins ARLEN_2   = {1};
      bins ARLEN_4   = {3};
      bins ARLEN_8   = {7};
      bins ARLEN_16  = {15};
      bins ARLEN_32  = {31};
      bins ARLEN_64  = {63};
      bins ARLEN_128 = {127};
      bins ARLEN_256 = {255};
      bins ARLEN_DEFAULT= default ;
    }

    ARBURST_CP : coverpoint packet.arburst {
      option.comment = "Read Address Burst values";
      bins READ_FIXED ={0};
      bins WRITE_INCR ={1}; 
      bins READ_WRAP  ={2};   
      illegal_bins ILLEGAL_BIN_OF_ARBURST = {3};   
    }

    ARSIZE_CP : coverpoint packet.arsize {
      option.comment = "Read Address Size values";
      bins ARSIZE_1BYTE    = {0};
      bins ARSIZE_2BYTES   = {1};
      bins ARSIZE_4BYTES   = {2};
      bins ARSIZE_8BYTES   = {3};
      bins ARSIZE_16BYTES  = {4};
      bins ARSIZE_32BYTES  = {5};
      bins ARSIZE_64BYTES  = {6};
      bins ARSIZE_128BYTES = {7};
    }

    ARLOCK_CP :coverpoint packet.arlock {
      option.comment= "Read Address Lock values";
      bins ARLOCK[] = {0,1};
    }

    ARCACHE_CP : coverpoint packet.arcache {
      option.comment = "Read Address Cache values";
      bins READ_BUFFERABLE = {0};
      bins READ_MODIFIABLE = {1};
      bins READ_OTHER_ALLOCATE = {2}; 
      bins READ_ALLOCATE = {3};
    }

    ARPROT_CP : coverpoint packet.arprot {
      option.comment = "Read Address Protection values";
      bins ARPROT[] = {[0:$]};
    }

    BID_CP : coverpoint packet.bid {
      option.comment = "Write Response values";
      bins BID[] = {[0:$]};
    }

    ARID_CP : coverpoint packet.rid {
      option.comment = "Read Address ID values";
      bins ARID[] = {[0:$]};
    }

    RID_CP : coverpoint packet.rid {
      option.comment = "Read ID values";
      bins RID[] = {[0:$]};
    }
    
    RRESP_CP : coverpoint packet.rresp {
      option.comment    = "Read Response values";
      bins READ_OKAY    = {0};
      bins READ_EXOKAY  = {1};
      bins READ_SLVERR  = {2};
      bins READ_DECERR  = {3};
    }


    // Address width can range from 1-64 bits according to the
    // AMBA AXI4 specification. Create a bin for each value so that
    // coverage hits only reflect the configured widths.
    ADDR_WIDTH_CP : coverpoint cfg.addr_width {
      bins width[] = {[1:64]};
    }

    // Data width is restricted to power-of-two values between
    // 8 and 1024 bits.  Create explicit bins for each legal value.
    DATA_WIDTH_CP : coverpoint cfg.data_width {
      bins DW_8    = {8};
      bins DW_16   = {16};
      bins DW_32   = {32};
      bins DW_64   = {64};
      bins DW_128  = {128};
      bins DW_256  = {256};
      bins DW_512  = {512};
      bins DW_1024 = {1024};
   }

    //-------------------------------------------------------
    // Wait state coverage
    //-------------------------------------------------------

    AW_WAIT_STATES_CP : coverpoint packet.aw_wait_states {
      option.comment = "AWREADY wait states";
      bins AW_WS[] = {[0:6]};
    }

    AW_HANDSHAKE_CP : coverpoint (packet.aw_wait_states == 0) {
      option.comment = "AWREADY handshake";
      bins HANDSHAKE = {1};
    }

    W_WAIT_STATES_CP : coverpoint packet.w_wait_states {
      option.comment = "WREADY wait states";
      bins W_WS[] = {[0:6]};
    }

    W_HANDSHAKE_CP : coverpoint (packet.w_wait_states == 0) {
      option.comment = "WREADY handshake";
      bins HANDSHAKE = {1};
    }

    B_WAIT_STATES_CP : coverpoint packet.b_wait_states {
      option.comment = "BREADY wait states";
      bins B_WS[] = {[0:6]};
    }

    B_HANDSHAKE_CP : coverpoint (packet.b_wait_states == 0) {
      option.comment = "BREADY handshake";
      bins HANDSHAKE = {1};
    }

    AR_WAIT_STATES_CP : coverpoint packet.ar_wait_states {
      option.comment = "ARREADY wait states";
      bins AR_WS[] = {[0:6]};
    }

    AR_HANDSHAKE_CP : coverpoint (packet.ar_wait_states == 0) {
      option.comment = "ARREADY handshake";
      bins HANDSHAKE = {1};
    }

    R_WAIT_STATES_CP : coverpoint packet.r_wait_states {
      option.comment = "RREADY wait states";
      bins R_WS[] = {[0:6]};
    }

    R_HANDSHAKE_CP : coverpoint (packet.r_wait_states == 0) {
      option.comment = "RREADY handshake";
      bins HANDSHAKE = {1};
    }
    TRANSFER_TYPE_CP : coverpoint packet.transfer_type {
      option.comment = "transfer type";
      bins BLOCKING_WRITE     = {0};
      bins BLOCKING_READ      = {1};
      bins NON_BLOCKING_WRITE = {2};
      bins NON_BLOCKING_READ  = {3};
    }

    //-------------------------------------------------------
    //-------------------------------------------------------
    // Error Injection and Exception Handling Coverage
    //-------------------------------------------------------
    
    // X-value injection scenarios
    X_INJECTION_TARGET_CP : coverpoint packet.awaddr[31:28] {
      option.comment = "X injection target signals based on special addresses";
      bins awvalid_x_inject = {4'hA};  // Address 0xAxxxxxxx for AWVALID X injection
      bins awaddr_x_inject = {4'hB};   // Address 0xBxxxxxxx for AWADDR X injection  
      bins wdata_x_inject = {4'hC};    // Address 0xCxxxxxxx for WDATA X injection
      bins arvalid_x_inject = {4'hD};  // Address 0xDxxxxxxx for ARVALID X injection
      bins normal_transaction = default;
    }
    
    // Exception scenario addresses
    EXCEPTION_SCENARIO_CP : coverpoint packet.awaddr[15:0] {
      option.comment = "Exception handling test scenarios";
      bins abort_awvalid = {16'hAB01};     // Abort AWVALID test
      bins abort_arvalid = {16'hAB02};     // Abort ARVALID test
      bins abort_wvalid = {16'hAB03};      // Abort WVALID test
      bins abort_wlast = {16'hAB04};       // Abort before WLAST test
      bins abort_bready = {16'hAB05};      // Abort BREADY test
      bins abort_rready = {16'hAB06};      // Abort RREADY test
      bins near_timeout = {16'hBEEF};      // Near timeout threshold test
      bins illegal_access = {16'h1A00};    // Protected/illegal address
      bins ecc_error_inject = {16'h1B00};  // ECC error injection
      bins special_register = {16'h1C00};  // Special function register
      bins multi_abort = {16'hAB10};       // Multiple abort events
      bins continuous_abort = {16'hAB11};  // Continuous abort events
      bins random_timeout = {16'hBEF1};    // Random timeout scenarios
      bins mixed_exception = {16'hABCD};   // Mixed exception types
      bins normal_addr = default;
    }
    
    // Timeout stall duration coverage
    TIMEOUT_STALL_DURATION_CP : coverpoint packet.awaddr[15:0] iff (packet.awaddr[31:16] == 16'hDEAD) {
      option.comment = "Stall duration for timeout testing (address 0xDEADBEEF = timeout test)";
      bins stall_1020_cycles = {16'hBEEB};  // 1020 cycles
      bins stall_1021_cycles = {16'hBEEC};  // 1021 cycles
      bins stall_1022_cycles = {16'hBEED};  // 1022 cycles
      bins stall_1023_cycles = {16'hBEEE};  // 1023 cycles (near threshold)
      bins stall_1024_cycles = {16'hBEEF};  // 1024 cycles (at threshold)
      bins stall_1025_cycles = {16'hBEF0};  // 1025 cycles (over threshold)
    }
    
    // Error response handling
    ERROR_RESPONSE_HANDLING_CP : coverpoint packet.bresp {
      option.comment = "Error response handling for exception scenarios";
      bins normal_okay = {0};
      bins exclusive_okay = {1};
      bins slave_error = {2};   // SLVERR for protected access, ECC errors
      bins decode_error = {3};  // DECERR for invalid addresses
    }
    
    // Recovery after error injection
    ERROR_RECOVERY_CP : coverpoint packet.tx_type {
      option.comment = "Transaction type after error injection (recovery test)";
      bins write_recovery = {WRITE};
      bins read_recovery = {READ};
      bins normal_operation = default;
    }
    
    // Enhanced X injection signal detection
    X_INJECT_SIGNAL_CP : coverpoint x_inject_signal {
      option.comment = "X injection active signal detection";
      bins awvalid_x_detected = {X_INJECT_AWVALID};
      bins awaddr_x_detected = {X_INJECT_AWADDR};
      bins wdata_x_detected = {X_INJECT_WDATA};
      bins arvalid_x_detected = {X_INJECT_ARVALID};
      bins bready_x_detected = {X_INJECT_BREADY};
      bins rready_x_detected = {X_INJECT_RREADY};
      bins no_x_injection = {X_INJECT_NONE};
    }
    
    // X injection duration coverage (updated for 5-20 cycles range)
    X_INJECT_DURATION_CP : coverpoint x_inject_duration {
      option.comment = "X injection duration in cycles";
      bins single_cycle = {1};
      bins two_cycles = {2};
      bins three_cycles = {3};
      bins four_cycles = {4};
      bins standard_range = {[5:20]};  // New standard range 5-20 cycles
      bins extended_range = {[21:50]};  // Extended for stress testing
      bins long_duration = {[51:$]};
    }
    
    // Multiple X injection count coverage (new)
    X_INJECT_COUNT_CP : coverpoint packet.awlen {
      option.comment = "Number of X injection events (1-20)";
      bins single_injection = {1};
      bins few_injections = {[2:5]};
      bins moderate_injections = {[6:10]};
      bins many_injections = {[11:15]};
      bins maximum_injections = {[16:20]};
    }
    
    // Exception abort duration coverage (new)
    ABORT_DURATION_CP : coverpoint packet.awsize {
      option.comment = "Abort event duration (5-50 cycles)";
      bins short_abort = {[0:1]};      // Maps to 5-10 cycles
      bins medium_abort = {[2:3]};     // Maps to 11-20 cycles
      bins long_abort = {[4:5]};       // Maps to 21-35 cycles
      bins very_long_abort = {[6:7]};  // Maps to 36-50 cycles
    }
    
    // Exception abort count coverage (new)
    ABORT_COUNT_CP : coverpoint packet.awburst {
      option.comment = "Number of abort events (1-15)";
      bins single_abort = {0};        // Maps to single abort
      bins multiple_aborts = {1};     // Maps to 2-7 aborts
      bins many_aborts = {2};         // Maps to 8-15 aborts
    }
    
    // Clock frequency change coverage (new) - using integer representation
    CLK_FREQ_SCALE_CP : coverpoint clk_freq_scale_idx {
      option.comment = "Clock frequency scaling factor index";
      bins halt = {-1};                // 0x speed (clock gated)
      bins slow_25 = {7};              // 0.25x speed
      bins slow_50 = {0};              // 0.5x speed
      bins slow_75 = {1};              // 0.75x speed  
      bins normal = {2};               // 1.0x speed
      bins fast_125 = {3};             // 1.25x speed
      bins fast_150 = {4};             // 1.5x speed
      bins fast_200 = {5};             // 2.0x speed
      bins fast_300 = {6};             // 3.0x speed
      bins fast_400 = {8};             // 4.0x speed
    }
    
    // Clock frequency change count coverage (new)
    CLK_FREQ_CHANGE_COUNT_CP : coverpoint clk_freq_change_count {
      option.comment = "Number of clock frequency changes";
      bins single_change = {1};
      bins few_changes = {[2:3]};
      bins moderate_changes = {[4:6]};
      bins many_changes = {[7:10]};
      bins excessive_changes = {[11:$]};
    }
    
    // Frequency transition patterns (new)
    FREQ_TRANSITION_PATTERN_CP : coverpoint freq_transition_pattern {
      option.comment = "Frequency transition pattern";
      bins steady = {0};
      bins speed_up = {1};
      bins slow_down = {2};
      bins oscillating = {3};
    }
    
    // Consecutive frequency changes (new)
    CONSECUTIVE_FREQ_CHANGES_CP : coverpoint consecutive_freq_changes {
      option.comment = "Back-to-back frequency changes";
      bins single = {1};
      bins burst_2_3 = {[2:3]};
      bins burst_4_6 = {[4:6]};
      bins burst_many = {[7:$]};
    }
    
    // Frequency change interval (new)
    FREQ_CHANGE_INTERVAL_CP : coverpoint freq_change_interval_cycles {
      option.comment = "Cycles between frequency changes";
      bins immediate = {[0:10]};
      bins fast = {[11:50]};
      bins medium_interval = {[51:200]};
      bins slow = {[201:1000]};
      bins very_slow = {[1001:$]};
    }
    
    // Frequency hold duration (new)
    FREQ_HOLD_DURATION_CP : coverpoint freq_hold_duration_cycles {
      option.comment = "Cycles at a frequency before change";
      bins brief = {[0:20]};
      bins short_hold = {[21:100]};
      bins medium_hold = {[101:500]};
      bins long_hold = {[501:2000]};
      bins extended = {[2001:$]};
    }
    
    // Frequency change during transfer (new)
    FREQ_CHANGE_DURING_XFER_CP : coverpoint freq_change_during_transfer {
      option.comment = "Frequency changed during active transfer";
      bins no_change = {0};
      bins changed = {1};
    }
    
    // Master interface frequency change (new)
    MASTER_INTF_FREQ_CP : coverpoint master_interface_id {
      option.comment = "Master interface with frequency change";
      bins master[10] = {[0:9]};
    }
    
    // Reset termination coverage (new)
    RESET_DURATION_CP : coverpoint reset_duration_cycles {
      option.comment = "Reset pulse duration in cycles";
      bins single_cycle = {1};
      bins short_reset = {[2:3]};
      bins medium_reset = {[4:6]};
      bins long_reset = {[7:10]};
      bins very_long_reset = {[11:$]};
    }
    
    // Reset phase coverage (new)
    RESET_PHASE_CP : coverpoint reset_phase_enum {
      option.comment = "Transfer phase when reset occurred";
      bins no_reset = {RESET_NONE};
      bins addr_phase = {RESET_ADDR_PHASE};
      bins data_phase = {RESET_DATA_PHASE};
      bins resp_phase = {RESET_RESP_PHASE};
      bins idle_phase = {RESET_IDLE_PHASE};
    }
    
    // Reset count coverage (new)
    RESET_COUNT_CP : coverpoint reset_count {
      option.comment = "Number of reset events";
      bins single_reset = {1};
      bins few_resets = {[2:3]};
      bins moderate_resets = {[4:5]};
      bins many_resets = {[6:8]};
      bins excessive_resets = {[9:$]};
    }
    
    // Bus matrix mode during X injection - removed as bus_type is not available in agent config
    // This coverage can be added at environment level if needed
    
    //-------------------------------------------------------
    // Cross of coverpoints
    //-------------------------------------------------------

    AWLENGTH_CP_X_AWSIZE_X_AWBURST    :cross AWLEN_CP,AWSIZE_CP,AWBURST_CP;
    ARLENGTH_CP_X_ARSIZE_X_ARBURST    :cross ARLEN_CP,ARSIZE_CP,ARBURST_CP;
    BID_CP_X_BRESP_CP                 :cross BID_CP,BRESP_CP;
    RID_CP_X_RRESP_CP                 :cross BID_CP,BRESP_CP;
    AWBURST_CP_X_AWLEN_CP_X_AWSIZE_CP :cross AWBURST_CP,AWLEN_CP,AWSIZE_CP;
    ARBURST_CP_X_ARLEN_CP_X_ARSIZE_CP :cross ARBURST_CP,ARLEN_CP,ARSIZE_CP;
    ADDR_DATA_WIDTH_CP : cross ADDR_WIDTH_CP, DATA_WIDTH_CP;
    // TRANSFER_TYPE_CP_X_BURST_TYPE_CP  :cross TRANSFER_TYPE_CP,BURST_TYPE_CP;
    
    // Error injection cross coverage
    X_INJECT_X_RESPONSE : cross X_INJECTION_TARGET_CP, ERROR_RESPONSE_HANDLING_CP;
    EXCEPTION_X_RESPONSE : cross EXCEPTION_SCENARIO_CP, ERROR_RESPONSE_HANDLING_CP;
    TIMEOUT_X_RESPONSE : cross TIMEOUT_STALL_DURATION_CP, packet.bresp;
    
    // Enhanced X injection cross coverage
    X_SIGNAL_X_DURATION : cross X_INJECT_SIGNAL_CP, X_INJECT_DURATION_CP;
    X_SIGNAL_X_RESPONSE : cross X_INJECT_SIGNAL_CP, ERROR_RESPONSE_HANDLING_CP;
    
    // New cross coverage for multiple injections
    X_SIGNAL_X_COUNT : cross X_INJECT_SIGNAL_CP, X_INJECT_COUNT_CP;
    X_COUNT_X_DURATION : cross X_INJECT_COUNT_CP, X_INJECT_DURATION_CP;
    
    // New cross coverage for enhanced exceptions
    EXCEPTION_X_ABORT_DURATION : cross EXCEPTION_SCENARIO_CP, ABORT_DURATION_CP;
    EXCEPTION_X_ABORT_COUNT : cross EXCEPTION_SCENARIO_CP, ABORT_COUNT_CP;
    ABORT_COUNT_X_DURATION : cross ABORT_COUNT_CP, ABORT_DURATION_CP;
    
    // New cross coverage for clock and reset exceptions
    CLK_FREQ_X_COUNT : cross CLK_FREQ_SCALE_CP, CLK_FREQ_CHANGE_COUNT_CP;
    CLK_FREQ_X_TRANSFER : cross CLK_FREQ_SCALE_CP, packet.tx_type;
    RESET_PHASE_X_DURATION : cross RESET_PHASE_CP, RESET_DURATION_CP;
    RESET_PHASE_X_COUNT : cross RESET_PHASE_CP, RESET_COUNT_CP;
    CLK_FREQ_X_RESET_PHASE : cross CLK_FREQ_SCALE_CP, RESET_PHASE_CP;
    
    // Enhanced frequency cross coverage
    FREQ_PATTERN_X_COUNT : cross FREQ_TRANSITION_PATTERN_CP, CLK_FREQ_CHANGE_COUNT_CP;
    FREQ_SCALE_X_INTERVAL : cross CLK_FREQ_SCALE_CP, FREQ_CHANGE_INTERVAL_CP;
    FREQ_SCALE_X_DURATION : cross CLK_FREQ_SCALE_CP, FREQ_HOLD_DURATION_CP;
    FREQ_DURING_XFER_X_TYPE : cross FREQ_CHANGE_DURING_XFER_CP, packet.tx_type;
    FREQ_CONSECUTIVE_X_PATTERN : cross CONSECUTIVE_FREQ_CHANGES_CP, FREQ_TRANSITION_PATTERN_CP;
    FREQ_MASTER_X_SCALE : cross MASTER_INTF_FREQ_CP, CLK_FREQ_SCALE_CP;
    FREQ_MASTER_X_PATTERN : cross MASTER_INTF_FREQ_CP, FREQ_TRANSITION_PATTERN_CP;

  endgroup: axi4_master_covergroup


  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_coverage", uvm_component parent = null);
  extern virtual function void write(axi4_master_tx t);
  extern virtual function void report_phase(uvm_phase phase);

endclass : axi4_master_coverage

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_master_coverage
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_master_coverage::new(string name = "axi4_master_coverage",
                                 uvm_component parent = null);
  super.new(name, parent);
  axi4_master_covergroup =new();
  wstrb_cg = new();
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: write
// sampling is done
//--------------------------------------------------------------------------------------------
function void axi4_master_coverage::write(axi4_master_tx t);
  // Fixed: Add null checks to prevent crashes in 10x10 configuration
  if (t == null) begin
    `uvm_warning(get_type_name(), "Null transaction received in coverage write - skipping")
    return;
  end
  
  if (axi4_master_agent_cfg_h == null) begin
    `uvm_warning(get_type_name(), "Coverage configuration not set - skipping coverage collection")
    return;
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
  
  // Report X injection detection
  if (x_inject_signal != X_INJECT_NONE) begin
    `uvm_info(get_type_name(), $sformatf("X injection detected - Signal: %s, Duration: %0d cycles", 
                                        x_inject_signal.name(), x_inject_duration), UVM_MEDIUM)
  end
  
  // Check for clock frequency changes via config_db
  void'(uvm_config_db#(real)::get(null, "*", "clk_freq_scale", clk_freq_scale_factor));
  void'(uvm_config_db#(int)::get(null, "*", "clk_freq_change_count", clk_freq_change_count));
  void'(uvm_config_db#(int)::get(null, "*", "master_intf_id", master_interface_id));
  
  // Map frequency scale to index for coverage
  if (clk_freq_scale_factor == 0.0) clk_freq_scale_idx = -1;      // Halted/gated
  else if (clk_freq_scale_factor <= 0.25) clk_freq_scale_idx = 7; // 0.25x
  else if (clk_freq_scale_factor <= 0.5) clk_freq_scale_idx = 0;  // 0.5x
  else if (clk_freq_scale_factor <= 0.75) clk_freq_scale_idx = 1; // 0.75x
  else if (clk_freq_scale_factor <= 1.0) clk_freq_scale_idx = 2;  // 1.0x
  else if (clk_freq_scale_factor <= 1.25) clk_freq_scale_idx = 3; // 1.25x
  else if (clk_freq_scale_factor <= 1.5) clk_freq_scale_idx = 4;  // 1.5x
  else if (clk_freq_scale_factor <= 2.0) clk_freq_scale_idx = 5;  // 2.0x
  else if (clk_freq_scale_factor <= 3.0) clk_freq_scale_idx = 6;  // 3.0x
  else clk_freq_scale_idx = 8;                                     // 4.0x+
  
  // Determine frequency transition pattern
  if (clk_freq_scale_factor > prev_freq_scale_factor) begin
    freq_transition_pattern = 1; // Speed up
    consecutive_freq_changes++;
  end else if (clk_freq_scale_factor < prev_freq_scale_factor) begin
    freq_transition_pattern = 2; // Slow down
    consecutive_freq_changes++;
  end else begin
    freq_transition_pattern = 0; // Steady
    consecutive_freq_changes = 0;
  end
  
  // Check if frequency change occurred during transfer
  if ((t.tx_type == WRITE || t.tx_type == READ) && 
      (clk_freq_scale_factor != prev_freq_scale_factor)) begin
    freq_change_during_transfer = 1;
  end else begin
    freq_change_during_transfer = 0;
  end
  
  // Update previous frequency for next comparison
  prev_freq_scale_factor = clk_freq_scale_factor;
  
  // Get timing metrics from config_db
  void'(uvm_config_db#(int)::get(null, "*", "freq_change_interval", freq_change_interval_cycles));
  void'(uvm_config_db#(int)::get(null, "*", "freq_hold_duration", freq_hold_duration_cycles));
  
  `uvm_info(get_type_name(),$sformatf("Before calling SAMPLE METHOD"),UVM_HIGH);

  axi4_master_covergroup.sample(axi4_master_agent_cfg_h,t);

  // Check if wstrb exists before processing
  if (t.wstrb.size() > 0) begin
    foreach(t.wstrb[i]) begin
      cov_wstrb = t.wstrb[i][3:0];
      wstrb_cg.sample();
    end
  end

  `uvm_info(get_type_name(),"After calling SAMPLE METHOD",UVM_HIGH);
endfunction: write

//--------------------------------------------------------------------------------------------
// Function: report_phase
// Used for reporting the coverage instance percentage values
//--------------------------------------------------------------------------------------------
function void axi4_master_coverage::report_phase(uvm_phase phase);
  `uvm_info(get_type_name(),$sformatf("AXI4 Master Agent Coverage = %0.2f %%", axi4_master_covergroup.get_coverage()), UVM_NONE);
endfunction: report_phase


`endif

