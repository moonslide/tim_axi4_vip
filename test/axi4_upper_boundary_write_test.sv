`ifndef AXI4_UPPER_BOUNDARY_WRITE_TEST_INCLUDED_
`define AXI4_UPPER_BOUNDARY_WRITE_TEST_INCLUDED_

class axi4_upper_boundary_write_test extends axi4_base_test;
  `uvm_component_utils(axi4_upper_boundary_write_test)

  axi4_virtual_upper_boundary_write_seq vseq;

  extern function new(string name="axi4_upper_boundary_write_test", uvm_component parent=null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
endclass

function axi4_upper_boundary_write_test::new(string name, uvm_component parent=null);
  super.new(name,parent);
endfunction

function void axi4_upper_boundary_write_test::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Override write_read_mode for write-only test
  axi4_env_cfg_h.write_read_mode_h = ONLY_WRITE_DATA;
  
  // Enable error injection mode to convert UVM_ERROR to UVM_WARNING for expected errors
  axi4_env_cfg_h.error_inject = 1;
  
  // Update the config_db with modified configuration
  uvm_config_db #(axi4_env_config)::set(this,"*","axi4_env_config",axi4_env_cfg_h);
endfunction

task axi4_upper_boundary_write_test::run_phase(uvm_phase phase);
  bit seq_done;
  vseq = axi4_virtual_upper_boundary_write_seq::type_id::create("vseq");
  phase.raise_objection(this);
  seq_done = 0;
  fork
    begin
      vseq.start(axi4_env_h.axi4_virtual_seqr_h);
      seq_done = 1;
    end
    begin : timeout_watch
      #1us;
      if(!seq_done) begin
        `uvm_error(get_type_name(),"vseq timeout or driver blocked")
      end
    end
  join_any
  phase.drop_objection(this);
  if(phase.phase_done.get_objection_total(this) != 0)
    `uvm_warning(get_type_name(),"objection count non-zero after drop")
endtask

`endif
