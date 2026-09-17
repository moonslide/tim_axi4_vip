`ifndef AXI4_MASTER_SEQ_ITEM_CONVERTER_INCLUDED_
`define AXI4_MASTER_SEQ_ITEM_CONVERTER_INCLUDED_

//--------------------------------------------------------------------------------------------
// class : axi4 master_seq_item_converter
// Description:
// class converting seq_item transactions into struct data items and viceversa
//--------------------------------------------------------------------------------------------

class axi4_master_seq_item_converter extends uvm_object;
  `uvm_object_utils(axi4_master_seq_item_converter)
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_master_seq_item_converter");
  extern static function void from_write_class(input axi4_master_tx input_conv_h,output axi4_write_transfer_char_s output_conv_h);
  extern static function void from_read_class(input axi4_master_tx input_conv_h,output axi4_read_transfer_char_s output_conv_h);
  extern static function void to_write_class(input axi4_write_transfer_char_s input_conv_h,output axi4_master_tx output_conv_h);
  extern static function void to_read_class(input axi4_read_transfer_char_s input_conv_h,output axi4_master_tx output_conv_h);
  extern static function void to_write_addr_data_class(input axi4_master_tx waddr_packet, input axi4_write_transfer_char_s input_conv_h,output axi4_master_tx output_conv_h);
  extern static function void to_write_addr_data_resp_class(input axi4_master_tx waddr_data_packet, input axi4_write_transfer_char_s input_conv_h,output axi4_master_tx output_conv_h);
  extern static function void to_read_addr_data_class(input axi4_master_tx raddr_packet, input axi4_read_transfer_char_s input_conv_h,output axi4_master_tx output_conv_h);
  extern function void do_print(uvm_printer printer);

endclass : axi4_master_seq_item_converter

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - axi4_master_seq_item_converter
//--------------------------------------------------------------------------------------------
function axi4_master_seq_item_converter::new(string name = "axi4_master_seq_item_converter");
  super.new(name);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: from_write_class
// Converting seq_item transactions into struct data items
//
// Parameters:
// name - axi4_master_tx, axi4_write_transfer_char_s
//--------------------------------------------------------------------------------------------

function void axi4_master_seq_item_converter::from_write_class( input axi4_master_tx input_conv_h, output axi4_write_transfer_char_s output_conv_h);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);
 $cast(output_conv_h.awid,input_conv_h.awid); 
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awid =  %b",output_conv_h.awid),UVM_HIGH);

  $cast(output_conv_h.awlen,input_conv_h.awlen);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awlen =  %b",output_conv_h.awlen),UVM_HIGH);

  $cast(output_conv_h.awsize,input_conv_h.awsize);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After randomizing awsize =  %b",output_conv_h.awsize),UVM_HIGH);

  $cast(output_conv_h.awburst,input_conv_h.awburst); 
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awburst =  %b",output_conv_h.awburst),UVM_HIGH);

  $cast(output_conv_h.awlock,input_conv_h.awlock);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awlock =  %b",output_conv_h.awlock),UVM_HIGH);

  $cast(output_conv_h.awcache,input_conv_h.awcache);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After randomizing awcache =  %b",output_conv_h.awcache),UVM_HIGH);

  $cast(output_conv_h.awprot,input_conv_h.awprot);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After randomizing awprot =  %b",output_conv_h.awprot),UVM_HIGH);

  $cast(output_conv_h.bid,input_conv_h.bid);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting bid =  %b",output_conv_h.bid),UVM_HIGH);

  $cast(output_conv_h.bresp,input_conv_h.bresp);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting bresp =  %b",output_conv_h.bresp),UVM_HIGH);
 
  output_conv_h.buser = input_conv_h.buser;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting buser =  %b",output_conv_h.buser),UVM_HIGH);

  output_conv_h.awaddr = input_conv_h.awaddr;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awaddr =  %0h",output_conv_h.awaddr),UVM_HIGH);

  output_conv_h.awqos = input_conv_h.awqos;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awqos =  %0h",output_conv_h.awqos),UVM_HIGH);

  // class -> struct: copy exactly AWLEN+1 beats. The old `!= 0` filter dropped
  // legitimately-zero beats, so a burst containing zeros was converted short.
  for(int i = 0; i < input_conv_h.wdata.size(); i++) begin
    output_conv_h.wdata[i] = input_conv_h.wdata[i];
    output_conv_h.wstrb[i] = input_conv_h.wstrb[i];
  end

  output_conv_h.wlast = input_conv_h.wlast;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting wlast =  %0h",output_conv_h.wlast),UVM_HIGH);

  output_conv_h.wuser = input_conv_h.wuser;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting wuser =  %0h",output_conv_h.wuser),UVM_HIGH);

  output_conv_h.awuser = input_conv_h.awuser;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awuser =  %0h",output_conv_h.awuser),UVM_HIGH);

  output_conv_h.aw_wait_states = input_conv_h.aw_wait_states;
  output_conv_h.w_wait_states  = input_conv_h.w_wait_states;
  output_conv_h.b_wait_states  = input_conv_h.b_wait_states;


  output_conv_h.wait_count_write_address_channel =input_conv_h.wait_count_write_address_channel ;
  output_conv_h.wait_count_write_data_channel =input_conv_h.wait_count_write_data_channel ;
  output_conv_h.wait_count_write_response_channel =input_conv_h.wait_count_write_response_channel ;

endfunction : from_write_class


//--------------------------------------------------------------------------------------------
// Function: from_read_class
// Converting seq_item transactions into struct data items
//
// Parameters:
// name - axi4_master_tx, axi4_read_transfer_char_s
//--------------------------------------------------------------------------------------------

function void axi4_master_seq_item_converter::from_read_class( input axi4_master_tx input_conv_h, output axi4_read_transfer_char_s output_conv_h);

  $cast(output_conv_h.arid,input_conv_h.arid);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arid =  %b",output_conv_h.arid),UVM_HIGH);

  $cast(output_conv_h.arlen,input_conv_h.arlen);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After conrveting arlen =  %b",output_conv_h.arlen),UVM_HIGH);

  $cast(output_conv_h.arsize,input_conv_h.arsize);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arsize =  %b",output_conv_h.arsize),UVM_HIGH);

  $cast(output_conv_h.arburst,input_conv_h.arburst);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arburst =  %b",output_conv_h.arburst),UVM_HIGH);

  $cast(output_conv_h.arlock,input_conv_h.arlock);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arlock =  %b",output_conv_h.arlock),UVM_HIGH);

  $cast(output_conv_h.arcache,input_conv_h.arcache);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arcache =  %b",output_conv_h.arcache),UVM_HIGH);

  $cast(output_conv_h.arprot,input_conv_h.arprot);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arprot =  %b",output_conv_h.arprot),UVM_HIGH);

  $cast(output_conv_h.rresp,input_conv_h.rresp);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting rresp =  %b",output_conv_h.rresp),UVM_HIGH);
  
  output_conv_h.araddr = input_conv_h.araddr;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting araddr =  %0h",output_conv_h.araddr),UVM_HIGH);

  output_conv_h.arqos = input_conv_h.arqos;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arqos =  %0h",output_conv_h.arqos),UVM_HIGH);

  output_conv_h.aruser = input_conv_h.aruser;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting aruser =  %0h",output_conv_h.aruser),UVM_HIGH);

  output_conv_h.arregion = input_conv_h.arregion;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arregion =  %0h",output_conv_h.arregion),UVM_HIGH);

  $cast(output_conv_h.rid,input_conv_h.rid);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting rid =  %b",output_conv_h.rid),UVM_HIGH);

  // No `!= 0` filter: a zero beat is data, not padding.
  foreach(input_conv_h.rdata[i]) begin
    output_conv_h.rdata[i] = input_conv_h.rdata[i];
  end

  output_conv_h.ruser = input_conv_h.ruser;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting ruser =  %0b",output_conv_h.ruser),UVM_HIGH);

  output_conv_h.ar_wait_states = input_conv_h.ar_wait_states;
  output_conv_h.r_wait_states  = input_conv_h.r_wait_states;
  // BENCH-065 mid-burst RREADY stall request travels to the driver BFM with
  // the rest of the read; the observed-side fields are the monitor's and are
  // carried through untouched so a driver-side round trip stays faithful.
  output_conv_h.r_stall_beat            = input_conv_h.r_stall_beat;
  output_conv_h.r_stall_cycles          = input_conv_h.r_stall_cycles;
  output_conv_h.r_stall_beat_observed   = input_conv_h.r_stall_beat_observed;
  output_conv_h.r_stall_cycles_observed = input_conv_h.r_stall_cycles_observed;

  output_conv_h.wait_count_read_address_channel =input_conv_h.wait_count_read_address_channel ;
  output_conv_h.wait_count_read_data_channel =input_conv_h.wait_count_read_data_channel ;

  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);

endfunction : from_read_class

//--------------------------------------------------------------------------------------------
// Function: to_write_class
// Converting struct data items into seq_item transactions
//
// Parameters:
// name - axi4_master_tx, axi4_write_transfer_char_s
//--------------------------------------------------------------------------------------------
function void axi4_master_seq_item_converter::to_write_class( input axi4_write_transfer_char_s
  input_conv_h, output axi4_master_tx output_conv_h);
  output_conv_h = new();

  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);
 

  output_conv_h.tx_type = WRITE; 

  $cast(output_conv_h.awid,input_conv_h.awid); 
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awid =  %b",output_conv_h.awid),UVM_HIGH);

  $cast(output_conv_h.awlen,input_conv_h.awlen);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awlen =  %b",output_conv_h.awlen),UVM_HIGH);

  $cast(output_conv_h.awsize,input_conv_h.awsize);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After randomizing awsize =  %b",output_conv_h.awsize),UVM_HIGH);

  $cast(output_conv_h.awburst,input_conv_h.awburst); 
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awburst =  %b",output_conv_h.awburst),UVM_HIGH);

  $cast(output_conv_h.awlock,input_conv_h.awlock);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awlock =  %b",output_conv_h.awlock),UVM_HIGH);

  $cast(output_conv_h.awcache,input_conv_h.awcache);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After randomizing awcache =  %b",output_conv_h.awcache),UVM_HIGH);

  $cast(output_conv_h.awprot,input_conv_h.awprot);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After randomizing awprot =  %b",output_conv_h.awprot),UVM_HIGH);

  output_conv_h.awaddr = input_conv_h.awaddr;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awaddr =  %0h",output_conv_h.awaddr),UVM_HIGH);

  output_conv_h.awqos = input_conv_h.awqos;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awqos =  %0h",output_conv_h.awqos),UVM_HIGH);

  output_conv_h.awuser = input_conv_h.awuser;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting awuser =  %0h",output_conv_h.awuser),UVM_HIGH);

  output_conv_h.wait_count_write_address_channel = input_conv_h.wait_count_write_address_channel;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting wait_count_write_address_channel =  %0h",output_conv_h.wait_count_write_address_channel),UVM_HIGH);

  // The measured AWREADY wait states (axi4_master_monitor_bfm, aw_ws) were
  // dropped by every struct -> class converter on this side; only the
  // class -> struct direction carried them. AW_WAIT_STATES_CP therefore read a
  // hard 0 on every monitored packet.
  output_conv_h.aw_wait_states = input_conv_h.aw_wait_states;

  // Copy exactly the beats this burst has, in order.
  //
  // This used to walk all 2**LENGTH struct entries, skip any whose data was 0,
  // and push_front the rest. Three separate defects: push_front REVERSED the
  // beat order, the `!= 0` filter silently DROPPED every legitimately-zero
  // beat, and the beat count came from "how many happened to be non-zero"
  // rather than from AWLEN. The scoreboard's wdata/wstrb comparison could
  // therefore never pass -- and did not, silently, because the mismatch branch
  // was not incrementing its failure counter either.
  output_conv_h.wdata = {};
  output_conv_h.wstrb = {};
  for(int i = 0; i <= int'(input_conv_h.awlen); i++) begin
    output_conv_h.wdata.push_back(input_conv_h.wdata[i]);
    output_conv_h.wstrb.push_back(input_conv_h.wstrb[i]);
    `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting wdata[%0d] = %0h wstrb[%0d] = %0h",i,input_conv_h.wdata[i],i,input_conv_h.wstrb[i]),UVM_HIGH);
  end

  output_conv_h.wlast = input_conv_h.wlast;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting wlast =  %0h",output_conv_h.wlast),UVM_HIGH);

  output_conv_h.wuser = input_conv_h.wuser;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting wuser =  %0h",output_conv_h.wuser),UVM_HIGH);

  output_conv_h.wait_count_write_data_channel = input_conv_h.wait_count_write_data_channel;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting wait_count_write_data_channel =  %0h",output_conv_h.wait_count_write_data_channel),UVM_HIGH);

  $cast(output_conv_h.bid,input_conv_h.bid);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting bid =  %b",output_conv_h.bid),UVM_HIGH);

  $cast(output_conv_h.bresp,input_conv_h.bresp);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting bresp =  %b",output_conv_h.bresp),UVM_HIGH);

  // BUSER travels with BID/BRESP. It was missing from every struct -> class
  // B-channel conversion on the master side, so even once the BFM samples it
  // the value would still be discarded here. Mirrors the slave converter.
  output_conv_h.buser = input_conv_h.buser;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting buser =  %0h",output_conv_h.buser),UVM_HIGH);

  output_conv_h.wait_count_write_response_channel = input_conv_h.wait_count_write_response_channel;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting wait_count_write_response_channel = %0h",output_conv_h.wait_count_write_response_channel),UVM_HIGH);

