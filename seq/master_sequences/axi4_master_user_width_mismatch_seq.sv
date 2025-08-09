`ifndef AXI4_MASTER_USER_WIDTH_MISMATCH_SEQ_INCLUDED_
`define AXI4_MASTER_USER_WIDTH_MISMATCH_SEQ_INCLUDED_

`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Class: axi4_master_user_width_mismatch_seq
// Master sequence to test USER signal width mismatch scenarios
// Tests truncation, padding, and width compatibility issues
//--------------------------------------------------------------------------------------------
class axi4_master_user_width_mismatch_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_user_width_mismatch_seq)

  // Configuration parameters
  string test_type = "TRUNCATION_32_TO_16";
  int num_tests = 1;
  int master_id = 0;
  int slave_id = 0;

  // Test patterns for different width scenarios
  bit [31:0] test_pattern_32bit;
  bit [15:0] test_pattern_16bit;
  bit [7:0]  test_pattern_8bit;
  bit [3:0]  test_pattern_4bit;
  bit        test_pattern_1bit;
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_user_width_mismatch_seq");
  extern task body();
  extern function bit [31:0] generate_test_pattern(string pattern_type);
  extern function void display_truncation_result(bit [31:0] original, int target_width);

endclass : axi4_master_user_width_mismatch_seq

//--------------------------------------------------------------------------------------------
// Construct: new
// Initializes the axi4_master_user_width_mismatch_seq class object
//
// Parameters:
//  name - axi4_master_user_width_mismatch_seq
//--------------------------------------------------------------------------------------------
function axi4_master_user_width_mismatch_seq::new(string name = "axi4_master_user_width_mismatch_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: generate_test_pattern
// Generates specific test patterns for width testing
//--------------------------------------------------------------------------------------------
function bit [31:0] axi4_master_user_width_mismatch_seq::generate_test_pattern(string pattern_type);
  case(pattern_type)
    "ALL_ONES":        return 32'hFFFF_FFFF;
    "ALL_ZEROS":       return 32'h0000_0000;
    "ALTERNATING":     return 32'hAAAA_AAAA;
    "ALTERNATING_INV": return 32'h5555_5555;
    "MSB_SET":         return 32'h8000_0000;
    "LSB_SET":         return 32'h0000_0001;
    "QOS_ROUTING":     return 32'h1234_5678; // QoS in [15:8], routing in [7:0]
    "INCREMENTAL":     return 32'h01234567;
    "BOUNDARY_16":     return 32'h0000_FFFF; // Tests 16-bit boundary
    "BOUNDARY_8":      return 32'h0000_00FF; // Tests 8-bit boundary
    "BOUNDARY_4":      return 32'h0000_000F; // Tests 4-bit boundary
    default:           return $urandom;
  endcase
endfunction : generate_test_pattern

//--------------------------------------------------------------------------------------------
// Function: display_truncation_result
// Shows what happens during truncation to different widths
//--------------------------------------------------------------------------------------------
function void axi4_master_user_width_mismatch_seq::display_truncation_result(bit [31:0] original, int target_width);
  bit [31:0] truncated;
  
  case(target_width)
    16: begin
      truncated = original & 32'h0000_FFFF;
      `uvm_info(get_type_name(), $sformatf("Truncation 32->16: 0x%08x -> 0x%04x (LSB preserved)", 
                original, truncated[15:0]), UVM_MEDIUM)
    end
    8: begin
      truncated = original & 32'h0000_00FF;
      `uvm_info(get_type_name(), $sformatf("Truncation 32->8: 0x%08x -> 0x%02x (LSB preserved)", 
                original, truncated[7:0]), UVM_MEDIUM)
    end
    4: begin
      truncated = original & 32'h0000_000F;
      `uvm_info(get_type_name(), $sformatf("Truncation 32->4: 0x%08x -> 0x%01x (LSB preserved)", 
                original, truncated[3:0]), UVM_MEDIUM)
    end
    1: begin
      truncated = original & 32'h0000_0001;
      `uvm_info(get_type_name(), $sformatf("Truncation 32->1: 0x%08x -> 0x%01x (LSB preserved)", 
                original, truncated[0]), UVM_MEDIUM)
    end
  endcase
endfunction : display_truncation_result

//--------------------------------------------------------------------------------------------
// Task: body
// Creates transactions to test USER signal width mismatches
//--------------------------------------------------------------------------------------------
task axi4_master_user_width_mismatch_seq::body();
  
  // Get configuration if set
  if(!uvm_config_db#(string)::get(null, get_full_name(), "test_type", test_type)) begin
    `uvm_info(get_type_name(), $sformatf("Using default test_type: %s", test_type), UVM_MEDIUM)
  end
  
  if(!uvm_config_db#(int)::get(null, get_full_name(), "num_tests", num_tests)) begin
    `uvm_info(get_type_name(), $sformatf("Using default num_tests: %0d", num_tests), UVM_MEDIUM)
  end
  
  uvm_config_db#(int)::get(null, get_full_name(), "master_id", master_id);
  uvm_config_db#(int)::get(null, get_full_name(), "slave_id", slave_id);
  
  `uvm_info(get_type_name(), $sformatf("Starting %s width mismatch tests (%0d iterations)", test_type, num_tests), UVM_LOW)
  
  repeat(num_tests) begin
    
    case(test_type)
      
      "TRUNCATION_32_TO_16": begin
        // Test truncation from 32-bit to 16-bit
        test_pattern_32bit = generate_test_pattern("QOS_ROUTING");
        `uvm_info(get_type_name(), "Testing 32-bit to 16-bit truncation", UVM_MEDIUM)
        display_truncation_result(test_pattern_32bit, 16);
        
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h3; // 4 beats
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == test_pattern_32bit;  // 32-bit USER
          wuser == test_pattern_32bit;   // Will be truncated to 16-bit at BUSER
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        finish_item(req);
      end
      
      "TRUNCATION_32_TO_8": begin
        // Test truncation from 32-bit to 8-bit
        test_pattern_32bit = generate_test_pattern("INCREMENTAL");
        `uvm_info(get_type_name(), "Testing 32-bit to 8-bit truncation", UVM_MEDIUM)
        display_truncation_result(test_pattern_32bit, 8);
        
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h1; // 2 beats
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == test_pattern_32bit;
          wuser == test_pattern_32bit;
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        finish_item(req);
      end
      
      "PADDING_8_TO_32": begin
        // Test padding from 8-bit to 32-bit
        test_pattern_8bit = 8'hA5;
        test_pattern_32bit = {24'h000000, test_pattern_8bit}; // Zero-padded
        `uvm_info(get_type_name(), $sformatf("Testing 8-bit to 32-bit padding: 0x%02x -> 0x%08x", 
                  test_pattern_8bit, test_pattern_32bit), UVM_MEDIUM)
        
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h2; // 3 beats
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == test_pattern_32bit;  // Padded value
          wuser == test_pattern_32bit;
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        finish_item(req);
      end
      
      "MSB_LSB_PRESERVATION": begin
        // Test MSB vs LSB preservation
        test_pattern_32bit = generate_test_pattern("ALL_ONES");
        `uvm_info(get_type_name(), "Testing MSB vs LSB preservation during truncation", UVM_MEDIUM)
        display_truncation_result(test_pattern_32bit, 16);
        display_truncation_result(test_pattern_32bit, 8);
        display_truncation_result(test_pattern_32bit, 4);
        display_truncation_result(test_pattern_32bit, 1);
        
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h0; // 1 beat
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == test_pattern_32bit;
          wuser == test_pattern_32bit;
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        finish_item(req);
      end
      
      "CHANNEL_WIDTH_DIFF": begin
        // Test channel width differences (AWUSER:32 vs BUSER:16)
        test_pattern_32bit = generate_test_pattern("QOS_ROUTING");
        test_pattern_16bit = test_pattern_32bit[15:0]; // Expected at BUSER
        `uvm_info(get_type_name(), $sformatf("Testing channel width diff: AWUSER=0x%08x, BUSER expects 0x%04x", 
                  test_pattern_32bit, test_pattern_16bit), UVM_MEDIUM)
        
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h7; // 8 beats
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == test_pattern_32bit;
          wuser == test_pattern_32bit;
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        finish_item(req);
      end
      
      "BOUNDARY_VALUES": begin
        // Test boundary values with different widths
        string pattern_names[] = '{"ALL_ONES", "ALTERNATING", "BOUNDARY_16", "BOUNDARY_8"};
        string selected_pattern = pattern_names[$urandom % 4];
        test_pattern_32bit = generate_test_pattern(selected_pattern);
        
        `uvm_info(get_type_name(), $sformatf("Testing boundary pattern %s: 0x%08x", 
                  selected_pattern, test_pattern_32bit), UVM_MEDIUM)
        display_truncation_result(test_pattern_32bit, 16);
        
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h3; // 4 beats
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == test_pattern_32bit;
          wuser == test_pattern_32bit;
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        finish_item(req);
      end
      
      "QOS_PRESERVATION": begin
        // Test QoS/routing information preservation
        test_pattern_32bit = 32'h0000_1234; // QoS=0x12, Routing=0x34 in LSBs
        `uvm_info(get_type_name(), $sformatf("Testing QoS preservation: 0x%08x (QoS=0x%02x, Route=0x%02x)", 
                  test_pattern_32bit, test_pattern_32bit[15:8], test_pattern_32bit[7:0]), UVM_MEDIUM)
        
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == WRITE;
          awid == `GET_AWID_ENUM(master_id);
          awaddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          awlen == 4'h1; // 2 beats
          awsize == WRITE_4_BYTES;
          awburst == WRITE_INCR;
          awuser == test_pattern_32bit;
          wuser == test_pattern_32bit;
          wdata.size() == awlen + 1;
          wstrb.size() == awlen + 1;
          foreach(wstrb[i]) {
            wstrb[i] == 4'hF;
          }
        });
        finish_item(req);
      end
      
      "READ_WIDTH_MISMATCH": begin
        // Test read channel width mismatch (ARUSER:32 vs RUSER:16)
        test_pattern_32bit = generate_test_pattern("QOS_ROUTING");
        test_pattern_16bit = test_pattern_32bit[15:0]; // Expected at RUSER
        `uvm_info(get_type_name(), $sformatf("Testing read width: ARUSER=0x%08x, RUSER expects 0x%04x", 
                  test_pattern_32bit, test_pattern_16bit), UVM_MEDIUM)
        
        req = axi4_master_tx::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          tx_type == READ;
          arid == `GET_ARID_ENUM(master_id);
          araddr == 64'h0000_0100_0000_0000 + (slave_id * 64'h1000_0000);
          arlen == 4'h3; // 4 beats
          arsize == READ_4_BYTES;
          arburst == READ_INCR;
          aruser == test_pattern_32bit;
        });
        finish_item(req);
      end
      
      default: begin
        `uvm_error(get_type_name(), $sformatf("Unknown test_type: %s", test_type))
      end
      
    endcase
    
    // Small delay between tests
    #100ns;
  end
  
  `uvm_info(get_type_name(), $sformatf("Completed %0d %s width mismatch tests", num_tests, test_type), UVM_LOW)
  
endtask : body

`endif