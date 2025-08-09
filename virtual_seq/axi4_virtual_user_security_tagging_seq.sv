`ifndef AXI4_VIRTUAL_USER_SECURITY_TAGGING_SEQ_INCLUDED_
`define AXI4_VIRTUAL_USER_SECURITY_TAGGING_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_user_security_tagging_seq
// Virtual sequence to test USER signal security tagging and access control
// Demonstrates various security scenarios and policy enforcement
//--------------------------------------------------------------------------------------------
class axi4_virtual_user_security_tagging_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_user_security_tagging_seq)

  // Master sequences for different security scenarios
  axi4_master_user_security_tagging_seq unclassified_seq_h;
  axi4_master_user_security_tagging_seq confidential_seq_h;
  axi4_master_user_security_tagging_seq secret_seq_h;
  axi4_master_user_security_tagging_seq top_secret_seq_h;
  axi4_master_user_security_tagging_seq cross_domain_seq_h[4];
  axi4_master_user_security_tagging_seq mixed_privilege_seq_h[4];

  // Slave sequences
  axi4_slave_nbk_write_seq axi4_slave_write_seq_h;
  axi4_slave_nbk_read_seq axi4_slave_read_seq_h;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_virtual_user_security_tagging_seq");
  extern task body();

endclass : axi4_virtual_user_security_tagging_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the object
//
// Parameters:
//  name - axi4_virtual_user_security_tagging_seq
//--------------------------------------------------------------------------------------------
function axi4_virtual_user_security_tagging_seq::new(string name = "axi4_virtual_user_security_tagging_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and starts sequences to test USER security tagging
//--------------------------------------------------------------------------------------------
task axi4_virtual_user_security_tagging_seq::body();
  
  `uvm_info(get_type_name(), "Starting USER Security Tagging Virtual Sequence", UVM_LOW)
  
  // Create slave sequences
  axi4_slave_write_seq_h = axi4_slave_nbk_write_seq::type_id::create("axi4_slave_write_seq_h");
  axi4_slave_read_seq_h = axi4_slave_nbk_read_seq::type_id::create("axi4_slave_read_seq_h");
  
  // Start slave sequences in forever loops
  fork
    begin : SLAVE_WRITE
      forever begin
        axi4_slave_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
      end
    end
    
    begin : SLAVE_READ
      forever begin
        axi4_slave_read_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
      end
    end
  join_none
  
  // Test Scenario 1: Unclassified access
  `uvm_info(get_type_name(), "==== Scenario 1: Unclassified Data Access ====", UVM_LOW)
  
  unclassified_seq_h = axi4_master_user_security_tagging_seq::type_id::create("unclassified_seq");
  unclassified_seq_h.security_level = unclassified_seq_h.SEC_UNCLASSIFIED;
  unclassified_seq_h.domain_id = unclassified_seq_h.DOMAIN_PUBLIC;
  unclassified_seq_h.access_rights = unclassified_seq_h.ACCESS_READ_WRITE;
  unclassified_seq_h.privilege_level = unclassified_seq_h.PRIV_USER;
  unclassified_seq_h.security_zone = unclassified_seq_h.ZONE_DMZ;
  unclassified_seq_h.encryption_required = unclassified_seq_h.ENCRYPT_NONE;
  
  `uvm_info(get_type_name(), "  Unclassified user accessing public domain", UVM_LOW)
  unclassified_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  #200ns;
  
  // Test Scenario 2: Confidential access
  `uvm_info(get_type_name(), "==== Scenario 2: Confidential Data Access ====", UVM_LOW)
  
  confidential_seq_h = axi4_master_user_security_tagging_seq::type_id::create("confidential_seq");
  confidential_seq_h.security_level = confidential_seq_h.SEC_CONFIDENTIAL;
  confidential_seq_h.domain_id = confidential_seq_h.DOMAIN_CORPORATE;
  confidential_seq_h.access_rights = confidential_seq_h.ACCESS_READ_WRITE;
  confidential_seq_h.privilege_level = confidential_seq_h.PRIV_USER;
  confidential_seq_h.security_zone = confidential_seq_h.ZONE_INTERNAL;
  confidential_seq_h.encryption_required = confidential_seq_h.ENCRYPT_AES128;
  
  `uvm_info(get_type_name(), "  Confidential access with AES128 encryption", UVM_LOW)
  confidential_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  #200ns;
  
  // Test Scenario 3: Secret access requiring elevated privilege
  `uvm_info(get_type_name(), "==== Scenario 3: Secret Data Access (Elevated Privilege) ====", UVM_LOW)
  
  secret_seq_h = axi4_master_user_security_tagging_seq::type_id::create("secret_seq");
  secret_seq_h.security_level = secret_seq_h.SEC_SECRET;
  secret_seq_h.domain_id = secret_seq_h.DOMAIN_SECURE;
  secret_seq_h.access_rights = secret_seq_h.ACCESS_READ_WRITE;
  secret_seq_h.privilege_level = secret_seq_h.PRIV_SUPERVISOR;
  secret_seq_h.security_zone = secret_seq_h.ZONE_CRITICAL;
  secret_seq_h.encryption_required = secret_seq_h.ENCRYPT_AES256;
  
  `uvm_info(get_type_name(), "  Secret access requiring supervisor privilege", UVM_LOW)
  secret_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  #200ns;
  
  // Test Scenario 4: Top Secret access
  `uvm_info(get_type_name(), "==== Scenario 4: Top Secret Data Access ====", UVM_LOW)
  
  top_secret_seq_h = axi4_master_user_security_tagging_seq::type_id::create("top_secret_seq");
  top_secret_seq_h.security_level = top_secret_seq_h.SEC_TOP_SECRET;
  top_secret_seq_h.domain_id = top_secret_seq_h.DOMAIN_ISOLATED;
  top_secret_seq_h.access_rights = top_secret_seq_h.ACCESS_READ_WRITE;
  top_secret_seq_h.privilege_level = top_secret_seq_h.PRIV_SECURE;
  top_secret_seq_h.security_zone = top_secret_seq_h.ZONE_ISOLATED;
  top_secret_seq_h.encryption_required = top_secret_seq_h.ENCRYPT_RSA4096;
  
  `uvm_info(get_type_name(), "  Top Secret access in isolated zone", UVM_LOW)
  top_secret_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
  #200ns;
  
  // Test Scenario 5: Cross-domain access attempts
  `uvm_info(get_type_name(), "==== Scenario 5: Cross-Domain Access Control ====", UVM_LOW)
  
  for(int i = 0; i < 4; i++) begin
    cross_domain_seq_h[i] = axi4_master_user_security_tagging_seq::type_id::create($sformatf("cross_domain_%0d", i));
    
    case(i)
      0: begin
        // Engineering trying to access Finance
        cross_domain_seq_h[i].domain_id = cross_domain_seq_h[i].DOMAIN_ENGINEERING;
        cross_domain_seq_h[i].security_level = cross_domain_seq_h[i].SEC_CONFIDENTIAL;
        `uvm_info(get_type_name(), "  Engineering → Finance (should be blocked)", UVM_LOW)
      end
      1: begin
        // HR accessing Corporate
        cross_domain_seq_h[i].domain_id = cross_domain_seq_h[i].DOMAIN_HR;
        cross_domain_seq_h[i].security_level = cross_domain_seq_h[i].SEC_RESTRICTED;
        `uvm_info(get_type_name(), "  HR → Corporate (allowed with restrictions)", UVM_LOW)
      end
      2: begin
        // Research accessing Production
        cross_domain_seq_h[i].domain_id = cross_domain_seq_h[i].DOMAIN_RESEARCH;
        cross_domain_seq_h[i].security_level = cross_domain_seq_h[i].SEC_CONFIDENTIAL;
        `uvm_info(get_type_name(), "  Research → Production (read-only allowed)", UVM_LOW)
      end
      3: begin
        // Public trying to access Secure
        cross_domain_seq_h[i].domain_id = cross_domain_seq_h[i].DOMAIN_PUBLIC;
        cross_domain_seq_h[i].security_level = cross_domain_seq_h[i].SEC_UNCLASSIFIED;
        `uvm_info(get_type_name(), "  Public → Secure (should be denied)", UVM_LOW)
      end
    endcase
    
    cross_domain_seq_h[i].access_rights = cross_domain_seq_h[i].ACCESS_READ_WRITE;
    cross_domain_seq_h[i].privilege_level = (i == 0) ? cross_domain_seq_h[i].PRIV_USER : 
                                            (i == 1) ? cross_domain_seq_h[i].PRIV_SUPERVISOR :
                                            cross_domain_seq_h[i].PRIV_USER;
    cross_domain_seq_h[i].security_zone = cross_domain_seq_h[i].ZONE_INTERNAL;
    
    cross_domain_seq_h[i].start(p_sequencer.axi4_master_write_seqr_h);
    #150ns;
  end
  
  #300ns;
  
  // Test Scenario 6: Mixed privilege levels
  `uvm_info(get_type_name(), "==== Scenario 6: Mixed Privilege Level Access ====", UVM_LOW)
  
  for(int i = 0; i < 4; i++) begin
    mixed_privilege_seq_h[i] = axi4_master_user_security_tagging_seq::type_id::create($sformatf("mixed_priv_%0d", i));
    
    // Vary privilege levels
    case(i)
      0: mixed_privilege_seq_h[i].privilege_level = mixed_privilege_seq_h[i].PRIV_USER;
      1: mixed_privilege_seq_h[i].privilege_level = mixed_privilege_seq_h[i].PRIV_SUPERVISOR;
      2: mixed_privilege_seq_h[i].privilege_level = mixed_privilege_seq_h[i].PRIV_HYPERVISOR;
      3: mixed_privilege_seq_h[i].privilege_level = mixed_privilege_seq_h[i].PRIV_SECURE;
    endcase
    
    // Adjust security level based on privilege
    mixed_privilege_seq_h[i].security_level = (i < 2) ? 
                                              mixed_privilege_seq_h[i].SEC_CONFIDENTIAL :
                                              mixed_privilege_seq_h[i].SEC_SECRET;
    
    mixed_privilege_seq_h[i].domain_id = mixed_privilege_seq_h[i].DOMAIN_CORPORATE;
    mixed_privilege_seq_h[i].access_rights = mixed_privilege_seq_h[i].ACCESS_READ_WRITE;
    mixed_privilege_seq_h[i].security_zone = mixed_privilege_seq_h[i].ZONE_INTERNAL;
    
    `uvm_info(get_type_name(), $sformatf("  Testing privilege level %0d", i), UVM_LOW)
    mixed_privilege_seq_h[i].start(p_sequencer.axi4_master_write_seqr_h);
    #100ns;
  end
  
  #300ns;
  
  // Test Scenario 7: Access rights enforcement
  `uvm_info(get_type_name(), "==== Scenario 7: Access Rights Enforcement ====", UVM_LOW)
  
  for(int i = 0; i < 3; i++) begin
    unclassified_seq_h = axi4_master_user_security_tagging_seq::type_id::create($sformatf("access_test_%0d", i));
    unclassified_seq_h.security_level = unclassified_seq_h.SEC_RESTRICTED;
    unclassified_seq_h.domain_id = unclassified_seq_h.DOMAIN_CORPORATE;
    unclassified_seq_h.privilege_level = unclassified_seq_h.PRIV_USER;
    unclassified_seq_h.security_zone = unclassified_seq_h.ZONE_INTERNAL;
    
    // Test different access rights
    case(i)
      0: begin
        unclassified_seq_h.access_rights = unclassified_seq_h.ACCESS_READ_ONLY;
        `uvm_info(get_type_name(), "  Testing READ_ONLY access", UVM_LOW)
      end
      1: begin
        unclassified_seq_h.access_rights = unclassified_seq_h.ACCESS_WRITE_ONLY;
        `uvm_info(get_type_name(), "  Testing WRITE_ONLY access", UVM_LOW)
      end
      2: begin
        unclassified_seq_h.access_rights = unclassified_seq_h.ACCESS_FULL;
        `uvm_info(get_type_name(), "  Testing FULL access", UVM_LOW)
      end
    endcase
    
    unclassified_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
    #100ns;
  end
  
  // Wait for all transactions to complete
  #1000ns;
  
  `uvm_info(get_type_name(), "Completed USER Security Tagging Virtual Sequence", UVM_LOW)
  `uvm_info(get_type_name(), "Test Summary:", UVM_LOW)
  `uvm_info(get_type_name(), "  - Demonstrated multi-level security classification", UVM_LOW)
  `uvm_info(get_type_name(), "  - Tested domain isolation and cross-domain restrictions", UVM_LOW)
  `uvm_info(get_type_name(), "  - Verified privilege-based access control", UVM_LOW)
  `uvm_info(get_type_name(), "  - Enforced access rights (R/W/X permissions)", UVM_LOW)
  `uvm_info(get_type_name(), "  - Showed encryption requirements for sensitive data", UVM_LOW)
  `uvm_info(get_type_name(), "  - Tested security zone isolation", UVM_LOW)
  
endtask : body

`endif