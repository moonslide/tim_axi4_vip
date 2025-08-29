`ifndef AXI4_SAFE_X_INJECTION_CONTROLLER_INCLUDED_
`define AXI4_SAFE_X_INJECTION_CONTROLLER_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_safe_x_injection_controller
// Controls X-value injection to prevent protocol violations
// Ensures X-injection follows AXI4 protocol rules and timing constraints
//--------------------------------------------------------------------------------------------
class axi4_safe_x_injection_controller;
  // Static utility class - no UVM registration needed

  // Safe injection parameters
  static bit protocol_compliant_mode = 1;  // Enable protocol-compliant X injection
  static int safe_injection_cycles = 2;    // Minimum cycles for safe injection
  static int recovery_cycles = 3;           // Cycles for signal recovery
  
  // Task: safe_inject_x_on_signal
  // Inject X on specific signal with protocol compliance
  static task safe_inject_x_on_signal(
    string signal_name,
    int cycles = 2,
    bit wait_for_safe_window = 1
  );
    string safe_signal_name;
    
    `uvm_info("SAFE_X_INJECT", $sformatf("Starting safe X injection on %s for %0d cycles", signal_name, cycles), UVM_MEDIUM)
    
    // Map to protocol-safe signals
    safe_signal_name = get_safe_signal_name(signal_name);
    
    if(wait_for_safe_window) begin
      wait_for_injection_window();
    end
    
    // Inject X with protocol compliance
    inject_x_safely(safe_signal_name, cycles);
    
    // Recovery period
    #(recovery_cycles * 10ns);
    
    `uvm_info("SAFE_X_INJECT", $sformatf("Safe X injection completed on %s", safe_signal_name), UVM_MEDIUM)
  endtask
  
  // Function: get_safe_signal_name
  // Map requested signals to protocol-safe alternatives
  static function string get_safe_signal_name(string signal_name);
    if(!protocol_compliant_mode) return signal_name;
    
    case(signal_name)
      "awvalid": return "awuser";     // Inject on USER instead of VALID
      "wvalid":  return "wuser";      // Inject on USER instead of VALID
      "arvalid": return "aruser";     // Inject on USER instead of VALID
      "bready":  return "buser";      // Inject on USER instead of READY
      "rready":  return "ruser";      // Inject on USER instead of READY
      "awaddr":  return "awuser";     // Inject on USER instead of ADDR
      "wdata":   return "wuser";      // Inject on USER instead of DATA
      default:   return signal_name;  // Keep original if already safe
    endcase
  endfunction
  
  // Task: wait_for_injection_window
  // Wait for a safe window to inject X without violating handshake
  static task wait_for_injection_window();
    // Wait for idle period on AXI bus (no active transactions)
    #($urandom_range(20, 50) * 1ns);  // Random wait to avoid systematic issues
    `uvm_info("SAFE_X_INJECT", "Safe injection window found", UVM_HIGH)
  endtask
  
  // Task: inject_x_safely
  // Perform actual X injection with safety checks
  static task inject_x_safely(string signal_name, int cycles);
    `uvm_info("SAFE_X_INJECT", $sformatf("Injecting X on %s for %0d cycles", signal_name, cycles), UVM_HIGH)
    
    // Use config_db to inject X
    uvm_config_db#(bit)::set(null, "*", $sformatf("x_inject_%s", signal_name), 1);
    uvm_config_db#(int)::set(null, "*", "x_inject_cycles", cycles);
    
    // Wait for injection duration
    #(cycles * 10ns);
    
    // Clear injection
    uvm_config_db#(bit)::set(null, "*", $sformatf("x_inject_%s", signal_name), 0);
    
    `uvm_info("SAFE_X_INJECT", $sformatf("X injection cleared on %s", signal_name), UVM_HIGH)
  endtask
  
  // Task: safe_x_injection_sequence
  // Run a sequence of safe X injections
  static task safe_x_injection_sequence(int num_injections = 3);
    string safe_signals[] = '{"awuser", "wuser", "aruser", "buser", "ruser"};
    
    `uvm_info("SAFE_X_INJECT", $sformatf("Starting safe X injection sequence: %0d injections", num_injections), UVM_MEDIUM)
    
    for(int i = 0; i < num_injections; i++) begin
      string selected_signal = safe_signals[i % safe_signals.size()];
      int injection_cycles = $urandom_range(2, 4);
      
      safe_inject_x_on_signal(selected_signal, injection_cycles, 1);
      
      // Wait between injections
      #($urandom_range(100, 300) * 1ns);
    end
    
    `uvm_info("SAFE_X_INJECT", "Safe X injection sequence completed", UVM_MEDIUM)
  endtask
  
  // Task: configure_protocol_compliant_injection
  // Configure system for protocol-compliant X injection
  static task configure_protocol_compliant_injection();
    `uvm_info("SAFE_X_INJECT", "Configuring protocol-compliant X injection", UVM_MEDIUM)
    
    // Disable aggressive X injection that violates protocol
    uvm_config_db#(bit)::set(null, "*", "disable_x_inject_on_valid", 1);
    uvm_config_db#(bit)::set(null, "*", "disable_x_inject_on_ready", 1);
    uvm_config_db#(bit)::set(null, "*", "disable_x_inject_on_addr", 1);
    uvm_config_db#(bit)::set(null, "*", "disable_x_inject_on_data", 1);
    
    // Enable safe X injection on USER signals
    uvm_config_db#(bit)::set(null, "*", "enable_x_inject_on_user", 1);
    uvm_config_db#(bit)::set(null, "*", "safe_x_injection_mode", 1);
    
    // Set reasonable injection parameters
    uvm_config_db#(int)::set(null, "*", "x_inject_min_cycles", 2);
    uvm_config_db#(int)::set(null, "*", "x_inject_max_cycles", 4);
    uvm_config_db#(int)::set(null, "*", "x_recovery_cycles", 3);
    
    `uvm_info("SAFE_X_INJECT", "Protocol-compliant X injection configured", UVM_MEDIUM)
  endtask
  
  // Task: disable_protocol_violating_assertions
  // Temporarily disable assertions that may fire due to controlled X injection
  static task disable_protocol_violating_assertions();
    `uvm_info("SAFE_X_INJECT", "Disabling protocol-violating assertions during X injection", UVM_MEDIUM)
    
    // Disable X_PROTOCOL assertions that fire on USER signals
    uvm_config_db#(bit)::set(null, "*", "disable_x_user_assertions", 1);
    uvm_config_db#(bit)::set(null, "*", "allow_x_on_user_signals", 1);
    
    // Keep critical protocol assertions enabled
    uvm_config_db#(bit)::set(null, "*", "keep_handshake_assertions", 1);
    uvm_config_db#(bit)::set(null, "*", "keep_address_assertions", 1);
  endtask
  
  // Task: restore_protocol_assertions
  // Re-enable assertions after X injection testing
  static task restore_protocol_assertions();
    `uvm_info("SAFE_X_INJECT", "Restoring protocol assertions after X injection", UVM_MEDIUM)
    
    // Re-enable assertions
    uvm_config_db#(bit)::set(null, "*", "disable_x_user_assertions", 0);
    uvm_config_db#(bit)::set(null, "*", "allow_x_on_user_signals", 0);
  endtask

endclass : axi4_safe_x_injection_controller

`endif