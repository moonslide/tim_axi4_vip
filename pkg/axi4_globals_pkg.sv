`ifndef AXI4_GLOBALS_PKG_INCLUDED_
`define AXI4_GLOBALS_PKG_INCLUDED_

// Include compile-time configuration defines
`include "axi4_defines.svh"
`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Package: axi4_globals_pkg
// Used for storing enums, parameters and defining the structs
//--------------------------------------------------------------------------------------------
package axi4_globals_pkg;

  //-------------------------------------------------------
  // Parameters used in axi4_avip are given below
  //-------------------------------------------------------
  //Parameter: MASTER_AGENT_ACTIVE
  //Used to set the master agent either active or passive
  parameter bit MASTER_AGENT_ACTIVE = 1;

  //Parameter: SLAVE_AGENT_ACTIVE
  //Used to set the slave agent either active or passive
  parameter bit SLAVE_AGENT_ACTIVE = 1;

  //Parameter: NO_OF_MASTERS
  //Used to set number of masters required (Configurable via compile-time defines)
  parameter int NO_OF_MASTERS = `AXI4_NUM_MASTERS;

  //Parameter: NO_OF_SLAVES
  //Used to set number of slaves required (Configurable via compile-time defines)
  parameter int NO_OF_SLAVES = `AXI4_NUM_SLAVES;

  //Parameter: ADDRESS_WIDTH
  //Used to set the address width to the address bus
  parameter int ADDRESS_WIDTH = 64;

  // Default stays 1024 so existing regressions are unaffected. Track-B builds
  // against the commercial fabric IP compile with +define+DATA_WIDTH=256, which is
  // the widest data bus the commercial fabric IP supports (legal values 32/64/128/256).
  `ifndef DATA_WIDTH
    `define DATA_WIDTH 1024
  `endif
  //Parameter: DATA_WIDTH
  //Used to set the data width
  parameter int DATA_WIDTH = `DATA_WIDTH;

  //Parameter: SLAVE_MEMORY_SIZE
  //Sets the memory size of the slave in KB
  parameter int SLAVE_MEMORY_SIZE = 12;

  //Parameter: SLAVE_MEMORY_GAP
  //Sets the memory gap size of the slave
  parameter int SLAVE_MEMORY_GAP = 2;

  //Parameter: MEMORY_WIDTH
  //Sets the width it can store in each location
  parameter int MEMORY_WIDTH = 8;

  //Parameter: STROBE_WIDTH
  //Used to define the width of the strobes
  parameter int STROBE_WIDTH = (DATA_WIDTH/8);

  //Variable: MEM_ID
  //Indicates Slave Memory Depth 
  parameter int MEM_ID = 2**ADDRESS_WIDTH;

  //Variable: LENGTH
  //Indicates the length of the address write and read channels
  parameter int LENGTH = 8;

  //Variable: OUTSTANDING_FIFO_DEPTH
  //Upper bound on the outstanding depth a manager agent may be configured for.
  //Read by axi4_master_driver_proxy::configure_outstanding_credits(), which sizes
  //the three per-channel credit semaphores from
  //axi4_master_agent_config::outstanding_write_tx / outstanding_read_tx and clamps
  //them here with a warning.
  //(Until AXI_ooo.md Phase 4 / P4.1 this parameter had zero readers repo-wide -
  //it was the dead half of the equally dead outstanding-depth knob, AXI_ooo.md
  //F4. Revived rather than deleted, per VIP_future.md ST-A2.)
  parameter int OUTSTANDING_FIFO_DEPTH = 16;

  //Variable: R_BEAT_STALL_MAX
  //Upper bound on axi4_master_tx::r_stall_cycles, the number of clock cycles the
  //manager holds RREADY low in front of one requested interior beat of a read
  //burst (BENCH-065). It is the declared response-bound policy the BENCH record
  //asks for: with at most OUTSTANDING_FIFO_DEPTH reads truly in flight and one
  //stall per read, the worst-case delay a claim task can see ahead of its own
  //burst stays well under the read-data claim escape
  //(axi4_master_driver_bfm.sv, R_CLAIM_ESCAPE_CYCLES = 50000), so a legal stall
  //can never be mistaken for the abandoned-burst failure of landmine #37. The
  //driver BFM checks that product at time 0.
  parameter int R_BEAT_STALL_MAX = 1000;

  //-------------------------------------------------------
  // Enums used in axi4_avip are given below
  //-------------------------------------------------------
  
  //Enum: awburst_e
  //Used to declare the enum type of write burst type
  typedef enum bit [1:0] {
    WRITE_FIXED    = 2'b00,
    WRITE_INCR     = 2'b01,
    WRITE_WRAP     = 2'b10,
    WRITE_RESERVED = 2'b11
  } awburst_e;

  //Enum: arburst_e
  //Used to declare the enum type of read burst type
  typedef enum bit [1:0] {
    READ_FIXED    = 2'b00,
    READ_INCR     = 2'b01,
    READ_WRAP     = 2'b10,
    READ_RESERVED = 2'b11
  } arburst_e;

  //Enum: transfer_size_e
  //Used to declare enum type for write transfer sizes
  typedef enum bit [2:0] {
    WRITE_1_BYTE    = 3'b000,
    WRITE_2_BYTES   = 3'b001,
    WRITE_4_BYTES   = 3'b010,
    WRITE_8_BYTES   = 3'b011,
    WRITE_16_BYTES  = 3'b100,
    WRITE_32_BYTES  = 3'b101,
    WRITE_64_BYTES  = 3'b110,
    WRITE_128_BYTES = 3'b111
  } awsize_e;

  //Enum: transfer_size_e
  //Used to declare enum type for read transfer sizes
  typedef enum bit [2:0] {
    READ_1_BYTE    = 3'b000,
    READ_2_BYTES   = 3'b001,
    READ_4_BYTES   = 3'b010,
    READ_8_BYTES   = 3'b011,
    READ_16_BYTES  = 3'b100,
    READ_32_BYTES  = 3'b101,
    READ_64_BYTES  = 3'b110,
    READ_128_BYTES = 3'b111
  } arsize_e;

  //Enum: awlock_e
  //Used to declare enum type for write lock access
  typedef enum bit {
    WRITE_NORMAL_ACCESS    = 1'b0,
    WRITE_EXCLUSIVE_ACCESS = 1'b1
  } awlock_e;

  //Enum: arlock_e
  //Used to declare enum type for read lock access
  typedef enum bit {
    READ_NORMAL_ACCESS    = 1'b0,
    READ_EXCLUSIVE_ACCESS = 1'b1
  } arlock_e;

  //Enum: awcache_e
  //Used to declare enum type for write cache access
  typedef enum bit [3:0] {
    WRITE_BUFFERABLE,
    WRITE_MODIFIABLE,
    WRITE_OTHER_ALLOCATE,
    WRITE_ALLOCATE
  } awcache_e;

  //Enum: arcache_e
  //Used to declare enum type for read cache access
  typedef enum bit [3:0] {
    READ_BUFFERABLE,
    READ_MODIFIABLE,
    READ_OTHER_ALLOCATE,
    READ_ALLOCATE
  } arcache_e;

  //Enum: endian_e
  //Used to declare enum type for the endians
  typedef enum bit {
    BIG_ENDIAN    = 1'b0,
    LITTLE_ENDIAN = 1'b1
  } endian_e;

  //Enum: awprot_e 
  //Used to declare enum type of write protection of the transaction
  typedef enum bit [2:0] {
    WRITE_NORMAL_SECURE_DATA               = 3'b000,
    WRITE_NORMAL_SECURE_INSTRUCTION        = 3'b001,
    WRITE_NORMAL_NONSECURE_DATA            = 3'b010,
    WRITE_NORMAL_NONSECURE_INSTRUCTION     = 3'b011,
    WRITE_PRIVILEGED_SECURE_DATA           = 3'b100,
    WRITE_PRIVILEGED_SECURE_INSTRUCTION    = 3'b101,
    WRITE_PRIVILEGED_NONSECURE_DATA        = 3'b110,
    WRITE_PRIVILEGED_NONSECURE_INSTRUCTION = 3'b111
  } awprot_e;

  //Enum: arprot_e 
  //Used to declare enum type of read protection of the transaction
  typedef enum bit [2:0] {
    READ_NORMAL_SECURE_DATA               = 3'b000,
    READ_NORMAL_SECURE_INSTRUCTION        = 3'b001,
    READ_NORMAL_NONSECURE_DATA            = 3'b010,
    READ_NORMAL_NONSECURE_INSTRUCTION     = 3'b011,
    READ_PRIVILEGED_SECURE_DATA           = 3'b100,
    READ_PRIVILEGED_SECURE_INSTRUCTION    = 3'b101,
    READ_PRIVILEGED_NONSECURE_DATA        = 3'b110,
    READ_PRIVILEGED_NONSECURE_INSTRUCTION = 3'b111
  } arprot_e;

  //Enum: awid_e
  //Used to declare the enum type of write address id
  // The named range expands to AWID_0 .. AWID_{2**AXI_ID_WIDTH-1}. At the
  // default AXI_ID_WIDTH of 4 that is AWID_0..AWID_15 with values 0..15, i.e.
  // bit-identical to the explicit list this replaced. It has to follow
  // AXI_ID_WIDTH because the converters assign these fields with $cast, which
  // is runtime-checked against the member list: behind an interconnect that
  // widens AxID (the commercial fabric IP appends the ingress-port index) the cast of an
  // out-of-range value FAILS SILENTLY and leaves the previous ID in place.
  typedef enum bit [15:0] {
    AWID_[0:`AXI_ID_LAST]
  } awid_e;

  //Enum: bid_e
  //Used to declare the enum type of write response id
  // The named range expands to AWID_0 .. AWID_{2**AXI_ID_WIDTH-1}. At the
  // default AXI_ID_WIDTH of 4 that is AWID_0..AWID_15 with values 0..15, i.e.
  // bit-identical to the explicit list this replaced. It has to follow
  // AXI_ID_WIDTH because the converters assign these fields with $cast, which
  // is runtime-checked against the member list: behind an interconnect that
  // widens AxID (the commercial fabric IP appends the ingress-port index) the cast of an
  // out-of-range value FAILS SILENTLY and leaves the previous ID in place.
  typedef enum bit [15:0] {
    BID_[0:`AXI_ID_LAST]
  } bid_e;

  //Enum: arid_e
  //Used to declare the enum type of read address id
  // The named range expands to AWID_0 .. AWID_{2**AXI_ID_WIDTH-1}. At the
  // default AXI_ID_WIDTH of 4 that is AWID_0..AWID_15 with values 0..15, i.e.
  // bit-identical to the explicit list this replaced. It has to follow
  // AXI_ID_WIDTH because the converters assign these fields with $cast, which
  // is runtime-checked against the member list: behind an interconnect that
  // widens AxID (the commercial fabric IP appends the ingress-port index) the cast of an
  // out-of-range value FAILS SILENTLY and leaves the previous ID in place.
  typedef enum bit [15:0] {
    ARID_[0:`AXI_ID_LAST]
  } arid_e;

  //Enum: rid_e
  //Used to declare the enum type of read data/response id
  // The named range expands to AWID_0 .. AWID_{2**AXI_ID_WIDTH-1}. At the
  // default AXI_ID_WIDTH of 4 that is AWID_0..AWID_15 with values 0..15, i.e.
  // bit-identical to the explicit list this replaced. It has to follow
  // AXI_ID_WIDTH because the converters assign these fields with $cast, which
  // is runtime-checked against the member list: behind an interconnect that
  // widens AxID (the commercial fabric IP appends the ingress-port index) the cast of an
  // out-of-range value FAILS SILENTLY and leaves the previous ID in place.
  typedef enum bit [15:0] {
    RID_[0:`AXI_ID_LAST]
  } rid_e;

  //Enum: bresp_e
  //Used to declare the enum type of write response
  typedef enum bit [1:0] {
    WRITE_OKAY   = 2'b00,
    WRITE_EXOKAY = 2'b01,
    WRITE_SLVERR = 2'b10,
    WRITE_DECERR = 2'b11
  } bresp_e;

  //Enum: rresp_e
  //Used to declare the enum type of read response
  typedef enum bit [1:0] {
    READ_OKAY   = 2'b00,
    READ_EXOKAY = 2'b01,
    READ_SLVERR = 2'b10,
    READ_DECERR = 2'b11
  } rresp_e;

  //Enum: tx_type
  //Used to declare the type of transaction done
  typedef enum bit {
    WRITE = 1,
    READ  = 0
  } tx_type_e;

  //Enum : transfer_type_e
  //Used to the determine the type of the transfer
  typedef enum bit[1:0] {
    BLOCKING_WRITE      = 2'b00, 
    BLOCKING_READ       = 2'b01, 
    NON_BLOCKING_WRITE  = 2'b10, 
    NON_BLOCKING_READ   = 2'b11 
  }transfer_type_e;

  //Enum : read_data_type_mode_e
  //Used to the determine the type of the read data
  typedef enum bit[1:0] {
    RANDOM_DATA_MODE = 2'b00,
    SLAVE_MEM_MODE   = 2'b01,
    USER_DATA_MODE   = 2'b10,
    SLAVE_ERR_RESP_MODE = 2'b11
  } read_data_type_mode_e;

  //Enum : transfer_type_e  
  //Used to determine the mode for score board check 
  typedef enum bit[1:0] {
    ONLY_WRITE_DATA  = 2'b00,
    ONLY_READ_DATA   = 2'b01,
    WRITE_READ_DATA  = 2'b10
  } write_read_data_mode_e;
  
  //Enum : Response_mode_e  
  //Used to determine the mode of response to send
  typedef enum bit[1:0] {
    RESP_IN_ORDER                 = 2'b00,
    ONLY_READ_RESP_OUT_OF_ORDER   = 2'b01,
    WRITE_READ_RESP_OUT_OF_ORDER  = 2'b10,
    ONLY_WRITE_RESP_OUT_OF_ORDER  = 2'b11
  } response_mode_e;

  //Enum : QoS_mode_e
  typedef enum bit[1:0] {
    QOS_MODE_DISABLE            = 2'b00,
    ONLY_READ_QOS_MODE_ENABLE   = 2'b01,
    WRITE_READ_QOS_MODE_ENABLE  = 2'b10,
    ONLY_WRITE_QOS_MODE_ENABLE  = 2'b11
  } qos_mode_e;

  //Enum : axqos_src_e
  //Where a manager agent takes the AxQOS value it drives from, per channel
  //(axi4_master_agent_config::awqos_src / arqos_src). Applied by the master
  //driver proxy after get_next_item(); the value is written back into the
  //sequence item, so sequence, monitor and scoreboard all see the same value.
  //AXQOS_SRC_SEQ is the default and leaves the sequence item untouched.
  typedef enum bit [1:0] {
    AXQOS_SRC_SEQ   = 2'd0,  // whatever the sequence item carries (legacy)
    AXQOS_SRC_CONST = 2'd1,  // every request uses <ch>qos_const
    AXQOS_SRC_SPAN  = 2'd2,  // uniform in [<ch>qos_span_lo : <ch>qos_span_hi]
    AXQOS_SRC_ZERO  = 2'd3   // a manager without a QoS signal: always 0
  } axqos_src_e;

  //Enum : wr_qos_arb_point_e
  //Where a manager with write QoS enabled (qos_mode_type ONLY_WRITE / WRITE_READ)
  //applies its AWQOS priority (axi4_master_agent_config::wr_qos_arb_point).
  //  WR_QOS_ARB_AT_WDATA (default, legacy): AWs are issued in the order the
  //    sequencer delivers them; the W-data thread then picks the queued write
  //    with the highest AWQOS. AXI4 has no WID, so when the highest-AWQOS write
  //    is not the oldest issued AW, its W burst goes out ahead of an older AW's
  //    and the subordinate pairs the data with the wrong address (A3.4.1).
  //    Same-AWID writes are kept in order, so stimulus with one AWID per
  //    manager never shows it.
  //  WR_QOS_ARB_AT_AW: the manager collects pending writes and lets AWQOS
  //    decide which AW is issued next; W bursts then follow AW order exactly as
  //    with QoS off. Protocol-correct; an option until a human flips the default.
  typedef enum bit {
    WR_QOS_ARB_AT_WDATA = 1'b0,
    WR_QOS_ARB_AT_AW    = 1'b1
  } wr_qos_arb_point_e;

  //Enum : qos_hold_scope_e
  //When the subordinate read-QoS arbiter holds R responses back to let a pool
  //of reads build up (axi4_slave_agent_config::rd_qos_hold_scope).
  typedef enum bit {
    QOS_HOLD_FIRST = 1'b0,   // hold only before the first response (legacy)
    QOS_HOLD_EACH  = 1'b1    // hold before every response
  } qos_hold_scope_e;

  //Used to store the awid for Qos mode
  awid_e awid_queue_for_qos[$];

  //-------------------------------------------------------
  // BENCH-066: transaction-attached X-injection descriptor
  //-------------------------------------------------------
  //Enum: x_inject_target_e
  //The manager-side signal an X-injection request targets. X_INJ_NONE (the
  //default of every axi4_master_tx) means "no injection" and leaves every
  //existing item bit-identical in behaviour. AWVALID/AWADDR/WDATA/BREADY are
  //write-side targets (dispatched by the proxy's write loop), ARVALID/RREADY
  //read-side (read loop); a descriptor naming a signal of the other channel
  //is a sequence error and is reported once as X_INJ_RESULT_INVALID.
  //The numeric values are also the index into the per-signal pin-level
  //witness arrays of assertions/master_assertions.sv (1..6).
  typedef enum int {
    X_INJ_NONE    = 0,
    X_INJ_AWVALID = 1,
    X_INJ_AWADDR  = 2,
    X_INJ_WDATA   = 3,
    X_INJ_ARVALID = 4,
    X_INJ_BREADY  = 5,
    X_INJ_RREADY  = 6
  } x_inject_target_e;
  localparam int X_INJ_NUM_TARGETS = 7;

  //Enum: x_inject_result_e
  //Outcome the driver writes back onto the requesting item (or idle request).
  //  NOT_REQUESTED    - descriptor was X_INJ_NONE, nothing was attempted
  //  OK               - the BFM drove X for exactly the requested aclk cycles
  //  TIMEOUT          - the channel's pin-level mutex could not be taken within
  //                     X_INJECT_ACQUIRE_TIMEOUT cycles (another owner never
  //                     released it); nothing was driven
  //  ABORTED_BY_RESET - ARESETn fell while waiting for the channel or while
  //                     driving; the signal was restored to idle immediately
  //  INVALID          - request rejected at accept time (cycle count out of
  //                     [1:X_INJECT_CYCLES_MAX], target on the wrong channel);
  //                     nothing was driven, reported with uvm_error
  typedef enum int {
    X_INJ_RESULT_NOT_REQUESTED    = 0,
    X_INJ_RESULT_OK               = 1,
    X_INJ_RESULT_TIMEOUT          = 2,
    X_INJ_RESULT_ABORTED_BY_RESET = 3,
    X_INJ_RESULT_INVALID          = 4
  } x_inject_result_e;

  //Enum: x_inject_assert_policy_e
  //Explicit assertion policy carried by the request (BENCH-066 repair-contract
  //item 6). SUPPRESS is today's behaviour: the master_assertions gate
  //x_inject_mode is raised for exactly the cycles the BFM owns the wire, so
  //NO_HANDSHAKE_DURING_X / NO_READY_HANDSHAKE_DURING_X / AWVALID_X_RECOVERY
  //are disabled during the drive. KEEP_ARMED leaves the gate low so an
  //assertion-detection self-test can observe its target assertion fire.
  typedef enum bit {
    X_INJ_SUPPRESS_CHECKS = 1'b0,
    X_INJ_KEEP_ARMED      = 1'b1
  } x_inject_assert_policy_e;

  //Variable: X_INJECT_CYCLES_MAX
  //Upper bound on a single X-injection hold, in aclk cycles. Well under the
  //driver BFM's 50000-cycle claim escapes so an injection can never be
  //mistaken for an abandoned transaction.
  parameter int X_INJECT_CYCLES_MAX = 1000;

  //Struct: x_inject_req_s
  //One completed item-attached X-injection request as the driver BFM logs it
  //for the monitor (axi4_master_driver_bfm::x_inject_req_log, popped by
  //axi4_master_monitor_proxy at the AW/AR handshake with the same id).
  //Built with a NAMED aggregate literal at its only push site
  //(axi4_master_driver_proxy::dispatch_x_inject) - keep it that way.
  typedef struct {
    bit                      is_write;
    bit [`AXI_ID_WIDTH-1:0]  id;
    x_inject_target_e        target;
    int                      cycles;
    x_inject_assert_policy_e policy;
    bit                      accepted;
    bit                      started;
    bit                      completed;
    x_inject_result_e        result;
    time                     start_time;
    time                     end_time;
    int                      cycles_driven;
  } x_inject_req_s;

  //Variable: X_INJECT_ACQUIRE_TIMEOUT
  //Cycles the driver BFM will wait for the target channel's pin-level mutex
  //(aw/w/ar_channel_key) before giving up with X_INJ_RESULT_TIMEOUT.
  parameter int X_INJECT_ACQUIRE_TIMEOUT = 10000;

  //-------------------------------------------------------
  // Structs used in axi_avip are given below
  //-------------------------------------------------------
  
  //Struct: axi4_w_transfer_char_s
  //This struct datatype consists of all write signals which are used for seq item conversion
  typedef struct {
    //Write Address Channel Signals
    bit [`AXI_ID_WIDTH-1:0] awid;
    bit [ADDRESS_WIDTH-1:0] awaddr;
    bit [7:0]               awlen;
    bit [2:0]               awsize;
    bit [1:0]               awburst;
    bit                     awlock;
    bit [3:0]               awcache;
    bit [3:0]               awqos;
    bit [3:0]               awregion;
    // USER fields follow the configured widths (axi4_bus_config.svh), the same
    // way axi4_if, the *_tx classes and the driver/monitor BFM ports already
    // do. They used to be hard-coded 1 bit (awuser/buser), 4 bits (aruser) and
    // 1 bit-per-beat (wuser), so this struct -- the ONLY hop between the class
    // layer and the pin layer -- silently truncated every USER signal:
    //   * class -> struct -> driver: AWUSER was cut to its LSB before it ever
    //     reached the pins, so a USER passthrough/tagging test drove a value
    //     the DUT never saw.
    //   * pins -> monitor -> struct -> class: the monitor's per-beat
    //     `req.wuser[i] = wuser` wrote a whole WUSER bus into a single bit.
    // Widening the field is the fix, NOT widening the consumers: every
    // consumer (BFM ports, converters, tx classes) was already correct.
    bit [`AXI_AWUSER_WIDTH-1:0] awuser;
    bit [2:0]               awprot;
    bit                     awvalid;
    bit	                    awready;
    //Write Data Channel Signals
    bit     [2**LENGTH:0][DATA_WIDTH-1:0] wdata;
    bit [2**LENGTH:0][(DATA_WIDTH/8)-1:0] wstrb;
    // One full WUSER per beat, indexed exactly like wdata/wstrb.
    bit [2**LENGTH:0][`AXI_WUSER_WIDTH-1:0] wuser;
    bit                                   wlast;
    //Write Response Channel Signals
    bit [`AXI_ID_WIDTH-1:0] bid;
    bit [1:0] bresp;
    bit [`AXI_BUSER_WIDTH-1:0] buser;
    bit       bvalid;
    bit       tx_type; 
    int       wait_count_write_address_channel;
    int       wait_count_write_data_channel;
    int       wait_count_write_response_channel;
    int       outstanding_write_tx;
    int       aw_wait_states;
    int       w_wait_states;
    int       b_wait_states;
  } axi4_write_transfer_char_s;

  //Struct: axi4_r_transfer_char_s
  //This struct datatype consists of all read signals which are used for seq item conversion
  typedef struct {
    //Read Address Channel Signals
    bit [`AXI_ID_WIDTH-1:0] arid;
    bit [ADDRESS_WIDTH-1:0] araddr;
    bit               [7:0] arlen;
    bit               [2:0] arsize;
    bit               [1:0] arburst;
    bit               [3:0] arcache;
    bit               [2:0] arprot;
    bit               [3:0] arqos;
    bit               [3:0] arregion;
    // See the USER note on axi4_write_transfer_char_s above.
    bit [`AXI_ARUSER_WIDTH-1:0] aruser;
    bit                     arlock;
    //Read Data Channel Signals
    bit [`AXI_ID_WIDTH-1:0] rid;
    bit [2**LENGTH:0][DATA_WIDTH-1:0] rdata;
    bit            [2**LENGTH:0][1:0] rresp;
    // One full RUSER per beat, indexed exactly like rdata/rresp.
    bit [2**LENGTH:0][`AXI_RUSER_WIDTH-1:0] ruser;
    bit                               rlast;
    bit                               rvalid;
    bit                               tx_type; 
    int                               wait_count_read_address_channel;
    int                               wait_count_read_data_channel;
    int                               outstanding_read_tx;
    int                               ar_wait_states;
    int                               r_wait_states;
    // BENCH-065 mid-burst RREADY stall. REQUEST side (class -> struct -> driver):
    // r_stall_beat is the interior beat index (1..arlen) in front of which the
    // manager holds RREADY low for r_stall_cycles clocks; -1 = no request. Beat
    // 0 stays r_wait_states' domain. OBSERVED side (monitor -> struct -> class):
    // the first interior beat at which the monitor measured RVALID high with
    // RREADY low, and for how many cycles; -1 / 0 when none. A plain struct
    // default is 0 for both -- the monitor BFM sets the observed sentinel
    // explicitly and the class field carries its own -1 initializer.
    int                               r_stall_beat;
    int                               r_stall_cycles;
    int                               r_stall_beat_observed;
    int                               r_stall_cycles_observed;
  } axi4_read_transfer_char_s;

  //Struct: axi4_cfg_char_s
  //This struct datatype consists of all configurations which are used for seq item conversion
  typedef struct {
    bit [ADDRESS_WIDTH-1:0] min_address;
    bit [ADDRESS_WIDTH-1:0] max_address;
    int                     wait_count_write_address_channel;
    int                     wait_count_write_data_channel;
    int                     wait_count_write_response_channel;
    int                     wait_count_read_address_channel;
    int                     wait_count_read_data_channel;
    int                     outstanding_write_tx;
    int                     outstanding_read_tx;
    response_mode_e         slave_response_mode;
    qos_mode_e              qos_mode_type;
  } axi4_transfer_cfg_s;

endpackage : axi4_globals_pkg

`endif