endfunction : to_write_class

//--------------------------------------------------------------------------------------------
// Function: to_read_class
// Converting struct data items into seq_item transactions
//
// Parameters:
// name - axi4_master_tx, axi4_read_transfer_char_s
//--------------------------------------------------------------------------------------------
function void axi4_master_seq_item_converter::to_read_class( input axi4_read_transfer_char_s
  input_conv_h, output axi4_master_tx output_conv_h);
  bit [1:0] worst_rresp;

  output_conv_h = new();

  $cast(output_conv_h.arid,input_conv_h.arid);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arid =  %b",output_conv_h.arid),UVM_HIGH);

  $cast(output_conv_h.arlen,input_conv_h.arlen);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arlen =  %b",output_conv_h.arlen),UVM_HIGH);

  output_conv_h.araddr = input_conv_h.araddr;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting araddr =  %0h",output_conv_h.araddr),UVM_HIGH);

  output_conv_h.arqos = input_conv_h.arqos;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arqos =  %0h",output_conv_h.arqos),UVM_HIGH);
  // ARREGION was copied only in from_read_class (the DRIVE direction). The two
  // monitor-direction converters dropped it, so the master packet the scoreboard
  // compares always read 0 while the subordinate reported the real pin value.
  output_conv_h.arregion = input_conv_h.arregion;

  $cast(output_conv_h.arsize,input_conv_h.arsize);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arsize =  %b",output_conv_h.arsize),UVM_HIGH);

  $cast(output_conv_h.arburst,input_conv_h.arburst);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arburst =  %b",output_conv_h.arburst),UVM_HIGH);

  $cast(output_conv_h.arlock,input_conv_h.arlock);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arlock =  %b",output_conv_h.arlock),UVM_HIGH);

  $cast(output_conv_h.arcache,input_conv_h.arcache);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arcache =  %b",output_conv_h.arcache),UVM_HIGH);

  $cast(output_conv_h.arprot,input_conv_h.arprot);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting arprot =  %b",output_conv_h.arprot),UVM_HIGH);

  output_conv_h.wait_count_read_address_channel = input_conv_h.wait_count_read_address_channel;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting wait_count_read_address_channel =  %0h",output_conv_h.wait_count_read_address_channel),UVM_HIGH);

  // Wait states were never carried struct -> class (same gap as to_write_class).
  // On the monitor's AR packet ar_wait_states is the measured ARREADY delay and
  // r_wait_states is still 0 (the R phase has not happened yet); on the
  // driver's completed packet both are the values the sequence requested.
  output_conv_h.ar_wait_states = input_conv_h.ar_wait_states;
  output_conv_h.r_wait_states  = input_conv_h.r_wait_states;
  // BENCH-065 fields. On the driver's completed packet these are the request
  // the sequence made (round trip). On the monitor's AR packet the struct is a
  // fresh zero-initialised local, so the request would read as beat 0 -- the
  // -1/"no request" sentinel is restored there; the stamped request reaches
  // the monitor path only on the completed-read packet
  // (axi4_master_monitor_proxy::axi4_read_data).
  output_conv_h.r_stall_beat            = (input_conv_h.r_stall_beat == 0) ? -1 : input_conv_h.r_stall_beat;
  output_conv_h.r_stall_cycles          = input_conv_h.r_stall_cycles;
  output_conv_h.r_stall_beat_observed   = (input_conv_h.r_stall_beat_observed == 0) ? -1 : input_conv_h.r_stall_beat_observed;
  output_conv_h.r_stall_cycles_observed = input_conv_h.r_stall_cycles_observed;

  // Collapse the per-beat RRESP array onto the packet's single rresp using the
  // WORST response in the burst.  The struct field is
  // `bit [2**LENGTH:0][1:0] rresp` -- one entry per beat -- so casting the
  // WHOLE array into a 2-bit enum only ever worked while the monitor wrote
  // just element [0]; once beats 1..N carry their own response the array no
  // longer fits and $cast fails outright (Error-[STASKE_DCF]).  rresp_e is
  // ordered by severity (OKAY 2'b00 < EXOKAY 2'b01 < SLVERR 2'b10 <
  // DECERR 2'b11), so "worst" is the maximum, and every struct->class site
  // collapses identically so master and slave stay comparable.
  worst_rresp = READ_OKAY;
  foreach(input_conv_h.rresp[i]) begin
    if(input_conv_h.rresp[i] > worst_rresp) worst_rresp = input_conv_h.rresp[i];
  end
  $cast(output_conv_h.rresp,worst_rresp);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting rresp =  %b",output_conv_h.rresp),UVM_HIGH);
  
  $cast(output_conv_h.rid,input_conv_h.rid);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting rid =  %b",output_conv_h.rid),UVM_HIGH);

  // Same defect class as the write path: push_front reversed the burst and the
  // `!= 0` filter dropped legitimately-zero beats. Copy ARLEN+1 beats in order.
  output_conv_h.rdata = {};
  for(int b = 0; b <= int'(input_conv_h.arlen); b++) begin
    output_conv_h.rdata.push_back(input_conv_h.rdata[b]);
    `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting rdata[%0d] = %0h",b,input_conv_h.rdata[b]),UVM_HIGH);
  end


  // ARUSER/RUSER were never carried struct -> class here, the exact mirror of the
  // slave-side gap: the scoreboard's AxUSER comparison therefore ran against a
  // hard-coded zero on this side too and could not fail.
  output_conv_h.aruser = input_conv_h.aruser;
  output_conv_h.ruser  = input_conv_h.ruser[0];
  output_conv_h.wait_count_read_data_channel = input_conv_h.wait_count_read_data_channel;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting wait_count_read_data_channel =  %0h",output_conv_h.wait_count_read_data_channel),UVM_HIGH);

  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);
endfunction : to_read_class

//--------------------------------------------------------------------------------------------
// Function: to_write_addr_data_class
// Converting struct data items into seq_item transactions
//
// Parameters:
// name - axi4_master_tx, axi4_write_transfer_char_s
//--------------------------------------------------------------------------------------------
function void axi4_master_seq_item_converter::to_write_addr_data_class(input axi4_master_tx waddr_packet, input axi4_write_transfer_char_s input_conv_h, output axi4_master_tx output_conv_h);
  output_conv_h = new();

  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);
 

  output_conv_h.tx_type = WRITE; 

  $cast(output_conv_h.awid,waddr_packet.awid); 
  $cast(output_conv_h.awlen,waddr_packet.awlen);
  $cast(output_conv_h.awsize,waddr_packet.awsize);
  $cast(output_conv_h.awburst,waddr_packet.awburst); 
  $cast(output_conv_h.awlock,waddr_packet.awlock);
  $cast(output_conv_h.awcache,waddr_packet.awcache);
  $cast(output_conv_h.awprot,waddr_packet.awprot);
  output_conv_h.awaddr = waddr_packet.awaddr;
  output_conv_h.awqos = waddr_packet.awqos;
  output_conv_h.awuser = waddr_packet.awuser;
  // AW delay comes from the carried-forward address packet, W delay from the
  // data-phase struct being converted here (measured for beat 0 by the monitor).
  // BENCH-066: the X-injection descriptor and driver-stamped status ride on
  // the carried-forward address packet (stamped there by
  // axi4_master_monitor_proxy from the driver BFM's request log). This
  // function allocates a fresh object, so they must be copied explicitly or
  // every combined packet reads X_INJ_NONE.
  output_conv_h.x_inject_target        = waddr_packet.x_inject_target;
  output_conv_h.x_inject_cycles        = waddr_packet.x_inject_cycles;
  output_conv_h.x_inject_assert_policy = waddr_packet.x_inject_assert_policy;
  output_conv_h.x_inject_accepted      = waddr_packet.x_inject_accepted;
  output_conv_h.x_inject_started       = waddr_packet.x_inject_started;
  output_conv_h.x_inject_completed     = waddr_packet.x_inject_completed;
  output_conv_h.x_inject_result        = waddr_packet.x_inject_result;
  output_conv_h.x_inject_start_time    = waddr_packet.x_inject_start_time;
  output_conv_h.x_inject_end_time      = waddr_packet.x_inject_end_time;
  output_conv_h.x_inject_cycles_driven = waddr_packet.x_inject_cycles_driven;

  output_conv_h.aw_wait_states = waddr_packet.aw_wait_states;
  output_conv_h.w_wait_states  = input_conv_h.w_wait_states;

  // Copy exactly the beats this burst has, in order.
  //
  // This used to walk all 2**LENGTH struct entries, skip any whose data was 0,
  // and push_front the rest. Three separate defects: push_front REVERSED the
  // beat order, the `!= 0` filter silently DROPPED every legitimately-zero
  // beat, and the beat count came from "how many happened to be non-zero"
  // rather than from AWLEN. The scoreboard's wdata/wstrb comparison could
  // therefore never pass -- and did not, silently, because the mismatch branch
  // was not incrementing its failure counter either.
  output_conv_h.wdata = {};
  output_conv_h.wstrb = {};
  for(int i = 0; i <= int'(waddr_packet.awlen); i++) begin
    output_conv_h.wdata.push_back(input_conv_h.wdata[i]);
    output_conv_h.wstrb.push_back(input_conv_h.wstrb[i]);
    `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting wdata[%0d] = %0h wstrb[%0d] = %0h",i,input_conv_h.wdata[i],i,input_conv_h.wstrb[i]),UVM_HIGH);
  end

  output_conv_h.wlast = input_conv_h.wlast;
  output_conv_h.wuser = input_conv_h.wuser;
  $cast(output_conv_h.bid,input_conv_h.bid);
  $cast(output_conv_h.bresp,input_conv_h.bresp);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting =  %s",output_conv_h.sprint()),UVM_HIGH);

endfunction : to_write_addr_data_class

//--------------------------------------------------------------------------------------------
// Function: to_write_addr_data_resp_class
// Converting struct data items into seq_item transactions
//
// Parameters:
// name - axi4_master_tx, axi4_write_transfer_char_s
//--------------------------------------------------------------------------------------------
function void axi4_master_seq_item_converter::to_write_addr_data_resp_class(input axi4_master_tx waddr_data_packet, input axi4_write_transfer_char_s input_conv_h, output axi4_master_tx output_conv_h);
  output_conv_h = new();

  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);
 

  output_conv_h.tx_type = WRITE; 

  $cast(output_conv_h.awid,waddr_data_packet.awid); 
  $cast(output_conv_h.awlen,waddr_data_packet.awlen);
  $cast(output_conv_h.awsize,waddr_data_packet.awsize);
  $cast(output_conv_h.awburst,waddr_data_packet.awburst); 
  $cast(output_conv_h.awlock,waddr_data_packet.awlock);
  $cast(output_conv_h.awcache,waddr_data_packet.awcache);
  $cast(output_conv_h.awprot,waddr_data_packet.awprot);
  output_conv_h.awaddr = waddr_data_packet.awaddr;
  output_conv_h.awqos = waddr_data_packet.awqos;
  output_conv_h.awuser = waddr_data_packet.awuser;

  // Carry the beats already reconstructed on the address+data packet through
  // to the response packet verbatim. The `!= 0` filter here silently dropped
  // zero beats a second time.
  output_conv_h.wdata = waddr_data_packet.wdata;
  output_conv_h.wstrb = waddr_data_packet.wstrb;

  output_conv_h.wlast = waddr_data_packet.wlast;
  output_conv_h.wuser = waddr_data_packet.wuser;
  $cast(output_conv_h.bid,input_conv_h.bid);
  $cast(output_conv_h.bresp,input_conv_h.bresp);
  // BUSER comes from the RESPONSE struct (this is the B-channel packet), not
  // from the carried-forward address+data packet -- which has no B fields.
  // This allocates a fresh object, so anything not copied here is lost; BUSER
  // was not copied, which is the second half of the always-zero master BUSER.
  output_conv_h.buser = input_conv_h.buser;
  // Same rule for the wait states: AW/W ride on the carried-forward packet,
  // B is measured on this response struct (axi4_master_monitor_bfm, b_ws).
  output_conv_h.aw_wait_states = waddr_data_packet.aw_wait_states;
  output_conv_h.w_wait_states  = waddr_data_packet.w_wait_states;
  output_conv_h.b_wait_states  = input_conv_h.b_wait_states;
  // BENCH-066: the X-injection descriptor and driver-stamped status ride on
  // the carried-forward address+data packet (stamped there by
  // axi4_master_monitor_proxy from the driver BFM's request log). This
  // function allocates a fresh object, so they must be copied explicitly or
  // every combined packet reads X_INJ_NONE.
  output_conv_h.x_inject_target        = waddr_data_packet.x_inject_target;
  output_conv_h.x_inject_cycles        = waddr_data_packet.x_inject_cycles;
  output_conv_h.x_inject_assert_policy = waddr_data_packet.x_inject_assert_policy;
  output_conv_h.x_inject_accepted      = waddr_data_packet.x_inject_accepted;
  output_conv_h.x_inject_started       = waddr_data_packet.x_inject_started;
  output_conv_h.x_inject_completed     = waddr_data_packet.x_inject_completed;
  output_conv_h.x_inject_result        = waddr_data_packet.x_inject_result;
  output_conv_h.x_inject_start_time    = waddr_data_packet.x_inject_start_time;
  output_conv_h.x_inject_end_time      = waddr_data_packet.x_inject_end_time;
  output_conv_h.x_inject_cycles_driven = waddr_data_packet.x_inject_cycles_driven;
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting =  %s",output_conv_h.sprint()),UVM_HIGH);

