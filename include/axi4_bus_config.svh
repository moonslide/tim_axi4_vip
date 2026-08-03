`ifndef AXI4_BUS_CONFIG_SVH
`define AXI4_BUS_CONFIG_SVH

//--------------------------------------------------------------------------------------------
// Scalable Bus Matrix Configuration Parameters
// Supports configurations from 4x4 up to 64x64 and beyond
//--------------------------------------------------------------------------------------------

// Bus matrix size detection based on compile/runtime parameters
`ifdef BUS_MATRIX_64X64
  `define NUM_MASTERS 64
  `define NUM_SLAVES  64
  `define ID_MAP_BITS 16  // Use all 16 IDs
`elsif BUS_MATRIX_10X10
  `define NUM_MASTERS 10
  `define NUM_SLAVES  10
  `define ID_MAP_BITS 10  // Use 10 out of 16 IDs
`else
  // Default 4x4 configuration
  `define NUM_MASTERS 4
  `define NUM_SLAVES  4
  `define ID_MAP_BITS 4   // Use only 4 IDs for compatibility
`endif

// ID mapping strategy for large bus matrices
`define GET_EFFECTIVE_AWID(master_id) ((master_id) % `ID_MAP_BITS)
`define GET_EFFECTIVE_ARID(master_id) ((master_id) % `ID_MAP_BITS)

// Helper macros to get enum from ID value
// These will be expanded as needed in each sequence file
`define GET_AWID_ENUM(id_val) \
  ((id_val % 16) == 0  ? AWID_0  : \
   (id_val % 16) == 1  ? AWID_1  : \
   (id_val % 16) == 2  ? AWID_2  : \
   (id_val % 16) == 3  ? AWID_3  : \
   (id_val % 16) == 4  ? AWID_4  : \
   (id_val % 16) == 5  ? AWID_5  : \
   (id_val % 16) == 6  ? AWID_6  : \
   (id_val % 16) == 7  ? AWID_7  : \
   (id_val % 16) == 8  ? AWID_8  : \
   (id_val % 16) == 9  ? AWID_9  : \
   (id_val % 16) == 10 ? AWID_10 : \
   (id_val % 16) == 11 ? AWID_11 : \
   (id_val % 16) == 12 ? AWID_12 : \
   (id_val % 16) == 13 ? AWID_13 : \
   (id_val % 16) == 14 ? AWID_14 : \
   (id_val % 16) == 15 ? AWID_15 : AWID_0)

`define GET_ARID_ENUM(id_val) \
  ((id_val % 16) == 0  ? ARID_0  : \
   (id_val % 16) == 1  ? ARID_1  : \
   (id_val % 16) == 2  ? ARID_2  : \
   (id_val % 16) == 3  ? ARID_3  : \
   (id_val % 16) == 4  ? ARID_4  : \
   (id_val % 16) == 5  ? ARID_5  : \
   (id_val % 16) == 6  ? ARID_6  : \
   (id_val % 16) == 7  ? ARID_7  : \
   (id_val % 16) == 8  ? ARID_8  : \
   (id_val % 16) == 9  ? ARID_9  : \
   (id_val % 16) == 10 ? ARID_10 : \
   (id_val % 16) == 11 ? ARID_11 : \
   (id_val % 16) == 12 ? ARID_12 : \
   (id_val % 16) == 13 ? ARID_13 : \
   (id_val % 16) == 14 ? ARID_14 : \
   (id_val % 16) == 15 ? ARID_15 : ARID_0)

//--------------------------------------------------------------------------------------------
// QoS and USER Signal Configuration Parameters
//--------------------------------------------------------------------------------------------

// QoS Width Configuration (Standard AXI4 = 4 bits)
`ifndef AXI_QOS_WIDTH
  `define AXI_QOS_WIDTH 4
`endif

// Transaction ID Width Configuration (AWID/ARID/BID/RID)
// Default 4 bits preserves the historical axi4_if declaration.
// Track-B builds against the NIC-400 fabric override this to 8, because the
// fabric's egress AxID is VIDWidth(4) + ceil(log2(10 ingress ports)) = 8 bits
// and the VIP slave agents must be able to echo the full ID back for the
// interconnect to route responses home.
`ifndef AXI_ID_WIDTH
  `define AXI_ID_WIDTH 4
`endif

// Highest legal transaction-ID value, as a LITERAL. It must always equal
// (2**AXI_ID_WIDTH)-1; hdl_top checks that at time 0 and $fatal()s if a build
// sets one without the other. It exists separately because VCS rejects a
// computed expression in an enum name range (Error-[ETRNC]), and the AxID
// enums in axi4_globals_pkg.sv have to span the full ID space -- the seq-item
// converters assign those fields with $cast, which is runtime-checked against
// the member list, so an ID outside it fails the cast silently and leaves the
// previous ID in place.
//   AXI_ID_WIDTH=4 -> 15 (default)   AXI_ID_WIDTH=8 -> 255 (Track-B / NIC-400)
`ifndef AXI_ID_LAST
  `define AXI_ID_LAST 15
`endif

// Track-B master-identity tag carried in AxUSER.
//
// Behind the fabric the subordinate cannot infer which manager issued a
// transaction. The egress AxID is NOT a usable substitute: it was measured to be
// a per-sub-block REVERSED permutation of the ingress port index on the 10x10
// build ({0,1} {2..5} {6..9}, each reversed), so `AxID & port_mask` scored 960/960
// reads against the wrong row of the access matrix. Fitting that permutation
// would hard-code one fabric configuration.
//
// Instead the Track-B sequences make the identity EXPLICIT on the wire:
//   AxUSER = {AXI4_MID_TAG, 4'(master_index)}
// The tag lets the subordinate tell "this carries an identity" from "this is
// ordinary USER data", so sequences that do not opt in keep the old behaviour
// instead of silently being attributed to master 0. AWUSER/ARUSER are enabled in
// both generated fabrics and are forwarded end to end.
`ifndef AXI4_MID_TAG
  `define AXI4_MID_TAG 28'h5A5_A100
`endif
`ifndef AXI4_MID_TAG_MASK
  `define AXI4_MID_TAG_MASK 32'hFFFF_FFF0
`endif

// Per-ingress external AxID width the NIC-400 was generated with (VIDWidth in
// scripts/build_vip_fabric_*.rb). The fabric's EGRESS AxID is
// {original AxID, ingress-port index} -- the port index sits in the LOW bits and
// is AXI_ID_WIDTH-AXI_VID_WIDTH wide. Established from measured probe data, not
// from the datasheet: on the 4x4 build egress bid 0x15/0x1c/0x0a/0x13 came back
// to the managers as 0x5/0x7/0x2/0x4, which only the {vid,port} split explains.
`ifndef AXI_VID_WIDTH
  `define AXI_VID_WIDTH 4
`endif

// Track-B fabric selection.
//
// BUS_MATRIX_FABRIC_IP      -> ext/nic400_vip4x4q ... 4x4, QoS, VIP BASE map
//                           when FABRIC_IP_4X4 is also defined,
//                           ext/nic400_vipv3b  ... 10x10, QoS, VIP ENHANCED map
//                           otherwise.
// FABRIC_IP_PORTS           -> how many of the VIP's agents attach to the fabric.
// FABRIC_IP_EGRESS_ID_WIDTH -> the fabric's egress AxID width, which is
//                           GlobalIDWidth = VIDWidth(4) + ceil(log2(ports)).
`ifdef FABRIC_IP_4X4
  `ifndef FABRIC_IP_PORTS
    `define FABRIC_IP_PORTS 4
  `endif
  `ifndef FABRIC_IP_EGRESS_ID_WIDTH
    `define FABRIC_IP_EGRESS_ID_WIDTH 6
  `endif
`else
  `ifndef FABRIC_IP_PORTS
    `define FABRIC_IP_PORTS 10
  `endif
  `ifndef FABRIC_IP_EGRESS_ID_WIDTH
    `define FABRIC_IP_EGRESS_ID_WIDTH 8
  `endif
`endif

// USER Signal Width Configuration
`ifndef AXI_AWUSER_WIDTH
  `define AXI_AWUSER_WIDTH 32
`endif

`ifndef AXI_ARUSER_WIDTH
  `define AXI_ARUSER_WIDTH 32
`endif

`ifndef AXI_WUSER_WIDTH
  `define AXI_WUSER_WIDTH 32
`endif

`ifndef AXI_BUSER_WIDTH
  `define AXI_BUSER_WIDTH 16
`endif

`ifndef AXI_RUSER_WIDTH
  `define AXI_RUSER_WIDTH 16
`endif

// End-of-test drain, in ns. See axi4_env::run_phase for why this exists: a
// NON_BLOCKING sequence completes at the ADDRESS handshake, so without a drain
// the run phase ends with W/B/R still in flight and those tests verify only the
// address channels.
//
// Sizing: the BLOCKING variant of the same traffic completes at 14350 ps
// (measured, axi4_blocking_8b_write_read_test), so 5 us is ~350x the time the
// same transactions need. It is simulation time, so it costs wall clock only
// while events are pending. Override per-run with +END_OF_TEST_DRAIN_NS=<n>.
`ifndef AXI4_END_OF_TEST_DRAIN_NS
  `define AXI4_END_OF_TEST_DRAIN_NS 5000
`endif

`endif // AXI4_BUS_CONFIG_SVH