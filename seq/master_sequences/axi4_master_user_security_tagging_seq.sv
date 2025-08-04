`ifndef AXI4_MASTER_USER_SECURITY_TAGGING_SEQ_INCLUDED_
`define AXI4_MASTER_USER_SECURITY_TAGGING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_security_tagging_seq
// Tests USER signals for security tagging functionality
// Implements security levels, access permissions, and trust zones using USER signals
//--------------------------------------------------------------------------------------------
class axi4_master_user_security_tagging_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_security_tagging_seq)
  
  // Configuration parameters
  int master_id = 0;
  int slave_id = 2;
  int num_transactions = 20;
  
  // Security levels
  typedef enum bit [2:0] {
    SECURE_LEVEL_0    = 3'b000, // Highest security (system level)
    SECURE_LEVEL_1    = 3'b001, // High security (kernel level)
    SECURE_LEVEL_2    = 3'b010, // Medium security (driver level)
    SECURE_LEVEL_3    = 3'b011, // Low security (application level)
    NON_SECURE_LEVEL  = 3'b100, // Non-secure
    PRIVILEGED_LEVEL  = 3'b101, // Privileged access
    USER_LEVEL        = 3'b110, // User level access
    GUEST_LEVEL       = 3'b111  // Guest level access
  } security_level_e;
  
  // Trust zones
  typedef enum bit [1:0] {
    TRUST_ZONE_SECURE     = 2'b00,
    TRUST_ZONE_NON_SECURE = 2'b01,
    TRUST_ZONE_MONITOR    = 2'b10,
    TRUST_ZONE_HYPERVISOR = 2'b11
  } trust_zone_e;
  
  // Access permissions
  typedef enum bit [2:0] {
    ACCESS_READ_ONLY    = 3'b001,
    ACCESS_WRITE_ONLY   = 3'b010,
    ACCESS_READ_WRITE   = 3'b011,
    ACCESS_EXECUTE      = 3'b100,
    ACCESS_READ_EXEC    = 3'b101,
    ACCESS_WRITE_EXEC   = 3'b110,
    ACCESS_FULL         = 3'b111
  } access_permission_e;
  
  // Security test scenarios
  typedef struct {
    string test_name;
    security_level_e sec_level;
    trust_zone_e trust_zone;
    access_permission_e access_perm;
    bit [7:0] user_id;
    string description;
  } security_test_t;
  
  security_test_t security_tests[] = '{
    '{"secure_sys_rw", SECURE_LEVEL_0, TRUST_ZONE_SECURE, ACCESS_READ_WRITE, 8'h01, "System level secure read-write"},
    '{"secure_kern_ro", SECURE_LEVEL_1, TRUST_ZONE_SECURE, ACCESS_READ_ONLY, 8'h02, "Kernel level secure read-only"},
    '{"secure_drv_exec", SECURE_LEVEL_2, TRUST_ZONE_SECURE, ACCESS_READ_EXEC, 8'h03, "Driver level secure read-exec"},
    '{"secure_app_full", SECURE_LEVEL_3, TRUST_ZONE_SECURE, ACCESS_FULL, 8'h04, "App level secure full access"},
    '{"non_secure_rw", NON_SECURE_LEVEL, TRUST_ZONE_NON_SECURE, ACCESS_READ_WRITE, 8'h05, "Non-secure read-write"},
    '{"priv_monitor", PRIVILEGED_LEVEL, TRUST_ZONE_MONITOR, ACCESS_FULL, 8'h06, "Privileged monitor access"},
    '{"user_basic", USER_LEVEL, TRUST_ZONE_NON_SECURE, ACCESS_READ_WRITE, 8'h07, "User level basic access"},
    '{"guest_limited", GUEST_LEVEL, TRUST_ZONE_NON_SECURE, ACCESS_READ_ONLY, 8'h08, "Guest level limited access"},
    '{"hypervisor_ctrl", SECURE_LEVEL_0, TRUST_ZONE_HYPERVISOR, ACCESS_FULL, 8'h09, "Hypervisor control access"},
    '{"secure_multi_zone", SECURE_LEVEL_1, TRUST_ZONE_SECURE, ACCESS_WRITE_EXEC, 8'h0A, "Multi-zone secure access"}
  };
  
  // Transaction parameters
  rand bit [ADDRESS_WIDTH-1:0] base_addr;
  
  constraint base_addr_c {
    base_addr == (slave_id == 2) ? 64'h0000_0008_8000_0000 : 64'h0000_0008_0000_0000;
  }
  
  extern function new(string name = "axi4_master_user_security_tagging_seq");
  extern virtual task body();
  extern virtual task generate_security_transaction(int test_idx, bit is_write);
  extern virtual function bit [31:0] encode_security_user_bits(security_test_t test_info);
  extern virtual function bit [7:0] calculate_security_hash(security_test_t test_info);
  
endclass : axi4_master_user_security_tagging_seq

//-----------------------------------------------------------------------------
// Constructor: new
//-----------------------------------------------------------------------------
function axi4_master_user_security_tagging_seq::new(string name = "axi4_master_user_security_tagging_seq");
  super.new(name);
endfunction : new

