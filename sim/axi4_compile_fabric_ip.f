// Track-B compile filelist: VIP + commercial fabric IP (arbitrated fabric DUT).
// Use together with:
//   +define+BUS_MATRIX_FABRIC_IP +define+DATA_WIDTH=256 +define+AXI_ID_WIDTH=8 +define+AXI_ID_LAST=255
//
// Paths are relative to sim/<simulator>/ like axi4_compile.f.
-f ../../sim/axi4_compile.f

// generated fabric IP (ext/nic400_vipv3b) + vectorised wrapper
-f ../../sim/fabric_ip_rtl.f
../../top/axi4_fabric_ip_wrapper.sv
