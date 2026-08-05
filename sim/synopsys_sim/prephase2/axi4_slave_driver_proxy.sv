`include "axi4_bus_config.svh"
`ifndef AXI4_SLAVE_DRIVER_PROXY_INCLUDED_
`define AXI4_SLAVE_DRIVER_PROXY_INCLUDED_

import axi4_bus_matrix_pkg::*;

//--------------------------------------------------------------------------------------------
// Class: axi4_slave_driver_proxy
// This is the proxy driver on the HVL side
// It receives the transactions and converts them to task calls for the HDL driver
//--------------------------------------------------------------------------------------------
class axi4_slave_driver_proxy extends uvm_driver#(axi4_slave_tx);
  `uvm_component_utils(axi4_slave_driver_proxy)

  // Port: seq_item_port
  // Derived driver classes should use this port to request items from the sequencer
  // They may also use it to send responses back.
  uvm_seq_item_pull_port #(REQ, RSP) axi_write_seq_item_port;
  uvm_seq_item_pull_port #(REQ, RSP) axi_read_seq_item_port;

  // Port: rsp_port
  // This port provides an alternate way of sending responses back to the originating sequencer.
  // Which port to use depends on which export the sequencer provides for connection.
  uvm_analysis_port #(RSP) axi_write_rsp_port;
  uvm_analysis_port #(RSP) axi_read_rsp_port;
  
  REQ req_wr, req_rd;
  RSP rsp_wr, rsp_rd;

  // Variable: axi4_slave_agent_cfg_h
  // Declaring handle for axi4_slave agent config class 
  axi4_slave_agent_config axi4_slave_agent_cfg_h;

  // Variable: axi4_slave_mem_h
  // Declaring handle for axi4_slave memory config class 
  axi4_slave_memory axi4_slave_mem_h;
  axi4_bus_matrix_ref axi4_bus_matrix_h;

  //Variable : axi4_slave_drv_bfm_h
  //Declaring handle for axi4 driver bfm
  virtual axi4_slave_driver_bfm axi4_slave_drv_bfm_h;

  //Declaring handle for uvm_tlm_analysis_fifo's for all the five channels
  uvm_tlm_fifo #(axi4_slave_tx) axi4_slave_write_addr_fifo_h;
  uvm_tlm_fifo #(axi4_slave_tx) axi4_slave_write_data_in_fifo_h;
  uvm_tlm_fifo #(axi4_slave_tx) axi4_slave_write_response_fifo_h;
  uvm_tlm_fifo #(axi4_slave_tx) axi4_slave_write_data_out_fifo_h;
  uvm_tlm_fifo #(axi4_slave_tx) axi4_slave_read_addr_fifo_h;
  uvm_tlm_fifo #(axi4_slave_tx) axi4_slave_read_data_in_fifo_h;

  //Declaring Semaphore handles for writes and reads
  semaphore semaphore_write_key;
  semaphore semaphore_rsp_write_key;
  semaphore semaphore_read_key;

  //write_read_mode_h used to get the transfer type
  write_read_data_mode_e write_read_mode_h;

  int wr_addr_cnt;
  int wr_resp_cnt;

  // Variables used for out of order support
  bit[`AXI_ID_WIDTH-1:0] response_id_queue[$];
  bit[`AXI_ID_WIDTH-1:0] response_id_cont_queue[$];
  bit      drive_id_cont;
  bit      drive_rd_id_cont;
  axi4_read_transfer_char_s rd_response_id_queue[$];
  axi4_read_transfer_char_s rd_response_id_cont_queue[$];

  bit      completed_initial_txn = 0;
  int      crossed_read_addr=0;

  //Qos mode signals
  axi4_slave_tx  qos_queue[$];
  axi4_slave_tx  qos_read_queue[$];
  int            queue_index;
  bit            qos_wait_enable = 1'b1;
  int            read_queue_index;
  
  // Exclusive Access Monitor - per AMBA AXI4 specification
  typedef struct {
    bit [ADDRESS_WIDTH-1:0] address;
    bit [15:0]              master_id;
    bit [7:0]               size;
    bit [7:0]               len;
    bit                     valid;
  } exclusive_monitor_s;
  
  // Exclusive monitor table - supports multiple monitors per slave
  exclusive_monitor_s exclusive_monitor[16]; // Support up to 16 exclusive monitors
  int num_exclusive_monitors = 0;
  
  
  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "axi4_slave_driver_proxy", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task axi4_write_task();
  extern virtual task axi4_read_task();
  extern virtual task task_memory_write(input axi4_slave_tx struct_write_packet);
  extern virtual task task_memory_read(input axi4_slave_tx read_pkt,ref axi4_read_transfer_char_s struct_read_packet);
  extern virtual task out_of_order_for_reads(output axi4_read_transfer_char_s oor_read_data_struct_read_packet);
  extern virtual function bresp_e mid_safe_write_resp(int mid, bit [ADDRESS_WIDTH-1:0] addr, bit [2:0] awprot);
  extern virtual function rresp_e mid_safe_read_resp (int mid, bit [ADDRESS_WIDTH-1:0] addr, bit [2:0] arprot);
  extern virtual function void setup_exclusive_monitor(bit [ADDRESS_WIDTH-1:0] addr, bit [15:0] master_id, bit [7:0] size, bit [7:0] len);
  extern virtual function bit check_exclusive_monitor(bit [ADDRESS_WIDTH-1:0] addr, bit [15:0] master_id);
  extern virtual function void clear_exclusive_monitors(bit [ADDRESS_WIDTH-1:0] addr);
  extern virtual function void invalidate_all_exclusive_monitors();
endclass : axi4_slave_driver_proxy

//--------------------------------------------------------------------------------------------
// Construct: new
// Parameters:
//  name - axi4_slave_driver_proxy
//  parent - parent under which this component is created
//--------------------------------------------------------------------------------------------
function axi4_slave_driver_proxy::new(string name = "axi4_slave_driver_proxy",
                                      uvm_component parent = null);
  super.new(name, parent);
  axi_write_seq_item_port                   = new("axi_write_seq_item_port", this);
  axi_read_seq_item_port                    = new("axi_read_seq_item_port", this);
  axi_write_rsp_port                        = new("axi_write_rsp_port", this);
  axi_read_rsp_port                         = new("axi_read_rsp_port", this);
  axi4_slave_write_addr_fifo_h              = new("axi4_slave_write_addr_fifo_h",this,16);
  axi4_slave_write_data_in_fifo_h           = new("axi4_slave_write_data_in_fifo_h",this,16);
  axi4_slave_write_response_fifo_h          = new("axi4_slave_write_response_fifo_h",this,16);
  axi4_slave_write_data_out_fifo_h          = new("axi4_slave_write_data_out_fifo_h",this,16);
  axi4_slave_read_addr_fifo_h               = new("axi4_slave_read_addr_fifo_h",this,16);
  axi4_slave_read_data_in_fifo_h            = new("axi4_slave_read_data_in_fifo_h",this,16);
  semaphore_write_key                       = new(1);
  semaphore_rsp_write_key                   = new(1);
  semaphore_read_key                        = new(1);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//
