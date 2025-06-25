`ifndef AXI4_BOUNDARY_WRITE_READ_TEST_INCLUDED_
`define AXI4_BOUNDARY_WRITE_READ_TEST_INCLUDED_
class axi4_boundary_write_read_test extends axi4_base_test;
  `uvm_component_utils(axi4_boundary_write_read_test)

  axi4_virtual_bk_boundary_write_read_seq boundary_seq_h;

  function new(string name="axi4_boundary_write_read_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    for(int i=0;i<NO_OF_SLAVES;i++) begin
      boundary_seq_h = axi4_virtual_bk_boundary_write_read_seq::type_id::create($sformatf("boundary_seq_h%0d", i));
      boundary_seq_h.slave_idx = i;
      boundary_seq_h.start(axi4_env_h.axi4_virtual_seqr_h);
    end
    phase.drop_objection(this);
  endtask
endclass
`endif
