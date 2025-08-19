`ifndef AXI4_USER_TRANSACTION_TRACING_TEST_INCLUDED_
`define AXI4_USER_TRANSACTION_TRACING_TEST_INCLUDED_

class axi4_user_transaction_tracing_test extends axi4_base_test;
  `uvm_component_utils(axi4_user_transaction_tracing_test)
  
  // Virtual sequence for transaction tracing
  axi4_virtual_user_transaction_tracing_seq tracing_vseq;
  
  // Bus matrix mode configuration
  axi4_bus_matrix_ref::bus_matrix_mode_e bus_mode = axi4_bus_matrix_ref::NONE;
  
  function new(string name = "axi4_user_transaction_tracing_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Enable transaction tracing
    uvm_config_db#(int)::set(this, "*", "enable_tracing", 1);
    
    // Configure bus matrix mode
    configure_bus_matrix_mode();
  endfunction
  
  function void configure_bus_matrix_mode();
    string bus_matrix_mode_str;
    
    // Check command line for bus matrix mode
    if($value$plusargs("BUS_MATRIX_MODE=%s", bus_matrix_mode_str)) begin
      case(bus_matrix_mode_str)
        "NONE": begin
          bus_mode = axi4_bus_matrix_ref::NONE;
          `uvm_info(get_type_name(), "Configuring test for NONE bus matrix mode", UVM_LOW)
        end
        "4x4", "BASE": begin
          bus_mode = axi4_bus_matrix_ref::BASE_BUS_MATRIX;
          `uvm_info(get_type_name(), "Configuring test for 4x4 bus matrix mode", UVM_LOW)
        end
        "ENHANCED", "10x10": begin
          bus_mode = axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX;
          `uvm_info(get_type_name(), "Configuring test for ENHANCED bus matrix mode", UVM_LOW)
        end
        default: begin
          bus_mode = axi4_bus_matrix_ref::NONE;
          `uvm_info(get_type_name(), "Unknown BUS_MATRIX_MODE, defaulting to NONE", UVM_LOW)
        end
      endcase
    end else begin
      bus_mode = axi4_bus_matrix_ref::NONE;
      `uvm_info(get_type_name(), "No BUS_MATRIX_MODE specified, defaulting to NONE", UVM_LOW)
    end
    
    // Set configuration for all components
    uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", bus_mode);
    
    // Configure bus matrix mode in environment config
    axi4_env_cfg_h.bus_matrix_mode = bus_mode;
    
    `uvm_info(get_type_name(), $sformatf("Bus matrix mode configured: %s", 
              bus_mode.name()), UVM_LOW)
  endfunction
  
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting User Transaction Tracing Test", UVM_LOW)
    
    // Create and configure the virtual sequence
    tracing_vseq = axi4_virtual_user_transaction_tracing_seq::type_id::create("tracing_vseq");
    
    // Pass bus matrix mode to virtual sequence
    uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::set(this, "*", "bus_matrix_mode", bus_mode);
    
    // Start the virtual sequence
    tracing_vseq.start(axi4_env_h.axi4_virtual_seqr_h);
    
    // Brief delay for completion
    #100ns;
    
    `uvm_info(get_type_name(), "User Transaction Tracing Test Completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
endclass
`endif
