`ifndef AXI4_SATURATION_MIDBURST_RESET_QOS_BOUNDARY_TEST_INCLUDED_
`define AXI4_SATURATION_MIDBURST_RESET_QOS_BOUNDARY_TEST_INCLUDED_

// Simple write sequence with controlled addressing
class axi4_simple_write_seq extends uvm_sequence #(axi4_master_tx);
  `uvm_object_utils(axi4_simple_write_seq)
  
  bit [63:0] base_addr = 64'h0000_0000_0000_0000;
  
  function new(string name = "axi4_simple_write_seq");
    super.new(name);
  endfunction
  
  task body();
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    if(!req.randomize() with {
      tx_type == WRITE;
      transfer_type == BLOCKING_WRITE;
      awaddr == base_addr + 64'h1000;
      awlen == 4'h0; // Single beat
      awsize == WRITE_4_BYTES;
      awburst == WRITE_FIXED;
      awid == `GET_AWID_ENUM(0);
      awprot == 3'b000;
      wdata.size() == 1;
      wstrb.size() == 1;
      wdata[0] == 32'hDEADBEEF;
      wstrb[0] == 4'hF;
    }) begin
      `uvm_fatal(get_type_name(), "Write randomization failed")
    end
    finish_item(req);
  endtask
endclass

// Simple read sequence with controlled addressing
class axi4_simple_read_seq extends uvm_sequence #(axi4_master_tx);
  `uvm_object_utils(axi4_simple_read_seq)
  
  bit [63:0] base_addr = 64'h0000_0000_0000_0000;
  
  function new(string name = "axi4_simple_read_seq");
    super.new(name);
  endfunction
  
  task body();
    req = axi4_master_tx::type_id::create("req");
    start_item(req);
    if(!req.randomize() with {
      tx_type == READ;
      transfer_type == BLOCKING_READ;
      araddr == base_addr + 64'h1000;
      arlen == 4'h0; // Single beat
      arsize == READ_4_BYTES;
      arburst == READ_FIXED;
      arid == `GET_ARID_ENUM(0);
      arprot == 3'b000;
    }) begin
      `uvm_fatal(get_type_name(), "Read randomization failed")
    end
    finish_item(req);
  endtask
endclass

class axi4_saturation_midburst_reset_qos_boundary_test extends axi4_base_test;
  `uvm_component_utils(axi4_saturation_midburst_reset_qos_boundary_test)
  
  // Simple sequences for basic test coverage
  axi4_simple_write_seq write_seq;
  axi4_simple_read_seq read_seq;
  
  // Bus matrix mode configuration
  axi4_bus_matrix_ref::bus_matrix_mode_e bus_mode = axi4_bus_matrix_ref::NONE;
  
  function new(string name = "axi4_saturation_midburst_reset_qos_boundary_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    int override_masters, override_slaves;
    axi4_bus_matrix_ref::bus_matrix_mode_e override_mode;
    
    // Configure bus matrix mode BEFORE calling super.build_phase()
    configure_bus_matrix_mode();
    
    // Create and configure test_config BEFORE super.build_phase()
    // This ensures base test uses our configuration
    test_config = axi4_test_config::type_id::create("test_config");
    test_config.bus_matrix_mode = bus_mode;
    test_config.num_masters = (bus_mode == axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX) ? 10 : 4;
    test_config.num_slaves = (bus_mode == axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX) ? 10 : 4;
    
    // Set in config_db so base test can get it
    uvm_config_db#(axi4_test_config)::set(this, "*", "test_config", test_config);
    
    super.build_phase(phase);
    
    // Apply our bus matrix mode overrides after super.build_phase()
    if (uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::get(this, "*", "bus_matrix_mode", override_mode)) begin
      axi4_env_cfg_h.bus_matrix_mode = override_mode;
    end
    
    if (uvm_config_db#(int)::get(this, "*", "override_num_masters", override_masters)) begin
      axi4_env_cfg_h.no_of_masters = override_masters;
    end
    
    if (uvm_config_db#(int)::get(this, "*", "override_num_slaves", override_slaves)) begin
      axi4_env_cfg_h.no_of_slaves = override_slaves;
    end
    
    `uvm_info(get_type_name(), "Saturation midburst reset QoS boundary test build phase", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Configured with Masters: %0d, Slaves: %0d", 
              axi4_env_cfg_h.no_of_masters, axi4_env_cfg_h.no_of_slaves), UVM_LOW)
  endfunction
  
  function void configure_bus_matrix_mode();
    string bus_matrix_mode_str;
    int selected_masters, selected_slaves;
    
    // Check command line for bus matrix mode
    if($value$plusargs("BUS_MATRIX_MODE=%s", bus_matrix_mode_str)) begin
      case(bus_matrix_mode_str)
        "NONE": begin
          bus_mode = axi4_bus_matrix_ref::NONE;
          selected_masters = 4;
          selected_slaves = 4;
          `uvm_info(get_type_name(), "Configuring test for NONE bus matrix mode (4x4 topology)", UVM_LOW)
        end
        "4x4", "BASE": begin
          bus_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
          selected_masters = 4;
          selected_slaves = 4;
          `uvm_info(get_type_name(), "Configuring test for BASE_BUS_MATRIX (4x4) mode", UVM_LOW)
        end
        "ENHANCED", "10x10": begin
          bus_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
          selected_masters = 10;
          selected_slaves = 10;
          `uvm_info(get_type_name(), "Configuring test for BUS_ENHANCED_MATRIX (10x10) mode", UVM_LOW)
        end
        default: begin
          bus_mode = axi4_bus_matrix_ref::NONE;
          selected_masters = 4;
          selected_slaves = 4;
          `uvm_info(get_type_name(), "Unknown BUS_MATRIX_MODE, defaulting to NONE (4x4)", UVM_LOW)
        end
      endcase
    end else begin
      bus_mode = axi4_bus_matrix_ref::NONE;
      selected_masters = 4;
      selected_slaves = 4;
      `uvm_info(get_type_name(), "No BUS_MATRIX_MODE specified, defaulting to NONE (4x4)", UVM_LOW)
    end
    
    // Set configuration for all components
    uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", bus_mode);
    uvm_config_db#(int)::set(this, "*", "override_num_masters", selected_masters);
    uvm_config_db#(int)::set(this, "*", "override_num_slaves", selected_slaves);
    
    `uvm_info(get_type_name(), $sformatf("Bus matrix mode configured: %s with %0d masters, %0d slaves", 
              bus_mode.name(), selected_masters, selected_slaves), UVM_LOW)
  endfunction
  
  task run_phase(uvm_phase phase);
    bit [63:0] base_addr;
    
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting Simplified Saturation Midburst Reset QoS Boundary Test", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("Bus mode: %s", bus_mode.name()), UVM_LOW)
    
    // Determine base address based on bus matrix mode
    // These addresses must match what the slaves expect
    case(bus_mode)
      axi4_bus_matrix_ref::NONE: begin
        // In NONE mode, any address works (all map to slave 0)
        base_addr = 64'h0000_0000_0000_0000;
        `uvm_info(get_type_name(), "Using NONE mode address: 0x0000_0000_0000_0000", UVM_LOW)
      end
      axi4_bus_matrix_ref::BASE_BUS_MATRIX: begin
        // In BASE mode, use DDR address range
        base_addr = 64'h0000_0100_0000_0000; // DDR in 4x4 mode
        `uvm_info(get_type_name(), "Using BASE mode DDR address: 0x0000_0100_0000_0000", UVM_LOW)
      end
      axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: begin
        // In ENHANCED mode, use DDR Non-Secure User range
        base_addr = 64'h0000_0008_4000_0000; // DDR Non-Secure User in ENHANCED mode
        `uvm_info(get_type_name(), "Using ENHANCED mode DDR address: 0x0000_0008_4000_0000", UVM_LOW)
      end
      default: begin
        base_addr = 64'h0000_0000_0000_0000;
        `uvm_info(get_type_name(), "Using default address: 0x0000_0000_0000_0000", UVM_LOW)
      end
    endcase
    
    // Phase 1: Basic Write
    `uvm_info(get_type_name(), "=== Phase 1: Basic Write ===", UVM_LOW)
    
    write_seq = axi4_simple_write_seq::type_id::create("write_seq");
    write_seq.base_addr = base_addr;
    write_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_write_seqr_h);
    
    // Brief delay
    #10ns;
    
    // Phase 2: Basic Read
    `uvm_info(get_type_name(), "=== Phase 2: Basic Read ===", UVM_LOW)
    
    read_seq = axi4_simple_read_seq::type_id::create("read_seq");
    read_seq.base_addr = base_addr;
    read_seq.start(axi4_env_h.axi4_virtual_seqr_h.axi4_master_read_seqr_h);
    
    // Brief delay for completion
    #10ns;
    
    `uvm_info(get_type_name(), "Simplified Saturation Test Completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass
`endif