`ifndef AXI4_BUS_MATRIX_REF_INCLUDED_
`define AXI4_BUS_MATRIX_REF_INCLUDED_

class axi4_bus_matrix_ref extends uvm_component;
  `uvm_component_utils(axi4_bus_matrix_ref)

  // Bus matrix mode enumeration
  typedef enum {
    BASE_BUS_MATRIX,        // Basic functionally simplified bus model
    BUS_ENHANCED_MATRIX,    // Complete 10x10 enhanced bus model
    NONE                    // No reference model
  } bus_matrix_mode_e;

  // Current bus matrix mode
  bus_matrix_mode_e bus_mode = BUS_ENHANCED_MATRIX;

  // simple memory for each slave indexed by address
  bit [DATA_WIDTH-1:0] slave_mem[NO_OF_SLAVES][bit [ADDRESS_WIDTH-1:0]];

  typedef struct {
    bit [ADDRESS_WIDTH-1:0] start_addr;
    bit [ADDRESS_WIDTH-1:0] end_addr;
    bit                      read_only;
    bit [NO_OF_MASTERS-1:0]  read_masters;
    bit [NO_OF_MASTERS-1:0]  write_masters;
    bit                      instruction_only;  // For XOM region
    bit                      write_only;       // For attribute monitor
  } slave_cfg_s;

  slave_cfg_s slave_cfg[NO_OF_SLAVES];
  
  // Number of configured slaves based on bus mode
  int num_configured_slaves;

  extern function new(string name = "axi4_bus_matrix_ref", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void configure_base_matrix();
  extern virtual function void configure_enhanced_matrix();
  extern virtual function void set_bus_mode(bus_matrix_mode_e mode);
  extern virtual function int decode(bit [ADDRESS_WIDTH-1:0] addr);
  extern virtual function bresp_e get_write_resp(int master, bit [ADDRESS_WIDTH-1:0] addr, bit [2:0] awprot);
  extern virtual function rresp_e get_read_resp(int master, bit [ADDRESS_WIDTH-1:0] addr, bit [2:0] arprot);
  extern virtual function void store_write(bit [ADDRESS_WIDTH-1:0] addr,
                                           bit [DATA_WIDTH-1:0] data);
  extern virtual function void load_read(bit [ADDRESS_WIDTH-1:0] addr,
                                         output bit [DATA_WIDTH-1:0] data);
  extern virtual function bit check_security_access(int master, int slave, bit is_secure_req);
  extern virtual function bit check_privilege_access(int master, int slave, bit is_privileged_req);
  extern virtual function bit check_instruction_access(int slave, bit is_instruction);
  extern virtual function bit [DATA_WIDTH-1:0] backdoor_read(bit [ADDRESS_WIDTH-1:0] addr, int slave_id);
endclass : axi4_bus_matrix_ref

function axi4_bus_matrix_ref::new(string name = "axi4_bus_matrix_ref", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void axi4_bus_matrix_ref::build_phase(uvm_phase phase);
  super.build_phase(phase);

  // Get bus mode from config_db if available
  if(!uvm_config_db#(bus_matrix_mode_e)::get(this, "", "bus_matrix_mode", bus_mode)) begin
    `uvm_info(get_type_name(), "Bus matrix mode not found in config_db, using default BUS_ENHANCED_MATRIX", UVM_MEDIUM)
  end

  // Configure slaves based on bus mode
  case(bus_mode)
    BASE_BUS_MATRIX: configure_base_matrix();
    BUS_ENHANCED_MATRIX: configure_enhanced_matrix();
    NONE: begin
      num_configured_slaves = 0;
      `uvm_info(get_type_name(), "Bus matrix mode set to NONE - no slaves configured", UVM_MEDIUM)
    end
  endcase
  
  `uvm_info(get_type_name(), $sformatf("Bus matrix configured in %s mode with %0d slaves", 
            bus_mode.name(), num_configured_slaves), UVM_MEDIUM)
endfunction : build_phase

