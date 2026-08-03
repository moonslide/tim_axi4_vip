`ifndef AXI4_SLAVE_COVERAGE_INCLUDED_
`define AXI4_SLAVE_COVERAGE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Per-channel analysis imps
//
// The slave monitor proxy publishes FIVE different packet shapes on five
// analysis ports (AW / W / B / AR / R). Every one of them is a freshly
// new()'d, 2-state axi4_slave_tx (axi4_slave_seq_item_converter::to_*_class
// all start with `output_conv_h = new()`), so every field the publishing
// channel did not observe is ZERO -- and zero is a LEGAL value for bresp and
// rresp (OKAY), for awburst and arburst (FIXED), for awsize and arsize
// (1 byte) and for every AxID (see pkg/axi4_globals_pkg.sv).
//
// The old wiring fanned all five ports into the single
// uvm_subscriber::analysis_export and unconditionally sampled ONE monolithic
// covergroup on every write(). A write-only test therefore scored first-time
// hits on the read-side bins and a read-only test polluted the write side
// symmetrically. Re-sampling the SAME real field from AW/W/B only inflates hit
// COUNTS (harmless); what inflated the PERCENTAGE was the opposite-channel and
// not-yet-observed fields scoring their FIRST hit on a legal zero bin.
//
// Each port now lands in its own write_* callback and samples only the
// covergroup whose source fields that particular packet actually carries:
//   write_saw : AW packet -> to_write_class()             : AW fields + aw/w/b_wait_states
//   write_sw  : W  packet -> to_write_addr_data_class()    : AW + W payload
//   write_sb  : B  packet -> to_write_addr_data_resp_class(): AW + W + B (complete write)
//   write_sar : AR packet -> to_read_class()               : AR fields only
//   write_sr  : R  packet -> to_read_addr_data_class()     : AR + R (complete read)
//--------------------------------------------------------------------------------------------
`uvm_analysis_imp_decl(_saw)
`uvm_analysis_imp_decl(_sw)
`uvm_analysis_imp_decl(_sb)
`uvm_analysis_imp_decl(_sar)
`uvm_analysis_imp_decl(_sr)

//--------------------------------------------------------------------------------------------
// Class: slave_coverage
// slave_coverage determines the how much code is covered for better functionality of the TB.
//--------------------------------------------------------------------------------------------
class axi4_slave_coverage extends uvm_component;
  `uvm_component_utils(axi4_slave_coverage)

  //-------------------------------------------------------
  // One analysis imp per AXI channel -- see the header note.
  //-------------------------------------------------------
  uvm_analysis_imp_saw #(axi4_slave_tx, axi4_slave_coverage) write_addr_export;
  uvm_analysis_imp_sw  #(axi4_slave_tx, axi4_slave_coverage) write_data_export;
  uvm_analysis_imp_sb  #(axi4_slave_tx, axi4_slave_coverage) write_resp_export;
  uvm_analysis_imp_sar #(axi4_slave_tx, axi4_slave_coverage) read_addr_export;
  uvm_analysis_imp_sr  #(axi4_slave_tx, axi4_slave_coverage) read_data_export;

  // Variable: axi4_slave_agent_cfg_h;
  // Handle for axi4_slave agent configuration
  axi4_slave_agent_config axi4_slave_agent_cfg_h;

  // Functional coverage for WSTRB patterns
  bit [3:0] cov_wstrb;

  // Variables to track X injection detection on slave side
  bit x_inject_bvalid_detected;
  bit x_inject_bresp_detected;
  bit x_inject_rvalid_detected;
  bit x_inject_rdata_detected;
  int x_inject_duration;

  // Enum for slave X injection signal types
  typedef enum int {
    X_INJECT_NONE = 0,
    X_INJECT_BVALID = 1,
    X_INJECT_BRESP = 2,
    X_INJECT_RVALID = 3,
    X_INJECT_RDATA = 4
  } x_inject_signal_e;

  x_inject_signal_e x_inject_signal;

  // Variables for clock frequency tracking on slave side
  real clk_freq_scale_factor = 1.0;
  int clk_freq_scale_idx;
  int clk_freq_change_count;
  real prev_freq_scale_factor = 1.0;
  int freq_transition_pattern;
  int consecutive_freq_changes;
  int freq_change_interval_cycles;
  int freq_hold_duration_cycles;
  bit freq_change_during_response;
  int slave_interface_id;  // Which slave interface experienced freq change

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
  // Covergroup: axi4_slave_write_addr_cg
  //
  // Sampled ONLY from the write-address (AW) analysis port. Every coverpoint
  // here reads a field that to_write_class() actually fills from the AW-phase
  // sample -- including aw/w/b_wait_states, which the slave converter assigns
  // ONLY on this packet (axi4_slave_seq_item_converter.sv:276-278); the
  // combined address+data and address+data+response packets leave them at 0,
  // so this is the only sample point at which they are real.
  //-------------------------------------------------------
  covergroup axi4_slave_write_addr_cg with function sample (axi4_slave_agent_config cfg, axi4_slave_tx packet);
    option.per_instance = 1;

    AWLEN_CP : coverpoint packet.awlen {
      option.comment = "Write Address Length values";
      bins AWLEN_1   = {0};
      bins AWLEN_2   = {1};
      bins AWLEN_4   = {3};
      bins AWLEN_8   = {7};
      bins AWLEN_16  = {15};
      bins AWLEN_32  = {31};
      bins AWLEN_64  = {63};
      bins AWLEN_128 = {127};
      bins AWLEN_256 = {255};
      bins AWLEN_DEFAULT = default ;
    }

    AWBURST_CP : coverpoint packet.awburst {
      option.comment = "Write Address Burst values";
      // Were named READ_FIXED / READ_WRAP on the WRITE channel, so a hole report
      // read "READ_FIXED uncovered" inside the write covergroup.
      bins WRITE_FIXED = {0};
      bins WRITE_INCR  = {1};
      bins WRITE_WRAP  = {2};
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
      option.comment = "Write Address Lock values";
      bins AWLOCK[] = {0,1};
    }

    AWCACHE_CP : coverpoint packet.awcache {
      option.comment = "Write Address Cache values";
      bins WRITE_BUFFERABLE = {0};
      bins WRITE_MODIFIABLE = {1};
      bins WRITE_OTHER_ALLOCATE = {2};
      bins WRITE_ALLOCATE   = {3};
    }

    AWPROT_CP : coverpoint packet.awprot {
      option.comment = "Write Address Protection values";
      bins AWPROT[] = {[0:$]};
    }

    AWID_CP : coverpoint packet.awid {
      option.comment = "Write Address ID values";
      bins AWID[] = {[0:$]};
    }

    //-------------------------------------------------------
    // Wait state coverage (write side)
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

    //-------------------------------------------------------
    // Exception scenarios keyed off the write ADDRESS. These stay on the AW
    // packet so a write that is deliberately ABORTED -- and therefore never
    // produces a B response -- is still counted. The response-correlated
    // versions live in axi4_slave_write_resp_cg.
    //-------------------------------------------------------

    SLAVE_TIMEOUT_CP : coverpoint packet.awaddr[15:0] iff (packet.awaddr[31:16] == 16'hDEAD) {
      option.comment = "Slave timeout stall behavior";
      bins timeout_test_address = {16'hBEEF};
      bins timeout_recovery = {16'hBEF0};
    }

    PROTECTED_ACCESS_CP : coverpoint packet.awaddr {
      option.comment = "Protected/illegal address access attempts";
      bins protected_region_1A00 = {64'h0000_0000_0000_1A00};
      bins ecc_error_region_1B00 = {64'h0000_0000_0000_1B00};
      bins special_reg_region_1C00 = {64'h0000_0000_0000_1C00};
      bins normal_regions = default;
    }

    // WRITE-side abort detection. The read-side bins that used to live in the
    // same coverpoint moved to READ_ABORT_DETECTION_CP in
    // axi4_slave_read_addr_cg: araddr is an unwritten zero on every write
    // packet, so keeping them here would make them permanently unhittable,
    // while keeping the write bins on read packets is exactly the fake-hit
    // mechanism this split removes.
    ABORT_DETECTION_CP : coverpoint packet.tx_type {
      option.comment = "Detection of aborted write transactions";
      bins awvalid_abort = {WRITE} iff (packet.awaddr == 64'h0000_0000_0000_AB01);
      bins wvalid_abort = {WRITE} iff (packet.awaddr == 64'h0000_0000_0000_AB03);
      bins wlast_abort = {WRITE} iff (packet.awaddr == 64'h0000_0000_0000_AB04);
      bins bready_abort = {WRITE} iff (packet.awaddr == 64'h0000_0000_0000_AB05);
      bins multi_abort = {WRITE} iff (packet.awaddr == 64'h0000_0000_0000_AB10);
      bins continuous_abort = {WRITE} iff (packet.awaddr == 64'h0000_0000_0000_AB11);
      bins normal_completion = default;
    }

    // Re-interpretations of AWLEN / AWSIZE / AWBURST used by the exception
    // tests; all three source fields are valid on the AW packet.
    X_INJECT_SLAVE_COUNT_CP : coverpoint packet.awlen {
      option.comment = "Number of X injection events on slave (1-20)";
      bins single_injection = {1};
      bins few_injections = {[2:5]};
      bins moderate_injections = {[6:10]};
      bins many_injections = {[11:15]};
      bins maximum_injections = {[16:20]};
    }

    EXCEPTION_RESPONSE_DELAY_CP : coverpoint packet.awsize {
      option.comment = "Response delay for exception scenarios";
      bins immediate_response = {0};
      bins short_delay = {[1:2]};
      bins medium_delay = {[3:4]};
      bins long_delay = {[5:7]};
    }

    ABORT_RECOVERY_TIME_CP : coverpoint packet.awburst {
      option.comment = "Recovery time after abort events";
      bins quick_recovery = {0};     // <10 cycles
      bins normal_recovery = {1};    // 10-50 cycles
      bins slow_recovery = {2};      // >50 cycles
    }

    // X-injection environment state. Also counted in axi4_slave_env_cg; weight
    // 0 keeps the duplicate out of this covergroup's denominator while still
    // letting the crosses below be built.
    X_INJECT_SLAVE_SIGNAL_CP : coverpoint x_inject_signal {
      option.comment = "X injection on slave response signals (at write address phase)";
      option.weight = 0;
      bins bvalid_x_detected = {X_INJECT_BVALID};
      bins bresp_x_detected = {X_INJECT_BRESP};
      bins rvalid_x_detected = {X_INJECT_RVALID};
      bins rdata_x_detected = {X_INJECT_RDATA};
      bins no_x_injection = {X_INJECT_NONE};
    }

    X_INJECT_SLAVE_DURATION_CP : coverpoint x_inject_duration {
      option.comment = "X injection duration on slave signals (at write address phase)";
      option.weight = 0;
      bins single_cycle = {1};
      bins two_cycles = {2};
      bins three_cycles = {3};
      bins four_cycles = {4};
      bins standard_range = {[5:20]};  // New standard range 5-20 cycles
      bins extended_range = {[21:50]};  // Extended for stress testing
      bins long_duration = {[51:$]};
    }

    //-------------------------------------------------------
    // Cross of coverpoints (all operands valid on the AW packet)
    //-------------------------------------------------------
    // AXI4 A3.4.1: FIXED tops out at 16 beats and WRAP is 2/4/8/16 only, so a
    // FIXED/WRAP burst longer than 16 beats cannot exist. Without these the
    // cross carries 64 impossible bins per direction.
    AWLENGTH_CP_X_AWSIZE_X_AWBURST : cross AWLEN_CP,AWSIZE_CP,AWBURST_CP {
      ignore_bins illegal_long_fixed_wrap =
        binsof(AWBURST_CP) intersect {WRITE_FIXED, WRITE_WRAP} &&
        binsof(AWLEN_CP)   intersect {31, 63, 127, 255};
    }

    X_SLAVE_SIGNAL_X_COUNT   : cross X_INJECT_SLAVE_SIGNAL_CP, X_INJECT_SLAVE_COUNT_CP;
    X_SLAVE_COUNT_X_DURATION : cross X_INJECT_SLAVE_COUNT_CP, X_INJECT_SLAVE_DURATION_CP;

    ABORT_X_RECOVERY  : cross ABORT_DETECTION_CP, ABORT_RECOVERY_TIME_CP;
    EXCEPTION_X_DELAY : cross ABORT_DETECTION_CP, EXCEPTION_RESPONSE_DELAY_CP;
    TIMEOUT_X_RECOVERY : cross SLAVE_TIMEOUT_CP, ABORT_RECOVERY_TIME_CP;

  endgroup: axi4_slave_write_addr_cg

  //-------------------------------------------------------
  // Covergroup: axi4_slave_write_resp_cg
  //
  // Sampled ONLY from the write-response (B) analysis port, i.e. on a
  // COMPLETED write. to_write_addr_data_resp_class() carries the AW fields
  // forward, so awaddr-derived coverpoints are valid here too and can
  // legitimately be crossed with BRESP. On the AW / W / AR / R packets bresp
  // is an unwritten 2-state zero, which is exactly WRITE_OKAY -- that is the
  // fake hit this split removes.
  //-------------------------------------------------------
  covergroup axi4_slave_write_resp_cg with function sample (axi4_slave_agent_config cfg, axi4_slave_tx packet);
    option.per_instance = 1;

    BID_CP : coverpoint packet.bid {
      option.comment = "Write Response ID values";
      bins BID[] = {[0:$]};
    }

    BRESP_CP : coverpoint packet.bresp {
      option.comment = "Write Response values";
      bins WRITE_OKAY   = {0};
      bins WRITE_EXOKAY = {1};
      bins WRITE_SLVERR = {2};
      bins WRITE_DECERR = {3};
    }

    SLAVE_ERROR_RESPONSE_CP : coverpoint packet.bresp {
      option.comment = "Slave error response generation for exceptions";
      bins slverr_for_protected = {2} iff (packet.awaddr == 64'h0000_0000_0000_1A00);
      bins slverr_for_ecc = {2} iff (packet.awaddr == 64'h0000_0000_0000_1B00);
      bins okay_response = {0};
      bins normal_response = default;
    }

    // Cross-partner copies. Already counted in axi4_slave_write_addr_cg /
    // axi4_slave_env_cg, so weight 0 keeps them out of this denominator.
    PROTECTED_ACCESS_CP : coverpoint packet.awaddr {
      option.comment = "Protected/illegal address of a COMPLETED write";
      option.weight = 0;
      bins protected_region_1A00 = {64'h0000_0000_0000_1A00};
      bins ecc_error_region_1B00 = {64'h0000_0000_0000_1B00};
      bins special_reg_region_1C00 = {64'h0000_0000_0000_1C00};
      bins normal_regions = default;
    }

    X_INJECT_SLAVE_SIGNAL_CP : coverpoint x_inject_signal {
      option.comment = "X injection on slave response signals at write response";
      option.weight = 0;
      bins bvalid_x_detected = {X_INJECT_BVALID};
      bins bresp_x_detected = {X_INJECT_BRESP};
      bins rvalid_x_detected = {X_INJECT_RVALID};
      bins rdata_x_detected = {X_INJECT_RDATA};
      bins no_x_injection = {X_INJECT_NONE};
    }

    SLAVE_CLK_FREQ_SCALE_CP : coverpoint clk_freq_scale_idx {
      option.comment = "Slave clock frequency scaling factor at write response";
      option.weight = 0;
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

    //-------------------------------------------------------
    // Cross of coverpoints (all operands valid on a completed write)
    //-------------------------------------------------------
    BID_CP_X_BRESP_CP           : cross BID_CP,BRESP_CP;
    X_SLAVE_SIGNAL_X_RESPONSE   : cross X_INJECT_SLAVE_SIGNAL_CP, SLAVE_ERROR_RESPONSE_CP;
    PROTECTED_ACCESS_X_RESPONSE : cross PROTECTED_ACCESS_CP, SLAVE_ERROR_RESPONSE_CP;
    SLAVE_FREQ_X_RESPONSE       : cross SLAVE_CLK_FREQ_SCALE_CP, packet.bresp;

  endgroup: axi4_slave_write_resp_cg

  //-------------------------------------------------------
  // Covergroup: axi4_slave_read_addr_cg
  //
  // Sampled ONLY from the read-address (AR) analysis port. to_read_class()
  // fills the AR fields; rid/rresp on that packet come from the AR-phase
  // struct and are not a real read response, so they are NOT covered here.
  //-------------------------------------------------------
  covergroup axi4_slave_read_addr_cg with function sample (axi4_slave_agent_config cfg, axi4_slave_tx packet);
    option.per_instance = 1;

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
      bins ARLEN_DEFAULT = default ;
    }

    ARBURST_CP : coverpoint packet.arburst {
      option.comment = "Read Address Burst values";
      // WRITE_INCR was the bin name on the READ channel -- see AWBURST_CP above.
      bins READ_FIXED = {0};
      bins READ_INCR  = {1};
      bins READ_WRAP  = {2};
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
      bins READ_BUFFERABLE      = {0};
      bins READ_MODIFIABLE      = {1};
      bins READ_OTHER_ALLOCATE  = {2};
      bins READ_ALLOCATE        = {3};
    }

    ARPROT_CP : coverpoint packet.arprot {
      option.comment = "Read Address Protection values";
      bins ARPROT[] = {[0:$]};
    }

    // Sampled packet.rid, so this was a duplicate of RID_CP and the read
    // ADDRESS id was never covered at all. Same defect existed on the master side.
    ARID_CP : coverpoint packet.arid {
      option.comment = "Read Address ID values";
      bins ARID[] = {[0:$]};
    }

    //-------------------------------------------------------
    // Wait state coverage (read side)
    //-------------------------------------------------------

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

    // Special register behavior (read address keyed)
    SPECIAL_REG_BEHAVIOR_CP : coverpoint packet.araddr[7:0] iff (packet.araddr == 64'h0000_0000_0000_1C00) {
      option.comment = "Special register read behaviors";
      bins read_to_clear = {8'h00};
      bins counter_increment = {8'h01};
      bins constant_value = {8'h02};
      bins status_register = {8'h03};
    }

    // READ-side half of the old ABORT_DETECTION_CP. Split out because araddr
    // is an unwritten zero on every write-channel packet.
    READ_ABORT_DETECTION_CP : coverpoint packet.tx_type {
      option.comment = "Detection of aborted read transactions";
      bins arvalid_abort = {READ} iff (packet.araddr == 64'h0000_0000_0000_AB02);
      bins rready_abort = {READ} iff (packet.araddr == 64'h0000_0000_0000_AB06);
      bins normal_completion = default;
    }

    ARLENGTH_CP_X_ARSIZE_X_ARBURST : cross ARLEN_CP,ARSIZE_CP,ARBURST_CP {
      ignore_bins illegal_long_fixed_wrap =
        binsof(ARBURST_CP) intersect {READ_FIXED, READ_WRAP} &&
        binsof(ARLEN_CP)   intersect {31, 63, 127, 255};
    }

  endgroup: axi4_slave_read_addr_cg

  //-------------------------------------------------------
  // Covergroup: axi4_slave_read_data_cg
  //
  // Sampled ONLY from the read-data (R) analysis port, i.e. on a COMPLETED
  // read. On every write-side packet rid/rresp are unwritten 2-state zeros,
  // which read as RID_0 and READ_OKAY -- the fake hits this split removes.
  //-------------------------------------------------------
  covergroup axi4_slave_read_data_cg with function sample (axi4_slave_agent_config cfg, axi4_slave_tx packet);
    option.per_instance = 1;

    RID_CP : coverpoint packet.rid {
      option.comment = "Read ID values";
      bins RID[] = {[0:$]};
    }

    RRESP_CP : coverpoint packet.rresp {
      option.comment = "Read Response values";
      bins READ_OKAY   = {0};
      bins READ_EXOKAY = {1};
      bins READ_SLVERR = {2};
      bins READ_DECERR = {3};
    }

    // Was `cross BID_CP,BRESP_CP` -- a copy of the write-side cross under a
    // read-side name, so RID/RRESP correlation was never collected and the
    // report showed the write-side cross twice. Same defect existed on the
    // master side.
    RID_CP_X_RRESP_CP : cross RID_CP,RRESP_CP;

  endgroup: axi4_slave_read_data_cg

  //-------------------------------------------------------
  // Covergroup: axi4_slave_env_cg
  //
  // Channel-agnostic state: agent configuration plus the clock-frequency and
  // X-injection environment state this component pulls out of the config_db.
  // None of it comes from a channel-specific packet field, so it is sampled on
  // every published packet exactly as before. packet.tx_type IS valid on every
  // packet (the write converters set WRITE explicitly and the read converters
  // leave the 2-state default 0, which IS READ -- see tx_type_e in
  // pkg/axi4_globals_pkg.sv).
  //-------------------------------------------------------
  covergroup axi4_slave_env_cg with function sample (axi4_slave_agent_config cfg, axi4_slave_tx packet);
    option.per_instance = 1;

    // Legal address widths span from 1 to 64 bits.  Create a bin for
    // every value so that coverage reflects exactly which widths were used.
    ADDR_WIDTH_CP : coverpoint cfg.addr_width {
      bins width[] = {[1:64]};
    }

    // Data width may only be one of the AMBA defined power-of-two widths.
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

    // NOTE: no slave struct->class converter ever assigns transfer_type, so
    // this coverpoint reads the 2-state default on every monitored packet and
    // can only ever hit BLOCKING_WRITE. That is a converter gap, reported
    // separately -- it is not fixed by the channel split.
    TRANSFER_TYPE_CP : coverpoint packet.transfer_type {
      option.comment = "transfer type";
      bins BLOCKING_WRITE     = {0};
      bins BLOCKING_READ      = {1};
      bins NON_BLOCKING_WRITE = {2};
      bins NON_BLOCKING_READ  = {3};
    }

    // X-value detection. Each bin guards itself on the channel it belongs to
    // (tx_type plus the address/data of that channel), so it stays correct on
    // every packet shape.
    X_VALUE_DETECTION_CP : coverpoint packet.tx_type {
      option.comment = "Detection of X values on slave input signals";
      bins x_on_awaddr = {WRITE} iff ($isunknown(packet.awaddr));
      bins x_on_wdata = {WRITE} iff (packet.wdata.size() > 0 && $isunknown(packet.wdata[0]));
      bins x_on_araddr = {READ} iff ($isunknown(packet.araddr));
      bins normal_signals = default;
    }

    X_INJECT_SLAVE_SIGNAL_CP : coverpoint x_inject_signal {
      option.comment = "X injection on slave response signals";
      bins bvalid_x_detected = {X_INJECT_BVALID};
      bins bresp_x_detected = {X_INJECT_BRESP};
      bins rvalid_x_detected = {X_INJECT_RVALID};
      bins rdata_x_detected = {X_INJECT_RDATA};
      bins no_x_injection = {X_INJECT_NONE};
    }

    X_INJECT_SLAVE_DURATION_CP : coverpoint x_inject_duration {
      option.comment = "X injection duration on slave signals";
      bins single_cycle = {1};
      bins two_cycles = {2};
      bins three_cycles = {3};
      bins four_cycles = {4};
      bins standard_range = {[5:20]};  // New standard range 5-20 cycles
      bins extended_range = {[21:50]};  // Extended for stress testing
      bins long_duration = {[51:$]};
    }

    SLAVE_CLK_FREQ_SCALE_CP : coverpoint clk_freq_scale_idx {
      option.comment = "Slave clock frequency scaling factor";
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

    SLAVE_FREQ_CHANGE_COUNT_CP : coverpoint clk_freq_change_count {
      option.comment = "Number of slave clock frequency changes";
      bins single_change = {1};
      bins few_changes = {[2:3]};
      bins moderate_changes = {[4:6]};
      bins many_changes = {[7:10]};
      bins excessive_changes = {[11:$]};
    }

    SLAVE_FREQ_PATTERN_CP : coverpoint freq_transition_pattern {
      option.comment = "Slave frequency transition pattern";
      bins steady = {0};
      bins speed_up = {1};
      bins slow_down = {2};
      bins oscillating = {3};
    }

    SLAVE_CONSECUTIVE_FREQ_CP : coverpoint consecutive_freq_changes {
      option.comment = "Back-to-back slave frequency changes";
      bins single = {1};
      bins burst_2_3 = {[2:3]};
      bins burst_4_6 = {[4:6]};
      bins burst_many = {[7:$]};
    }

    FREQ_DURING_RESPONSE_CP : coverpoint freq_change_during_response {
      option.comment = "Frequency changed during response phase";
      bins no_change = {0};
      bins changed = {1};
    }

    SLAVE_INTF_FREQ_CP : coverpoint slave_interface_id {
      option.comment = "Slave interface with frequency change";
      bins slave[10] = {[0:9]};
    }

    //-------------------------------------------------------
    // Cross of coverpoints
    //-------------------------------------------------------
    ADDR_DATA_WIDTH_CP : cross ADDR_WIDTH_CP, DATA_WIDTH_CP;

    X_SLAVE_SIGNAL_X_DURATION : cross X_INJECT_SLAVE_SIGNAL_CP, X_INJECT_SLAVE_DURATION_CP;

    SLAVE_FREQ_X_TRANSFER : cross SLAVE_CLK_FREQ_SCALE_CP, TRANSFER_TYPE_CP;
    SLAVE_FREQ_X_PATTERN  : cross SLAVE_CLK_FREQ_SCALE_CP, SLAVE_FREQ_PATTERN_CP;
    SLAVE_INTF_X_SCALE    : cross SLAVE_INTF_FREQ_CP, SLAVE_CLK_FREQ_SCALE_CP;
    FREQ_DURING_RESP_X_TYPE : cross FREQ_DURING_RESPONSE_CP, TRANSFER_TYPE_CP;

  endgroup: axi4_slave_env_cg

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_slave_coverage", uvm_component parent = null);
  extern virtual function bit sample_ok(axi4_slave_tx t);
  extern virtual function void collect_env_state(axi4_slave_tx t);
  extern virtual function void write_saw(axi4_slave_tx t);
  extern virtual function void write_sw(axi4_slave_tx t);
  extern virtual function void write_sb(axi4_slave_tx t);
  extern virtual function void write_sar(axi4_slave_tx t);
  extern virtual function void write_sr(axi4_slave_tx t);
  extern virtual function void report_phase(uvm_phase phase);
endclass : axi4_slave_coverage

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_slave_coverage
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_slave_coverage::new(string name = "axi4_slave_coverage",uvm_component parent = null);
  super.new(name, parent);
  axi4_slave_write_addr_cg = new();
  axi4_slave_write_resp_cg = new();
  axi4_slave_read_addr_cg  = new();
  axi4_slave_read_data_cg  = new();
  axi4_slave_env_cg        = new();
  wstrb_cg                 = new();

  write_addr_export = new("write_addr_export", this);
  write_data_export = new("write_data_export", this);
  write_resp_export = new("write_resp_export", this);
  read_addr_export  = new("read_addr_export",  this);
  read_data_export  = new("read_data_export",  this);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: sample_ok
// Common guard shared by every channel callback.
//--------------------------------------------------------------------------------------------
function bit axi4_slave_coverage::sample_ok(axi4_slave_tx t);
  // Fixed: Add null checks to prevent crashes in 10x10 configuration
  if (t == null) begin
    `uvm_warning(get_type_name(), "Null transaction received in coverage write - skipping")
    return 0;
  end

  if (axi4_slave_agent_cfg_h == null) begin
    `uvm_warning(get_type_name(), "Coverage configuration not set - skipping coverage collection")
    return 0;
  end
  return 1;
endfunction : sample_ok

//--------------------------------------------------------------------------------------------
// Function: collect_env_state
// Pulls the X-injection / clock-frequency environment state out of the
// config_db. Called once per published packet, exactly as the single write()
// used to be, so the freq-transition state machine below sees the same call
// sequence it did before the channel split.
//--------------------------------------------------------------------------------------------
function void axi4_slave_coverage::collect_env_state(axi4_slave_tx t);

  // Check for X injection signals on slave side via config_db
  void'(uvm_config_db#(bit)::get(null, "*", "x_inject_bvalid", x_inject_bvalid_detected));
  void'(uvm_config_db#(bit)::get(null, "*", "x_inject_bresp", x_inject_bresp_detected));
  void'(uvm_config_db#(bit)::get(null, "*", "x_inject_rvalid", x_inject_rvalid_detected));
  void'(uvm_config_db#(bit)::get(null, "*", "x_inject_rdata", x_inject_rdata_detected));
  void'(uvm_config_db#(int)::get(null, "*", "x_inject_cycles", x_inject_duration));

  // Determine which X injection signal is active on slave
  if (x_inject_bvalid_detected) x_inject_signal = X_INJECT_BVALID;
  else if (x_inject_bresp_detected) x_inject_signal = X_INJECT_BRESP;
  else if (x_inject_rvalid_detected) x_inject_signal = X_INJECT_RVALID;
  else if (x_inject_rdata_detected) x_inject_signal = X_INJECT_RDATA;
  else x_inject_signal = X_INJECT_NONE;

  // Report X injection detection on slave
  if (x_inject_signal != X_INJECT_NONE) begin
    `uvm_info(get_type_name(), $sformatf("Slave X injection detected - Signal: %s, Duration: %0d cycles",
                                        x_inject_signal.name(), x_inject_duration), UVM_MEDIUM)
  end

  // Check for clock frequency changes on slave via config_db
  void'(uvm_config_db#(real)::get(null, "*", "slave_clk_freq_scale", clk_freq_scale_factor));
  if (clk_freq_scale_factor == 0.0) begin
    // If no slave-specific frequency, check global
    void'(uvm_config_db#(real)::get(null, "*", "clk_freq_scale", clk_freq_scale_factor));
  end
  void'(uvm_config_db#(int)::get(null, "*", "slave_freq_change_count", clk_freq_change_count));
  void'(uvm_config_db#(int)::get(null, "*", "slave_intf_id", slave_interface_id));

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

  // Check if frequency change occurred during response phase
  if ((t.transfer_type == BLOCKING_WRITE || t.transfer_type == NON_BLOCKING_WRITE) &&
      (t.bresp != 2'b00) && (clk_freq_scale_factor != prev_freq_scale_factor)) begin
    freq_change_during_response = 1;
  end else if ((t.transfer_type == BLOCKING_READ || t.transfer_type == NON_BLOCKING_READ) &&
               (t.rresp != 2'b00) && (clk_freq_scale_factor != prev_freq_scale_factor)) begin
    freq_change_during_response = 1;
  end else begin
    freq_change_during_response = 0;
  end

  // Update previous frequency for next comparison
  prev_freq_scale_factor = clk_freq_scale_factor;

  // Get timing metrics from config_db
  void'(uvm_config_db#(int)::get(null, "*", "freq_change_interval", freq_change_interval_cycles));
  void'(uvm_config_db#(int)::get(null, "*", "freq_hold_duration", freq_hold_duration_cycles));

endfunction : collect_env_state

//--------------------------------------------------------------------------------------------
// Function: write_saw
// Write ADDRESS channel packet: AW fields plus the wait-state counters.
//--------------------------------------------------------------------------------------------
function void axi4_slave_coverage::write_saw(axi4_slave_tx t);
  if (!sample_ok(t)) return;
  collect_env_state(t);
  axi4_slave_write_addr_cg.sample(axi4_slave_agent_cfg_h, t);
  axi4_slave_env_cg.sample(axi4_slave_agent_cfg_h, t);
endfunction : write_saw

//--------------------------------------------------------------------------------------------
// Function: write_sw
// Write DATA channel packet: AW fields plus the reconstructed WDATA/WSTRB
// burst. This is the only packet on which the beat payload is rebuilt from
// AWLEN, so it is the correct and only sampling point for wstrb_cg.
//--------------------------------------------------------------------------------------------
function void axi4_slave_coverage::write_sw(axi4_slave_tx t);
  if (!sample_ok(t)) return;
  collect_env_state(t);
  axi4_slave_env_cg.sample(axi4_slave_agent_cfg_h, t);

  // Check if wstrb exists before processing
  if (t.wstrb.size() > 0) begin
    foreach(t.wstrb[i]) begin
      cov_wstrb = t.wstrb[i][3:0];
      wstrb_cg.sample();
    end
  end
endfunction : write_sw

//--------------------------------------------------------------------------------------------
// Function: write_sb
// Write RESPONSE channel packet: the complete write (AW + W + B).
//--------------------------------------------------------------------------------------------
function void axi4_slave_coverage::write_sb(axi4_slave_tx t);
  if (!sample_ok(t)) return;
  collect_env_state(t);
  axi4_slave_write_resp_cg.sample(axi4_slave_agent_cfg_h, t);
  axi4_slave_env_cg.sample(axi4_slave_agent_cfg_h, t);
endfunction : write_sb

//--------------------------------------------------------------------------------------------
// Function: write_sar
// Read ADDRESS channel packet: AR fields only.
//--------------------------------------------------------------------------------------------
function void axi4_slave_coverage::write_sar(axi4_slave_tx t);
  if (!sample_ok(t)) return;
  collect_env_state(t);
  axi4_slave_read_addr_cg.sample(axi4_slave_agent_cfg_h, t);
  axi4_slave_env_cg.sample(axi4_slave_agent_cfg_h, t);
endfunction : write_sar

//--------------------------------------------------------------------------------------------
// Function: write_sr
// Read DATA channel packet: the complete read (AR + R).
//--------------------------------------------------------------------------------------------
function void axi4_slave_coverage::write_sr(axi4_slave_tx t);
  if (!sample_ok(t)) return;
  collect_env_state(t);
  axi4_slave_read_data_cg.sample(axi4_slave_agent_cfg_h, t);
  axi4_slave_env_cg.sample(axi4_slave_agent_cfg_h, t);
endfunction : write_sr

//--------------------------------------------------------------------------------------------
// Function: report_phase
// Used for reporting the coverage instance percentage values
//--------------------------------------------------------------------------------------------
function void axi4_slave_coverage::report_phase(uvm_phase phase);
  `uvm_info(get_type_name(),$sformatf("AXI4 Slave Agent Coverage : write_addr = %0.2f %%, write_resp = %0.2f %%, read_addr = %0.2f %%, read_data = %0.2f %%, env = %0.2f %%",
                                      axi4_slave_write_addr_cg.get_coverage(),
                                      axi4_slave_write_resp_cg.get_coverage(),
                                      axi4_slave_read_addr_cg.get_coverage(),
                                      axi4_slave_read_data_cg.get_coverage(),
                                      axi4_slave_env_cg.get_coverage()), UVM_NONE);
endfunction: report_phase


`endif

