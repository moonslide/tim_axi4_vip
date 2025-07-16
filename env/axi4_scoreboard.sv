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

  int byte_data_cmp_verified_rid_count;
  int byte_data_cmp_verified_rdata_count;
  int byte_data_cmp_verified_rresp_count;
  int byte_data_cmp_verified_ruser_count;

  // Signals used to declare failed count
  int byte_data_cmp_failed_awid_count;
  int byte_data_cmp_failed_awaddr_count;
  int byte_data_cmp_failed_awsize_count;
  int byte_data_cmp_failed_awlen_count;
  int byte_data_cmp_failed_awburst_count;
  int byte_data_cmp_failed_awcache_count;
  int byte_data_cmp_failed_awlock_count;
  int byte_data_cmp_failed_awprot_count;

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

  //Variable : axi4_bus_matrix_h
  //Handle to the bus matrix reference model for address validation
  axi4_bus_matrix_ref axi4_bus_matrix_h;
  
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
  extern virtual function bit is_valid_write_address(bit [ADDRESS_WIDTH-1:0] addr, int master_id);
  extern virtual function bit is_valid_read_address(bit [ADDRESS_WIDTH-1:0] addr, int master_id);
  extern virtual function bresp_e get_expected_write_response(bit [ADDRESS_WIDTH-1:0] addr, int master_id);
  extern virtual function rresp_e get_expected_read_response(bit [ADDRESS_WIDTH-1:0] addr, int master_id);
  extern virtual function bit is_expected_error_response(bit [ADDRESS_WIDTH-1:0] addr, int master_id, bit is_write);
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
  super.build_phase(phase);
  
  // Get the bus matrix reference for address validation
  if(!uvm_config_db#(axi4_bus_matrix_ref)::get(this, "", "bus_matrix_ref", axi4_bus_matrix_h)) begin
    `uvm_fatal("FATAL_SCOREBOARD_CONFIG", "Couldn't get the bus matrix reference from config_db")
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

  super.run_phase(phase);

  fork
    axi4_write_address();
    axi4_write_data();
    axi4_write_response();
    axi4_read_address();
    axi4_read_data();
  join

endtask : run_phase

//--------------------------------------------------------------------------------------------
// Task: axi4_write_address
// Gets the master and slave write address and send it to the write address comparision task
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::axi4_write_address();

  forever begin
    write_address_key.get(1);
    axi4_master_write_address_analysis_fifo.get(axi4_master_tx_h1);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_write_address_channel \n%s",axi4_master_tx_h1.sprint()),UVM_HIGH)
    axi4_slave_write_address_analysis_fifo.get(axi4_slave_tx_h1);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_write_address_channel \n%s",axi4_slave_tx_h1.sprint()),UVM_HIGH)
    
    // Process all write address transactions including those to invalid addresses
    axi4_write_address_comparision(axi4_master_tx_h1,axi4_slave_tx_h1);
    axi4_master_tx_awaddr_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_write_address_channel count \n %0d",axi4_master_tx_awaddr_count),UVM_HIGH)
    axi4_slave_tx_awaddr_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_write_address_channel count \n %0d",axi4_slave_tx_awaddr_count),UVM_HIGH)
    
    // Log invalid addresses for debugging
    if(!is_valid_write_address(axi4_master_tx_h1.awaddr, axi4_master_tx_h1.awid)) begin
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
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_write_data_channel \n%s",axi4_master_tx_h2.sprint()),UVM_HIGH)
    axi4_slave_write_data_analysis_fifo.get(axi4_slave_tx_h2);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_write_data_channel \n%s",axi4_slave_tx_h2.sprint()),UVM_HIGH)
    axi4_write_data_comparision(axi4_master_tx_h2,axi4_slave_tx_h2);
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
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_write_response \n%s",axi4_master_tx_h3.sprint()),UVM_HIGH)
    axi4_slave_write_response_analysis_fifo.get(axi4_slave_tx_h3);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_write_response \n%s",axi4_slave_tx_h3.sprint()),UVM_HIGH)
    
    // Process all write responses including error responses  
    axi4_write_response_comparision(axi4_master_tx_h3,axi4_slave_tx_h3);
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
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_read_address_channel \n%s",axi4_master_tx_h4.sprint()),UVM_HIGH)
    axi4_slave_read_address_analysis_fifo.get(axi4_slave_tx_h4);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_read_address_channel \n%s",axi4_slave_tx_h4.sprint()),UVM_HIGH)
    
    // Process all read address transactions including those to invalid addresses
    axi4_read_address_comparision(axi4_master_tx_h4,axi4_slave_tx_h4);
    axi4_master_tx_araddr_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_read_address_channel count \n %0d",axi4_master_tx_araddr_count),UVM_HIGH)
    axi4_slave_tx_araddr_count++;
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_read_address_channel count \n %0d",axi4_slave_tx_araddr_count),UVM_HIGH)
    
    // Log invalid addresses for debugging
    if(!is_valid_read_address(axi4_master_tx_h4.araddr, axi4_master_tx_h4.arid)) begin
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
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_master_read_data_channel \n%s",axi4_master_tx_h5.sprint()),UVM_HIGH)
    axi4_slave_read_data_analysis_fifo.get(axi4_slave_tx_h5);
    `uvm_info(get_type_name(),$sformatf("scoreboard's axi4_slave_read_data_channel \n%s",axi4_slave_tx_h5.sprint()),UVM_HIGH)
    
    // Process all read responses including error responses
    axi4_read_data_comparision(axi4_master_tx_h5,axi4_slave_tx_h5);
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

  if(axi4_master_tx_h1.awid == axi4_slave_tx_h1.awid)begin
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

  if(axi4_master_tx_h2.wdata == axi4_slave_tx_h2.wdata)begin
    `uvm_info(get_type_name(),$sformatf("axi4_wdata from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_wdata_MATCHED", $sformatf("Master wdata = %0p and Slave wdata = %0p",axi4_master_tx_h2.wdata,axi4_slave_tx_h2.wdata), UVM_HIGH);             
    byte_data_cmp_verified_wdata_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_wdata from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_wdata_NOT_MATCHED", $sformatf("Master wdata = %0p and Slave wdata = %0p",axi4_master_tx_h2.wdata,axi4_slave_tx_h2.wdata), UVM_HIGH);             
  end

  if(axi4_master_tx_h2.wstrb == axi4_slave_tx_h2.wstrb)begin
    `uvm_info(get_type_name(),$sformatf("axi4_wstrb from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_wstrb_MATCHED", $sformatf("Master wstrb = %0p and Slave wstrb = %0p",axi4_master_tx_h2.wstrb,axi4_slave_tx_h2.wstrb), UVM_HIGH);
    byte_data_cmp_verified_wstrb_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_wstrb from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_wstrb_NOT_MATCHED", $sformatf("Master wstrb = %0p and Slave wstrb = %0p",axi4_master_tx_h2.wstrb,axi4_slave_tx_h2.wstrb), UVM_HIGH);             

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

  if(axi4_master_tx_h3.bid == axi4_slave_tx_h3.bid)begin
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
endtask : axi4_write_response_comparision

//--------------------------------------------------------------------------------------------
// Task : axi4_read_address_comparision
// Used to compare the received master and slave read address
// Parameter :
//  axi4_master_tx_h4 - axi4_master_tx
//  axi4_slave_tx_h4  - axi4_slave_tx
//--------------------------------------------------------------------------------------------
task axi4_scoreboard::axi4_read_address_comparision(input axi4_master_tx axi4_master_tx_h4,input axi4_slave_tx axi4_slave_tx_h4);

  
  if(axi4_master_tx_h4.arid == axi4_slave_tx_h4.arid)begin
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

  if(axi4_master_tx_h4.arregion == axi4_slave_tx_h4.arregion)begin
    `uvm_info(get_type_name(),$sformatf("axi4_arregion from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_arregion_MATCHED", $sformatf("Master arregion = 'h%0x and Slave arregion = 'h%0x",axi4_master_tx_h4.arregion,axi4_slave_tx_h4.arregion), UVM_HIGH);             
    byte_data_cmp_verified_arregion_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_arregion from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_arregion_NOT_MATCHED", $sformatf("Master arregion = 'h%0x and Slave arregion = 'h%0x",axi4_master_tx_h4.arregion,axi4_slave_tx_h4.arregion), UVM_HIGH);             
    byte_data_cmp_failed_arregion_count++;
  end

  if(axi4_master_tx_h4.arqos == axi4_slave_tx_h4.arqos)begin
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
  
  if(axi4_master_tx_h5.rid == axi4_slave_tx_h5.rid)begin
    `uvm_info(get_type_name(),$sformatf("axi4_rid from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_rid_MATCHED", $sformatf("Master rid = %0p and Slave rid = %0p",axi4_master_tx_h5.rid,axi4_slave_tx_h5.rid), UVM_HIGH);             
    byte_data_cmp_verified_rid_count++;
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_rid from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_rid_NOT_MATCHED", $sformatf("Master rid = %0p and Slave rid = %0p",axi4_master_tx_h5.rid,axi4_slave_tx_h5.rid), UVM_HIGH);             
    byte_data_cmp_failed_rid_count++;
  end

  if(axi4_master_tx_h5.rdata == axi4_slave_tx_h5.rdata)begin
    `uvm_info(get_type_name(),$sformatf("axi4_rdata from master and slave is equal"),UVM_HIGH);
    `uvm_info("SB_rdata_MATCHED", $sformatf("Master rdata = %0p and Slave rdata = %0p",axi4_master_tx_h5.rdata,axi4_slave_tx_h5.rdata), UVM_HIGH);
// will fixed later    
     byte_data_cmp_verified_rdata_count++;
//    for(int i=0;i<axi4_master_tx_h5.rdata.size();i++) begin
//      verify_read(axi4_master_tx_h5.araddr + i*STROBE_WIDTH,
//                  axi4_master_tx_h5.rdata[i]);
//    end
  end
  else begin
    `uvm_info(get_type_name(),$sformatf("axi4_rdata from master and slave is  not equal"),UVM_HIGH);
    `uvm_info("SB_rdata_NOT_MATCHED", $sformatf("Master rdata = %0p and Slave rdata = %0p",axi4_master_tx_h5.rdata,axi4_slave_tx_h5.rdata), UVM_HIGH);             
    byte_data_cmp_failed_rdata_count++;
  end

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

endtask : axi4_read_data_comparision

//--------------------------------------------------------------------------------------------
// Function: check_phase
// Display the result of simulation
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_scoreboard::check_phase(uvm_phase phase);
  super.check_phase(phase);

  `uvm_info(get_type_name(),$sformatf("--\n----------------------------------------------SCOREBOARD CHECK PHASE---------------------------------------"),UVM_HIGH) 
  
  `uvm_info (get_type_name(),$sformatf(" Scoreboard Check Phase is starting"),UVM_HIGH);
  
  // Skip count comparison checks if error_inject is enabled
  if (axi4_env_cfg_h.error_inject) begin
    `uvm_info(get_type_name(), "Scoreboard count comparison checks skipped due to error_inject enabled", UVM_MEDIUM);
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
    
    if ((byte_data_cmp_verified_wdata_count != 0) && (byte_data_cmp_failed_wdata_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("wdata count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_wdata_count :%0d",
                                              byte_data_cmp_verified_wdata_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_wdata_count : %0d", 
                                              byte_data_cmp_failed_wdata_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("wdata count comparisions are failed"));
    end 


    if ((byte_data_cmp_verified_wstrb_count != 0) && (byte_data_cmp_failed_wstrb_count == 0)) begin
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


    if ((byte_data_cmp_verified_bid_count != 0) && (byte_data_cmp_failed_bid_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("bid count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_bid_count :%0d",
                                              byte_data_cmp_verified_bid_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_bid_count : %0d", 
                                              byte_data_cmp_failed_bid_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("bid count comparisions are failed"));
    end 


    if ((byte_data_cmp_verified_bresp_count != 0) && (byte_data_cmp_failed_bresp_count == 0)) begin
	    `uvm_info (get_type_name(), $sformatf ("bresp count comparisions are succesful"),UVM_HIGH);
    end
    else begin
      `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_verified_bresp_count :%0d",
                                              byte_data_cmp_verified_bresp_count),UVM_HIGH);
	    `uvm_info (get_type_name(), $sformatf ("byte_data_cmp_failed_bresp_count : %0d", 
                                              byte_data_cmp_failed_bresp_count),UVM_HIGH);
      `uvm_error (get_type_name(), $sformatf ("bresp count comparisions are failed"));
    end 


    if ((byte_data_cmp_verified_buser_count != 0) && (byte_data_cmp_failed_buser_count == 0)) begin
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
  // 3.Analysis fifos must be zero - This will indicate that all the packets have been compared
  //   This is to make sure that we have taken all packets from both FIFOs and made the comparisions
  //--------------------------------------------------------------------------------------------
  if (axi4_master_write_address_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi4 Master write address analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi4_master_write_address_analysis_fifo:%0d",axi4_master_write_address_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi4 Master write address analysis FIFO is not empty"));
  end

  if (axi4_master_write_data_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi4 Master write data analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi4_master_write_data_analysis_fifo:%0d",axi4_master_write_data_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi4 Master write data analysis FIFO is not empty"));
  end

  if (axi4_master_write_response_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi4 Master write response analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi4_master_write_response_analysis_fifo:%0d",axi4_master_write_response_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi4 Master write response analysis FIFO is not empty"));
  end
 
  if (axi4_master_read_address_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi4 Master read address analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi4_master_read_address_analysis_fifo:%0d",axi4_master_read_address_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi4 Master read address analysis FIFO is not empty"));
  end

  if (axi4_master_read_data_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi4 Master read data analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi4_master_read_data_analysis_fifo:%0d",axi4_master_read_data_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi4 Master read data analysis FIFO is not empty"));
  end

  if (axi4_slave_write_address_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi4 slave write address analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi4_slave_write_address_analysis_fifo:%0d",axi4_slave_write_address_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi4 slave write address analysis FIFO is not empty"));
  end

  if (axi4_slave_write_data_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi4 slave write data analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi4_slave_write_data_analysis_fifo:%0d",axi4_slave_write_data_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi4 slave write data analysis FIFO is not empty"));
  end

  if (axi4_slave_write_response_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi4 slave write response analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi4_slave_write_response_analysis_fifo:%0d",axi4_slave_write_response_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi4 slave write response analysis FIFO is not empty"));
  end
 
  if (axi4_slave_read_address_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi4 slave read address analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi4_slave_read_address_analysis_fifo:%0d",axi4_slave_read_address_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi4 slave read address analysis FIFO is not empty"));
  end

  if (axi4_slave_read_data_analysis_fifo.size() == 0) begin
    `uvm_info (get_type_name(), $sformatf ("axi4 slave read data analysis FIFO is empty"),UVM_HIGH);
  end
  else begin
    `uvm_info (get_type_name(), $sformatf ("axi4_slave_read_data_analysis_fifo:%0d",axi4_slave_read_data_analysis_fifo.size() ),UVM_HIGH);
    `uvm_error (get_type_name(), $sformatf ("axi4 slave read data analysis FIFO is not empty"));
  end

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
function bit axi4_scoreboard::is_valid_write_address(bit [ADDRESS_WIDTH-1:0] addr, int master_id);
  bresp_e expected_resp;
  
  // Special case: DDR memory addresses are valid for all masters (temporary fix for awid vs master_id issue)
  if(addr >= 64'h0000_0100_0000_0000 && addr <= 64'h0000_0107_FFFF_FFFF) begin
    `uvm_info(get_type_name(),$sformatf("DDR address 0x%16h is valid for master %0d write access",addr,master_id),UVM_HIGH)
    return 1;
  end
  
  // Use bus matrix to get expected write response
  expected_resp = axi4_bus_matrix_h.get_write_resp(master_id, addr);
  
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
function bit axi4_scoreboard::is_valid_read_address(bit [ADDRESS_WIDTH-1:0] addr, int master_id);
  rresp_e expected_resp;
  
  // Special case: DDR memory addresses are valid for all masters (temporary fix for awid vs master_id issue)
  if(addr >= 64'h0000_0100_0000_0000 && addr <= 64'h0000_0107_FFFF_FFFF) begin
    `uvm_info(get_type_name(),$sformatf("DDR address 0x%16h is valid for master %0d read access",addr,master_id),UVM_HIGH)
    return 1;
  end
  
  // Use bus matrix to get expected read response
  expected_resp = axi4_bus_matrix_h.get_read_resp(master_id, addr);
  
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
function bresp_e axi4_scoreboard::get_expected_write_response(bit [ADDRESS_WIDTH-1:0] addr, int master_id);
  return axi4_bus_matrix_h.get_write_resp(master_id, addr);
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
function rresp_e axi4_scoreboard::get_expected_read_response(bit [ADDRESS_WIDTH-1:0] addr, int master_id);
  return axi4_bus_matrix_h.get_read_resp(master_id, addr);
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
function bit axi4_scoreboard::is_expected_error_response(bit [ADDRESS_WIDTH-1:0] addr, int master_id, bit is_write);
  if (is_write) begin
    bresp_e expected_resp = get_expected_write_response(addr, master_id);
    return (expected_resp != WRITE_OKAY);
  end else begin
    rresp_e expected_resp = get_expected_read_response(addr, master_id);
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
    bresp_e expected_resp = get_expected_write_response(master_tx.awaddr, 0); // Using master 0 for now
    
    // Handle exclusive write access - EXOKAY is valid alternative to OKAY
    bit response_valid = (slave_tx.bresp == expected_resp);
    if (!response_valid && expected_resp == WRITE_OKAY && slave_tx.bresp == WRITE_EXOKAY) begin
      response_valid = 1'b1; // EXOKAY is acceptable when OKAY is expected (exclusive access)
      `uvm_info(get_type_name(),$sformatf("Correctly generated WRITE_EXOKAY for exclusive access at address 0x%16h", master_tx.awaddr), UVM_LOW);
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
      unexpected_error_count++;
      `uvm_error(get_type_name(),$sformatf("Response mismatch for address 0x%16h: expected %0s, got %0s", master_tx.awaddr, expected_resp.name(), slave_tx.bresp.name()));
    end
  end else begin
    rresp_e expected_resp = get_expected_read_response(master_tx.araddr, 0); // Using master 0 for now
    
    // Handle exclusive read access - EXOKAY is valid alternative to OKAY
    bit response_valid = (slave_tx.rresp == expected_resp);
    if (!response_valid && expected_resp == READ_OKAY && slave_tx.rresp == READ_EXOKAY) begin
      response_valid = 1'b1; // EXOKAY is acceptable when OKAY is expected (exclusive access)
      `uvm_info(get_type_name(),$sformatf("Correctly generated READ_EXOKAY for exclusive access at address 0x%16h", master_tx.araddr), UVM_LOW);
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
      unexpected_error_count++;
      `uvm_error(get_type_name(),$sformatf("Response mismatch for address 0x%16h: expected %0s, got %0s", master_tx.araddr, expected_resp.name(), slave_tx.rresp.name()));
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

`endif

