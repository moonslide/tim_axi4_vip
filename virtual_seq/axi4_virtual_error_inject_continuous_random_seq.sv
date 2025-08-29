`ifndef AXI4_VIRTUAL_ERROR_INJECT_CONTINUOUS_RANDOM_SEQ_INCLUDED_
`define AXI4_VIRTUAL_ERROR_INJECT_CONTINUOUS_RANDOM_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_error_inject_continuous_random_seq
// Virtual sequence for continuous random error injections throughout test
//--------------------------------------------------------------------------------------------
class axi4_virtual_error_inject_continuous_random_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_error_inject_continuous_random_seq)

  // Test duration in ns
  int test_duration = 5000;
  
  function new(string name = "axi4_virtual_error_inject_continuous_random_seq");
    super.new(name);
  endfunction

  task body();
    super.body();
    
    `uvm_info(get_type_name(), "Starting continuous random error injection", UVM_MEDIUM)
    
    // Enable continuous random injection mode
    uvm_config_db#(bit)::set(null, "*", "continuous_x_injection", 1);
    uvm_config_db#(bit)::set(null, "*", "randomize_injection", 1);
    
    // Run for test duration with random injections
    fork
      begin
        automatic int end_time = $time + test_duration;
        
        while($time < end_time) begin
          // Random delay between injections (10-100ns)
          #($urandom_range(10, 100) * 1ns);
          
          // Randomly select and inject on a signal
          case($urandom_range(0, 5))
            0: begin
              uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 1);
              #($urandom_range(3, 10) * 10ns);
              uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid", 0);
            end
            1: begin
              uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 1);
              #($urandom_range(3, 10) * 10ns);
              uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr", 0);
            end
            2: begin
              uvm_config_db#(bit)::set(null, "*", "x_inject_wdata", 1);
              #($urandom_range(3, 10) * 10ns);
              uvm_config_db#(bit)::set(null, "*", "x_inject_wdata", 0);
            end
            3: begin
              uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid", 1);
              #($urandom_range(3, 10) * 10ns);
              uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid", 0);
            end
            4: begin
              uvm_config_db#(bit)::set(null, "*", "x_inject_bready", 1);
              #($urandom_range(3, 10) * 10ns);
              uvm_config_db#(bit)::set(null, "*", "x_inject_bready", 0);
            end
            5: begin
              uvm_config_db#(bit)::set(null, "*", "x_inject_rready", 1);
              #($urandom_range(3, 10) * 10ns);
              uvm_config_db#(bit)::set(null, "*", "x_inject_rready", 0);
            end
          endcase
        end
      end
    join
    
    // Disable continuous mode
    uvm_config_db#(bit)::set(null, "*", "continuous_x_injection", 0);
    
    `uvm_info(get_type_name(), "Continuous random error injection completed", UVM_MEDIUM)
    
  endtask
endclass

`endif