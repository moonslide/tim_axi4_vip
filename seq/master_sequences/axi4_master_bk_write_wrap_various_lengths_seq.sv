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
    assert(req.randomize() with {
      trans_type == WRITE_TRANSACTION;
      awaddr == 32'h1200; // Aligned address
      awid == 4'hB;       // Example ID
      awlen == 8'h03;     // 4 beats
      awsize == 3'b010;   // 4 bytes per beat
      awburst == AXI_BURST_WRAP;
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
