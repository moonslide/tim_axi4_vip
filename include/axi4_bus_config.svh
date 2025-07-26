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

`endif // AXI4_BUS_CONFIG_SVH