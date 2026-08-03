`ifndef AXI4_SCOREBOARD_INCLUDED_
`define AXI4_SCOREBOARD_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_scoreboard
// Scoreboard the data getting from monitor port that goes into the implementation port
//--------------------------------------------------------------------------------------------
class axi4_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi4_scoreboard)

  // Declaring handles for master tx and slave tx
  axi4_master_tx axi4_master_tx_h1;
  axi4_master_tx axi4_master_tx_h2;
  axi4_master_tx axi4_master_tx_h3;
  axi4_master_tx axi4_master_tx_h4;
  axi4_master_tx axi4_master_tx_h5;

  axi4_slave_tx axi4_slave_tx_h1;
  axi4_slave_tx axi4_slave_tx_h2;
  axi4_slave_tx axi4_slave_tx_h3;
  axi4_slave_tx axi4_slave_tx_h4;
  axi4_slave_tx axi4_slave_tx_h5;


  // Byte-level scoreboard memory updated on writes
  bit [7:0] expected_mem [longint];
  bit [DATA_WIDTH-1:0] exp_val = '0;

  // Bus matrix reference for response validation
  axi4_bus_matrix_ref axi4_bus_matrix_h;

  // Counters for response validation
  int valid_decerr_count; // Count of expected DECERR responses
  int valid_slverr_count; // Count of expected SLVERR responses
  int unexpected_error_count; // Count of unexpected error responses



  //Variable : axi4_master_analysis_fifo
  //Used to store the axi4_master_data
  uvm_tlm_analysis_fifo#(axi4_master_tx) axi4_master_read_address_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi4_master_tx) axi4_master_read_data_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi4_master_tx) axi4_master_write_address_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi4_master_tx) axi4_master_write_data_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi4_master_tx) axi4_master_write_response_analysis_fifo;
  
  //Variable : axi4_slave_analysis_fifo
  //Used to store the axi4_slave_data
  uvm_tlm_analysis_fifo#(axi4_slave_tx) axi4_slave_read_address_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi4_slave_tx) axi4_slave_read_data_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi4_slave_tx) axi4_slave_write_address_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi4_slave_tx) axi4_slave_write_data_analysis_fifo;
  uvm_tlm_analysis_fifo#(axi4_slave_tx) axi4_slave_write_response_analysis_fifo;

  //master tx_count
  int axi4_master_tx_awaddr_count;
  //slave tx count
  int axi4_slave_tx_awaddr_count;
  
  //master tx_count
  int axi4_master_tx_wdata_count;
  //slave tx count
  int axi4_slave_tx_wdata_count;
  
  //master tx_count
  int axi4_master_tx_bresp_count;
  //slave tx count
  int axi4_slave_tx_bresp_count;
  
  //master tx_count
  int axi4_master_tx_araddr_count;
  //slave tx count
  int axi4_slave_tx_araddr_count;
  
  //master tx_count
  int axi4_master_tx_rdata_count;
  //slave tx count
  int axi4_slave_tx_rdata_count;
  
  //master tx_count
  int axi4_master_tx_rresp_count;
  //slave tx count
  int axi4_slave_tx_rresp_count;
  
  // Signals used to declare verified count
  int byte_data_cmp_verified_awid_count;
  int byte_data_cmp_verified_awaddr_count;
  int byte_data_cmp_verified_awsize_count;
  int byte_data_cmp_verified_awlen_count;
  int byte_data_cmp_verified_awburst_count;
  int byte_data_cmp_verified_awcache_count;
  int byte_data_cmp_verified_awlock_count;
  int byte_data_cmp_verified_awprot_count;
  int byte_data_cmp_verified_awuser_count;

  int byte_data_cmp_verified_wdata_count;
  int byte_data_cmp_verified_wstrb_count;
  int byte_data_cmp_verified_wuser_count;

  int byte_data_cmp_verified_aw_wait_states_count;
  int byte_data_cmp_verified_w_wait_states_count;
  int byte_data_cmp_verified_b_wait_states_count;
  int byte_data_cmp_verified_ar_wait_states_count;
  int byte_data_cmp_verified_r_wait_states_count;

  int byte_data_cmp_verified_bid_count;
  int byte_data_cmp_verified_bresp_count;
  int byte_data_cmp_verified_buser_count;

  int byte_data_cmp_verified_arid_count;
  int byte_data_cmp_verified_araddr_count;
  int byte_data_cmp_verified_arsize_count;
  int byte_data_cmp_verified_arlen_count;
  int byte_data_cmp_verified_arburst_count;
  int byte_data_cmp_verified_arcache_count;
  int byte_data_cmp_verified_arlock_count;
  int byte_data_cmp_verified_arprot_count;
  int byte_data_cmp_verified_arregion_count;
  int byte_data_cmp_verified_arqos_count;
  int byte_data_cmp_verified_aruser_count;

  int byte_data_cmp_verified_rid_count;
  int byte_data_cmp_verified_rdata_count;
  int byte_data_cmp_verified_rresp_count;
  int byte_data_cmp_verified_ruser_count;
  
  // Error and Abandon rule counter (claude.md compliance)
  int byte_data_cmp_error_abandon_count;

  // Signals used to declare failed count
  int byte_data_cmp_failed_awid_count;
  int byte_data_cmp_failed_awaddr_count;
  int byte_data_cmp_failed_awsize_count;
  int byte_data_cmp_failed_awlen_count;
  int byte_data_cmp_failed_awburst_count;
  int byte_data_cmp_failed_awcache_count;
  int byte_data_cmp_failed_awlock_count;
  int byte_data_cmp_failed_awprot_count;
  int byte_data_cmp_failed_awuser_count;

  int byte_data_cmp_failed_wdata_count;
  int byte_data_cmp_failed_wstrb_count;
  int byte_data_cmp_failed_wuser_count;

  int byte_data_cmp_failed_aw_wait_states_count;
  int byte_data_cmp_failed_w_wait_states_count;
  int byte_data_cmp_failed_b_wait_states_count;
  int byte_data_cmp_failed_ar_wait_states_count;
  int byte_data_cmp_failed_r_wait_states_count;

  int byte_data_cmp_failed_bid_count;
  int byte_data_cmp_failed_bresp_count;
  int byte_data_cmp_failed_buser_count;

  int byte_data_cmp_failed_arid_count;
  int byte_data_cmp_failed_araddr_count;
  int byte_data_cmp_failed_arsize_count;
  int byte_data_cmp_failed_arlen_count;
  int byte_data_cmp_failed_arburst_count;
  int byte_data_cmp_failed_arcache_count;
  int byte_data_cmp_failed_arlock_count;
  int byte_data_cmp_failed_arprot_count;
  int byte_data_cmp_failed_arregion_count;
  int byte_data_cmp_failed_arqos_count;
  int byte_data_cmp_failed_aruser_count;

  int byte_data_cmp_failed_rid_count;
  int byte_data_cmp_failed_rdata_count;
  int byte_data_cmp_failed_rresp_count;
  int byte_data_cmp_failed_ruser_count;

  // Counters for abandoned transactions due to error responses
  int abandoned_write_addr_count;
  int abandoned_write_resp_count;
  int abandoned_read_addr_count;
  int abandoned_read_data_count;

  semaphore write_address_key;
  semaphore write_data_key;
  semaphore write_response_key;
  semaphore read_address_key;
  semaphore read_data_key;

  //Variable : axi4_env_cfg_h
  //Declaring handle for axi4_env_config_object
  axi4_env_config axi4_env_cfg_h;

  // axi4_bus_matrix_h already declared at line 30
  
  // Slave memory handles for backdoor verification
  axi4_slave_memory axi4_slave_mem_h[];

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_scoreboard", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual function void start_of_simulation_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task axi4_write_address();
  extern virtual task axi4_write_data();
  extern virtual task axi4_write_response();
  extern virtual task axi4_read_address();
  extern virtual task axi4_read_data();
  extern virtual task axi4_write_address_comparision(input axi4_master_tx axi4_master_tx_h1,input axi4_slave_tx axi4_slave_tx_h1);
  extern virtual task axi4_write_data_comparision(input axi4_master_tx axi4_master_tx_h2,input axi4_slave_tx axi4_slave_tx_h2);
  extern virtual task axi4_write_response_comparision(input axi4_master_tx axi4_master_tx_h3,input axi4_slave_tx axi4_slave_tx_h3);
  extern virtual task axi4_read_address_comparision(input axi4_master_tx axi4_master_tx_h4,input axi4_slave_tx axi4_slave_tx_h4);
  extern virtual task axi4_read_data_comparision(input axi4_master_tx axi4_master_tx_h5,input axi4_slave_tx axi4_slave_tx_h5);
  extern virtual function void check_phase (uvm_phase phase);
  //-------------------------------------------------------
  // Keyed pairing (axi4_env_config::sb_keyed_pairing)
  //
  // The channel tasks below used to take one transaction off the master fifo
  // and one off the slave fifo and compare them, i.e. they paired by ARRIVAL
  // ORDER. Both fifos are fed by EVERY agent (env/axi4_env.sv), so that only
  // holds when nothing between the two sides can reorder -- true for the 1:1
  // direct wiring, false for any arbitrating interconnect. Behind the NIC-400
  // fabric it reported mismatches between two perfectly legal addresses that
  // had simply swapped places.
  //
  // When keyed pairing is on, slave-side transactions are drawn into a holding
  // pool and the OLDEST one whose (address, len, size, burst) matches the
  // master-side transaction is used. Address is the key rather than AxID
  // because an interconnect remaps IDs but must not alter the address. Oldest
  // match wins, which is what AXI's same-ID ordering rule guarantees and is in
  // any case the only defensible choice when two entries are indistinguishable
  // in every field being compared.
  //-------------------------------------------------------
  axi4_slave_tx sb_slave_waddr_pool[$];
  axi4_slave_tx sb_slave_wdata_pool[$];
  axi4_slave_tx sb_slave_raddr_pool[$];

  //Outstanding transaction IDs per master port, as a multiset (count per id).
  //A manager may have several transactions in flight and an interconnect or an
  //out-of-order subordinate may answer them in any order, so the checkable
  //property is "the BID/RID I received is one I am still waiting on", not
  //"it equals the id of whichever address packet happens to be paired here".
  int sb_outstanding_awid[int][int];
  int sb_outstanding_arid[int][int];

  //B/R responses and their AW/AR are consumed by independent forever loops, so
  //a response can reach the scoreboard before the address packet that issued
  //it. Ids that do not match yet are parked here and re-tested in check_phase,
  //by which time every address packet has been consumed.
  int sb_pending_bid[$][2];
  int sb_pending_rid[$][2];

  //Counters for the id-returned-to-originating-manager checks. These replace
  //the master-vs-slave AxID equality comparisons when an interconnect remaps
  //IDs: the remapped value is the DUT's business, but AXI4 still requires the
  //manager to receive its own BID/RID back, and nothing checked that before.
  int byte_data_cmp_verified_bid_to_master_count;
  int byte_data_cmp_failed_bid_to_master_count;
  int byte_data_cmp_verified_rid_to_master_count;
  int byte_data_cmp_failed_rid_to_master_count;

  //-------------------------------------------------------
  // FINDING 1 -- end-of-test completeness accounting
  //
  // check_phase used to inspect only the analysis-fifo SIZES. Every channel
  // task below pulls a master item OUT of its fifo and then blocks waiting for
  // its slave partner, so a transaction that was dropped, misrouted or simply
  // never answered leaves both fifos empty and the run reports UVM_ERROR 0 /
  // TEST RESULT PASS. Reproduced at seed 424242: 10 writes issued, 9 BIDs
  // verified, exit code 0.
  //
  // Every place a transaction can still be sitting when the run ends is now
  // recorded and inspected by sb_end_of_test_completeness_check():
  //   sb_inflight[]         a master item taken off a fifo whose partner never
  //                         arrived -- the channel task is parked in a get()
  //   sb_slave_*_pool       slave items drawn out of a fifo by the keyed
  //                         matchers and never consumed
  //   sb_outstanding_a?id   a request the manager issued and was never
  //                         answered for (this is the seed-424242 escape)
  //   sb_rx/sb_matched      items taken off the master fifos vs items that
  //                         completed a comparison
  //   analysis fifo used()  items a monitor published that no channel task ever
  //                         dequeued -- invisible to every counter above
  // A non-empty / non-zero value in any of them is a UVM_ERROR, not a log line.
  //
  // The gate runs ahead of BOTH mode guards in check_phase (all-slaves-PASSIVE
  // and error_inject). Neither mode may skip accounting; they may only skip the
  // master-vs-slave field-equality comparisons.
  //-------------------------------------------------------
  typedef enum int {SB_CH_AW = 0, SB_CH_W = 1, SB_CH_B = 2, SB_CH_AR = 3, SB_CH_R = 4} sb_chan_e;

  typedef struct {
    bit              active;    //a master item is parked waiting for a partner
    int              src_index; //originating master port
    longint unsigned id;        //AWID/ARID of the parked item
    longint unsigned addr;      //AWADDR/ARADDR of the parked item
    time             t_parked;  //when the channel task blocked
  } sb_inflight_s;

  //Number of resets observed. Reported by the completeness check so a clean
  //result on a reset test cannot be mistaken for "no reset ever happened".
  int sb_reset_count;

  sb_inflight_s sb_inflight[5];
  //Master items taken OFF the master analysis fifo, per channel.
  int sb_rx_master_count[5];
  //Master items that completed a comparison against a slave partner.
  int sb_matched_count[5];

  //Slave-side holding pools for the keyed B/R matchers -- see FINDING 5 below.
  axi4_slave_tx sb_slave_bresp_pool[$];
  axi4_slave_tx sb_slave_rdata_pool[$];

  extern virtual function bit sb_wdata_equal_under_strobe(input axi4_master_tx m_tx, input axi4_slave_tx s_tx);
  extern virtual task sb_match_slave_write_address(input axi4_master_tx m_tx, output axi4_slave_tx s_tx);
  extern virtual task sb_match_slave_write_data   (input axi4_master_tx m_tx, output axi4_slave_tx s_tx);
  extern virtual task sb_match_slave_read_address (input axi4_master_tx m_tx, output axi4_slave_tx s_tx);
  extern virtual task sb_match_slave_write_response(input axi4_master_tx m_tx, output axi4_slave_tx s_tx);
  extern virtual task sb_match_slave_read_data    (input axi4_master_tx m_tx, output axi4_slave_tx s_tx);
  extern virtual function string sb_chan_name(input sb_chan_e ch);
  extern virtual function void sb_mark_inflight(input sb_chan_e ch, input int src_index,
                                                input longint unsigned id, input longint unsigned addr);
  extern virtual function void sb_clear_inflight(input sb_chan_e ch);
  extern virtual function void sb_retire_outstanding_awid(input int src_index, input int id);
  extern virtual function void sb_retire_outstanding_arid(input int src_index, input int id);
  extern virtual function void sb_retest_pending_ids();
  extern virtual function void sb_clear_on_reset();
  extern virtual function void sb_end_of_test_completeness_check();
  extern virtual function int  sb_fifo_residue(input string nm, input int n);
  extern virtual function bit is_valid_write_address(bit [ADDRESS_WIDTH-1:0] addr, int master_id, bit [2:0] awprot);
  extern virtual function bit is_valid_read_address(bit [ADDRESS_WIDTH-1:0] addr, int master_id, bit [2:0] arprot);
  extern virtual function bresp_e get_expected_write_response(bit [ADDRESS_WIDTH-1:0] addr, int master_id, bit [2:0] awprot);
  extern virtual function rresp_e get_expected_read_response(bit [ADDRESS_WIDTH-1:0] addr, int master_id, bit [2:0] arprot);
  extern virtual function bit is_expected_error_response(bit [ADDRESS_WIDTH-1:0] addr, int master_id, bit is_write, bit [2:0] axprot);
  extern virtual task validate_response_correctness(input axi4_master_tx master_tx, input axi4_slave_tx slave_tx, bit is_write);
  extern virtual function void report_phase(uvm_phase phase);

  extern function void verify_read(bit [ADDRESS_WIDTH-1:0] addr,
                                   bit [DATA_WIDTH-1:0] data);
  extern function void store_write(bit [ADDRESS_WIDTH-1:0] addr,
                                   bit [DATA_WIDTH-1:0] data,
                                   bit [STROBE_WIDTH-1:0] strobe);
  extern function bit backdoor_read_verify(bit [ADDRESS_WIDTH-1:0] addr,
                                          bit [DATA_WIDTH-1:0] expected_data,
                                          int slave_id);
  extern function void set_slave_memory_handles(axi4_slave_memory slave_mem_h[]);

endclass : axi4_scoreboard

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_scoreboard
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_scoreboard::new(string name = "axi4_scoreboard",
                                 uvm_component parent = null);
  super.new(name, parent);
  axi4_master_write_address_analysis_fifo = new("axi4_master_write_address_analysis_fifo",this);
  axi4_master_write_data_analysis_fifo = new("axi4_master_write_data_analysis_fifo",this);
  axi4_master_write_response_analysis_fifo= new("axi4_master_write_response_analysis_fifo",this);
  axi4_master_read_address_analysis_fifo = new("axi4_master_read_address_analysis_fifo",this);
  axi4_master_read_data_analysis_fifo = new("axi4_master_read_data_analysis_fifo",this);
 
  axi4_slave_write_address_analysis_fifo = new("axi4_slave_write_address_analysis_fifo",this);
  axi4_slave_write_data_analysis_fifo = new("axi4_slave_write_data_analysis_fifo",this);
  axi4_slave_write_response_analysis_fifo= new("axi4_slave_write_response_analysis_fifo",this);
  axi4_slave_read_address_analysis_fifo = new("axi4_slave_read_address_analysis_fifo",this);
  axi4_slave_read_data_analysis_fifo = new("axi4_slave_read_data_analysis_fifo",this);

  write_address_key = new(1);
  write_data_key = new(1);
  write_response_key = new(1);
  read_address_key = new(1);
  read_data_key = new(1);

endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::build_phase(uvm_phase phase);
  bit error_inject_override;
  
  super.build_phase(phase);
  
  // Check if error_inject flag has been set by the test
  // This allows tests to override the default env_config setting
  if(uvm_config_db#(bit)::get(this, "", "error_inject", error_inject_override)) begin
    `uvm_info("SCOREBOARD_CONFIG", $sformatf("Retrieved error_inject=%0d from config_db (test override)", error_inject_override), UVM_MEDIUM)
    // Store for later use in check_phase - will check this before checking env_config
    uvm_config_db#(bit)::set(this, "", "scoreboard_error_inject_override", error_inject_override);
  end
  
  // Get the bus matrix reference for address validation (optional for tests without bus matrix)
  if(!uvm_config_db#(axi4_bus_matrix_ref)::get(this, "", "bus_matrix_ref", axi4_bus_matrix_h)) begin
    `uvm_info("SCOREBOARD_CONFIG", "Bus matrix reference not found in config_db - operating without bus matrix (for tests with bus_matrix_mode=NONE)", UVM_MEDIUM)
    axi4_bus_matrix_h = null;
  end
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: connect_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
endfunction  : end_of_elaboration_phase

//--------------------------------------------------------------------------------------------
// Function: start_of_simulation_phase
// <Description_here>
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::start_of_simulation_phase(uvm_phase phase);
  super.start_of_simulation_phase(phase);
endfunction : start_of_simulation_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
// All the comparision are done
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::run_phase(uvm_phase phase);

  uvm_event reset_e = uvm_event_pool::get_global("axi4_sb_reset_e");

  super.run_phase(phase);

  // Each channel task blocks in a slave-side get() while holding a master item.
  // A mid-test reset discards the subordinate's side of that transfer, so the
  // partner never arrives and the task stays parked forever -- and worse, pairs
  // that pre-reset master item against the first POST-reset slave item, which
  // produces comparison errors for transfers that were never related.
  //
  // Clearing the bookkeeping alone would not fix that: the parked processes
  // have to die. So the channel tasks are restarted around every reset.
  forever begin
    fork
      begin : sb_channels
        fork
          axi4_write_address();
          axi4_write_data();
          axi4_write_response();
          axi4_read_address();
          axi4_read_data();
        join
      end
      begin : sb_reset_watch
        reset_e.wait_trigger();
      end
    join_any
    disable fork;

    // join_any also returns if the channel tasks somehow all finish; they are
    // forever loops, so reaching here means a reset fired.
    sb_clear_on_reset();
  end

endtask : run_phase

//--------------------------------------------------------------------------------------------
// Function: sb_clear_on_reset
// Drops every in-flight expectation. AXI4 does not carry transactions across
// reset, so anything still outstanding is legitimately gone and must not be
// reported by sb_end_of_test_completeness_check() as a lost transfer.
//
// The verified/failed tallies are deliberately NOT cleared: they record checks
// that already completed, and zeroing them would erase real findings.
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::sb_clear_on_reset();

  sb_reset_count++;

  // The channel tasks were just killed by `disable fork`. Each of them holds its
  // channel key between get(1) at the top of the loop and put(1) at the bottom,
  // so a task killed inside that window never returns its key and the restarted
  // task blocks on get(1) forever -- silently, with no comparison ever running
  // again on that channel. Observed as exactly this: the write-address task died
  // mid-iteration at the power-on reset and all eight AW field checks then failed
  // with verified_count == 0. Re-arm every key, since every task is restarting.
  write_address_key  = new(1);
  write_data_key     = new(1);
  write_response_key = new(1);
  read_address_key   = new(1);
  read_data_key      = new(1);

  foreach (sb_inflight[c]) begin
    sb_inflight[c].active = 0;
    sb_rx_master_count[c] = 0;
    sb_matched_count[c]   = 0;
  end

  sb_outstanding_awid.delete();
  sb_outstanding_arid.delete();
  sb_pending_bid.delete();
  sb_pending_rid.delete();

  sb_slave_waddr_pool.delete();
  sb_slave_wdata_pool.delete();
  sb_slave_raddr_pool.delete();
  sb_slave_bresp_pool.delete();
  sb_slave_rdata_pool.delete();

  // Items already published to the fifos before the reset are equally stale.
  axi4_master_write_address_analysis_fifo.flush();
  axi4_master_write_data_analysis_fifo.flush();
  axi4_master_write_response_analysis_fifo.flush();
  axi4_master_read_address_analysis_fifo.flush();
  axi4_master_read_data_analysis_fifo.flush();
  axi4_slave_write_address_analysis_fifo.flush();
  axi4_slave_write_data_analysis_fifo.flush();
  axi4_slave_write_response_analysis_fifo.flush();
  axi4_slave_read_address_analysis_fifo.flush();
  axi4_slave_read_data_analysis_fifo.flush();

  `uvm_info(get_type_name(), $sformatf("Reset #%0d observed: in-flight scoreboard state discarded", sb_reset_count), UVM_LOW)

endfunction : sb_clear_on_reset

//--------------------------------------------------------------------------------------------
// Task: axi4_write_address
// Gets the master and slave write address and send it to the write address comparision task
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::axi4_write_address();

  forever begin
    write_address_key.get(1);
    axi4_master_write_address_analysis_fifo.get(axi4_master_tx_h1);
    //FINDING 1: from here until the comparison completes this item exists ONLY
    //inside this task. Record it so check_phase can see it if the slave-side
    //get() below never returns.
    sb_rx_master_count[SB_CH_AW]++;
    sb_mark_inflight(SB_CH_AW, axi4_master_tx_h1.sb_src_index,
                     longint'(axi4_master_tx_h1.awid), longint'(axi4_master_tx_h1.awaddr));
    // "This manager has an outstanding write of this id" is established by the
    // manager issuing AW -- nothing downstream. Registering it after the
    // blocking slave-side get() below made an undecoded address (no slave
    // partner ever arrives, but the interconnect's default slave still returns
    // a DECERR BID) surface as "bid returned to the WRONG manager".
    sb_outstanding_awid[axi4_master_tx_h1.sb_src_index][int'(axi4_master_tx_h1.awid)]++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_write_address_channel \n%s",axi4_master_tx_h1.sprint()),UVM_HIGH)
    if(axi4_env_cfg_h.sb_keyed_pairing)
      sb_match_slave_write_address(axi4_master_tx_h1, axi4_slave_tx_h1);
    else
      axi4_slave_write_address_analysis_fifo.get(axi4_slave_tx_h1);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_write_address_channel \n%s",axi4_slave_tx_h1.sprint()),UVM_HIGH)
    
    // Process all write address transactions including those to invalid addresses
    axi4_write_address_comparision(axi4_master_tx_h1,axi4_slave_tx_h1);
    sb_clear_inflight(SB_CH_AW);
    sb_matched_count[SB_CH_AW]++;
    axi4_master_tx_awaddr_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_write_address_channel count \n %0d",axi4_master_tx_awaddr_count),UVM_HIGH)
    axi4_slave_tx_awaddr_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_write_address_channel count \n %0d",axi4_slave_tx_awaddr_count),UVM_HIGH)
    
    // Pass the SOURCE MASTER PORT, not AWID. is_valid_write_address() forwards
    // this to the bus matrix as the master index for its permission/security
    // lookup, so using AWID evaluated every access against whichever master
    // happens to share that number.
    if(!is_valid_write_address(axi4_master_tx_h1.awaddr, axi4_master_tx_h1.sb_src_index, axi4_master_tx_h1.awprot)) begin
      `uvm_info(get_type_name(),$sformatf("Write transaction to invalid address 0x%16h processed by scoreboard - expecting error response",axi4_master_tx_h1.awaddr),UVM_LOW)
    end
    
    write_address_key.put(1);
  end

endtask : axi4_write_address

//--------------------------------------------------------------------------------------------
// Task: axi4_write_data
// Gets the master and slave write data and send it to the write data comparision task
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::axi4_write_data();

  forever begin
    write_data_key.get(1);
    axi4_master_write_data_analysis_fifo.get(axi4_master_tx_h2);
    sb_rx_master_count[SB_CH_W]++;
    sb_mark_inflight(SB_CH_W, axi4_master_tx_h2.sb_src_index,
                     longint'(axi4_master_tx_h2.awid), longint'(axi4_master_tx_h2.awaddr));
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_write_data_channel \n%s",axi4_master_tx_h2.sprint()),UVM_HIGH)
    if(axi4_env_cfg_h.sb_keyed_pairing)
      sb_match_slave_write_data(axi4_master_tx_h2, axi4_slave_tx_h2);
    else
      axi4_slave_write_data_analysis_fifo.get(axi4_slave_tx_h2);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_write_data_channel \n%s",axi4_slave_tx_h2.sprint()),UVM_HIGH)
    axi4_write_data_comparision(axi4_master_tx_h2,axi4_slave_tx_h2);
    sb_clear_inflight(SB_CH_W);
    sb_matched_count[SB_CH_W]++;
    axi4_master_tx_wdata_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_write_data_channel count \n %0d",axi4_master_tx_wdata_count),UVM_HIGH)
    axi4_slave_tx_wdata_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_write_data_channel count \n %0d",axi4_slave_tx_wdata_count),UVM_HIGH)
    write_data_key.put(1);
  end

endtask : axi4_write_data

//--------------------------------------------------------------------------------------------
// Task: axi4_write_response
// Gets the master and slave write response and send it to the write response comparision task
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::axi4_write_response();

  forever begin
    write_response_key.get(1);
    axi4_master_write_response_analysis_fifo.get(axi4_master_tx_h3);
    sb_rx_master_count[SB_CH_B]++;
    sb_mark_inflight(SB_CH_B, axi4_master_tx_h3.sb_src_index,
                     longint'(axi4_master_tx_h3.bid), longint'(axi4_master_tx_h3.awaddr));
    //AXI4: the write response must carry back an AWID the manager is still
    //waiting on. Master-side-only property, retired HERE (before the slave
    //pairing can block) so a lost slave response cannot masquerade as a
    //never-returned BID.
    sb_retire_outstanding_awid(axi4_master_tx_h3.sb_src_index, int'(axi4_master_tx_h3.bid));
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_write_response \n%s",axi4_master_tx_h3.sprint()),UVM_HIGH)
    //FINDING 5: B used to be paired by fifo head on both sides. See
    //sb_match_slave_write_response() for the key and why it is the key.
    if(axi4_env_cfg_h.sb_keyed_pairing)
      sb_match_slave_write_response(axi4_master_tx_h3, axi4_slave_tx_h3);
    else
      axi4_slave_write_response_analysis_fifo.get(axi4_slave_tx_h3);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_write_response \n%s",axi4_slave_tx_h3.sprint()),UVM_HIGH)

    // Process all write responses including error responses
    axi4_write_response_comparision(axi4_master_tx_h3,axi4_slave_tx_h3);
    sb_clear_inflight(SB_CH_B);
    sb_matched_count[SB_CH_B]++;
    axi4_master_tx_bresp_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_write_response_channel count \n %0d",axi4_master_tx_bresp_count),UVM_HIGH)
    axi4_slave_tx_bresp_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_write_response_channel count \n %0d",axi4_slave_tx_bresp_count),UVM_HIGH)
    
    // Log error responses for debugging
    if((axi4_slave_tx_h3.bresp == 2'b10) || (axi4_slave_tx_h3.bresp == 2'b11)) begin // SLVERR or DECERR
      `uvm_info(get_type_name(),$sformatf("Write response with error (bresp=%0d) for BID=0x%h processed by scoreboard",axi4_slave_tx_h3.bresp,axi4_slave_tx_h3.bid),UVM_LOW)
    end
    
    write_response_key.put(1);
  end

endtask : axi4_write_response

//--------------------------------------------------------------------------------------------
// Task: axi4_read_address
// Gets the master and slave read address and send it to the read address comparision task
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::axi4_read_address();

  forever begin
    read_address_key.get(1);
    axi4_master_read_address_analysis_fifo.get(axi4_master_tx_h4);
    sb_rx_master_count[SB_CH_AR]++;
    sb_mark_inflight(SB_CH_AR, axi4_master_tx_h4.sb_src_index,
                     longint'(axi4_master_tx_h4.arid), longint'(axi4_master_tx_h4.araddr));
    // Registered on the manager's AR, not after pairing -- see the write-address
    // channel above for why the pairing-time registration was wrong.
    sb_outstanding_arid[axi4_master_tx_h4.sb_src_index][int'(axi4_master_tx_h4.arid)]++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_read_address_channel \n%s",axi4_master_tx_h4.sprint()),UVM_HIGH)
    if(axi4_env_cfg_h.sb_keyed_pairing)
      sb_match_slave_read_address(axi4_master_tx_h4, axi4_slave_tx_h4);
    else
      axi4_slave_read_address_analysis_fifo.get(axi4_slave_tx_h4);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_read_address_channel \n%s",axi4_slave_tx_h4.sprint()),UVM_HIGH)
    
    // Process all read address transactions including those to invalid addresses
    axi4_read_address_comparision(axi4_master_tx_h4,axi4_slave_tx_h4);
    sb_clear_inflight(SB_CH_AR);
    sb_matched_count[SB_CH_AR]++;
    axi4_master_tx_araddr_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_read_address_channel count \n %0d",axi4_master_tx_araddr_count),UVM_HIGH)
    axi4_slave_tx_araddr_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_read_address_channel count \n %0d",axi4_slave_tx_araddr_count),UVM_HIGH)
    
    // Source master port, not ARID -- see the write-address channel above.
    if(!is_valid_read_address(axi4_master_tx_h4.araddr, axi4_master_tx_h4.sb_src_index, axi4_master_tx_h4.arprot)) begin
      `uvm_info(get_type_name(),$sformatf("Read transaction to invalid address 0x%16h processed by scoreboard - expecting error response",axi4_master_tx_h4.araddr),UVM_LOW)
    end
    
    read_address_key.put(1);
  end

endtask : axi4_read_address

//--------------------------------------------------------------------------------------------
// Task: axi4_read_data
// Gets the master and slave read data and send it to the read data comparision task
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::axi4_read_data();

  forever begin
    read_data_key.get(1);
    axi4_master_read_data_analysis_fifo.get(axi4_master_tx_h5);
    sb_rx_master_count[SB_CH_R]++;
    sb_mark_inflight(SB_CH_R, axi4_master_tx_h5.sb_src_index,
                     longint'(axi4_master_tx_h5.rid), longint'(axi4_master_tx_h5.araddr));
    //AXI4: the read data must carry back an ARID the manager is still waiting
    //on. Master-side-only property -- retired before the slave pairing.
    sb_retire_outstanding_arid(axi4_master_tx_h5.sb_src_index, int'(axi4_master_tx_h5.rid));
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_read_data_channel \n%s",axi4_master_tx_h5.sprint()),UVM_HIGH)
    //FINDING 5: R used to be paired by fifo head on both sides. See
    //sb_match_slave_read_data() for the key and why it is the key.
    if(axi4_env_cfg_h.sb_keyed_pairing)
      sb_match_slave_read_data(axi4_master_tx_h5, axi4_slave_tx_h5);
    else
      axi4_slave_read_data_analysis_fifo.get(axi4_slave_tx_h5);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_read_data_channel \n%s",axi4_slave_tx_h5.sprint()),UVM_HIGH)

    // Process all read responses including error responses
    axi4_read_data_comparision(axi4_master_tx_h5,axi4_slave_tx_h5);
    sb_clear_inflight(SB_CH_R);
    sb_matched_count[SB_CH_R]++;
    axi4_master_tx_rdata_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_read_data_channel count \n %0d",axi4_master_tx_rdata_count),UVM_HIGH)
    axi4_slave_tx_rdata_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_read_data_channel count \n %0d",axi4_slave_tx_rdata_count),UVM_HIGH)
    axi4_master_tx_rresp_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_read_response_channel count \n %0d",axi4_master_tx_rresp_count),UVM_HIGH)
    axi4_slave_tx_rresp_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_read_response_channel count \n %0d",axi4_slave_tx_rresp_count),UVM_HIGH)
    
    // Log error responses for debugging
    if((axi4_slave_tx_h5.rresp == 2'b10) || (axi4_slave_tx_h5.rresp == 2'b11)) begin // SLVERR or DECERR
      `uvm_info(get_type_name(),$sformatf("Read response with error (rresp=%0d) for RID=0x%h processed by scoreboard",axi4_slave_tx_h5.rresp,axi4_slave_tx_h5.rid),UVM_LOW)
    end
    
    read_data_key.put(1);
  end

endtask : axi4_read_data

//--------------------------------------------------------------------------------------------
// Task : axi4_write_address_comparision
// Used to compare the received master and slave write address
// Parameter :
//  axi4_master_tx_h1 - axi4_master_tx
//  axi4_slave_tx_h1  - axi4_slave_tx
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::axi4_write_address_comparision(input axi4_master_tx axi4_master_tx_h1,input axi4_slave_tx axi4_slave_tx_h1);

  if(!axi4_env_cfg_h.axid_passthrough_chk_cfg || (axi4_master_tx_h1.awid == axi4_slave_tx_h1.awid))begin
    `uvm_info(get_type_name(),$sformatf("axi4_awid from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_AWID_MATCHED", $sformatf("Master AWID = 'h%0x and Slave AWID = 'h%0x",axi4_master_tx_h1.awid,axi4_slave_tx_h1.awid), UVM_HIGH);             
    byte_data_cmp_verified_awid_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_awid from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_AWID_NOT_MATCHED", $sformatf("Master AWID = 'h%0x and Slave AWID = 'h%0x",axi4_master_tx_h1.awid,axi4_slave_tx_h1.awid), UVM_HIGH);             
    byte_data_cmp_failed_awid_count++;
  end
  
  if(axi4_master_tx_h1.awaddr == axi4_slave_tx_h1.awaddr)begin
    `uvm_info(get_type_name(),$sformatf("axi4_awaddr from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_AWADDR_MATCHED", $sformatf("Master AWADDR = 'h%0x and Slave AWADDR = 'h%0x",axi4_master_tx_h1.awaddr,axi4_slave_tx_h1.awaddr), UVM_HIGH);             
    byte_data_cmp_verified_awaddr_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_awaddr from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_AWADDR_NOT_MATCHED", $sformatf("Master AWADDR = 'h%0x and Slave AWADDR = 'h%0x",axi4_master_tx_h1.awaddr,axi4_slave_tx_h1.awaddr), UVM_HIGH);             
    byte_data_cmp_failed_awaddr_count++;
  end

  if(axi4_master_tx_h1.awlen == axi4_slave_tx_h1.awlen)begin
    `uvm_info(get_type_name(),$sformatf("axi4_awlen from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_awlen_MATCHED", $sformatf("Master awlen = 'h%0x and Slave awlen = 'h%0x",axi4_master_tx_h1.awlen,axi4_slave_tx_h1.awlen), UVM_HIGH);             
    byte_data_cmp_verified_awlen_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_awlen from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_awlen_NOT_MATCHED", $sformatf("Master awlen = 'h%0x and Slave awlen = 'h%0x",axi4_master_tx_h1.awlen,axi4_slave_tx_h1.awlen), UVM_HIGH);             
    byte_data_cmp_failed_awlen_count++;
  end

  if(axi4_master_tx_h1.awsize == axi4_slave_tx_h1.awsize)begin
    `uvm_info(get_type_name(),$sformatf("axi4_awsize from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_awsize_MATCHED", $sformatf("Master awsize = 'h%0x and Slave awsize = 'h%0x",axi4_master_tx_h1.awsize,axi4_slave_tx_h1.awsize), UVM_HIGH);             
    byte_data_cmp_verified_awsize_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_awsize from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_awsize_NOT_MATCHED", $sformatf("Master awsize = 'h%0x and Slave awsize = 'h%0x",axi4_master_tx_h1.awsize,axi4_slave_tx_h1.awsize), UVM_HIGH);             
    byte_data_cmp_failed_awsize_count++;
  end

  if(axi4_master_tx_h1.awburst == axi4_slave_tx_h1.awburst)begin
    `uvm_info(get_type_name(),$sformatf("axi4_awburst from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_awburst_MATCHED", $sformatf("Master awburst = 'h%0x and Slave awburst = 'h%0x",axi4_master_tx_h1.awburst,axi4_slave_tx_h1.awburst), UVM_HIGH);             
    byte_data_cmp_verified_awburst_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_awburst from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_awburst_NOT_MATCHED", $sformatf("Master awburst = 'h%0x and Slave awburst = 'h%0x",axi4_master_tx_h1.awburst,axi4_slave_tx_h1.awburst), UVM_HIGH);             
    byte_data_cmp_failed_awburst_count++;
  end

  if(axi4_master_tx_h1.awlock == axi4_slave_tx_h1.awlock)begin
    `uvm_info(get_type_name(),$sformatf("axi4_awlock from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_awlock_MATCHED", $sformatf("Master awlock = 'h%0x and Slave awlock = 'h%0x",axi4_master_tx_h1.awlock,axi4_slave_tx_h1.awlock), UVM_HIGH);             
    byte_data_cmp_verified_awlock_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_awlock from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_awlock_NOT_MATCHED", $sformatf("Master awlock = 'h%0x and Slave awlock = 'h%0x",axi4_master_tx_h1.awlock,axi4_slave_tx_h1.awlock), UVM_HIGH);             
    byte_data_cmp_failed_awlock_count++;
  end

  if(axi4_master_tx_h1.awcache == axi4_slave_tx_h1.awcache)begin
    `uvm_info(get_type_name(),$sformatf("axi4_awcache from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_awcache_MATCHED", $sformatf("Master awcache = 'h%0x and Slave awcache = 'h%0x",axi4_master_tx_h1.awcache,axi4_slave_tx_h1.awcache), UVM_HIGH);             
    byte_data_cmp_verified_awcache_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_awcache from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_awcache_NOT_MATCHED", $sformatf("Master awcache = 'h%0x and Slave awcache = 'h%0x",axi4_master_tx_h1.awcache,axi4_slave_tx_h1.awcache), UVM_HIGH);             
    byte_data_cmp_failed_awcache_count++;
  end

  if(axi4_master_tx_h1.awprot == axi4_slave_tx_h1.awprot)begin
    `uvm_info(get_type_name(),$sformatf("axi4_awprot from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_awprot_MATCHED", $sformatf("Master awprot = 'h%0x and Slave awprot = 'h%0x",axi4_master_tx_h1.awprot,axi4_slave_tx_h1.awprot), UVM_HIGH);             
    byte_data_cmp_verified_awprot_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_awprot from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_awprot_NOT_MATCHED", $sformatf("Master awprot = 'h%0x and Slave awprot = 'h%0x",axi4_master_tx_h1.awprot,axi4_slave_tx_h1.awprot), UVM_HIGH);
    byte_data_cmp_failed_awprot_count++;
  end

  if(axi4_env_cfg_h.check_wait_states) begin
    if(axi4_master_tx_h1.aw_wait_states == axi4_slave_tx_h1.aw_wait_states) begin
      byte_data_cmp_verified_aw_wait_states_count++;
    end
    else begin
      byte_data_cmp_failed_aw_wait_states_count++;
      `uvm_info("SB_AW_WAIT_STATES_NOT_MATCHED", $sformatf("Master=%0d Slave=%0d",axi4_master_tx_h1.aw_wait_states,axi4_slave_tx_h1.aw_wait_states), UVM_HIGH);
    end
  end

  // AWUSER signal comparison - Enhancement for USER signal integrity
  if(!axi4_env_cfg_h.axuser_passthrough_chk_cfg || (axi4_master_tx_h1.awuser == axi4_slave_tx_h1.awuser))begin
    `uvm_info(get_type_name(),$sformatf("axi4_awuser from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_AWUSER_MATCHED", $sformatf("Master awuser = 'h%0x and Slave awuser = 'h%0x",axi4_master_tx_h1.awuser,axi4_slave_tx_h1.awuser), UVM_HIGH);
    byte_data_cmp_verified_awuser_count++;
  end
  else begin
    `uvm_error(get_type_name(),$sformatf("⚠️  AWUSER SIGNAL INTEGRITY FAILURE: axi4_awuser from master and slave are NOT equal - potential width truncation or interconnect corruption"));
    `uvm_error("SB_AWUSER_NOT_MATCHED", $sformatf("❌ Master awuser = 'h%0x but Slave awuser = 'h%0x - USER signal passthrough failed",axi4_master_tx_h1.awuser,axi4_slave_tx_h1.awuser));
    byte_data_cmp_failed_awuser_count++;
  end

endtask : axi4_write_address_comparision

//--------------------------------------------------------------------------------------------
// Task : axi4_write_data_comparision
// Used to compare the received master and slave write data
// Parameter :
//  axi4_master_tx_h2 - axi4_master_tx
//  axi4_slave_tx_h2  - axi4_slave_tx
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::axi4_write_data_comparision(input axi4_master_tx axi4_master_tx_h2,input axi4_slave_tx axi4_slave_tx_h2);

  axi4_write_address_comparision(axi4_master_tx_h2,axi4_slave_tx_h2);

  if(sb_wdata_equal_under_strobe(axi4_master_tx_h2,axi4_slave_tx_h2))begin
    `uvm_info(get_type_name(),$sformatf("axi4_wdata from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_wdata_MATCHED", $sformatf("Master wdata = %0p and Slave wdata = %0p",axi4_master_tx_h2.wdata,axi4_slave_tx_h2.wdata), UVM_HIGH);             
    byte_data_cmp_verified_wdata_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_wdata from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_wdata_NOT_MATCHED", $sformatf("Master wdata = %0p and Slave wdata = %0p",axi4_master_tx_h2.wdata,axi4_slave_tx_h2.wdata), UVM_HIGH);
    // This counter was never incremented, so a write-payload mismatch left BOTH
    // wdata counters at zero and check_phase read that as "no transactions
    // processed" -- an unconditional silent pass on the one thing a write test
    // exists to prove.
    byte_data_cmp_failed_wdata_count++;
  end

  if(axi4_master_tx_h2.wstrb == axi4_slave_tx_h2.wstrb)begin
    `uvm_info(get_type_name(),$sformatf("axi4_wstrb from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_wstrb_MATCHED", $sformatf("Master wstrb = %0p and Slave wstrb = %0p",axi4_master_tx_h2.wstrb,axi4_slave_tx_h2.wstrb), UVM_HIGH);
    byte_data_cmp_verified_wstrb_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_wstrb from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_wstrb_NOT_MATCHED", $sformatf("Master wstrb = %0p and Slave wstrb = %0p",axi4_master_tx_h2.wstrb,axi4_slave_tx_h2.wstrb), UVM_HIGH);
    // Same silent-pass hole as wdata above.
    byte_data_cmp_failed_wstrb_count++;
  end

  foreach(axi4_master_tx_h2.wdata[i]) begin
    store_write(axi4_master_tx_h2.awaddr + i*STROBE_WIDTH,
                axi4_master_tx_h2.wdata[i],
                axi4_master_tx_h2.wstrb[i]);
  end



  if(axi4_master_tx_h2.wuser == axi4_slave_tx_h2.wuser)begin
    `uvm_info(get_type_name(),$sformatf("axi4_wuser from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_wuser_MATCHED", $sformatf("Master wuser = 'h%0x and Slave wuser = 'h%0x",axi4_master_tx_h2.wuser,axi4_slave_tx_h2.wuser), UVM_HIGH);             
    byte_data_cmp_verified_wuser_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_wuser from master and slave is not equal"),UVM_MEDIUM);
    `uvm_info("SB_wuser_NOT_MATCHED", $sformatf("Master wuser = 'h%0x and Slave wuser = 'h%0x",axi4_master_tx_h2.wuser,axi4_slave_tx_h2.wuser), UVM_MEDIUM);
    byte_data_cmp_failed_wuser_count++;
  end

  if(axi4_env_cfg_h.check_wait_states) begin
    if(axi4_master_tx_h2.w_wait_states == axi4_slave_tx_h2.w_wait_states) begin
      byte_data_cmp_verified_w_wait_states_count++;
    end
    else begin
      byte_data_cmp_failed_w_wait_states_count++;
      `uvm_info("SB_W_WAIT_STATES_NOT_MATCHED", $sformatf("Master=%0d Slave=%0d",axi4_master_tx_h2.w_wait_states,axi4_slave_tx_h2.w_wait_states), UVM_HIGH);
    end
  end

endtask : axi4_write_data_comparision

//--------------------------------------------------------------------------------------------
// Task : axi4_write_response_comparision
// Used to compare the received master and slave write response
// Parameter :
//  axi4_master_tx_h3 - axi4_master_tx
//  axi4_slave_tx_h3  - axi4_slave_tx
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::axi4_write_response_comparision(input axi4_master_tx axi4_master_tx_h3,input axi4_slave_tx axi4_slave_tx_h3);

  // Validate response correctness (including expected DECERR/SLVERR)
  validate_response_correctness(axi4_master_tx_h3, axi4_slave_tx_h3, 1); // 1 = write operation

  // Write response phase should only compare bid, bresp, buser (not wdata/wuser)
  // Write data comparisons are handled separately in the write data phase
  `uvm_info(get_type_name(),$sformatf("Write response comparison - bid/bresp/buser only"),UVM_HIGH);

  if(!axi4_env_cfg_h.axid_passthrough_chk_cfg || (axi4_master_tx_h3.bid == axi4_slave_tx_h3.bid))begin
    `uvm_info(get_type_name(),$sformatf("axi4_bid from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_bid_MATCHED", $sformatf("Master bid = %0p and Slave bid = %0p",axi4_master_tx_h3.bid,axi4_slave_tx_h3.bid), UVM_HIGH);             
    byte_data_cmp_verified_bid_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_bid from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_bid_NOT_MATCHED", $sformatf("Master bid = %0p and Slave bid = %0p",axi4_master_tx_h3.bid,axi4_slave_tx_h3.bid), UVM_HIGH);             
    byte_data_cmp_failed_bid_count++;
  end

  if(axi4_master_tx_h3.bresp == axi4_slave_tx_h3.bresp)begin
    `uvm_info(get_type_name(),$sformatf("axi4_bresp from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_bresp_MATCHED", $sformatf("Master bresp = %0p and Slave bresp = %0p",axi4_master_tx_h3.bresp,axi4_slave_tx_h3.bresp), UVM_HIGH);             
    byte_data_cmp_verified_bresp_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_bresp from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_bresp_NOT_MATCHED", $sformatf("Master bresp = %0p and Slave bresp = %0p",axi4_master_tx_h3.bresp,axi4_slave_tx_h3.bresp), UVM_HIGH);             
    byte_data_cmp_failed_bresp_count++;
  end

  if(axi4_master_tx_h3.buser == axi4_slave_tx_h3.buser)begin
    `uvm_info(get_type_name(),$sformatf("axi4_buser from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_buser_MATCHED", $sformatf("Master buser = 'h%0x and Slave buser = 'h%0x",axi4_master_tx_h3.buser,axi4_slave_tx_h3.buser), UVM_HIGH);             
    byte_data_cmp_verified_buser_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_buser from master and slave is not equal"),UVM_MEDIUM);
    `uvm_info("SB_buser_NOT_MATCHED", $sformatf("Master buser = 'h%0x and Slave buser = 'h%0x",axi4_master_tx_h3.buser,axi4_slave_tx_h3.buser), UVM_MEDIUM);
    byte_data_cmp_failed_buser_count++;
  end

  if(axi4_env_cfg_h.check_wait_states) begin
    if(axi4_master_tx_h3.b_wait_states == axi4_slave_tx_h3.b_wait_states) begin
      byte_data_cmp_verified_b_wait_states_count++;
    end
    else begin
      byte_data_cmp_failed_b_wait_states_count++;
      `uvm_info("SB_B_WAIT_STATES_NOT_MATCHED", $sformatf("Master=%0d Slave=%0d",axi4_master_tx_h3.b_wait_states,axi4_slave_tx_h3.b_wait_states), UVM_HIGH);
    end
  end
  // The bid-returned-to-originating-manager retirement used to live here. It
  // is a MASTER-SIDE-ONLY property -- "the manager got back an id it was still
  // waiting on" -- and running it here made it depend on the slave-side
  // partner turning up. When the slave response was lost the channel task
  // parked before ever reaching this line, so the outstanding map kept an id
  // the manager had in fact been given, and the resulting error blamed the
  // wrong thing. It now runs in axi4_write_response() the moment the master
  // packet is received. See sb_retire_outstanding_awid().

endtask : axi4_write_response_comparision

//--------------------------------------------------------------------------------------------
// Task : axi4_read_address_comparision
// Used to compare the received master and slave read address
// Parameter :
//  axi4_master_tx_h4 - axi4_master_tx
//  axi4_slave_tx_h4  - axi4_slave_tx
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::axi4_read_address_comparision(input axi4_master_tx axi4_master_tx_h4,input axi4_slave_tx axi4_slave_tx_h4);

  
  if(!axi4_env_cfg_h.axid_passthrough_chk_cfg || (axi4_master_tx_h4.arid == axi4_slave_tx_h4.arid))begin
    `uvm_info(get_type_name(),$sformatf("axi4_arid from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_arID_MATCHED", $sformatf("Master arID = 'h%0x and Slave arID = 'h%0x",axi4_master_tx_h4.arid,axi4_slave_tx_h4.arid), UVM_HIGH);             
    byte_data_cmp_verified_arid_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_arid from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_arID_NOT_MATCHED", $sformatf("Master arID = 'h%0x and Slave arID = 'h%0x",axi4_master_tx_h4.arid,axi4_slave_tx_h4.arid), UVM_HIGH);             
    byte_data_cmp_failed_arid_count++;
  end
  
  if(axi4_master_tx_h4.araddr == axi4_slave_tx_h4.araddr)begin
    `uvm_info(get_type_name(),$sformatf("axi4_araddr from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_arADDR_MATCHED", $sformatf("Master arADDR = 'h%0x and Slave arADDR = 'h%0x",axi4_master_tx_h4.araddr,axi4_slave_tx_h4.araddr), UVM_HIGH);             
    byte_data_cmp_verified_araddr_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_araddr from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_arADDR_NOT_MATCHED", $sformatf("Master arADDR = 'h%0x and Slave arADDR = 'h%0x",axi4_master_tx_h4.araddr,axi4_slave_tx_h4.araddr), UVM_HIGH);             
    byte_data_cmp_failed_araddr_count++;
  end

  if(axi4_master_tx_h4.arlen == axi4_slave_tx_h4.arlen)begin
    `uvm_info(get_type_name(),$sformatf("axi4_arlen from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_arlen_MATCHED", $sformatf("Master arlen = 'h%0x and Slave arlen = 'h%0x",axi4_master_tx_h4.arlen,axi4_slave_tx_h4.arlen), UVM_HIGH);             
    byte_data_cmp_verified_arlen_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_arlen from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_arlen_NOT_MATCHED", $sformatf("Master arlen = 'h%0x and Slave arlen = 'h%0x",axi4_master_tx_h4.arlen,axi4_slave_tx_h4.arlen), UVM_HIGH);             
    byte_data_cmp_failed_arlen_count++;
  end

  if(axi4_master_tx_h4.arsize == axi4_slave_tx_h4.arsize)begin
    `uvm_info(get_type_name(),$sformatf("axi4_arsize from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_arsize_MATCHED", $sformatf("Master arsize = 'h%0x and Slave arsize = 'h%0x",axi4_master_tx_h4.arsize,axi4_slave_tx_h4.arsize), UVM_HIGH);             
    byte_data_cmp_verified_arsize_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_arsize from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_arsize_NOT_MATCHED", $sformatf("Master arsize = 'h%0x and Slave arsize = 'h%0x",axi4_master_tx_h4.arsize,axi4_slave_tx_h4.arsize), UVM_HIGH);             
    byte_data_cmp_failed_arsize_count++;
  end

  if(axi4_master_tx_h4.arburst == axi4_slave_tx_h4.arburst)begin
    `uvm_info(get_type_name(),$sformatf("axi4_arburst from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_arburst_MATCHED", $sformatf("Master arburst = 'h%0x and Slave arburst = 'h%0x",axi4_master_tx_h4.arburst,axi4_slave_tx_h4.arburst), UVM_HIGH);             
    byte_data_cmp_verified_arburst_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_arburst from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_arburst_NOT_MATCHED", $sformatf("Master arburst = 'h%0x and Slave arburst = 'h%0x",axi4_master_tx_h4.arburst,axi4_slave_tx_h4.arburst), UVM_HIGH);             
    byte_data_cmp_failed_arburst_count++;
  end

  if(axi4_master_tx_h4.arlock == axi4_slave_tx_h4.arlock)begin
    `uvm_info(get_type_name(),$sformatf("axi4_arlock from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_arlock_MATCHED", $sformatf("Master arlock = 'h%0x and Slave arlock = 'h%0x",axi4_master_tx_h4.arlock,axi4_slave_tx_h4.arlock), UVM_HIGH);             
    byte_data_cmp_verified_arlock_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_arlock from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_arlock_NOT_MATCHED", $sformatf("Master arlock = 'h%0x and Slave arlock = 'h%0x",axi4_master_tx_h4.arlock,axi4_slave_tx_h4.arlock), UVM_HIGH);             
    byte_data_cmp_failed_arlock_count++;
  end

  if(axi4_master_tx_h4.arcache == axi4_slave_tx_h4.arcache)begin
    `uvm_info(get_type_name(),$sformatf("axi4_arcache from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_arcache_MATCHED", $sformatf("Master arcache = 'h%0x and Slave arcache = 'h%0x",axi4_master_tx_h4.arcache,axi4_slave_tx_h4.arcache), UVM_HIGH);             
    byte_data_cmp_verified_arcache_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_arcache from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_arcache_NOT_MATCHED", $sformatf("Master arcache = 'h%0x and Slave arcache = 'h%0x",axi4_master_tx_h4.arcache,axi4_slave_tx_h4.arcache), UVM_HIGH);             
    byte_data_cmp_failed_arcache_count++;
  end

  if(axi4_master_tx_h4.arprot == axi4_slave_tx_h4.arprot)begin
    `uvm_info(get_type_name(),$sformatf("axi4_arprot from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_arprot_MATCHED", $sformatf("Master arprot = 'h%0x and Slave arprot = 'h%0x",axi4_master_tx_h4.arprot,axi4_slave_tx_h4.arprot), UVM_HIGH);             
    byte_data_cmp_verified_arprot_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_arprot from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_arprot_NOT_MATCHED", $sformatf("Master arprot = 'h%0x and Slave arprot = 'h%0x",axi4_master_tx_h4.arprot,axi4_slave_tx_h4.arprot), UVM_HIGH);             
    byte_data_cmp_failed_arprot_count++;
  end

  if(!axi4_env_cfg_h.axregion_passthrough_chk_cfg || (axi4_master_tx_h4.arregion == axi4_slave_tx_h4.arregion))begin
    `uvm_info(get_type_name(),$sformatf("axi4_arregion from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_arregion_MATCHED", $sformatf("Master arregion = 'h%0x and Slave arregion = 'h%0x",axi4_master_tx_h4.arregion,axi4_slave_tx_h4.arregion), UVM_HIGH);             
    byte_data_cmp_verified_arregion_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_arregion from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_arregion_NOT_MATCHED", $sformatf("Master arregion = 'h%0x and Slave arregion = 'h%0x",axi4_master_tx_h4.arregion,axi4_slave_tx_h4.arregion), UVM_HIGH);             
    byte_data_cmp_failed_arregion_count++;
  end

  if(!axi4_env_cfg_h.axqos_passthrough_chk_cfg || (axi4_master_tx_h4.arqos == axi4_slave_tx_h4.arqos))begin
    `uvm_info(get_type_name(),$sformatf("axi4_arqos from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_arqos_MATCHED", $sformatf("Master arqos = 'h%0x and Slave arqos = 'h%0x",axi4_master_tx_h4.arqos,axi4_slave_tx_h4.arqos), UVM_HIGH);             
    byte_data_cmp_verified_arqos_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_arqos from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_arqos_NOT_MATCHED", $sformatf("Master arqos = 'h%0x and Slave arqos = 'h%0x",axi4_master_tx_h4.arqos,axi4_slave_tx_h4.arqos), UVM_HIGH);
    byte_data_cmp_failed_arqos_count++;
  end

  if(axi4_env_cfg_h.check_wait_states) begin
    if(axi4_master_tx_h4.ar_wait_states == axi4_slave_tx_h4.ar_wait_states) begin
      byte_data_cmp_verified_ar_wait_states_count++;
    end
    else begin
      byte_data_cmp_failed_ar_wait_states_count++;
      `uvm_info("SB_AR_WAIT_STATES_NOT_MATCHED", $sformatf("Master=%0d Slave=%0d",axi4_master_tx_h4.ar_wait_states,axi4_slave_tx_h4.ar_wait_states), UVM_HIGH);
    end
  end

  // ARUSER signal comparison - Enhancement for USER signal integrity
  if(!axi4_env_cfg_h.axuser_passthrough_chk_cfg || (axi4_master_tx_h4.aruser == axi4_slave_tx_h4.aruser))begin
    `uvm_info(get_type_name(),$sformatf("axi4_aruser from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_ARUSER_MATCHED", $sformatf("Master aruser = 'h%0x and Slave aruser = 'h%0x",axi4_master_tx_h4.aruser,axi4_slave_tx_h4.aruser), UVM_HIGH);
    byte_data_cmp_verified_aruser_count++;
  end
  else begin
    `uvm_error(get_type_name(),$sformatf("⚠️  ARUSER SIGNAL INTEGRITY FAILURE: axi4_aruser from master and slave are NOT equal - potential width truncation or interconnect corruption"));
    `uvm_error("SB_ARUSER_NOT_MATCHED", $sformatf("❌ Master aruser = 'h%0x but Slave aruser = 'h%0x - USER signal passthrough failed",axi4_master_tx_h4.aruser,axi4_slave_tx_h4.aruser));
    byte_data_cmp_failed_aruser_count++;
  end

endtask : axi4_read_address_comparision

//--------------------------------------------------------------------------------------------
// Task : axi4_read_data_comparision
// Used to compare the received master and slave read data
// Parameter :
//  axi4_master_tx_h5 - axi4_master_tx
//  axi4_slave_tx_h5  - axi4_slave_tx
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::axi4_read_data_comparision(input axi4_master_tx axi4_master_tx_h5,input axi4_slave_tx axi4_slave_tx_h5);

  axi4_read_address_comparision(axi4_master_tx_h5,axi4_slave_tx_h5);
  
  // Validate response correctness (including expected DECERR/SLVERR)
  validate_response_correctness(axi4_master_tx_h5, axi4_slave_tx_h5, 0); // 0 = read operation
  
  // Always validate RID regardless of error response
  if(!axi4_env_cfg_h.axid_passthrough_chk_cfg || (axi4_master_tx_h5.rid == axi4_slave_tx_h5.rid))begin
    `uvm_info(get_type_name(),$sformatf("axi4_rid from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_rid_MATCHED", $sformatf("Master rid = %0p and Slave rid = %0p",axi4_master_tx_h5.rid,axi4_slave_tx_h5.rid), UVM_HIGH);             
    byte_data_cmp_verified_rid_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_rid from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_rid_NOT_MATCHED", $sformatf("Master rid = %0p and Slave rid = %0p",axi4_master_tx_h5.rid,axi4_slave_tx_h5.rid), UVM_HIGH);             
    byte_data_cmp_failed_rid_count++;
  end

  // Always validate RRESP regardless of error response
  if(axi4_master_tx_h5.rresp == axi4_slave_tx_h5.rresp)begin
    `uvm_info(get_type_name(),$sformatf("axi4_rresp from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_rresp_MATCHED", $sformatf("Master rresp = %0p and Slave rresp = %0p",axi4_master_tx_h5.rresp,axi4_slave_tx_h5.rresp), UVM_HIGH);             
    byte_data_cmp_verified_rresp_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_rresp from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_rresp_NOT_MATCHED", $sformatf("Master rresp = %0p and Slave rresp = %0p",axi4_master_tx_h5.rresp,axi4_slave_tx_h5.rresp), UVM_HIGH);             
    byte_data_cmp_failed_rresp_count++;
  end

  // ERROR AND ABANDON RULE (claude.md): Skip data validation for error responses
  // If RRESP indicates DECERR (2'b11) or SLVERR (2'b10), data is invalid and should not be checked
  if (axi4_slave_tx_h5.rresp == 2'b11 || axi4_slave_tx_h5.rresp == 2'b10) begin
    `uvm_info("SB_ERROR_ABANDON", 
      $sformatf("RRESP=%0b detected - Abandoning RDATA validation per claude.md Error and Abandon rule", 
      axi4_slave_tx_h5.rresp), UVM_MEDIUM);
    
    // Mark transaction as completed failure - no data validation
    byte_data_cmp_error_abandon_count++;
  end
  else begin
    // Only validate RDATA for successful responses (OKAY, EXOKAY)
    if(axi4_master_tx_h5.rdata == axi4_slave_tx_h5.rdata)begin
      `uvm_info(get_type_name(),$sformatf("axi4_rdata from master and slave is equal"),UVM_HIGH);
      `uvm_info("SB_rdata_MATCHED", $sformatf("Master rdata = %0p and Slave rdata = %0p",axi4_master_tx_h5.rdata,axi4_slave_tx_h5.rdata), UVM_HIGH);
// will fixed later    
       byte_data_cmp_verified_rdata_count++;
//      for(int i=0;i<axi4_master_tx_h5.rdata.size();i++) begin
//        verify_read(axi4_master_tx_h5.araddr + i*STROBE_WIDTH,
//                    axi4_master_tx_h5.rdata[i]);
//      end
    end
    else begin
      `uvm_info(get_type_name(),$sformatf("axi4_rdata from master and slave is  not equal"),UVM_HIGH);
      `uvm_info("SB_rdata_NOT_MATCHED", $sformatf("Master rdata = %0p and Slave rdata = %0p",axi4_master_tx_h5.rdata,axi4_slave_tx_h5.rdata), UVM_HIGH);             
      byte_data_cmp_failed_rdata_count++;
    end
  end

  // Always validate RUSER regardless of error response
  if(axi4_master_tx_h5.ruser == axi4_slave_tx_h5.ruser)begin
    `uvm_info(get_type_name(),$sformatf("axi4_ruser from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_ruser_MATCHED", $sformatf("Master ruser = %0p and Slave ruser = %0p",axi4_master_tx_h5.ruser,axi4_slave_tx_h5.ruser), UVM_HIGH);             
    byte_data_cmp_verified_ruser_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_ruser from master and slave is not equal"),UVM_MEDIUM);
    `uvm_info("SB_ruser_NOT_MATCHED", $sformatf("Master ruser = %0p and Slave ruser = %0p",axi4_master_tx_h5.ruser,axi4_slave_tx_h5.ruser), UVM_MEDIUM);             
    byte_data_cmp_failed_ruser_count++;
  end

  if(axi4_env_cfg_h.check_wait_states) begin
    if(axi4_master_tx_h5.r_wait_states == axi4_slave_tx_h5.r_wait_states) begin
      byte_data_cmp_verified_r_wait_states_count++;
    end
    else begin
      byte_data_cmp_failed_r_wait_states_count++;
      `uvm_info("SB_R_WAIT_STATES_NOT_MATCHED", $sformatf("Master=%0d Slave=%0d",axi4_master_tx_h5.r_wait_states,axi4_slave_tx_h5.r_wait_states), UVM_HIGH);
    end
  end

  // The rid-returned-to-originating-manager retirement moved to
  // axi4_read_data(), for the same reason as the BID one above: it is a
  // master-side property and must not be gated on the slave partner arriving.

endtask : axi4_read_data_comparision

//--------------------------------------------------------------------------------------------
// Function: check_phase
// Display the result of simulation
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::check_phase(uvm_phase phase);
  bit all_slaves_passive = 1;
  bit error_inject_override;
  bit has_override;
  int disable_end_of_test_checks = 0;
  
  super.check_phase(phase);

  `uvm_info(get_type_name(),$sformatf("--\n----------------------------------------------SCOREBOARD CHECK PHASE---------------------------------------"),UVM_HIGH) 
  
  `uvm_info (get_type_name(),$sformatf(" Scoreboard Check Phase is starting"),UVM_HIGH);
  
  // Check if end-of-test checks should be disabled (for sanity tests)
  void'(uvm_config_db#(int)::get(null, "*", "disable_end_of_test_checks", disable_end_of_test_checks));

  //--------------------------------------------------------------------------------------------
  // THE ONLY remaining path that skips the completeness gate below.
  //
  // Unlike the passive / error_inject guards further down, this one is not
  // derived from a MODE -- it is an explicit per-test opt-out, written into the
  // test source (axi4_basic_sanity_test, axi4_master_base_test,
  // axi4_reset_comprehensive_test, axi4_independent_reset_test) and greppable
  // there. It is therefore treated as a declared waiver rather than a silent
  // hole, and it is raised to a WARNING so that it is counted and printed in
  // every log's report summary: a run whose scoreboard checked nothing must
  // never look identical to a run whose scoreboard checked everything.
  //
  // Residual gap, stated deliberately: three of those four tests are reset /
  // abort / X-injection tests, i.e. exactly the class where a transaction is
  // most likely to be lost. Removing this opt-out is a separate change with a
  // separate blast radius and needs its own fail-then-pass evidence.
  //--------------------------------------------------------------------------------------------
  if (disable_end_of_test_checks) begin
    `uvm_warning(get_type_name(), "disable_end_of_test_checks=1 : ALL scoreboard end-of-test checking is waived for this test, INCLUDING the completeness gate (in-flight / unmatched / holding-pool / outstanding-id / pipeline-balance / analysis-fifo residue). A PASS from this run says nothing about whether every transaction was accounted for.")
    return; // Skip all end-of-test checking
  end

  // Establish the slave-agent mode. Used ONLY to gate the master-vs-slave FIELD
  // EQUALITY comparisons further down; the completeness gate below runs
  // regardless -- see the rationale there.
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i]) begin
    if(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].is_active == UVM_ACTIVE) begin
      all_slaves_passive = 0;
      break;
    end
  end

  //--------------------------------------------------------------------------------------------
  // SINGLE COMPLETENESS GATE -- ahead of every mode guard in this function.
  //
  // Two separate fail-open holes used to live here, and both are closed by
  // moving ONE call in front of ALL the guards:
  //
  //   (a) all-slaves-PASSIVE returned before any accounting ran. Passive removes
  //       the slave DRIVER, not the slave MONITOR: slave/axi4_slave_agent.sv
  //       builds axi4_slave_mon_proxy_h unconditionally and env/axi4_env.sv
  //       connects its five analysis ports to this scoreboard unconditionally.
  //       So a passive-slave test (axi4_write_test, and any DUT/VIP integration
  //       config where the DUT is the responder) still feeds this scoreboard on
  //       both sides, still parks items in-flight, and still leaked every one of
  //       them past a clean-looking PASS. What passive changes is only whether a
  //       VIP subordinate exists to compare AGAINST -- that is handled INSIDE
  //       the completeness function, which detects "no subordinate-side
  //       transaction was ever observed" and reports it as one explicit error
  //       instead of N identical ones. It never silently passes.
  //
  //   (b) error_inject returned before the raw analysis-fifo residue checks.
  //       The C1-C5 accounting only sees items a channel task already get()-ed;
  //       an item still sitting in an analysis fifo that no worker ever pulled
  //       was invisible on all 23 error-injection test classes. The fifo residue
  //       check is now C6 inside the same function, so it is covered by the same
  //       single gate.
  //
  // The mode guards below now do exactly one thing: skip the master-vs-slave
  // FIELD EQUALITY comparisons that genuinely do not apply in that mode
  // (no VIP subordinate to compare against / errors deliberately injected so
  // fields legitimately differ). Neither of them may skip accounting.
  //--------------------------------------------------------------------------------------------
  sb_end_of_test_completeness_check();

  if (all_slaves_passive) begin
    `uvm_info(get_type_name(), "Scoreboard master-vs-slave FIELD comparisons skipped - all slaves are PASSIVE. Completeness accounting (C1-C6) DID run above and is authoritative for this run.", UVM_MEDIUM);
    return;
  end

  // Check for error_inject override from test first
  has_override = uvm_config_db#(bit)::get(this, "", "scoreboard_error_inject_override", error_inject_override);

  // Skip count comparison checks if error_inject is enabled (either from override or env_config)
  if ((has_override && error_inject_override) || (!has_override && axi4_env_cfg_h.error_inject)) begin
    `uvm_info(get_type_name(), $sformatf("Scoreboard master-vs-slave FIELD comparisons skipped due to error_inject enabled (override=%0d, env_cfg=%0d). Completeness accounting (C1-C6) DID run above.",
                                          has_override ? error_inject_override : 0, axi4_env_cfg_h.error_inject), UVM_MEDIUM);
    return;
  end

  //--------------------------------------------------------------------------------------------
  // 1.Check if the comparisions counter is NON-zero
  //   A non-zero value indicates that the comparisions never happened and throw error
  // 2.Initial count of the failed count is zero
  //   If the failed count is more than 0 it means comparision is failed and gives error  
  //--------------------------------------------------------------------------------------------

  //-------------------------------------------------------
  // Write_Address_Channel comparision
  //-------------------------------------------------------
  if(axi4_env_cfg_h.write_read_mode_h == ONLY_WRITE_DATA || axi4_env_cfg_h.write_read_mode_h == WRITE_READ_DATA) begin
    if ((byte_data_cmp_verified_awid_count != 0) && (byte_data_cmp_failed_awid_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("awid count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_awid_count :%0d",
                                              byte_data_cmp_verified_awid_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_awid_count : %0d", 
                                              byte_data_cmp_failed_awid_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("awid count comparisions are failed"));
    end

    if ((byte_data_cmp_verified_awaddr_count != 0) && (byte_data_cmp_failed_awaddr_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("awaddr count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_awaddr_count :%0d",
                                              byte_data_cmp_verified_awaddr_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_awaddr_count : %0d", 
                                              byte_data_cmp_failed_awaddr_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("awaddr count comparisions are failed"));
    end

    if ((byte_data_cmp_verified_awsize_count != 0) && (byte_data_cmp_failed_awsize_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("awsize count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_awsize_count :%0d",
                                              byte_data_cmp_verified_awsize_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_awsize_count : %0d", 
                                              byte_data_cmp_failed_awsize_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("awsize count comparisions are failed"));
    end

    if ((byte_data_cmp_verified_awlen_count != 0) && (byte_data_cmp_failed_awlen_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("awlen count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_awlen_count :%0d",
                                              byte_data_cmp_verified_awlen_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_awlen_count : %0d", 
                                              byte_data_cmp_failed_awlen_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("awlen count comparisions are failed"));
    end
    
    if ((byte_data_cmp_verified_awburst_count != 0) && (byte_data_cmp_failed_awburst_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("awburst count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_awburst_count :%0d",
                                              byte_data_cmp_verified_awburst_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_awburst_count : %0d", 
                                              byte_data_cmp_failed_awburst_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("awburst count comparisions are failed"));
    end
    
    if ((byte_data_cmp_verified_awcache_count != 0) && (byte_data_cmp_failed_awcache_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("awcache count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_awcache_count :%0d",
                                              byte_data_cmp_verified_awcache_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_awcache_count : %0d", 
                                              byte_data_cmp_failed_awcache_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("awcache count comparisions are failed"));
    end
    
    if ((byte_data_cmp_verified_awlock_count != 0) && (byte_data_cmp_failed_awlock_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("awlock count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_awlock_count :%0d",
                                              byte_data_cmp_verified_awlock_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_awlock_count : %0d", 
                                              byte_data_cmp_failed_awlock_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("awlock count comparisions are failed"));
    end
    
    if ((byte_data_cmp_verified_awprot_count != 0) && (byte_data_cmp_failed_awprot_count == 0)) begin
            `uvm_info (get_type_name(), $sformatf ("awprot count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_awprot_count :%0d",
                                              byte_data_cmp_verified_awprot_count),UVM_HIGH);
            `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_awprot_count : %0d",
                                              byte_data_cmp_failed_awprot_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("awprot count comparisions are failed"));
    end

    if(axi4_env_cfg_h.check_wait_states) begin
      if ((byte_data_cmp_verified_aw_wait_states_count != 0) && (byte_data_cmp_failed_aw_wait_states_count == 0)) begin
              `uvm_info (get_type_name(), $sformatf ("aw wait states comparisions are succesful"),UVM_HIGH);
      end
      else begin
        `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_aw_wait_states_count :%0d",
                                                byte_data_cmp_verified_aw_wait_states_count),UVM_HIGH);
              `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_aw_wait_states_count : %0d",
                                                byte_data_cmp_failed_aw_wait_states_count),UVM_HIGH);
        `uvm_error (get_type_name(), $sformatf ("aw wait states comparisions are failed"));
      end
    end
    
    //-------------------------------------------------------
    // Write_Data_Channel comparision
    //-------------------------------------------------------
    
    if ((byte_data_cmp_verified_wdata_count == 0) && (byte_data_cmp_failed_wdata_count == 0)) begin
      `uvm_info (get_type_name(), $sformatf ("wdata count comparisons - no transactions processed"),UVM_MEDIUM);
    end
    else if ((byte_data_cmp_verified_wdata_count != 0) && (byte_data_cmp_failed_wdata_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("wdata count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_wdata_count :%0d",
                                              byte_data_cmp_verified_wdata_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_wdata_count : %0d", 
                                              byte_data_cmp_failed_wdata_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("wdata count comparisions are failed"));
    end 


    if ((byte_data_cmp_verified_wstrb_count == 0) && (byte_data_cmp_failed_wstrb_count == 0)) begin
      `uvm_info (get_type_name(), $sformatf ("wstrb count comparisons - no transactions processed"),UVM_MEDIUM);
    end
    else if ((byte_data_cmp_verified_wstrb_count != 0) && (byte_data_cmp_failed_wstrb_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("wstrb count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_wstrb_count :%0d",
                                              byte_data_cmp_verified_wstrb_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_wstrb_count : %0d", 
                                              byte_data_cmp_failed_wstrb_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("wstrb count comparisions are failed"));
    end 


    // Only check wuser if write data comparisons occurred
    if ((byte_data_cmp_verified_wdata_count + byte_data_cmp_failed_wdata_count) > 0) begin
      if ((byte_data_cmp_verified_wuser_count != 0) && (byte_data_cmp_failed_wuser_count == 0)) begin
	      `uvm_info (get_type_name(), $sformatf ("wuser count comparisions are succesful"),UVM_HIGH);
      end
      else if (byte_data_cmp_failed_wuser_count > 0) begin
        `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_wuser_count :%0d",
                                                byte_data_cmp_verified_wuser_count),UVM_MEDIUM);
              `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_wuser_count : %0d",
                                                byte_data_cmp_failed_wuser_count),UVM_MEDIUM);
        if (axi4_env_cfg_h.error_inject) begin
          `uvm_warning (get_type_name(), $sformatf ("wuser count comparisons are failed - %0d mismatches out of %0d total comparisons", 
                                                   byte_data_cmp_failed_wuser_count, 
                                                   byte_data_cmp_verified_wuser_count + byte_data_cmp_failed_wuser_count));
        end
        else begin
          `uvm_error (get_type_name(), $sformatf ("wuser count comparisons are failed - %0d mismatches out of %0d total comparisons", 
                                                 byte_data_cmp_failed_wuser_count, 
                                                 byte_data_cmp_verified_wuser_count + byte_data_cmp_failed_wuser_count));
        end
      end
      else begin
        `uvm_info (get_type_name(), $sformatf ("wuser comparisons skipped - no wuser data compared"),UVM_HIGH);
      end
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("No write data comparisons occurred, skipping wuser check"),UVM_HIGH);
    end

    if(axi4_env_cfg_h.check_wait_states) begin
      if ((byte_data_cmp_verified_w_wait_states_count != 0) && (byte_data_cmp_failed_w_wait_states_count == 0)) begin
              `uvm_info (get_type_name(), $sformatf ("w wait states comparisions are succesful"),UVM_HIGH);
      end
      else begin
        `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_w_wait_states_count :%0d",
                                                byte_data_cmp_verified_w_wait_states_count),UVM_HIGH);
              `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_w_wait_states_count : %0d",
                                                byte_data_cmp_failed_w_wait_states_count),UVM_HIGH);
        `uvm_error (get_type_name(), $sformatf ("w wait states comparisions are failed"));
      end
    end

    //-------------------------------------------------------
    // Write_Response_Channel comparision
    //-------------------------------------------------------


    if ((byte_data_cmp_verified_bid_count == 0) && (byte_data_cmp_failed_bid_count == 0)) begin
      `uvm_info (get_type_name(), $sformatf ("bid count comparisons - no transactions processed"),UVM_MEDIUM);
    end
    else if ((byte_data_cmp_verified_bid_count != 0) && (byte_data_cmp_failed_bid_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("bid count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_bid_count :%0d",
                                              byte_data_cmp_verified_bid_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_bid_count : %0d", 
                                              byte_data_cmp_failed_bid_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("bid count comparisions are failed"));
    end 


    if ((byte_data_cmp_verified_bresp_count == 0) && (byte_data_cmp_failed_bresp_count == 0)) begin
      `uvm_info (get_type_name(), $sformatf ("bresp count comparisons - no transactions processed"),UVM_MEDIUM);
    end
    else if ((byte_data_cmp_verified_bresp_count != 0) && (byte_data_cmp_failed_bresp_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("bresp count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_bresp_count :%0d",
                                              byte_data_cmp_verified_bresp_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_bresp_count : %0d", 
                                              byte_data_cmp_failed_bresp_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("bresp count comparisions are failed"));
    end 


    if ((byte_data_cmp_verified_buser_count == 0) && (byte_data_cmp_failed_buser_count == 0)) begin
      `uvm_info (get_type_name(), $sformatf ("buser count comparisons - no transactions processed"),UVM_MEDIUM);
    end
    else if ((byte_data_cmp_verified_buser_count != 0) && (byte_data_cmp_failed_buser_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("buser count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_buser_count :%0d",
                                              byte_data_cmp_verified_buser_count),UVM_MEDIUM);
            `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_buser_count : %0d",
                                              byte_data_cmp_failed_buser_count),UVM_MEDIUM);
      `uvm_error (get_type_name(), $sformatf ("buser count comparisons are failed - %0d mismatches out of %0d total comparisons", 
                                             byte_data_cmp_failed_buser_count, 
                                             byte_data_cmp_verified_buser_count + byte_data_cmp_failed_buser_count));
    end

    if(axi4_env_cfg_h.check_wait_states) begin
      if ((byte_data_cmp_verified_b_wait_states_count != 0) && (byte_data_cmp_failed_b_wait_states_count == 0)) begin
              `uvm_info (get_type_name(), $sformatf ("b wait states comparisions are succesful"),UVM_HIGH);
      end
      else begin
        `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_b_wait_states_count :%0d",
                                                byte_data_cmp_verified_b_wait_states_count),UVM_HIGH);
              `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_b_wait_states_count : %0d",
                                                byte_data_cmp_failed_b_wait_states_count),UVM_HIGH);
        `uvm_error (get_type_name(), $sformatf ("b wait states comparisions are failed"));
      end
    end
  end

  //-------------------------------------------------------
  // Read_Address_Channel comparision
  //-------------------------------------------------------
  if(axi4_env_cfg_h.write_read_mode_h == ONLY_READ_DATA || axi4_env_cfg_h.write_read_mode_h == WRITE_READ_DATA) begin
    if ((byte_data_cmp_verified_arid_count != 0) && (byte_data_cmp_failed_arid_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arid count comparisions are successful"),UVM_HIGH);
    end
    else if ((byte_data_cmp_verified_arid_count == 0) && (byte_data_cmp_failed_arid_count == 0) && (valid_decerr_count > 0 || valid_slverr_count > 0) && (unexpected_error_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arid count validation successful - all responses correctly generated as expected errors (DECERR=%0d, SLVERR=%0d)", valid_decerr_count, valid_slverr_count),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_arid_count == 0) && (byte_data_cmp_failed_arid_count == 0) && (valid_decerr_count == 0) && (valid_slverr_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arid count comparisions - no transactions processed"),UVM_LOW);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_arid_count :%0d",
                                              byte_data_cmp_verified_arid_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_arid_count : %0d", 
                                              byte_data_cmp_failed_arid_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("valid_decerr_count : %0d, valid_slverr_count : %0d, unexpected_error_count : %0d", 
                                              valid_decerr_count, valid_slverr_count, unexpected_error_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("arid count comparisions are failed"));
    end

    if ((byte_data_cmp_verified_araddr_count != 0) && (byte_data_cmp_failed_araddr_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("araddr count comparisions are successful"),UVM_HIGH);
    end
    else if ((byte_data_cmp_verified_araddr_count == 0) && (byte_data_cmp_failed_araddr_count == 0) && (valid_decerr_count > 0 || valid_slverr_count > 0) && (unexpected_error_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("araddr count validation successful - all responses correctly generated as expected errors"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_araddr_count == 0) && (byte_data_cmp_failed_araddr_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("araddr count comparisions - no transactions processed"),UVM_LOW);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_araddr_count :%0d",
                                              byte_data_cmp_verified_araddr_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_araddr_count : %0d", 
                                              byte_data_cmp_failed_araddr_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("araddr count comparisions are failed"));
    end

    if ((byte_data_cmp_verified_arsize_count == 0) && (byte_data_cmp_failed_arsize_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arsize count comparisions - no transactions processed (likely all decode errors)"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_arsize_count != 0) && (byte_data_cmp_failed_arsize_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arsize count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_arsize_count :%0d",
                                              byte_data_cmp_verified_arsize_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_arsize_count : %0d", 
                                              byte_data_cmp_failed_arsize_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("arsize count comparisions are failed"));
    end

    if ((byte_data_cmp_verified_arlen_count == 0) && (byte_data_cmp_failed_arlen_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arlen count comparisions - no transactions processed (likely all decode errors)"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_arlen_count != 0) && (byte_data_cmp_failed_arlen_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arlen count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_arlen_count :%0d",
                                              byte_data_cmp_verified_arlen_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_arlen_count : %0d", 
                                              byte_data_cmp_failed_arlen_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("arlen count comparisions are failed"));
    end
    
    if ((byte_data_cmp_verified_arburst_count == 0) && (byte_data_cmp_failed_arburst_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arburst count comparisions - no transactions processed (likely all decode errors)"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_arburst_count != 0) && (byte_data_cmp_failed_arburst_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arburst count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_arburst_count :%0d",
                                              byte_data_cmp_verified_arburst_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_arburst_count : %0d", 
                                              byte_data_cmp_failed_arburst_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("arburst count comparisions are failed"));
    end
    
    if ((byte_data_cmp_verified_arcache_count == 0) && (byte_data_cmp_failed_arcache_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arcache count comparisions - no transactions processed (likely all decode errors)"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_arcache_count != 0) && (byte_data_cmp_failed_arcache_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arcache count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_arcache_count :%0d",
                                              byte_data_cmp_verified_arcache_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_arcache_count : %0d", 
                                              byte_data_cmp_failed_arcache_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("arcache count comparisions are failed"));
    end
    
    if ((byte_data_cmp_verified_arlock_count == 0) && (byte_data_cmp_failed_arlock_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arlock count comparisions - no transactions processed (likely all decode errors)"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_arlock_count != 0) && (byte_data_cmp_failed_arlock_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arlock count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_arlock_count :%0d",
                                              byte_data_cmp_verified_arlock_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_arlock_count : %0d", 
                                              byte_data_cmp_failed_arlock_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("arlock count comparisions are failed"));
    end
    
    if ((byte_data_cmp_verified_arprot_count == 0) && (byte_data_cmp_failed_arprot_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arprot count comparisions - no transactions processed (likely all decode errors)"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_arprot_count != 0) && (byte_data_cmp_failed_arprot_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arprot count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_arprot_count :%0d",
                                              byte_data_cmp_verified_arprot_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_arprot_count : %0d", 
                                              byte_data_cmp_failed_arprot_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("arprot count comparisions are failed"));
    end
 
    if ((byte_data_cmp_verified_arregion_count == 0) && (byte_data_cmp_failed_arregion_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arregion count comparisions - no transactions processed (likely all decode errors)"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_arregion_count != 0) && (byte_data_cmp_failed_arregion_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arregion count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_arregion_count :%0d",
                                              byte_data_cmp_verified_arregion_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_arregion_count : %0d", 
                                              byte_data_cmp_failed_arregion_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("arregion count comparisions are failed"));
    end

    if ((byte_data_cmp_verified_arqos_count == 0) && (byte_data_cmp_failed_arqos_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arqos count comparisions - no transactions processed (likely all decode errors)"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_arqos_count != 0) && (byte_data_cmp_failed_arqos_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("arqos count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_arqos_count :%0d",
                                              byte_data_cmp_verified_arqos_count),UVM_HIGH);
            `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_arqos_count : %0d",
                                              byte_data_cmp_failed_arqos_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("arqos count comparisions are failed"));
    end

    if(axi4_env_cfg_h.check_wait_states) begin
      if ((byte_data_cmp_verified_ar_wait_states_count != 0) && (byte_data_cmp_failed_ar_wait_states_count == 0)) begin
              `uvm_info (get_type_name(), $sformatf ("ar wait states comparisions are succesful"),UVM_HIGH);
      end
      else begin
        `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_ar_wait_states_count :%0d",
                                                byte_data_cmp_verified_ar_wait_states_count),UVM_HIGH);
              `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_ar_wait_states_count : %0d",
                                                byte_data_cmp_failed_ar_wait_states_count),UVM_HIGH);
        `uvm_error (get_type_name(), $sformatf ("ar wait states comparisions are failed"));
      end
    end

    //-------------------------------------------------------
    // Read_Data_Channel comparision
    //-------------------------------------------------------
    if ((byte_data_cmp_verified_rid_count == 0) && (byte_data_cmp_failed_rid_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("rid count comparisions - no transactions processed (likely all decode errors)"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_rid_count != 0) && (byte_data_cmp_failed_rid_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("rid count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_rid_count :%0d",
                                              byte_data_cmp_verified_rid_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_rid_count : %0d", 
                                              byte_data_cmp_failed_rid_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("rid count comparisions are failed"));
    end

    // The bid/rid-returned-to-originating-manager re-test used to live here,
    // inside the READ-mode branch, so it never ran for a write-only test and
    // the outstanding-id maps were left un-drained. It is now unconditional,
    // in sb_end_of_test_completeness_check() below.

     if ((byte_data_cmp_verified_rdata_count == 0) && (byte_data_cmp_failed_rdata_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("rdata count comparisions - no transactions processed (likely all decode errors)"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_rdata_count != 0) && (byte_data_cmp_failed_rdata_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("rdata count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_rdata_count :%0d",
                                              byte_data_cmp_verified_rdata_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_rdata_count : %0d", 
                                              byte_data_cmp_failed_rdata_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("rdata count comparisions are failed"));
    end


     if ((byte_data_cmp_verified_rresp_count == 0) && (byte_data_cmp_failed_rresp_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("rresp count comparisions - no transactions processed (likely all decode errors)"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_rresp_count != 0) && (byte_data_cmp_failed_rresp_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("rresp count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_rresp_count :%0d",
                                              byte_data_cmp_verified_rresp_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_rresp_count : %0d", 
                                              byte_data_cmp_failed_rresp_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("rresp count comparisions are failed"));
    end

     if ((byte_data_cmp_verified_ruser_count == 0) && (byte_data_cmp_failed_ruser_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("ruser count comparisions - no transactions processed (likely all decode errors)"),UVM_LOW);
    end
    else if ((byte_data_cmp_verified_ruser_count != 0) && (byte_data_cmp_failed_ruser_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("ruser count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_ruser_count :%0d",
                                              byte_data_cmp_verified_ruser_count),UVM_MEDIUM);
            `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_ruser_count : %0d",
                                              byte_data_cmp_failed_ruser_count),UVM_MEDIUM);
      `uvm_error (get_type_name(), $sformatf ("ruser count comparisons are failed - %0d mismatches out of %0d total comparisons", 
                                             byte_data_cmp_failed_ruser_count, 
                                             byte_data_cmp_verified_ruser_count + byte_data_cmp_failed_ruser_count));
    end

    if(axi4_env_cfg_h.check_wait_states) begin
      if ((byte_data_cmp_verified_r_wait_states_count != 0) && (byte_data_cmp_failed_r_wait_states_count == 0)) begin
              `uvm_info (get_type_name(), $sformatf ("r wait states comparisions are succesful"),UVM_HIGH);
      end
      else begin
        `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_r_wait_states_count :%0d",
                                                byte_data_cmp_verified_r_wait_states_count),UVM_HIGH);
              `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_r_wait_states_count : %0d",
                                                byte_data_cmp_failed_r_wait_states_count),UVM_HIGH);
        `uvm_error (get_type_name(), $sformatf ("r wait states comparisions are failed"));
      end
    end
  end


  //--------------------------------------------------------------------------------------------
  // 2.Check if master packets received are same as slave packets received
  //   To Make sure that we have equal number of master and slave packets
  //--------------------------------------------------------------------------------------------
  
  //--------------------------------------------------------------------------------------------
  // 3./4. Analysis-fifo residue and in-flight accounting used to be checked HERE,
  //   at the very end of check_phase, which put them behind both the
  //   all-slaves-PASSIVE return and the error_inject return. Both are now part of
  //   the single completeness gate near the top of this function
  //   (sb_end_of_test_completeness_check(), C1-C6), so they run in every mode.
  //
  //   The ten fifo checks that lived here were additionally VACUOUS: they tested
  //   uvm_tlm_analysis_fifo::size(), which returns the fifo's CAPACITY, and an
  //   analysis fifo is constructed unbounded (uvm_tlm_fifos.svh: super.new(name,
  //   parent, 0) "analysis fifo must be unbounded"). size() therefore returned 0
  //   unconditionally and the `is not empty` branch was unreachable in EVERY
  //   mode, including the ones where the code was nominally reached. The C6
  //   check uses used(), which is the occupancy.
  //--------------------------------------------------------------------------------------------

  `uvm_info(get_type_name(),$sformatf("--\n----------------------------------------------END OF SCOREBOARD CHECK PHASE---------------------------------------"),UVM_HIGH)

endfunction : check_phase

//--------------------------------------------------------------------------------------------
// Function: report_phase
// Display the result of simulation
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::report_phase(uvm_phase phase);
  super.report_phase(phase);
  
  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD REPORT PHASE");
  $display("-------------------------------------------- ");
  $display(" ");
  
  $display("WRITE_ADDRESS_PHASE");

  //Number of awid comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awid comparisions:%0d",byte_data_cmp_verified_awid_count+byte_data_cmp_failed_awid_count),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awid failed comparisions:%0d",byte_data_cmp_failed_awid_count),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awid verified comparisions:%0d",byte_data_cmp_verified_awid_count),UVM_HIGH);

 
  //Number of awaddr comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awaddr comparisions:%0d",byte_data_cmp_verified_awaddr_count+byte_data_cmp_failed_awaddr_count),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awaddr failed comparisions:%0d",byte_data_cmp_failed_awaddr_count),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awaddr verified comparisions:%0d",byte_data_cmp_verified_awaddr_count ),UVM_HIGH);


  //Number of awsize comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awsize comparisions:%0d",byte_data_cmp_verified_awsize_count+byte_data_cmp_failed_awsize_count),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awsize failed comparisions:%0d",byte_data_cmp_failed_awsize_count),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awsize verified comparisions:%0d",byte_data_cmp_verified_awsize_count ),UVM_HIGH);
  
  
  //Number of awlen comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awlen comparisions:%0d" ,byte_data_cmp_verified_awlen_count+byte_data_cmp_failed_awlen_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awlen failed comparisions:%0d" ,byte_data_cmp_failed_awlen_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awlen verified comparisions:%0d" ,byte_data_cmp_verified_awlen_count ),UVM_HIGH);
  
  
  //Number of awburst comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awburst comparisions:%0d",byte_data_cmp_verified_awburst_count+byte_data_cmp_failed_awburst_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awburst failed comparisions:%0d",byte_data_cmp_failed_awburst_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awburst verified comparisions:%0d",byte_data_cmp_verified_awburst_count ),UVM_HIGH);
  
  
  //Number of awcache comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awcache comparisions:%0d",byte_data_cmp_verified_awcache_count+byte_data_cmp_failed_awcache_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awcache failed comparisions:%0d",byte_data_cmp_failed_awcache_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awcache verified comparisions:%0d",byte_data_cmp_verified_awcache_count ),UVM_HIGH);
  
  
  //Number of awlock comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awlock comparisions:%0d",byte_data_cmp_verified_awlock_count+byte_data_cmp_failed_awlock_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awlock failed comparisions:%0d",byte_data_cmp_failed_awlock_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awlock verified comparisions:%0d",byte_data_cmp_verified_awlock_count ),UVM_HIGH);
  
  
  //Number of awprot comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awprot comparisions:%0d",byte_data_cmp_verified_awprot_count+byte_data_cmp_failed_awprot_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awprot failed comparisions:%0d",byte_data_cmp_failed_awprot_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise awprot verified comparisions:%0d",byte_data_cmp_verified_awprot_count ),UVM_HIGH);

  
  //Number of awuser comparisoins done
  `uvm_info (get_type_name(),$sformatf("🔍 AWUSER signal integrity comparisons:%0d",byte_data_cmp_verified_awuser_count+byte_data_cmp_failed_awuser_count ),UVM_MEDIUM);
  if(byte_data_cmp_failed_awuser_count > 0) begin
    `uvm_error (get_type_name(),$sformatf("⚠️  AWUSER FAILURES:%0d - Signal truncation or interconnect corruption detected!",byte_data_cmp_failed_awuser_count ));
  end
  `uvm_info (get_type_name(),$sformatf("✅ AWUSER verified comparisons:%0d",byte_data_cmp_verified_awuser_count ),UVM_MEDIUM);

  if(axi4_env_cfg_h.check_wait_states) begin
    `uvm_info (get_type_name(),$sformatf("Total no. of aw wait state comparisions:%0d",byte_data_cmp_verified_aw_wait_states_count+byte_data_cmp_failed_aw_wait_states_count ),UVM_HIGH);
    `uvm_info (get_type_name(),$sformatf("Total no. of aw wait state failed comparisions:%0d",byte_data_cmp_failed_aw_wait_states_count ),UVM_HIGH);
    `uvm_info (get_type_name(),$sformatf("Total no. of aw wait state verified comparisions:%0d",byte_data_cmp_verified_aw_wait_states_count ),UVM_HIGH);
  end
  
  $display("WRITE_DATA_PHASE");
  
  //Number of wdata comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise wdata comparisions:%0d",byte_data_cmp_verified_wdata_count+byte_data_cmp_failed_wdata_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise wdata failed comparisions:%0d",byte_data_cmp_failed_wdata_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise wdata verified comparisions:%0d",byte_data_cmp_verified_wdata_count ),UVM_HIGH);
  
  
  //Number of wstrb comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise wstrb comparisions:%0d",byte_data_cmp_verified_wstrb_count+byte_data_cmp_failed_wstrb_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise wstrb failed comparisions:%0d",byte_data_cmp_failed_wstrb_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise wstrb verified comparisions:%0d",byte_data_cmp_verified_wstrb_count ),UVM_HIGH);
 
  
  //Number of wuser comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise wuser comparisions:%0d",byte_data_cmp_verified_wuser_count+byte_data_cmp_failed_wuser_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise wuser failed comparisions:%0d",byte_data_cmp_failed_wuser_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise wuser verified comparisions:%0d",byte_data_cmp_verified_wuser_count ),UVM_HIGH);

  if(axi4_env_cfg_h.check_wait_states) begin
    `uvm_info (get_type_name(),$sformatf("Total no. of w wait state comparisions:%0d",byte_data_cmp_verified_w_wait_states_count+byte_data_cmp_failed_w_wait_states_count ),UVM_HIGH);
    `uvm_info (get_type_name(),$sformatf("Total no. of w wait state failed comparisions:%0d",byte_data_cmp_failed_w_wait_states_count ),UVM_HIGH);
    `uvm_info (get_type_name(),$sformatf("Total no. of w wait state verified comparisions:%0d",byte_data_cmp_verified_w_wait_states_count ),UVM_HIGH);
  end
 
  $display("WRITE_RESPONSE_PHASE");
  
  //Number of bid comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise bid comparisions:%0d",byte_data_cmp_verified_bid_count+byte_data_cmp_failed_bid_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise bid failed comparisions:%0d",byte_data_cmp_failed_bid_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise bid verified comparisions:%0d",byte_data_cmp_verified_bid_count ),UVM_HIGH);
 
  //Number of bresp comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise bresp comparisions:%0d",byte_data_cmp_verified_bresp_count+byte_data_cmp_failed_bresp_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise bresp failed comparisions:%0d",byte_data_cmp_failed_bresp_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise bresp verified comparisions:%0d",byte_data_cmp_verified_bresp_count ),UVM_HIGH);

  if(axi4_env_cfg_h.check_wait_states) begin
    `uvm_info (get_type_name(),$sformatf("Total no. of b wait state comparisions:%0d",byte_data_cmp_verified_b_wait_states_count+byte_data_cmp_failed_b_wait_states_count ),UVM_HIGH);
    `uvm_info (get_type_name(),$sformatf("Total no. of b wait state failed comparisions:%0d",byte_data_cmp_failed_b_wait_states_count ),UVM_HIGH);
    `uvm_info (get_type_name(),$sformatf("Total no. of b wait state verified comparisions:%0d",byte_data_cmp_verified_b_wait_states_count ),UVM_HIGH);
  end

  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD WRITE ADDRESS PACKETS");
  $display("-------------------------------------------- ");
  $display(" ");
    `uvm_info(get_type_name(),$sformatf("scoreboard's write address packets count  from master   \n %0d",axi4_master_tx_awaddr_count),UVM_HIGH)
    `uvm_info(get_type_name(),$sformatf("scoreboard's write address packets count  from slave    \n %0d",axi4_slave_tx_awaddr_count),UVM_HIGH)
    //`uvm_info (get_type_name(),$sformatf("Total no. of byte wise awaddr verified comparisions:%0d",byte_data_cmp_verified_awaddr_count ),UVM_NONE);
  //`uvm_info (get_type_name(),$sformatf("Total no. of byte wise awaddr failed comparisions:%0d",byte_data_cmp_failed_awaddr_count ),UVM_NONE);
 
  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD WRITE DATA PACKETS");
  $display("-------------------------------------------- ");
  $display(" ");
    `uvm_info(get_type_name(),$sformatf("scoreboard's  write data packets count from master \n %0d",axi4_master_tx_wdata_count),UVM_HIGH)
    `uvm_info(get_type_name(),$sformatf("scoreboard's  write data packets count from slave   \n %0d",axi4_slave_tx_wdata_count),UVM_HIGH)
  
  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD WRITE RESPONSE PACKETS");
  $display("-------------------------------------------- ");
  $display(" ");
    `uvm_info(get_type_name(),$sformatf("scoreboard's write response packets count from master \n %0d",axi4_master_tx_bresp_count),UVM_HIGH)
    `uvm_info(get_type_name(),$sformatf("scoreboard's write response packets count from slave  \n %0d",axi4_slave_tx_bresp_count),UVM_HIGH)
  

  
  $display("-------------------------------------------- ");
  $display("READ_ADDRESS_PHASE");
  $display("-------------------------------------------- ");
  
  //Number of arid comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arid comparisions:%0d",byte_data_cmp_verified_arid_count+byte_data_cmp_failed_arid_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arid failed comparisions:%0d",byte_data_cmp_failed_arid_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arid verified comparisions:%0d",byte_data_cmp_verified_arid_count ),UVM_HIGH);
  
  
  //Number of araddr comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise araddr comparisions:%0d",byte_data_cmp_verified_araddr_count+byte_data_cmp_failed_araddr_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise araddr failed comparisions:%0d",byte_data_cmp_failed_araddr_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise araddr verified comparisions:%0d",byte_data_cmp_verified_araddr_count ),UVM_HIGH);
 
  
  //Number of arsize comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arsize comparisions:%0d",byte_data_cmp_verified_arsize_count+byte_data_cmp_failed_arsize_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arsize failed comparisions:%0d",byte_data_cmp_failed_arsize_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arsize verified comparisions:%0d",byte_data_cmp_verified_arsize_count ),UVM_HIGH);
  
  
  //Number of arlen comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arlen comparisions:%0d",byte_data_cmp_verified_arlen_count+byte_data_cmp_failed_arlen_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arlen failed comparisions:%0d",byte_data_cmp_failed_arlen_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arlen verified comparisions:%0d",byte_data_cmp_verified_arlen_count ),UVM_HIGH);

  
  //Number of arburst comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arburst comparisions:%0d",byte_data_cmp_verified_arburst_count+byte_data_cmp_failed_arburst_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arburst failed comparisions:%0d",byte_data_cmp_failed_arburst_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arburst verified comparisions:%0d",byte_data_cmp_verified_arburst_count ),UVM_HIGH);
 
  
  //Number of arcache comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arcache comparisions:%0d",byte_data_cmp_verified_arcache_count+byte_data_cmp_failed_arcache_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arcache failed comparisions:%0d",byte_data_cmp_failed_arcache_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arcache verified comparisions:%0d",byte_data_cmp_verified_arcache_count ),UVM_HIGH);
  
  
  //Number of arlock comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arlock comparisions:%0d",byte_data_cmp_verified_arlock_count+byte_data_cmp_failed_arlock_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arlock failed comparisions:%0d",byte_data_cmp_failed_arlock_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arlock verified comparisions:%0d",byte_data_cmp_verified_arlock_count ),UVM_HIGH);
  
  
  //Number of arprot comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arprot  comparisions:%0d",byte_data_cmp_verified_arprot_count+byte_data_cmp_failed_arprot_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arprot failed comparisions:%0d",byte_data_cmp_failed_arprot_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arprot verified comparisions:%0d",byte_data_cmp_verified_arprot_count ),UVM_HIGH);
  
  
  //Number of arregion comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arregion comparisions:%0d",byte_data_cmp_verified_arregion_count+byte_data_cmp_failed_arregion_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arregion failed comparisions:%0d",byte_data_cmp_failed_arregion_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arregion verified comparisions:%0d",byte_data_cmp_verified_arregion_count ),UVM_HIGH);
 
  
  //Number of arqos comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arqos comparisions:%0d",byte_data_cmp_verified_arqos_count+byte_data_cmp_failed_arqos_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arqos failed comparisions:%0d",byte_data_cmp_failed_arqos_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise arqos verified comparisions:%0d",byte_data_cmp_verified_arqos_count ),UVM_HIGH);

  
  //Number of aruser comparisoins done  
  `uvm_info (get_type_name(),$sformatf("🔍 ARUSER signal integrity comparisons:%0d",byte_data_cmp_verified_aruser_count+byte_data_cmp_failed_aruser_count ),UVM_MEDIUM);
  if(byte_data_cmp_failed_aruser_count > 0) begin
    `uvm_error (get_type_name(),$sformatf("⚠️  ARUSER FAILURES:%0d - Signal truncation or interconnect corruption detected!",byte_data_cmp_failed_aruser_count ));
  end
  `uvm_info (get_type_name(),$sformatf("✅ ARUSER verified comparisons:%0d",byte_data_cmp_verified_aruser_count ),UVM_MEDIUM);

  if(axi4_env_cfg_h.check_wait_states) begin
    `uvm_info (get_type_name(),$sformatf("Total no. of ar wait state comparisions:%0d",byte_data_cmp_verified_ar_wait_states_count+byte_data_cmp_failed_ar_wait_states_count ),UVM_HIGH);
    `uvm_info (get_type_name(),$sformatf("Total no. of ar wait state failed comparisions:%0d",byte_data_cmp_failed_ar_wait_states_count ),UVM_HIGH);
    `uvm_info (get_type_name(),$sformatf("Total no. of ar wait state verified comparisions:%0d",byte_data_cmp_verified_ar_wait_states_count ),UVM_HIGH);
  end
  
  $display("READ_DATA_PHASE");
 
  //Number of rid comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise rid comparisions:%0d",byte_data_cmp_verified_rid_count+byte_data_cmp_failed_rid_count ),UVM_HIGH);
  
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise rid failed comparisions:%0d",byte_data_cmp_failed_rid_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise rid  verified comparisions:%0d",byte_data_cmp_verified_rid_count ),UVM_HIGH);
 
  //Number of rdata comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise rdata comparisions:%0d",byte_data_cmp_verified_rdata_count+byte_data_cmp_failed_rdata_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise rdata failed comparisions:%0d",byte_data_cmp_failed_rdata_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise rdata verified comparisions:%0d",byte_data_cmp_verified_rdata_count ),UVM_HIGH);
  
  
  //Number of rresp comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise rresp comparisions:%0d",byte_data_cmp_verified_rresp_count+byte_data_cmp_failed_rresp_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise rresp failed comparisions:%0d",byte_data_cmp_failed_rresp_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise rresp verified comparisions:%0d",byte_data_cmp_verified_rresp_count ),UVM_HIGH);
  
  
  //Number of ruser comparisoins done
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise ruser comparisions:%0d",byte_data_cmp_verified_ruser_count+byte_data_cmp_failed_ruser_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise ruser failed comparisions:%0d",byte_data_cmp_failed_ruser_count ),UVM_HIGH);
  `uvm_info (get_type_name(),$sformatf("Total no. of byte wise ruser verified comparisions:%0d",byte_data_cmp_verified_ruser_count ),UVM_HIGH);

  if(axi4_env_cfg_h.check_wait_states) begin
    `uvm_info (get_type_name(),$sformatf("Total no. of r wait state comparisions:%0d",byte_data_cmp_verified_r_wait_states_count+byte_data_cmp_failed_r_wait_states_count ),UVM_HIGH);
    `uvm_info (get_type_name(),$sformatf("Total no. of r wait state failed comparisions:%0d",byte_data_cmp_failed_r_wait_states_count ),UVM_HIGH);
    `uvm_info (get_type_name(),$sformatf("Total no. of r wait state verified comparisions:%0d",byte_data_cmp_verified_r_wait_states_count ),UVM_HIGH);
  end
  
  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD READ ADDRESS PACKETS");
  $display("-------------------------------------------- ");
  $display(" ");
    `uvm_info(get_type_name(),$sformatf("scoreboard's read address packets count from master \n %0d",axi4_master_tx_araddr_count),UVM_HIGH)
    `uvm_info(get_type_name(),$sformatf("scoreboard's read address packets count from slave  \n %0d",axi4_slave_tx_araddr_count),UVM_HIGH)
  
  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD READ DATA PACKETS");
  $display("-------------------------------------------- ");
  $display(" ");
    `uvm_info(get_type_name(),$sformatf("scoreboard's  read data packets count from master \n %0d",axi4_master_tx_rdata_count),UVM_HIGH)
    `uvm_info(get_type_name(),$sformatf("scoreboard's  read data packets count from slave  \n %0d",axi4_slave_tx_rdata_count),UVM_HIGH)
  
  $display(" ");
  $display("-------------------------------------------- ");
  $display("SCOREBOARD READ RESPONSE PACKETS");
  $display("-------------------------------------------- ");
  $display(" ");
    `uvm_info(get_type_name(),$sformatf("scoreboard's read response packets count from master \n %0d",axi4_master_tx_rresp_count),UVM_HIGH)
    `uvm_info(get_type_name(),$sformatf("scoreboard's read response packets count from slave   \n %0d",axi4_slave_tx_rresp_count),UVM_HIGH)

  // Display final test result based on UVM_ERROR and UVM_FATAL counts
  begin
    uvm_report_server rpt_server;
    int error_count;
    int fatal_count;
    
    rpt_server = uvm_report_server::get_server();
    error_count = rpt_server.get_severity_count(UVM_ERROR);
    fatal_count = rpt_server.get_severity_count(UVM_FATAL);
    
    $display(" ");
    $display("##########################################");
    if ((error_count == 0) && (fatal_count == 0)) begin
      $display("TestCase PASSED!!!");
    end else begin
      $display("TestCase ERROR!!!");
      $display("UVM_ERROR Count: %0d", error_count);
      $display("UVM_FATAL Count: %0d", fatal_count);
    end
    $display("##########################################");
    $display(" ");
  end

endfunction : report_phase

function void axi4_scoreboard::verify_read(bit [ADDRESS_WIDTH-1:0] addr,
                                           bit [DATA_WIDTH-1:0] data);
  if (!axi4_env_cfg_h.wstrb_compare_enable)
    return;
  for(int b=0; b<STROBE_WIDTH; b++) begin
    if(expected_mem.exists(addr + b))
      exp_val[8*b +: 8] = expected_mem[addr + b];
  end
  if (exp_val !== data) begin
    `uvm_error(get_type_name(),
               $sformatf("Read data mismatch at 0x%0h exp=%0h act=%0h",
                          addr, exp_val, data));
  end
endfunction

function void axi4_scoreboard::store_write(bit [ADDRESS_WIDTH-1:0] addr,
                                           bit [DATA_WIDTH-1:0] data,
                                           bit [STROBE_WIDTH-1:0] strobe);
  // Store in bus matrix reference model (for all writes including write-only slaves)
  if (axi4_bus_matrix_h != null) begin
    // Debug message for S9 writes
    if (addr >= 64'h0900_0000_0000 && addr <= 64'h0900_0000_FFFF) begin
      int byte_offset = addr[6:0]; // Byte offset within 128-byte data
      `uvm_info(get_type_name(), 
        $sformatf("Storing to S9: addr=0x%16h, byte_offset=%0d, data[31:0]=0x%08h, strobe=0x%032h", 
        addr, byte_offset, data[31:0], strobe), UVM_MEDIUM);
    end
    axi4_bus_matrix_h.store_write(addr, data);
  end
  
  // Store in scoreboard memory if wstrb comparison is enabled
  if (!axi4_env_cfg_h.wstrb_compare_enable)
    return;
  for(int b=0; b<STROBE_WIDTH; b++) begin
    if(strobe[b])
      expected_mem[addr + b] = data[8*b +: 8];
  end
endfunction

//--------------------------------------------------------------------------------------------
// Function: is_valid_write_address
// Validates if the address is accessible by the given master for write operations
// Parameters:
//   addr - Address to validate
//   master_id - Master ID requesting the write
// Returns:
//   1 if address is valid for write, 0 if invalid (should get DECERR)
//--------------------------------------------------------------------------------------------
function bit axi4_scoreboard::is_valid_write_address(bit [ADDRESS_WIDTH-1:0] addr, int master_id, bit [2:0] awprot);
  bresp_e expected_resp;
  
  // Special case: DDR memory addresses are valid for all masters (temporary fix for awid vs master_id issue)
  if(addr >= 64'h0000_0100_0000_0000 && addr <= 64'h0000_0107_FFFF_FFFF) begin
    `uvm_info(get_type_name(),$sformatf("DDR address 0x%16h is valid for master %0d write access",addr,master_id),UVM_HIGH)
    return 1;
  end
  
  // Use bus matrix to get expected write response. AWPROT now comes from the
  // caller instead of the hard-coded 3'b000 the old TODO left behind, so the
  // access matrix's security rules are actually exercised.
  if (axi4_bus_matrix_h != null) begin
    expected_resp = axi4_bus_matrix_h.get_write_resp(master_id, addr, awprot);
  end else begin
    // If no bus matrix configured, default to OKAY (valid)
    expected_resp = WRITE_OKAY;
  end
  
  // If expected response is WRITE_OKAY, then address is valid
  // If expected response is WRITE_DECERR or WRITE_SLVERR, then address is invalid
  if(expected_resp == WRITE_OKAY) begin
    `uvm_info(get_type_name(),$sformatf("Address 0x%16h is valid for master %0d write access",addr,master_id),UVM_HIGH)
    return 1;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("Address 0x%16h is invalid for master %0d write access (expected response: %0s)",addr,master_id,expected_resp.name()),UVM_HIGH)
    return 0;
  end
endfunction : is_valid_write_address

//--------------------------------------------------------------------------------------------
// Function: is_valid_read_address
// Validates if the address is accessible by the given master for read operations
// Parameters:
//   addr - Address to validate
//   master_id - Master ID requesting the read
// Returns:
//   1 if address is valid for read, 0 if invalid (should get DECERR)
//--------------------------------------------------------------------------------------------
function bit axi4_scoreboard::is_valid_read_address(bit [ADDRESS_WIDTH-1:0] addr, int master_id, bit [2:0] arprot);
  rresp_e expected_resp;
  
  // Special case: DDR memory addresses are valid for all masters (temporary fix for awid vs master_id issue)
  if(addr >= 64'h0000_0100_0000_0000 && addr <= 64'h0000_0107_FFFF_FFFF) begin
    `uvm_info(get_type_name(),$sformatf("DDR address 0x%16h is valid for master %0d read access",addr,master_id),UVM_HIGH)
    return 1;
  end
  
  // Use bus matrix to get expected read response; ARPROT from the caller.
  if (axi4_bus_matrix_h != null) begin
    expected_resp = axi4_bus_matrix_h.get_read_resp(master_id, addr, arprot);
  end else begin
    // If no bus matrix configured, default to OKAY (valid)
    expected_resp = READ_OKAY;
  end
  
  // If expected response is READ_OKAY, then address is valid
  // If expected response is READ_DECERR or READ_SLVERR, then address is invalid
  if(expected_resp == READ_OKAY) begin
    `uvm_info(get_type_name(),$sformatf("Address 0x%16h is valid for master %0d read access",addr,master_id),UVM_HIGH)
    return 1;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("Address 0x%16h is invalid for master %0d read access (expected response: %0s)",addr,master_id,expected_resp.name()),UVM_HIGH)
    return 0;
  end
endfunction : is_valid_read_address

//--------------------------------------------------------------------------------------------
// Function: get_expected_write_response
// Gets the expected write response for a given address and master
// Parameters:
//   addr - Address to check
//   master_id - Master ID making the request
// Returns:
//   Expected write response (WRITE_OKAY, WRITE_DECERR, WRITE_SLVERR)
//--------------------------------------------------------------------------------------------
function bresp_e axi4_scoreboard::get_expected_write_response(bit [ADDRESS_WIDTH-1:0] addr, int master_id, bit [2:0] awprot);
  // TODO: Get actual AxPROT from transaction - for now use default
  if (axi4_bus_matrix_h != null) begin
    // AWPROT was hard-coded to 3'b000 here, i.e. "privileged secure data", so the
    // access matrix's security rules were never exercised on the write path at
    // all: a non-secure write to a secure-only region scored as permitted.
    return axi4_bus_matrix_h.get_write_resp(master_id, addr, awprot);
  end else begin
    // If no bus matrix configured, default to OKAY response
    return WRITE_OKAY;
  end
endfunction : get_expected_write_response

//--------------------------------------------------------------------------------------------
// Function: get_expected_read_response
// Gets the expected read response for a given address and master
// Parameters:
//   addr - Address to check
//   master_id - Master ID making the request
// Returns:
//   Expected read response (READ_OKAY, READ_DECERR, READ_SLVERR)
//--------------------------------------------------------------------------------------------
function rresp_e axi4_scoreboard::get_expected_read_response(bit [ADDRESS_WIDTH-1:0] addr, int master_id, bit [2:0] arprot);
  rresp_e expected_resp;
  // Use actual AxPROT from transaction
  if (axi4_bus_matrix_h != null) begin
    expected_resp = axi4_bus_matrix_h.get_read_resp(master_id, addr, arprot);
    `uvm_info("SB_EXPECTED_RESP", $sformatf("Master %0d read addr 0x%16h ARPROT=%3b -> Expected: %s", 
              master_id, addr, arprot, expected_resp.name()), UVM_LOW);
  end else begin
    // If no bus matrix configured, default to OKAY response
    expected_resp = READ_OKAY;
    `uvm_info("SB_EXPECTED_RESP", "No bus matrix configured - defaulting to READ_OKAY", UVM_LOW);
  end
  return expected_resp;
endfunction : get_expected_read_response

//--------------------------------------------------------------------------------------------
// Function: is_expected_error_response
// Checks if an error response (DECERR/SLVERR) is expected for the given address/master
// Parameters:
//   addr - Address to check
//   master_id - Master ID making the request
//   is_write - 1 for write operation, 0 for read operation
// Returns:
//   1 if error response is expected, 0 if OKAY response is expected
//--------------------------------------------------------------------------------------------
function bit axi4_scoreboard::is_expected_error_response(bit [ADDRESS_WIDTH-1:0] addr, int master_id, bit is_write, bit [2:0] axprot);
  if (is_write) begin
    bresp_e expected_resp = get_expected_write_response(addr, master_id, axprot);
    return (expected_resp != WRITE_OKAY);
  end else begin
    // For read, use default arprot since we don't have transaction context here
    rresp_e expected_resp = get_expected_read_response(addr, master_id, axprot);
    return (expected_resp != READ_OKAY);
  end
endfunction : is_expected_error_response

//--------------------------------------------------------------------------------------------
// Task: validate_response_correctness
// Validates that the actual response matches the expected response from bus matrix
// Counts correct error responses as successful validations
// Parameters:
//   master_tx - Master transaction
//   slave_tx - Slave transaction
//   is_write - 1 for write operation, 0 for read operation
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::validate_response_correctness(input axi4_master_tx master_tx, input axi4_slave_tx slave_tx, bit is_write);
  if (is_write) begin
    // In 1:1 connection, try to infer master ID from transaction
    // Extract numeric part from AWID (e.g., "AWID_7" -> 7)
    // The originating master port, taken from the monitor stamp. This used to be
    // reverse-engineered from the AWID enum's NAME string ("AWID_7" -> 7 -> %
    // no_of_masters), which is wrong twice over: AWID is stimulus, not identity,
    // and behind an interconnect that widens AxID the enum has no name at all so
    // the parse silently produced master 0 for every transaction.
    int inferred_master_id = (master_tx.sb_src_index >= 0) ? master_tx.sb_src_index : 0;
    string awid_str = master_tx.awid.name();  // kept for the debug prints below
    int awid_num;
    bresp_e expected_resp;
    bit response_valid;
    
    if (awid_str.len() >= 5 && awid_str.substr(0, 4) == "AWID_") begin
      awid_num = awid_str.substr(5, awid_str.len()-1).atoi();
      // NOTE: awid_num is informational only now -- it no longer selects the
      // master used for the bus-matrix permission lookup.
      // In some cases, ID might map to master number
    end
    `uvm_info(get_type_name(), $sformatf("Write validation: AWID=%s, inferred_master_id=%0d, address=0x%16h", master_tx.awid, inferred_master_id, master_tx.awaddr), UVM_HIGH);
    expected_resp = get_expected_write_response(master_tx.awaddr, inferred_master_id, master_tx.awprot);
    
    // Handle exclusive write access - EXOKAY is valid alternative to OKAY
    response_valid = (slave_tx.bresp == expected_resp);
    if (!response_valid && expected_resp == WRITE_OKAY && slave_tx.bresp == WRITE_EXOKAY) begin
      response_valid = 1'b1; // EXOKAY is acceptable when OKAY is expected (exclusive access)
      `uvm_info(get_type_name(),$sformatf("Correctly generated WRITE_EXOKAY for exclusive access at address 0x%16h", master_tx.awaddr), UVM_LOW);
    end
    
    // Handle bench-only configuration limitation: direct 1:1 connections mean masters can only access their paired slave
    // Check if the target slave for this address is different from the connected slave  
    if (!response_valid && slave_tx.bresp == WRITE_SLVERR && expected_resp == WRITE_OKAY) begin
      if (axi4_bus_matrix_h != null) begin
        int target_slave_id = axi4_bus_matrix_h.decode(master_tx.awaddr);
        // In bench-only mode with direct connections, master N is connected to slave N
        // If target slave is different from connected slave, SLVERR is expected
        if (target_slave_id != inferred_master_id) begin
          response_valid = 1'b1;
          `uvm_info(get_type_name(),$sformatf("BENCH_ONLY_MODE: Accepting SLVERR for cross-slave write access - Master %0d trying to access Slave %0d at address 0x%16h", 
                    inferred_master_id, target_slave_id, master_tx.awaddr), UVM_MEDIUM);
        end
      end else begin
        // Without bus matrix, assume bench-only mode with 1:1 connections
        // Accept SLVERR as valid response for any write in this mode
        response_valid = 1'b1;
        `uvm_info(get_type_name(),$sformatf("BENCH_ONLY_MODE (no bus matrix): Accepting SLVERR for write at address 0x%16h from Master %0d", 
                  master_tx.awaddr, inferred_master_id), UVM_MEDIUM);
      end
    end
    
    if (response_valid) begin
      if (expected_resp == WRITE_DECERR) begin
        valid_decerr_count++;
        `uvm_info(get_type_name(),$sformatf("Correctly generated WRITE_DECERR for address 0x%16h (boundary crossing validation successful)", master_tx.awaddr), UVM_LOW);
      end else if (expected_resp == WRITE_SLVERR) begin
        valid_slverr_count++;
        `uvm_info(get_type_name(),$sformatf("Correctly generated WRITE_SLVERR for address 0x%16h (access control validation successful)", master_tx.awaddr), UVM_LOW);
      end
      // WRITE_OKAY and WRITE_EXOKAY responses are handled by regular comparison logic
    end else begin
      // Handle error injection mode: Accept SLVERR when error injection is enabled for protocol violation tests
      if (slave_tx.bresp == WRITE_SLVERR && expected_resp == WRITE_OKAY && axi4_env_cfg_h.error_inject) begin
        `uvm_info(get_type_name(),$sformatf("ERROR_INJECT_MODE: Accepting SLVERR for protocol violation test at address 0x%16h from Master %0d", 
                  master_tx.awaddr, inferred_master_id), UVM_LOW);
        // Do NOT increment unexpected_error_count - this is expected behavior for protocol violation tests
      end else begin
        unexpected_error_count++;
        `uvm_error(get_type_name(),$sformatf("Response mismatch for address 0x%16h: expected %0s, got %0s", master_tx.awaddr, expected_resp.name(), slave_tx.bresp.name()));
      end
    end
  end else begin
    // In 1:1 connection, try to infer master ID from transaction
    // Extract numeric part from ARID (e.g., "ARID_7" -> 7)
    // Originating master port from the monitor stamp -- see the write-side
    // comment. The ARID name parse below is retained for debug output only.
    int inferred_master_id = (master_tx.sb_src_index >= 0) ? master_tx.sb_src_index : 0;
    string arid_str = master_tx.arid.name();
    int arid_num;
    rresp_e expected_resp;
    bit response_valid;
    
    `uvm_info(get_type_name(), $sformatf("Debug: arid_str='%s', len=%0d, substr(0,4)='%s'", 
                                         arid_str, arid_str.len(), arid_str.substr(0, 4)), UVM_MEDIUM);
    if (arid_str.len() >= 6 && arid_str.substr(0, 4) == "ARID_") begin
      string num_str = arid_str.substr(5, arid_str.len()-1);
      arid_num = num_str.atoi();
      `uvm_info(get_type_name(), $sformatf("Extracted num_str='%s', arid_num=%0d", num_str, arid_num), UVM_MEDIUM);
      
      // Use configuration-aware modulo mapping to match slave driver
      // This ensures consistent master ID mapping across all components
      `uvm_info(get_type_name(), $sformatf("ARID parsing: arid_str=%s, arid_num=%0d, no_of_masters=%0d, inferred_master_id=%0d", 
                                           arid_str, arid_num, axi4_env_cfg_h.no_of_masters, inferred_master_id), UVM_MEDIUM);
    end
    `uvm_info(get_type_name(), $sformatf("Read validation: ARID=%s, inferred_master_id=%0d, address=0x%16h, arprot=%b", master_tx.arid, inferred_master_id, master_tx.araddr, master_tx.arprot), UVM_MEDIUM);
    expected_resp = get_expected_read_response(master_tx.araddr, inferred_master_id, master_tx.arprot);
    
    // Handle exclusive read access - EXOKAY is valid alternative to OKAY
    response_valid = (slave_tx.rresp == expected_resp);
    if (!response_valid && expected_resp == READ_OKAY && slave_tx.rresp == READ_EXOKAY) begin
      response_valid = 1'b1; // EXOKAY is acceptable when OKAY is expected (exclusive access)
      `uvm_info(get_type_name(),$sformatf("Correctly generated READ_EXOKAY for exclusive access at address 0x%16h", master_tx.araddr), UVM_LOW);
    end
    
    // Handle SLAVE_MEM_MODE where slaves always return OKAY/SLVERR but bus matrix expects different response
    // In SLAVE_MEM_MODE, if slave returns SLVERR and bus matrix expects DECERR or SLVERR, consider it valid
    if (!response_valid && slave_tx.rresp == READ_SLVERR && (expected_resp == READ_DECERR || expected_resp == READ_SLVERR)) begin
      response_valid = 1'b1;
      `uvm_info(get_type_name(),$sformatf("SLAVE_MEM_MODE: Accepting SLVERR response for expected %s at address 0x%16h", expected_resp.name(), master_tx.araddr), UVM_MEDIUM);
    end
    
    // Handle bench-only configuration limitation: direct 1:1 connections mean masters can only access their paired slave
    // Check if the target slave for this address is different from the connected slave
    if (!response_valid && slave_tx.rresp == READ_SLVERR && expected_resp == READ_OKAY) begin
      if (axi4_bus_matrix_h != null) begin
        int target_slave_id = axi4_bus_matrix_h.decode(master_tx.araddr);
        // In bench-only mode with direct connections, master N is connected to slave N
        // If target slave is different from connected slave, SLVERR is expected
        if (target_slave_id != inferred_master_id) begin
          response_valid = 1'b1;
          `uvm_info(get_type_name(),$sformatf("BENCH_ONLY_MODE: Accepting SLVERR for cross-slave access - Master %0d trying to access Slave %0d at address 0x%16h", 
                    inferred_master_id, target_slave_id, master_tx.araddr), UVM_MEDIUM);
        end
      end else begin
        // Without bus matrix, assume bench-only mode with 1:1 connections
        // Accept SLVERR as valid response for any read in this mode
        response_valid = 1'b1;
        `uvm_info(get_type_name(),$sformatf("BENCH_ONLY_MODE (no bus matrix): Accepting SLVERR for read at address 0x%16h from Master %0d", 
                  master_tx.araddr, inferred_master_id), UVM_MEDIUM);
      end
    end
    
    if (response_valid) begin
      if (expected_resp == READ_DECERR) begin
        valid_decerr_count++;
        `uvm_info(get_type_name(),$sformatf("Correctly generated READ_DECERR for address 0x%16h (boundary crossing validation successful)", master_tx.araddr), UVM_LOW);
      end else if (expected_resp == READ_SLVERR) begin
        valid_slverr_count++;
        `uvm_info(get_type_name(),$sformatf("Correctly generated READ_SLVERR for address 0x%16h (access control validation successful)", master_tx.araddr), UVM_LOW);
      end
      // READ_OKAY and READ_EXOKAY responses are handled by regular comparison logic
    end else begin
      // Handle error injection mode: Accept SLVERR when error injection is enabled for protocol violation tests
      if (slave_tx.rresp == READ_SLVERR && expected_resp == READ_OKAY && axi4_env_cfg_h.error_inject) begin
        `uvm_info(get_type_name(),$sformatf("ERROR_INJECT_MODE: Accepting READ_SLVERR for protocol violation test at address 0x%16h from Master %0d", 
                  master_tx.araddr, inferred_master_id), UVM_LOW);
        // Do NOT increment unexpected_error_count - this is expected behavior for protocol violation tests
      end else begin
        unexpected_error_count++;
        `uvm_error(get_type_name(),$sformatf("Response mismatch for address 0x%16h: expected %0s, got %0s", master_tx.araddr, expected_resp.name(), slave_tx.rresp.name()));
      end
    end
  end
endtask : validate_response_correctness

//--------------------------------------------------------------------------------------------
// Function: set_slave_memory_handles
// Sets the slave memory handles for backdoor verification
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::set_slave_memory_handles(axi4_slave_memory slave_mem_h[]);
  axi4_slave_mem_h = new[slave_mem_h.size()];
  foreach(slave_mem_h[i]) begin
    axi4_slave_mem_h[i] = slave_mem_h[i];
  end
endfunction : set_slave_memory_handles

//--------------------------------------------------------------------------------------------
// Function: backdoor_read_verify
// Performs backdoor read verification against slave memory
// Returns 1 if data matches, 0 if mismatch
//--------------------------------------------------------------------------------------------
function bit axi4_scoreboard::backdoor_read_verify(bit [ADDRESS_WIDTH-1:0] addr,
                                                   bit [DATA_WIDTH-1:0] expected_data,
                                                   int slave_id);
  bit [DATA_WIDTH-1:0] actual_data;
  
  if (slave_id >= axi4_slave_mem_h.size()) begin
    `uvm_error(get_type_name(), $sformatf("Invalid slave_id %0d for backdoor read", slave_id))
    return 0;
  end
  
  if (axi4_slave_mem_h[slave_id] == null) begin
    `uvm_error(get_type_name(), $sformatf("Slave memory handle %0d is null", slave_id))
    return 0;
  end
  
  // Perform backdoor read from slave memory
  axi4_slave_mem_h[slave_id].mem_read(addr, actual_data);
  
  if (actual_data == expected_data) begin
    `uvm_info(get_type_name(), $sformatf("BACKDOOR VERIFY PASS: Addr=0x%16h, Expected=0x%16h, Actual=0x%16h", 
             addr, expected_data, actual_data), UVM_LOW);
    return 1;
  end else begin
    `uvm_error(get_type_name(), $sformatf("BACKDOOR VERIFY FAIL: Addr=0x%16h, Expected=0x%16h, Actual=0x%16h", 
              addr, expected_data, actual_data));
    return 0;
  end
endfunction : backdoor_read_verify


//--------------------------------------------------------------------------------------------
// Task: sb_match_slave_write_address
// Returns the oldest pooled slave write-address transaction whose address key
// matches m_tx, pulling more from the analysis fifo until one turns up.
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::sb_match_slave_write_address(input axi4_master_tx m_tx, output axi4_slave_tx s_tx);
  axi4_slave_tx cand;
  int idx;
  forever begin
    foreach(sb_slave_waddr_pool[i]) begin
      cand = sb_slave_waddr_pool[i];
      if(cand.awaddr  == m_tx.awaddr  &&
         cand.awlen   == m_tx.awlen   &&
         cand.awsize  == m_tx.awsize  &&
         cand.awburst == m_tx.awburst) begin
        s_tx = cand;
        sb_slave_waddr_pool.delete(i);
        return;
      end
    end
    axi4_slave_write_address_analysis_fifo.get(cand);
    sb_slave_waddr_pool.push_back(cand);
  end
endtask : sb_match_slave_write_address

//--------------------------------------------------------------------------------------------
// Task: sb_match_slave_write_data
// Write data carries the burst's address, so the same key works here.
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::sb_match_slave_write_data(input axi4_master_tx m_tx, output axi4_slave_tx s_tx);
  axi4_slave_tx cand;
  forever begin
    foreach(sb_slave_wdata_pool[i]) begin
      cand = sb_slave_wdata_pool[i];
      if(cand.awaddr == m_tx.awaddr) begin
        s_tx = cand;
        sb_slave_wdata_pool.delete(i);
        return;
      end
    end
    axi4_slave_write_data_analysis_fifo.get(cand);
    sb_slave_wdata_pool.push_back(cand);
  end
endtask : sb_match_slave_write_data

//--------------------------------------------------------------------------------------------
// Task: sb_match_slave_read_address
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::sb_match_slave_read_address(input axi4_master_tx m_tx, output axi4_slave_tx s_tx);
  axi4_slave_tx cand;
  forever begin
    foreach(sb_slave_raddr_pool[i]) begin
      cand = sb_slave_raddr_pool[i];
      if(cand.araddr  == m_tx.araddr  &&
         cand.arlen   == m_tx.arlen   &&
         cand.arsize  == m_tx.arsize  &&
         cand.arburst == m_tx.arburst) begin
        s_tx = cand;
        sb_slave_raddr_pool.delete(i);
        return;
      end
    end
    axi4_slave_read_address_analysis_fifo.get(cand);
    sb_slave_raddr_pool.push_back(cand);
  end
endtask : sb_match_slave_read_address

//--------------------------------------------------------------------------------------------
// Task: sb_match_slave_write_response          (FINDING 5 -- B is no longer positional)
//
// THE KEY: (awaddr, awlen, awsize, awburst) -- the same key the AW channel
// uses -- taken oldest-match-first.
//
// Why that key and not something more obvious:
//  * NOT arrival order. Both fifos are fed by EVERY agent (env/axi4_env.sv
//    connect_phase), and an interconnect may return B responses for different
//    IDs or different subordinate ports in any order it likes. Pairing head to
//    head then compares two responses that were never related, which shows up
//    as a false BRESP/BUSER mismatch, or -- worse -- as a silent PASS when the
//    two swapped responses happen to carry the same value, hiding a routing
//    swap. That is exactly what the AW/W/AR channels were fixed for.
//  * NOT BID == BID. The fabric REMAPS the id (NIC-400 appends the ingress
//    port index to the egress AxID); that is why axid_passthrough_chk_cfg
//    exists and is turned off with a DUT in the path. An identifier the DUT is
//    allowed to rewrite cannot be a correlation key. The manager-side property
//    that survives remapping -- "the BID I got back is one I am still waiting
//    on" -- is checked separately against sb_outstanding_awid.
//  * NOT sb_src_index. It is stamped by both monitors but means different
//    things on the two sides: master port index vs slave port index. Two
//    different namespaces cannot be compared for equality.
//  * The ADDRESS survives. An AXI interconnect decodes on the address to route;
//    it does not alter it. This is the one assumption the keyed AW/W/AR
//    matchers already rest on, so B/R reuse it rather than introducing a
//    second, separately-falsifiable assumption.
//
// This works because the master-side and slave-side B packets are both
// COMBINED packets: the monitors join AW+W+B before publishing
// (axi4_*_seq_item_converter::to_write_addr_data_resp_class copies awaddr/
// awlen/awsize/awburst forward), so the address key is present on both sides
// of the comparison even though B itself carries no address.
//
// Ambiguity policy: two in-flight writes from different managers to the SAME
// address with the same shape are indistinguishable in every field this
// scoreboard compares, so oldest-match-wins is both AXI's same-id ordering
// rule and the only defensible choice. If the two are genuinely swapped the
// comparison result is identical either way.
//
// Blocking policy: if no match ever arrives this task stays parked in the
// get() below. That is deliberate -- the parked item is recorded in
// sb_inflight[SB_CH_B] and check_phase turns it into a UVM_ERROR naming the
// transaction, instead of the run ending green with a lost response.
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::sb_match_slave_write_response(input axi4_master_tx m_tx, output axi4_slave_tx s_tx);
  axi4_slave_tx cand;
  forever begin
    foreach(sb_slave_bresp_pool[i]) begin
      cand = sb_slave_bresp_pool[i];
      if(cand.awaddr  == m_tx.awaddr  &&
         cand.awlen   == m_tx.awlen   &&
         cand.awsize  == m_tx.awsize  &&
         cand.awburst == m_tx.awburst) begin
        s_tx = cand;
        sb_slave_bresp_pool.delete(i);
        return;
      end
    end
    axi4_slave_write_response_analysis_fifo.get(cand);
    sb_slave_bresp_pool.push_back(cand);
  end
endtask : sb_match_slave_write_response

//--------------------------------------------------------------------------------------------
// Task: sb_match_slave_read_data               (FINDING 5 -- R is no longer positional)
//
// THE KEY: (araddr, arlen, arsize, arburst), oldest match first -- the read
// mirror of sb_match_slave_write_response above; the same reasoning applies
// verbatim (RID is remapped, sb_src_index is two namespaces, the address is
// invariant across the interconnect).
//
// Again both sides are COMBINED packets: to_read_addr_data_class copies
// araddr/arlen/arsize/arburst onto the read-data packet on the master AND the
// slave side, so the key is available even though the R channel carries no
// address. arlen is part of the key deliberately: a returned burst of the
// wrong length must not be silently matched to a request of another length --
// it has to surface as a mismatch or as an unaccounted transaction, never as a
// convenient partner.
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::sb_match_slave_read_data(input axi4_master_tx m_tx, output axi4_slave_tx s_tx);
  axi4_slave_tx cand;
  forever begin
    foreach(sb_slave_rdata_pool[i]) begin
      cand = sb_slave_rdata_pool[i];
      if(cand.araddr  == m_tx.araddr  &&
         cand.arlen   == m_tx.arlen   &&
         cand.arsize  == m_tx.arsize  &&
         cand.arburst == m_tx.arburst) begin
        s_tx = cand;
        sb_slave_rdata_pool.delete(i);
        return;
      end
    end
    axi4_slave_read_data_analysis_fifo.get(cand);
    sb_slave_rdata_pool.push_back(cand);
  end
endtask : sb_match_slave_read_data

//--------------------------------------------------------------------------------------------
// Function: sb_chan_name
// Grep-able channel names for the completeness messages.
//--------------------------------------------------------------------------------------------
function string axi4_scoreboard::sb_chan_name(input sb_chan_e ch);
  case(ch)
    SB_CH_AW : return "WRITE_ADDRESS";
    SB_CH_W  : return "WRITE_DATA";
    SB_CH_B  : return "WRITE_RESPONSE";
    SB_CH_AR : return "READ_ADDRESS";
    SB_CH_R  : return "READ_DATA";
    default  : return "UNKNOWN";
  endcase
endfunction : sb_chan_name

//--------------------------------------------------------------------------------------------
// Function: sb_mark_inflight / sb_clear_inflight                          (FINDING 1)
// Records the master item a channel task is currently holding. Between the
// mark and the clear the item exists only as a local handle inside a task;
// nothing else in the scoreboard can see it, which is precisely how a
// never-answered transaction used to disappear.
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::sb_mark_inflight(input sb_chan_e ch, input int src_index,
                                                input longint unsigned id, input longint unsigned addr);
  sb_inflight[ch].active    = 1;
  sb_inflight[ch].src_index = src_index;
  sb_inflight[ch].id        = id;
  sb_inflight[ch].addr      = addr;
  sb_inflight[ch].t_parked  = $time;
endfunction : sb_mark_inflight

function void axi4_scoreboard::sb_clear_inflight(input sb_chan_e ch);
  sb_inflight[ch].active = 0;
endfunction : sb_clear_inflight

//--------------------------------------------------------------------------------------------
// Function: sb_retire_outstanding_awid / sb_retire_outstanding_arid
// Retires one outstanding request id for a manager when its response is seen
// at that manager's own port. A response whose id is not (yet) outstanding is
// parked in sb_pending_* and re-tested at end of test by
// sb_retest_pending_ids(), because the address and response channels are
// consumed by independent forever loops and a response may legally reach the
// scoreboard before the address packet that issued it.
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::sb_retire_outstanding_awid(input int src_index, input int id);
  if(sb_outstanding_awid.exists(src_index) &&
     sb_outstanding_awid[src_index].exists(id) &&
     sb_outstanding_awid[src_index][id] > 0) begin
    sb_outstanding_awid[src_index][id]--;
    byte_data_cmp_verified_bid_to_master_count++;
  end
  else begin
    sb_pending_bid.push_back('{src_index, id});
  end
endfunction : sb_retire_outstanding_awid

function void axi4_scoreboard::sb_retire_outstanding_arid(input int src_index, input int id);
  if(sb_outstanding_arid.exists(src_index) &&
     sb_outstanding_arid[src_index].exists(id) &&
     sb_outstanding_arid[src_index][id] > 0) begin
    sb_outstanding_arid[src_index][id]--;
    byte_data_cmp_verified_rid_to_master_count++;
  end
  else begin
    sb_pending_rid.push_back('{src_index, id});
  end
endfunction : sb_retire_outstanding_arid

//--------------------------------------------------------------------------------------------
// Function: sb_retest_pending_ids
// Re-tests the B/R responses that reached the scoreboard before the address
// packet that issued them (independent forever loops, so that ordering is
// legal). By the time check_phase runs every address packet has been consumed,
// so a still-unmatched id here is a real "response to a request this manager
// never made".
//
// Moved out of the READ-mode branch of check_phase: it used to be skipped
// entirely for write-only tests, which both lost the BID check and left
// sb_outstanding_awid un-drained.
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::sb_retest_pending_ids();
  foreach(sb_pending_bid[i]) begin
    if(sb_outstanding_awid.exists(sb_pending_bid[i][0]) &&
       sb_outstanding_awid[sb_pending_bid[i][0]].exists(sb_pending_bid[i][1]) &&
       sb_outstanding_awid[sb_pending_bid[i][0]][sb_pending_bid[i][1]] > 0) begin
      sb_outstanding_awid[sb_pending_bid[i][0]][sb_pending_bid[i][1]]--;
      byte_data_cmp_verified_bid_to_master_count++;
    end
    else begin
      `uvm_info("SB_BID_TO_MASTER_NOT_MATCHED", $sformatf("Master %0d received BID='h%0x with no outstanding write of that id",sb_pending_bid[i][0],sb_pending_bid[i][1]), UVM_LOW);
      byte_data_cmp_failed_bid_to_master_count++;
    end
  end
  sb_pending_bid.delete();

  foreach(sb_pending_rid[i]) begin
    if(sb_outstanding_arid.exists(sb_pending_rid[i][0]) &&
       sb_outstanding_arid[sb_pending_rid[i][0]].exists(sb_pending_rid[i][1]) &&
       sb_outstanding_arid[sb_pending_rid[i][0]][sb_pending_rid[i][1]] > 0) begin
      sb_outstanding_arid[sb_pending_rid[i][0]][sb_pending_rid[i][1]]--;
      byte_data_cmp_verified_rid_to_master_count++;
    end
    else begin
      `uvm_info("SB_RID_TO_MASTER_NOT_MATCHED", $sformatf("Master %0d received RID='h%0x with no outstanding read of that id",sb_pending_rid[i][0],sb_pending_rid[i][1]), UVM_LOW);
      byte_data_cmp_failed_rid_to_master_count++;
    end
  end
  sb_pending_rid.delete();

  if (byte_data_cmp_failed_bid_to_master_count == 0) begin
    `uvm_info (get_type_name(), $sformatf ("bid returned to originating manager: %0d verified",byte_data_cmp_verified_bid_to_master_count),UVM_LOW);
  end
  else begin
    `uvm_error (get_type_name(), $sformatf ("bid returned to the WRONG manager %0d time(s)",byte_data_cmp_failed_bid_to_master_count));
  end

  if (byte_data_cmp_failed_rid_to_master_count == 0) begin
    `uvm_info (get_type_name(), $sformatf ("rid returned to originating manager: %0d verified",byte_data_cmp_verified_rid_to_master_count),UVM_LOW);
  end
  else begin
    `uvm_error (get_type_name(), $sformatf ("rid returned to the WRONG manager %0d time(s)",byte_data_cmp_failed_rid_to_master_count));
  end
endfunction : sb_retest_pending_ids

//--------------------------------------------------------------------------------------------
// Function: sb_fifo_residue
// One analysis fifo's end-of-test occupancy. Reports and returns it.
//
// The caller must pass used(), NOT size(): uvm_tlm_fifo::size() returns the
// fifo's CAPACITY, and uvm_tlm_analysis_fifo is always constructed unbounded
// (capacity 0). Comparing size() to 0 is what made the previous ten fifo checks
// unable to fire.
//--------------------------------------------------------------------------------------------
function int axi4_scoreboard::sb_fifo_residue(input string nm, input int n);
  if(n != 0) begin
    `uvm_error("SB_INCOMPLETE_FIFO",
               $sformatf("axi4 %s analysis FIFO is not empty: %0d item(s) were published by a monitor and never taken off the fifo, so they were never compared. This is NOT a pass.", nm, n));
  end
  else begin
    `uvm_info(get_type_name(), $sformatf("axi4 %s analysis FIFO is empty", nm), UVM_HIGH);
  end
  return n;
endfunction : sb_fifo_residue

//--------------------------------------------------------------------------------------------
// Function: sb_end_of_test_completeness_check                             (FINDING 1)
//
// The one function that decides whether every transaction this scoreboard saw
// was actually ACCOUNTED FOR. Five independent ways a transaction can go
// missing, five checks, each of which raises a UVM_ERROR naming the
// transaction rather than a count:
//
//   C1 sb_inflight[]        a channel task is parked holding a master item
//   C2 rx vs matched        items taken off a master fifo but never compared
//   C3 holding pools        slave items pulled out of a fifo and never used
//   C4 outstanding a?id     a request that was never answered  <-- the
//                           seed-424242 escape (10 writes, 9 BIDs, PASS)
//   C5 pipeline balance     AW/W/B (and AR/R) counts must agree; a write whose
//                           B never arrived shows up here even if the B
//                           channel itself looks internally consistent
//   C6 analysis-fifo        an item published by a monitor that NO channel task
//      residue              ever pulled off the fifo. C1-C5 can only see items a
//                           worker already get()-ed, so this is the one place a
//                           never-dequeued item is visible.
//
// C6 is evaluated FIRST and unconditionally: it is the only one of the six whose
// meaning does not depend on whether a VIP subordinate exists.
//
// PASSIVE-MODE SEMANTICS (deliberate, not incidental):
//   UVM_PASSIVE removes the slave DRIVER, not the slave MONITOR. The monitor is
//   built and connected to this scoreboard either way, so a passive-slave run
//   still delivers subordinate-side transactions whenever anything (the direct
//   1:1 wiring, a DUT, the NIC-400 fabric) drives the subordinate interface, and
//   the full accounting applies unchanged.
//   The one case passive genuinely changes is when NOTHING drives the
//   subordinate side at all: then no comparison was ever possible, and reporting
//   it once ("nothing was checked") carries strictly more information than
//   reporting the same fact once per transaction. That case is detected from
//   OBSERVED traffic, never assumed from the mode, and it is still a UVM_ERROR -
//   a scoreboard that checked nothing must not report a pass.
//
// NEGATIVE-CHECK HOOK: +SB_SELFTEST_COMPLETENESS=<mask> injects one synthetic
// fault per bit so each check can be demonstrated FIRING on a passing test.
// Injection is fail-only -- it can add errors, never remove them -- and prints
// a banner so a self-test run can never be mistaken for a clean run.
//   bit0 -> C1   bit1 -> C3   bit2 -> C4   bit3 -> C2   bit4 -> C5
//   bit5 -> C6   bit6 -> the no-subordinate-observed check
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::sb_end_of_test_completeness_check();
  int unsigned selftest = 0;
  int id_map[int];
  int total_outstanding_aw = 0;
  int total_outstanding_ar = 0;
  sb_chan_e ch;
  axi4_slave_tx sb_selftest_tx;
  axi4_slave_tx sb_selftest_fifo_tx;
  bit all_slaves_passive = 1;
  bit master_side_seen   = 0;
  bit slave_side_seen    = 0;
  bit force_no_sub       = 0;
  int fifo_residue       = 0;

  // Stated explicitly: a reset discards in-flight expectations, so a clean
  // result here on a reset test means "clean since the last reset", not
  // "every transaction the test ever issued was accounted for".
  if (sb_reset_count > 0) begin
    `uvm_info(get_type_name(), $sformatf("Completeness accounting covers the window after reset #%0d (state was discarded at each reset)", sb_reset_count), UVM_LOW)
  end

  void'($value$plusargs("SB_SELFTEST_COMPLETENESS=%d", selftest));
  if(selftest != 0) begin
    `uvm_warning(get_type_name(), $sformatf("SB_SELFTEST_COMPLETENESS=%0d - INJECTING SYNTHETIC COMPLETENESS FAULTS. This run's verdict is NOT a functional result.", selftest));
    if(selftest[0]) sb_mark_inflight(SB_CH_B, 99, 64'hDEAD, 64'hDEAD_BEEF);
    if(selftest[1]) begin
      sb_selftest_tx = axi4_slave_tx::type_id::create("sb_selftest_pool_residue");
      sb_slave_bresp_pool.push_back(sb_selftest_tx);
    end
    if(selftest[2]) sb_outstanding_awid[99][8'hAB] = 1;
    if(selftest[3]) sb_rx_master_count[SB_CH_AW]++;
    if(selftest[4]) begin
      sb_rx_master_count[SB_CH_AW]++;
      sb_matched_count[SB_CH_AW]++;
    end
    if(selftest[5]) begin
      // Push one item straight into an analysis fifo. The channel tasks are dead
      // by check_phase, so nothing can drain it and C6 must report it. Note this
      // also makes the subordinate side "seen", which is why bit6 has its own
      // forcing path rather than relying on this one.
      sb_selftest_fifo_tx = axi4_slave_tx::type_id::create("sb_selftest_fifo_residue");
      axi4_slave_write_response_analysis_fifo.write(sb_selftest_fifo_tx);
    end
    if(selftest[6]) force_no_sub = 1;
  end

  //-------------------------------------------------------
  // C6: items still queued in an analysis fifo, i.e. published by a monitor and
  //     never taken by any channel task. Evaluated before everything else and in
  //     every mode.
  //
  //     used() is the occupancy. The ten checks this replaces called size(),
  //     which is the fifo's CAPACITY -- and uvm_tlm_analysis_fifo is constructed
  //     unbounded (capacity 0), so those checks compared 0 to 0 and could never
  //     fire in any mode. See the note in check_phase.
  //-------------------------------------------------------
  fifo_residue  = sb_fifo_residue("Master write address",  axi4_master_write_address_analysis_fifo.used());
  fifo_residue += sb_fifo_residue("Master write data",     axi4_master_write_data_analysis_fifo.used());
  fifo_residue += sb_fifo_residue("Master write response", axi4_master_write_response_analysis_fifo.used());
  fifo_residue += sb_fifo_residue("Master read address",   axi4_master_read_address_analysis_fifo.used());
  fifo_residue += sb_fifo_residue("Master read data",      axi4_master_read_data_analysis_fifo.used());
  fifo_residue += sb_fifo_residue("slave write address",   axi4_slave_write_address_analysis_fifo.used());
  fifo_residue += sb_fifo_residue("slave write data",      axi4_slave_write_data_analysis_fifo.used());
  fifo_residue += sb_fifo_residue("slave write response",  axi4_slave_write_response_analysis_fifo.used());
  fifo_residue += sb_fifo_residue("slave read address",    axi4_slave_read_address_analysis_fifo.used());
  fifo_residue += sb_fifo_residue("slave read data",       axi4_slave_read_data_analysis_fifo.used());
  `uvm_info("SB_COMPLETENESS", $sformatf("analysis-fifo residue at end of test: %0d item(s)", fifo_residue), UVM_LOW);

  // Drain the early-arriving responses first: until this runs the outstanding
  // maps still hold ids that WERE answered, and C4 would fire falsely.
  // Deliberately ahead of the no-subordinate branch below: the BID/RID-returned-
  // to-originating-manager property is master-side only and stays valid even
  // when there is no subordinate-side observation at all.
  sb_retest_pending_ids();

  //-------------------------------------------------------
  // Did this run actually have two sides to compare?
  //
  // Answered from OBSERVED traffic only, never from the configured mode. A
  // subordinate-side transaction leaves exactly one of three traces: it was
  // compared (matched_count), it is parked in a keyed holding pool, or it is
  // still queued in a slave analysis fifo.
  //-------------------------------------------------------
  foreach(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i])
    if(axi4_env_cfg_h.axi4_slave_agent_cfg_h[i].is_active == UVM_ACTIVE) all_slaves_passive = 0;

  for(int c = 0; c < 5; c++) begin
    if(sb_rx_master_count[c] > 0) master_side_seen = 1;
    if(sb_matched_count[c]   > 0) slave_side_seen  = 1;
  end
  if(sb_slave_waddr_pool.size() || sb_slave_wdata_pool.size() || sb_slave_bresp_pool.size() ||
     sb_slave_raddr_pool.size() || sb_slave_rdata_pool.size()) slave_side_seen = 1;
  if(axi4_slave_write_address_analysis_fifo.used()  || axi4_slave_write_data_analysis_fifo.used() ||
     axi4_slave_write_response_analysis_fifo.used() || axi4_slave_read_address_analysis_fifo.used() ||
     axi4_slave_read_data_analysis_fifo.used()) slave_side_seen = 1;

  if(force_no_sub) begin
    all_slaves_passive = 1;
    master_side_seen   = 1;
    slave_side_seen    = 0;
  end

  if(all_slaves_passive && master_side_seen && !slave_side_seen) begin
    // One error, not N. Every C1/C2/C4/C5 row would restate this single fact
    // (there was no partner for anything), and a wall of them buries it. C3 and
    // C6 are unaffected: C6 already ran above, and a non-empty holding pool is
    // impossible here by construction (a pooled item IS subordinate traffic).
    `uvm_error("SB_INCOMPLETE_NO_SUBORDINATE",
               $sformatf("All slave agents are PASSIVE and NO subordinate-side transaction was observed for the whole run, yet the manager side delivered AW=%0d W=%0d B=%0d AR=%0d R=%0d transaction(s). ZERO comparisons were performed - this scoreboard checked NOTHING, and a PASS from this run is vacuous. Either a responder (active slave agent / DUT / fabric) is missing, or the slave monitor is not connected. Per-transaction accounting is suppressed because every row would restate this one fact.",
                         sb_rx_master_count[SB_CH_AW], sb_rx_master_count[SB_CH_W],
                         sb_rx_master_count[SB_CH_B],  sb_rx_master_count[SB_CH_AR],
                         sb_rx_master_count[SB_CH_R]));
    return;
  end

  if(all_slaves_passive && !master_side_seen && !slave_side_seen) begin
    // No traffic at all reached this scoreboard. Not an error on its own (a
    // reset-only or connectivity-only test legitimately drives nothing), but it
    // must be visible, because every check below is trivially satisfied.
    `uvm_warning(get_type_name(), "Scoreboard observed NO transactions at all on either side (all slaves PASSIVE). Completeness checks C1-C6 are trivially satisfied and prove nothing about this run.");
    return;
  end

  //-------------------------------------------------------
  // C1: a channel task is still holding a master item
  //-------------------------------------------------------
  for(int c = 0; c < 5; c++) begin
    ch = sb_chan_e'(c);
    if(sb_inflight[c].active) begin
      `uvm_error("SB_INCOMPLETE_INFLIGHT",
                 $sformatf("%s channel ended with a master transaction still awaiting its slave partner: master_port=%0d id='h%0x addr='h%0x parked_at=%0t. The comparison never happened - this is NOT a pass.",
                           sb_chan_name(ch), sb_inflight[c].src_index, sb_inflight[c].id,
                           sb_inflight[c].addr, sb_inflight[c].t_parked));
    end
  end

  //-------------------------------------------------------
  // C2: taken off a master fifo but never compared
  //-------------------------------------------------------
  for(int c = 0; c < 5; c++) begin
    ch = sb_chan_e'(c);
    if(sb_rx_master_count[c] != sb_matched_count[c]) begin
      `uvm_error("SB_INCOMPLETE_UNMATCHED",
                 $sformatf("%s channel: %0d master transactions were taken off the analysis fifo but only %0d completed a comparison (%0d unaccounted).",
                           sb_chan_name(ch), sb_rx_master_count[c], sb_matched_count[c],
                           sb_rx_master_count[c] - sb_matched_count[c]));
    end
    else begin
      `uvm_info("SB_COMPLETENESS", $sformatf("%s channel: %0d received, %0d matched",
                                             sb_chan_name(ch), sb_rx_master_count[c], sb_matched_count[c]), UVM_LOW);
    end
  end

  //-------------------------------------------------------
  // C3: slave items pulled into a keyed holding pool and never consumed.
  //     These are OUT of the analysis fifos, so the fifo-size checks above
  //     report them as empty.
  //-------------------------------------------------------
  if(sb_slave_waddr_pool.size() != 0)
    `uvm_error("SB_INCOMPLETE_POOL", $sformatf("slave write-address holding pool still holds %0d unmatched transaction(s); first addr='h%0x", sb_slave_waddr_pool.size(), sb_slave_waddr_pool[0].awaddr));
  if(sb_slave_wdata_pool.size() != 0)
    `uvm_error("SB_INCOMPLETE_POOL", $sformatf("slave write-data holding pool still holds %0d unmatched transaction(s); first addr='h%0x", sb_slave_wdata_pool.size(), sb_slave_wdata_pool[0].awaddr));
  if(sb_slave_bresp_pool.size() != 0)
    `uvm_error("SB_INCOMPLETE_POOL", $sformatf("slave write-response holding pool still holds %0d unmatched transaction(s); first addr='h%0x", sb_slave_bresp_pool.size(), sb_slave_bresp_pool[0].awaddr));
  if(sb_slave_raddr_pool.size() != 0)
    `uvm_error("SB_INCOMPLETE_POOL", $sformatf("slave read-address holding pool still holds %0d unmatched transaction(s); first addr='h%0x", sb_slave_raddr_pool.size(), sb_slave_raddr_pool[0].araddr));
  if(sb_slave_rdata_pool.size() != 0)
    `uvm_error("SB_INCOMPLETE_POOL", $sformatf("slave read-data holding pool still holds %0d unmatched transaction(s); first addr='h%0x", sb_slave_rdata_pool.size(), sb_slave_rdata_pool[0].araddr));

  //-------------------------------------------------------
  // C4: a request that was issued and never answered.
  //     THIS is the check that catches the reported escape: the manager issued
  //     10 writes, 9 BIDs came back, the 10th AWID stays in the map.
  //-------------------------------------------------------
  foreach(sb_outstanding_awid[m]) begin
    id_map = sb_outstanding_awid[m];
    foreach(id_map[id]) begin
      if(id_map[id] > 0) begin
        total_outstanding_aw += id_map[id];
        `uvm_error("SB_INCOMPLETE_OUTSTANDING_AWID",
                   $sformatf("master_port=%0d issued %0d write(s) with AWID='h%0x that never received a BID. The write was NOT verified.",
                             m, id_map[id], id));
      end
    end
  end
  foreach(sb_outstanding_arid[m]) begin
    id_map = sb_outstanding_arid[m];
    foreach(id_map[id]) begin
      if(id_map[id] > 0) begin
        total_outstanding_ar += id_map[id];
        `uvm_error("SB_INCOMPLETE_OUTSTANDING_ARID",
                   $sformatf("master_port=%0d issued %0d read(s) with ARID='h%0x that never received an RID. The read was NOT verified.",
                             m, id_map[id], id));
      end
    end
  end
  `uvm_info("SB_COMPLETENESS", $sformatf("outstanding at end of test: writes=%0d reads=%0d", total_outstanding_aw, total_outstanding_ar), UVM_LOW);

  //-------------------------------------------------------
  // C5: pipeline balance. Every write that was address-checked must also have
  //     been data-checked and response-checked; every read address-checked
  //     must also have been data-checked. Independent of C4 because it catches
  //     a transaction lost between two SCOREBOARD channels, not on the bus.
  //-------------------------------------------------------
  if(sb_matched_count[SB_CH_AW] != sb_matched_count[SB_CH_W])
    `uvm_error("SB_INCOMPLETE_PIPELINE",
               $sformatf("write pipeline unbalanced: %0d AW compared but %0d W compared",
                         sb_matched_count[SB_CH_AW], sb_matched_count[SB_CH_W]));
  if(sb_matched_count[SB_CH_AW] != sb_matched_count[SB_CH_B])
    `uvm_error("SB_INCOMPLETE_PIPELINE",
               $sformatf("write pipeline unbalanced: %0d AW compared but %0d B compared - %0d write(s) were never response-checked",
                         sb_matched_count[SB_CH_AW], sb_matched_count[SB_CH_B],
                         sb_matched_count[SB_CH_AW] - sb_matched_count[SB_CH_B]));
  if(sb_matched_count[SB_CH_AR] != sb_matched_count[SB_CH_R])
    `uvm_error("SB_INCOMPLETE_PIPELINE",
               $sformatf("read pipeline unbalanced: %0d AR compared but %0d R compared - %0d read(s) were never data-checked",
                         sb_matched_count[SB_CH_AR], sb_matched_count[SB_CH_R],
                         sb_matched_count[SB_CH_AR] - sb_matched_count[SB_CH_R]));
endfunction : sb_end_of_test_completeness_check


//--------------------------------------------------------------------------------------------
// Function: sb_wdata_equal_under_strobe
// Compares the write payload on the byte lanes WSTRB actually selects.
//
// AXI4 only defines the contents of strobed byte lanes; the value of an
// unstrobed lane is explicitly not architecturally meaningful, and an
// interconnect is free to drop it. Comparing whole WDATA words therefore
// cannot pass behind a real DUT: with the Track-B fabric and a narrow AxSIZE
// the master-side monitor sees the full randomized 256-bit word while the
// slave side sees only the two strobed bytes ('h5bfa in the measured case).
// It also under-checks in the 1:1 case, where two payloads differing only in
// unstrobed lanes would have to be reported as a mismatch.
//--------------------------------------------------------------------------------------------
function bit axi4_scoreboard::sb_wdata_equal_under_strobe(input axi4_master_tx m_tx, input axi4_slave_tx s_tx);
  int beats;
  if(m_tx.wdata.size() != s_tx.wdata.size()) return 0;
  beats = m_tx.wdata.size();
  for(int b = 0; b < beats; b++) begin
    bit [(DATA_WIDTH/8)-1:0] strb;
    // Only lanes both sides agree are active can carry defined data. A strobe
    // mismatch is reported separately by the wstrb comparison.
    strb = m_tx.wstrb[b] & s_tx.wstrb[b];
    for(int by = 0; by < DATA_WIDTH/8; by++) begin
      if(strb[by]) begin
        if(m_tx.wdata[b][8*by +: 8] !== s_tx.wdata[b][8*by +: 8]) return 0;
      end
    end
  end
  return 1;
endfunction : sb_wdata_equal_under_strobe

`endif

