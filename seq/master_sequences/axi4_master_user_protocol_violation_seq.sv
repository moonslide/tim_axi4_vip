`ifndef AXI4_MASTER_USER_PROTOCOL_VIOLATION_SEQ_INCLUDED_
`define AXI4_MASTER_USER_PROTOCOL_VIOLATION_SEQ_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_protocol_violation_seq
// Master sequence to generate various USER signal protocol violations
// Intentionally creates violations to test error detection mechanisms
//--------------------------------------------------------------------------------------------
class axi4_master_user_protocol_violation_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_protocol_violation_seq)

  // Configuration parameters
  string violation_type = "AWUSER_WUSER_MISMATCH";
  int num_violations = 1;
  int master_id = 0;
  int slave_id = 0;

  // Random variables for generating violations
  rand bit [31:0] awuser_value;
  rand bit [31:0] wuser_value;
  rand bit [31:0] aruser_value;
  rand bit [31:0] ruser_value;
  
  //-------------------------------------------------------
  // Constraints
  //-------------------------------------------------------
  constraint valid_user_range_c {
    awuser_value inside {[32'h0:32'hFFFFFFFF]};
    wuser_value inside {[32'h0:32'hFFFFFFFF]};
    aruser_value inside {[32'h0:32'hFFFFFFFF]};
    ruser_value inside {[32'h0:32'hFFFFFFFF]};
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_user_protocol_violation_seq");
  extern task body();

endclass : axi4_master_user_protocol_violation_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the axi4_master_user_protocol_violation_seq class object
//
// Parameters:
//  name - axi4_master_user_protocol_violation_seq
//--------------------------------------------------------------------------------------------
function axi4_master_user_protocol_violation_seq::new(string name = "axi4_master_user_protocol_violation_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
// Creates transaction with specific USER signal protocol violations
//--------------------------------------------------------------------------------------------
task axi4_master_user_protocol_violation_seq::body();
  
  // Get configuration if set
  if(!uvm_config_db#(string)::get(null, get_full_name(), "violation_type", violation_type)) begin
    `uvm_info(get_type_name(), $sformatf("Using default violation_type: %s", violation_type), UVM_MEDIUM)
  end
  
  if(!uvm_config_db#(int)::get(null, get_full_name(), "num_violations", num_violations)) begin
    `uvm_info(get_type_name(), $sformatf("Using default num_violations: %0d", num_violations), UVM_MEDIUM)
  end
  
  uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id);
  uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id);
  
  `uvm_info(get_type_name(), $sformatf("Starting %s violations (%0d times)", violation_type, num_violations), UVM_LOW)
  
  repeat(num_violations) begin
    
    case(violation_type)
      
      "AWUSER_WUSER_MISMATCH": begin
        // Violation: AWUSER != WUSER
        `uvm_info(get_type_name(), "Creating AWUSER != WUSER mismatch violation", UVM_MEDIUM)
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h3; // 4 beats
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == 32'hAABBCCDD; // Set specific AWUSER
          wuser == 32'h11223344;  // Different WUSER - VIOLATION!
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        `uvm_info(get_type_name(), $sformatf("VIOLATION: AWUSER=0x%08x != WUSER=0x%08x", 
                  req.awuser, req.wuser), UVM_LOW)
        finish_item(req);
      end
      
      "RESERVED_BITS_SET": begin
        // Violation: Reserved bits [31:24] are set
        `uvm_info(get_type_name(), "Creating reserved bits violation", UVM_MEDIUM)
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h1; // 2 beats
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == 32'hFF00_1234; // Reserved bits [31:24] set - VIOLATION!
          wuser == 32'hFF00_1234;  // Same violation in WUSER
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        `uvm_info(get_type_name(), $sformatf("VIOLATION: Reserved bits set in USER=0x%08x", 
                  req.awuser), UVM_LOW)
        finish_item(req);
      end
      
      "USER_CHANGE_MID_BURST": begin
        // Violation: USER signal changes during burst (simulated)
        `uvm_info(get_type_name(), "Creating USER change mid-burst violation", UVM_MEDIUM)
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'hF; // 16 beats - long burst
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == 32'h5555_AAAA; // Initial USER value
          wuser == 32'h5555_AAAA;  // Same initially
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        // Note: Actual mid-burst change would require BFM modification
        `uvm_info(get_type_name(), $sformatf("VIOLATION: USER will change mid-burst from 0x%08x", 
                  req.awuser), UVM_LOW)
        finish_item(req);
      end
      
      "INVALID_COMBINATION": begin
        // Violation: Invalid combination of USER signal bits
        // Example: Routing to slave 15 with priority 0 (invalid combo)
        `uvm_info(get_type_name(), "Creating invalid USER combination violation", UVM_MEDIUM)
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h2; // 3 beats
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          // Invalid: Max routing with min priority
          awuser == 32'h000F_00FF; // Slave 15 routing with priority 0 - VIOLATION!
          wuser == 32'h000F_00FF;
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        `uvm_info(get_type_name(), $sformatf("VIOLATION: Invalid USER combination=0x%08x", 
                  req.awuser), UVM_LOW)
        finish_item(req);
      end
      
      "INTEGRITY_FAILURE": begin
        // Violation: Simulated integrity failure (all bits flipped)
        `uvm_info(get_type_name(), "Creating USER signal integrity failure", UVM_MEDIUM)
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h0; // 1 beat
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == 32'hA5A5_A5A5; // Pattern that might get corrupted
          wuser == 32'h5A5A_5A5A;  // Inverted pattern - simulates corruption
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        `uvm_info(get_type_name(), $sformatf("VIOLATION: USER integrity failure AWUSER=0x%08x, WUSER=0x%08x", 
                  req.awuser, req.wuser), UVM_LOW)
        finish_item(req);
      end
      
      "USER_OVERFLOW": begin
        // Violation: USER value overflow (all bits set)
        `uvm_info(get_type_name(), "Creating USER value overflow violation", UVM_MEDIUM)
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h1; // 2 beats
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == 32'hFFFF_FFFF; // Maximum value - potential overflow
          wuser == 32'hFFFF_FFFF;  // Maximum value
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        `uvm_info(get_type_name(), $sformatf("VIOLATION: USER overflow value=0x%08x", 
                  req.awuser), UVM_LOW)
        finish_item(req);
      end
      
      "UNEXPECTED_ZERO": begin
        // Violation: USER is zero when non-zero expected
        `uvm_info(get_type_name(), "Creating unexpected zero USER violation", UVM_MEDIUM)
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h7; // 8 beats
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == 32'h0000_0000; // Zero when routing info expected - VIOLATION!
          wuser == 32'h0000_0000;  // Zero USER
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        `uvm_info(get_type_name(), $sformatf("VIOLATION: Unexpected zero USER=0x%08x", 
                  req.awuser), UVM_LOW)
        finish_item(req);
      end
      
      "ARUSER_RUSER_MISMATCH": begin
        // Violation: ARUSER != RUSER (Read channel)
        `uvm_info(get_type_name(), "Creating ARUSER != RUSER mismatch violation", UVM_MEDIUM)
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == READ;
          arid == `GET_ARID_ENUM(master_id);
          araddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          arlen == 4'h3; // 4 beats
          arsize == READ_4_BYTES;
          arburst == READ_INCR;
          aruser == 32'hDEAD_BEEF; // Set specific ARUSER
          // Note: RUSER mismatch would be detected at slave/scoreboard
        });
        `uvm_info(get_type_name(), $sformatf("VIOLATION: ARUSER=0x%08x (RUSER mismatch expected)", 
                  req.aruser), UVM_LOW)
        finish_item(req);
      end
      
      default: begin
        `uvm_error(get_type_name(), $sformatf("Unknown violation type: %s", violation_type))
      end
      
    endcase
    
    // Small delay between violations
    #100ns;
  end
  
  `uvm_info(get_type_name(), $sformatf("Completed %0d %s violations", num_violations, violation_type), UVM_LOW)
  
endtask : body

`endif