endfunction : to_write_addr_data_resp_class

//--------------------------------------------------------------------------------------------
// Function: to_read_addr_data_class
// Converting struct data items into seq_item transactions
//
// Parameters:
// name - axi4_master_tx, axi4_read_transfer_char_s
//--------------------------------------------------------------------------------------------
function void axi4_master_seq_item_converter::to_read_addr_data_class(input axi4_master_tx raddr_packet, input axi4_read_transfer_char_s input_conv_h, output axi4_master_tx output_conv_h);
  bit [1:0] worst_rresp;

  output_conv_h = new();

  $cast(output_conv_h.arid,raddr_packet.arid);
  $cast(output_conv_h.arlen,raddr_packet.arlen);
  $cast(output_conv_h.arsize,raddr_packet.arsize);
  $cast(output_conv_h.arburst,raddr_packet.arburst);
  $cast(output_conv_h.arlock,raddr_packet.arlock);
  $cast(output_conv_h.arcache,raddr_packet.arcache);
  $cast(output_conv_h.arprot,raddr_packet.arprot);
  output_conv_h.araddr = raddr_packet.araddr;
  output_conv_h.arqos = raddr_packet.arqos;
  output_conv_h.arregion = raddr_packet.arregion;   // was dropped -- see to_read_class
  $cast(output_conv_h.rid,input_conv_h.rid);

  // Collapse the per-beat RRESP array onto the packet's single rresp using
  // the WORST response seen in the burst.  AXI4 gives every read beat its own
  // RRESP, so a burst can answer OKAY on some beats and SLVERR/DECERR on
  // others; taking the last beat (or bit-casting the whole array, which is the
  // same thing since element [0] holds the low bits) silently dropped an error
  // that did not land on the final beat.  The rresp_e encoding is ordered by
  // severity -- OKAY 2'b00 < EXOKAY 2'b01 < SLVERR 2'b10 < DECERR 2'b11 -- so
  // "worst" is the maximum.  The slave-side converter collapses identically,
  // which is what keeps the scoreboard's master-vs-slave compare valid.
  worst_rresp = READ_OKAY;
  for(int i=0;i<raddr_packet.arlen+1;i++)begin
        output_conv_h.rdata[i] = input_conv_h.rdata[i];
    if(input_conv_h.rresp[i] > worst_rresp) worst_rresp = input_conv_h.rresp[i];
    `uvm_info("axi4_master_seq_item_conv_class",$sformatf("combined read data packet after reading rdata= %0p",output_conv_h.rdata[i]),UVM_FULL);
    end

  $cast(output_conv_h.rresp,worst_rresp);

  // The BFM hands up one COMPLETED burst at a time (axi4_master_monitor_proxy
  // ::axi4_read_data), so this combined packet always represents a burst that
  // ended on RLAST.  axi4_read_transfer_char_s carries no rlast field, and a
  // fresh object defaults it to 0, which silently disabled every rlast-gated
  // consumer -- read SLVERR/DECERR counting and read latency correlation in
  // axi4_performance_metrics.  Mirrors the wlast carried on the write-side
  // response packet in to_write_addr_data_resp_class.
  output_conv_h.rlast = 1'b1;

  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("After converting read_addr_data_packet =  %s",output_conv_h.sprint()),UVM_HIGH);
  `uvm_info("axi4_master_seq_item_conv_class",$sformatf("----------------------------------------------------------------------"),UVM_HIGH);

  // Same gap as to_read_class above: carry ARUSER/RUSER onto the combined packet.
  output_conv_h.aruser = raddr_packet.aruser;
  output_conv_h.ruser  = input_conv_h.ruser[0];

  // Wait states: AR was measured on the address packet, R (beat 0) on the
  // R-phase struct being converted here. Neither was carried before, so the
  // completed-read packet -- the only one on which r_wait_states can be
  // non-zero -- always published 0.
  output_conv_h.ar_wait_states = raddr_packet.ar_wait_states;
  output_conv_h.r_wait_states  = input_conv_h.r_wait_states;
  // BENCH-066: the X-injection descriptor and driver-stamped status ride on
  // the carried-forward read-address packet (stamped there by
  // axi4_master_monitor_proxy from the driver BFM's request log). This
  // function allocates a fresh object, so they must be copied explicitly or
  // every combined packet reads X_INJ_NONE.
  output_conv_h.x_inject_target        = raddr_packet.x_inject_target;
  output_conv_h.x_inject_cycles        = raddr_packet.x_inject_cycles;
  output_conv_h.x_inject_assert_policy = raddr_packet.x_inject_assert_policy;
  output_conv_h.x_inject_accepted      = raddr_packet.x_inject_accepted;
  output_conv_h.x_inject_started       = raddr_packet.x_inject_started;
  output_conv_h.x_inject_completed     = raddr_packet.x_inject_completed;
  output_conv_h.x_inject_result        = raddr_packet.x_inject_result;
  output_conv_h.x_inject_start_time    = raddr_packet.x_inject_start_time;
  output_conv_h.x_inject_end_time      = raddr_packet.x_inject_end_time;
  output_conv_h.x_inject_cycles_driven = raddr_packet.x_inject_cycles_driven;

  // BENCH-065 pin-level witness measured by axi4_master_monitor_bfm on the R
  // phase. A monitor accumulator that never saw an interior stall carries the
  // -1 sentinel the BFM set; a struct that was never routed through the BFM
  // (0) is normalised to the same sentinel. The REQUEST fields stay at the
  // class initializer (-1 / 0) here; axi4_master_monitor_proxy stamps them from
  // the driver BFM's request log right after this conversion.
  output_conv_h.r_stall_beat_observed   = (input_conv_h.r_stall_beat_observed == 0) ? -1 : input_conv_h.r_stall_beat_observed;
  output_conv_h.r_stall_cycles_observed = input_conv_h.r_stall_cycles_observed;

