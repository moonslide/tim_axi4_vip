// AXI_data_integrity.md F8 -- the RED build for the memory-model byte-collapse fix.
// Identical to ../axi4_compile.f EXCEPT for the incdir below, which prepends the
// pre-fix (word-granular, DATA_WIDTH-aligned) axi4_bus_matrix_ref so VCS resolves
//   `include "axi4_bus_matrix_ref.sv"
// to it instead of to the byte-granular working-tree file. Everything else --
// including the re-enabled verify_read() checker -- is the live tree.
// Recreate the staged file with:
//   git show a9017e8:bm/axi4_bus_matrix_ref.sv > f8pre/axi4_bus_matrix_ref.sv
+incdir+./f8pre
+incdir+../../pkg/
+incdir+../../include/
+incdir+../../seq/master_sequences/
+incdir+../../master/
+incdir+../../agent/master_agent_bfm/ 
+incdir+../../virtual_seqr/
+incdir+../../virtual_seq/
+incdir+../../env
+incdir+../../bm
+incdir+../../slave
+incdir+../../seq/slave_sequences/
+incdir+../../test
+incdir+../../agent/slave_agent_bfm
+incdir+../../intf/axi4_interface
../../pkg/axi4_globals_pkg.sv
../../master/axi4_master_pkg.sv
../../bm/axi4_bus_matrix_pkg.sv
../../slave/axi4_slave_pkg.sv
../../seq/master_sequences/axi4_master_seq_pkg.sv
../../seq/slave_sequences/axi4_slave_seq_pkg.sv
../../env/axi4_env_pkg.sv
../../virtual_seq/axi4_virtual_seq_pkg.sv
../../test/axi4_test_pkg.sv
../../intf/axi4_interface/axi4_if.sv
../../agent/master_agent_bfm/axi4_master_driver_bfm.sv
../../agent/master_agent_bfm/axi4_master_monitor_bfm.sv
../../agent/master_agent_bfm/axi4_master_agent_bfm.sv
../../agent/slave_agent_bfm/axi4_slave_driver_bfm.sv
../../agent/slave_agent_bfm/axi4_slave_monitor_bfm.sv
../../agent/slave_agent_bfm/axi4_slave_agent_bfm.sv
../../top/hdl_top.sv
../../top/hvl_top.sv
../../assertions/master_assertions.sv
../../assertions/slave_assertions.sv

// All master sequences are included via the package file above
// No individual sequence files needed here

// All virtual sequences are included via the package file above
// No individual virtual sequence files needed here

// All test files are included via the package file above
// No individual test files needed here