function void axi4_bus_matrix_ref::configure_base_matrix();
  // Configure 4x4 base matrix per AXI_MATRIX.txt specification
  num_configured_slaves = 4;
  
  // S0: DDR_Memory - R/W access per AXI_MATRIX.txt
  // M0,M1,M2,M3 all have R/W access to DDR
  slave_cfg[0] = '{64'h0000_0100_0000_0000,     // 32 GiB DDR Memory
                    64'h0000_0107_FFFF_FFFF,
                    1'b0,                       // Not read-only
                    4'b1111,                    // All 4 masters can read
                    4'b1111,                    // All 4 masters can write
                    1'b0,                       // Not instruction-only
                    1'b0};                      // Not write-only
                    
  // S1: Boot_ROM - Read-only for all masters
  slave_cfg[1] = '{64'h0000_0000_0000_0000,     // 128 KiB Boot ROM
                    64'h0000_0000_0001_FFFF,
                    1'b1,                       // Read-only
                    4'b1111,                    // All 4 masters can read
                    4'b0000,                    // No masters can write
                    1'b0,                       // Not instruction-only
                    1'b0};                      // Not write-only
                    
  // S2: Peripheral_Regs - R/W for M0,M1,M2 per AXI_MATRIX.txt
  slave_cfg[2] = '{64'h0000_0010_0000_0000,     // 1 MiB Peripheral Registers
                    64'h0000_0010_000F_FFFF,
                    1'b0,                       // Not read-only
                    4'b0111,                    // M0,M1,M2 can read
                    4'b0111,                    // M0,M1,M2 can write
                    1'b0,                       // Not instruction-only
                    1'b0};                      // Not write-only
                    
  // S3: HW_Fuse_Box - Read-only for M0,M3 per AXI_MATRIX.txt
  slave_cfg[3] = '{64'h0000_0020_0000_0000,     // 4 KiB Hardware Fuse Box
                    64'h0000_0020_0000_0FFF,
                    1'b1,                       // Read-only
                    4'b1001,                    // M0,M3 can read (M0=CPU_Core_A, M3=GPU)
                    4'b0000,                    // No masters can write
                    1'b0,                       // Not instruction-only
                    1'b0};                      // Not write-only
                    
  `uvm_info(get_type_name(), "Configured 4x4 base bus matrix per AXI_MATRIX.txt", UVM_MEDIUM)
endfunction : configure_base_matrix

function void axi4_bus_matrix_ref::configure_enhanced_matrix();
  // Configure 10x10 enhanced matrix per claude.md address mapping
  num_configured_slaves = 10;
  
  // S0: DDR Secure Kernel - Secure access only (1GB)
  slave_cfg[0] = '{64'h0000_0008_0000_0000,
                    64'h0000_0008_3FFF_FFFF,
                    1'b0,                       // Not read-only (R/W)
                    10'b1111111111,             // All masters can read (security check applied)
                    10'b1111111111,             // All masters can write (security check applied)
                    1'b0,                       // Not instruction-only
                    1'b0};                      // Not write-only
                    
  // S1: DDR Non-Secure User - Non-secure access allowed (1GB)
  slave_cfg[1] = '{64'h0000_0008_4000_0000,
                    64'h0000_0008_7FFF_FFFF,
                    1'b0,                       // Not read-only (R/W)
                    10'b1111111111,             // All masters can read
                    10'b1111111111,             // All masters can write
                    1'b0,                       // Not instruction-only
                    1'b0};                      // Not write-only
                    
  // S2: DDR Shared Buffer - All masters can access (1GB)
  slave_cfg[2] = '{64'h0000_0008_8000_0000,
                    64'h0000_0008_BFFF_FFFF,
                    1'b0,                       // Not read-only (R/W)
                    10'b1111111111,             // All masters can read
                    10'b1111111111,             // All masters can write
                    1'b0,                       // Not instruction-only
                    1'b0};                      // Not write-only
                    
  // S3: Illegal Address Hole - No access allowed (1GB)
  slave_cfg[3] = '{64'h0000_0008_C000_0000,
                    64'h0000_0008_FFFF_FFFF,
                    1'b1,                       // Read-only (but actually no access)
                    10'b0000000000,             // No masters can read
                    10'b0000000000,             // No masters can write
                    1'b0,                       // Not instruction-only
                    1'b0};                      // Not write-only
                    
  // S4: XOM Instruction-Only - Instruction reads only (1GB)
  slave_cfg[4] = '{64'h0000_0009_0000_0000,
                    64'h0000_0009_3FFF_FFFF,
                    1'b1,                       // Read-only (instruction fetch only)
                    10'b1111111111,             // All masters can read (but instruction only)
                    10'b0000000000,             // No masters can write
                    1'b1,                       // instruction_only = true
                    1'b0};                      // Not write-only
                    
  // S5: RO Peripheral - Read-only for all (64KB)
  slave_cfg[5] = '{64'h0000_000A_0000_0000,
                    64'h0000_000A_0000_FFFF,
                    1'b1,                       // Read-only
                    10'b1111111111,             // All masters can read
                    10'b0000000000,             // No masters can write
                    1'b0,                       // Not instruction-only
                    1'b0};                      // Not write-only
                    
  // S6: Privileged-Only - Privileged access only (64KB)
  slave_cfg[6] = '{64'h0000_000A_0001_0000,
                    64'h0000_000A_0001_FFFF,
                    1'b0,                       // Not read-only (R/W)
                    10'b1111111111,             // All masters can read (privilege check applied)
                    10'b1111111111,             // All masters can write (privilege check applied)
                    1'b0,                       // Not instruction-only
                    1'b0};                      // Not write-only
                    
  // S7: Secure-Only - Secure access only (64KB)
  slave_cfg[7] = '{64'h0000_000A_0002_0000,
                    64'h0000_000A_0002_FFFF,
                    1'b0,                       // Not read-only (R/W)
                    10'b1111111111,             // All masters can read (security check applied)
                    10'b1111111111,             // All masters can write (security check applied)
                    1'b0,                       // Not instruction-only
                    1'b0};                      // Not write-only
                    
  // S8: Scratchpad - All masters can access (64KB)
  slave_cfg[8] = '{64'h0000_000A_0003_0000,
                    64'h0000_000A_0003_FFFF,
                    1'b0,                       // Not read-only (R/W)
                    10'b1111111111,             // All masters can read
                    10'b1111111111,             // All masters can write
                    1'b0,                       // Not instruction-only
                    1'b0};                      // Not write-only
                    
  // S9: Attribute Monitor - Write-only (64KB)
  slave_cfg[9] = '{64'h0000_000A_0004_0000,
                    64'h0000_000A_0004_FFFF,
                    1'b0,                       // Not read-only (write-only)
                    10'b0000000000,             // No masters can read
                    10'b1111111111,             // All masters can write
                    1'b0,                       // Not instruction-only
                    1'b1};                      // write_only = true
                    
  `uvm_info(get_type_name(), "Configured 10x10 enhanced bus matrix per claude.md", UVM_MEDIUM)
