`ifndef AXI4_MASTER_USER_SECURITY_TAGGING_SEQ_INCLUDED_
`define AXI4_MASTER_USER_SECURITY_TAGGING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_security_tagging_seq
// Master sequence for USER signal security tagging
// Generates transactions with various security classifications and access controls
//--------------------------------------------------------------------------------------------
class axi4_master_user_security_tagging_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_security_tagging_seq)

  // Security level definitions
  typedef enum bit [3:0] {
    SEC_UNCLASSIFIED     = 4'h0,
    SEC_RESTRICTED       = 4'h1,
    SEC_CONFIDENTIAL     = 4'h2,
    SEC_SECRET           = 4'h4,
    SEC_TOP_SECRET       = 4'h8,
    SEC_COSMIC_TOP_SECRET = 4'hF
  } security_level_e;
  
  // Domain ID definitions
  typedef enum bit [3:0] {
    DOMAIN_PUBLIC        = 4'h0,
    DOMAIN_CORPORATE     = 4'h1,
    DOMAIN_ENGINEERING   = 4'h2,
    DOMAIN_FINANCE       = 4'h3,
    DOMAIN_HR            = 4'h4,
    DOMAIN_RESEARCH      = 4'h5,
    DOMAIN_PRODUCTION    = 4'h6,
    DOMAIN_SECURE        = 4'h7,
    DOMAIN_ISOLATED      = 4'hF
  } domain_id_e;
  
  // Access rights definitions
  typedef enum bit [3:0] {
    ACCESS_NONE          = 4'h0,
    ACCESS_READ_ONLY     = 4'h1,
    ACCESS_WRITE_ONLY    = 4'h2,
    ACCESS_READ_WRITE    = 4'h3,
    ACCESS_EXECUTE       = 4'h4,
    ACCESS_READ_EXECUTE  = 4'h5,
    ACCESS_FULL          = 4'h7,
    ACCESS_ADMIN         = 4'hF
  } access_rights_e;
  
  // Privilege level definitions
  typedef enum bit [3:0] {
    PRIV_USER            = 4'h0,
    PRIV_SUPERVISOR      = 4'h1,
    PRIV_HYPERVISOR      = 4'h2,
    PRIV_SECURE          = 4'h3,
    PRIV_ROOT            = 4'hF
  } privilege_level_e;
  
  // Security zone definitions
  typedef enum bit [3:0] {
    ZONE_DMZ             = 4'h0,
    ZONE_INTERNAL        = 4'h1,
    ZONE_CRITICAL        = 4'h2,
    ZONE_ISOLATED        = 4'h3,
    ZONE_AIR_GAP         = 4'hF
  } security_zone_e;
  
  // Encryption type definitions
  typedef enum bit [3:0] {
    ENCRYPT_NONE         = 4'h0,
    ENCRYPT_AES128       = 4'h1,
    ENCRYPT_AES256       = 4'h2,
    ENCRYPT_RSA2048      = 4'h3,
    ENCRYPT_RSA4096      = 4'h4,
    ENCRYPT_QUANTUM      = 4'hF
  } encryption_type_e;
  
  // Security tag configuration
  rand security_level_e    security_level;
  rand domain_id_e         domain_id;
  rand access_rights_e     access_rights;
  rand privilege_level_e   privilege_level;
  rand security_zone_e     security_zone;
  rand encryption_type_e   encryption_required;
  rand bit [3:0]           integrity_check;
  rand bit [3:0]           audit_level;
  
  // Configuration for bus matrix mode
  bit is_enhanced_mode = 0;
  int target_slave_id = 0;
  
  // Constraints
  constraint security_cfg_c {
    // Higher security levels require higher privileges
    (security_level >= SEC_SECRET) -> (privilege_level >= PRIV_SUPERVISOR);
    (security_level >= SEC_TOP_SECRET) -> (privilege_level >= PRIV_SECURE);
    
    // Critical zones require encryption
    (security_zone == ZONE_CRITICAL || security_zone == ZONE_ISOLATED) -> 
      (encryption_required != ENCRYPT_NONE);
    
    // Admin access requires highest privilege
    (access_rights == ACCESS_ADMIN) -> (privilege_level == PRIV_ROOT);
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_user_security_tagging_seq");
  extern task body();
  extern function bit [31:0] encode_security_tag();
  extern function string decode_security_tag(bit [31:0] tag);
  extern function bit verify_security_policy(bit [31:0] tag, bit is_write);

endclass : axi4_master_user_security_tagging_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the sequence
//
// Parameters:
//  name - axi4_master_user_security_tagging_seq
//--------------------------------------------------------------------------------------------
function axi4_master_user_security_tagging_seq::new(string name = "axi4_master_user_security_tagging_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and sends transactions with security tags
//--------------------------------------------------------------------------------------------
task axi4_master_user_security_tagging_seq::body();
  bit [31:0] security_tag;
  bit policy_valid;
  string tag_info;
  bit [63:0] base_addr;
  bit [63:0] addr_offset;
  
  req = axi4_master_tx::type_id::create("req");
  start_item(req);
  
  // Generate security tag
  security_tag = encode_security_tag();
  tag_info = decode_security_tag(security_tag);
  
  // Verify security policy
  policy_valid = verify_security_policy(security_tag, 1'b1);
  
  `uvm_info(get_type_name(), $sformatf("Security Tag: 0x%08h - %s", security_tag, tag_info), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("Policy Check: %s", policy_valid ? "AUTHORIZED" : "DENIED"), UVM_MEDIUM)
  
  // Use mode-aware address mapping
  if (!is_enhanced_mode) begin
    // 4x4 BASE mode addresses matching AXI_MATRIX.txt
    // S0: DDR_Memory at 0x0000_0100_0000_0000 (R/W)
    // S1: Boot_ROM at 0x0000_0000_0000_0000 (Read-Only)
    // S2: Peripheral_Regs at 0x0000_0010_0000_0000 (R/W)
    // S3: HW_Fuse_Box at 0x0000_0020_0000_0000 (Read-Only)
    // Only target writable slaves (0 and 2)
    if (target_slave_id == 1 || target_slave_id == 3) begin
      target_slave_id = (target_slave_id == 1) ? 0 : 2; // Redirect to writable slave
    end
    case(target_slave_id)
      0: base_addr = 64'h0000_0100_0000_0000; // DDR_Memory (R/W)
      2: base_addr = 64'h0000_0010_0000_0000; // Peripheral_Regs (R/W)
      default: base_addr = 64'h0000_0100_0000_0000; // Default to DDR
    endcase
  end else begin
    // 10x10 ENHANCED mode addresses
    // S3: Illegal Address Hole - NO ACCESS ALLOWED
    // S4: Instruction-only - READ-ONLY
    // S5: Read-only peripheral - READ-ONLY  
    // Redirect to writable slaves only (0, 1, 2, 6, 7, 8, 9)
    if (target_slave_id == 3 || target_slave_id == 4 || target_slave_id == 5) begin
      // Redirect to a writable slave
      case(target_slave_id)
        3: target_slave_id = 0; // S3 is illegal, use S0 instead
        4: target_slave_id = 1; // S4 is instruction-only, use S1 instead
        5: target_slave_id = 2; // S5 is read-only, use S2 instead
        default: target_slave_id = 0;
      endcase
    end
    
    case(target_slave_id)
      0: base_addr = 64'h0000_0008_0000_0000; // DDR Secure (R/W)
      1: base_addr = 64'h0000_0008_4000_0000; // DDR Non-Secure (R/W)
      2: base_addr = 64'h0000_0008_8000_0000; // DDR Shared (R/W)
      3: base_addr = 64'h0000_0008_c000_0000; // Illegal - should never reach here
      4: base_addr = 64'h0000_0009_0000_0000; // Instruction-only - should never reach here
      5: base_addr = 64'h0000_000a_0000_0000; // Read-only - should never reach here
      6: base_addr = 64'h0000_000a_0001_0000; // Privileged-Only (R/W)
      7: base_addr = 64'h0000_000a_0002_0000; // Secure-Only (R/W)
      8: base_addr = 64'h0000_000a_0003_0000; // Non-Secure (R/W)
      9: base_addr = 64'h0000_000a_0004_0000; // Exclusive Monitor (R/W)
      default: base_addr = 64'h0000_0008_0000_0000;
    endcase
  end
  
  addr_offset = $urandom() & 64'hFFF;
  
  if(!req.randomize() with {
    req.transfer_type == NON_BLOCKING_WRITE;
    req.awburst == WRITE_INCR;
    req.awsize == WRITE_4_BYTES;
    req.awlen == 8'h00;  // Single beat burst
    req.awuser == security_tag;
    req.wuser == security_tag;  // Same security tag for write data
    req.awaddr == local::base_addr + local::addr_offset;
    // Constrain AWID based on bus matrix mode
    if (!local::is_enhanced_mode) {
      // 4x4 mode: Slave 2 only allows masters 0, 1, 2
      if (local::target_slave_id == 2) {
        req.awid inside {AWID_0, AWID_1, AWID_2};
      } else {
        req.awid inside {AWID_0, AWID_1, AWID_2, AWID_3};
      }
    } else {
      // 10x10 mode: All masters allowed for writable slaves
      req.awid inside {AWID_0, AWID_1, AWID_2, AWID_3, AWID_4, AWID_5, AWID_6, AWID_7, AWID_8, AWID_9};
    }
  }) begin
    `uvm_fatal("axi4", "Randomization failed for security tagging sequence")
  end
  
  finish_item(req);
  
endtask : body

//--------------------------------------------------------------------------------------------
// Function: encode_security_tag
// Encodes security attributes into USER signal
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_security_tagging_seq::encode_security_tag();
  bit [31:0] tag;
  
  tag[3:0]   = security_level;
  tag[7:4]   = domain_id;
  tag[11:8]  = access_rights;
  tag[15:12] = privilege_level;
  tag[19:16] = security_zone;
  tag[23:20] = encryption_required;
  tag[27:24] = integrity_check;
  tag[31:28] = audit_level;
  
  return tag;
endfunction : encode_security_tag

//--------------------------------------------------------------------------------------------
// Function: decode_security_tag
// Decodes security tag to human-readable string
//--------------------------------------------------------------------------------------------
function string axi4_master_user_security_tagging_seq::decode_security_tag(bit [31:0] tag);
  string sec_str, dom_str, acc_str, priv_str, zone_str;
  
  // Decode security level
  case (tag[3:0])
    SEC_UNCLASSIFIED:     sec_str = "UNCLASSIFIED";
    SEC_RESTRICTED:       sec_str = "RESTRICTED";
    SEC_CONFIDENTIAL:     sec_str = "CONFIDENTIAL";
    SEC_SECRET:           sec_str = "SECRET";
    SEC_TOP_SECRET:       sec_str = "TOP_SECRET";
    SEC_COSMIC_TOP_SECRET: sec_str = "COSMIC_TOP_SECRET";
    default:              sec_str = $sformatf("LEVEL_%0h", tag[3:0]);
  endcase
  
  // Decode domain
  case (tag[7:4])
    DOMAIN_PUBLIC:        dom_str = "PUBLIC";
    DOMAIN_CORPORATE:     dom_str = "CORPORATE";
    DOMAIN_ENGINEERING:   dom_str = "ENGINEERING";
    DOMAIN_FINANCE:       dom_str = "FINANCE";
    DOMAIN_HR:            dom_str = "HR";
    DOMAIN_RESEARCH:      dom_str = "RESEARCH";
    DOMAIN_PRODUCTION:    dom_str = "PRODUCTION";
    DOMAIN_SECURE:        dom_str = "SECURE";
    DOMAIN_ISOLATED:      dom_str = "ISOLATED";
    default:              dom_str = $sformatf("DOMAIN_%0h", tag[7:4]);
  endcase
  
  // Decode access rights
  case (tag[11:8])
    ACCESS_NONE:          acc_str = "NONE";
    ACCESS_READ_ONLY:     acc_str = "RO";
    ACCESS_WRITE_ONLY:    acc_str = "WO";
    ACCESS_READ_WRITE:    acc_str = "RW";
    ACCESS_EXECUTE:       acc_str = "X";
    ACCESS_READ_EXECUTE:  acc_str = "RX";
    ACCESS_FULL:          acc_str = "RWX";
    ACCESS_ADMIN:         acc_str = "ADMIN";
    default:              acc_str = $sformatf("ACC_%0h", tag[11:8]);
  endcase
  
  // Decode privilege level
  case (tag[15:12])
    PRIV_USER:            priv_str = "USER";
    PRIV_SUPERVISOR:      priv_str = "SUPER";
    PRIV_HYPERVISOR:      priv_str = "HYPER";
    PRIV_SECURE:          priv_str = "SECURE";
    PRIV_ROOT:            priv_str = "ROOT";
    default:              priv_str = $sformatf("PRIV_%0h", tag[15:12]);
  endcase
  
  // Decode security zone
  case (tag[19:16])
    ZONE_DMZ:             zone_str = "DMZ";
    ZONE_INTERNAL:        zone_str = "INTERNAL";
    ZONE_CRITICAL:        zone_str = "CRITICAL";
    ZONE_ISOLATED:        zone_str = "ISOLATED";
    ZONE_AIR_GAP:         zone_str = "AIR_GAP";
    default:              zone_str = $sformatf("ZONE_%0h", tag[19:16]);
  endcase
  
  return $sformatf("Sec:%s,Dom:%s,Acc:%s,Priv:%s,Zone:%s", 
                   sec_str, dom_str, acc_str, priv_str, zone_str);
endfunction : decode_security_tag

//--------------------------------------------------------------------------------------------
// Function: verify_security_policy
// Verifies if the security policy allows the transaction
//--------------------------------------------------------------------------------------------
function bit axi4_master_user_security_tagging_seq::verify_security_policy(bit [31:0] tag, bit is_write);
  security_level_e   sec_lvl;
  domain_id_e        dom;
  access_rights_e    acc;
  privilege_level_e  priv;
  security_zone_e    zone;
  
  // Extract fields
  sec_lvl = security_level_e'(tag[3:0]);
  dom = domain_id_e'(tag[7:4]);
  acc = access_rights_e'(tag[11:8]);
  priv = privilege_level_e'(tag[15:12]);
  zone = security_zone_e'(tag[19:16]);
  
  // Policy checks
  
  // Check 1: Write access requires write permissions
  if (is_write && (acc == ACCESS_READ_ONLY || acc == ACCESS_NONE || acc == ACCESS_EXECUTE)) begin
    `uvm_info(get_type_name(), "POLICY VIOLATION: Write attempted without write permission", UVM_LOW)
    return 0;
  end
  
  // Check 2: High security requires appropriate privilege
  if (sec_lvl >= SEC_SECRET && priv < PRIV_SUPERVISOR) begin
    `uvm_info(get_type_name(), "POLICY VIOLATION: Insufficient privilege for security level", UVM_LOW)
    return 0;
  end
  
  // Check 3: Isolated zone requires highest security
  if (zone == ZONE_ISOLATED && sec_lvl < SEC_SECRET) begin
    `uvm_info(get_type_name(), "POLICY VIOLATION: Isolated zone requires higher security level", UVM_LOW)
    return 0;
  end
  
  // Check 4: Cross-domain access restrictions
  if (dom == DOMAIN_ISOLATED && priv < PRIV_SECURE) begin
    `uvm_info(get_type_name(), "POLICY VIOLATION: Isolated domain requires secure privilege", UVM_LOW)
    return 0;
  end
  
  return 1; // Policy check passed
endfunction : verify_security_policy

`endif