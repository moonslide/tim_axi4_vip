`ifndef AXI4_UPPER_BOUNDARY_WRITE_TEST_INCLUDED_
`define AXI4_UPPER_BOUNDARY_WRITE_TEST_INCLUDED_

class axi4_upper_boundary_write_test extends axi4_base_test;
  `uvm_component_utils(axi4_upper_boundary_write_test)

  axi4_virtual_upper_boundary_write_seq vseq;

  extern function new(string name="axi4_upper_boundary_write_test", uvm_component parent=null);
  extern virtual task run_phase(uvm_phase phase);
endclass

function axi4_upper_boundary_write_test::new(string name, uvm_component parent=null);
  super.new(name,parent);
endfunction

task axi4_upper_boundary_write_test::run_phase(uvm_phase phase);
  vseq = axi4_virtual_upper_boundary_write_seq::type_id::create("vseq");
  phase.raise_objection(this);
  bit seq_done = 0;
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
  if(phase.get_objection_total() != 0)
    `uvm_warning(get_type_name(),"objection count non-zero after drop")
endtask

`endif
