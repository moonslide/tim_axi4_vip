`ifndef AXI4_MASTER_COVERAGE_INCLUDED_
`define AXI4_MASTER_COVERAGE_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: master_coverage
// master_coverage determines the how much code is covered for better functionality of the TB.
//--------------------------------------------------------------------------------------------
class axi4_master_coverage extends uvm_subscriber #(axi4_master_tx);
  `uvm_component_utils(axi4_master_coverage)

  // Variable: axi4_master_agent_cfg_h
  // Declaring handle for master agent configuration class 
  axi4_master_agent_config axi4_master_agent_cfg_h;
 
  //-------------------------------------------------------
  // Covergroup: axi4_master_covergroup
  // Covergroup consists of the various coverpoints based on
  // no. of the variables used to improve the coverage.
  //-------------------------------------------------------
  covergroup axi4_master_covergroup with function sample (axi4_master_agent_config cfg, axi4_master_tx packet);
    option.per_instance = 1;

    //-------------------------------------------------------
    // Write channel signals 
    //-------------------------------------------------------
   
    AWLEN_CP : coverpoint packet.awlen {
      option.comment = "Write Address Length values";
      bins AWLEN_1      = {0};
      bins AWLEN_2      = {1};
      bins AWLEN_4      = {3};
      bins AWLEN_8      = {7};
      bins AWLEN_16     = {15};
      bins AWLEN_32     = {31};
      bins AWLEN_64     = {63};
      bins AWLEN_128    = {127};
      bins AWLEN_256    = {255};
      bins AWLEN_DEFAULT = default ;
    }

    AWBURST_CP : coverpoint packet.awburst {
      option.comment = "Write Address Burst values";
      bins READ_FIXED = {0};
      bins WRITE_INCR = {1}; 
      bins READ_WRAP  = {2};     
      illegal_bins ILLEGAL_BIN_OF_AWBURST = {3};     
    }

    AWSIZE_CP : coverpoint packet.awsize {
      option.comment = "Write Address size values";
      bins AWSIZE_1BYTE    = {0};
      bins AWSIZE_2BYTES   = {1};
      bins AWSIZE_4BYTES   = {2};
      bins AWSIZE_8BYTES   = {3};
      bins AWSIZE_16BYTES  = {4};
      bins AWSIZE_32BYTES  = {5};
      bins AWSIZE_64BYTES  = {6};
      bins AWSIZE_128BYTES = {7};
    }

    AWLOCK_CP :coverpoint packet.awlock {
      option.comment= "Write Address Lock values";
      bins AWLOCK[] = {0,1};
    }

    AWCACHE_CP : coverpoint packet.awcache {
      option.comment = "Write Address Cache values";
      bins WRITE_BUFFERABLE     = {0};
      bins WRITE_MODIFIABLE     = {1};
      bins WRITE_OTHER_ALLOCATE = {2}; 
      bins WRITE_ALLOCATE       = {3};
    }

    AWPROT_CP : coverpoint packet.awprot {
      option.comment = "Write Address Protection values";
      bins AWPROT[] = {[0:$]};
    }

    AWID_CP : coverpoint packet.awid {
      option.comment = "Write Address ID values";
      bins AWID[] = {[0:$]};
    }

    // Cover write strobe patterns for first data beat
    WSTRB_CP : coverpoint (packet.wstrb.size() > 0 ? packet.wstrb[0] : 0) {
      option.comment = "Write strobe patterns";
      bins NONE         = {4'h0};
      bins ALL          = {4'hF};
      bins LOWER_HALF   = {4'h3};
      bins UPPER_HALF   = {4'hC};
      bins EVEN_BYTES   = {4'h5};
      bins ODD_BYTES    = {4'hA};
      bins BYTE0        = {4'h1};
      bins BYTE3        = {4'h8};
      bins OTHER        = default;
    }

    BRESP_CP : coverpoint packet.bresp {
      option.comment    = "Write Response values";
      bins WRITE_OKAY   = {0};
      bins WRITE_EXOKAY = {1};
      bins WRITE_SLVERR = {2};
      bins WRITE_DECERR = {3};
    }

    //-------------------------------------------------------
    // Read channel signals 
    //-------------------------------------------------------
    
    ARLEN_CP : coverpoint packet.arlen {
      option.comment = "Read Address Length values";
      bins ARLEN_1   = {0};
      bins ARLEN_2   = {1};
      bins ARLEN_4   = {3};
      bins ARLEN_8   = {7};
      bins ARLEN_16  = {15};
      bins ARLEN_32  = {31};
      bins ARLEN_64  = {63};
      bins ARLEN_128 = {127};
      bins ARLEN_256 = {255};
      bins ARLEN_DEFAULT= default ;
    }

    ARBURST_CP : coverpoint packet.arburst {
      option.comment = "Read Address Burst values";
      bins READ_FIXED ={0};
      bins WRITE_INCR ={1}; 
      bins READ_WRAP  ={2};   
      illegal_bins ILLEGAL_BIN_OF_ARBURST = {3};   
    }

    ARSIZE_CP : coverpoint packet.arsize {
      option.comment = "Read Address Size values";
      bins ARSIZE_1BYTE    = {0};
      bins ARSIZE_2BYTES   = {1};
      bins ARSIZE_4BYTES   = {2};
      bins ARSIZE_8BYTES   = {3};
      bins ARSIZE_16BYTES  = {4};
      bins ARSIZE_32BYTES  = {5};
      bins ARSIZE_64BYTES  = {6};
      bins ARSIZE_128BYTES = {7};
    }

    ARLOCK_CP :coverpoint packet.arlock {
      option.comment= "Read Address Lock values";
      bins ARLOCK[] = {0,1};
    }

    ARCACHE_CP : coverpoint packet.arcache {
      option.comment = "Read Address Cache values";
      bins READ_BUFFERABLE = {0};
      bins READ_MODIFIABLE = {1};
      bins READ_OTHER_ALLOCATE = {2}; 
      bins READ_ALLOCATE = {3};
    }

    ARPROT_CP : coverpoint packet.arprot {
      option.comment = "Read Address Protection values";
      bins ARPROT[] = {[0:$]};
    }

    BID_CP : coverpoint packet.bid {
      option.comment = "Write Response values";
      bins BID[] = {[0:$]};
    }

    ARID_CP : coverpoint packet.rid {
      option.comment = "Read Address ID values";
      bins ARID[] = {[0:$]};
    }

    RID_CP : coverpoint packet.rid {
      option.comment = "Read ID values";
      bins RID[] = {[0:$]};
    }
    
    RRESP_CP : coverpoint packet.rresp {
      option.comment    = "Read Response values";
      bins READ_OKAY    = {0};
      bins READ_EXOKAY  = {1};
      bins READ_SLVERR  = {2};
      bins READ_DECERR  = {3};
    }


    // Address width can range from 1-64 bits according to the
    // AMBA AXI4 specification. Create a bin for each value so that
    // coverage hits only reflect the configured widths.
    ADDR_WIDTH_CP : coverpoint cfg.addr_width {
      bins width[] = {[1:64]};
    }

    // Data width is restricted to power-of-two values between
    // 8 and 1024 bits.  Create explicit bins for each legal value.
    DATA_WIDTH_CP : coverpoint cfg.data_width {
      bins DW_8    = {8};
      bins DW_16   = {16};
      bins DW_32   = {32};
      bins DW_64   = {64};
      bins DW_128  = {128};
      bins DW_256  = {256};
      bins DW_512  = {512};
      bins DW_1024 = {1024};
   }

    //-------------------------------------------------------
    // Wait state coverage
    //-------------------------------------------------------

    AW_WAIT_STATES_CP : coverpoint packet.aw_wait_states {
      option.comment = "AWREADY wait states";
      bins AW_WS[] = {[0:6]};
    }

    AW_HANDSHAKE_CP : coverpoint (packet.aw_wait_states == 0) {
      option.comment = "AWREADY handshake";
      bins HANDSHAKE = {1};
    }

    W_WAIT_STATES_CP : coverpoint packet.w_wait_states {
      option.comment = "WREADY wait states";
      bins W_WS[] = {[0:6]};
    }

    W_HANDSHAKE_CP : coverpoint (packet.w_wait_states == 0) {
      option.comment = "WREADY handshake";
      bins HANDSHAKE = {1};
    }

    B_WAIT_STATES_CP : coverpoint packet.b_wait_states {
      option.comment = "BREADY wait states";
      bins B_WS[] = {[0:6]};
    }

    B_HANDSHAKE_CP : coverpoint (packet.b_wait_states == 0) {
      option.comment = "BREADY handshake";
      bins HANDSHAKE = {1};
    }

    AR_WAIT_STATES_CP : coverpoint packet.ar_wait_states {
      option.comment = "ARREADY wait states";
      bins AR_WS[] = {[0:6]};
    }

    AR_HANDSHAKE_CP : coverpoint (packet.ar_wait_states == 0) {
      option.comment = "ARREADY handshake";
      bins HANDSHAKE = {1};
    }

    R_WAIT_STATES_CP : coverpoint packet.r_wait_states {
      option.comment = "RREADY wait states";
      bins R_WS[] = {[0:6]};
    }

    R_HANDSHAKE_CP : coverpoint (packet.r_wait_states == 0) {
      option.comment = "RREADY handshake";
      bins HANDSHAKE = {1};
    }
    TRANSFER_TYPE_CP : coverpoint packet.transfer_type {
      option.comment = "transfer type";
      bins BLOCKING_WRITE     = {0};
      bins BLOCKING_READ      = {1};
      bins NON_BLOCKING_WRITE = {2};
      bins NON_BLOCKING_READ  = {3};
    }

    WRITE_CROSS_4K_CP : coverpoint (((packet.awaddr & 32'hFFFFF000) != ((packet.awaddr + ((packet.awlen+1)*(1<<packet.awsize)) - 1) & 32'hFFFFF000))) {
      option.comment = "Write burst crosses 4KB";
      bins NO  = {0};
      bins YES = {1};
    }

    READ_CROSS_4K_CP : coverpoint (((packet.araddr & 32'hFFFFF000) != ((packet.araddr + ((packet.arlen+1)*(1<<packet.arsize)) - 1) & 32'hFFFFF000))) {
      option.comment = "Read burst crosses 4KB";
      bins NO  = {0};
      bins YES = {1};
    }

    //-------------------------------------------------------
    // Cross of coverpoints
    //-------------------------------------------------------

    AWLENGTH_CP_X_AWSIZE_X_AWBURST    :cross AWLEN_CP,AWSIZE_CP,AWBURST_CP;
    ARLENGTH_CP_X_ARSIZE_X_ARBURST    :cross ARLEN_CP,ARSIZE_CP,ARBURST_CP;
    BID_CP_X_BRESP_CP                 :cross BID_CP,BRESP_CP;
    RID_CP_X_RRESP_CP                 :cross BID_CP,BRESP_CP;
    AWBURST_CP_X_AWLEN_CP_X_AWSIZE_CP :cross AWBURST_CP,AWLEN_CP,AWSIZE_CP;
    ARBURST_CP_X_ARLEN_CP_X_ARSIZE_CP :cross ARBURST_CP,ARLEN_CP,ARSIZE_CP;
    ADDR_DATA_WIDTH_CP : cross ADDR_WIDTH_CP, DATA_WIDTH_CP;
    // TRANSFER_TYPE_CP_X_BURST_TYPE_CP  :cross TRANSFER_TYPE_CP,BURST_TYPE_CP;

  endgroup: axi4_master_covergroup


  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_coverage", uvm_component parent = null);
  extern virtual function void write(axi4_master_tx t);
  extern virtual function void report_phase(uvm_phase phase);

endclass : axi4_master_coverage

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_master_coverage
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_master_coverage::new(string name = "axi4_master_coverage",
                                 uvm_component parent = null);
  super.new(name, parent);
  axi4_master_covergroup =new();
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: write
// sampling is done
//--------------------------------------------------------------------------------------------
function void axi4_master_coverage::write(axi4_master_tx t);
 `uvm_info(get_type_name(),$sformatf("Before calling SAMPLE METHOD"),UVM_HIGH);

  axi4_master_covergroup.sample(axi4_master_agent_cfg_h,t);

  `uvm_info(get_type_name(),"After calling SAMPLE METHOD",UVM_HIGH);
endfunction: write

//--------------------------------------------------------------------------------------------
// Function: report_phase
// Used for reporting the coverage instance percentage values
//--------------------------------------------------------------------------------------------
function void axi4_master_coverage::report_phase(uvm_phase phase);
  `uvm_info(get_type_name(),$sformatf("AXI4 Master Agent Coverage = %0.2f %%", axi4_master_covergroup.get_coverage()), UVM_NONE);
endfunction: report_phase

`endif

