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

// Helper function to get enum from ID value
function automatic axi4_master_tx::awid_e get_awid_enum(int id_val);
  case(id_val % 16)
    0:  return axi4_master_tx::AWID_0;
    1:  return axi4_master_tx::AWID_1;
    2:  return axi4_master_tx::AWID_2;
    3:  return axi4_master_tx::AWID_3;
    4:  return axi4_master_tx::AWID_4;
    5:  return axi4_master_tx::AWID_5;
    6:  return axi4_master_tx::AWID_6;
    7:  return axi4_master_tx::AWID_7;
    8:  return axi4_master_tx::AWID_8;
    9:  return axi4_master_tx::AWID_9;
    10: return axi4_master_tx::AWID_10;
    11: return axi4_master_tx::AWID_11;
    12: return axi4_master_tx::AWID_12;
    13: return axi4_master_tx::AWID_13;
    14: return axi4_master_tx::AWID_14;
    15: return axi4_master_tx::AWID_15;
    default: return axi4_master_tx::AWID_0;
  endcase
endfunction

function automatic axi4_master_tx::arid_e get_arid_enum(int id_val);
  case(id_val % 16)
    0:  return axi4_master_tx::ARID_0;
    1:  return axi4_master_tx::ARID_1;
    2:  return axi4_master_tx::ARID_2;
    3:  return axi4_master_tx::ARID_3;
    4:  return axi4_master_tx::ARID_4;
    5:  return axi4_master_tx::ARID_5;
    6:  return axi4_master_tx::ARID_6;
    7:  return axi4_master_tx::ARID_7;
    8:  return axi4_master_tx::ARID_8;
    9:  return axi4_master_tx::ARID_9;
    10: return axi4_master_tx::ARID_10;
    11: return axi4_master_tx::ARID_11;
    12: return axi4_master_tx::ARID_12;
    13: return axi4_master_tx::ARID_13;
    14: return axi4_master_tx::ARID_14;
    15: return axi4_master_tx::ARID_15;
    default: return axi4_master_tx::ARID_0;
  endcase
endfunction

`endif // AXI4_BUS_CONFIG_SVH