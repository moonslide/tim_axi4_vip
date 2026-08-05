`ifndef AXI4_VIRTUAL_ALL_MASTER_SLAVE_ACCESS_SEQ_INCLUDED_
`define AXI4_VIRTUAL_ALL_MASTER_SLAVE_ACCESS_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_all_master_slave_access_write_seq
// Blocking write whose AWADDR is constrained to the address window the ACTIVE bus matrix
// mode has mapped to slave `sid`, taken from the master agent config that axi4_base_test
// programmed (master_min/max_addr_range_array, i.e. the same source the mem-mode sequences
// use - see axi4_master_nbk_slave_mem_mode_write_incr_burst_seq.sv:41-42).
//
// axi4_master_bk_write_seq randomises AWADDR across the whole ADDRESS_WIDTH space with only
// a size-alignment soft constraint (axi4_master_tx.sv:241). That is harmless in NONE mode -
// axi4_bus_matrix_ref::decode() maps every address to slave 0 and get_write_resp() returns
// WRITE_OKAY unconditionally - but under BASE/ENHANCED it lands in unmapped space and the
// matrix answers DECERR, which axi4_performance_metrics counts as a protocol issue.
// This test wants LEGAL master->slave traffic, so it constrains the address instead.
//--------------------------------------------------------------------------------------------
class axi4_all_master_slave_access_write_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_all_master_slave_access_write_seq)
  `uvm_declare_p_sequencer(axi4_master_write_sequencer)

  // Target slave index - set by the virtual sequence before each start()
  int sid = 0;

  extern function new(string name="axi4_all_master_slave_access_write_seq");
  extern task body();
endclass : axi4_all_master_slave_access_write_seq

function axi4_all_master_slave_access_write_seq::new(string name="axi4_all_master_slave_access_write_seq");
  super.new(name);
endfunction : new

task axi4_all_master_slave_access_write_seq::body();
  bit [ADDRESS_WIDTH-1:0] min_addr;
  bit [ADDRESS_WIDTH-1:0] max_addr;

  super.body();

  min_addr = p_sequencer.axi4_master_agent_cfg_h.master_min_addr_range_array[sid];
  max_addr = p_sequencer.axi4_master_agent_cfg_h.master_max_addr_range_array[sid];

  // Keep the whole burst inside the region: awsize is soft-constrained to <= 4 bytes and
  // INCR allows 256 beats, so the longest burst this sequence can emit spans 1 KiB.
  // 4 KiB of headroom covers that with margin; skip it on regions too small to spare it.
  if (max_addr > min_addr + 64'h0000_0000_0000_2000) begin
    max_addr = max_addr - 64'h0000_0000_0000_1000;
  end

  start_item(req);
  if(!req.randomize() with {
                              req.awaddr inside {[min_addr:max_addr]};
                              req.tx_type == WRITE;
                              req.transfer_type == BLOCKING_WRITE;
                            }) begin
    `uvm_fatal("axi4","Rand failed");
  end
  `uvm_info(get_type_name(), $sformatf("S%0d write addr 0x%016h (window 0x%016h-0x%016h)",
                                       sid, req.awaddr, min_addr, max_addr), UVM_HIGH);
  finish_item(req);
endtask : body

//--------------------------------------------------------------------------------------------
// Class: axi4_all_master_slave_access_read_seq
// Read counterpart of the above - same rationale, ARADDR instead of AWADDR.
//--------------------------------------------------------------------------------------------
class axi4_all_master_slave_access_read_seq extends axi4_master_bk_base_seq;
  `uvm_object_utils(axi4_all_master_slave_access_read_seq)
  `uvm_declare_p_sequencer(axi4_master_read_sequencer)

  // Target slave index - set by the virtual sequence before each start()
  int sid = 0;

  extern function new(string name="axi4_all_master_slave_access_read_seq");
  extern task body();
endclass : axi4_all_master_slave_access_read_seq

function axi4_all_master_slave_access_read_seq::new(string name="axi4_all_master_slave_access_read_seq");
  super.new(name);
endfunction : new

task axi4_all_master_slave_access_read_seq::body();
  bit [ADDRESS_WIDTH-1:0] min_addr;
  bit [ADDRESS_WIDTH-1:0] max_addr;

  super.body();

  min_addr = p_sequencer.axi4_master_agent_cfg_h.master_min_addr_range_array[sid];
  max_addr = p_sequencer.axi4_master_agent_cfg_h.master_max_addr_range_array[sid];

  if (max_addr > min_addr + 64'h0000_0000_0000_2000) begin
    max_addr = max_addr - 64'h0000_0000_0000_1000;
  end

  start_item(req);
  if(!req.randomize() with {
                              req.araddr inside {[min_addr:max_addr]};
                              req.tx_type == READ;
                              req.transfer_type == BLOCKING_READ;
                            }) begin
    `uvm_fatal("axi4","Rand failed");
  end
  `uvm_info(get_type_name(), $sformatf("S%0d read addr 0x%016h (window 0x%016h-0x%016h)",
                                       sid, req.araddr, min_addr, max_addr), UVM_HIGH);
  finish_item(req);
endtask : body

//--------------------------------------------------------------------------------------------
// Class: axi4_virtual_all_master_slave_access_seq
//--------------------------------------------------------------------------------------------
class axi4_virtual_all_master_slave_access_seq extends axi4_virtual_base_seq;
  `uvm_object_utils(axi4_virtual_all_master_slave_access_seq)

  extern function new(string name="axi4_virtual_all_master_slave_access_seq");
  extern task body();
  extern function void get_legal_slaves(output int wr_slaves[$], output int rd_slaves[$]);
