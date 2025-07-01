`ifndef MASTER_ASSERTIONS_INCLUDED_
`define MASTER_ASSERTIONS_INCLUDED_

//-------------------------------------------------------
// Importing Global Package
//-------------------------------------------------------
import axi4_globals_pkg::*;

//--------------------------------------------------------------------------------------------
// Interface : master_assertions
// Used to write the assertion checks required for the master checks
//--------------------------------------------------------------------------------------------
interface master_assertions (input                     aclk,
                             input                     aresetn,
                             //Write Address Channel Signals
                             input               [3:0] awid,
                             input [ADDRESS_WIDTH-1:0] awaddr,
                             input               [3:0] awlen,
                             input               [2:0] awsize,
                             input               [1:0] awburst,
                             input               [1:0] awlock,
                             input               [3:0] awcache,
                             input               [2:0] awprot,
                             input                     awvalid,
                             input                     awready,
                             //Write Data Channel Signals
                             input     [DATA_WIDTH-1:0] wdata,
                             input [(DATA_WIDTH/8)-1:0] wstrb,
                             input                      wlast,
                             input                [3:0] wuser,
                             input                      wvalid,
                             input                      wready,
                             //Write Response Channel
                             input [3:0] bid,
                             input [1:0] bresp,
                             input [3:0] buser,
                             input       bvalid,
                             input       bready,
                             //Read Address Channel Signals
                             input               [3:0] arid,     
                             input [ADDRESS_WIDTH-1:0] araddr,  
                             input               [7:0] arlen,      
                             input               [2:0] arsize,     
                             input               [1:0] arburst,    
                             input               [1:0] arlock,     
                             input               [3:0] arcache,    
                             input               [2:0] arprot,     
                             input               [3:0] arqos,      
                             input               [3:0] arregion,   
                             input               [3:0] aruser,     
                             input                     arvalid,
                             input	                   arready,
                             //Read Data Channel Signals
                             input            [3:0] rid,
                             input [DATA_WIDTH-1:0] rdata,
                             input            [1:0] rresp,
                             input                  rlast,
                             input            [3:0] ruser,
                             input                  rvalid,
                             input                  rready  
                            );  

  //-------------------------------------------------------
  // Importing Uvm Package
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh";

  // Cycle limit between VALID and READY handshakes. This value must be a
  // constant because it is used inside the timing window for the assertions.
  // Tests can override the parameter when the interface is instantiated.
  parameter int READY_DELAY_CYCLES = 100;


  

  //--------------------------------------------------------------------------------------------
  // Assertion properties written for various checks in write address channel
  //--------------------------------------------------------------------------------------------
  //Assertion:   AXI_WA_STABLE_SIGNALS_CHECK
  //Description: All signals must remain stable after AWVALID is asserted until AWREADY IS LOW
  property if_write_address_channel_signals_are_stable;
    @(posedge aclk) disable iff (!aresetn)
    (awvalid==1 && awready==0) |=> ($stable(awid) && $stable(awaddr) && $stable(awlen) && $stable(awsize) && 
                                    $stable(awburst) && $stable(awlock) && $stable(awcache) && $stable(awprot));
  endproperty : if_write_address_channel_signals_are_stable
  AXI_WA_STABLE_SIGNALS_CHECK: assert property (if_write_address_channel_signals_are_stable);
 
  //Assertion:   AXI_WA_UNKNOWN_SIGNALS_CHECK
  //Description: A value of X on signals is not permitted when AWVALID is HIGH
  property if_write_address_channel_signals_are_unknown;
    @(posedge aclk) disable iff (!aresetn)
    (awvalid==1) |-> (!($isunknown(awid)) && !($isunknown(awaddr)) && !($isunknown(awlen)) && !($isunknown(awsize))
                     && !($isunknown(awburst)) && !($isunknown(awlock)) && !($isunknown(awcache)) && !($isunknown(awprot)));
  endproperty : if_write_address_channel_signals_are_unknown
  AXI_WA_UNKNOWN_SIGNALS_CHECK: assert property (if_write_address_channel_signals_are_unknown);

  //Assertion:   AW_READY_WITHIN_LIMIT
  //Description: AWREADY must be asserted within READY_DELAY_CYCLES after AWVALID rises
  property aw_ready_within_limit;
    @(posedge aclk) disable iff(!aresetn)
      $rose(awvalid) |-> (##[1:READY_DELAY_CYCLES] awready);
  endproperty : aw_ready_within_limit
  AW_READY_WITHIN_LIMIT: assert property(aw_ready_within_limit)
    else `uvm_error("AW_READY_DELAY", $sformatf("AWREADY not asserted within %0d cycles after AWVALID", READY_DELAY_CYCLES));

  //Assertion:   AXI_WA_VALID_STABLE_CHECK
  //Description: When AWVALID is asserted, then it must remain asserted until AWREADY is HIGH
  //Assertion stays asserted from the time awvalid becomes high and till awready becomes high using s_until_with keyword
///  property axi_write_address_channel_valid_stable_check;
///    @(posedge aclk) disable iff (!aresetn)
///    $rose(awvalid) |-> awvalid s_until_with awready;
///  endproperty : axi_write_address_channel_valid_stable_check
///  AXI_WA_VALID_STABLE_CHECK : assert property (axi_write_address_channel_valid_stable_check);


  //--------------------------------------------------------------------------------------------
  // Assertion properties written for various checks in write data channel
  //--------------------------------------------------------------------------------------------
  //Assertion:   AXI_WD_STABLE_SIGNALS_CHECK
  //Description: All signals must remain stable after WVALID is asserted until WREADY IS LOW
  property if_write_data_channel_signals_are_stable;
    @(posedge aclk) disable iff (!aresetn)
    (wvalid==1 && wready==0) |=> ($stable(wdata) && $stable(wstrb) && $stable(wlast) && $stable(wuser));
  endproperty : if_write_data_channel_signals_are_stable
  AXI_WD_STABLE_SIGNALS_CHECK: assert property (if_write_data_channel_signals_are_stable);
 
  //Assertion:   AXI_WD_UNKNOWN_SIGNALS_CHECK
  //Description: A value of X on signals is not permitted when WVALID is HIGH
  property if_write_data_channel_signals_are_unknown;
    @(posedge aclk) disable iff (!aresetn)
    (wvalid == 1) |-> (!($isunknown(wdata)) && !($isunknown(wstrb)) && !($isunknown(wlast)) && !($isunknown(wuser)));
  endproperty : if_write_data_channel_signals_are_unknown
  AXI_WD_UNKNOWN_SIGNALS_CHECK: assert property (if_write_data_channel_signals_are_unknown);

  //Assertion:   W_READY_WITHIN_LIMIT
  //Description: WREADY must be asserted within READY_DELAY_CYCLES after WVALID rises
  property w_ready_within_limit;
    @(posedge aclk) disable iff(!aresetn)
      $rose(wvalid) |-> (##[1:READY_DELAY_CYCLES] wready);
  endproperty : w_ready_within_limit
  W_READY_WITHIN_LIMIT: assert property(w_ready_within_limit)
    else `uvm_error("W_READY_DELAY", $sformatf("WREADY not asserted within %0d cycles after WVALID", READY_DELAY_CYCLES));

  //Assertion:   AXI_WD_VALID_STABLE_CHECK
  //Description: When WVALID is asserted, then it must remain asserted until WREADY is HIGH
  //Assertion stays asserted from the time wvalid becomes high and till wready becomes high using s_until_with keyword
//  property axi_write_data_channel_valid_stable_check;
//    @(posedge aclk) disable iff (!aresetn)
//    $rose(wvalid) |-> wvalid s_until_with wready;
//  endproperty : axi_write_data_channel_valid_stable_check
//  AXI_WD_VALID_STABLE_CHECK : assert property (axi_write_data_channel_valid_stable_check);
  
  
  //--------------------------------------------------------------------------------------------
  // Assertion properties written for various checks in write response channel
  //--------------------------------------------------------------------------------------------
  //Assertion:   AXI_WR_STABLE_SIGNALS_CHECK
  //Description: All signals must remain stable after BVALID is asserted until BREADY IS LOW
  property if_write_response_channel_signals_are_stable;
    @(posedge aclk) disable iff(!aresetn)
    bvalid==1 && bready==0 |=> $stable(bid) && $stable(buser) && $stable(bresp); 
  endproperty : if_write_response_channel_signals_are_stable
  AXI_WR_STABLE_SIGNALS_CHECK: assert property (if_write_response_channel_signals_are_stable);

  //Assertion:   AXI_WR_UNKNOWN_SIGNALS_CHECK
  //Description: A value of X on signals is not permitted when BVALID is HIGH
  property if_write_response_channel_signals_are_unknown;
    @(posedge aclk) disable iff(!aresetn)
    bvalid==1 |-> !$isunknown(bid) && !$isunknown(buser) && !$isunknown(bresp);  
  endproperty : if_write_response_channel_signals_are_unknown
  AXI_WR_UNKNOWN_SIGNALS_CHECK: assert property (if_write_response_channel_signals_are_unknown);

  //Assertion:   B_READY_WITHIN_LIMIT
  //Description: BREADY must be asserted within READY_DELAY_CYCLES after BVALID rises
  property b_ready_within_limit;
    @(posedge aclk) disable iff(!aresetn)
      $rose(bvalid) |-> (##[1:READY_DELAY_CYCLES] bready);
  endproperty : b_ready_within_limit
  B_READY_WITHIN_LIMIT: assert property(b_ready_within_limit)
    else `uvm_error("B_READY_DELAY", $sformatf("BREADY not asserted within %0d cycles after BVALID", READY_DELAY_CYCLES));

  //Assertion:   AXI_WR_VALID_STABLE_CHECK
  //Description: When BVALID is asserted, then it must remain asserted until BREADY is HIGH
  //Assertion stays asserted from the time bvalid becomes high and till bready becomes high using s_until_with keyword
///  property axi_write_response_channel_valid_stable_check;
///    @(posedge aclk) disable iff(!aresetn)
///    $rose(bvalid) |-> bvalid s_until_with bready;
///  endproperty : axi_write_response_channel_valid_stable_check
///  AXI_WR_VALID_STABLE_CHECK : assert property (axi_write_response_channel_valid_stable_check);
 

  //--------------------------------------------------------------------------------------------
  // Assertion properties written for various checks in read address channel
  //--------------------------------------------------------------------------------------------
  //Assertion:   AXI_RA_STABLE_SIGNALS_CHECK
  //Description: All signals must remain stable after ARVALID is asserted until ARREADY IS LOW
  property if_read_address_channel_signals_are_stable;
    @(posedge aclk) disable iff (!aresetn)
    (arvalid==1 && arready==0) |=> ($stable(arid) && $stable(araddr) && $stable(arlen) && $stable(arsize) && 
                                    $stable(arburst) && $stable(arlock) && $stable(arcache) && $stable(arprot));
  endproperty : if_read_address_channel_signals_are_stable
  AXI_RA_STABLE_SIGNALS_CHECK: assert property (if_read_address_channel_signals_are_stable);
 
  //Assertion:   AXI_RA_UNKNOWN_SIGNALS_CHECK
  //Description: A value of X on signals is not permitted when ARVALID is HIGH
  property if_read_address_channel_signals_are_unknown;
    @(posedge aclk) disable iff (!aresetn)
    (arvalid==1) |-> (!($isunknown(arid)) && !($isunknown(araddr)) && !($isunknown(arlen)) && !($isunknown(arsize))
                     && !($isunknown(arburst)) && !($isunknown(arlock)) && !($isunknown(arcache)) && !($isunknown(arprot)));
  endproperty : if_read_address_channel_signals_are_unknown
  AXI_RA_UNKNOWN_SIGNALS_CHECK: assert property (if_read_address_channel_signals_are_unknown);

  //Assertion:   AR_READY_WITHIN_LIMIT
  //Description: ARREADY must be asserted within READY_DELAY_CYCLES after ARVALID rises
  property ar_ready_within_limit;
    @(posedge aclk) disable iff(!aresetn)
      $rose(arvalid) |-> (##[1:READY_DELAY_CYCLES] arready);
  endproperty : ar_ready_within_limit
  AR_READY_WITHIN_LIMIT: assert property(ar_ready_within_limit)
    else `uvm_error("AR_READY_DELAY", $sformatf("ARREADY not asserted within %0d cycles after ARVALID", READY_DELAY_CYCLES));

  //Assertion:   AXI_RA_VALID_STABLE_CHECK
  //Description: When ARVALID is asserted, then it must remain asserted until ARREADY is HIGH
  //Assertion stays asserted from the time arvalid becomes high and till arready becomes high using s_until_with keyword
////  property axi_read_address_channel_valid_stable_check;
////    @(posedge aclk) disable iff (!aresetn)
////    $rose(arvalid) |-> arvalid s_until_with arready;
////  endproperty : axi_read_address_channel_valid_stable_check
////  AXI_RA_VALID_STABLE_CHECK : assert property (axi_read_address_channel_valid_stable_check);
////

  //--------------------------------------------------------------------------------------------
  // Assertion properties written for various checks in read data channel
  //--------------------------------------------------------------------------------------------
  //Assertion:   AXI_RD_STABLE_SIGNALS_CHECK
  //Description: All signals must remain stable after RVALID is asserted until RREADY IS LOW
  property if_read_data_channel_signals_are_stable;
    @(posedge aclk) disable iff (!aresetn)
    (rvalid==1 && rready==0) |=> ($stable(rid) && $stable(rdata) && $stable(rresp) && $stable(rlast) && $stable(ruser));
  endproperty : if_read_data_channel_signals_are_stable
  AXI_RD_STABLE_SIGNALS_CHECK: assert property (if_read_data_channel_signals_are_stable);
 
  //Assertion:   AXI_RD_UNKNOWN_SIGNALS_CHECK
  //Description: A value of X on signals is not permitted when RVALID is HIGH
  property if_read_data_channel_signals_are_unknown;
    @(posedge aclk) disable iff (!aresetn)
    (rvalid==1) |-> (!($isunknown(rid)) && !($isunknown(rdata)) && !($isunknown(rresp))
                    && !($isunknown(rlast)) && !($isunknown(ruser)));
  endproperty : if_read_data_channel_signals_are_unknown
  AXI_RD_UNKNOWN_SIGNALS_CHECK: assert property (if_read_data_channel_signals_are_unknown);

  //Assertion:   R_READY_WITHIN_LIMIT
  //Description: RREADY must be asserted within READY_DELAY_CYCLES after RVALID rises
  property r_ready_within_limit;
    @(posedge aclk) disable iff(!aresetn)
      $rose(rvalid) |-> (##[1:READY_DELAY_CYCLES] rready);
  endproperty : r_ready_within_limit
  R_READY_WITHIN_LIMIT: assert property(r_ready_within_limit)
    else `uvm_error("R_READY_DELAY", $sformatf("RREADY not asserted within %0d cycles after RVALID", READY_DELAY_CYCLES));

  //Assertion:   AXI_RD_VALID_STABLE_CHECK
  //Description: When RVALID is asserted, then it must remain asserted until RREADY is HIGH
  //Assertion stays asserted from the time rvalid becomes high and till rready becomes high using s_until_with keyword
//  property axi_read_data_channel_valid_stable_check;
//    @(posedge aclk) disable iff (!aresetn)
//    $rose(rvalid) |-> rvalid s_until_with rready;
//  endproperty : axi_read_data_channel_valid_stable_check
//  AXI_RD_VALID_STABLE_CHECK : assert property (axi_read_data_channel_valid_stable_check);

endinterface : master_assertions

`endif

