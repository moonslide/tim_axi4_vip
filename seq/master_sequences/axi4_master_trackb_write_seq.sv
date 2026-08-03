`ifndef AXI4_MASTER_TRACKB_WRITE_SEQ_INCLUDED_
`define AXI4_MASTER_TRACKB_WRITE_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_trackb_write_seq
//
// Non-blocking write whose address is constrained to a mapped region of the
// commercial fabric IP, so the transaction actually reaches a VIP slave agent
// instead of being answered with DECERR by the fabric's default slave.
// See axi4_master_trackb_base_seq for the reasoning and the region table.
//--------------------------------------------------------------------------------------------
class axi4_master_trackb_write_seq extends axi4_master_trackb_base_seq;
  `uvm_object_utils(axi4_master_trackb_write_seq)

  // Last address driven, so a paired read sequence can target the same place.
  bit [63:0] last_addr;

  extern function new(string name = "axi4_master_trackb_write_seq");
  extern task body();
endclass : axi4_master_trackb_write_seq

function axi4_master_trackb_write_seq::new(string name = "axi4_master_trackb_write_seq");
  super.new(name);
endfunction : new

task axi4_master_trackb_write_seq::body();
  bit [63:0] base;
  bit [63:0] size;

  super.body();
  base = region_base(target_slave);
  size = region_size(target_slave);

  req = axi4_master_tx::type_id::create("req");
  start_item(req);

  if (!req.randomize() with {
        req.tx_type       == WRITE;
        req.transfer_type == NON_BLOCKING_WRITE;
        req.awburst       == WRITE_INCR;
        req.awid          inside {[0:9]};

        // stay inside the mapped region, and leave room for the burst
        req.awaddr >= base;
        req.awaddr <  base + size - 4096;

        // beat no wider than the Track-B data bus
        req.awsize <= max_size_log2;

        // keep the burst short and, together with the alignment below,
        // guaranteed not to cross a 4KB boundary
        req.awlen inside {[0:15]};

        // 4KB-aligned start => a <=16-beat, <=32B/beat burst cannot cross 4KB
        req.awaddr % 4096 == 0;
      }) begin
    `uvm_fatal(get_type_name(), "Track-B write randomization failed")
  end

  last_addr = req.awaddr;
  `uvm_info(get_type_name(),
            $sformatf("Track-B WRITE S%0d addr=0x%016h awid=%0d awlen=%0d awsize=%0d",
                      target_slave, req.awaddr, req.awid, req.awlen, req.awsize), UVM_MEDIUM)
  finish_item(req);

endtask : body

`endif