endfunction : to_read_addr_data_class


//--------------------------------------------------------------------------------------------
// Function: do_print method
// Print method can be added to display the data members values
//--------------------------------------------------------------------------------------------
function void axi4_master_seq_item_converter::do_print(uvm_printer printer);

  axi4_write_transfer_char_s axi4_w_st;
  axi4_read_transfer_char_s axi4_r_st;
  super.do_print(printer);
  printer.print_field("awid",axi4_w_st.awid,$bits(axi4_w_st.awid),UVM_DEC);
  printer.print_field("awlen",axi4_w_st.awlen,$bits(axi4_w_st.awlen),UVM_DEC);
  printer.print_field("awsize",axi4_w_st.awsize,$bits(axi4_w_st.awsize),UVM_BIN);
  printer.print_field("awburst",axi4_w_st.awburst,$bits(axi4_w_st.awburst),UVM_BIN);
  printer.print_field("awlock",axi4_w_st.awlock,$bits(axi4_w_st.awlock),UVM_BIN);
  printer.print_field("awcache",axi4_w_st.awcache,$bits(axi4_w_st.awcache),UVM_BIN);
  printer.print_field("awprot",axi4_w_st.awprot,$bits(axi4_w_st.awprot),UVM_DEC);
  printer.print_field("bid",axi4_w_st.bid,$bits(axi4_w_st.bid),UVM_DEC);
  foreach(axi4_w_st.wdata[i]) begin
    printer.print_field($sformatf("wdata[%0d]",i),axi4_w_st.wdata[i],$bits(axi4_w_st.wdata[i]),UVM_HEX);
  end
  foreach(axi4_w_st.wstrb[i]) begin
    printer.print_field($sformatf("wstrb[%0d]",i),axi4_w_st.wstrb[i],$bits(axi4_w_st.wstrb[i]),UVM_HEX);
  end
 
 printer.print_field("arid",axi4_r_st.arid,$bits(axi4_r_st.arid),UVM_DEC);
 printer.print_field("arlen",axi4_r_st.arlen,$bits(axi4_r_st.arlen),UVM_DEC);
 printer.print_field("arsize",axi4_r_st.arsize,$bits(axi4_r_st.arsize),UVM_BIN);
 printer.print_field("arburst",axi4_r_st.arburst,$bits(axi4_r_st.arburst),UVM_BIN);
 printer.print_field("arlock",axi4_r_st.arlock,$bits(axi4_r_st.arlock),UVM_BIN);
 printer.print_field("arcache",axi4_r_st.arcache,$bits(axi4_r_st.arcache),UVM_BIN);
 printer.print_field("arprot",axi4_r_st.arprot,$bits(axi4_r_st.arprot),UVM_DEC);
 printer.print_field("rresp",axi4_r_st.rresp,$bits(axi4_r_st.rresp),UVM_DEC);
 foreach(axi4_r_st.rdata[i]) begin
   printer.print_field($sformatf("rdata[%0d]",i),axi4_r_st.rdata[i],$bits(axi4_r_st.rdata[i]),UVM_HEX);
 end
endfunction : do_print

`endif
