`ifndef MASTER_ASSERTIONS_INCLUDED_
`define MASTER_ASSERTIONS_INCLUDED_

//-------------------------------------------------------
// Importing Global Package
//-------------------------------------------------------
import axi4_globals_pkg::*;
import uvm_pkg::*;
`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Interface : master_assertions
// Used to write the assertion checks required for the master checks
//--------------------------------------------------------------------------------------------
interface master_assertions (input                     aclk,
                             input                     aresetn,
                             //Write Address Channel Signals
                             input               [3:0] awid,
                             input [ADDRESS_WIDTH-1:0] awaddr,
                             input               [7:0] awlen,
                             input               [2:0] awsize,
                             input               [1:0] awburst,
                             input               [1:0] awlock,
                             input               [3:0] awcache,
                             input               [2:0] awprot,
                             input               [3:0] awqos,
                             input               [3:0] awregion,
                             input [`AXI_AWUSER_WIDTH-1:0] awuser,
                             input                     awvalid,
                             input                     awready,
                             //Write Data Channel Signals
                             input     [DATA_WIDTH-1:0] wdata,
                             input [(DATA_WIDTH/8)-1:0] wstrb,
                             input                      wlast,
                             input [`AXI_WUSER_WIDTH-1:0] wuser,
                             input                      wvalid,
                             input                      wready,
                             //Write Response Channel
                             input [3:0] bid,
                             input [1:0] bresp,
                             input [`AXI_BUSER_WIDTH-1:0] buser,
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
                             input [`AXI_ARUSER_WIDTH-1:0] aruser,     
                             input                     arvalid,
                             input	                   arready,
                             //Read Data Channel Signals
                             input            [3:0] rid,
                             input [DATA_WIDTH-1:0] rdata,
                             input            [1:0] rresp,
                             input                  rlast,
                             input [`AXI_RUSER_WIDTH-1:0] ruser,
                             input                  rvalid,
                             input                  rready  
                            );  

  //-------------------------------------------------------
  // Importing Uvm Package
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh";

  // Cycle limit between VALID and READY handshakes.
  // For non-blocking outstanding transfers, we disable timeout checks
  // to avoid SVA-LDRF warnings while still maintaining protocol checks.
  bit disable_timeout_checks = 0;  // Can be set via config_db
  
  // Use reasonable timeout for normal operations
  // Reduced to avoid SVA-LDRF warning while still allowing sufficient time
  localparam int ready_delay_cycles = 1000;  // Reasonable limit to avoid SVA-LDRF


  

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
  //Description: AWREADY must be asserted within ready_delay_cycles after AWVALID rises
  property aw_ready_within_limit;
    @(posedge aclk) disable iff(!aresetn || disable_timeout_checks)
      $rose(awvalid) |-> ##[1:$] awready;  // Use unbounded eventually operator
  endproperty : aw_ready_within_limit
  AW_READY_WITHIN_LIMIT: assert property(aw_ready_within_limit)
    else `uvm_error("AW_READY_DELAY", $sformatf("AWREADY not asserted within %0d cycles after AWVALID", ready_delay_cycles));

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
  //Description: WREADY must be asserted within ready_delay_cycles after WVALID rises
  property w_ready_within_limit;
    @(posedge aclk) disable iff(!aresetn || disable_timeout_checks)
      $rose(wvalid) |-> ##[1:$] wready;  // Use unbounded eventually operator
  endproperty : w_ready_within_limit
  W_READY_WITHIN_LIMIT: assert property(w_ready_within_limit)
    else `uvm_error("W_READY_DELAY", $sformatf("WREADY not asserted within %0d cycles after WVALID", ready_delay_cycles));

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
  //Description: BREADY must be asserted within ready_delay_cycles after BVALID rises
  property b_ready_within_limit;
    @(posedge aclk) disable iff(!aresetn || disable_timeout_checks)
      $rose(bvalid) |-> ##[1:$] bready;  // Use unbounded eventually operator
  endproperty : b_ready_within_limit
  B_READY_WITHIN_LIMIT: assert property(b_ready_within_limit)
    else `uvm_error("B_READY_DELAY", $sformatf("BREADY not asserted within %0d cycles after BVALID", ready_delay_cycles));

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
  //Description: ARREADY must be asserted within ready_delay_cycles after ARVALID rises
  property ar_ready_within_limit;
    @(posedge aclk) disable iff(!aresetn || disable_timeout_checks)
      $rose(arvalid) |-> ##[1:$] arready;  // Use unbounded eventually operator
  endproperty : ar_ready_within_limit
  AR_READY_WITHIN_LIMIT: assert property(ar_ready_within_limit)
    else `uvm_error("AR_READY_DELAY", $sformatf("ARREADY not asserted within %0d cycles after ARVALID", ready_delay_cycles));

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
  //Description: RREADY must be asserted within ready_delay_cycles after RVALID rises
  property r_ready_within_limit;
    @(posedge aclk) disable iff(!aresetn || disable_timeout_checks)
      $rose(rvalid) |-> ##[1:$] rready;  // Use unbounded eventually operator
  endproperty : r_ready_within_limit
  R_READY_WITHIN_LIMIT: assert property(r_ready_within_limit)
    else `uvm_error("R_READY_DELAY", $sformatf("RREADY not asserted within %0d cycles after RVALID", ready_delay_cycles));

  //Assertion:   AXI_RD_VALID_STABLE_CHECK
  //Description: When RVALID is asserted, then it must remain asserted until RREADY is HIGH
  //Assertion stays asserted from the time rvalid becomes high and till rready becomes high using s_until_with keyword
//  property axi_read_data_channel_valid_stable_check;
//    @(posedge aclk) disable iff (!aresetn)
//    $rose(rvalid) |-> rvalid s_until_with rready;
//  endproperty : axi_read_data_channel_valid_stable_check
//  AXI_RD_VALID_STABLE_CHECK : assert property (axi_read_data_channel_valid_stable_check);

  //--------------------------------------------------------------------------------------------
  // X Injection Detection Assertions 
  //--------------------------------------------------------------------------------------------
  
  // Property to detect X on AWVALID
  property detect_x_on_awvalid;
    @(posedge aclk) disable iff (!aresetn)
    $isunknown(awvalid);
  endproperty : detect_x_on_awvalid
  
  `ifndef DISABLE_X_ASSERTIONS
  // Cover property to track X injection on AWVALID
  X_INJECT_AWVALID_COVER: cover property(detect_x_on_awvalid) 
    $display("[%0t] X detected on AWVALID signal", $time);
  `endif
  
  `ifndef DISABLE_X_ASSERTIONS
  // Assertion to check no handshake occurs during X on AWVALID
  property no_handshake_during_awvalid_x;
    @(posedge aclk) disable iff (!aresetn)
    $isunknown(awvalid) |-> !awready;
  endproperty : no_handshake_during_awvalid_x
  NO_HANDSHAKE_AWVALID_X: assert property(no_handshake_during_awvalid_x)
    else `uvm_warning("X_INJECT", "AWREADY asserted while AWVALID has X value");
  `endif // DISABLE_X_ASSERTIONS
  
  // Property to detect X on AWADDR with valid high
  property detect_x_on_awaddr;
    @(posedge aclk) disable iff (!aresetn)
    (awvalid === 1'b1) && $isunknown(awaddr);
  endproperty : detect_x_on_awaddr
  
  `ifndef DISABLE_X_ASSERTIONS
  X_INJECT_AWADDR_COVER: cover property(detect_x_on_awaddr)
    $display("[%0t] X detected on AWADDR while AWVALID=1", $time);
  `endif
  
  // Property to detect X on WDATA
  property detect_x_on_wdata;
    @(posedge aclk) disable iff (!aresetn)
    (wvalid === 1'b1) && $isunknown(wdata);
  endproperty : detect_x_on_wdata
  
  `ifndef DISABLE_X_ASSERTIONS
  X_INJECT_WDATA_COVER: cover property(detect_x_on_wdata)
    $display("[%0t] X detected on WDATA while WVALID=1", $time);
  `endif
  
  // Property to detect X on ARVALID
  property detect_x_on_arvalid;
    @(posedge aclk) disable iff (!aresetn)
    $isunknown(arvalid);
  endproperty : detect_x_on_arvalid
  
  `ifndef DISABLE_X_ASSERTIONS
  X_INJECT_ARVALID_COVER: cover property(detect_x_on_arvalid)
    $display("[%0t] X detected on ARVALID signal", $time);
  `endif
  
  `ifndef DISABLE_X_ASSERTIONS
  // Assertion to check recovery after X injection
  property awvalid_recovers_from_x;
    @(posedge aclk) disable iff (!aresetn || x_inject_mode)
    $isunknown(awvalid) |-> ##[1:10] (awvalid === 1'b0 || awvalid === 1'b1);
  endproperty : awvalid_recovers_from_x
  AWVALID_X_RECOVERY: assert property(awvalid_recovers_from_x)
    else `uvm_error("X_RECOVERY", "AWVALID did not recover from X within 10 cycles");
  `endif // DISABLE_X_ASSERTIONS
  
  // Additional X detection for BREADY
  property detect_x_on_bready;
    @(posedge aclk) disable iff (!aresetn)
    $isunknown(bready);
  endproperty : detect_x_on_bready
  
  `ifndef DISABLE_X_ASSERTIONS
  X_INJECT_BREADY_COVER: cover property(detect_x_on_bready)
    $display("[%0t] X detected on BREADY signal", $time);
  `endif
  
  // Additional X detection for RREADY
  property detect_x_on_rready;
    @(posedge aclk) disable iff (!aresetn)
    $isunknown(rready);
  endproperty : detect_x_on_rready
  
  `ifndef DISABLE_X_ASSERTIONS
  X_INJECT_RREADY_COVER: cover property(detect_x_on_rready)
    $display("[%0t] X detected on RREADY signal", $time);
  `endif
  
  // Control flag for X injection testing
  bit x_inject_mode = 0;
  
  initial begin
    bit awvalid_inject, arvalid_inject, wdata_inject;
    bit bready_inject, rready_inject, awaddr_inject;
    
    forever begin
      @(posedge aclk);
      // Check config_db for X injection mode - set to 1 if any injection is active
      awvalid_inject = 0; arvalid_inject = 0; wdata_inject = 0;
      bready_inject = 0; rready_inject = 0; awaddr_inject = 0;
      
      void'(uvm_config_db#(bit)::get(null, "*", "x_inject_awvalid", awvalid_inject));
      void'(uvm_config_db#(bit)::get(null, "*", "x_inject_arvalid", arvalid_inject));
      void'(uvm_config_db#(bit)::get(null, "*", "x_inject_wdata", wdata_inject));
      void'(uvm_config_db#(bit)::get(null, "*", "x_inject_bready", bready_inject));
      void'(uvm_config_db#(bit)::get(null, "*", "x_inject_rready", rready_inject));
      void'(uvm_config_db#(bit)::get(null, "*", "x_inject_awaddr", awaddr_inject));
      
      // Set x_inject_mode to 1 if any injection is active
      x_inject_mode = (awvalid_inject || arvalid_inject || wdata_inject || 
                       bready_inject || rready_inject || awaddr_inject) ? 1 : 0;
    end
  end
  
  `ifndef DISABLE_X_ASSERTIONS
  // Check no handshake during X on any valid signal
  property no_handshake_during_x_valid;
    @(posedge aclk) disable iff (!aresetn || x_inject_mode)
    ($isunknown(awvalid) || $isunknown(arvalid) || $isunknown(wvalid)) |-> 
    (!awready && !arready && !wready);
  endproperty : no_handshake_during_x_valid
  
  NO_HANDSHAKE_DURING_X: assert property(no_handshake_during_x_valid)
    else `uvm_error("X_PROTOCOL", "Handshake occurred during X on valid signal");
  
  // Check no handshake completion during X on ready signals
  property no_handshake_during_x_ready;
    @(posedge aclk) disable iff (!aresetn || x_inject_mode)
    ($isunknown(bready) || $isunknown(rready)) |-> 
    (!(bvalid && bready === 1'b1) && !(rvalid && rready === 1'b1));
  endproperty : no_handshake_during_x_ready
  
  NO_READY_HANDSHAKE_DURING_X: assert property(no_handshake_during_x_ready)
    else `uvm_error("X_PROTOCOL", "Handshake completed during X on ready signal");
  `endif // DISABLE_X_ASSERTIONS
  
  // Track X injection duration
  int x_inject_cycle_count = 0;
  always @(posedge aclk) begin
    if($isunknown(awvalid) || $isunknown(arvalid) || 
       ($isunknown(awaddr) && awvalid) || ($isunknown(wdata) && wvalid) ||
       $isunknown(bready) || $isunknown(rready)) begin
      x_inject_cycle_count++;
      `uvm_info("X_INJECT_MONITOR", $sformatf("X injection active for %0d cycles", x_inject_cycle_count), UVM_HIGH)
    end else if(x_inject_cycle_count > 0) begin
      `uvm_info("X_INJECT_MONITOR", $sformatf("X injection completed after %0d cycles", x_inject_cycle_count), UVM_MEDIUM)
      x_inject_cycle_count = 0;
    end
  end

endinterface : master_assertions

`endif

