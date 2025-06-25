//----------------------------------------------------------------------
// Copyright (c) 2021, Truechip Solutions Pvt. Ltd.
// ALL RIGHTS RESERVED
//----------------------------------------------------------------------
// File name : axi4_master_bk_write_max_burst_length_seq.sv
// Author    : Truechip
// Version   : 1.0
// Created   :
//----------------------------------------------------------------------

`ifndef AXI4_MASTER_BK_WRITE_MAX_BURST_LENGTH_SEQ_SV
`define AXI4_MASTER_BK_WRITE_MAX_BURST_LENGTH_SEQ_SV

//----------------------------------------------------------------------
// Class: axi4_master_bk_write_max_burst_length_seq
// Description: Sequence for writing with maximum burst length (256 beats)
//----------------------------------------------------------------------
class axi4_master_bk_write_max_burst_length_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_bk_write_max_burst_length_seq)

  //--------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------
  function new(string name = "axi4_master_bk_write_max_burst_length_seq");
    super.new(name);
  endfunction : new

  //--------------------------------------------------------------------
  // Task: body
  // Description: Generates and sends a write transaction with max burst length
  //--------------------------------------------------------------------
  virtual task body();
    `uvm_info(get_type_name(), "Starting sequence: axi4_master_bk_write_max_burst_length_seq", UVM_LOW)
    super.body(); // Call super.body() if it contains common setup/functionality

    // Create the transaction
    req = axi4_master_tx::type_id::create("req");

    start_item(req);

    // Define local variables for enum values to help constraint solver
    axi4_globals_pkg::tx_type_e  des_tx_type  = axi4_globals_pkg::WRITE;
    axi4_globals_pkg::awid_e     des_awid     = axi4_globals_pkg::AWID_10; // 4'hA
    axi4_globals_pkg::awsize_e   des_awsize   = axi4_globals_pkg::WRITE_4_BYTES; // 3'b010
    axi4_globals_pkg::awburst_e  des_awburst  = axi4_globals_pkg::WRITE_INCR;

    assert(req.randomize() with {
      req.tx_type == des_tx_type;
      req.awaddr == 32'h1100; // Start address
      req.awid == des_awid;
      req.awlen == 8'hFF; // 256 beats
      req.awsize == des_awsize;
      req.awburst == des_awburst;
      // WLAST will be handled by the driver/BFM
    });

    // Populate WDATA with the specified pattern
    req.wdata.delete(); // Clear any previous/randomized data
    for (int i = 0; i < (req.awlen + 1); i++) begin
      req.wdata.push_back(32'hAABB0000 + i);
      // Assuming WSTRB should indicate all bytes valid for this test
      // The size of wstrb depends on DATA_WIDTH. For 32-bit data (4 bytes as per awsize):
      // If DATA_WIDTH is 32, wstrb is 4 bits.
      // This should ideally be handled by constraints in axi4_master_tx or here if specific.
      // For now, let's assume constraints in axi4_master_tx handle wstrb appropriately
      // or that the driver/BFM will populate it based on awsize if not fully specified here.
      // Example if DATA_WIDTH is 32: req.wstrb.push_back(4'b1111);
    end

    finish_item(req);

    // Get the response
    get_response(rsp); // Assuming 'rsp' is defined in the base sequence or handled appropriately

    `uvm_info(get_type_name(), "Finished sequence: axi4_master_bk_write_max_burst_length_seq", UVM_LOW)
  endtask : body

endclass : axi4_master_bk_write_max_burst_length_seq

`endif // AXI4_MASTER_BK_WRITE_MAX_BURST_LENGTH_SEQ_SV
