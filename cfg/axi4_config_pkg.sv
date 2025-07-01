package axi4_config_pkg;
  import axi4_globals_pkg::*;

  typedef struct {
    string master_name;
    string allowed_slaves[$];
  } master_access_config_s;

  typedef struct {
    string slave_name;
    logic [ADDRESS_WIDTH-1:0] base_addr;
    logic [ADDRESS_WIDTH-1:0] size;
  } slave_addr_config_s;

  // ------------------------------------------------------------------
  // Master to Slave access permission table
  // ------------------------------------------------------------------
  // M0 : CPU_Core_A    -> S0, S2, S3
  // M1 : CPU_Core_B    -> S0, S2
  // M2 : DMA_Controller-> S0, S2
  // M3 : GPU           -> S0, S3
  master_access_config_s master_access_table[$] = '{
    '{"master0", '{"slave0", "slave2", "slave3"}},
    '{"master1", '{"slave0", "slave2"}},
    '{"master2", '{"slave0", "slave2"}},
    '{"master3", '{"slave0", "slave3"}}
  };

  // ------------------------------------------------------------------
  // Slave address mapping
  // ------------------------------------------------------------------
  // S0 : DDR_Memory      0x0000_0100_0000_0000 - 0x0000_0107_FFFF_FFFF (32GiB)
  // S1 : Boot_ROM        0x0000_0000_0000_0000 - 0x0000_0000_0001_FFFF (128KiB)
  // S2 : Peripheral_Regs 0x0000_0010_0000_0000 - 0x0000_0010_000F_FFFF (1MiB)
  // S3 : System_Config   0x0000_0020_0000_0000 - 0x0000_0020_0000_0FFF (4KiB)
  slave_addr_config_s slave_addr_table[$] = '{
    '{"slave0", 64'h0000_0100_0000_0000, 64'h0000_0008_0000_0000},
    '{"slave1", 64'h0000_0000_0000_0000, 64'h0000_0000_0002_0000},
    '{"slave2", 64'h0000_0010_0000_0000, 64'h0000_0000_0010_0000},
    '{"slave3", 64'h0000_0020_0000_0000, 64'h0000_0000_0000_1000}
  };
endpackage

