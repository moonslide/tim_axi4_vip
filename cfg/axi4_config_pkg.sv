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
  // M0 : CPU_Core_A -> S0, S1
  // M1 : CPU_Core_B -> S0, S2
  master_access_config_s master_access_table[$] = '{
    '{"master0", '{"slave0", "slave1"}},
    '{"master1", '{"slave0", "slave2"}}
  };

  // ------------------------------------------------------------------
  // Slave address mapping
  // ------------------------------------------------------------------
  // S0 : DDR_Memory      0x0000_0000_0000_0000 - 0x0000_0000_0000_FFFF (64KiB)
  // S1 : Boot_ROM        0x0000_0000_0001_0000 - 0x0000_0000_0001_FFFF (64KiB)
  // S2 : Peripheral_Regs 0x0000_0000_0002_0000 - 0x0000_0000_0002_FFFF (64KiB)
  slave_addr_config_s slave_addr_table[$] = '{
    '{"slave0", 64'h0000_0000_0000_0000, 64'h0000_0000_0001_0000},
    '{"slave1", 64'h0000_0000_0001_0000, 64'h0000_0000_0001_0000},
    '{"slave2", 64'h0000_0000_0002_0000, 64'h0000_0000_0001_0000}
  };
endpackage

