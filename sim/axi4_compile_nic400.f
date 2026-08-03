// Track-B compile filelist: VIP + ARM CoreLink NIC-400 arbitrated fabric DUT.
// Use together with:
//   +define+BUS_MATRIX_NIC400 +define+DATA_WIDTH=256 +define+AXI_ID_WIDTH=8 +define+AXI_ID_LAST=255
//
// Paths are relative to sim/<simulator>/ like axi4_compile.f.
-f ../../sim/axi4_compile.f

// generated NIC-400 fabric (ext/nic400_vipv3b) + vectorised wrapper
-f ../../sim/nic400_rtl.f
../../top/axi4_nic400_fabric_wrapper.sv
