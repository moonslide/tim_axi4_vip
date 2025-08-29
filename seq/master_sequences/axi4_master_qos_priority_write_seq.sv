`ifndef AXI4_MASTER_QOS_PRIORITY_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_PRIORITY_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_priority_write_seq
// Generates write transactions with configurable QoS priority values
//--------------------------------------------------------------------------------------------
class axi4_master_qos_priority_write_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_qos_priority_write_seq)

  // Variable: qos_value
  // Configurable QoS value for priority testing
  bit [3:0] qos_value = 4'b0000;
  
  // Variable: master_id
  // Master ID for this sequence (used to set AWID)
  int master_id = 0;
  
  // Variable: target_slave_id
  // -1 means randomly select a valid slave based on bus matrix mode
  int target_slave_id = -1;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_qos_priority_write_seq");
  extern task body();

endclass : axi4_master_qos_priority_write_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi4_master_qos_priority_write_seq
//--------------------------------------------------------------------------------------------
function axi4_master_qos_priority_write_seq::new(string name = "axi4_master_qos_priority_write_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates write transaction with specific QoS value for priority testing
//--------------------------------------------------------------------------------------------
task axi4_master_qos_priority_write_seq::body();
  bit [63:0] target_addr;
  bit [2:0] prot_value;
  axi4_master_agent_config cfg_h;
  axi4_bus_matrix_ref::bus_matrix_mode_e bus_mode;
  int num_slaves;
  
  super.body();
  
  // Get the agent configuration to access address ranges
  if(!uvm_config_db#(axi4_master_agent_config)::get(m_sequencer, "", "axi4_master_agent_config", cfg_h)) begin
    cfg_h = null;
  end
  
  // Get bus matrix mode from config_db
  if(!uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::get(m_sequencer, "", "bus_matrix_mode", bus_mode)) begin
    bus_mode = axi4_bus_matrix_ref::NONE; // Default to NONE (no bus matrix ref model)
  end
  
  // Get actual number of slaves from configuration
  if(!uvm_config_db#(int)::get(m_sequencer, "", "num_slaves", num_slaves)) begin
    // Fallback to defaults based on bus matrix mode if not set
    case(bus_mode)
      axi4_bus_matrix_ref::NONE: num_slaves = 1;  // 1x1 for NONE mode
      axi4_bus_matrix_ref::BASE_BUS_MATRIX: num_slaves = 4; // 4x4 bus matrix
      axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: num_slaves = 10; // 10x10 bus matrix
      default: num_slaves = 1;
    endcase
  end
  
  // If target_slave_id not specified by test, select a random valid slave
  // Otherwise use the specified target_slave_id
  if (target_slave_id == -1) begin
    // Select a random slave that exists in current configuration
    // Respect access control rules and avoid read-only slaves
    if (bus_mode == axi4_bus_matrix_ref::NONE && num_slaves == 1) begin
      // For 1x1 mode, only slave 0 exists
      target_slave_id = 0;
    end else if (bus_mode == axi4_bus_matrix_ref::NONE) begin
      // For NONE mode with multiple slaves, all masters can access all slaves except slave 1 (read-only)
      int valid_slaves[] = '{0, 2, 3};
      target_slave_id = valid_slaves[$urandom_range(0, 2)];
    end else if (bus_mode == axi4_bus_matrix_ref::BASE_BUS_MATRIX) begin
      // For BASE mode, respect access control:
      // Slave 0 (DDR): All masters can R/W
      // Slave 1 (Boot_ROM): Read-only, skip for writes
      // Slave 2 (Peripheral): Only M0,M1,M2 can access
      // Slave 3 (HW_Fuse): Read-only, skip for writes
      case(master_id)
        0, 1, 2: begin
          // Masters 0,1,2 can access slaves 0,2
          int valid_slaves[] = '{0, 2};
          target_slave_id = valid_slaves[$urandom_range(0, 1)];
        end
        3: begin
          // Master 3 can only access slave 0 (DDR)
          target_slave_id = 0;
        end
        default: target_slave_id = 0; // Default to DDR
      endcase
    end else begin
      // For ENHANCED mode, avoid read-only slaves and illegal address holes
      // S3: Illegal address hole - no access
      // S4: Instruction-only (read-only)
      // S5: Read-only peripheral
      // Valid slaves for write: 0,1,2,6,7,8,9
      int valid_slaves[] = '{0, 1, 2, 6, 7, 8, 9};
      target_slave_id = valid_slaves[$urandom_range(0, 6)];
    end
  end
  
  // Generate address based on bus matrix mode and slave ID
  case(bus_mode)
    axi4_bus_matrix_ref::NONE: begin
      // For NONE mode, check if it's 1x1 or multi-slave configuration
      if (num_slaves == 1) begin
        // For 1x1 mode, slave 0 handles 0x0000_0000_0000_0000 to 0x0000_0000_FFFF_FFFF
        target_addr = 64'h0000_0000_0000_0000 + ($urandom_range(0, 32'h0000_FFF0) & ~64'hF); // Valid range for slave 0
      end else begin
        // For NONE mode with multiple slaves, use simple low addresses
        case(target_slave_id)
          0: target_addr = 64'h0000_0000_0000_0000 + ($urandom_range(0, 32'h0000_FFF0) & ~64'hF); // Low memory region (64KB, 16-byte aligned)
          1: target_addr = 64'h0000_0001_0000_0000 + ($urandom_range(0, 32'h0000_FFF0) & ~64'hF); // Next region (64KB, 16-byte aligned)
          2: target_addr = 64'h0000_0002_0000_0000 + ($urandom_range(0, 32'h0000_FFF0) & ~64'hF); // Next region (64KB, 16-byte aligned)  
          3: target_addr = 64'h0000_0003_0000_0000 + ($urandom_range(0, 32'h0000_FFF0) & ~64'hF); // Next region (64KB, 16-byte aligned)
          default: target_addr = 64'h0000_0000_0000_1000; // Default safe address
        endcase
      end
    end
    
    axi4_bus_matrix_ref::BASE_BUS_MATRIX: begin
      // For BASE_BUS_MATRIX (4x4), use address ranges from AXI_MATRIX.txt
      // These ranges match axi4_base_test::setup_base_master_agent_cfg()
      case(target_slave_id)
        0: target_addr = 64'h0000_0100_0000_0000 + ($urandom_range(0, 32'h0000_FFF0) & ~64'hF); // DDR_Memory (limit to 64KB for testing, 16-byte aligned)
        1: target_addr = 64'h0000_0000_0000_0000 + ($urandom_range(0, 32'h0001_FFF0) & ~64'hF); // Boot_ROM (128KB range, 16-byte aligned)
        2: target_addr = 64'h0000_0010_0000_0000 + ($urandom_range(0, 32'h0000_FFF0) & ~64'hF); // Peripheral_Regs (limit to 64KB for testing, 16-byte aligned)
        3: target_addr = 64'h0000_0020_0000_0000 + ($urandom_range(0, 32'h0000_0FF0) & ~64'hF); // HW_Fuse_Box (4KB range, 16-byte aligned)
        default: target_addr = 64'h0000_0100_0000_0000; // Default to DDR base
      endcase
    end
    
    axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: begin
      // For BUS_ENHANCED_MATRIX (10x10), use specific address ranges for each slave
      // These ranges match axi4_base_test::setup_enhanced_master_agent_cfg()
      case(target_slave_id)
        0: target_addr = 64'h0000_0008_0000_0000 + ($urandom_range(0, 32'h3FFF_FFF0) & ~64'hF); // S0: DDR Secure Kernel (1GB, 16-byte aligned)
        1: target_addr = 64'h0000_0008_4000_0000 + ($urandom_range(0, 32'h3FFF_FFF0) & ~64'hF); // S1: DDR Non-Secure User (1GB, 16-byte aligned)
        2: target_addr = 64'h0000_0008_8000_0000 + ($urandom_range(0, 32'h3FFF_FFF0) & ~64'hF); // S2: DDR Shared Buffer (1GB, 16-byte aligned)
        // S3: Illegal Address Hole - excluded from write sequences
        // S4: XOM Instruction-Only - excluded from write sequences
        // S5: RO Peripheral - read-only, excluded from write sequences
        6: target_addr = 64'h0000_000A_0001_0000 + ($urandom_range(0, 32'h0000_FFF0) & ~64'hF); // S6: Privileged-Only (64KB, 16-byte aligned)
        7: target_addr = 64'h0000_000A_0002_0000 + ($urandom_range(0, 32'h0000_FFF0) & ~64'hF); // S7: Secure-Only (64KB, 16-byte aligned)
        8: target_addr = 64'h0000_000A_0003_0000 + ($urandom_range(0, 32'h0000_FFF0) & ~64'hF); // S8: Scratchpad (64KB, 16-byte aligned)
        9: target_addr = 64'h0000_000A_0004_0000 + ($urandom_range(0, 32'h0000_FFF0) & ~64'hF); // S9: Attribute Monitor (64KB, 16-byte aligned)
        default: target_addr = 64'h0000_0008_0000_0000; // Default to S0 DDR base
      endcase
    end
    
    default: target_addr = 64'h0000_0100_0000_0000; // Default safe address
  endcase
  
  start_item(req);
  
  // Set AxPROT based on target slave requirements
  // Note: This implementation's AxPROT[0] interpretation: 0=Privileged, 1=Normal (opposite of AXI spec)
  // AxPROT[2]: 0=Data, 1=Instruction
  // AxPROT[1]: 0=Secure, 1=Non-secure  
  // AxPROT[0]: 0=Privileged, 1=Normal (bus matrix specific)
  if (bus_mode == axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX) begin
    case(target_slave_id)
      0, 7: prot_value = 3'b000;  // S0 (Secure Kernel) and S7 (Secure-Only) require secure access (privileged)
      6: prot_value = 3'b000;     // S6 (Privileged-Only) requires privileged access (awprot[0]=0)
      default: prot_value = 3'b010; // Others can use non-secure, normal access
    endcase
  end else begin
    prot_value = 3'b010; // Non-secure, normal, data access for other modes
  end
  
  if(!req.randomize() with {
    req.tx_type == WRITE;
    req.transfer_type == NON_BLOCKING_WRITE;
    req.awqos == local::qos_value;
    req.awburst == WRITE_INCR;
    req.awsize == WRITE_4_BYTES;
    req.awlen == 8'h00;  // Single beat burst to simplify
    req.awaddr == local::target_addr;
    req.awprot == local::prot_value;
  }) begin
    `uvm_fatal("axi4", "Randomization failed for QoS priority write sequence")
  end
  
  // Set AWID after randomization to identify the master
  req.awid = $sformatf("AWID_%0d", master_id);
  
  `uvm_info(get_type_name(), $sformatf("QoS Priority Write - Mode: %s, Slave: %0d, QoS: %0h, Address: 0x%016h", 
            bus_mode.name(), target_slave_id, req.awqos, req.awaddr), UVM_MEDIUM)
  
  finish_item(req);
  
endtask : body

`endif