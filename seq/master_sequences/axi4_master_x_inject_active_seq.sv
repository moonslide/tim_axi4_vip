`ifndef AXI4_MASTER_X_INJECT_ACTIVE_SEQ_INCLUDED_
`define AXI4_MASTER_X_INJECT_ACTIVE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_x_inject_active_seq
// Sequence for injecting X values during ACTIVE transactions (not idle)
//--------------------------------------------------------------------------------------------
class axi4_master_x_inject_active_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_x_inject_active_seq)

  // Injection control parameters
  rand bit [ADDRESS_WIDTH-1:0] target_addr;
  rand bit [DATA_WIDTH-1:0] test_data;
  rand bit [3:0] test_id;
  rand int unsigned x_inject_cycles;
  rand int unsigned delay_before_inject;  // Random delay before injection
  rand int unsigned num_transactions;     // Number of transactions to run
  rand int unsigned inject_after_n_txn;   // Inject after N transactions
  
  // Injection target
  rand bit inject_on_awvalid;
  rand bit inject_on_awaddr;
  rand bit inject_on_wdata;
  rand bit inject_on_arvalid;
  rand bit inject_on_bready;
  rand bit inject_on_rready;

  // Constraints
  constraint c_injection {
    x_inject_cycles inside {[1:5]};
    delay_before_inject inside {[10:100]}; // 10-100 cycles random delay
    num_transactions inside {[5:20]};
    inject_after_n_txn inside {[2:10]};
    inject_after_n_txn < num_transactions;
    
    // Only one injection type at a time
    $countones({inject_on_awvalid, inject_on_awaddr, inject_on_wdata, 
                inject_on_arvalid, inject_on_bready, inject_on_rready}) == 1;
  }
  
  constraint c_target_addr {
    target_addr[1:0] == 2'b00; // Word aligned
  }

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_x_inject_active_seq");
  extern task body();
  extern task run_normal_transactions(int num);
  extern task trigger_x_injection_during_transaction();

endclass : axi4_master_x_inject_active_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function axi4_master_x_inject_active_seq::new(string name = "axi4_master_x_inject_active_seq");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Task: body
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_active_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting ACTIVE X injection sequence"), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("  Total transactions: %0d", num_transactions), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("  Inject after transaction: %0d", inject_after_n_txn), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("  X injection cycles: %0d", x_inject_cycles), UVM_MEDIUM)
  `uvm_info(get_type_name(), $sformatf("  Delay before injection: %0d cycles", delay_before_inject), UVM_MEDIUM)
  
  // Run normal transactions first
  run_normal_transactions(inject_after_n_txn);
  
  // Now trigger X injection during an active transaction
  trigger_x_injection_during_transaction();
  
  // Continue with remaining transactions
  run_normal_transactions(num_transactions - inject_after_n_txn - 1);
  
  `uvm_info(get_type_name(), "Active X injection sequence completed", UVM_MEDIUM)
  
endtask : body