//-----------------------------------------------------------------------------
// Task: body
// Generates transactions with security tagging USER signals
//-----------------------------------------------------------------------------
task axi4_master_user_security_tagging_seq::body();
  
  super.body();
  
  // Get configuration from config_db
  if (!uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id)) begin
    `uvm_info(get_type_name(), "Using default master_id = 0", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id)) begin
    `uvm_info(get_type_name(), "Using default slave_id = 2", UVM_MEDIUM)
  end
  
  if (!uvm_config_db#(int)::get(null, get_full_name(), "num_transactions", num_transactions)) begin
    `uvm_info(get_type_name(), "Using default num_transactions = 20", UVM_MEDIUM)
  end
  
  `uvm_info(get_type_name(), $sformatf("Starting USER security tagging sequence: Master[%0d] → Slave[%0d]",
                                        master_id, slave_id), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Testing %0d security tagging scenarios", security_tests.size()), UVM_MEDIUM)
  
  // Test each security scenario with both write and read transactions
  for (int i = 0; i < security_tests.size() && i < num_transactions; i++) begin
    `uvm_info(get_type_name(), $sformatf("Testing security scenario %0d: %s - %s",
                                          i, security_tests[i].test_name, security_tests[i].description), UVM_HIGH)
    
    // Generate write transaction with security tagging
    generate_security_transaction(i, 1'b1);
    #150;
    
    // Generate read transaction with security tagging
    generate_security_transaction(i, 1'b0);
    #150;
  end
  
  `uvm_info(get_type_name(), $sformatf("USER security tagging sequence completed: %0d scenarios tested",
                                        security_tests.size()), UVM_MEDIUM)
  
endtask : body

//-----------------------------------------------------------------------------
// Task: generate_security_transaction
// Creates transactions with security tagging USER signals
//-----------------------------------------------------------------------------
task axi4_master_user_security_tagging_seq::generate_security_transaction(int test_idx, bit is_write);
  
  security_test_t current_test = security_tests[test_idx];
  bit [31:0] security_user_bits;
  int burst_len = $urandom_range(0, 2);
  
  security_user_bits = encode_security_user_bits(current_test);
  
  if (is_write) begin
    // Generate write transaction with security tagging
    `uvm_do_with(req, {
      req.tx_type == WRITE;
      req.awaddr == base_addr + (test_idx * 'h200);
      req.awid == awid_e'(master_id % 16);
      req.awlen == burst_len; // Short bursts for security testing
      req.awsize == WRITE_8_BYTES;
      req.awburst == WRITE_INCR;
      req.awqos == (current_test.sec_level == SECURE_LEVEL_0) ? 4'hF : 4'h8; // Higher QoS for secure
      req.awuser == security_user_bits;
      req.wuser == {24'h000000, current_test.user_id}; // User ID in WUSER
    })
    
    `uvm_info(get_type_name(), $sformatf("WRITE %s: SecLvl=%0d, TrustZone=%0d, Access=%0d, AWUSER=0x%08h",
                                          current_test.test_name, current_test.sec_level, current_test.trust_zone,
                                          current_test.access_perm, security_user_bits), UVM_HIGH)
  end
  else begin
    // Generate read transaction with security tagging
    `uvm_do_with(req, {
      req.tx_type == READ;
      req.araddr == base_addr + (test_idx * 'h200) + 'h2000; // Offset for reads
      req.arid == arid_e'(master_id % 16);
      req.arlen == burst_len; // Short bursts for security testing
      req.arsize == READ_8_BYTES;
      req.arburst == READ_INCR;
      req.arqos == (current_test.sec_level == SECURE_LEVEL_0) ? 4'hF : 4'h8; // Higher QoS for secure
      req.aruser == security_user_bits;
    })
    
    `uvm_info(get_type_name(), $sformatf("READ %s: SecLvl=%0d, TrustZone=%0d, Access=%0d, ARUSER=0x%08h",
                                          current_test.test_name, current_test.sec_level, current_test.trust_zone,
                                          current_test.access_perm, security_user_bits), UVM_HIGH)
  end
  
endtask : generate_security_transaction

//-----------------------------------------------------------------------------
// Function: encode_security_user_bits
// Encodes security information into USER signal bits
//-----------------------------------------------------------------------------
function bit [31:0] axi4_master_user_security_tagging_seq::encode_security_user_bits(security_test_t test_info);
  bit [31:0] user_bits = 32'h00000000;
  bit [7:0] sec_hash;
  
  // Encode security information in USER bits
  user_bits[2:0]   = test_info.sec_level;      // Bits [2:0]: Security level
  user_bits[4:3]   = test_info.trust_zone;     // Bits [4:3]: Trust zone
  user_bits[7:5]   = test_info.access_perm;    // Bits [7:5]: Access permissions
  user_bits[15:8]  = test_info.user_id;        // Bits [15:8]: User ID
  user_bits[19:16] = master_id[3:0];           // Bits [19:16]: Master ID
  
  // Calculate security hash for integrity
  sec_hash = calculate_security_hash(test_info);
  user_bits[27:20] = sec_hash;                 // Bits [27:20]: Security hash
  
  // Security tag valid bit and version
  user_bits[28] = 1'b1;                        // Bit [28]: Security tag valid
  user_bits[31:29] = 3'b001;                   // Bits [31:29]: Security tag version
  
  return user_bits;
endfunction : encode_security_user_bits

//-----------------------------------------------------------------------------
// Function: calculate_security_hash
// Calculates a simple hash for security tag integrity
//-----------------------------------------------------------------------------
function bit [7:0] axi4_master_user_security_tagging_seq::calculate_security_hash(security_test_t test_info);
  bit [7:0] hash = 8'h00;
  
  // Simple hash calculation based on security parameters
  hash ^= {5'b00000, test_info.sec_level};
  hash ^= {6'b000000, test_info.trust_zone};
  hash ^= {5'b00000, test_info.access_perm};
  hash ^= test_info.user_id;
  hash ^= master_id[7:0];
  
  // Add some non-linear mixing
  hash = {hash[6:0], hash[7]} ^ {hash[3:0], hash[7:4]};
  
  return hash;
endfunction : calculate_security_hash

`endif