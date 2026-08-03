`ifndef AXI4_MASTER_TRACKB_READ_SEQ_INCLUDED_
`define AXI4_MASTER_TRACKB_READ_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_trackb_read_seq
//
// Read counterpart of axi4_master_trackb_write_seq: address constrained to a
// mapped fabric IP region. If read_addr is set (non-zero) the sequence reads
// exactly that address, which lets a test do a write-then-read-back pair.
//--------------------------------------------------------------------------------------------
class axi4_master_trackb_read_seq extends axi4_master_trackb_base_seq;
  `uvm_object_utils(axi4_master_trackb_read_seq)

  // When non-zero, read this exact address instead of randomising one.
  bit [63:0] read_addr = '0;

  extern function new(string name = "axi4_master_trackb_read_seq");
  extern task body();
endclass : axi4_master_trackb_read_seq

function axi4_master_trackb_read_seq::new(string name = "axi4_master_trackb_read_seq");
  super.new(name);
endfunction : new

task axi4_master_trackb_read_seq::body();
  bit [63:0] base;
  bit [63:0] size;

  super.body();
  base = region_base(target_slave);
  size = region_size(target_slave);

  req = axi4_master_tx::type_id::create("req");
  start_item(req);

  if (read_addr != 0) begin
    if (!req.randomize() with {
          req.tx_type       == READ;
          req.transfer_type == NON_BLOCKING_READ;
          req.arburst       == READ_INCR;
          req.arid          inside {[0:9]};
          req.araddr        == read_addr;
          req.arsize        <= max_size_log2;
          req.arlen         inside {[0:15]};
        }) begin
      `uvm_fatal(get_type_name(), "Track-B directed read randomization failed")
    end
  end
  else begin
    if (!req.randomize() with {
          req.tx_type       == READ;
          req.transfer_type == NON_BLOCKING_READ;
          req.arburst       == READ_INCR;
          req.arid          inside {[0:9]};
          req.araddr        >= base;
          req.araddr        <  base + size - 4096;
          req.arsize        <= max_size_log2;
          req.arlen         inside {[0:15]};
          req.araddr % 4096 == 0;
        }) begin
      `uvm_fatal(get_type_name(), "Track-B read randomization failed")
    end
  end

  `uvm_info(get_type_name(),
            $sformatf("Track-B READ  S%0d addr=0x%016h arid=%0d arlen=%0d arsize=%0d",
                      target_slave, req.araddr, req.arid, req.arlen, req.arsize), UVM_MEDIUM)
  finish_item(req);

endtask : body

`endif
