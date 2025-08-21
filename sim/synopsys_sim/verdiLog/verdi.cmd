verdiSetActWin -dock widgetDock_<Decl._Tree>
debImport "-elab" "simv.daidir/kdb"
debLoadSimResult \
           /home/timtim01/eda_test/project/vip_test0/tim_axi4_vip/sim/synopsys_sim/default.fsdb
wvCreateWindow
verdiSetActWin -win $_nWave2
verdiWindowResize -win $_Verdi_1 "1270" "297" "900" "700"
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "hdl_top.master_intf\[0\]" -win $_nTrace1
srcSetScope "hdl_top.master_intf\[0\]" -delim "." -win $_nTrace1
srcHBSelect "hdl_top.master_intf\[0\]" -win $_nTrace1
verdiWindowResize -win $_Verdi_1 "531" "481" "900" "700"
srcDeselectAll -win $_nTrace1
srcSelect -signal "awcache" -line 23 -pos 1 -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcDeselectAll -win $_nTrace1
srcSelect -signal "awvalid" -line 28 -pos 1 -win $_nTrace1
wvAddSignal -win $_nWave2 "/hdl_top/master_intf\[0\]/awvalid"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvZoomAll -win $_nWave2
verdiSetActWin -win $_nWave2
wvZoomAll -win $_nWave2
srcHBSelect "hdl_top.axi4_master_agent_bfm\[0\]" -win $_nTrace1
srcSetScope "hdl_top.axi4_master_agent_bfm\[0\]" -delim "." -win $_nTrace1
srcHBSelect "hdl_top.axi4_master_agent_bfm\[0\]" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "hdl_top.axi4_master_agent_bfm\[0\].axi4_master_agent_bfm_h" -win \
           $_nTrace1
srcSetScope "hdl_top.axi4_master_agent_bfm\[0\].axi4_master_agent_bfm_h" -delim \
           "." -win $_nTrace1
srcHBSelect "hdl_top.axi4_master_agent_bfm\[0\].axi4_master_agent_bfm_h" -win \
           $_nTrace1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
verdiWindowResize -win $_Verdi_1 "1952" "632" "900" "700"
