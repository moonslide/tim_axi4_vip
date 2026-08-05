`ifndef AXI4_MASTER_REFUSED_WRITE_SHADOW_SEQ_INCLUDED_
`define AXI4_MASTER_REFUSED_WRITE_SHADOW_SEQ_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: axi4_master_refused_write_shadow_seq
//
// Write half of the AXI_ooo.md Phase 3 (third fix pass) directed test for the
// same-ID checker's WRITE-SHADOW COMMIT GATE. Runs on MASTER 7.
//
// THE ONE FACT THIS SEQUENCE IS BUILT AROUND
//   axi4_scoreboard::store_write() (env/axi4_scoreboard.sv:2540-2562) writes the
//   manager's W data into axi4_bus_matrix_h -- the SAME reference model the
//   subordinate answers SLAVE_MEM_MODE reads out of -- UNCONDITIONALLY, with no
//   reference to BRESP. So in this bench a write the subordinate REFUSES is still
//   readable afterwards. Measured, not assumed.
//   The write shadow therefore has to record what MEMORY ends up holding. A gate
//   that refuses a write memory took anyway leaves the shadow stale, the next read
//   of that address mismatches its head, and any same-ID sibling holding the value
//   memory really returns gets convicted. That is the false positive below.
//
// THE ADDRESSES (ENHANCED map, bm/axi4_bus_matrix_ref.sv::configure_enhanced_matrix)
//   S7 "Secure-Only" 0x0000_000A_0002_0000 .. 0x0000_000A_0002_FFFF. It is also
//   slave AGENT 7's own range (test/axi4_base_test.sv::setup_enhanced_slave_agent_cfg)
//   and this bench wires master 7 straight to agent 7, so reads of it come out of
//   memory rather than the generated-data branch.
//     ADDR_W = 0xA_0002_1000   the address whose shadow gets poisoned
//     ADDR_Z = 0xA_0002_2000   the innocent same-ID sibling (different DATA_WIDTH window)
//
// WHY MASTER 7 AND WHY AWPROT
//   get_write_resp() runs a security check on S7:
//       check_security_access(master, 7, ~awprot[1]) -> master_is_secure[m] || is_secure_req
//   Master 7 is NOT a secure master (bm/axi4_bus_matrix_ref.sv:402), so for master 7
//   the PREDICTION for one and the same address flips purely on AWPROT[1]:
//       awprot = WRITE_NORMAL_SECURE_DATA    (3'b000) -> WRITE_OKAY
//       awprot = WRITE_NORMAL_NONSECURE_DATA (3'b010) -> WRITE_SLVERR
//   That is the cleanest possible probe of a gate that decides from a prediction:
//   same port, same address, same beat, two different predicted answers, and
//   store_write() commits BOTH to memory either way.
//
// THE THREE WRITES
//   step 1  W, awprot=SECURE,     payload 0xAA -> predicted OKAY. Shadowed by every
//           version of the gate. Memory[W] = 0xAA.
//   step 2  Z, awprot=SECURE,     payload 0xCC -> predicted OKAY. Shadowed. Memory[Z] = 0xCC.
//   step 3  W, awprot=NONSECURE,  payload 0xCC -> predicted SLVERR, and the
//           subordinate really does answer SLVERR and skip task_memory_write --
//           but store_write() has already put 0xCC in the bus matrix, so
//           MEMORY[W] IS NOW 0xCC.
//             * PRE-FIX gate (predicted, W channel): refuses -> shadow[W] stays 0xAA.
//             * strict observed-BRESP gate:          refuses -> shadow[W] stays 0xAA.
//             * FIXED gate (mirrors store_write):    shadows -> shadow[W] = 0xCC.
//
// Payloads are byte-replicated and non-zero: the only shape that survives this
// bench's memory model (AXI_data_integrity.md F8) and therefore the only shape
// sb_sameid_beat_known()'s survivability gate will adjudicate on. W and Z are in
// different DATA_WIDTH-aligned windows, so neither window is poisoned.
//
// This sequence proves nothing on its own; see axi4_refused_write_shadow_test.
//--------------------------------------------------------------------------------------------
class axi4_master_refused_write_shadow_seq extends axi4_master_nbk_base_seq;
  `uvm_object_utils(axi4_master_refused_write_shadow_seq)

  // The address whose shadow the refused write poisons.
  static function bit [63:0] addr_w();
    return 64'h0000_000A_0002_1000;
  endfunction : addr_w

  // The innocent same-ID sibling, in a different DATA_WIDTH-aligned window.
  static function bit [63:0] addr_z();
    return 64'h0000_000A_0002_2000;
  endfunction : addr_z

  static function bit [7:0] tag_old();  return 8'hAA; endfunction   // W's first content
  static function bit [7:0] tag_new();  return 8'hCC; endfunction   // what memory really ends up holding

  function new(string name = "axi4_master_refused_write_shadow_seq");
    super.new(name);
  endfunction : new

  // One single-beat, full-width, byte-uniform write.
  local task do_full_beat_write(string tag, bit [63:0] addr, bit [7:0] fill,
                                awid_e awid_v, awprot_e prot_v);
    axi4_master_tx tx;
    tx = axi4_master_tx::type_id::create(tag);
    start_item(tx);
    if (!tx.randomize() with {
      tx.tx_type       == WRITE;
      tx.transfer_type == NON_BLOCKING_WRITE;
      tx.awid          == local::awid_v;
      tx.awaddr        == local::addr;
      tx.awlen         == 0;
      tx.awsize        == WRITE_128_BYTES;
      tx.awburst       == WRITE_INCR;
      tx.awlock        == WRITE_NORMAL_ACCESS;
      tx.awcache       == 4'h0;
      tx.awprot        == local::prot_v;
      tx.awuser        == 4'h0;
      tx.wuser         == 4'h0;
      tx.wdata.size()  == 1;
      tx.wstrb.size()  == 1;
      tx.wdata[0]      == {(DATA_WIDTH/8){local::fill}};
      tx.wstrb[0]      == {(DATA_WIDTH/8){1'b1}};
    }) `uvm_fatal(get_type_name(), $sformatf("randomize() failed for %s", tag))
    `uvm_info(get_type_name(),
              $sformatf("REFUSED_SHADOW write %s: ADDR=0x%016h fill=0x%02h awprot=%s",
                        tag, addr, fill, prot_v.name()), UVM_LOW)
    finish_item(tx);
  endtask : do_full_beat_write

  task body();
    // super.body() intentionally not called -- several writes in flight, so a shared
    // `req` handle is unsafe (same reason as axi4_master_same_id_nonadjacent_preload_seq).

    // step 1: W gets 0xAA, predicted and answered OKAY.
    do_full_beat_write("refused_shadow_w_okay", addr_w(), tag_old(), AWID_1,
                       WRITE_NORMAL_SECURE_DATA);
    // step 2: the innocent sibling Z gets 0xCC, predicted and answered OKAY.
    do_full_beat_write("refused_shadow_z_okay", addr_z(), tag_new(), AWID_2,
                       WRITE_NORMAL_SECURE_DATA);
    // step 3: W again with 0xCC, this time NON-SECURE -> predicted AND answered
    // SLVERR, task_memory_write skipped -- but store_write() already committed
    // 0xCC into the model the reads come from.
    do_full_beat_write("refused_shadow_w_slverr", addr_w(), tag_new(), AWID_3,
                       WRITE_NORMAL_NONSECURE_DATA);
  endtask : body

endclass : axi4_master_refused_write_shadow_seq

`endif