endfunction : configure_enhanced_matrix

function int axi4_bus_matrix_ref::decode(bit [ADDRESS_WIDTH-1:0] addr);
  // In NONE mode, always return slave 0 for any address
  if(bus_mode == NONE) begin
    `uvm_info("BUS_MATRIX_DECODE", $sformatf("NONE mode: Address 0x%16h maps to slave 0 (accepting all addresses)", addr), UVM_LOW);
    return 0;
  end
  
  // Check only configured slaves based on bus mode
  for(int i = 0; i < num_configured_slaves; i++) begin
    if(addr >= slave_cfg[i].start_addr && addr <= slave_cfg[i].end_addr) begin
      `uvm_info("BUS_MATRIX_DECODE", $sformatf("Address 0x%16h maps to slave %0d (range 0x%16h - 0x%16h)", 
               addr, i, slave_cfg[i].start_addr, slave_cfg[i].end_addr), UVM_LOW);
      return i;
    end
  end
  `uvm_info("BUS_MATRIX_DECODE", $sformatf("Address 0x%16h does not map to any slave - returning -1", addr), UVM_LOW);
  return -1;
endfunction : decode

function bresp_e axi4_bus_matrix_ref::get_write_resp(int master, bit [ADDRESS_WIDTH-1:0] addr, bit [2:0] awprot);
  int sid = decode(addr);
  bresp_e resp;
  
  // Check if bus mode is NONE
  if(bus_mode == NONE) return WRITE_OKAY;
  
  // Check address decode
  if(sid < 0 || sid == 3) begin // S3 is illegal address hole
    `uvm_info("BUS_MATRIX_WRITE_RESP", $sformatf("Master %0d write to unmapped/illegal address 0x%16h - DECERR", master, addr), UVM_LOW)
    return WRITE_DECERR;
  end
  
  // Check read-only regions
  if(slave_cfg[sid].read_only) begin
    `uvm_info("BUS_MATRIX_WRITE_RESP", $sformatf("Master %0d write to read-only slave %0d - SLVERR", master, sid), UVM_LOW)
    return WRITE_SLVERR;
  end
  
  // For enhanced matrix mode, check security and privilege
  if(bus_mode == BUS_ENHANCED_MATRIX) begin
    // Check security for S0 (Secure Kernel), S4 (XOM), and S7 (Secure-Only)
    if(sid == 0 || sid == 4 || sid == 7) begin
      if(!check_security_access(master, sid, ~awprot[1])) begin
        `uvm_info("BUS_MATRIX_WRITE_RESP", $sformatf("Master %0d security violation writing slave %0d - %s", 
                  master, sid, (sid == 0 || sid == 4) ? "DECERR" : "SLVERR"), UVM_LOW)
        return (sid == 0 || sid == 4) ? WRITE_DECERR : WRITE_SLVERR;
      end
    end
    
    // Check privilege for S6 (Privileged-Only)
    if(sid == 6) begin
      if(!check_privilege_access(master, sid, ~awprot[0])) begin
        `uvm_info("BUS_MATRIX_WRITE_RESP", $sformatf("Master %0d privilege violation writing slave %0d - SLVERR", master, sid), UVM_LOW)
        return WRITE_SLVERR;
      end
    end
  end
  
  // Basic access check
  if(!slave_cfg[sid].write_masters[master]) begin
    `uvm_info("BUS_MATRIX_WRITE_RESP", $sformatf("Master %0d not allowed to write slave %0d - SLVERR", master, sid), UVM_LOW)
    return WRITE_SLVERR;
  end
  
  return WRITE_OKAY;
