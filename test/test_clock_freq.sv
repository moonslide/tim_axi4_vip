// Simple standalone program to verify clock frequency changes
module test_clock_freq;
  
  time prev_time = 0;
  time curr_time = 0;
  real period;
  int count = 0;
  
  initial begin
    $display("Starting clock frequency verification...");
    
    // Monitor the clock from hdl_top
    fork
      begin
        forever begin
          @(posedge hdl_top.aclk);
          curr_time = $time;
          if(prev_time != 0) begin
            period = real'(curr_time - prev_time);
            count++;
            if(count <= 5 || (count > 10 && count <= 15) || (count > 25 && count <= 30)) begin
              $display("[%0t] Clock edge #%0d: Period = %.2f ns (%.2f MHz)", 
                       $time, count, period, 1000.0/period);
            end
          end
          prev_time = curr_time;
        end
      end
    join_none
    
    // Test sequence
    #100ns;
    $display("\n=== DEFAULT FREQUENCY (100 MHz) ===");
    #100ns;
    
    $display("\n=== CHANGING TO 2X FREQUENCY (200 MHz) ===");
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 2.0);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    #200ns;
    
    $display("\n=== CHANGING TO 0.5X FREQUENCY (50 MHz) ===");  
    uvm_config_db#(real)::set(null, "*", "clk_freq_scale", 0.5);
    uvm_config_db#(bit)::set(null, "*", "clk_freq_change_active", 1);
    #400ns;
    
    $display("\n=== Clock frequency verification complete ===");
    $display("Total edges monitored: %0d", count);
  end
  
endmodule