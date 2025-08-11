// Example of TC047 with full scalability support
`include "axi4_bus_config.svh"

class axi4_master_id_multiple_writes_different_awid_id_multiple_writes_different_awid_seq extends axi4_master_base_seq;
  
  // ... existing code ...
  
  function bit [15:0] get_awid_for_scenario(int scenario, int master_id);
    // Scalable AWID generation based on bus configuration
    int base_id = `GET_EFFECTIVE_AWID(master_id);
    int num_ids = `ID_MAP_BITS;
    
    case (scenario)
      0: return base_id;                               // Master's base ID
      1: return (base_id + 1) % num_ids;              // Next ID (wraps around)
      2: return (base_id + 2) % num_ids;              // Skip one
      3: return (base_id + 3) % num_ids;              // Skip two
      4: return (num_ids - 1 - base_id) % num_ids;    // Reverse mapping
      5: return (base_id * 3 + 1) % num_ids;          // Hash distribution
      default: return base_id;
    endcase
  endfunction
  
  task body();
    // ... existing code ...
    
    // SCENARIO 4: Scalable AWID test
    `uvm_info(get_type_name(), 
      $sformatf("ID_MULTIPLE_WRITES_DIFFERENT_AWID: Master[%0d] SCENARIO 4 - Scalable AWID test for %0dx%0d matrix", 
      master_id, `NUM_MASTERS, `NUM_SLAVES), UVM_LOW);
    
    for (int i = 0; i < 2; i++) begin
      // Use scalable ID mapping
      awid_val = `GET_EFFECTIVE_AWID(master_id);
      
      // For variety in large matrices, add offset
      if (`NUM_MASTERS > 16) begin
        // Use different IDs for better distribution
        awid_val = (awid_val + i * 4) % `ID_MAP_BITS;
      end
      
      req = axi4_master_tx::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        req.tx_type == WRITE;
        req.awid == `GET_AWID_ENUM(awid_val);  // Convert to enum
        // ... rest of constraints ...
      });
      finish_item(req);
      
      `uvm_info(get_type_name(), 
        $sformatf("Master[%0d] using AWID=%0d (effective ID for %0dx%0d matrix)", 
        master_id, awid_val, `NUM_MASTERS, `NUM_SLAVES), UVM_LOW);
    end
  endtask
endclass