endfunction : get_write_resp

function rresp_e axi4_bus_matrix_ref::get_read_resp(int master, bit [ADDRESS_WIDTH-1:0] addr, bit [2:0] arprot);
  int sid = decode(addr);
  
  // Check if bus mode is NONE
  if(bus_mode == NONE) return READ_OKAY;
  
  `uvm_info("BUS_MATRIX_READ_RESP", $sformatf("Master %0d reading address 0x%16h: decode returned %0d, arprot=%3b", 
            master, addr, sid, arprot), UVM_LOW);
  
  // Check address decode
  if(sid < 0 || sid == 3) begin // S3 is illegal address hole
    `uvm_info("BUS_MATRIX_READ_RESP", $sformatf("Address 0x%16h unmapped/illegal - returning READ_DECERR", addr), UVM_LOW);
    return READ_DECERR;
  end
  
  // Check write-only regions (S9: Attribute Monitor)
  if(slave_cfg[sid].write_only) begin
    `uvm_info("BUS_MATRIX_READ_RESP", $sformatf("Master %0d read from write-only slave %0d - SLVERR", master, sid), UVM_LOW)
    return READ_SLVERR;
  end
  
  // For enhanced matrix mode, check security, privilege, and instruction access FIRST
  if(bus_mode == BUS_ENHANCED_MATRIX) begin
    // Check instruction-only access for S4 (XOM)
    if(sid == 4) begin
      `uvm_info("BUS_MATRIX_READ_RESP", $sformatf("S4 check: master=%0d, arprot=%3b, is_instruction=%b", master, arprot, arprot[2]), UVM_LOW);
      if(!check_instruction_access(sid, arprot[2])) begin
        `uvm_info("BUS_MATRIX_READ_RESP", $sformatf("Master %0d non-instruction read from XOM slave %0d - SLVERR", master, sid), UVM_LOW)
        return READ_SLVERR;
      end
    end
    
    // Check security for S0 (Secure Kernel), S4 (XOM), and S7 (Secure-Only)
    if(sid == 0 || sid == 4 || sid == 7) begin
      if(!check_security_access(master, sid, ~arprot[1])) begin
        `uvm_info("BUS_MATRIX_READ_RESP", $sformatf("Master %0d security violation reading slave %0d - %s", 
                  master, sid, (sid == 0 || sid == 4) ? "DECERR" : "SLVERR"), UVM_LOW)
        return (sid == 0 || sid == 4) ? READ_DECERR : READ_SLVERR;
      end
    end
    
    // Check privilege for S6 (Privileged-Only)  
    if(sid == 6) begin
      if(!check_privilege_access(master, sid, ~arprot[0])) begin
        `uvm_info("BUS_MATRIX_READ_RESP", $sformatf("Master %0d privilege violation reading slave %0d - SLVERR", master, sid), UVM_LOW)
        return READ_SLVERR;
      end
    end
  end
  
  // Basic access check last (for base matrix compatibility)
  if(!slave_cfg[sid].read_masters[master]) begin
    `uvm_info("BUS_MATRIX_READ_RESP", $sformatf("Master %0d not allowed to read slave %0d - returning READ_SLVERR", master, sid), UVM_LOW);
    return READ_SLVERR;
  end
  
  `uvm_info("BUS_MATRIX_READ_RESP", $sformatf("Master %0d reading slave %0d - returning READ_OKAY", master, sid), UVM_LOW);
  return READ_OKAY;
endfunction : get_read_resp

function void axi4_bus_matrix_ref::store_write(bit [ADDRESS_WIDTH-1:0] addr,
                                               bit [DATA_WIDTH-1:0] data);
  int sid = decode(addr);
  bit [ADDRESS_WIDTH-1:0] aligned_addr;
  
  // For wide data bus, align address to DATA_WIDTH boundary
  // With DATA_WIDTH=1024 bits (128 bytes), align to 128-byte boundary
  aligned_addr = addr & ~((DATA_WIDTH/8) - 1);
  
  if(sid >= 0) begin
    slave_mem[sid][aligned_addr] = data;
    `uvm_info(get_type_name(), 
      $sformatf("store_write: sid=%0d, addr=0x%16h, aligned_addr=0x%16h, data[31:0]=0x%08h", 
      sid, addr, aligned_addr, data[31:0]), UVM_HIGH);
  end