endclass

function axi4_virtual_all_master_slave_access_seq::new(string name="axi4_virtual_all_master_slave_access_seq");
  super.new(name);
endfunction

//--------------------------------------------------------------------------------------------
// Function: get_legal_slaves
// Slaves this test may target without provoking an error response, per the ACTIVE bus matrix
// mode. Derived from axi4_bus_matrix_ref::configure_*_matrix() + get_write_resp/get_read_resp:
// only regions that are mapped, permit every master, and are subject to no AxPROT-dependent
// security / privilege / instruction-fetch check qualify.
//
//   NONE     : decode() returns slave 0 for every address and the responses are hard-coded
//              OKAY, and axi4_base_test gives the master the full 64-bit window, so the
//              constraint is a no-op here - this mode behaves exactly as before.
//   BASE 4x4 : S0 DDR_Memory  R/W for M0-M3.  S1 Boot_ROM read-only but readable by all.
//              (S2 excludes M3, S3 only M0/M3 - not universally safe, so not used.)
//   ENHANCED : S1 DDR Non-Secure User, S2 DDR Shared Buffer, S8 Scratchpad are R/W for all
//              masters with no prot check.  S5 RO Peripheral is additionally read-safe.
//              (S0/S4/S7 apply a security check, S6 a privilege check, S3 is the illegal
//              hole, S9 is write-only - all of them can legitimately answer DECERR/SLVERR.)
//--------------------------------------------------------------------------------------------
function void axi4_virtual_all_master_slave_access_seq::get_legal_slaves(output int wr_slaves[$],
                                                                        output int rd_slaves[$]);
  wr_slaves.delete();
  rd_slaves.delete();

  case (env_cfg_h.bus_matrix_mode)
    axi4_bus_matrix_ref::BUS_ENHANCED_MATRIX: begin
      wr_slaves = '{1, 2, 8};
      rd_slaves = '{1, 2, 5, 8};
    end
    axi4_bus_matrix_ref::BASE_BUS_MATRIX: begin
      wr_slaves = '{0};
      rd_slaves = '{0, 1};
    end
    default: begin // NONE
      wr_slaves = '{0};
      rd_slaves = '{0};
    end
  endcase

  // Never index past the slaves this run actually instantiated.
  foreach (wr_slaves[i]) begin
    if (wr_slaves[i] >= env_cfg_h.no_of_slaves) wr_slaves[i] = 0;
  end
  foreach (rd_slaves[i]) begin
    if (rd_slaves[i] >= env_cfg_h.no_of_slaves) rd_slaves[i] = 0;
  end
endfunction : get_legal_slaves

task axi4_virtual_all_master_slave_access_seq::body();
  axi4_slave_bk_write_seq axi4_slave_bk_write_seq_h;
  axi4_slave_bk_read_seq axi4_slave_bk_read_seq_h;
  axi4_all_master_slave_access_write_seq axi4_master_bk_write_seq_h;
  axi4_all_master_slave_access_read_seq axi4_master_bk_read_seq_h;
  int wr_slaves[$];
  int rd_slaves[$];

  super.body();

  get_legal_slaves(wr_slaves, rd_slaves);
  `uvm_info(get_type_name(), $sformatf("bus_matrix_mode=%s: write slaves=%p read slaves=%p",
                                       env_cfg_h.bus_matrix_mode.name(), wr_slaves, rd_slaves), UVM_LOW);

  // Create sequence handles
  axi4_slave_bk_write_seq_h = axi4_slave_bk_write_seq::type_id::create("axi4_slave_bk_write_seq_h");
  axi4_slave_bk_read_seq_h = axi4_slave_bk_read_seq::type_id::create("axi4_slave_bk_read_seq_h");
  axi4_master_bk_write_seq_h = axi4_all_master_slave_access_write_seq::type_id::create("axi4_master_bk_write_seq_h");
  axi4_master_bk_read_seq_h = axi4_all_master_slave_access_read_seq::type_id::create("axi4_master_bk_read_seq_h");

  // Start slave responders (exactly like working test)
  fork
    begin : T1_SL_WR
      forever begin
        axi4_slave_bk_write_seq_h.start(p_sequencer.axi4_slave_write_seqr_h);
      end
    end
    begin : T2_SL_RD
      forever begin
        axi4_slave_bk_read_seq_h.start(p_sequencer.axi4_slave_read_seqr_h);
      end
    end
  join_none

  // Run master sequences, walking the legal slave regions round-robin so the test
  // actually spreads over the mapped slaves instead of one random 64-bit address.
  fork
    begin: T1_WRITE
      for (int i = 0; i < 4; i++) begin
        axi4_master_bk_write_seq_h.sid = wr_slaves[i % wr_slaves.size()];
        axi4_master_bk_write_seq_h.start(p_sequencer.axi4_master_write_seqr_h);
      end
    end
    begin: T2_READ
      for (int i = 0; i < 6; i++) begin
        axi4_master_bk_read_seq_h.sid = rd_slaves[i % rd_slaves.size()];
        axi4_master_bk_read_seq_h.start(p_sequencer.axi4_master_read_seqr_h);
      end
    end
  join
endtask

`endif
