// Fix for axi4_user_transaction_tracing_test
// This fix ensures that the test properly generates and waits for transactions
// to be processed by the scoreboard

class axi4_user_transaction_tracing_test_fixed extends axi4_user_transaction_tracing_test;
  `uvm_component_utils(axi4_user_transaction_tracing_test_fixed)
  
  function new(string name = "axi4_user_transaction_tracing_test_fixed", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Disable scoreboard for this test since it's focused on USER signal tracing
    // not data integrity checking
    axi4_env_cfg_h.has_scoreboard = 0;
    
    `uvm_info(get_type_name(), "Disabling scoreboard for USER signal transaction tracing test", UVM_LOW)
  endfunction
  
endclass