`ifndef AXI4_EXCEPTION_CLK_GATING_TEST_INCLUDED_
`define AXI4_EXCEPTION_CLK_GATING_TEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_exception_clk_gating_test
// Tests clock gating functionality - stopping and restarting clock during transfers
//--------------------------------------------------------------------------------------------
class axi4_exception_clk_gating_test extends axi4_base_test;
  `uvm_component_utils(axi4_exception_clk_gating_test)
  
  // Virtual sequence handle
  axi4_virtual_write_read_seq axi4_virtual_write_read_seq_h;
  
  // Test configuration
  rand int num_gating_events;
  rand int gating_duration_ns[];
  rand int gating_interval_ns[];
  rand bit gate_during_transfer[];
  
  // Constraints
  constraint c_gating_events {
    num_gating_events inside {[3:8]};
  }
  
  constraint c_gating_arrays {
    gating_duration_ns.size() == num_gating_events;
    gating_interval_ns.size() == num_gating_events;
    gate_during_transfer.size() == num_gating_events;
    
    foreach(gating_duration_ns[i]) {
      gating_duration_ns[i] inside {[50:500]};  // 50-500ns gating
      gating_interval_ns[i] inside {[100:1000]}; // 100-1000ns between gates
      gate_during_transfer[i] dist {0 := 30, 1 := 70}; // 70% during transfer
    }
  }
  
  //--------------------------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------------------------
  function new(string name = "axi4_exception_clk_gating_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  //--------------------------------------------------------------------------------------------
  // Function: setup_axi4_env_cfg
  //--------------------------------------------------------------------------------------------
  virtual function void setup_axi4_env_cfg();
    super.setup_axi4_env_cfg();
    
    // Enable frequency checker for this test
    axi4_env_cfg_h.has_freq_checker = 1;
    
    `uvm_info(get_type_name(), "Enabled frequency checker for clock gating test", UVM_MEDIUM)
  endfunction : setup_axi4_env_cfg
  
  //--------------------------------------------------------------------------------------------
  // Function: build_phase
  //--------------------------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Disable X assertions during clock gating
    uvm_config_db#(bit)::set(this, "*", "disable_x_assertions", 1);
    
    `uvm_info(get_type_name(), "Build phase completed for Clock Gating Test", UVM_LOW)
  endfunction : build_phase
  
  //--------------------------------------------------------------------------------------------
  // Task: run_phase
  //--------------------------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    int active_masters;
    int active_slaves;
    
    phase.raise_objection(this);
    
    // Determine active interfaces based on bus matrix mode
    case(axi4_env_cfg_h.bus_matrix_mode)
      axi4_bus_matrix_ref::NONE: begin
        active_masters = 1;
        active_slaves = 1;
      end
      axi4_bus_matrix_ref::BASE_BUS_MATRIX: begin
        active_masters = 4;
        active_slaves = 4;
      end
      axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: begin
        active_masters = axi4_env_cfg_h.no_of_masters;
        active_slaves = axi4_env_cfg_h.no_of_slaves;
      end
    endcase
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    CLOCK GATING EXCEPTION TEST STARTING", UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    // Randomize test parameters
    if(!this.randomize()) begin
      `uvm_error(get_type_name(), "Randomization failed")
    end
    
    `uvm_info(get_type_name(), $sformatf("Test Configuration:"), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Number of gating events: %0d", num_gating_events), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Active Masters: %0d", active_masters), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Active Slaves: %0d", active_slaves), UVM_LOW)
    
    // Create and start the virtual sequence
    axi4_virtual_write_read_seq_h = axi4_virtual_write_read_seq::type_id::create("axi4_virtual_write_read_seq_h");
    
    fork
      // Thread 1: Run normal transfers
      begin
        `uvm_info(get_type_name(), "Starting AXI4 write-read transfers", UVM_LOW)
        axi4_virtual_write_read_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
      end
      
      // Thread 2: Inject clock gating events on different interfaces
      begin
        for(int i = 0; i < num_gating_events; i++) begin
          int target_intf;
          
          // Wait for interval
          #(gating_interval_ns[i] * 1ns);
          
          // Select random interface to gate
          target_intf = $urandom_range(0, active_masters-1);
          
          // Inject clock gating
          `uvm_info(get_type_name(), $sformatf("=== CLOCK GATING EVENT %0d on Interface %0d ===", i+1, target_intf), UVM_LOW)
          `uvm_info(get_type_name(), $sformatf("Stopping clock for %0d ns", gating_duration_ns[i]), UVM_LOW)
          
          // Stop the clock for specific interface
          uvm_config_db#(bit)::set(null, "*", $sformatf("clk_enable_intf_%0d", target_intf), 0);
          // Also set global for backward compatibility
          if(target_intf == 0) begin
            uvm_config_db#(bit)::set(null, "*", "clk_enable", 0);
          end
          
          // Notify freq_checker about gating event (treated as 0Hz)
          if(axi4_env_h.axi4_freq_checker_h != null) begin
            uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 0.0);
            uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
          end
          
          // Wait for gating duration
          #(gating_duration_ns[i] * 1ns);
          
          // Restart the clock
          uvm_config_db#(bit)::set(null, "*", $sformatf("clk_enable_intf_%0d", target_intf), 1);
          if(target_intf == 0) begin
            uvm_config_db#(bit)::set(null, "*", "clk_enable", 1);
          end
          
          // Notify freq_checker about restart (back to 1.0x)
          if(axi4_env_h.axi4_freq_checker_h != null) begin
            uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 1.0);
            uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
            #10ns;
            uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 0);
          end
          
          `uvm_info(get_type_name(), $sformatf("Clock restarted on interface %0d after gating event %0d", target_intf, i+1), UVM_LOW)
          
          // Small delay to stabilize
          #50ns;
        end
      end
    join_any
    
    // Allow some time for recovery
    #500ns;
    
    // Disable all virtual sequences
    disable fork;
    
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    `uvm_info(get_type_name(), "    CLOCK GATING EXCEPTION TEST COMPLETED", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    Total gating events: %0d", num_gating_events), UVM_LOW)
    `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    
    phase.drop_objection(this);
    
  endtask : run_phase
  
  //--------------------------------------------------------------------------------------------
  // Function: report_phase
  //--------------------------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    svr = uvm_report_server::get_server();
    
    if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
      `uvm_info(get_type_name(), "===============================================", UVM_LOW)
      `uvm_info(get_type_name(), "    CLOCK GATING TEST PASSED", UVM_LOW)
      `uvm_info(get_type_name(), "    Successfully handled clock stop/start", UVM_LOW)
      `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    end else begin
      `uvm_info(get_type_name(), "===============================================", UVM_LOW)
      `uvm_info(get_type_name(), "    CLOCK GATING TEST FAILED", UVM_LOW)
      `uvm_info(get_type_name(), "===============================================", UVM_LOW)
    end
  endfunction : report_phase
  
endclass : axi4_exception_clk_gating_test

`endif