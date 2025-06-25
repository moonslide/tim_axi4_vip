//----------------------------------------------------------------------
// Copyright (c) 2021, Truechip Solutions Pvt. Ltd.
// ALL RIGHTS RESERVED
//----------------------------------------------------------------------
// File name : axi4_master_bk_read_max_burst_length_seq.sv
// Author    : Truechip
// Version   : 1.0
// Created   :
//----------------------------------------------------------------------

`ifndef AXI4_MASTER_BK_READ_MAX_BURST_LENGTH_SEQ_SV
`define AXI4_MASTER_BK_READ_MAX_BURST_LENGTH_SEQ_SV

//----------------------------------------------------------------------
// Class: axi4_master_bk_read_max_burst_length_seq
// Description: Sequence for reading with maximum burst length (256 beats)
//----------------------------------------------------------------------
class axi4_master_bk_read_max_burst_length_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_bk_read_max_burst_length_seq)

  //--------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------
  function new(string name = "axi4_master_bk_read_max_burst_length_seq");
    super.new(name);
  endfunction : new

  //--------------------------------------------------------------------
  // Task: body
  // Description: Generates and sends a read transaction with max burst length
  //--------------------------------------------------------------------
  virtual task body();
    `uvm_info(get_type_name(), "Starting sequence: axi4_master_bk_read_max_burst_length_seq", UVM_LOW)
    super.body();

    req = axi4_master_tx::type_id::create("req");

    start_item(req);
    assert(req.randomize() with {
      req.tx_type == READ; // Corrected
      req.araddr == 32'h1600; // Start address, must be aligned
      req.arid == axi4_globals_pkg::ARID_12;       // Example ID (0xC), using explicit package scope
      req.arlen == 8'hFF;     // 256 beats
      req.arsize == axi4_globals_pkg::READ_4_BYTES;   // 4 bytes per beat, using explicit package scope
      req.arburst == axi4_globals_pkg::READ_INCR; // Corrected and using explicit package scope
    });
    finish_item(req);

    // Get the response, which will include the read data
    // The 'req' object will be populated with rdata by the driver/sequencer communication
    // after the read operation completes.
    get_response(req); // Assuming get_response updates the same 'req' object or a 'rsp' object
                       // If 'rsp' is used, then 'rsp.rdata' would be checked.
                       // For simplicity, let's assume 'req' is updated with read data.

    // Optional: Basic check of received data properties if needed here,
    // otherwise rely on scoreboard for full data verification.
    if (req.rdata.size() == (req.arlen + 1)) begin // Corrected arlen to req.arlen for clarity if arlen is also a class member
      `uvm_info(get_type_name(), $sformatf("Correct number of read beats received: %0d", req.rdata.size()), UVM_LOW);
    end else begin
      `uvm_error(get_type_name(), $sformatf("Incorrect number of read beats. Expected: %0d, Got: %0d", (req.arlen+1), req.rdata.size()));
    end

    `uvm_info(get_type_name(), "Finished sequence: axi4_master_bk_read_max_burst_length_seq", UVM_LOW)
  endtask : body

endclass : axi4_master_bk_read_max_burst_length_seq

`endif // AXI4_MASTER_BK_READ_MAX_BURST_LENGTH_SEQ_SV
