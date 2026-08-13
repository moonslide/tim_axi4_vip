`ifndef AXI4_MASTER_4K_BOUNDARY_CROSS_SEQ_INCLUDED_
`define AXI4_MASTER_4K_BOUNDARY_CROSS_SEQ_INCLUDED_

class axi4_master_4k_boundary_cross_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_4k_boundary_cross_seq)
  `uvm_declare_p_sequencer(axi4_master_write_sequencer)
  int sid = 0;

  extern function new(string name="axi4_master_4k_boundary_cross_seq");
  extern task body();
  extern task drive_crossing_write(bit [ADDRESS_WIDTH-1:0] addr, string tag);
endclass

function axi4_master_4k_boundary_cross_seq::new(string name="axi4_master_4k_boundary_cross_seq");
  super.new(name);
endfunction

task axi4_master_4k_boundary_cross_seq::body();
  bit [ADDRESS_WIDTH-1:0] boundary_addr;
  bit [ADDRESS_WIDTH-1:0] unmapped_cross_addr;
  axi4_master_tx probe_req;
  axi4_bus_matrix_ref::bus_matrix_mode_e bus_mode;
  super.body();

  // Last 4 bytes of a page inside DDR_Memory, and of a page in unmapped space.
  unmapped_cross_addr = 64'h0000_0000_0050_0FFC;

  if(!uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::get(m_sequencer, "", "bus_matrix_mode", bus_mode))
    bus_mode = axi4_bus_matrix_ref::NONE;

  // AXI4 forbids a burst that crosses a 4KB boundary.  Prove that the
  // transaction-level constraints reject the crossing case.
  //
  // "randomize() returned 0" on its own is NOT that proof: it says some
  // constraint blocked the item, not WHICH one.  A future edit to wdata_c1 /
  // wstrb_c4 / awsize_c6, or any new hard constraint, could make the same
  // inline set unsatisfiable for an unrelated reason and this probe would go
  // on reporting success while the 4KB rule had silently stopped being
  // checked.  So each leg is a PAIR: the same randomize must fail with
  // ax_4kb_boundary_c7 enabled and succeed with only that constraint
  // disabled.  Nothing else changes between the two calls, so the rejection is
  // attributable to that constraint and to nothing else.
  boundary_addr = 64'h0000_0100_0000_0FFC;
  probe_req = axi4_master_tx::type_id::create("probe_req");
  if (probe_req == null)
    `uvm_fatal("4K_BOUNDARY_CROSS", "Failed to create negative-constraint probe item");

  if (probe_req.randomize() with {awaddr == boundary_addr;
                                  awlen  == 1;
                                  awsize == WRITE_4_BYTES;
                                  awburst == WRITE_INCR;
                                  tx_type == WRITE;
                                  transfer_type == NON_BLOCKING_WRITE;})
    `uvm_fatal("4K_BOUNDARY_CROSS", "Illegal two-beat write crossing 4KB boundary randomized");
  probe_req.aw_4kb_boundary_c7.constraint_mode(0);
  if (!probe_req.randomize() with {awaddr == boundary_addr;
                                   awlen  == 1;
                                   awsize == WRITE_4_BYTES;
                                   awburst == WRITE_INCR;
                                   tx_type == WRITE;
                                   transfer_type == NON_BLOCKING_WRITE;})
    `uvm_fatal("4K_BOUNDARY_CROSS",
               "Crossing write is still unsatisfiable with aw_4kb_boundary_c7 disabled - the probe above proved nothing about the 4KB rule");
  probe_req.aw_4kb_boundary_c7.constraint_mode(1);

  if (probe_req.randomize() with {araddr == boundary_addr;
                                  arlen  == 1;
                                  arsize == READ_4_BYTES;
                                  arburst == READ_INCR;
                                  tx_type == READ;
                                  transfer_type == NON_BLOCKING_READ;})
    `uvm_fatal("4K_BOUNDARY_CROSS", "Illegal two-beat read crossing 4KB boundary randomized");
  probe_req.ar_4kb_boundary_c7.constraint_mode(0);
  if (!probe_req.randomize() with {araddr == boundary_addr;
                                   arlen  == 1;
                                   arsize == READ_4_BYTES;
                                   arburst == READ_INCR;
                                   tx_type == READ;
                                   transfer_type == NON_BLOCKING_READ;})
    `uvm_fatal("4K_BOUNDARY_CROSS",
               "Crossing read is still unsatisfiable with ar_4kb_boundary_c7 disabled - the probe above proved nothing about the 4KB rule");
  probe_req.ar_4kb_boundary_c7.constraint_mode(1);

  // POSITIVE probe: the 4KB rule must not over-reject.
  //
  // AXI4 A3.4.1 lets an INCR burst START unaligned; the first beat's byte lanes
  // are truncated into the aligned block containing that address, so a single
  // 4-byte beat at ...0FFF occupies the aligned block 0xFFC..0xFFF and stays
  // inside the page.  ax*addr_c0 is only a SOFT alignment constraint, so an
  // unaligned sequence can legitimately ask for this -- and a 4KB check that
  // measures the span from the RAW address computes 4095+4=4099 and refuses it.
  // These two probes fail the test if that over-rejection ever comes back.
  if (!probe_req.randomize() with {awaddr == boundary_addr + 3;   // ...0FFF
                                   awlen  == 0;
                                   awsize == WRITE_4_BYTES;
                                   awburst == WRITE_INCR;
                                   tx_type == WRITE;
                                   transfer_type == NON_BLOCKING_WRITE;})
    `uvm_fatal("4K_BOUNDARY_CROSS",
               "Legal UNALIGNED single-beat write at the last bytes of a page was rejected - the 4KB constraint is measuring from the raw address instead of the aligned one");
  if (!probe_req.randomize() with {araddr == boundary_addr + 3;   // ...0FFF
                                   arlen  == 0;
                                   arsize == READ_4_BYTES;
                                   arburst == READ_INCR;
                                   tx_type == READ;
                                   transfer_type == NON_BLOCKING_READ;})
    `uvm_fatal("4K_BOUNDARY_CROSS",
               "Legal UNALIGNED single-beat read at the last bytes of a page was rejected - see the write-side note above");
  `uvm_info("4K_BOUNDARY_CROSS",
            "Legal unaligned end-of-page beats accepted; illegal crossing bursts rejected", UVM_MEDIUM)
  `uvm_info("4K_BOUNDARY_CROSS", "Illegal 4KB-crossing write/read constraints rejected as required", UVM_MEDIUM)

  // The final four-byte beat in the page is legal -- the in-page control case.
  start_item(req);
  if (!req.randomize() with {awaddr == boundary_addr;
                             awlen  == 0;
                             awsize == WRITE_4_BYTES;
                             awburst == WRITE_INCR;
                             tx_type == WRITE;
                             transfer_type == NON_BLOCKING_WRITE;
                             wuser == 4'h0;})
    `uvm_fatal("4K_BOUNDARY_CROSS", "Legal final-page-beat write failed to randomize");
  req.wdata.delete();
  req.wdata.push_back($urandom);
  req.wstrb.delete();
  req.wstrb.push_back('hf);
  req.wlast = 1'b1;
  finish_item(req);

  // The point of this test is what the INTERCONNECT does with a burst that
  // crosses a 4KB page, so the crossing bursts have to reach it.  Case 1 stays
  // inside DDR_Memory; case 2 crosses into unmapped space and must be answered
  // with DECERR.  Driving them is not a contradiction of aw_4kb_boundary_c7 --
  // that constraint keeps RANDOM traffic legal, and this directed sequence
  // switches it off for these two items only.
  drive_crossing_write(boundary_addr, "mapped");

  // The unmapped-space leg needs an address DECODER to answer with DECERR.
  // In NONE mode the master is wired 1:1 to a slave with no decoder in
  // between, so nobody answers and the burst just times out -- a bench
  // artifact, not a DUT finding.  Only drive it when a bus matrix exists.
  if(bus_mode != axi4_bus_matrix_ref::NONE)
    drive_crossing_write(unmapped_cross_addr, "unmapped (expect DECERR)");
  else
    `uvm_info("4K_BOUNDARY_CROSS",
              "BUS_MATRIX_MODE=NONE: no decoder, skipping the unmapped-space crossing write", UVM_MEDIUM)
endtask

//--------------------------------------------------------------------------------------------
// Task: drive_crossing_write
// Drives one two-beat INCR write that deliberately crosses a 4KB boundary.
//--------------------------------------------------------------------------------------------
task axi4_master_4k_boundary_cross_seq::drive_crossing_write(bit [ADDRESS_WIDTH-1:0] addr, string tag);
  `uvm_info("4K_BOUNDARY_CROSS",
            $sformatf("Driving %s 4KB-crossing write at 0x%016h", tag, addr), UVM_MEDIUM)
  start_item(req);
  req.aw_4kb_boundary_c7.constraint_mode(0);
  if (!req.randomize() with {awaddr == addr;
                             awlen  == 1;
                             awsize == WRITE_4_BYTES;
                             awburst == WRITE_INCR;
                             tx_type == WRITE;
                             transfer_type == NON_BLOCKING_WRITE;
                             wuser == 4'h0;})
    `uvm_fatal("4K_BOUNDARY_CROSS",
               $sformatf("Rand failed for %s 4KB-crossing write", tag));
  req.aw_4kb_boundary_c7.constraint_mode(1);
  req.wdata.delete();
  req.wdata.push_back($urandom); req.wdata.push_back($urandom);
  req.wstrb.delete();
  req.wstrb.push_back('hf); req.wstrb.push_back('hf);
  req.wlast = 1'b1;
  finish_item(req);
endtask

`endif
