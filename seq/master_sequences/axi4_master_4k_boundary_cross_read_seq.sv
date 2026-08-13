`ifndef AXI4_MASTER_4K_BOUNDARY_CROSS_READ_SEQ_INCLUDED_
`define AXI4_MASTER_4K_BOUNDARY_CROSS_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_4k_boundary_cross_read_seq
// Read-side counterpart of axi4_master_4k_boundary_cross_seq.  It exists as a
// separate sequence because a read item must be started on
// axi4_master_read_seqr_h; read items pushed onto the write sequencer are
// handed to the write driver and never appear on the AR channel.
//--------------------------------------------------------------------------------------------
class axi4_master_4k_boundary_cross_read_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_4k_boundary_cross_read_seq)
  `uvm_declare_p_sequencer(axi4_master_read_sequencer)

  extern function new(string name="axi4_master_4k_boundary_cross_read_seq");
  extern task body();
  extern task drive_crossing_read(bit [ADDRESS_WIDTH-1:0] addr, string tag);
endclass

function axi4_master_4k_boundary_cross_read_seq::new(string name="axi4_master_4k_boundary_cross_read_seq");
  super.new(name);
endfunction

task axi4_master_4k_boundary_cross_read_seq::body();
  bit [ADDRESS_WIDTH-1:0] boundary_addr;
  bit [ADDRESS_WIDTH-1:0] unmapped_cross_addr;
  axi4_bus_matrix_ref::bus_matrix_mode_e bus_mode;
  super.body();

  boundary_addr       = 64'h0000_0100_0000_0FFC;
  unmapped_cross_addr = 64'h0000_0000_0050_0FFC;

  if(!uvm_config_db#(axi4_bus_matrix_ref::bus_matrix_mode_e)::get(m_sequencer, "", "bus_matrix_mode", bus_mode))
    bus_mode = axi4_bus_matrix_ref::NONE;

  // In-page control: the last legal beat of the page.
  start_item(req);
  if (!req.randomize() with {araddr == boundary_addr;
                             arlen  == 0;
                             arsize == READ_4_BYTES;
                             arburst == READ_INCR;
                             tx_type == READ;
                             transfer_type == NON_BLOCKING_READ;})
    `uvm_fatal("4K_BOUNDARY_CROSS", "Legal final-page-beat read failed to randomize");
  finish_item(req);

  drive_crossing_read(boundary_addr, "mapped");

  // See the write-side counterpart: without a decoder there is nothing to
  // return DECERR, so the read data phase would simply time out.
  if(bus_mode != axi4_bus_matrix_ref::NONE)
    drive_crossing_read(unmapped_cross_addr, "unmapped (expect DECERR)");
  else
    `uvm_info("4K_BOUNDARY_CROSS",
              "BUS_MATRIX_MODE=NONE: no decoder, skipping the unmapped-space crossing read", UVM_MEDIUM)
endtask

//--------------------------------------------------------------------------------------------
// Task: drive_crossing_read
// Drives one two-beat INCR read that deliberately crosses a 4KB boundary.
// ar_4kb_boundary_c7 keeps RANDOM traffic legal; this directed sequence turns
// it off for this item so the interconnect's response can be observed.
//--------------------------------------------------------------------------------------------
task axi4_master_4k_boundary_cross_read_seq::drive_crossing_read(bit [ADDRESS_WIDTH-1:0] addr, string tag);
  `uvm_info("4K_BOUNDARY_CROSS",
            $sformatf("Driving %s 4KB-crossing read at 0x%016h", tag, addr), UVM_MEDIUM)
  start_item(req);
  req.ar_4kb_boundary_c7.constraint_mode(0);
  if (!req.randomize() with {araddr == addr;
                             arlen  == 1;
                             arsize == READ_4_BYTES;
                             arburst == READ_INCR;
                             tx_type == READ;
                             transfer_type == NON_BLOCKING_READ;})
    `uvm_fatal("4K_BOUNDARY_CROSS",
               $sformatf("Rand failed for %s 4KB-crossing read", tag));
  req.ar_4kb_boundary_c7.constraint_mode(1);
  finish_item(req);
endtask

`endif