endfunction : store_write

function void axi4_bus_matrix_ref::load_read(bit [ADDRESS_WIDTH-1:0] addr,
                                             output bit [DATA_WIDTH-1:0] data);
  int sid = decode(addr);
  bit [ADDRESS_WIDTH-1:0] aligned_addr;
  
  // For wide data bus, align address to DATA_WIDTH boundary
  // With DATA_WIDTH=1024 bits (128 bytes), align to 128-byte boundary
  aligned_addr = addr & ~((DATA_WIDTH/8) - 1);
  
  if(sid >= 0 && slave_mem[sid].exists(aligned_addr)) begin
    data = slave_mem[sid][aligned_addr];
    `uvm_info(get_type_name(), 
      $sformatf("load_read: sid=%0d, addr=0x%16h, aligned_addr=0x%16h, data[31:0]=0x%08h", 
      sid, addr, aligned_addr, data[31:0]), UVM_HIGH);
  end else begin
    data = '0;
    `uvm_info(get_type_name(), 
      $sformatf("load_read: sid=%0d, addr=0x%16h, aligned_addr=0x%16h not found, returning 0", 
      sid, addr, aligned_addr), UVM_HIGH);
  end
endfunction : load_read

function void axi4_bus_matrix_ref::set_bus_mode(bus_matrix_mode_e mode);
  bus_mode = mode;
  
  // Update num_configured_slaves based on mode
  case(mode)
    BASE_BUS_MATRIX: num_configured_slaves = 4;
    BUS_ENHANCED_MATRIX: num_configured_slaves = 10;
    NONE: num_configured_slaves = 0;
  endcase
  
  `uvm_info(get_type_name(), $sformatf("Bus matrix mode set to %s with %0d slaves", 
            mode.name(), num_configured_slaves), UVM_MEDIUM)
endfunction : set_bus_mode

function bit axi4_bus_matrix_ref::check_security_access(int master, int slave, bit is_secure_req);
  // Define master security attributes based on claude.md
  bit master_is_secure[10] = '{1, 0, 1, 0, 0, 1, 0, 0, 0, 0}; // M0,M2,M5 are secure
  
  // For S0 (Secure Kernel), S4 (XOM), and S7 (Secure-Only), only secure masters or secure requests allowed
  if(slave == 0 || slave == 4 || slave == 7) begin
    return (master_is_secure[master] || is_secure_req);
  end
  
  return 1; // Other slaves don't have security restrictions
endfunction : check_security_access

function bit axi4_bus_matrix_ref::check_privilege_access(int master, int slave, bit is_privileged_req);
  // Define master privilege attributes based on claude.md
  // M0,M2,M4,M5,M6,M9 are privileged; M1,M3,M7,M8 are unprivileged
  bit master_is_privileged[10] = '{1, 0, 1, 0, 1, 1, 1, 0, 0, 1};
  
  // For S6 (Privileged-Only), only privileged masters or privileged requests allowed
  if(slave == 6) begin
    return (master_is_privileged[master] || is_privileged_req);
  end
  
  return 1; // Other slaves don't have privilege restrictions
endfunction : check_privilege_access

function bit axi4_bus_matrix_ref::check_instruction_access(int slave, bit is_instruction);
  // For S4 (XOM Instruction-Only), only instruction accesses allowed
  if(slave == 4) begin
    return is_instruction;
  end
  
  return 1; // Other slaves don't have instruction restrictions
endfunction : check_instruction_access

function bit [DATA_WIDTH-1:0] axi4_bus_matrix_ref::backdoor_read(bit [ADDRESS_WIDTH-1:0] addr, int slave_id);
  bit [DATA_WIDTH-1:0] data;
  bit [ADDRESS_WIDTH-1:0] aligned_addr;
  
  // For wide data bus, align address to DATA_WIDTH boundary
  aligned_addr = addr & ~((DATA_WIDTH/8) - 1);
  
  // Perform backdoor read directly from slave memory without protocol checks
  // This is used for verification purposes to confirm writes to write-only regions
  if(slave_id >= 0 && slave_id < num_configured_slaves) begin
    if(slave_mem[slave_id].exists(aligned_addr)) begin
      data = slave_mem[slave_id][aligned_addr];
      `uvm_info(get_type_name(), 
        $sformatf("Backdoor read from S%0d: addr=0x%16h, aligned_addr=0x%16h, data[31:0]=0x%08h", 
        slave_id, addr, aligned_addr, data[31:0]), UVM_HIGH);
    end else begin
      data = '0;
      `uvm_info(get_type_name(), 
        $sformatf("Backdoor read from S%0d: addr=0x%16h, aligned_addr=0x%16h not found, returning 0", 
        slave_id, addr, aligned_addr), UVM_HIGH);
    end
  end else begin
    data = '0;
    `uvm_warning(get_type_name(), 
      $sformatf("Backdoor read: Invalid slave_id %0d, returning 0", slave_id));
  end
  
  return data;
endfunction : backdoor_read

`endif
