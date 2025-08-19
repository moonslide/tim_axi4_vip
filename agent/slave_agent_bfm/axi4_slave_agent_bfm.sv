`ifndef AXI4_SLAVE_AGENT_BFM_INCLUDED_
`define AXI4_SLAVE_AGENT_BFM_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module:AXI4 Slave Agent BFM
// This module is used as the configuration class for slave agent bfm and its components
//--------------------------------------------------------------------------------------------
module axi4_slave_agent_bfm #(parameter int SLAVE_ID = 0)(axi4_if intf);

  //-------------------------------------------------------
  // Package : Importing Uvm Pakckage and Test Package
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  slave_assertions S_A(
    .aclk(intf.aclk),
    .aresetn(intf.aresetn),
    .awid(intf.awid),
    .awaddr(intf.awaddr),
    .awlen(intf.awlen),
    .awsize(intf.awsize),
    .awburst(intf.awburst),
    .awlock(intf.awlock),
    .awcache(intf.awcache),
    .awprot(intf.awprot),
    .awqos(intf.awqos),
    .awregion(intf.awregion),
    .awuser(intf.awuser),
    .awvalid(intf.awvalid),
    .awready(intf.awready),
    .wdata(intf.wdata),
    .wstrb(intf.wstrb),
    .wlast(intf.wlast),
    .wuser(intf.wuser),
    .wvalid(intf.wvalid),
    .wready(intf.wready),
    .bid(intf.bid),
    .bresp(intf.bresp),
    .buser(intf.buser),
    .bvalid(intf.bvalid),
    .bready(intf.bready),
    .arid(intf.arid),
    .araddr(intf.araddr),
    .arlen(intf.arlen),
    .arsize(intf.arsize),
    .arburst(intf.arburst),
    .arlock(intf.arlock),
    .arcache(intf.arcache),
    .arprot(intf.arprot),
    .arqos(intf.arqos),
    .arregion(intf.arregion),
    .aruser(intf.aruser),
    .arvalid(intf.arvalid),
    .arready(intf.arready),
    .rid(intf.rid),
    .rdata(intf.rdata),
    .rresp(intf.rresp),
    .rlast(intf.rlast),
    .ruser(intf.ruser),
    .rvalid(intf.rvalid),
    .rready(intf.rready)
  ); 
  //-------------------------------------------------------
  // AXI4 Slave Driver bfm instantiation
  //-------------------------------------------------------
  axi4_slave_driver_bfm axi4_slave_drv_bfm_h (.aclk     (intf.aclk)     , 
                                              .aresetn  (intf.aresetn)  ,
                                              .awid     (intf.awid)     ,           
                                              .awaddr   (intf.awaddr)   ,  
                                              .awlen    (intf.awlen)    ,   
                                              .awsize   (intf.awsize)   ,  
                                              .awburst  (intf.awburst)  , 
                                              .awlock   (intf.awlock)   ,  
                                              .awcache  (intf.awcache)  , 
                                              .awprot   (intf.awprot)   ,  
                                              .awqos    (intf.awqos)    ,
                                              .awregion (intf.awregion) ,
                                              .awuser   (intf.awuser)   ,
                                              .awvalid  (intf.awvalid)  , 
                                              .awready  (intf.awready)  , 
                                                                            
                                              .wdata    (intf.wdata)    ,   
                                              .wstrb    (intf.wstrb)    ,   
                                              .wlast    (intf.wlast)    ,   
                                              .wuser    (intf.wuser)    ,   
                                              .wvalid   (intf.wvalid)   ,  
                                              .wready   (intf.wready)   ,  
                                                              
                                              .bid      (intf.bid)      ,    
                                              .bresp    (intf.bresp)    ,   
                                              .buser    (intf.buser)    ,   
                                              .bvalid   (intf.bvalid)   ,  
                                              .bready   (intf.bready)   ,  
                                                                            
                                              .arid     (intf.arid)     ,    
                                              .araddr   (intf.araddr)   ,  
                                              .arlen    (intf.arlen)    ,   
                                              .arsize   (intf.arsize)   ,  
                                              .arburst  (intf.arburst)  , 
                                              .arlock   (intf.arlock)   ,  
                                              .arcache  (intf.arcache)  , 
                                              .arprot   (intf.arprot)   ,  
                                              .arqos    (intf.arqos)    ,   
                                              .arregion (intf.arregion) ,
                                              .aruser   (intf.aruser)   ,  
                                              .arvalid  (intf.arvalid)  , 
                                              .arready  (intf.arready)  , 
                                                                            
                                              .rid      (intf.rid)      ,     
                                              .rdata    (intf.rdata)    ,   
                                              .rresp    (intf.rresp)    ,   
                                              .rlast    (intf.rlast)    ,   
                                              .ruser    (intf.ruser)    ,   
                                              .rvalid   (intf.rvalid)   ,  
                                              .rready   (intf.rready)   
                                              );
  
  //-------------------------------------------------------
  // AXI4 Slave monitor  bfm instantiation
  //-------------------------------------------------------
  axi4_slave_monitor_bfm axi4_slave_mon_bfm_h (.aclk(intf.aclk), 
                                               .aresetn(intf.aresetn),
                                               .awid     (intf.awid)     ,           
                                               .awaddr   (intf.awaddr)   ,  
                                               .awlen    (intf.awlen)    ,   
                                               .awsize   (intf.awsize)   ,  
                                               .awburst  (intf.awburst)  , 
                                               .awlock   (intf.awlock)   ,  
                                               .awcache  (intf.awcache)  , 
                                               .awprot   (intf.awprot)   ,  
                                               .awqos    (intf.awqos)    ,
                                               .awregion (intf.awregion) ,
                                               .awuser   (intf.awuser)   ,
                                               .awvalid  (intf.awvalid)  , 
                                               .awready  (intf.awready)  , 
                                                                             
                                               .wdata    (intf.wdata)    ,   
                                               .wstrb    (intf.wstrb)    ,   
                                               .wlast    (intf.wlast)    ,   
                                               .wuser    (intf.wuser)    ,   
                                               .wvalid   (intf.wvalid)   ,  
                                               .wready   (intf.wready)   ,  
                                                               
                                               .bid      (intf.bid)      ,    
                                               .bresp    (intf.bresp)    ,   
                                               .buser    (intf.buser)    ,   
                                               .bvalid   (intf.bvalid)   ,  
                                               .bready   (intf.bready)   ,  
                                                                             
                                               .arid     (intf.arid)     ,    
                                               .araddr   (intf.araddr)   ,  
                                               .arlen    (intf.arlen)    ,   
                                               .arsize   (intf.arsize)   ,  
                                               .arburst  (intf.arburst)  , 
                                               .arlock   (intf.arlock)   ,  
                                               .arcache  (intf.arcache)  , 
                                               .arprot   (intf.arprot)   ,  
                                               .arqos    (intf.arqos)    ,   
                                               .arregion (intf.arregion) ,
                                               .aruser   (intf.aruser)   ,  
                                               .arvalid  (intf.arvalid)  , 
                                               .arready  (intf.arready)  , 
                                                                             
                                               .rid      (intf.rid)      ,     
                                               .rdata    (intf.rdata)    ,   
                                               .rresp    (intf.rresp)    ,   
                                               .rlast    (intf.rlast)    ,   
                                               .ruser    (intf.ruser)    ,   
                                               .rvalid   (intf.rvalid)   ,  
                                               .rready   (intf.rready)   
                                               );


  //-------------------------------------------------------
  // Setting the virtual handle of BMFs into config_db
  //-------------------------------------------------------
  initial begin
    string path;
    path = $sformatf("*axi4_slave_agent_h[%0d]*", SLAVE_ID);
    uvm_config_db#(virtual axi4_slave_driver_bfm)::set(null, path,
                                                     "axi4_slave_driver_bfm",
                                                     axi4_slave_drv_bfm_h);
    uvm_config_db#(virtual axi4_slave_monitor_bfm)::set(null, path,
                                                      "axi4_slave_monitor_bfm",
                                                      axi4_slave_mon_bfm_h);
    // Export the bound assertion interface so the environment can
    // configure parameters such as ready_delay_cycles after build time.
    uvm_config_db#(virtual slave_assertions)::set(null, path,
                                                 "slave_assertions",
                                                 S_A);
  end

  initial begin
    `uvm_info("axi4 slave agent bfm",$sformatf("AXI4 SLAVE AGENT BFM"),UVM_LOW);
  end
   
endmodule : axi4_slave_agent_bfm

`endif