//--------------------------------------------------------------------------------------------
// Task: run_normal_transactions
// Run specified number of normal write/read transactions
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_active_seq::run_normal_transactions(int num);
  
  for(int i = 0; i < num; i++) begin
    req = axi4_master_tx::type_id::create($sformatf("req_%0d", i));
    start_item(req);
    
    assert(req.randomize() with {
      tx_type dist { WRITE := 60, READ := 40 };
      awaddr == local::target_addr + (i * 64);
      araddr == local::target_addr + (i * 64);
      awid == local::test_id;
      arid == local::test_id;
      awlen inside {[0:3]};  // 1-4 beat bursts
      arlen inside {[0:3]};
      awsize == WRITE_4_BYTES;
      arsize == READ_4_BYTES;
      awburst == WRITE_INCR;
      arburst == READ_INCR;
      transfer_type == BLOCKING_WRITE;
    }) else `uvm_fatal(get_type_name(), "Randomization failed")
    
    finish_item(req);
    
    // Small delay between transactions
    #($urandom_range(10, 50) * 1ns);
  end
  
endtask : run_normal_transactions

//--------------------------------------------------------------------------------------------
// Task: trigger_x_injection_during_transaction
// Start a transaction and inject X while it's active
//--------------------------------------------------------------------------------------------
task axi4_master_x_inject_active_seq::trigger_x_injection_during_transaction();
  
  `uvm_info(get_type_name(), "Triggering X injection during active transaction", UVM_HIGH)
  
  // Fork to run transaction and injection in parallel
  fork
    begin : transaction_thread
      // Start a write or read transaction
      req = axi4_master_tx::type_id::create("inject_req");
      start_item(req);
      
      assert(req.randomize() with {
        tx_type == (inject_on_arvalid || inject_on_rready) ? READ : WRITE;
        awaddr == local::target_addr;
        araddr == local::target_addr;
        awid == local::test_id;
        arid == local::test_id;
        awlen == 3;  // 4-beat burst to have longer transaction
        arlen == 3;
        awsize == WRITE_4_BYTES;
        arsize == READ_4_BYTES;
        awburst == WRITE_INCR;
        arburst == READ_INCR;
        transfer_type == BLOCKING_WRITE;
      }) else `uvm_fatal(get_type_name(), "Randomization failed")
      
      finish_item(req);
    end
    
    begin : injection_thread
      // Wait for random delay to let transaction start
      #(delay_before_inject * 1ns);
      
      // Set X injection flags based on target
      if(inject_on_awvalid) begin
        `uvm_info(get_type_name(), $sformatf("Injecting X on AWVALID during active write"), UVM_MEDIUM)
        uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid_active", 1);
        uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles);
      end
      else if(inject_on_awaddr) begin
        `uvm_info(get_type_name(), $sformatf("Injecting X on AWADDR while AWVALID=1"), UVM_MEDIUM)
        uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr_active", 1);
        uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles);
      end
      else if(inject_on_wdata) begin
        `uvm_info(get_type_name(), $sformatf("Injecting X on WDATA while WVALID=1"), UVM_MEDIUM)
        uvm_config_db#(bit)::set(null, "*", "x_inject_wdata_active", 1);
        uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles);
      end
      else if(inject_on_arvalid) begin
        `uvm_info(get_type_name(), $sformatf("Injecting X on ARVALID during active read"), UVM_MEDIUM)
        uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid_active", 1);
        uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles);
      end
      else if(inject_on_bready) begin
        `uvm_info(get_type_name(), $sformatf("Injecting X on BREADY while waiting for response"), UVM_MEDIUM)
        uvm_config_db#(bit)::set(null, "*", "x_inject_bready_active", 1);
        uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles);
      end
      else if(inject_on_rready) begin
        `uvm_info(get_type_name(), $sformatf("Injecting X on RREADY while receiving data"), UVM_MEDIUM)
        uvm_config_db#(bit)::set(null, "*", "x_inject_rready_active", 1);
        uvm_config_db#(int)::set(null, "*", "x_inject_cycles", x_inject_cycles);
      end
      
      // Wait for injection duration
      #(x_inject_cycles * 10ns);
      
      // Clear all injection flags
      uvm_config_db#(bit)::set(null, "*", "x_inject_awvalid_active", 0);
      uvm_config_db#(bit)::set(null, "*", "x_inject_awaddr_active", 0);
      uvm_config_db#(bit)::set(null, "*", "x_inject_wdata_active", 0);
      uvm_config_db#(bit)::set(null, "*", "x_inject_arvalid_active", 0);
      uvm_config_db#(bit)::set(null, "*", "x_inject_bready_active", 0);
      uvm_config_db#(bit)::set(null, "*", "x_inject_rready_active", 0);
    end
  join
  
  // Wait for recovery
  #(50ns);
  
endtask : trigger_x_injection_during_transaction

`endif