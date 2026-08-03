# EDA Tool Inventory (verified 2026-07-03, /home/eda_tools)

Tools are INSTALLED; several flows are not yet stood up in this tree —
standing them up is in-scope work for the owning agent, not a blocker.

| Tool | Path | Version | Owner agent |
|---|---|---|---|
| VCS (sim) | `/home/eda_tools/synopsys/vcs/W-2024.09-SP1/bin/vcs` | W-2024.09-SP1 | dv-build-engineer |
| Verdi (debug) | `/home/eda_tools/synopsys/verdi/W-2024.09-SP1/bin/verdi` | W-2024.09-SP1 | dv-wave-debugger |
| Design Compiler | `/home/eda_tools/synopsys/syn/V-2023.12-SP3/bin/dc_shell` | V-2023.12-SP3 | syn-timing-engineer |
| PrimeTime (STA) | `/home/eda_tools/synopsys/prime/V-2023.12-SP1/bin/pt_shell` | V-2023.12-SP1 | syn-timing-engineer |
| SpyGlass (lint/CDC/RDC) | `/home/eda_tools/synopsys/spyglass/ufe_optional_spyglass-vcs/V-2023.12-SP1/SPYGLASS_HOME/bin/{spyglass,sg_shell}` | V-2023.12-SP1 | static-signoff-engineer |
| VC Static | `/home/eda_tools/synopsys/vc_static/V-2023.12-SP1` | V-2023.12-SP1 | static-signoff-engineer |
| Formality (LEC) | `/home/eda_tools/synopsys/fm/fm/V-2023.12-SP3/bin/fm_shell` | V-2023.12-SP3 | static-signoff-engineer |
| ARM GCC | `/home/eda_tools/arm/gcc-arm-none-eabi-10-2020-q4-major/bin` | 10-2020-q4 | dv-fw-test-author |
| ZeBu runtime | zRci wrappers in `$OOBTB/zebu_prj/runtime/`, `zCui` | (cluster) | zebu-emulation-engineer |
| Cadence suite / hspice / waveview / custom_comp / esp | `/home/eda_tools/{cadence,hspice,waveview,custom_comp,esp}` | various | (analog/mixed — no agent yet) |
| LSF (volclava) | `/home/volclava-2.0/bin` (bsub/bjobs/bkill) | 2.0 | dv-regression-runner |

Rules: quote versions in sign-off evidence; a flow "not yet stood up" is a
task (owning agent builds it, documents it here + quick-reference), never
an excuse; licenses come from the sourced environment profile.
