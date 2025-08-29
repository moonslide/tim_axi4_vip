`ifndef AXI4_MASTER_EXCEPTION_RANDOM_SEQ_INCLUDED_
`define AXI4_MASTER_EXCEPTION_RANDOM_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_exception_random_seq
// Randomized exception injection sequence
//--------------------------------------------------------------------------------------------
class axi4_master_exception_random_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_exception_random_seq)

  // Exception type enum
  typedef enum int {
    ABORT_AWVALID,
    ABORT_ARVALID,
    NEAR_TIMEOUT,
    ILLEGAL_ACCESS,
    ECC_ERROR_SIM,
    SPECIAL_REG_READ
  } exception_type_e;
  
  // Randomization parameters
  rand int unsigned num_exceptions;
  rand int unsigned delay_between_exceptions;
  rand exception_type_e exception_types[];
  
  // Constraints
  constraint c_exceptions {
    num_exceptions inside {[3:10]};
    delay_between_exceptions inside {[100:1000]};
    exception_types.size() == num_exceptions;
    foreach(exception_types[i]) {
      exception_types[i] inside {[ABORT_AWVALID:SPECIAL_REG_READ]};
    }
  }
  
  // Random parameters for each exception type
  rand bit [63:0] random_addrs[];
  rand int unsigned random_stall_cycles[];
  rand bit [31:0] random_unlock_keys[];
  
  constraint c_exception_params {
    random_addrs.size() == num_exceptions;
    random_stall_cycles.size() == num_exceptions;
    random_unlock_keys.size() == num_exceptions;
    
    foreach(random_addrs[i]) {
      random_addrs[i][11:0] == 0; // 4KB aligned
      random_addrs[i] < 64'h0001_0000_0000; // Stay in lower memory
    }
    
    foreach(random_stall_cycles[i]) {
      random_stall_cycles[i] inside {[100:1000]};
    }
    
    foreach(random_unlock_keys[i]) {
      random_unlock_keys[i] != 0;
    }
  }

  function new(string name = "axi4_master_exception_random_seq");
    super.new(name);
  endfunction

  task body();
    axi4_master_exception_seq exc_seq;
    axi4_master_bk_write_seq write_seq;
    axi4_master_bk_read_seq read_seq;
    
    `uvm_info(get_type_name(), $sformatf("Starting Random Exception sequence with %0d exceptions", num_exceptions), UVM_MEDIUM)
    
    for(int i = 0; i < num_exceptions; i++) begin
      `uvm_info(get_type_name(), $sformatf("Exception %0d: Type=%s", i, exception_types[i].name()), UVM_MEDIUM)
      
      // Add some normal transactions before exception
      repeat($urandom_range(1, 3)) begin
        if($urandom_range(0, 1)) begin
          write_seq = axi4_master_bk_write_seq::type_id::create($sformatf("write_seq_%0d", i));
          write_seq.start(m_sequencer);
        end else begin
          read_seq = axi4_master_bk_read_seq::type_id::create($sformatf("read_seq_%0d", i));
          read_seq.start(m_sequencer);
        end
        #($urandom_range(10, 50) * 1ns);
      end
      
      // Create and configure exception sequence
      exc_seq = axi4_master_exception_seq::type_id::create($sformatf("exc_seq_%0d", i));
      
      case(exception_types[i])
        ABORT_AWVALID: begin
          exc_seq.exception_type = axi4_master_exception_seq::ABORT_AWVALID;
          exc_seq.target_addr = random_addrs[i];
        end
        
        ABORT_ARVALID: begin
          exc_seq.exception_type = axi4_master_exception_seq::ABORT_ARVALID;
          exc_seq.target_addr = random_addrs[i];
        end
        
        NEAR_TIMEOUT: begin
          exc_seq.exception_type = axi4_master_exception_seq::NEAR_TIMEOUT;
          exc_seq.target_addr = random_addrs[i];
          exc_seq.stall_cycles = random_stall_cycles[i];
        end
        
        ILLEGAL_ACCESS: begin
          exc_seq.exception_type = axi4_master_exception_seq::ILLEGAL_ACCESS;
          exc_seq.protected_addr = random_addrs[i];
          exc_seq.unlock_key = random_unlock_keys[i];
        end
        
        ECC_ERROR_SIM: begin
          exc_seq.exception_type = axi4_master_exception_seq::ECC_ERROR_SIM;
        end
        
        SPECIAL_REG_READ: begin
          exc_seq.exception_type = axi4_master_exception_seq::SPECIAL_REG_READ;
          exc_seq.num_special_reads = $urandom_range(2, 6);
        end
      endcase
      
      // Start the exception sequence
      exc_seq.start(m_sequencer);
      
      // Random delay before next exception
      #(delay_between_exceptions * 1ns);
    end
    
    // Add some recovery transactions
    repeat($urandom_range(2, 5)) begin
      write_seq = axi4_master_bk_write_seq::type_id::create("recovery_write");
      write_seq.start(m_sequencer);
      #($urandom_range(10, 50) * 1ns);
    end
    
  endtask

endclass

`endif