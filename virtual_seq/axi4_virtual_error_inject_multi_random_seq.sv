`ifndef AXI4_VIRTUAL_ERROR_INJECT_MULTI_RANDOM_SEQ_INCLUDED_
`define AXI4_VIRTUAL_ERROR_INJECT_MULTI_RANDOM_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_multi_random_seq
// Virtual sequence for multiple random error injections
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_multi_random_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_multi_random_seq)

  // Random injection parameters
  rand int num_injections;
  rand int injection_delay[];
  rand int injection_duration[];
  
  // Constraints
  constraint num_injections_c {
    num_injections inside {[1:20]};
  }
  
  constraint injection_arrays_c {
    injection_delay.size() == num_injections;
    injection_duration.size() == num_injections;
    
    foreach(injection_delay[i]) {
      injection_delay[i] inside {[50:500]}; // 50-500ns between injections
    }
    
    foreach(injection_duration[i]) {
      injection_duration[i] inside {[5:20]}; // 5-20 cycles per injection
    }
  }

  function new(string name = "axi4_virtual_error_inject_multi_random_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), $sformatf("Starting multi-random error injection with %0d injections", num_injections), UVM_MEDIUM)
    
    // Perform multiple random injections
    for(int i = 0; i < num_injections; i++) begin
      automatic int inj_idx = i;
      
      // Wait for random delay
      #(injection_delay[inj_idx] * 1ns);
      
      `uvm_info(get_type_name(), $sformatf("Injection %0d: Starting %0d-cycle X injection", inj_idx+1, injection_duration[inj_idx]), UVM_HIGH)
      
      // Randomly select signal to inject
      case($urandom_range(0, 5))
        0: begin
          uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 1);
          uvm_config_db#(int)::set(null, "*", "x_inject_cycles", injection_duration[inj_idx]);
          `uvm_info(get_type_name(), "Injecting X on AWVALID", UVM_HIGH)
        end
        1: begin  
          uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 1);
          uvm_config_db#(int)::set(null, "*", "x_inject_cycles", injection_duration[inj_idx]);
          `uvm_info(get_type_name(), "Injecting X on AWADDR", UVM_HIGH)
        end
        2: begin
          uvm_config_db#(bit)::set(null, "*", "x_inject_wdata", 1);
          uvm_config_db#(int)::set(null, "*", "x_inject_cycles", injection_duration[inj_idx]);
          `uvm_info(get_type_name(), "Injecting X on WDATA", UVM_HIGH)
        end
        3: begin
          uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid", 1);
          uvm_config_db#(int)::set(null, "*", "x_inject_cycles", injection_duration[inj_idx]);
          `uvm_info(get_type_name(), "Injecting X on ARVALID", UVM_HIGH)
        end
        4: begin
          uvm_config_db#(bit)::set(null, "*", "x_inject_bready", 1);
          uvm_config_db#(int)::set(null, "*", "x_inject_cycles", injection_duration[inj_idx]);
          `uvm_info(get_type_name(), "Injecting X on BREADY", UVM_HIGH)
        end
        5: begin
          uvm_config_db#(bit)::set(null, "*", "x_inject_rready", 1);
          uvm_config_db#(int)::set(null, "*", "x_inject_cycles", injection_duration[inj_idx]);
          `uvm_info(get_type_name(), "Injecting X on RREADY", UVM_HIGH)
        end
      endcase
      
      // Wait for injection to complete
      #(injection_duration[inj_idx] * 10ns);
      
      // Clear injection flags
      uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 0);
      uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 0);
      uvm_config_db#(bit)::set(null, "*", "x_inject_wdata", 0);
      uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid", 0);
      uvm_config_db#(bit)::set(null, "*", "x_inject_bready", 0);
      uvm_config_db#(bit)::set(null, "*", "x_inject_rready", 0);
    end
    
    // Allow time for recovery
    #500ns;
    
    `uvm_info(get_type_name(), "Multi-random error injection sequence completed", UVM_MEDIUM)
    
  endtask
endclass

`endif