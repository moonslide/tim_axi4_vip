`ifndef AXI4_SLAVE_SPARSE_ERROR_INJECTION_SEQ_INCLUDED_
`define AXI4_SLAVE_SPARSE_ERROR_INJECTION_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_sparse_error_injection_seq
// Injects sparse errors (SLVERR/DECERR) at specified rate
//--------------------------------------------------------------------------------------------
class axi4_slave_sparse_error_injection_seq extends axi4_slave_base_seq;
  `uvm_object_utils(axi4_slave_sparse_error_injection_seq)

  rand int error_rate = 1;  // Percentage
  rand int num_transactions = 100;
  
  constraint error_rate_c {
    error_rate inside {[1:5]};
  }

  extern function new(string name = "axi4_slave_sparse_error_injection_seq");
  extern task body();

endclass : axi4_slave_sparse_error_injection_seq

function axi4_slave_sparse_error_injection_seq::new(string name = "axi4_slave_sparse_error_injection_seq");
  super.new(name);
endfunction : new

task axi4_slave_sparse_error_injection_seq::body();
  super.body();
  
  `uvm_info(get_type_name(), $sformatf("Starting sparse error injection sequence with rate=%0d%%", error_rate), UVM_HIGH)
  
  for(int i = 0; i < num_transactions; i++) begin
    req = axi4_slave_tx::type_id::create("req");
    
    start_item(req);
    if($urandom_range(0, 99) < error_rate) begin
      // Inject error
      if(!req.randomize() with {
        bresp inside {WRITE_SLVERR, WRITE_DECERR};
        rresp inside {READ_SLVERR, READ_DECERR};
        aw_wait_states == 0;
        w_wait_states == 0;
        ar_wait_states == 0;
        b_wait_states == 0;
        r_wait_states == 0;
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
    end else begin
      // Normal response
      if(!req.randomize() with {
        bresp == WRITE_OKAY;
        rresp == READ_OKAY;
        aw_wait_states == 0;
        w_wait_states == 0;
        ar_wait_states == 0;
        b_wait_states == 0;
        r_wait_states == 0;
      }) begin
        `uvm_fatal(get_type_name(), "Randomization failed")
      end
    end
    finish_item(req);
  end
  
  `uvm_info(get_type_name(), "Completed sparse error injection sequence", UVM_HIGH)
  
endtask : body

`endif