package memory_map_pkg;
  import axi4_globals_pkg::*;

  typedef struct packed {
    bit [ADDRESS_WIDTH-1:0] min_addr;
    bit [ADDRESS_WIDTH-1:0] max_addr;
  } mem_range_t;

  localparam mem_range_t SLAVE_MEM_MAP[NO_OF_SLAVES] = '{
    '{64'h0000_1000, 64'h0000_1FFC},
    '{64'h0000_2000, 64'h0000_2FFC},
    '{64'h0000_3000, 64'h0000_3FFC},
    '{64'h0000_4000, 64'h0000_4FFC}
  };
endpackage

