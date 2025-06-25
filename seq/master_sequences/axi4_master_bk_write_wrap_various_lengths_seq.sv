//----------------------------------------------------------------------
// Copyright (c) 2021, Truechip Solutions Pvt. Ltd.
// ALL RIGHTS RESERVED
//----------------------------------------------------------------------
// File name : axi4_master_bk_write_wrap_various_lengths_seq.sv
// Author    : Truechip
// Version   : 1.0
// Created   :
//----------------------------------------------------------------------

`ifndef AXI4_MASTER_BK_WRITE_WRAP_VARIOUS_LENGTHS_SEQ_SV
`define AXI4_MASTER_BK_WRITE_WRAP_VARIOUS_LENGTHS_SEQ_SV

//----------------------------------------------------------------------
// Class: axi4_master_bk_write_wrap_various_lengths_seq
// Description: Sequence for WRAP burst with various lengths (currently 4 beats)
//----------------------------------------------------------------------
class axi4_master_bk_write_wrap_various_lengths_seq extends axi4_master_base_seq;
  `uvm_object_utils(axi4_master_bk_write_wrap_various_lengths_seq)

  //--------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------
  function new(string name = "axi4_master_bk_write_wrap_various_lengths_seq");
    super.new(name);
  endfunction : new

  //--------------------------------------------------------------------
  // Task: body
  // Description: Generates and sends a WRAP write transaction
  //--------------------------------------------------------------------
  virtual task body();
    `uvm_info(get_type_name(), "Starting sequence: axi4_master_bk_write_wrap_various_lengths_seq", UVM_LOW)
    super.body();

    req = axi4_master_tx::type_id::create("req");

    start_item(req);

    // Define local variables for enum values to help constraint solver
    axi4_globals_pkg::tx_type_e  des_tx_type  = axi4_globals_pkg::WRITE;
    axi4_globals_pkg::awid_e     des_awid     = axi4_globals_pkg::AWID_11; // 0xB
    axi4_globals_pkg::awsize_e   des_awsize   = axi4_globals_pkg::WRITE_4_BYTES;
    axi4_globals_pkg::awburst_e  des_awburst  = axi4_globals_pkg::WRITE_WRAP;

    assert(req.randomize() with {
      req.tx_type == des_tx_type;
      req.awaddr == 32'h1200; // Aligned address
      req.awid == des_awid;
      req.awlen == 8'h03;     // 4 beats
      req.awsize == des_awsize;
      req.awburst == des_awburst;
    });

    // Populate WDATA with a test pattern for wrap
    // For a 4-beat WRAP at 0x1200 with 4 bytes/beat, total size = 16 bytes.
    // Addresses will be: 0x1200, 0x1204, 0x1208, 0x120C.
    // Wrap boundary = (awaddr / ( (awlen+1) * (2**awsize) )) * ( (awlen+1) * (2**awsize) )
    // Wrap boundary = (0x1200 / (4 * 4)) * (4*4) = (0x1200 / 16) * 16 = 0x1200.
    // So addresses are 0x1200, 0x1204, 0x1208, 0x120C.
    // If awaddr was 0x120C, addresses would be 0x120C, 0x1200, 0x1204, 0x1208.

    req.wdata.delete();
    for (int i = 0; i < (req.awlen + 1); i++) begin
      req.wdata.push_back(32'hC0DE0000 + i); // Example data pattern
    end

    finish_item(req);
    get_response(rsp);
    `uvm_info(get_type_name(), "Finished sequence: axi4_master_bk_write_wrap_various_lengths_seq", UVM_LOW)
  endtask : body

endclass : axi4_master_bk_write_wrap_various_lengths_seq

`endif // AXI4_MASTER_BK_WRITE_WRAP_VARIOUS_LENGTHS_SEQ_SV
