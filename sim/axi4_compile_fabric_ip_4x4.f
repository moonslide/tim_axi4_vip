// Track-B 4x4 compile filelist: VIP + the 4x4 QoS commercial fabric IP.
//
// Use together with:
//   +define+BUS_MATRIX_FABRIC_IP +define+FABRIC_IP_4X4
//   +define+DATA_WIDTH=256 +define+AXI_ID_WIDTH=6 +define+AXI_ID_LAST=63
//
// The fabric in ext/nic400_vip4x4q carries the VIP's BASE (4x4) bus-matrix
// memory map in its decoder, so +BUS_MATRIX_MODE=4x4 lines up with the RTL.
// GlobalIDWidth is 6 (VIDWidth 4 + 2 bits of ingress index), hence AXI_ID_WIDTH=6.
//
// Paths are relative to sim/<simulator>/ like axi4_compile.f.
-f ../../sim/axi4_compile.f

// generated fabric IP 4x4 QoS fabric + vectorised wrapper
-f ../../sim/fabric_ip_4x4_rtl.f
../../top/axi4_fabric_ip_wrapper_4x4.sv