// Parameters:
//  phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_slave_driver_proxy::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db #(virtual axi4_slave_driver_bfm)::get(this,"","axi4_slave_driver_bfm",axi4_slave_drv_bfm_h)) begin
    `uvm_fatal("FATAL_MDP_CANNOT_GET_tx_DRIVER_BFM","cannot get() axi4_slave_drv_bfm_h");
  end
  if(!uvm_config_db#(axi4_bus_matrix_ref)::get(this, "*", "axi4_bus_matrix_gm", axi4_bus_matrix_h)) begin
    `uvm_info("SLAVE_DRIVER_CONFIG", "Bus matrix reference not found in config_db - operating without bus matrix (for tests with bus_matrix_mode=NONE)", UVM_MEDIUM)
    axi4_bus_matrix_h = null;
  end
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
//
// Parameters:
// phase - uvm phase
//--------------------------------------------------------------------------------------------
function void axi4_slave_driver_proxy::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  if(axi4_slave_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE) begin
    axi4_slave_mem_h = axi4_slave_memory::type_id::create("axi4_slave_mem_h");
    
    // Initialize ROM memory content if this is the ROM slave (address range 0x0 - 0x1FFFF)
    if(axi4_slave_agent_cfg_h.min_address == 64'h0000_0000_0000_0000 && 
       axi4_slave_agent_cfg_h.max_address == 64'h0000_0000_0001_FFFF) begin
      // Populate ROM region with basic boot code patterns
      if (axi4_bus_matrix_h != null) begin
        for(bit [ADDRESS_WIDTH-1:0] addr = axi4_slave_agent_cfg_h.min_address; 
            addr <= axi4_slave_agent_cfg_h.max_address; addr += 4) begin
          axi4_bus_matrix_h.store_write(addr, 32'hDEADBEEF); // ROM boot pattern
        end
        `uvm_info("slave_driver_proxy", $sformatf("ROM slave memory initialized from 0x%16h to 0x%16h", 
                 axi4_slave_agent_cfg_h.min_address, axi4_slave_agent_cfg_h.max_address), UVM_LOW)
      end else begin
        `uvm_info("slave_driver_proxy", "No bus matrix - skipping ROM initialization", UVM_MEDIUM)
      end
    end
    
    // In SLAVE_MEM_MODE, reads are independent of writes, so no need to wait
    completed_initial_txn = 1;
    `uvm_info("slave_driver_proxy", "SLAVE_MEM_MODE: Setting completed_initial_txn=1 (reads independent of writes)", UVM_HIGH)
  end
  axi4_slave_drv_bfm_h.axi4_slave_drv_proxy_h= this;
endfunction  : end_of_elaboration_phase


//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task axi4_slave_driver_proxy::run_phase(uvm_phase phase);

  `uvm_info(get_type_name(),$sformatf("SLAVE_DRIVER_PROXY starting, bus_matrix_h=%p", axi4_bus_matrix_h),UVM_MEDIUM)

  //wait for system reset
  axi4_slave_drv_bfm_h.wait_for_system_reset();

  fork 
    axi4_write_task();
    axi4_read_task();
  join


endtask : run_phase 

//--------------------------------------------------------------------------------------------
// task axi4 write task
//--------------------------------------------------------------------------------------------
task axi4_slave_driver_proxy::axi4_write_task();
  
  forever begin
    
    process addr_tx;
    process data_tx;
    process response_tx;

    // In SLAVE_MEM_MODE, don't wait for sequencer transactions - be reactive to BFM signals
    if(axi4_slave_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE) begin
      // Create transaction immediately - BFM will handle signal waiting
      // In SLAVE_MEM_MODE, create a dummy transaction for the BFM to fill with real signal data
      req_wr = axi4_slave_tx::type_id::create("req_wr");
      // Initialize with default values - BFM will fill with actual sampled values
      // Use simple randomization without constraints
      if(!req_wr.randomize() with {
        aw_wait_states == 0;
        w_wait_states == 0;
        b_wait_states == 0;
        ar_wait_states == 0;
        r_wait_states == 0;
      }) begin
        `uvm_info("SLAVE_DRIVER_PROXY", "Randomization failed, using default values", UVM_LOW)
      end
      // Put dummy transaction into FIFOs for processing
      axi4_slave_write_data_in_fifo_h.put(req_wr);
      axi4_slave_write_response_fifo_h.put(req_wr);
    end else begin
      // Normal mode - get transaction from sequencer
      axi_write_seq_item_port.get_next_item(req_wr);
      // writting the req into write data and response fifo's
      axi4_slave_write_data_in_fifo_h.put(req_wr);
      axi4_slave_write_response_fifo_h.put(req_wr);
    end
    
    // Keep threads active in all modes - in SLAVE_MEM_MODE they will be reactive to BFM signals
    fork
      begin : WRITE_ADDRESS_CHANNEL
      
      axi4_slave_tx              local_slave_addr_tx;
      axi4_write_transfer_char_s struct_write_packet;
      axi4_transfer_cfg_s        struct_cfg;
      bit[`AXI_ID_WIDTH-1:0]     local_awid;
    
      //returns status of address thread
      addr_tx=process::self();
      

      //Converting transactions into struct data type
      axi4_slave_seq_item_converter::from_write_class(req_wr,struct_write_packet);
      `uvm_info(get_type_name(), $sformatf("from_write_class:: struct_write_packet = \n %0p",struct_write_packet), UVM_HIGH); 

     //Converting configurations into struct config type
     axi4_slave_cfg_converter::from_class(axi4_slave_agent_cfg_h,struct_cfg);
     `uvm_info(get_type_name(), $sformatf("from_write_class:: struct_cfg =  \n %0p",struct_cfg),UVM_HIGH);
     
     //write address_task - BFM will wait for and sample real signals, updating struct with real data
     axi4_slave_drv_bfm_h.axi4_write_address_phase(struct_write_packet);

     if(axi4_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER || axi4_slave_agent_cfg_h.slave_response_mode == ONLY_WRITE_RESP_OUT_OF_ORDER) begin
       if(response_id_queue.size() == 0) begin
         response_id_queue.push_back(struct_write_packet.awid);
       end
       else begin
         // condition to check if the same id's are coming back to back
         if(struct_write_packet.awid == response_id_queue[$]) begin
           drive_id_cont = 1'b1;
           local_awid = response_id_queue.pop_back();
           response_id_cont_queue.push_back(local_awid);
           response_id_cont_queue.push_back(struct_write_packet.awid);
         end
         else begin
           response_id_queue.push_back(struct_write_packet.awid);
         end
       end
     end

     //Converting struct into transaction data type
     axi4_slave_seq_item_converter::to_write_class(struct_write_packet,local_slave_addr_tx);

     if((axi4_slave_agent_cfg_h.qos_mode_type == ONLY_WRITE_QOS_MODE_ENABLE) || (axi4_slave_agent_cfg_h.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE)) begin
        qos_queue.push_front(local_slave_addr_tx);
      end
     
     `uvm_info("DEBUG_SLAVE_WRITE_ADDR_PROXY", $sformatf("AFTER :: Received req packet \n %s",local_slave_addr_tx.sprint()), UVM_NONE);
     
     // putting write address data into address fifo
     if(axi4_slave_write_addr_fifo_h.is_full) begin
       `uvm_error(get_type_name(),$sformatf("WRITE_ADDR_THREAD::Cannot put into FIFO as WRITE_FIFO is FULL"));
     end
     else begin
       axi4_slave_write_addr_fifo_h.put(local_slave_addr_tx);
     end
     wr_addr_cnt++;
   
   end
 
  begin : WRITE_DATA_CHANNEL

      axi4_slave_tx              local_slave_data_tx;
      axi4_write_transfer_char_s struct_write_packet;
      axi4_transfer_cfg_s        struct_cfg;
      
      //returns status of write data thread
      data_tx=process::self();

      // Trying to get the write key 
      semaphore_write_key.get(1);

      //getting the data from write data fifo
      axi4_slave_write_data_in_fifo_h.get(local_slave_data_tx);
      
      //Converting transactions into struct data type
      axi4_slave_seq_item_converter::from_write_class(local_slave_data_tx,struct_write_packet);
      `uvm_info(get_type_name(), $sformatf("from_write_class:: struct_write_packet = \n %0p",struct_write_packet), UVM_HIGH); 

      //Converting configurations into struct config type
      axi4_slave_cfg_converter::from_class(axi4_slave_agent_cfg_h,struct_cfg);
      `uvm_info(get_type_name(), $sformatf("from_write_class:: struct_cfg =  \n %0p",struct_cfg),UVM_HIGH);

      // write data_task
      axi4_slave_drv_bfm_h.axi4_write_data_phase(struct_write_packet,struct_cfg);
      `uvm_info("DEBUG_SLAVE_WDATA_PROXY", $sformatf("AFTER :: Reciving struct pkt from bfm \n%p",struct_write_packet), UVM_HIGH);
     
      
      //Converting struct into transaction data type
      axi4_slave_seq_item_converter::to_write_class(struct_write_packet,local_slave_data_tx);


     `uvm_info("DEBUG_SLAVE_WDATA_PROXY_TO_CLASS", $sformatf("AFTER TO CLASS :: Received req packet \n %s", local_slave_data_tx.sprint()), UVM_NONE);

     //putting the write data into write data out fifo 
      axi4_slave_write_data_out_fifo_h.put(local_slave_data_tx);

      //putting back the semaphore key
      semaphore_write_key.put(1);

    end

  begin : WRITE_RESPONSE_CHANNEL

      axi4_slave_tx              local_slave_addr_tx;
      axi4_slave_tx              local_slave_data_tx;
      axi4_slave_tx              local_slave_response_tx;
      axi4_slave_tx              packet;
      axi4_slave_tx              qos_value_check_1;
      axi4_write_transfer_char_s struct_write_packet;
      axi4_transfer_cfg_s        struct_cfg;
      bit[`AXI_ID_WIDTH-1:0]     bid_local;   // Track-B: must follow AXI_ID_WIDTH
      bit [ADDRESS_WIDTH-1:0]    end_wrap_addr;
      bit                        slave_err;
      int                        start_sid;
      int                        end_sid;
      int                        wait_cycles;
      bit [1:0]                  original_bresp;
      
      //returns status of response thread
      response_tx=process::self();

      data_tx.await();

      //getting the key from semaphore
      semaphore_rsp_write_key.get(1);

      if((axi4_slave_agent_cfg_h.qos_mode_type == ONLY_WRITE_QOS_MODE_ENABLE) || (axi4_slave_agent_cfg_h.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE)) begin
        // qos_queue is filled by WRITE_ADDRESS_CHANNEL, but this thread only
        // awaits WRITE_DATA_CHANNEL. AXI permits the write data phase to finish
        // before the write address phase, so the queue can legitimately still be
        // empty here. Unguarded, `qos_queue[$]` yielded null and
        // `qos_queue.delete(queue_index)` then aborted the simulation with
        // "DT-MCWII ... delete method called with invalid index (size:0, index:0)"
        // -- reproduced with axi4_qos_basic_priority_test +BUS_MATRIX_MODE=ENHANCED.
        // `queue_index` is also a class member, so a stale value from a previous
        // response survived into this one; seed it here instead.
        wait(qos_queue.size() > 0);
        queue_index       = 0;
        qos_value_check_1 = qos_queue[0];
        for(int i=0;i<qos_queue.size();i++) begin
          if(qos_queue[i].awqos >= qos_value_check_1.awqos) begin
            qos_value_check_1 = qos_queue[i];
            queue_index = i;
          end
        end
        local_slave_response_tx = qos_queue[queue_index];
        qos_queue.delete(queue_index);
      end
      else begin 
        if(axi4_slave_write_response_fifo_h.is_empty) begin
          `uvm_error(get_type_name(),$sformatf("WRITE_RESP_THREAD::Cannot get write resp data from FIFO as WRITE_RESP_FIFO is EMPTY"));
        end
        else begin
          //getting the data from response fifo
          axi4_slave_write_response_fifo_h.get(local_slave_response_tx);
        end
      end

      
      //Converting transactions into struct data type
      axi4_slave_seq_item_converter::from_write_class(local_slave_response_tx,struct_write_packet);
      `uvm_info(get_type_name(), $sformatf("from_write_class:: struct_write_packet = \n %0p",struct_write_packet), UVM_HIGH);
      
      // Store the original bresp to preserve user-defined response in SLAVE_MEM_MODE
      original_bresp = struct_write_packet.bresp; 

      //Converting configurations into struct config type
      axi4_slave_cfg_converter::from_class(axi4_slave_agent_cfg_h,struct_cfg);
      `uvm_info(get_type_name(), $sformatf("from_write_class:: struct_cfg =  \n %0p",struct_cfg),UVM_HIGH);

      //check for fifo empty if not get the data 
      if((axi4_slave_agent_cfg_h.qos_mode_type == ONLY_WRITE_QOS_MODE_ENABLE) || (axi4_slave_agent_cfg_h.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE)) begin
        local_slave_addr_tx = local_slave_response_tx;
        struct_write_packet.bid = awid_queue_for_qos.pop_front();
        
        // In SLAVE_MEM_MODE with QoS, we need to get the actual address from the write_addr_fifo
        // The QoS queue transaction may have dummy/randomized addresses
        if(axi4_slave_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE) begin
          axi4_slave_tx actual_addr_tx;
          if(!axi4_slave_write_addr_fifo_h.is_empty) begin
            axi4_slave_write_addr_fifo_h.get(actual_addr_tx);
            // Copy the actual address to our transaction
            local_slave_addr_tx.awaddr = actual_addr_tx.awaddr;
            local_slave_addr_tx.awlen = actual_addr_tx.awlen;
            local_slave_addr_tx.awsize = actual_addr_tx.awsize;
            local_slave_addr_tx.awburst = actual_addr_tx.awburst;
            local_slave_addr_tx.awlock = actual_addr_tx.awlock;
            local_slave_addr_tx.awid = actual_addr_tx.awid;
            local_slave_addr_tx.awprot = actual_addr_tx.awprot;
            `uvm_info("SLAVE_MEM_QOS_DEBUG", $sformatf("Using actual address 0x%16h from BFM instead of QoS queue addr", actual_addr_tx.awaddr), UVM_LOW);
          end else begin
            `uvm_error(get_type_name(), "SLAVE_MEM_MODE with QoS: Write address FIFO is empty - cannot get actual address");
          end
        end
      end
      else begin
        if(axi4_slave_write_addr_fifo_h.is_empty) begin
          `uvm_info("DEBUG_FIFO",$sformatf("fifo_size = %0d",axi4_slave_write_addr_fifo_h.size()),UVM_HIGH)
          // In out-of-order mode, it's normal for FIFO to be temporarily empty
          if(axi4_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER || 
             axi4_slave_agent_cfg_h.slave_response_mode == ONLY_WRITE_RESP_OUT_OF_ORDER) begin
            `uvm_info(get_type_name(),$sformatf("WRITE_RESP_THREAD::Waiting for write addr data in out-of-order mode"),UVM_MEDIUM);
          end else begin
            `uvm_info(get_type_name(),$sformatf("WRITE_RESP_THREAD::Waiting for write addr data in in-order mode"),UVM_MEDIUM);
          end
          wait_cycles = 0;
          while(axi4_slave_write_addr_fifo_h.is_empty) begin
            @(posedge axi4_slave_drv_bfm_h.aclk);
            if(wait_cycles++ > 50000) begin
              `uvm_error(get_type_name(),"WRITE_RESP_THREAD::Timeout waiting for write addr data - FIFO remained empty");
              break;
            end
          end
        end
        if(!axi4_slave_write_addr_fifo_h.is_empty) begin
          axi4_slave_write_addr_fifo_h.get(local_slave_addr_tx);
          `uvm_info("DEBUG_FIFO",$sformatf("fifo_size = %0d",axi4_slave_write_addr_fifo_h.size()),UVM_HIGH)
          `uvm_info("DEBUG_FIFO",$sformatf("fifo_used =%0d",axi4_slave_write_addr_fifo_h.used()),UVM_HIGH)
        end
      end

      if(local_slave_addr_tx.awburst == WRITE_FIXED) begin
        end_wrap_addr =  local_slave_addr_tx.awaddr + ((2**local_slave_addr_tx.awsize)) - 1;
      end
      if(local_slave_addr_tx.awburst == WRITE_INCR) begin
        end_wrap_addr =  local_slave_addr_tx.awaddr + ((local_slave_addr_tx.awlen+1)*(2**local_slave_addr_tx.awsize)) - 1;
      end
      if(local_slave_addr_tx.awburst == WRITE_WRAP) begin
         end_wrap_addr = local_slave_addr_tx.awaddr - int'(local_slave_addr_tx.awaddr%((local_slave_addr_tx.awlen+1)*(2**local_slave_addr_tx.awsize)));
         end_wrap_addr = end_wrap_addr + ((local_slave_addr_tx.awlen+1)*(2**local_slave_addr_tx.awsize)) - 1;
      end

      // Determine the response for the entire burst. If any address in the
      // burst falls outside the allowed region, the transaction should fail.
      if (axi4_bus_matrix_h != null) begin
        start_sid = axi4_bus_matrix_h.decode(local_slave_addr_tx.awaddr);
        end_sid   = axi4_bus_matrix_h.decode(end_wrap_addr);
      end else begin
        // No bus matrix - assume this slave handles all addresses directed to it
        start_sid = axi4_slave_agent_cfg_h.slave_id;
        end_sid = axi4_slave_agent_cfg_h.slave_id;
      end

      `uvm_info("SLAVE_DRIVER_BOUNDARY_DEBUG", $sformatf("Address 0x%16h: end_wrap_addr=0x%16h, start_sid=%0d, end_sid=%0d", 
               local_slave_addr_tx.awaddr, end_wrap_addr, start_sid, end_sid), UVM_LOW);

      if(start_sid != end_sid || start_sid < 0 || end_sid < 0) begin
        `uvm_info("SLAVE_DRIVER_BOUNDARY_DEBUG", $sformatf("Setting WRITE_DECERR for addr 0x%16h: start_sid=%0d, end_sid=%0d", 
                 local_slave_addr_tx.awaddr, start_sid, end_sid), UVM_LOW);
        struct_write_packet.bresp = WRITE_DECERR;
      end else begin
        // Handle exclusive write access according to AMBA AXI4 specification
        if(local_slave_addr_tx.awlock == WRITE_EXCLUSIVE_ACCESS) begin
          // Check if this exclusive write should succeed
          if(check_exclusive_monitor(local_slave_addr_tx.awaddr, local_slave_addr_tx.awid)) begin
            struct_write_packet.bresp = WRITE_EXOKAY; // Exclusive access succeeded
            `uvm_info("EXCLUSIVE_ACCESS", $sformatf("Exclusive write SUCCESS at 0x%16h for master ID %0d - returning EXOKAY", 
                     local_slave_addr_tx.awaddr, local_slave_addr_tx.awid), UVM_LOW);
            // Clear exclusive monitors for this address after successful exclusive write
            clear_exclusive_monitors(local_slave_addr_tx.awaddr);
          end else begin
            struct_write_packet.bresp = WRITE_OKAY; // Exclusive access failed, but write completes normally
            `uvm_info("EXCLUSIVE_ACCESS", $sformatf("Exclusive write FAILED at 0x%16h for master ID %0d - returning OKAY", 
                     local_slave_addr_tx.awaddr, local_slave_addr_tx.awid), UVM_LOW);
          end
          
          // Clear any other monitors that may overlap with this write (per AXI4 spec)
          clear_exclusive_monitors(local_slave_addr_tx.awaddr);
        end else begin
          // Normal write - check bus matrix and clear any exclusive monitors for this address
          // Extract master_id from AWID value
          // TC046 uses AWID = master_id * 4, so we need to divide by 4
          // For general case, assume lower bits of AWID contain master ID
          int master_id = 0;
          int awid_value = int'(local_slave_addr_tx.awid);
          
          // Extract master ID from AWID - assume master ID is encoded in lower bits
          // Common patterns: 
          // - Direct mapping: AWID 0->M0, AWID 1->M1, etc.
          // Use modulo mapping based on actual bus matrix configuration
          // Check bus matrix mode and use appropriate modulo
          // The bus matrix wants the SOURCE MASTER, and the scoreboard now derives
          // that from the monitor's source-port stamp. The two must agree or the
          // slave's response and the scoreboard's expectation are computed against
          // different rows of the access matrix. With the 1:1 direct wiring
          // (top/hdl_top.sv connects master[j] to slave[j]) this agent's own
          // slave_id IS the source master. Behind the NIC-400 fabric it is not,
          // and the egress AxID carries the ingress port instead, so the historical
          // AxID rule is kept there.
          `ifdef BUS_MATRIX_FABRIC_IP
            // The fabric's egress AxID is {original AxID, ingress-port index} with the
            // port in the LOW AXI_ID_WIDTH-AXI_VID_WIDTH bits, so the requesting master
            // is decodable here rather than guessed. `AxID % nports` was a guess: it is
            // only right when the manager happens to drive an AxID equal to its own port
            // index, and disagreed with the scoreboard (which uses the monitor's source
            // stamp) the moment a sweep drove arbitrary IDs -- measured 75 'Response
            // mismatch' errors, in both directions, on the coverage sweep.
            // Manager identity is carried EXPLICITLY in AxUSER behind the fabric
            // (AXI4_MID_TAG, include/axi4_bus_config.svh). Deriving it from the egress
            // AxID was wrong: that field is a per-sub-block REVERSED permutation of the
            // ingress port index on the 10x10 build -- measured 960/960 reads attributed
            // to the wrong access-matrix row. Untagged traffic falls back to the old rule.
            if (((local_slave_addr_tx.awuser) & `AXI4_MID_TAG_MASK) == {`AXI4_MID_TAG, 4'h0})
              master_id = int'((local_slave_addr_tx.awuser) & 32'hF);
            else
              // No AXI4_MID_TAG in AxUSER: this is not fabric traffic that carries manager
              // identity, and the egress AxID is a reversed permutation of the ingress port
              // index (measured), so deriving an id from it attributes the access to the
              // wrong access-matrix row and denies legal in-range transfers. Mark the
              // manager UNKNOWN and let the scoreboard -- which has the true master port --
              // own the permission check.
              master_id = -1;
          `else
            master_id = axi4_slave_agent_cfg_h.slave_id;
          `endif
          
          if (axi4_bus_matrix_h != null) begin
            // AWPROT must come from the SAME packet as the address. It was taken
            // from struct_write_packet, which in SLAVE_MEM_MODE is the reactive
            // dummy the proxy randomizes -- an unrelated, random AWPROT. The
            // address was already read from local_slave_addr_tx; the protection
            // attribute has to be too, or the access matrix is queried with one
            // transaction's address and another's security attributes.
            struct_write_packet.bresp = mid_safe_write_resp(master_id,
                                                                         local_slave_addr_tx.awaddr,
                                                                         local_slave_addr_tx.awprot);
            `uvm_info("SLAVE_DRIVER_BOUNDARY_DEBUG", $sformatf("Bus matrix returned bresp=%0d for addr 0x%16h", 
                     struct_write_packet.bresp, local_slave_addr_tx.awaddr), UVM_LOW);
          end else begin
            // No bus matrix - default to WRITE_OKAY for normal writes
            struct_write_packet.bresp = WRITE_OKAY;
            `uvm_info("SLAVE_DRIVER_BOUNDARY_DEBUG", $sformatf("No bus matrix - returning default bresp=%0d for addr 0x%16h", 
                     struct_write_packet.bresp, local_slave_addr_tx.awaddr), UVM_LOW);
          end
          
          // Normal write invalidates exclusive monitors at overlapping addresses (per AXI4 spec)
          clear_exclusive_monitors(local_slave_addr_tx.awaddr);
        end
      end
      
      // In SLAVE_MEM_MODE, we should always use the bus matrix calculated response
      // The original dummy transaction's response should be ignored
      if (axi4_slave_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE && 
          original_bresp != struct_write_packet.bresp) begin
        `uvm_info("SLAVE_DRIVER_DEBUG", $sformatf("SLAVE_MEM_MODE: Using bus matrix bresp=%0d instead of original bresp=%0d for addr 0x%16h", 
                 struct_write_packet.bresp, original_bresp, local_slave_addr_tx.awaddr), UVM_LOW);
      end
      
      slave_err = (struct_write_packet.bresp != WRITE_OKAY && struct_write_packet.bresp != WRITE_EXOKAY);

      `uvm_info("slave_driver_proxy",$sformatf("min_tx=%0d",axi4_slave_agent_cfg_h.get_minimum_transactions),UVM_HIGH)
      if(axi4_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER || axi4_slave_agent_cfg_h.slave_response_mode == ONLY_WRITE_RESP_OUT_OF_ORDER) begin
        // Skip wait loop if minimum_transactions is 0 (configured for out-of-order mode)
        if(axi4_slave_agent_cfg_h.get_minimum_transactions > 0) begin
          wait_cycles = 0;
          while(axi4_slave_write_data_out_fifo_h.size > axi4_slave_agent_cfg_h.get_minimum_transactions) begin
            @(posedge axi4_slave_drv_bfm_h.aclk);
            if(wait_cycles++ > 50000) begin
              `uvm_error("slave_driver_proxy","write response wait timeout")
              break;
            end
          end
        end
          `uvm_info("slave_driver_proxy",$sformatf("fifo_size = %0d",axi4_slave_write_data_out_fifo_h.used()),UVM_HIGH)
          if(drive_id_cont == 1) begin
            bid_local = response_id_cont_queue.pop_front(); 
            `uvm_info("slave_driver_proxy",$sformatf("bid_local = %0d",bid_local),UVM_HIGH)
            `uvm_info("slave_driver_proxy",$sformatf("drive_id_cont = %0d",drive_id_cont),UVM_HIGH)
            if(response_id_cont_queue.size()==0) drive_id_cont = 1'b0;
          end
          else begin
            response_id_queue.shuffle();
            bid_local = response_id_queue.pop_front(); 
            `uvm_info("slave_driver_proxy",$sformatf("bid_local = %0d",bid_local),UVM_HIGH)
          end
          slave_err = (struct_write_packet.bresp != WRITE_OKAY);
          // write response_task
          axi4_slave_drv_bfm_h.axi4_write_response_phase(struct_write_packet,struct_cfg,bid_local);
          `uvm_info("DEBUG_SLAVE_WDATA_PROXY", $sformatf("AFTER :: Reciving struct pkt from bfm \n %p",struct_write_packet), UVM_HIGH);
      //  end
      end
      else begin
       slave_err = (struct_write_packet.bresp != WRITE_OKAY);
        // write response_task
        axi4_slave_drv_bfm_h.axi4_write_response_phase(struct_write_packet,struct_cfg,bid_local);
        `uvm_info("DEBUG_SLAVE_WDATA_PROXY", $sformatf("AFTER :: Reciving struct pkt from bfm \n %p",struct_write_packet), UVM_HIGH);
      end

      //Converting struct into transaction data type
      axi4_slave_seq_item_converter::to_write_class(struct_write_packet,local_slave_response_tx);

     `uvm_info("DEBUG_SLAVE_WDATA_PROXY_TO_CLASS", $sformatf("AFTER TO CLASS :: Received req packet \n %s", local_slave_response_tx.sprint()), UVM_NONE);
     

      axi4_slave_write_data_out_fifo_h.get(local_slave_data_tx);

     //Calling combined data packet from converter class
     axi4_slave_seq_item_converter::tx_write_packet(local_slave_addr_tx,local_slave_data_tx,local_slave_response_tx,packet);
     `uvm_info("DEBUG_SLAVE_WDATA_PROXY", $sformatf("AFTER :: COMBINED WRITE CHANNEL PACKET \n%s",packet.sprint()), UVM_NONE);

     //calling task memory write to store the data into slave memory
     if(axi4_slave_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE && ~slave_err) begin
       task_memory_write(packet);
     end
     
     // Log error responses for debugging
     if(slave_err) begin
       `uvm_info("SLAVE_DRIVER_DEBUG", $sformatf("Write transaction has error response (DECERR/SLVERR) for address 0x%16h - skipping memory write", local_slave_addr_tx.awaddr), UVM_LOW);
     end
     
     wr_resp_cnt++;
     if(wr_addr_cnt == wr_resp_cnt) begin
       completed_initial_txn=1;
     end
     
     semaphore_rsp_write_key.put(1);
   end
  // `join_any` restarted the forever loop as soon as ANY of the three channel
  // threads finished -- normally the address thread, which is the shortest. A
  // fresh WRITE_RESPONSE_CHANNEL thread was then forked while the previous one
  // was still blocked on `data_tx.await()` holding the single-entry
  // `semaphore_rsp_write_key`. Response threads pile up on that semaphore and
  // most writes never reach axi4_write_response_phase, so BVALID is never
  // driven and the write never retires.
  //
  // Against 1:1 direct wiring the timing happened to serialise and hid this.
  // Against any real DUT -- an interconnect, or any IP where several masters
  // funnel into one slave port with independent AW/W interleaving -- it bites:
  // measured 13 write-data phases entered, 9 completed, only 2 responses issued.
  //
  // Completing all three channel phases before accepting the next write is the
  // correct behaviour for a reactive slave model.
  //
  // NOTE (2026-08-02): this `join` no longer gates AW ACCEPTANCE. The subordinate
  // BFM accepts and captures write addresses in a background thread, so a new
  // AWVALID is taken while this iteration is still finishing its data and
  // response phases (see the header of axi4_write_address_phase in the slave
  // driver BFM). Detaching the RESPONSE from this join as well was tried and
  // reverted: with responses lagging, the accept loop raced ahead until
  // `axi4_slave_write_response_fifo_h` (depth 16) blocked on put, which stalls
  // the data phase and is worse than the throttling this join provides.
  join

  // Only check thread status if we actually have threads running (non-SLAVE_MEM_MODE)
  if(axi4_slave_agent_cfg_h.read_data_mode != SLAVE_MEM_MODE) begin
    //checking the status of write address thread
    addr_tx.await();
    `uvm_info("SLAVE_STATUS_CHECK",$sformatf("AFTER_FORK_JOIN_ANY:: SLAVE_ADDRESS_CHANNEL_STATUS =\n %s",addr_tx.status()),UVM_MEDIUM)
    `uvm_info("SLAVE_STATUS_CHECK",$sformatf("AFTER_FORK_JOIN_ANY:: SLAVE_WDATA_CHANNEL_STATUS = \n %s",data_tx.status()),UVM_MEDIUM)
    `uvm_info("SLAVE_STATUS_CHECK",$sformatf("AFTER_FORK_JOIN_ANY:: SLAVE_WRESP_CHANNEL_STATUS = \n%s",response_tx.status()),UVM_MEDIUM)
  end
   
   // Only call item_done() when not in SLAVE_MEM_MODE
   if(axi4_slave_agent_cfg_h.read_data_mode != SLAVE_MEM_MODE) begin
     axi_write_seq_item_port.item_done();
   end

 end
 
 endtask : axi4_write_task

//-------------------------------------------------------
// task axi4 read task
//-------------------------------------------------------
task axi4_slave_driver_proxy::axi4_read_task();
  
  forever begin
    
    //Declaring the process for read address channel and read data channel for status check
    //
    // AUTOMATIC matters here. Variables declared inside a loop in an automatic
    // class method are allocated per CALL, not per iteration, so with the
    // `join_any` below iteration N+1 was overwriting the handles that
    // iteration N's data thread was about to `.await()`. Making them automatic
    // gives every iteration its own pair and removes that race.
    //
    // The fork below stays `join_any` on purpose: converting it to `join` (as
    // the write task did) serialises AR acceptance to one outstanding read per
    // slave agent, and the QoS read path then deadlocks on its own
    // `wait(qos_read_queue.size>=2)` -- measured as 5-8 `timeout waiting for
    // arready` in axi4_qos_basic_priority_test / _equal_priority_fairness_test.
    automatic process rd_addr;
    automatic process rd_data;

    // The read address THIS iteration accepted, handed from the address thread
    // to the data thread that answers it (known-landmines #14).
    //
    // AUTOMATIC for the same reason as the process handles above: one per
    // iteration, so iteration N+1 cannot overwrite the address iteration N's
    // data thread is still answering.
    //
    // What it replaces: `axi4_slave_read_addr_fifo_h.peek(...)`, an UNKEYED read
    // of the FIFO head. The head is only this transaction while every read is
    // answered strictly in acceptance order with nothing else consuming the
    // FIFO, which is an assumption about thread scheduling, not a protocol fact
    // -- and it is false in the out-of-order mode below, where the proxy
    // deliberately answers a read that is NOT at the head. The data thread has
    // already `await()`ed its own address thread, so it can simply be told which
    // address it accepted.
    automatic axi4_slave_tx rd_addr_tx = null;

    int master_id; // Variable for bus matrix master ID mapping

    // In SLAVE_MEM_MODE, don't wait for sequencer transactions - be reactive to BFM signals
    if(axi4_slave_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE) begin
      // Create transaction immediately - BFM will handle signal waiting
      // In SLAVE_MEM_MODE, create a dummy transaction for the BFM to fill with real signal data
      req_rd = axi4_slave_tx::type_id::create("req_rd");
      // Initialize with default values - BFM will fill with actual sampled values
      // Constrain address to avoid 0x0 which can cause spurious DECERR responses
      assert(req_rd.randomize() with {
        araddr != 0;  // Avoid address 0x0 to prevent spurious bus matrix errors
        aw_wait_states == 0;
        w_wait_states == 0;
        b_wait_states == 0;
        ar_wait_states == 0;
        r_wait_states == 0;
      });
      // Put dummy transaction into FIFO for processing
      axi4_slave_read_data_in_fifo_h.put(req_rd);
    end else begin
      // Normal mode - get transaction from sequencer
      axi_read_seq_item_port.get_next_item(req_rd);
      //putting the data into read data fifo
      axi4_slave_read_data_in_fifo_h.put(req_rd);
    end

    // Keep threads active in all modes - in SLAVE_MEM_MODE they will be reactive to BFM signals
    fork
      begin : READ_ADDRESS_CHANNEL
      
      axi4_slave_tx              local_slave_tx;
      axi4_read_transfer_char_s struct_read_packet;
      axi4_read_transfer_char_s oor_struct_read_packet;
      axi4_transfer_cfg_s       struct_cfg;
      
      //returns status of address thread
      rd_addr = process::self();
      
      //Converting transactions into struct data type
      axi4_slave_seq_item_converter::from_read_class(req_rd,struct_read_packet);
      `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_read_packet = \n %0p",struct_read_packet), UVM_HIGH); 
      
      //Converting configurations into struct config type
      axi4_slave_cfg_converter::from_class(axi4_slave_agent_cfg_h,struct_cfg);
      `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_cfg =  \n %0p",struct_cfg),UVM_HIGH);
      
      //read address_task - BFM will wait for and sample real signals, updating struct with real data
      axi4_slave_drv_bfm_h.axi4_read_address_phase(struct_read_packet,struct_cfg);

     // Storing data for enabling out_of_order feature
     if(axi4_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER || axi4_slave_agent_cfg_h.slave_response_mode == ONLY_READ_RESP_OUT_OF_ORDER) begin
       if(rd_response_id_queue.size() == 0) begin
         rd_response_id_queue.push_back(struct_read_packet);
       end
       else begin
         // condition to check if the same id's are coming back to back
         oor_struct_read_packet = rd_response_id_queue[$];
         if(struct_read_packet.arid == oor_struct_read_packet.arid) begin
           drive_rd_id_cont = 1'b1;
           oor_struct_read_packet = rd_response_id_queue.pop_back();
           rd_response_id_cont_queue.push_back(oor_struct_read_packet);
           rd_response_id_cont_queue.push_back(struct_read_packet);
         end
         else begin
           rd_response_id_queue.push_back(struct_read_packet);
         end
       end
     end
      
     //Converting struct into transaction data type
     axi4_slave_seq_item_converter::to_read_class(struct_read_packet,local_slave_tx);
     `uvm_info("DEBUG_SLAVE_READ_ADDR_PROXY", $sformatf(" to_class_raddr_phase_slave_proxy  \n %p",struct_read_packet), UVM_HIGH);

     // Handle exclusive read access according to AMBA AXI4 specification
     if(local_slave_tx.arlock == READ_EXCLUSIVE_ACCESS) begin
       // Set up exclusive monitor for this read
       setup_exclusive_monitor(local_slave_tx.araddr, local_slave_tx.arid, local_slave_tx.arsize, local_slave_tx.arlen);
       `uvm_info("EXCLUSIVE_ACCESS", $sformatf("Exclusive read monitor setup at 0x%16h for master ID %0d", 
                local_slave_tx.araddr, local_slave_tx.arid), UVM_LOW);
     end

     if((axi4_slave_agent_cfg_h.qos_mode_type == ONLY_READ_QOS_MODE_ENABLE) || (axi4_slave_agent_cfg_h.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE)) begin
        qos_read_queue.push_front(local_slave_tx);
      end
     
     // Hand THIS accepted read address to the data thread of this same
     // iteration (see the rd_addr_tx declaration). Set before the FIFO put so it
     // is valid the instant this thread ends, which is what rd_addr.await()
     // waits for.
     rd_addr_tx = local_slave_tx;

     //Putting back the sampled read address data into fifo
     axi4_slave_read_addr_fifo_h.put(local_slave_tx);
     `uvm_info("DEBUG_SLAVE_READ_ADDR_PROXY", $sformatf("AFTER :: Received req packet \n %s",local_slave_tx.sprint()), UVM_NONE);
    
   end
  
   begin : READ_DATA_CHANNEL
    
     axi4_slave_tx              local_slave_rdata_tx;
     axi4_slave_tx              local_slave_raddr_tx;
     axi4_slave_tx              local_slave_addr_chk_tx;
     axi4_slave_tx              qos_value_check_1;
     axi4_slave_tx              packet;
    axi4_read_transfer_char_s  struct_read_packet;
    axi4_transfer_cfg_s        struct_cfg;
    int                        total_bytes;
    int                        compl_cycles;
    int                        rd_cycles;

     //returns status of data thread
     rd_data = process::self();


     //Waiting for the read address thread to complete
     rd_addr.await();

     //Getting the key from semaphore
     semaphore_read_key.get(1);

     if((axi4_slave_agent_cfg_h.qos_mode_type == ONLY_READ_QOS_MODE_ENABLE) || (axi4_slave_agent_cfg_h.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE)) begin
      if(axi4_slave_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE) begin
         compl_cycles = 0;
         // Skip wait in SLAVE_MEM_MODE - reads are independent of writes
         `uvm_info("slave_driver_proxy", "SLAVE_MEM_MODE: Skipping write completion wait for read", UVM_HIGH)
       end
       if(qos_wait_enable) begin
         wait(qos_read_queue.size>=2);
       end
       qos_wait_enable = 1'b0;
       // Same defect as the QoS write response branch: after the first read
       // qos_wait_enable is 0, so nothing guarantees the queue is non-empty here.
       // Selecting from an empty queue yields null and the delete() below aborts
       // the simulation with DT-MCWII. read_queue_index is a class member too, so
       // seed it rather than inheriting a stale index from the previous read.
       wait(qos_read_queue.size() > 0);
       read_queue_index  = 0;
       qos_value_check_1 = qos_read_queue[0];
       for(int i=0;i<qos_read_queue.size();i++) begin
         if(qos_read_queue[i].arqos >= qos_value_check_1.arqos) begin
           qos_value_check_1 = qos_read_queue[i];
           read_queue_index = i;
         end
       end
       //Getting the data from read data fifo
       //axi4_slave_read_data_in_fifo_h.get(local_slave_rdata_tx);
       //local_slave_rdata_tx.rid = rid_e'(qos_read_queue[read_queue_index].arid);
       local_slave_rdata_tx =  qos_read_queue[read_queue_index];
       qos_read_queue.delete(read_queue_index);
     end
     else begin
       //Getting the data from read data fifo
       axi4_slave_read_data_in_fifo_h.get(local_slave_rdata_tx);
     end

     if(((axi4_slave_agent_cfg_h.read_data_mode == RANDOM_DATA_MODE) || (write_read_mode_h == ONLY_READ_DATA)) && (axi4_slave_agent_cfg_h.read_data_mode !== SLAVE_MEM_MODE)) begin
       

       //Converting transactions into struct data type
       axi4_slave_seq_item_converter::from_read_class(local_slave_rdata_tx,struct_read_packet);
       `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_read_packet = \n %0p",struct_read_packet), UVM_HIGH); 
 
       //Converting configurations into struct config type
       axi4_slave_cfg_converter::from_class(axi4_slave_agent_cfg_h,struct_cfg);
       `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_cfg =  \n %0p",struct_cfg),UVM_HIGH);
       
       //Task to check the out_of_order enable and updates the read structure 
       if((axi4_slave_agent_cfg_h.slave_response_mode == ONLY_READ_RESP_OUT_OF_ORDER) || (axi4_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER) ) begin
         out_of_order_for_reads(struct_read_packet);
         `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_read_packet = \n %0p",struct_read_packet), UVM_HIGH); 
       end
       
       //read data task
       axi4_slave_drv_bfm_h.axi4_read_data_phase(struct_read_packet,struct_cfg,axi4_slave_agent_cfg_h.slave_response_mode);
       `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: READ CHANNEL PACKET \n %p",struct_read_packet), UVM_HIGH);
     end
     else if (axi4_slave_agent_cfg_h.read_data_mode == SLAVE_MEM_MODE || axi4_slave_agent_cfg_h.read_data_mode == SLAVE_ERR_RESP_MODE && write_read_mode_h != ONLY_READ_DATA) begin

      // Declare error response variables for memory mode processing
      bit error_response;
      bit error_response_inside;
      bit error_response_inside_wrap;
      bit perm_denied;
      rd_cycles = 0;
      // In SLAVE_MEM_MODE, we don't need to wait for write completion as reads are independent
      if(axi4_slave_agent_cfg_h.read_data_mode != SLAVE_MEM_MODE) begin
        while(completed_initial_txn==0) begin
          @(posedge axi4_slave_drv_bfm_h.aclk);
          if(rd_cycles++ > 10000) begin  // Increase timeout to 10000 cycles
            if (axi4_slave_agent_cfg_h.error_inject) begin
              `uvm_warning("slave_driver_proxy","initial write completion timeout")
            end
            else begin
              `uvm_error("slave_driver_proxy","initial write completion timeout")
            end
            break;
          end
        end
      end
       //Converting transactions into struct data type
       axi4_slave_seq_item_converter::from_read_class(local_slave_rdata_tx,struct_read_packet);
       `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_read_packet = \n %0p",struct_read_packet), UVM_HIGH); 
 
       //Converting configurations into struct config type
       axi4_slave_cfg_converter::from_class(axi4_slave_agent_cfg_h,struct_cfg);
       `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_cfg =  \n %0p",struct_cfg),UVM_HIGH);

       if((axi4_slave_agent_cfg_h.slave_response_mode == ONLY_READ_RESP_OUT_OF_ORDER) || (axi4_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER) ) begin
         out_of_order_for_reads(struct_read_packet);
         `uvm_info(get_type_name(), $sformatf("from_read_class:: struct_read_packet = \n %0p",struct_read_packet), UVM_HIGH); 
       end

     // ------------------------------------------------------------------
     // Bind the response to the read it is answering (known-landmines #14).
     //
     // Everything below -- the bus-matrix permission/decode query, the RRESP
     // array, the memory read and the error-data fill -- is computed from
     // local_slave_addr_chk_tx, so that handle decides WHICH read this response
     // belongs to. It must be the read whose data phase is about to be driven,
     // and each of the three response policies picks a different one:
     //
     //   QoS       - the highest-priority queued read, selected above.
     //   Out-of-order - the read that out_of_order_for_reads() just selected
     //                  into struct_read_packet; the BFM drives that read's
     //                  ARID/ARLEN, so the response must be computed for it too.
     //   In-order  - the read THIS iteration accepted (rd_addr_tx).
     //
     // It used to be `peek()` on the read address FIFO head for the last two.
     // For out-of-order that is provably the wrong transaction whenever the
     // shuffle picks anything but the head, and for in-order it is right only
     // as long as no other consumer touches the FIFO and every data thread runs
     // in acceptance order -- an assumption about thread scheduling rather than
     // a protocol fact. The response is now bound to its own transaction by
     // construction in all three cases.
     // ------------------------------------------------------------------
     if((axi4_slave_agent_cfg_h.qos_mode_type == ONLY_READ_QOS_MODE_ENABLE) || (axi4_slave_agent_cfg_h.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE)) begin
        local_slave_addr_chk_tx = local_slave_rdata_tx;
      end
      else if((axi4_slave_agent_cfg_h.slave_response_mode == ONLY_READ_RESP_OUT_OF_ORDER) || (axi4_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER)) begin
        axi4_slave_seq_item_converter::to_read_class(struct_read_packet,local_slave_addr_chk_tx);
      end
      else if(rd_addr_tx != null) begin
        local_slave_addr_chk_tx = rd_addr_tx;
      end
      else begin
        // Cannot happen: the data thread only runs after rd_addr.await(), and
        // the address thread sets rd_addr_tx before it ends. Kept as the old
        // behaviour rather than a null dereference if it ever does.
        axi4_slave_read_addr_fifo_h.peek(local_slave_addr_chk_tx);
        `uvm_info("slave_driver_proxy","read data thread ran with no bound read address - fell back to the read address FIFO head",UVM_LOW)
      end
      `uvm_info("RDBG",$sformatf("READ_RESP_BOUND arid=0x%0h araddr=0x%0h arprot=%0b arlen=%0d arsize=%0d",local_slave_addr_chk_tx.arid,local_slave_addr_chk_tx.araddr,local_slave_addr_chk_tx.arprot,local_slave_addr_chk_tx.arlen,local_slave_addr_chk_tx.arsize),UVM_HIGH)
      total_bytes = (local_slave_addr_chk_tx.arlen+1)*(2**(local_slave_addr_chk_tx.arsize));
      `uvm_info("SLAVE_DRIVER_ALWAYS", $sformatf("Slave %0d checking address 0x%16h against range [0x%16h:0x%16h]", 
               axi4_slave_agent_cfg_h.slave_id, local_slave_addr_chk_tx.araddr, 
               axi4_slave_agent_cfg_h.min_address, axi4_slave_agent_cfg_h.max_address), UVM_LOW);
      if(local_slave_addr_chk_tx.araddr inside {[axi4_slave_agent_cfg_h.min_address : axi4_slave_agent_cfg_h.max_address]}) begin : ADDR_INSIDE_SLAVE_MEM_RANGE
        `uvm_info("SLAVE_DRIVER_ALWAYS", $sformatf("Address 0x%16h IS INSIDE slave %0d range", 
                 local_slave_addr_chk_tx.araddr, axi4_slave_agent_cfg_h.slave_id), UVM_LOW);
        perm_denied = 1'b0;
        // Access-matrix permission is a property of (master, address, AxPROT). It
        // does NOT depend on the burst type or on whether the burst crosses a
        // boundary, but the per-burst branches below only consult the matrix
        // inside `if(crossed_read_addr)`, so an in-range read that the matrix
        // forbids was answered OKAY straight out of slave memory. Measured on the
        // Track-B sweep: 12x "expected READ_SLVERR, got READ_OKAY" at S7
        // (Secure-Only, 0xA_0002_xxxx) plus 10x expected DECERR at S0, with both
        // sides agreeing on master 7 and arprot=011 -- the subordinate simply
        // never asked. Decide it once, here, before any memory access.
        if (axi4_bus_matrix_h != null) begin
          rresp_e perm_rresp;
          // Derive the requesting master the same way every other site does; the
          // outer master_id is only assigned inside the per-burst branches below.
`ifdef BUS_MATRIX_FABRIC_IP
          if (((local_slave_addr_chk_tx.aruser) & `AXI4_MID_TAG_MASK) == {`AXI4_MID_TAG, 4'h0})
            master_id = int'((local_slave_addr_chk_tx.aruser) & 32'hF);
          else
            // No AXI4_MID_TAG in AxUSER: this is not fabric traffic that carries manager
            // identity, and the egress AxID is a reversed permutation of the ingress port
            // index (measured), so deriving an id from it attributes the access to the
            // wrong access-matrix row and denies legal in-range transfers. Mark the
            // manager UNKNOWN and let the scoreboard -- which has the true master port --
            // own the permission check.
            master_id = -1;
`else
          master_id = axi4_slave_agent_cfg_h.slave_id;
`endif
          perm_rresp = mid_safe_read_resp(master_id,
                                                       local_slave_addr_chk_tx.araddr,
                                                       local_slave_addr_chk_tx.arprot);
          if (perm_rresp != READ_OKAY && perm_rresp != READ_EXOKAY) begin
            `uvm_info("SLAVE_DRIVER_DEBUG",
                      $sformatf("In-range read denied by the access matrix: master=%0d addr=0x%16h arprot=%03b -> %s",
                                master_id, local_slave_addr_chk_tx.araddr,
                                local_slave_addr_chk_tx.arprot, perm_rresp.name()), UVM_LOW);
            for(int d = 0; d < (local_slave_addr_chk_tx.arlen + 1); d++) begin
              struct_read_packet.rresp[d] = perm_rresp;
              struct_read_packet.rdata[d] = '0;
            end
            axi4_slave_drv_bfm_h.axi4_read_data_phase(struct_read_packet, struct_cfg,
                                                      axi4_slave_agent_cfg_h.slave_response_mode);
            axi4_slave_seq_item_converter::to_read_class(struct_read_packet, local_slave_rdata_tx);
            axi4_slave_read_addr_fifo_h.get(local_slave_raddr_tx);
            axi4_slave_seq_item_converter::tx_read_packet(local_slave_raddr_tx, local_slave_rdata_tx, packet);
            semaphore_read_key.put(1);
            perm_denied = 1'b1;   // `continue` is illegal inside this fork branch
          end
        end

        if (!perm_denied) begin

        if(local_slave_addr_chk_tx.arburst == READ_FIXED) begin
          // Check bus matrix response first before memory operations
          error_response_inside = 1'b0;
          if(crossed_read_addr) begin
            for(int depth=0;depth<(local_slave_addr_chk_tx.arlen+1);depth++) begin
              // Extract master_id from ARID value
              int master_id = 0;
              int arid_value = int'(local_slave_addr_chk_tx.arid);
              
              // Use configuration-aware modulo mapping based on actual bus matrix configuration
              // Check bus matrix mode and use appropriate modulo
              // The bus matrix wants the SOURCE MASTER, and the scoreboard now derives
              // that from the monitor's source-port stamp. The two must agree or the
              // slave's response and the scoreboard's expectation are computed against
              // different rows of the access matrix. With the 1:1 direct wiring
              // (top/hdl_top.sv connects master[j] to slave[j]) this agent's own
              // slave_id IS the source master. Behind the NIC-400 fabric it is not,
              // and the egress AxID carries the ingress port instead, so the historical
              // AxID rule is kept there.
              `ifdef BUS_MATRIX_FABRIC_IP
                // The fabric's egress AxID is {original AxID, ingress-port index} with the
                // port in the LOW AXI_ID_WIDTH-AXI_VID_WIDTH bits, so the requesting master
                // is decodable here rather than guessed. `AxID % nports` was a guess: it is
                // only right when the manager happens to drive an AxID equal to its own port
                // index, and disagreed with the scoreboard (which uses the monitor's source
                // stamp) the moment a sweep drove arbitrary IDs -- measured 75 'Response
                // mismatch' errors, in both directions, on the coverage sweep.
                // Manager identity is carried EXPLICITLY in AxUSER behind the fabric
                // (AXI4_MID_TAG, include/axi4_bus_config.svh). Deriving it from the egress
                // AxID was wrong: that field is a per-sub-block REVERSED permutation of the
                // ingress port index on the 10x10 build -- measured 960/960 reads attributed
                // to the wrong access-matrix row. Untagged traffic falls back to the old rule.
                if (((local_slave_addr_chk_tx.aruser) & `AXI4_MID_TAG_MASK) == {`AXI4_MID_TAG, 4'h0})
                  master_id = int'((local_slave_addr_chk_tx.aruser) & 32'hF);
                else
                  master_id = -1;  // manager unknown -- see the first such site above
              `else
                master_id = axi4_slave_agent_cfg_h.slave_id;
              `endif
              
              if (axi4_bus_matrix_h != null) begin
                struct_read_packet.rresp[depth] = mid_safe_read_resp(master_id,
                                                                                 local_slave_addr_chk_tx.araddr,
                                                                                 local_slave_addr_chk_tx.arprot);
              end else begin
                // No bus matrix - default to READ_OKAY
                struct_read_packet.rresp[depth] = READ_OKAY;
              end
              if (struct_read_packet.rresp[depth] == 2 || struct_read_packet.rresp[depth] == 3) begin
                error_response_inside = 1'b1;
              end
            end
          end
          else begin
            // Extract master_id from ARID value
            // This ensures bus matrix checks use the correct master permissions
            int master_id = 0;
            int arid_value = int'(local_slave_addr_chk_tx.arid);
            
            // Use configuration-aware modulo mapping based on actual bus matrix configuration
            // Check bus matrix mode and use appropriate modulo
            // The bus matrix wants the SOURCE MASTER, and the scoreboard now derives
            // that from the monitor's source-port stamp. The two must agree or the
            // slave's response and the scoreboard's expectation are computed against
            // different rows of the access matrix. With the 1:1 direct wiring
            // (top/hdl_top.sv connects master[j] to slave[j]) this agent's own
            // slave_id IS the source master. Behind the NIC-400 fabric it is not,
            // and the egress AxID carries the ingress port instead, so the historical
            // AxID rule is kept there.
            `ifdef BUS_MATRIX_FABRIC_IP
              // The fabric's egress AxID is {original AxID, ingress-port index} with the
              // port in the LOW AXI_ID_WIDTH-AXI_VID_WIDTH bits, so the requesting master
              // is decodable here rather than guessed. `AxID % nports` was a guess: it is
              // only right when the manager happens to drive an AxID equal to its own port
              // index, and disagreed with the scoreboard (which uses the monitor's source
              // stamp) the moment a sweep drove arbitrary IDs -- measured 75 'Response
              // mismatch' errors, in both directions, on the coverage sweep.
              // Manager identity is carried EXPLICITLY in AxUSER behind the fabric
              // (AXI4_MID_TAG, include/axi4_bus_config.svh). Deriving it from the egress
              // AxID was wrong: that field is a per-sub-block REVERSED permutation of the
              // ingress port index on the 10x10 build -- measured 960/960 reads attributed
              // to the wrong access-matrix row. Untagged traffic falls back to the old rule.
              if (((local_slave_addr_chk_tx.aruser) & `AXI4_MID_TAG_MASK) == {`AXI4_MID_TAG, 4'h0})
                master_id = int'((local_slave_addr_chk_tx.aruser) & 32'hF);
              else
                master_id = -1;  // manager unknown -- see the first such site above
            `else
              master_id = axi4_slave_agent_cfg_h.slave_id;
            `endif
            
            if (axi4_bus_matrix_h != null) begin
              struct_read_packet.rresp = mid_safe_read_resp(master_id,
                                                                         local_slave_addr_chk_tx.araddr,
                                                                         local_slave_addr_chk_tx.arprot);
            end else begin
              // No bus matrix - default to READ_OKAY
              struct_read_packet.rresp = READ_OKAY;
            end
            
            // Handle exclusive read response according to AMBA AXI4 specification
            if(local_slave_addr_chk_tx.arlock == READ_EXCLUSIVE_ACCESS && struct_read_packet.rresp == READ_OKAY) begin
              struct_read_packet.rresp = READ_EXOKAY; // Exclusive read always gets EXOKAY if no error
              `uvm_info("EXCLUSIVE_ACCESS", $sformatf("Exclusive read returning EXOKAY for addr 0x%16h, master ID %0d", 
                       local_slave_addr_chk_tx.araddr, local_slave_addr_chk_tx.arid), UVM_LOW);
            end
            
            if (struct_read_packet.rresp == 2 || struct_read_packet.rresp == 3) begin
              error_response_inside = 1'b1;
            end
          end
          
          // Handle error responses properly without abandoning transaction
          if (error_response_inside) begin
            `uvm_info("SLAVE_DRIVER_DEBUG", $sformatf("Read transaction has error response (DECERR/SLVERR) for address 0x%16h - providing default data", local_slave_addr_chk_tx.araddr), UVM_LOW);
            // For error responses, provide default data but complete transaction
            for(int i=0;i<local_slave_addr_chk_tx.arlen+1;i++) begin
              struct_read_packet.rdata[i] = '0; // Default error data
            end
          end else begin
            // Only perform memory operations if no error response
            task_memory_read(local_slave_addr_chk_tx,struct_read_packet);
          end

          //read data task - always complete transaction
          axi4_slave_drv_bfm_h.axi4_read_data_phase(struct_read_packet,struct_cfg,axi4_slave_agent_cfg_h.slave_response_mode);
          `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: READ_CHANNEL_PACKET \n%p",struct_read_packet), UVM_NONE);
        end
        else if(local_slave_addr_chk_tx.arburst == READ_WRAP || local_slave_addr_chk_tx.arburst == READ_INCR) begin
          if(axi4_bus_matrix_h != null && axi4_bus_matrix_h.decode(local_slave_addr_chk_tx.araddr) >= 0 || axi4_bus_matrix_h == null) begin 
            // Check bus matrix response first before memory operations
            error_response_inside_wrap = 1'b0;
            
            // Always check bus matrix response for access permissions (e.g., write-only slaves)
            // Extract master_id from ARID value
            begin
              int arid_value_wrap = int'(local_slave_addr_chk_tx.arid);
              // Use configuration-aware modulo mapping based on actual bus matrix configuration
              // Check bus matrix mode and use appropriate modulo
              // The bus matrix wants the SOURCE MASTER, and the scoreboard now derives
              // that from the monitor's source-port stamp. The two must agree or the
              // slave's response and the scoreboard's expectation are computed against
              // different rows of the access matrix. With the 1:1 direct wiring
              // (top/hdl_top.sv connects master[j] to slave[j]) this agent's own
              // slave_id IS the source master. Behind the NIC-400 fabric it is not,
              // and the egress AxID carries the ingress port instead, so the historical
              // AxID rule is kept there.
              `ifdef BUS_MATRIX_FABRIC_IP
                // The fabric's egress AxID is {original AxID, ingress-port index} with the
                // port in the LOW AXI_ID_WIDTH-AXI_VID_WIDTH bits, so the requesting master
                // is decodable here rather than guessed. `AxID % nports` was a guess: it is
                // only right when the manager happens to drive an AxID equal to its own port
                // index, and disagreed with the scoreboard (which uses the monitor's source
                // stamp) the moment a sweep drove arbitrary IDs -- measured 75 'Response
                // mismatch' errors, in both directions, on the coverage sweep.
                // Manager identity is carried EXPLICITLY in AxUSER behind the fabric
                // (AXI4_MID_TAG, include/axi4_bus_config.svh). Deriving it from the egress
                // AxID was wrong: that field is a per-sub-block REVERSED permutation of the
                // ingress port index on the 10x10 build -- measured 960/960 reads attributed
                // to the wrong access-matrix row. Untagged traffic falls back to the old rule.
                if (((local_slave_addr_chk_tx.aruser) & `AXI4_MID_TAG_MASK) == {`AXI4_MID_TAG, 4'h0})
                  master_id = int'((local_slave_addr_chk_tx.aruser) & 32'hF);
                else
                  master_id = -1;  // manager unknown -- see the first such site above
              `else
                master_id = axi4_slave_agent_cfg_h.slave_id;
              `endif
            end
            
            // First, check if any address in the burst has access restrictions
            for(int depth=0;depth<(local_slave_addr_chk_tx.arlen+1);depth++) begin
              struct_read_packet.rresp[depth] = mid_safe_read_resp(master_id,
                                                                               local_slave_addr_chk_tx.araddr + (depth * (1 << local_slave_addr_chk_tx.arsize)),
                                                                               local_slave_addr_chk_tx.arprot);
              if (struct_read_packet.rresp[depth] == 2 || struct_read_packet.rresp[depth] == 3) begin
                error_response_inside_wrap = 1'b1;
                `uvm_info("SLAVE_DRIVER_DEBUG", $sformatf("Bus matrix returned error response %0d for read to address 0x%16h", 
                         struct_read_packet.rresp[depth], local_slave_addr_chk_tx.araddr + (depth * (1 << local_slave_addr_chk_tx.arsize))), UVM_LOW);
              end
            end
            
            // Additionally check for address boundary crossing if needed
            if (!error_response_inside_wrap) begin
              for(int j=0,int loc=0;j<total_bytes;j++) begin
                if((local_slave_addr_chk_tx.araddr+j)==crossed_read_addr) begin
                  loc = j/STROBE_WIDTH;
                  
                  for(int depth=0;depth<(local_slave_addr_chk_tx.arlen+1);depth++) begin
                    if (axi4_bus_matrix_h != null) begin
                      if(depth > loc) struct_read_packet.rresp[depth] = mid_safe_read_resp(master_id,
                                                                                                     local_slave_addr_chk_tx.araddr,
                                                                                                     local_slave_addr_chk_tx.arprot);
                      else struct_read_packet.rresp[depth] = mid_safe_read_resp(master_id,
                                                                                               local_slave_addr_chk_tx.araddr,
                                                                                               local_slave_addr_chk_tx.arprot);
                    end else begin
                      // No bus matrix - default to READ_OKAY
                      struct_read_packet.rresp[depth] = READ_OKAY;
                    end
                    if (struct_read_packet.rresp[depth] == 2 || struct_read_packet.rresp[depth] == 3) begin
                      error_response_inside_wrap = 1'b1;
                    end
                  end
                  break;
                end
              end
            end
            
            // Handle error responses properly without abandoning transaction
            if (error_response_inside_wrap) begin
              `uvm_info("SLAVE_DRIVER_DEBUG", $sformatf("Read transaction (WRAP/INCR) has error response (DECERR/SLVERR) for address 0x%16h - providing default data", local_slave_addr_chk_tx.araddr), UVM_LOW);
              // For error responses, provide default data but complete transaction
              for(int i=0;i<local_slave_addr_chk_tx.arlen+1;i++) begin
                struct_read_packet.rdata[i] = '0; // Default error data
              end
            end else begin
              // Only perform memory operations if no error response
              task_memory_read(local_slave_addr_chk_tx,struct_read_packet);
            end
            
            //read data task - always complete transaction
            axi4_slave_drv_bfm_h.axi4_read_data_phase(struct_read_packet,struct_cfg,axi4_slave_agent_cfg_h.slave_response_mode);
            `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: READ_CHANNEL_PACKET \n%p",struct_read_packet), UVM_NONE);
          end
          else begin
            // Check bus matrix response first before deciding if this is an error
            bit error_response_inside_range = 1'b0;
            for(int depth=0;depth<(local_slave_addr_chk_tx.arlen+1);depth++) begin
              // Extract master_id from ARID value
              int master_id = 0;
              int arid_value = int'(local_slave_addr_chk_tx.arid);
              
              // Use configuration-aware modulo mapping based on actual bus matrix configuration
              // Check bus matrix mode and use appropriate modulo
              // The bus matrix wants the SOURCE MASTER, and the scoreboard now derives
              // that from the monitor's source-port stamp. The two must agree or the
              // slave's response and the scoreboard's expectation are computed against
              // different rows of the access matrix. With the 1:1 direct wiring
              // (top/hdl_top.sv connects master[j] to slave[j]) this agent's own
              // slave_id IS the source master. Behind the NIC-400 fabric it is not,
              // and the egress AxID carries the ingress port instead, so the historical
              // AxID rule is kept there.
              `ifdef BUS_MATRIX_FABRIC_IP
                // The fabric's egress AxID is {original AxID, ingress-port index} with the
                // port in the LOW AXI_ID_WIDTH-AXI_VID_WIDTH bits, so the requesting master
                // is decodable here rather than guessed. `AxID % nports` was a guess: it is
                // only right when the manager happens to drive an AxID equal to its own port
                // index, and disagreed with the scoreboard (which uses the monitor's source
                // stamp) the moment a sweep drove arbitrary IDs -- measured 75 'Response
                // mismatch' errors, in both directions, on the coverage sweep.
                // Manager identity is carried EXPLICITLY in AxUSER behind the fabric
                // (AXI4_MID_TAG, include/axi4_bus_config.svh). Deriving it from the egress
                // AxID was wrong: that field is a per-sub-block REVERSED permutation of the
                // ingress port index on the 10x10 build -- measured 960/960 reads attributed
                // to the wrong access-matrix row. Untagged traffic falls back to the old rule.
                if (((local_slave_addr_chk_tx.aruser) & `AXI4_MID_TAG_MASK) == {`AXI4_MID_TAG, 4'h0})
                  master_id = int'((local_slave_addr_chk_tx.aruser) & 32'hF);
                else
                  master_id = -1;  // manager unknown -- see the first such site above
              `else
                master_id = axi4_slave_agent_cfg_h.slave_id;
              `endif
              
              if (axi4_bus_matrix_h != null) begin
                struct_read_packet.rresp[depth] = mid_safe_read_resp(master_id,
                                                                                 local_slave_addr_chk_tx.araddr,
                                                                                 local_slave_addr_chk_tx.arprot);
              end else begin
                // No bus matrix - default to READ_OKAY
                struct_read_packet.rresp[depth] = READ_OKAY;
              end
              `uvm_info("SLAVE_DRIVER_DEBUG", $sformatf("Bus matrix returned rresp[%0d] = %0d for address 0x%16h inside range", 
                       depth, struct_read_packet.rresp[depth], local_slave_addr_chk_tx.araddr), UVM_LOW);
              
              // Check for error responses - SLVERR (2) or DECERR (3)
              if (struct_read_packet.rresp[depth] == 2 || struct_read_packet.rresp[depth] == 3) begin
                error_response_inside_range = 1'b1;
                `uvm_info("SLAVE_DRIVER_DEBUG", $sformatf("Error response detected (rresp=%0d) for address 0x%16h inside range - abandoning transaction", 
                         struct_read_packet.rresp[depth], local_slave_addr_chk_tx.araddr), UVM_LOW);
              end
            end
            
            // Handle error responses properly without abandoning transaction
            if (error_response_inside_range) begin
              `uvm_info("SLAVE_DRIVER_DEBUG", $sformatf("Read transaction (inside range) has error response (DECERR/SLVERR) for address 0x%16h - providing default data", local_slave_addr_chk_tx.araddr), UVM_LOW);
              // For error responses, provide default data but complete transaction
              for(int i=0;i<local_slave_addr_chk_tx.arlen+1;i++) begin
                struct_read_packet.rdata[i] = '0; // Default error data
              end
              //read data task - always complete transaction
              axi4_slave_drv_bfm_h.axi4_read_data_phase(struct_read_packet,struct_cfg,axi4_slave_agent_cfg_h.slave_response_mode);
              `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("Error response transaction completed with default data"), UVM_LOW);
            end else begin
              // Only generate UVM_ERROR if this is not an error response transaction
              axi4_slave_agent_cfg_h.user_rdata = (local_slave_addr_chk_tx.arsize ==
              READ_1_BYTE)?32'ha:((local_slave_addr_chk_tx.arsize ==
              READ_2_BYTES)?32'haa:((local_slave_addr_chk_tx.arsize ==
              READ_4_BYTES)?32'hdead_beaf:{DATA_WIDTH{16'habcd}}));
              for(int i=0;i<local_slave_addr_chk_tx.arlen+1;i++) begin
                struct_read_packet.rdata[i] =  axi4_slave_agent_cfg_h.user_rdata;
              end
              //read data task
              axi4_slave_drv_bfm_h.axi4_read_data_phase(struct_read_packet,struct_cfg,axi4_slave_agent_cfg_h.slave_response_mode);
              `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: READ_CHANNEL_PACKET \n%p",struct_read_packet), UVM_HIGH);
              if (axi4_slave_agent_cfg_h.error_inject) begin
                `uvm_warning("AXI4_SLAVE_DRIVER_PROXY",$sformatf("ADDRESS trying to read DOESN'T EXIST in the slave memory... READING DEFAULT VALUES...."))
              end
              else begin
                `uvm_error("AXI4_SLAVE_DRIVER_PROXY",$sformatf("ADDRESS trying to read DOESN'T EXIST in the slave memory... READING DEFAULT VALUES...."))
              end;
            end
          end
        end
        end  // if (!perm_denied)
      end
      else begin : ADDR_NOT_INSIDE_SLAVE_MEM_RANGE
        int master_id;  // Declare variable at the beginning of the block
        int decoded_slave_id;
        
        `uvm_info("SLAVE_DRIVER_DEBUG", $sformatf("Address 0x%16h is NOT INSIDE slave %0d range [0x%16h:0x%16h] - calling bus matrix", 
                 local_slave_addr_chk_tx.araddr, axi4_slave_agent_cfg_h.slave_id, 
                 axi4_slave_agent_cfg_h.min_address, axi4_slave_agent_cfg_h.max_address), UVM_LOW);
        
        error_response = 1'b0;
        // Extract master_id from ARID value
        begin
          int arid_value_last = int'(local_slave_addr_chk_tx.arid);
          // Use configuration-aware modulo mapping based on actual bus matrix configuration
          // Check bus matrix mode and use appropriate modulo
          // The bus matrix wants the SOURCE MASTER, and the scoreboard now derives
          // that from the monitor's source-port stamp. The two must agree or the
          // slave's response and the scoreboard's expectation are computed against
          // different rows of the access matrix. With the 1:1 direct wiring
          // (top/hdl_top.sv connects master[j] to slave[j]) this agent's own
          // slave_id IS the source master. Behind the NIC-400 fabric it is not,
          // and the egress AxID carries the ingress port instead, so the historical
          // AxID rule is kept there.
          `ifdef BUS_MATRIX_FABRIC_IP
            // The fabric's egress AxID is {original AxID, ingress-port index} with the
            // port in the LOW AXI_ID_WIDTH-AXI_VID_WIDTH bits, so the requesting master
            // is decodable here rather than guessed. `AxID % nports` was a guess: it is
            // only right when the manager happens to drive an AxID equal to its own port
            // index, and disagreed with the scoreboard (which uses the monitor's source
            // stamp) the moment a sweep drove arbitrary IDs -- measured 75 'Response
            // mismatch' errors, in both directions, on the coverage sweep.
            // Manager identity is carried EXPLICITLY in AxUSER behind the fabric
            // (AXI4_MID_TAG, include/axi4_bus_config.svh). Deriving it from the egress
            // AxID was wrong: that field is a per-sub-block REVERSED permutation of the
            // ingress port index on the 10x10 build -- measured 960/960 reads attributed
            // to the wrong access-matrix row. Untagged traffic falls back to the old rule.
            if (((local_slave_addr_chk_tx.aruser) & `AXI4_MID_TAG_MASK) == {`AXI4_MID_TAG, 4'h0})
              master_id = int'((local_slave_addr_chk_tx.aruser) & 32'hF);
            else
              master_id = -1;  // manager unknown -- see the first such site above
          `else
            master_id = axi4_slave_agent_cfg_h.slave_id;
          `endif
        end
        
        for(int depth=0;depth<(((axi4_slave_agent_cfg_h.slave_response_mode == WRITE_READ_RESP_OUT_OF_ORDER)
          || (axi4_slave_agent_cfg_h.slave_response_mode == ONLY_READ_RESP_OUT_OF_ORDER) ||
          (axi4_slave_agent_cfg_h.qos_mode_type == ONLY_READ_QOS_MODE_ENABLE) ||
          (axi4_slave_agent_cfg_h.qos_mode_type == WRITE_READ_QOS_MODE_ENABLE))  ? (struct_read_packet.arlen+1) : (local_slave_addr_chk_tx.arlen+1));depth++) begin
          struct_read_packet.rresp[depth] = mid_safe_read_resp(master_id,
                                                                           local_slave_addr_chk_tx.araddr,
                                                                           local_slave_addr_chk_tx.arprot);
          `uvm_info("SLAVE_DRIVER_DEBUG", $sformatf("Bus matrix returned rresp[%0d] = %0d for address 0x%16h", 
                   depth, struct_read_packet.rresp[depth], local_slave_addr_chk_tx.araddr), UVM_LOW);
          
          // Check for error responses - SLVERR (2) or DECERR (3)
          if (struct_read_packet.rresp[depth] == 2 || struct_read_packet.rresp[depth] == 3) begin
            error_response = 1'b1;
            `uvm_info("SLAVE_DRIVER_DEBUG", $sformatf("Error response detected (rresp=%0d) for address 0x%16h - abandoning transaction", 
                     struct_read_packet.rresp[depth], local_slave_addr_chk_tx.araddr), UVM_LOW);
          end
        end

        // Only process read data if no error response
        if (!error_response) begin
          //read data task
          axi4_slave_drv_bfm_h.axi4_read_data_phase(struct_read_packet,struct_cfg,axi4_slave_agent_cfg_h.slave_response_mode);
          `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: READ CHANNEL PACKET \n %p",struct_read_packet), UVM_HIGH);
        end else begin
          // For error responses, provide default data but don't call memory functions
          for(int i=0;i<local_slave_addr_chk_tx.arlen+1;i++) begin
            struct_read_packet.rdata[i] = '0; // Default error data
          end
          axi4_slave_drv_bfm_h.axi4_read_data_phase(struct_read_packet,struct_cfg,axi4_slave_agent_cfg_h.slave_response_mode);
          `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("Error response transaction completed with default data"), UVM_LOW);
        end
      end
     end
     //Calling converter class for reads to convert struct to req
     axi4_slave_seq_item_converter::to_read_class(struct_read_packet,local_slave_rdata_tx);
     `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: READ CHANNEL PACKET \n %s",local_slave_rdata_tx.sprint()), UVM_NONE);

     //Getting teh sampled read address from read address fifo
     axi4_slave_read_addr_fifo_h.get(local_slave_raddr_tx);
    
     //Calling the Combined coverter class to combine read address and read data packet
     axi4_slave_seq_item_converter::tx_read_packet(local_slave_raddr_tx,local_slave_rdata_tx,packet);
     `uvm_info("DEBUG_SLAVE_RDATA_PROXY", $sformatf("AFTER :: COMBINED READ CHANNEL PACKET \n%s",packet.sprint()), UVM_NONE);
     
     //Putting back the key
     semaphore_read_key.put(1);
   end
  // See the `automatic` note on rd_addr/rd_data above: join_any is retained so
  // the slave can keep accepting read addresses while a read data phase runs,
  // and the handle race it used to cause is fixed by the automatic declaration.
  join_any

  // Only check thread status if we actually have threads running (non-SLAVE_MEM_MODE)
  if(axi4_slave_agent_cfg_h.read_data_mode != SLAVE_MEM_MODE) begin
    //Check the status of read address thread
    rd_addr.await();
    `uvm_info("SLAVE_STATUS_CHECK",$sformatf("AFTER_FORK_JOIN_ANY:: SLAVE_READ_CHANNEL_STATUS = \n %s",rd_addr.status()),UVM_MEDIUM)
    `uvm_info("SLAVE_STATUS_CHECK",$sformatf("AFTER_FORK_JOIN_ANY:: SLAVE_RDATA_CHANNEL_STATUS = \n %s",rd_data.status()),UVM_MEDIUM)
  end

  // Only call item_done() when not in SLAVE_MEM_MODE
  if(axi4_slave_agent_cfg_h.read_data_mode != SLAVE_MEM_MODE) begin
    axi_read_seq_item_port.item_done();
  end
end

endtask : axi4_read_task

//--------------------------------------------------------------------------------------------
// Task: task_memory_write
// This task is used to write the data into the slave memory
// Parameters:
//  struct_packet   - axi4_write_transfer_char_s
//--------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------
// WSTRB is a BYTE ENABLE, not a byte counter.
//
// The INCR and WRAP branches used to carry a cursor `k` that was incremented
// ONLY when a strobe bit was set, and wrote each enabled byte to `awaddr + k`.
// That silently compresses the address space: a beat whose only asserted lane is
// lane 2 wrote its byte to `awaddr + 0` instead of `awaddr + 2`, and any gap in
// the strobe pattern pulled every following byte of the burst down by the width
// of the gap. WRAP had it worse - the same cursor also drove the wrap
// bookkeeping (`k_t`), so a sparse pattern moved the wrap point as well.
//
// Directed stimulus that hits this exists today: test/axi4_wstrb_alternating_test
// drives 0101 / 1010 through seq/master_sequences/axi4_master_wstrb_seq.sv, and
// its read-back only agreed with the write because the reference memory and the
// expectation were wrong in the same direction.
//
// The address of an enabled byte is now derived from the BEAT, independently of
// how many other lanes happen to be enabled:
//
//   beat_bytes   = 2**AWSIZE                            bytes carried per beat
//   aligned_addr = AWADDR - AWADDR % beat_bytes         AXI4 A3.4.1 aligned_address
//   beat_addr(j) = INCR: AWADDR + j*beat_bytes
//                  WRAP: lower + ((AWADDR + j*beat_bytes - lower) % wrap_bytes)
//   lane_base(j) = (aligned_addr + j*beat_bytes) % STROBE_WIDTH
//   byte address = beat_addr(j) + (lane - lane_base(j))
//
// lane_base is the lowest byte lane this beat occupies on the data bus, and it
// is what makes the lane index mean "offset within the beat". It is derived the
// same way axi4_master_tx::post_randomize places the strobes (`remainder_check =
// awaddr % STROBE_WIDTH`, shifted left by 2**awsize per beat), so the two sides
// agree by construction instead of by accident.
//
// Equivalence with the old code, which is why this is not a behavioural change
// for anything except sparse strobes: when a beat's strobes are CONTIGUOUS and
// start at lane_base - which is every burst the master generates for an
// AWSIZE-aligned address - the old cursor produced exactly beat_addr(j) +
// (lane - lane_base(j)) for every enabled byte, in both INCR and WRAP including
// the wrapped beats. Worked examples are in the report accompanying this change.
//
// FIXED is left alone: it already applies the lane offset (`awaddr + strb`) and
// was cited as the correct counter-example.
//--------------------------------------------------------------------------------------------
task axi4_slave_driver_proxy::task_memory_write(input axi4_slave_tx struct_write_packet);
  bit [DATA_WIDTH-1:0] tmp_wdata;
  // lower_addr/end_addr used to be plain `int`, i.e. 32 bits signed, while an
  // address here is ADDRESS_WIDTH (64) bits. Every WRAP burst above 4GB - and
  // the DDR base this VIP's own tests use is 0x0000_0100_0000_0000 - therefore
  // computed its wrap boundary from the low 32 bits and wrote the wrapped half
  // of the burst to a truncated `lower_addr + k` near zero, while the
  // un-wrapped half went to the full 64-bit address. They carry addresses now.
  bit [ADDRESS_WIDTH-1:0] lower_addr;
  bit [ADDRESS_WIDTH-1:0] aligned_addr;
  bit [ADDRESS_WIDTH-1:0] beat_addr;
  bit [ADDRESS_WIDTH-1:0] byte_addr;
  int                     beat_bytes;
  int                     wrap_bytes;
  int                     lane_base;
  int                     lane_off;

  beat_bytes   = 2**struct_write_packet.awsize;
  aligned_addr = struct_write_packet.awaddr - (struct_write_packet.awaddr % beat_bytes);

  if(struct_write_packet.awburst == WRITE_FIXED) begin
    for(int j=0;j<(struct_write_packet.awlen+1);j++)begin
      `uvm_info("DEBUG_MEMORY_WRITE",$sformatf("memory_task_awlen=%d",struct_write_packet.awlen),UVM_HIGH)
        for(int strb=0;strb<STROBE_WIDTH;strb++) begin
        `uvm_info("DEBUG_MEMORY_WRITE", $sformatf("task_memory_write inside for loop wstrb = %0h",struct_write_packet.wstrb[strb]), UVM_HIGH);
        if(struct_write_packet.wstrb[j][strb] == 1) begin
          tmp_wdata = '0;
          tmp_wdata[7:0] = struct_write_packet.wdata[j][8*strb+7 -: 8];
          // Store in slave memory with proper DATA_WIDTH formatting
          if (axi4_bus_matrix_h != null) begin
            axi4_bus_matrix_h.store_write(struct_write_packet.awaddr + strb, tmp_wdata);
          end else if (axi4_slave_mem_h != null) begin
            // Use local slave memory when no bus matrix
            axi4_slave_mem_h.mem_write(struct_write_packet.awaddr + strb, tmp_wdata);
          end
          `uvm_info("DEBUG_MEMORY_WRITE", $sformatf("FIXED: Stored byte 0x%02x at address 0x%16h", 
                   struct_write_packet.wdata[j][8*strb+7 -: 8], struct_write_packet.awaddr + strb), UVM_HIGH);
        end
      end
    end
  end
  if(struct_write_packet.awburst == WRITE_INCR) begin
    for(int j=0;j<(struct_write_packet.awlen+1);j++)begin
      `uvm_info("DEBUG_MEMORY_WRITE",$sformatf("memory_task_awlen=%d",struct_write_packet.awlen),UVM_HIGH)
      // This beat's address and its lowest occupied byte lane - both derived
      // from the burst, never from how many strobes were asserted.
      beat_addr = struct_write_packet.awaddr + j*beat_bytes;
      lane_base = (aligned_addr + j*beat_bytes) % STROBE_WIDTH;
        for(int strb=0;strb<STROBE_WIDTH;strb++) begin
        `uvm_info("DEBUG_MEMORY_WRITE", $sformatf("task_memory_write inside for loop wstrb = %0h,lane_base=%0d",struct_write_packet.wstrb[j],lane_base), UVM_HIGH);
        if(struct_write_packet.wstrb[j][strb] == 1) begin
          lane_off = strb - lane_base;
          if(lane_off < 0) begin
            // A strobe below this beat's active byte lanes. AXI4 A3.4.3 requires
            // those to be deasserted, so this is illegal stimulus rather than a
            // byte with an address; dropping it is preferable to writing below
            // the beat's own address.
            `uvm_info("DEBUG_MEMORY_WRITE", $sformatf("Beat %0d: WSTRB bit %0d is below this beat's lane base %0d - byte dropped (AXI4 A3.4.3)", j, strb, lane_base), UVM_MEDIUM);
            continue;
          end
          byte_addr = beat_addr + lane_off;
          tmp_wdata = '0;
          tmp_wdata[7:0] = struct_write_packet.wdata[j][8*strb+7 -: 8];
          // Store in slave memory with proper DATA_WIDTH formatting
          if (axi4_bus_matrix_h != null) begin
            axi4_bus_matrix_h.store_write(byte_addr, tmp_wdata);
          end else if (axi4_slave_mem_h != null) begin
            axi4_slave_mem_h.mem_write(byte_addr, tmp_wdata);
          end
          `uvm_info("DEBUG_MEMORY_WRITE", $sformatf("INCR: Stored byte 0x%02x at address 0x%16h (beat %0d, lane %0d, lane_base %0d)",
                   struct_write_packet.wdata[j][8*strb+7 -: 8], byte_addr, j, strb, lane_base), UVM_HIGH);
        end
      end
    end
  end
  if(struct_write_packet.awburst == WRITE_WRAP) begin
    wrap_bytes = (struct_write_packet.awlen+1)*beat_bytes;
    lower_addr = struct_write_packet.awaddr - (struct_write_packet.awaddr % wrap_bytes);
    for(int j=0;j<(struct_write_packet.awlen+1);j++)begin
      `uvm_info("DEBUG_MEMORY_WRITE",$sformatf("memory_task_awlen=%d",struct_write_packet.awlen),UVM_HIGH)
      // The wrap is now arithmetic on the BEAT address (AXI4 A3.4.1: a WRAP
      // burst's address wraps back to the wrap boundary once it reaches the
      // upper limit), instead of a byte cursor that only advanced on asserted
      // strobes and therefore moved the wrap point whenever a strobe was low.
      beat_addr = lower_addr + ((struct_write_packet.awaddr + j*beat_bytes - lower_addr) % wrap_bytes);
      lane_base = (aligned_addr + j*beat_bytes) % STROBE_WIDTH;
        for(int strb=0;strb<STROBE_WIDTH;strb++) begin
        `uvm_info("DEBUG_MEMORY_WRITE", $sformatf("task_memory_write inside for loop wstrb = %0h,lane_base=%0d",struct_write_packet.wstrb[j],lane_base), UVM_HIGH);
          if(struct_write_packet.wstrb[j][strb] == 1) begin
            lane_off = strb - lane_base;
            if(lane_off < 0) begin
              // See the identical guard in the INCR branch.
              `uvm_info("DEBUG_MEMORY_WRITE", $sformatf("Beat %0d: WSTRB bit %0d is below this beat's lane base %0d - byte dropped (AXI4 A3.4.3)", j, strb, lane_base), UVM_MEDIUM);
              continue;
            end
            byte_addr = beat_addr + lane_off;
            tmp_wdata = '0;
            tmp_wdata[7:0] = struct_write_packet.wdata[j][8*strb+7 -: 8];
            if (axi4_bus_matrix_h != null) begin
              axi4_bus_matrix_h.store_write(byte_addr, tmp_wdata);
            end else if (axi4_slave_mem_h != null) begin
              axi4_slave_mem_h.mem_write(byte_addr, tmp_wdata);
            end
            `uvm_info("DEBUG_MEMORY_WRITE", $sformatf("WRAP: Stored byte 0x%02x at address 0x%16h (beat %0d, lane %0d, lane_base %0d, wrap [0x%16h:0x%16h))",
                     struct_write_packet.wdata[j][8*strb+7 -: 8], byte_addr, j, strb, lane_base, lower_addr, lower_addr+wrap_bytes), UVM_HIGH);
          end
      end
    end
  end

endtask : task_memory_write

task axi4_slave_driver_proxy::task_memory_read(input axi4_slave_tx read_pkt,ref axi4_read_transfer_char_s struct_read_packet);
  int lower_addr,end_addr,k_t;
  if(read_pkt.arburst == READ_FIXED) begin
    for(int j=0,int k=0;j<(read_pkt.arlen+1);j++)begin
      `uvm_info("DEBUG_MEMORY_WRITE",$sformatf("memory_task_arlen=%d",read_pkt.arlen),UVM_HIGH)
      for(int strb=0;strb<(2**(read_pkt.arsize));strb++) begin
        bit [DATA_WIDTH-1:0] tmp_rdata;
        if (axi4_bus_matrix_h != null) begin
          axi4_bus_matrix_h.load_read(read_pkt.araddr, tmp_rdata);
        end else if (axi4_slave_mem_h != null) begin
          axi4_slave_mem_h.mem_read(read_pkt.araddr, tmp_rdata);
        end else begin
          tmp_rdata = '0; // Default value when no memory available
        end
        struct_read_packet.rdata[j][8*strb+7 -: 8] = tmp_rdata[7:0];
        k++;
      end
    end
    if((read_pkt.araddr+((2**(read_pkt.arsize))))> axi4_slave_agent_cfg_h.max_address) begin 
      crossed_read_addr = 1;
    end
    else crossed_read_addr = 0;
  end
  if(read_pkt.arburst == READ_INCR) begin
    for(int j=0,int k=0;j<(read_pkt.arlen+1);j++)begin
      `uvm_info("DEBUG_MEMORY_WRITE",$sformatf("memory_task_arlen=%d",read_pkt.arlen),UVM_HIGH)
        for(int strb=0;strb<(2**(read_pkt.arsize));strb++) begin
          bit [DATA_WIDTH-1:0] tmp_rdata;
          if (axi4_bus_matrix_h != null) begin
            axi4_bus_matrix_h.load_read(read_pkt.araddr+k, tmp_rdata);
          end else if (axi4_slave_mem_h != null) begin
            axi4_slave_mem_h.mem_read(read_pkt.araddr+k, tmp_rdata);
          end else begin
            tmp_rdata = '0;
          end
          struct_read_packet.rdata[j][8*strb+7 -: 8] = tmp_rdata[7:0];
          if(read_pkt.araddr+k > axi4_slave_agent_cfg_h.max_address) begin 
            crossed_read_addr = read_pkt.araddr+k;
          end
          k++;
        end
      end
    end
  if(read_pkt.arburst == READ_WRAP) begin
    lower_addr = read_pkt.araddr - int'(read_pkt.araddr%((read_pkt.arlen+1)*(2**read_pkt.arsize)));
    end_addr = lower_addr + ((read_pkt.arlen+1)*(2**read_pkt.arsize));
    k_t = read_pkt.araddr;
    for(int j=0,int k=0;j<(read_pkt.arlen+1);j++)begin
      `uvm_info("DEBUG_MEMORY_WRITE",$sformatf("memory_task_arlen=%d",read_pkt.arlen),UVM_HIGH)
        for(int strb=0;strb<(2**(read_pkt.arsize));strb++) begin
          if(k_t < end_addr)  begin
             bit [DATA_WIDTH-1:0] tmp_rdata;
             if (axi4_bus_matrix_h != null) begin
            axi4_bus_matrix_h.load_read(read_pkt.araddr+k, tmp_rdata);
          end else if (axi4_slave_mem_h != null) begin
            axi4_slave_mem_h.mem_read(read_pkt.araddr+k, tmp_rdata);
          end else begin
            tmp_rdata = '0;
          end
             struct_read_packet.rdata[j][8*strb+7 -: 8] = tmp_rdata[7:0];
             if(read_pkt.araddr+k > axi4_slave_agent_cfg_h.max_address) crossed_read_addr = read_pkt.araddr+k;
             k++;
             k_t++;
             if(k_t == end_addr) k = 0;
          end
          else begin
            bit [DATA_WIDTH-1:0] tmp_rdata;
            if (axi4_bus_matrix_h != null) begin
              axi4_bus_matrix_h.load_read(lower_addr+k, tmp_rdata);
            end else if (axi4_slave_mem_h != null) begin
              axi4_slave_mem_h.mem_read(lower_addr+k, tmp_rdata);
            end else begin
              tmp_rdata = '0;
            end
            struct_read_packet.rdata[j][8*strb+7 -: 8] = tmp_rdata[7:0];
             if(crossed_read_addr == -1) begin
               if(lower_addr+k > axi4_slave_agent_cfg_h.max_address) crossed_read_addr = lower_addr+k;
             end
            k++;
          end
        end
      end
    end
endtask : task_memory_read


task axi4_slave_driver_proxy::out_of_order_for_reads(output axi4_read_transfer_char_s oor_read_data_struct_read_packet);
 int read_wait;
 int min_backlog;
 read_wait   = 0;
 min_backlog = axi4_slave_agent_cfg_h.get_minimum_transactions;

 // Gate 1 - CORRECTNESS. Never pop from an empty queue: `pop_front()` on an
 // empty SystemVerilog queue returns a default-constructed struct, and the
 // caller drives that straight onto the R channel as an all-zero response for a
 // read nobody answered. This must hold whatever minimum_transactions is.
 //
 // What this replaces: a wait on `axi4_slave_read_addr_fifo_h.size >
 // minimum_transactions` that (a) tested the wrong direction and (b) tested the
 // wrong object. The reference VIP waits for the backlog to BUILD
 // (ref_vip/src/hvl_top/slave/axi4_slave_driver_proxy.sv:805,
 // `wait(size > minimum_transactions)`) because reordering needs several
 // pending reads to choose between; this copy waited for it to DRAIN, which in
 // ONLY_READ_RESP_OUT_OF_ORDER never happens, so every response burned 1000
 // clocks and raised "read response wait timeout". It also polled the AR fifo
 // rather than the queue actually popped below, so the empty-pop above was
 // never actually prevented - and the `minimum_transactions == 0` early-out
 // skipped the wait entirely, which is the configuration the sibling
 // out-of-order tests all select.
 while((drive_rd_id_cont == 1) ? (rd_response_id_cont_queue.size() == 0)
                               : (rd_response_id_queue.size()      == 0)) begin
   @(posedge axi4_slave_drv_bfm_h.aclk);
   if(read_wait++ > 1000) begin
     `uvm_error("slave_driver_proxy","read response wait timeout: no read pending to respond to")
     break;
   end
 end

 // Gate 2 - REORDER QUALITY, best effort, never an error. Let a backlog of more
 // than minimum_transactions accumulate so the shuffle below has something to
 // reorder. Bounded, because a manager that simply has no more reads in flight
 // must not stall the R channel: responding in order is a weaker stimulus, not
 // a failure.
 read_wait = 0;
 while(drive_rd_id_cont == 0 && rd_response_id_queue.size() <= min_backlog && read_wait < 50) begin
   @(posedge axi4_slave_drv_bfm_h.aclk);
   read_wait++;
 end
 `uvm_info("slave_driver_proxy",$sformatf("fifo_size = %0d",axi4_slave_read_addr_fifo_h.used()),UVM_HIGH)
 if(drive_rd_id_cont == 1 && rd_response_id_cont_queue.size() > 0) begin
   oor_read_data_struct_read_packet = rd_response_id_cont_queue.pop_front();
   if(rd_response_id_cont_queue.size()==0) drive_rd_id_cont = 1'b0;
 end
 else if(rd_response_id_queue.size() > 0) begin
   rd_response_id_queue.shuffle();
   oor_read_data_struct_read_packet = rd_response_id_queue.pop_front();
 end
 // else: gate 1 timed out and already raised the error. Falling through without
 // a pop leaves the caller's packet as the output default rather than silently
 // consuming an unrelated entry from the other queue.
endtask : out_of_order_for_reads

//--------------------------------------------------------------------------------------------
// Function: setup_exclusive_monitor
// Sets up exclusive monitor for exclusive read access per AMBA AXI4 specification
// Parameters:
//  addr      - Address for exclusive monitor
//  master_id - Master ID that performed exclusive read
//  size      - Transfer size
//  len       - Transfer length
//--------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------
// Function: mid_safe_write_resp / mid_safe_read_resp
//
// The access matrix answers a per-manager question, so it needs a manager. Behind
// the fabric that identity arrives in AxUSER (AXI4_MID_TAG); on traffic that does
// not carry the tag the subordinate simply cannot know who issued the transfer.
// Guessing it from the egress AxID denied legal in-range transfers -- observed as
// "Response mismatch for address 0x0000000800001058: expected WRITE_OKAY, got
// WRITE_DECERR" while the very same bus matrix logged that address decoding to
// slave 0.
//
// Address DECODE is still knowable without a manager, and an unmapped address is
// still a DECERR, so only the permission half is dropped. The scoreboard holds
// the true master port index and keeps checking permissions there.
//--------------------------------------------------------------------------------------------
function bresp_e axi4_slave_driver_proxy::mid_safe_write_resp(int mid, bit [ADDRESS_WIDTH-1:0] addr, bit [2:0] awprot);
  if (mid >= 0) return axi4_bus_matrix_h.get_write_resp(mid, addr, awprot);
  return (axi4_bus_matrix_h.decode(addr) < 0) ? WRITE_DECERR : WRITE_OKAY;
endfunction : mid_safe_write_resp

function rresp_e axi4_slave_driver_proxy::mid_safe_read_resp(int mid, bit [ADDRESS_WIDTH-1:0] addr, bit [2:0] arprot);
  if (mid >= 0) return axi4_bus_matrix_h.get_read_resp(mid, addr, arprot);
  return (axi4_bus_matrix_h.decode(addr) < 0) ? READ_DECERR : READ_OKAY;
endfunction : mid_safe_read_resp

function void axi4_slave_driver_proxy::setup_exclusive_monitor(bit [ADDRESS_WIDTH-1:0] addr, bit [15:0] master_id, bit [7:0] size, bit [7:0] len);
  int monitor_idx = -1;
  
  // Find an empty monitor slot or reuse existing one for same address/master
  for(int i = 0; i < 16; i++) begin
    if(!exclusive_monitor[i].valid) begin
      monitor_idx = i;
      break;
    end else if(exclusive_monitor[i].address == addr && exclusive_monitor[i].master_id == master_id) begin
      monitor_idx = i;
      break;
    end
  end
  
  // If no empty slot, replace the oldest (simple replacement policy)
  if(monitor_idx == -1) begin
    monitor_idx = 0;
    `uvm_info("EXCLUSIVE_MONITOR", "No empty monitor slots - replacing monitor 0", UVM_LOW);
  end
  
  // Setup the monitor
  exclusive_monitor[monitor_idx].address = addr;
  exclusive_monitor[monitor_idx].master_id = master_id;
  exclusive_monitor[monitor_idx].size = size;
  exclusive_monitor[monitor_idx].len = len;
  exclusive_monitor[monitor_idx].valid = 1'b1;
  
  `uvm_info("EXCLUSIVE_MONITOR", $sformatf("Monitor %0d setup: addr=0x%16h, master=%0d, size=%0d, len=%0d", 
           monitor_idx, addr, master_id, size, len), UVM_MEDIUM);
endfunction : setup_exclusive_monitor

//--------------------------------------------------------------------------------------------
// Function: check_exclusive_monitor
// Checks if exclusive write should succeed based on exclusive monitors
// Returns: 1 if exclusive write should succeed (EXOKAY), 0 if it should fail (OKAY)
// Parameters:
//  addr      - Address for exclusive write
//  master_id - Master ID performing exclusive write
//--------------------------------------------------------------------------------------------
function bit axi4_slave_driver_proxy::check_exclusive_monitor(bit [ADDRESS_WIDTH-1:0] addr, bit [15:0] master_id);
  for(int i = 0; i < 16; i++) begin
    if(exclusive_monitor[i].valid && 
       exclusive_monitor[i].address == addr && 
       exclusive_monitor[i].master_id == master_id) begin
      `uvm_info("EXCLUSIVE_MONITOR", $sformatf("Monitor %0d MATCH for exclusive write: addr=0x%16h, master=%0d", 
               i, addr, master_id), UVM_MEDIUM);
      return 1'b1; // Exclusive access should succeed
    end
  end
  
  `uvm_info("EXCLUSIVE_MONITOR", $sformatf("NO MATCH for exclusive write: addr=0x%16h, master=%0d", 
           addr, master_id), UVM_MEDIUM);
  return 1'b0; // Exclusive access failed
endfunction : check_exclusive_monitor

//--------------------------------------------------------------------------------------------
// Function: clear_exclusive_monitors
// Clears exclusive monitors that overlap with the given address (per AXI4 spec)
// Parameters:
//  addr - Address that invalidates exclusive monitors
//--------------------------------------------------------------------------------------------
function void axi4_slave_driver_proxy::clear_exclusive_monitors(bit [ADDRESS_WIDTH-1:0] addr);
  int cleared_count = 0;
  
  for(int i = 0; i < 16; i++) begin
    if(exclusive_monitor[i].valid) begin
      // Calculate address range for this monitor
      bit [ADDRESS_WIDTH-1:0] monitor_start = exclusive_monitor[i].address;
      bit [ADDRESS_WIDTH-1:0] monitor_end = monitor_start + ((exclusive_monitor[i].len + 1) * (2 ** exclusive_monitor[i].size)) - 1;
      
      // Check if addresses overlap (simple overlap check)
      if(addr >= monitor_start && addr <= monitor_end) begin
        `uvm_info("EXCLUSIVE_MONITOR", $sformatf("Clearing monitor %0d due to overlapping write at 0x%16h (monitor range: 0x%16h-0x%16h)", 
                 i, addr, monitor_start, monitor_end), UVM_MEDIUM);
        exclusive_monitor[i].valid = 1'b0;
        cleared_count++;
      end
    end
  end
  
  if(cleared_count > 0) begin
    `uvm_info("EXCLUSIVE_MONITOR", $sformatf("Cleared %0d exclusive monitors due to write at 0x%16h", 
             cleared_count, addr), UVM_LOW);
  end
endfunction : clear_exclusive_monitors

//--------------------------------------------------------------------------------------------
// Function: invalidate_all_exclusive_monitors  
// Invalidates all exclusive monitors (used for system-wide events)
//--------------------------------------------------------------------------------------------
function void axi4_slave_driver_proxy::invalidate_all_exclusive_monitors();
  int cleared_count = 0;
  
  for(int i = 0; i < 16; i++) begin
    if(exclusive_monitor[i].valid) begin
      exclusive_monitor[i].valid = 1'b0;
      cleared_count++;
    end
  end
  
  `uvm_info("EXCLUSIVE_MONITOR", $sformatf("Invalidated all %0d exclusive monitors", cleared_count), UVM_LOW);
endfunction : invalidate_all_exclusive_monitors

`endif
