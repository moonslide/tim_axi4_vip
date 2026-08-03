# Quick reference — tim_axi4_vip (verified 2026-08-01)

Build/run/test-select/pass-criteria: see project `CLAUDE.md` (single source).

| Thing | Where |
|---|---|
| Compile filelists | `sim/axi4_compile.f` (baseline), `sim/axi4_compile_nic400.f` (Track-B) |
| Regression lists (x2, keep in sync) | `sim/` and `testlists/axi4_transfers_regression.list` |
| Fabric RTL (golden, do not edit) | `ext/nic400_vipv3b/` |
| Fabric sanity | `bash sim/run_fabric_smoke.sh` → 3/3 PASS |
| Fabric generation (remote) | `192.168.77.84:/home/timchen/fabric_test/RECORD.md` |
| Spec / plan / debug notes | `claude.md` / `VIP_future.md` / `TRACKB_DEBUG_NOTES.md` |
| Slave count/mode config | `test/axi4_base_test.sv` (+BUS_MATRIX_MODE=...) |
