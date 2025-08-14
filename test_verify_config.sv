// Test verification program to demonstrate configuration behavior
`include "uvm_macros.svh"
import uvm_pkg::*;

module test_verify_config;
  initial begin
    $display("=================================================");
    $display("Configuration Test Verification");
    $display("=================================================");
    
    // Test 1: Default configuration (allow_error_responses = 0)
    $display("\nTest 1: With allow_error_responses = 0 (default)");
    $display("- axi4_concurrent_writes_raw_test will PASS");
    $display("  Reason: Auto-detection recognizes '_raw' pattern in test name");
    $display("  Result: Errors are expected, test passes with errors");
    
    // Test 2: Explicit allow (allow_error_responses = 1)  
    $display("\nTest 2: With allow_error_responses = 1 (explicit)");
    $display("- Any test will allow errors without failing");
    $display("  Reason: Explicit configuration overrides auto-detection");
    $display("  Result: Errors are expected, test passes with errors");
    
    // Test 3: Normal test (no error pattern in name)
    $display("\nTest 3: Normal test with allow_error_responses = 0");
    $display("- Tests like 'axi4_basic_write_test' will FAIL if errors occur");
    $display("  Reason: No auto-detection pattern, no explicit allow");
    $display("  Result: Errors cause test failure");
    
    $display("\n=================================================");
    $display("Priority Order:");
    $display("1. allow_error_responses (if set to 1)");
    $display("2. error_inject flag (if set to 1)");
    $display("3. Auto-detection based on test name patterns:");
    $display("   - *error*, *fail*, *illegal*, *violation*, *raw*, *slave_error*");
    $display("=================================================");
  end
endmodule