`ifndef AXI4_MASTER_DRIVER_BFM_INCLUDED_
`define AXI4_MASTER_DRIVER_BFM_INCLUDED_

//-------------------------------------------------------
// Importing global package
//-------------------------------------------------------
import axi4_globals_pkg::*;
`include "axi4_bus_config.svh"

//--------------------------------------------------------------------------------------------
// Interface : axi4_master_driver_bfm
//  Used as the HDL driver for axi4
//  It connects with the HVL driver_proxy for driving the stimulus
//--------------------------------------------------------------------------------------------
interface axi4_master_driver_bfm(input bit                      aclk, 
                                 input bit                      aresetn,
                                 //Write Address Channel Signals
                                 output reg               [3:0] awid,
                                 output reg [ADDRESS_WIDTH-1:0] awaddr,
                                 output reg               [7:0] awlen,
                                 output reg               [2:0] awsize,
                                 output reg               [1:0] awburst,
                                 output reg               [1:0] awlock,
                                 output reg               [3:0] awcache,
                                 output reg               [2:0] awprot,
                                 output reg               [3:0] awqos,
                                 output reg               [3:0] awregion,
                                 output reg [`AXI_AWUSER_WIDTH-1:0] awuser,
                                 output reg                     awvalid,
                                 input    	                    awready,
                                 //Write Data Channel Signals
                                 output reg    [DATA_WIDTH-1: 0] wdata,
                                 output reg [(DATA_WIDTH/8)-1:0] wstrb,
                                 output reg                      wlast,
                                 output reg [`AXI_WUSER_WIDTH-1:0] wuser,
                                 output reg                      wvalid,
                                 input                           wready,
                                 //Write Response Channel Signals
                                 input      [3:0] bid,
                                 input      [1:0] bresp,
                                 input      [`AXI_BUSER_WIDTH-1:0] buser,
                                 input            bvalid,
                                 output	reg       bready,
                                 //Read Address Channel Signals
                                 output reg               [3:0] arid,
                                 output reg [ADDRESS_WIDTH-1:0] araddr,
                                 output reg               [7:0] arlen,
                                 output reg               [2:0] arsize,
                                 output reg               [1:0] arburst,
                                 output reg               [1:0] arlock,
                                 output reg               [3:0] arcache,
                                 output reg               [2:0] arprot,
                                 output reg               [3:0] arqos,
                                 output reg               [3:0] arregion,
                                 output reg [`AXI_ARUSER_WIDTH-1:0] aruser,
                                 output reg                     arvalid,
                                 input                          arready,
                                 //Read Data Channel Signals
                                 input                  [3:0] rid,
                                 input      [DATA_WIDTH-1: 0] rdata,
                                 input                  [1:0] rresp,
                                 input                        rlast,
                                 input      [`AXI_RUSER_WIDTH-1:0] ruser,
                                 input                        rvalid,
                                 output	reg                   rready  
                                );  
  
  //-------------------------------------------------------
  // Importing UVM Package 
  //-------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh" 

  //-------------------------------------------------------
  // Importing Global Package
  //-------------------------------------------------------
  import axi4_master_pkg::axi4_master_driver_proxy;

  //Variable: name
  //Used to store the name of the interface
  string name = "AXI4_MASTER_DRIVER_BFM"; 

  //Variable: axi4_master_driver_proxy_h
  //Creating the handle for master driver proxy
  axi4_master_driver_proxy axi4_master_drv_proxy_h;

  // X Injection Control Variables
  bit x_inject_mode = 0;
  bit awvalid_x_inject = 0;
  bit awaddr_x_inject = 0;
  bit wdata_x_inject = 0;
  bit arvalid_x_inject = 0;
  int x_inject_cycles = 0;
  int x_inject_counter = 0;

  initial begin
    `uvm_info(name,$sformatf(name),UVM_LOW)
  end

  //-------------------------------------------------------
  // Task: wait_for_aresetn
  // Waiting for the system reset to be active low
  //-------------------------------------------------------
  task wait_for_aresetn();
    @(negedge aresetn);
    `uvm_info(name,$sformatf("SYSTEM RESET DETECTED"),UVM_HIGH)
    awvalid <= 1'b0;
    wvalid  <= 1'b0;
    bready  <= 1'b0;
    arvalid <= 1'b0;
    rready  <= 1'b0;
    @(posedge aresetn);
    `uvm_info(name,$sformatf("SYSTEM RESET DEACTIVATED"),UVM_HIGH)
  endtask : wait_for_aresetn

  //--------------------------------------------------------------------------------------------
  // Tasks written for all 5 channels in BFM are given below
  //--------------------------------------------------------------------------------------------

  //-------------------------------------------------------
  // Task: axi4_write_address_channel_task
  // This task will drive the write address signals
  //-------------------------------------------------------
task axi4_write_address_channel_task (inout axi4_write_transfer_char_s data_write_packet, axi4_transfer_cfg_s cfg_packet);
    int aw_cycles;
    @(posedge aclk);
    aw_cycles = 0;

    `uvm_info(name,$sformatf("data_write_packet=\n%p",data_write_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("cfg_packet=\n%p",cfg_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("DRIVING_WRITE_ADDRESS_CHANNEL"),UVM_HIGH)
    
    awid     <= data_write_packet.awid;
    awaddr   <= data_write_packet.awaddr;
    awlen    <= data_write_packet.awlen;
    awsize   <= data_write_packet.awsize;
    awburst  <= data_write_packet.awburst;
    awlock   <= data_write_packet.awlock;
    awcache  <= data_write_packet.awcache;
    awprot   <= data_write_packet.awprot;
    awqos    <= data_write_packet.awqos;
    awregion <= data_write_packet.awregion;
    awuser   <= data_write_packet.awuser;
    awvalid  <= 1'b1;
    
    `uvm_info(name,$sformatf("detect_awready = %0d",awready),UVM_HIGH)
    do begin
      @(posedge aclk);
      if(aw_cycles++ > 1000) begin
        //`uvm_error(name,"timeout waiting for awready")
        break;
      end
      data_write_packet.wait_count_write_address_channel++;
    end while(awready !== 1);

    `uvm_info(name,$sformatf("After_loop_of_Detecting_awready = %0d, awvalid = %0d",awready,awvalid),UVM_HIGH)
    awvalid <= 1'b0;

  endtask : axi4_write_address_channel_task

  //-------------------------------------------------------
  // Task: axi4_write_data_channel_task
  // This task will drive the write data signals
  //-------------------------------------------------------
task axi4_write_data_channel_task (inout axi4_write_transfer_char_s data_write_packet, input axi4_transfer_cfg_s cfg_packet);
    int wr_cycles;
    
    `uvm_info(name,$sformatf("data_write_packet=\n%p",data_write_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("cfg_packet=\n%p",cfg_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("DRIVE TO WRITE DATA CHANNEL"),UVM_HIGH)

    @(posedge aclk);

    for(int i=0; i<data_write_packet.awlen + 1; i++) begin
      wdata  <= data_write_packet.wdata[i];
      wstrb  <= data_write_packet.wstrb[i];
      wuser  <= data_write_packet.wuser;
      wlast  <= 1'b0;
      wvalid <= 1'b1;
      `uvm_info(name,$sformatf("DETECT_WRITE_DATA_WAIT_STATE"),UVM_HIGH)
        
      if(data_write_packet.awlen == i)begin  
        wlast  <= 1'b1;
      end

      wr_cycles = 0;
      do begin
        @(posedge aclk);
        if(wr_cycles++ > 50000) begin
          //`uvm_error(name,"timeout waiting for wready")
          break;
        end
      end while(wready===0);
      `uvm_info(name,$sformatf("DEBUG_NA:WDATA[%0d]=%0h",i,data_write_packet.wdata[i]),UVM_HIGH)
    end

    wlast <= 1'b0;
    wvalid<= 1'b0;
    `uvm_info(name,$sformatf("WRITE_DATA_COMP data_write_packet=\n%p",data_write_packet),UVM_HIGH)
  endtask : axi4_write_data_channel_task

  //-------------------------------------------------------
  // Task: axi4_write_response_channel_task
  // This task will drive the write response signals
  //-------------------------------------------------------
task axi4_write_response_channel_task (inout axi4_write_transfer_char_s data_write_packet, input axi4_transfer_cfg_s cfg_packet);
    int bv_cycles;

    `uvm_info(name,$sformatf("WRITE_RESP data_write_packet=\n%p",data_write_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("cfg_packet=\n%p",cfg_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("DRIVE TO WRITE RESPONSE CHANNEL"),UVM_HIGH)
    
    bv_cycles = 0;
    do begin
      @(posedge aclk);
      if(bv_cycles++ > 1000) begin
        //`uvm_error(name,"timeout waiting for bvalid")
        break;
      end
    end while(bvalid !== 1'b1);

    repeat(data_write_packet.b_wait_states)begin
      `uvm_info(name,$sformatf("DRIVING WAIT STATES in write response:: %0d",data_write_packet.b_wait_states),UVM_HIGH);
      @(posedge aclk);
      bready <= 0;
    end

    data_write_packet.bvalid = bvalid;
    data_write_packet.bid    = bid;
    data_write_packet.bresp  = bresp;
    data_write_packet.buser  = buser;
    bready <= 1'b1;

    `uvm_info(name,$sformatf("CHECKING WRITE RESPONSE :: %p",data_write_packet),UVM_HIGH);
    @(posedge aclk);
    bready <= 1'b0;

  endtask : axi4_write_response_channel_task

  //-------------------------------------------------------
  // Task: axi4_read_address_channel_task
  // This task will drive the read address signals
  //-------------------------------------------------------
task axi4_read_address_channel_task (inout axi4_read_transfer_char_s data_read_packet, input axi4_transfer_cfg_s cfg_packet);
    int ar_cycles;
    @(posedge aclk);
    ar_cycles = 0;
    
    `uvm_info(name,$sformatf("data_read_packet=\n%p",data_read_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("cfg_packet=\n%p",cfg_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("DRIVE TO READ ADDRESS CHANNEL"),UVM_HIGH)

    arid     <= data_read_packet.arid;
    araddr   <= data_read_packet.araddr;
    arlen    <= data_read_packet.arlen;
    arsize   <= data_read_packet.arsize;
    arburst  <= data_read_packet.arburst;
    arlock   <= data_read_packet.arlock;
    arcache  <= data_read_packet.arcache;
    arprot   <= data_read_packet.arprot;
    arqos    <= data_read_packet.arqos;
    aruser   <= data_read_packet.aruser;
    arregion <= data_read_packet.arregion;
    arvalid  <= 1'b1;

    `uvm_info(name,$sformatf("detect_awready = %0d",arready),UVM_HIGH)
    do begin
      @(posedge aclk);
      if(ar_cycles++ > 1000) begin
        `uvm_error(name,"timeout waiting for arready")
        break;
      end
      data_read_packet.wait_count_read_address_channel++;
    end while(arready !== 1);

    `uvm_info(name,$sformatf("After_loop_of_Detecting_awready = %0d, awvalid = %0d",awready,awvalid),UVM_HIGH)
    arvalid <= 1'b0;
  endtask : axi4_read_address_channel_task

  //-------------------------------------------------------
  // Task: axi4_read_data_channel_task
  // This task will drive the read data signals
  //-------------------------------------------------------
task axi4_read_data_channel_task (inout axi4_read_transfer_char_s data_read_packet, input axi4_transfer_cfg_s cfg_packet, input bit error_inject = 0);

    reg [7:0]i = 0;  // Changed from static to automatic - each task gets its own copy
    int rv_cycles;
    int rv2_cycles;
    `uvm_info(name,$sformatf("data_read_packet in read data Channel=\n%p",data_read_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("cfg_packet=\n%p",cfg_packet),UVM_HIGH)
    `uvm_info(name,$sformatf("DRIVE TO READ DATA CHANNEL"),UVM_HIGH)
    
    rv_cycles = 0;
    do begin
      @(posedge aclk);
      //Driving rready as low initially
      rready  <= 0;
      if(rv_cycles++ > 50000) begin
        if(error_inject) begin
          `uvm_warning(name,"timeout waiting for rvalid")
        end
        else begin
          `uvm_error(name,"timeout waiting for rvalid")
        end
        break;
      end
    end while(rvalid === 1'b0);
    
    repeat(data_read_packet.r_wait_states)begin
      `uvm_info(name,$sformatf("DRIVING WAIT STATES in read data channel :: %0d",data_read_packet.r_wait_states),UVM_HIGH);
      @(posedge aclk);
    end

    //Driving ready as high
    rready <= 1'b1;

    forever begin
      rv2_cycles = 0;
      do begin
        @(posedge aclk);
        if(rv2_cycles++ > 50000) begin
          if(error_inject) begin
            `uvm_warning(name,"timeout waiting for rvalid")
          end
          else begin
            `uvm_error(name,"timeout waiting for rvalid")
          end
          break;
        end
      end while(rvalid === 1'b0);

      data_read_packet.rid      = rid;
      data_read_packet.rdata[i] = rdata;
      data_read_packet.ruser    = ruser;
      data_read_packet.rresp    = rresp;
      `uvm_info(name,$sformatf("DEBUG_NA:RDATA[%0d]=%0h",i,data_read_packet.rdata[i]),UVM_HIGH)
      
      i++;  

      if(rlast === 1'b1)begin
        i=0;
        break;
      end
    end
   
    @(posedge aclk);
    rready <= 1'b0;

  endtask : axi4_read_data_channel_task

  //-------------------------------------------------------
  // Task: inject_x_on_awvalid
  // Injects X value on AWVALID signal for specified cycles
  //-------------------------------------------------------
  task inject_x_on_awvalid(int cycles);
    `uvm_info(name, $sformatf("Injecting X on AWVALID for %0d cycles", cycles), UVM_MEDIUM)
    
    // Drive X on awvalid
    awvalid <= 1'bx;
    
    // Hold for specified cycles
    repeat(cycles) @(posedge aclk);
    
    // Return to idle state
    awvalid <= 1'b0;
    
    `uvm_info(name, "X injection on AWVALID completed", UVM_MEDIUM)
  endtask : inject_x_on_awvalid

  //-------------------------------------------------------
  // Task: inject_x_on_awaddr
  // Injects X value on AWADDR signal with AWVALID=1
  //-------------------------------------------------------
  task inject_x_on_awaddr(int cycles);
    `uvm_info(name, $sformatf("Injecting X on AWADDR for %0d cycles", cycles), UVM_MEDIUM)
    
    // Set awvalid high with X on address
    awvalid <= 1'b1;
    awaddr <= 'x;
    
    // Hold for specified cycles
    repeat(cycles) @(posedge aclk);
    
    // Return to idle state
    awvalid <= 1'b0;
    awaddr <= '0;
    
    `uvm_info(name, "X injection on AWADDR completed", UVM_MEDIUM)
  endtask : inject_x_on_awaddr

  //-------------------------------------------------------
  // Task: inject_x_on_wdata
  // Injects X value on WDATA signal with WVALID=1
  //-------------------------------------------------------
  task inject_x_on_wdata(int cycles);
    `uvm_info(name, $sformatf("Injecting X on WDATA for %0d cycles", cycles), UVM_MEDIUM)
    
    // Set wvalid high with X on data
    wvalid <= 1'b1;
    wdata <= 'x;
    wstrb <= 'x;
    
    // Hold for specified cycles
    repeat(cycles) @(posedge aclk);
    
    // Return to idle state
    wvalid <= 1'b0;
    wdata <= '0;
    wstrb <= '0;
    
    `uvm_info(name, "X injection on WDATA completed", UVM_MEDIUM)
  endtask : inject_x_on_wdata

  //-------------------------------------------------------
  // Task: inject_x_on_arvalid
  // Injects X value on ARVALID signal for specified cycles
  //-------------------------------------------------------
  task inject_x_on_arvalid(int cycles);
    `uvm_info(name, $sformatf("Injecting X on ARVALID for %0d cycles", cycles), UVM_MEDIUM)
    
    // Drive X on arvalid
    arvalid <= 1'bx;
    
    // Hold for specified cycles
    repeat(cycles) @(posedge aclk);
    
    // Return to idle state
    arvalid <= 1'b0;
    
    `uvm_info(name, "X injection on ARVALID completed", UVM_MEDIUM)
  endtask : inject_x_on_arvalid

  //-------------------------------------------------------
  // Task: inject_x_on_bready
  // Injects X value on BREADY signal for specified cycles
  //-------------------------------------------------------
  task inject_x_on_bready(int cycles);
    `uvm_info(name, $sformatf("Injecting X on BREADY for %0d cycles", cycles), UVM_MEDIUM)
    
    // Drive X on bready
    bready <= 1'bx;
    
    // Hold for specified cycles
    repeat(cycles) @(posedge aclk);
    
    // Return to idle state
    bready <= 1'b0;
    
    `uvm_info(name, "X injection on BREADY completed", UVM_MEDIUM)
  endtask : inject_x_on_bready

  //-------------------------------------------------------
  // Task: inject_x_on_rready
  // Injects X value on RREADY signal for specified cycles
  //-------------------------------------------------------
  task inject_x_on_rready(int cycles);
    `uvm_info(name, $sformatf("Injecting X on RREADY for %0d cycles", cycles), UVM_MEDIUM)
    
    // Drive X on rready
    rready <= 1'bx;
    
    // Hold for specified cycles
    repeat(cycles) @(posedge aclk);
    
    // Return to idle state
    rready <= 1'b0;
    
    `uvm_info(name, "X injection on RREADY completed", UVM_MEDIUM)
  endtask : inject_x_on_rready

  //-------------------------------------------------------
  // Task: set_x_injection_mode
  // Enables/disables X injection mode
  //-------------------------------------------------------
  task set_x_injection_mode(bit enable, string signal_name, int cycles);
    x_inject_mode = enable;
    x_inject_cycles = cycles;
    
    if(enable) begin
      case(signal_name)
        "AWVALID": awvalid_x_inject = 1;
        "AWADDR":  awaddr_x_inject = 1;
        "WDATA":   wdata_x_inject = 1;
        "ARVALID": arvalid_x_inject = 1;
        default: `uvm_error(name, $sformatf("Unknown signal for X injection: %s", signal_name))
      endcase
      `uvm_info(name, $sformatf("X injection enabled for %s, cycles=%0d", signal_name, cycles), UVM_LOW)
    end else begin
      awvalid_x_inject = 0;
      awaddr_x_inject = 0;
      wdata_x_inject = 0;
      arvalid_x_inject = 0;
      `uvm_info(name, "X injection disabled", UVM_LOW)
    end
  endtask : set_x_injection_mode

endinterface : axi4_master_driver_bfm

`endif

