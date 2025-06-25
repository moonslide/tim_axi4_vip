`ifndef AXI4_BOUNDARY_WRITE_INCR_ACROSS_4KB_TEST_INCLUDED_
`define AXI4_BOUNDARY_WRITE_INCR_ACROSS_4KB_TEST_INCLUDED_
class axi4_boundary_write_incr_across_4kb_test extends axi4_base_test;
  `uvm_component_utils(axi4_boundary_write_incr_across_4kb_test)
  axi4_virtual_bk_boundary_single_seq seq_h;
  function new(string name="axi4_boundary_write_incr_across_4kb_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    for(int i=0;i<NO_OF_SLAVES;i++) begin
      seq_h = axi4_virtual_bk_boundary_single_seq::type_id::create($sformatf("seq_h%0d", i));
      seq_h.is_write = 1;
      seq_h.addr = 12'h0FFC;
      seq_h.len_valid = 1;
      seq_h.len = 1;
      seq_h.burst_valid = 1;
      seq_h.burst = WRITE_INCR;
      seq_h.slave_idx = i;
      seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
    end
    phase.drop_objection(this);
  endtask
endclass
`endif

