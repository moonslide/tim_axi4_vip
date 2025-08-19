`ifndef AXI4_MASTER_QOS_USER_BOOST_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_QOS_USER_BOOST_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_qos_user_boost_write_seq
// Master sequence for QoS write transactions with USER-based priority boosting
// Supports all three bus matrix modes: NONE, BASE_BUS_MATRIX (4x4), BUS_ENHANCED_MATRIX (10x10)
//--------------------------------------------------------------------------------------------
class axi4_master_qos_user_boost_write_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_qos_user_boost_write_seq)

  // QoS base priority value (1-15)
  rand bit [3:0] base_qos_value;
  
  // USER signal boost value (0-15)
  rand bit [3:0] user_boost_value;
  
  // Enable USER boost flag
  rand bit user_boost_enable;
  
  // Master ID for this sequence
  int master_id = 0;

  // Constraints
  constraint valid_qos_c {
    base_qos_value inside {1, 2, 4, 8};  // Use common QoS values
  }
  
  constraint valid_boost_c {
    user_boost_value inside {0, 2, 4, 8};  // Boost values
    user_boost_enable inside {0, 1};
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_qos_user_boost_write_seq");
  extern task body();

endclass : axi4_master_qos_user_boost_write_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the sequence
//
// Parameters:
//  name - axi4_master_qos_user_boost_write_seq
//--------------------------------------------------------------------------------------------
function axi4_master_qos_user_boost_write_seq::new(string name = "axi4_master_qos_user_boost_write_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates and sends the write transaction with QoS and USER priority boost
//--------------------------------------------------------------------------------------------
task axi4_master_qos_user_boost_write_seq::body();
  bit [3:0] effective_qos;
  bit [31:0] user_signal;
  int target_slave_id;
  bit [63:0] target_addr;
  axi4_bus_matrix_ref::bus_matrix_mode_e bus_mode;
  int num_slaves;
  
  req = axi4_master_tx::type_id::create("req");
  
  // Get bus matrix mode from config_db
  if(!uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::get(m_sequencer, "", "bus_matrix_mode", bus_mode)) begin
    bus_mode = axi4_bus_matrix_ref::NONE; // Default to NONE
  end
  
  // Determine number of slaves based on bus matrix mode
  case(bus_mode)
    axi4_bus_matrix_ref::NONE: num_slaves = 4;
    axi4_bus_matrix_ref::BASE_BUS_MATRIX: num_slaves = 4;
    axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: num_slaves = 10;
    default: num_slaves = 4;
  endcase
  
  // Select a valid slave for write (avoid read-only slaves)
  if (bus_mode == axi4_bus_matrix_ref::NONE) begin
    // For NONE mode, avoid slave 1 (if it's read-only)
    int valid_slaves[] = '{0, 2, 3};
    target_slave_id = valid_slaves[$urandom_range(0, 2)];
  end else if (bus_mode == axi4_bus_matrix_ref::BASE_BUS_MATRIX) begin
    // For BASE mode:
    // Slave 0 (DDR): All masters can R/W
    // Slave 1 (Boot_ROM): Read-only
    // Slave 2 (Peripheral): Only M0,M1,M2 can access
    // Slave 3 (HW_Fuse): Read-only
    // For simplicity, always use slave 0 or 2
    int valid_slaves[] = '{0, 2};
    target_slave_id = valid_slaves[$urandom_range(0, 1)];
  end else begin
    // For ENHANCED mode, avoid read-only and illegal slaves
    // S3: Illegal address hole
    // S4: Instruction-only (read-only)
    // S5: Read-only peripheral
    int valid_slaves[] = '{0, 1, 2, 6, 7, 8, 9};
    target_slave_id = valid_slaves[$urandom_range(0, 6)];
  end
  
  // Generate proper address based on bus matrix mode and slave
  case(bus_mode)
    axi4_bus_matrix_ref::NONE, axi4_bus_matrix_ref::BASE_BUS_MATRIX: begin
      case(target_slave_id)
        0: target_addr = 64'h0000_0100_0000_0000 + {$urandom_range(0, 'hFFF), 4'h0}; // DDR
        1: target_addr = 64'h0000_0000_0000_0000 + {$urandom_range(0, 'h1FF), 4'h0}; // Boot_ROM
        2: target_addr = 64'h0000_0010_0000_0000 + {$urandom_range(0, 'hFFF), 4'h0}; // Peripheral
        3: target_addr = 64'h0000_0020_0000_0000 + {$urandom_range(0, 'hFF), 4'h0};  // HW_Fuse
        default: target_addr = 64'h0000_0100_0000_0000;
      endcase
    end
    
    axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: begin
      case(target_slave_id)
        0: target_addr = 64'h0000_0008_0000_0000 + {$urandom_range(0, 'hFFF), 4'h0}; // S0: DDR Cache-Coherent
        1: target_addr = 64'h0000_0008_4000_0000 + {$urandom_range(0, 'hFFF), 4'h0}; // S1: DDR Non-Coherent
        2: target_addr = 64'h0000_0008_8000_0000 + {$urandom_range(0, 'hFFF), 4'h0}; // S2: DDR Shared Buffer
        6: target_addr = 64'h0000_000A_0001_0000 + {$urandom_range(0, 'hFF), 4'h0};  // S6: Privileged-Only
        7: target_addr = 64'h0000_000A_0002_0000 + {$urandom_range(0, 'hFF), 4'h0};  // S7: Secure-Only
        8: target_addr = 64'h0000_000A_0003_0000 + {$urandom_range(0, 'hFF), 4'h0};  // S8: Scratchpad
        9: target_addr = 64'h0000_000A_0004_0000 + {$urandom_range(0, 'hFF), 4'h0};  // S9: Attribute Monitor
        default: target_addr = 64'h0000_0008_0000_0000;
      endcase
    end
    
    default: target_addr = 64'h0000_0100_0000_0000;
  endcase
  
  // Calculate effective QoS (base + boost if enabled)
  if(user_boost_enable) begin
    effective_qos = base_qos_value + user_boost_value;
    if(effective_qos > 15) effective_qos = 15;  // Cap at maximum
  end
  else begin
    effective_qos = base_qos_value;
  end
  
  // Encode USER signal: [31:8]=reserved, [7:4]=boost_enable, [3:0]=boost_value
  user_signal = {24'h0, user_boost_enable, 3'b0, user_boost_value};
  
  start_item(req);
  
  if(!req.randomize() with {
    req.transfer_type == NON_BLOCKING_WRITE;
    req.awqos == base_qos_value;  // Use base QoS in protocol
    req.awuser == user_signal;     // USER carries boost info
    req.awburst == WRITE_INCR;
    req.awsize == WRITE_4_BYTES;
    req.awlen == 8'h00;  // Single beat burst
    req.awaddr == local::target_addr;
    req.awprot == 3'b000;  // Non-secure, non-privileged, data access
  }) begin
    `uvm_fatal("axi4", "Randomization failed for QoS USER boost write sequence")
  end
  
  // Set AWID to identify the master
  req.awid = $sformatf("AWID_%0d", master_id);
  
  `uvm_info(get_type_name(), $sformatf("QoS+USER Write - Mode: %s, Slave: %0d, Base QoS: %0h, USER Boost: %0s (value=%0h), Effective QoS: %0h, Address: 0x%016h", 
            bus_mode.name(), target_slave_id, base_qos_value, user_boost_enable ? "ENABLED" : "DISABLED", 
            user_boost_value, effective_qos, req.awaddr), UVM_MEDIUM)
  
  finish_item(req);
  
endtask : body

`endif