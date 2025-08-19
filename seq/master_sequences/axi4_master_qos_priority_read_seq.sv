`ifndef AXI4_MASTER_QOS_PRIORITY_READ_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_PRIORITY_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_priority_read_seq
// Generates read transactions with configurable QoS priority values
//--------------------------------------------------------------------------------------------
class axi4_master_qos_priority_read_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_qos_priority_read_seq)

  // Variable: qos_value
  // Configurable QoS value for priority testing
  bit [3:0] qos_value = 4'b0000;
  
  // Variable: master_id
  // Master ID for this sequence (used to set ARID)
  int master_id = 0;
  
  // Variable: target_slave_id
  // -1 means randomly select a valid slave based on bus matrix mode
  int target_slave_id = -1;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_qos_priority_read_seq");
  extern task body();

endclass : axi4_master_qos_priority_read_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes new memory for the object
//
// Parameters:
//  name - axi4_master_qos_priority_read_seq
//--------------------------------------------------------------------------------------------
function axi4_master_qos_priority_read_seq::new(string name = "axi4_master_qos_priority_read_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates read transaction with specific QoS value for priority testing
//--------------------------------------------------------------------------------------------
task axi4_master_qos_priority_read_seq::body();
  bit [63:0] target_addr;
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
  
  // Determine number of slaves based on bus matrix mode
  case(bus_mode)
    axi4_bus_matrix_ref::NONE: num_slaves = 4;  // No bus matrix ref model - use default 4 slaves
    axi4_bus_matrix_ref::BASE_BUS_MATRIX: num_slaves = 4; // 4x4 bus matrix
    axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: num_slaves = 10; // 10x10 bus matrix
    default: num_slaves = 4;
  endcase
  
  // If target_slave_id not specified by test, select a random valid slave
  // Otherwise use the specified target_slave_id
  if (target_slave_id == -1) begin
    // Select a random slave that exists in current configuration
    // Respect access control rules for reads
    if (bus_mode == axi4_bus_matrix_ref::NONE) begin
      // For NONE mode, all masters can read all slaves
      target_slave_id = $urandom_range(0, num_slaves-1);
      end else if (bus_mode == axi4_bus_matrix_ref::BASE_BUS_MATRIX) begin
      // For BASE mode, respect read access control:
      // Slave 0 (DDR): All masters can read
      // Slave 1 (Boot_ROM): All masters can read
      // Slave 2 (Peripheral): Only M0,M1,M2 can read
      // Slave 3 (HW_Fuse): Only M0,M3 can read
      case(master_id)
        0: begin
          // Master 0 can read all slaves
          target_slave_id = $urandom_range(0, 3);
        end
        1, 2: begin
          // Masters 1,2 can read slaves 0,1,2
          int valid_slaves[] = '{0, 1, 2};
          target_slave_id = valid_slaves[$urandom_range(0, 2)];
        end
        3: begin
          // Master 3 can read slaves 0,1,3
          int valid_slaves[] = '{0, 1, 3};
          target_slave_id = valid_slaves[$urandom_range(0, 2)];
        end
        default: target_slave_id = 0; // Default to DDR
      endcase
    end else begin
      // For ENHANCED mode, all masters can read most slaves but avoid illegal address hole, XOM, and write-only
      // S3: Illegal address hole - no access allowed
      // S4: XOM Instruction-Only - skip for data reads (ARPROT[2]=0)
      // S9: Attribute Monitor - write-only, no read access allowed
      // Valid slaves for data read: 0,1,2,5,6,7,8 (exclude S3, S4, and S9)
      int valid_slaves[] = '{0, 1, 2, 5, 6, 7, 8};
      target_slave_id = valid_slaves[$urandom_range(0, 6)];
    end
  end
  
  // Generate address based on bus matrix mode and slave ID
  case(bus_mode)
    axi4_bus_matrix_ref::NONE: begin
      // For NONE mode (no bus matrix ref model), use simple low addresses
      // These addresses work without bus matrix decoding
      case(target_slave_id)
        0: target_addr = 64'h0000_0000_0000_0000 + {$urandom_range(0, 'hFFFF), 4'h0}; // Low memory region
        1: target_addr = 64'h0000_0000_0001_0000 + {$urandom_range(0, 'hFFFF), 4'h0}; // Next region
        2: target_addr = 64'h0000_0000_0002_0000 + {$urandom_range(0, 'hFFFF), 4'h0}; // Next region
        3: target_addr = 64'h0000_0000_0003_0000 + {$urandom_range(0, 'hFFFF), 4'h0}; // Next region
        default: target_addr = 64'h0000_0000_0000_1000; // Default safe address
      endcase
    end
    
    axi4_bus_matrix_ref::BASE_BUS_MATRIX: begin
      // For BASE_BUS_MATRIX (4x4), use address ranges from AXI_MATRIX.txt
      // These ranges match axi4_base_test::setup_base_master_agent_cfg()
      case(target_slave_id)
        0: target_addr = 64'h0000_0100_0000_0000 + {$urandom_range(0, 'hFFFF), 4'h0}; // DDR_Memory (32GB range, align to 16 bytes)
        1: target_addr = 64'h0000_0000_0000_0000 + {$urandom_range(0, 'h1FFF), 4'h0}; // Boot_ROM (128KB range, align to 16 bytes)
        2: target_addr = 64'h0000_0010_0000_0000 + {$urandom_range(0, 'hFFFF), 4'h0}; // Peripheral_Regs (1MB range, align to 16 bytes)
        3: target_addr = 64'h0000_0020_0000_0000 + {$urandom_range(0, 'h0FF), 4'h0};  // HW_Fuse_Box (4KB range, align to 16 bytes)
        default: target_addr = 64'h0000_0100_0000_0000; // Default to DDR base
      endcase
    end
    
    axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: begin
      // For BUS_ENHANCED_MATRIX (10x10), use specific address ranges for each slave
      // These ranges match axi4_base_test::setup_enhanced_master_agent_cfg()
      case(target_slave_id)
        0: target_addr = 64'h0000_0008_0000_0000 + {$urandom_range(0, 'hFFFF), 4'h0}; // S0: DDR Cache-Coherent
        1: target_addr = 64'h0000_0008_4000_0000 + {$urandom_range(0, 'hFFFF), 4'h0}; // S1: DDR Non-Coherent
        2: target_addr = 64'h0000_0008_8000_0000 + {$urandom_range(0, 'hFFFF), 4'h0}; // S2: DDR Shared Buffer
        // S3: Illegal Address Hole - excluded from read sequences
        // S4: XOM Instruction-Only - excluded from read sequences  
        5: target_addr = 64'h0000_000A_0000_0000 + {$urandom_range(0, 'h0FFF), 4'h0}; // S5: RO Peripheral (64KB)
        6: target_addr = 64'h0000_000A_0001_0000 + {$urandom_range(0, 'h0FFF), 4'h0}; // S6: Privileged-Only (64KB)
        7: target_addr = 64'h0000_000A_0002_0000 + {$urandom_range(0, 'h0FFF), 4'h0}; // S7: Secure-Only (64KB)
        8: target_addr = 64'h0000_000A_0003_0000 + {$urandom_range(0, 'h0FFF), 4'h0}; // S8: Scratchpad (64KB)
        // S9: Attribute Monitor is write-only - excluded from read sequences
        default: target_addr = 64'h0000_0008_0000_0000; // Default to S0 DDR base
      endcase
    end
    
    default: target_addr = 64'h0000_0100_0000_0000; // Default safe address
  endcase
  
  start_item(req);
  
  if(!req.randomize() with {
    req.tx_type == READ;
    req.transfer_type == NON_BLOCKING_READ;
    req.arqos == local::qos_value;
    req.arburst == READ_INCR;
    req.arsize == READ_4_BYTES;
    req.arlen == 8'h00;  // Single beat burst to simplify
    req.araddr == local::target_addr;
    req.arprot == 3'b010;  // Set to secure, non-privileged, data access
  }) begin
    `uvm_fatal("axi4", "Randomization failed for QoS priority read sequence")
  end
  
  // Set ARID after randomization to identify the master
  req.arid = $sformatf("ARID_%0d", master_id);
  
  `uvm_info(get_type_name(), $sformatf("QoS Priority Read - Mode: %s, Slave: %0d, QoS: %0h, Address: 0x%016h", 
            bus_mode.name(), target_slave_id, req.arqos, req.araddr), UVM_MEDIUM)
  
  finish_item(req);
  
endtask : body

`endif