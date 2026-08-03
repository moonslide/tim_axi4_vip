# Codex UVM VIP Code Review

結論：截至 2026-08-02 21:38 CST 的 current worktree 仍不建議合併或發布；確認 8 個 P1 與 2 個 P2 findings。完整 Track-B compile、固定 seed smoke 與 standalone fabric smoke 雖然通過，但沒有覆蓋下列 reorder、backpressure、sparse WSTRB、非零 BUSER 與 coverage-integrity 路徑。

## Review 基準

- 綁定樹：`/home/timtim01/eda_test/project/tim_axi4_vip`
- 基準 HEAD：`d09a68f50ddcff4b991bd695fffbe001ec0f09ae`
- 證據截止：2026-08-02 21:38 CST；功能 source 最後異動為 21:24，之後只有 simulator 產物更新
- Worktree：34 個 tracked files modified、21 個 untracked entries；tracked diff 為 3,480 insertions / 703 deletions
- 範圍：目前完整 worktree，重點為 BFM handshake、monitor/converter、scoreboard、coverage，以及 Track-B/NIC-400 test/build flow
- 嚴重度：P1 = 可能造成 protocol violation、false PASS/FAIL、交易遺失或無界 regression，視為 release blocker；P2 = checker/coverage 正確性缺口，應在 closure 前修正
- 本次除重寫本報告外，未修改功能 source

審查期間另一個 session 同步修改了 source。本報告已捨棄舊 snapshot 的 findings，重新以以上 cutoff 的 current worktree 編譯、執行並逐項查核。

## Findings

### 1. [P1] Scoreboard completeness 在 passive 與 error-injection 模式仍可 fail open

`check_phase()` 在所有 slave agent 為 passive 時直接返回，位置早於 completeness check；但 passive agent 的 monitor 仍會建立並連到 scoreboard。因此 passive DUT/VIP integration test 即使有 queued、in-flight 或 unmatched transaction，也不會執行 C1–C5 accounting。

- [env/axi4_scoreboard.sv:1280](env/axi4_scoreboard.sv#L1280)：`all_slaves_passive` 直接 `return`
- [env/axi4_scoreboard.sv:1300](env/axi4_scoreboard.sv#L1300)：C1–C5 completeness check 位於該 return 之後
- [slave/axi4_slave_agent.sv:71](slave/axi4_slave_agent.sv#L71)、[env/axi4_env.sv:286](env/axi4_env.sv#L286)：passive monitor 仍存在並連接 analysis path
- [test/axi4_write_test.sv:42](test/axi4_write_test.sv#L42)、[test/axi4_write_test.sv:61](test/axi4_write_test.sv#L61)：現有 test 將 slave 設為 passive，但仍啟動 master traffic

Error-injection 分支雖已先執行 C1–C5，卻在 raw FIFO empty checks 之前返回；C1–C5 只統計已由 worker `get()` 的項目、holding pools 與 outstanding IDs，不檢查仍留在 analysis FIFO、尚未被 worker 取出的項目。

- [env/axi4_scoreboard.sv:1305](env/axi4_scoreboard.sv#L1305)：error-injection guard 返回
- [env/axi4_scoreboard.sv:1821](env/axi4_scoreboard.sv#L1821)：raw FIFO checks 因而不可達
- [env/axi4_scoreboard.sv:2930](env/axi4_scoreboard.sv#L2930)：C1–C5 沒有 raw FIFO size check

影響：特別是 reset/abort/near-timeout/error-injection 測試，analysis item 若停在 FIFO 或 passive guard 後，可能在未完成比較時結束。建議把單一 accounting + raw FIFO completeness gate 放在所有模式 guard 之前；模式 guard 只應略過不適用的欄位相等比較。

### 2. [P1] Track-B 10x10 topology 沒有由 test 自我綁定，缺少 plusarg 時靜默退化成 NONE/4x4

`axi4_trackb_smoke_test` 與其 coverage subclass 沒有發布 `ENHANCED/10x10` test config；名稱分類也不認得 `trackb`，因此依賴 `+BUS_MATRIX_MODE=ENHANCED`。省略或拼錯 plusarg 時，test 不會 fail fast，而是開始以 `NONE/4x4` reference model 執行。

- [test/axi4_test_config.sv:51](test/axi4_test_config.sv#L51)：test-name classification 無 Track-B 規則
- [test/axi4_test_config.sv:113](test/axi4_test_config.sv#L113)：DEFAULT 為 `NONE`, 4 masters, 4 slaves
- [test/axi4_trackb_smoke_test.sv:60](test/axi4_trackb_smoke_test.sv#L60)：build phase 只調 checker knobs，未發布 topology
- [test/axi4_trackb_cov_sweep_test.sv:17](test/axi4_trackb_cov_sweep_test.sv#L17)：coverage sweep 繼承相同缺口
- [test/axi4_trackb_4x4_smoke_test.sv:36](test/axi4_trackb_4x4_smoke_test.sv#L36)：4x4 subclass 反而有正確的 self-binding，可作對照
- [bm/axi4_bus_matrix_ref.sv:220](bm/axi4_bus_matrix_ref.sv#L220)、[bm/axi4_bus_matrix_ref.sv:287](bm/axi4_bus_matrix_ref.sv#L287)：NONE 將地址導向 slave 0 並回 OKAY

動態 probe（未給 topology plusarg）：

```text
/tmp/codex_trackb_default_config_probe_medium.log:79-81
Category=DEFAULT_TESTS, Bus_Matrix=NONE, Masters=4, Slaves=4

/tmp/codex_trackb_default_config_probe_medium.log:1019
Driving 4 masters at slave region S2
```

影響：10x10 DUT 可能只被 4 個 master 驅動，expected decode/response 也來自錯誤 reference mode。建議 Track-B test class 在 `super.build_phase()` 前發布固定 topology，並對不相符 plusarg `uvm_fatal`。

### 3. [P1] Reactive slave 遺失 AxLOCK/AxCACHE/AxREGION，並把未觀測語意留給 dummy transaction

Write address capture 只保存 ID/address/len/size/burst/QoS/PROT/USER，沒有 AWLOCK/AWCACHE/AWREGION；read address sampling 同樣沒有保存 ARLOCK/ARCACHE/ARREGION。SLAVE_MEM_MODE 的 proxy 卻先 randomize dummy transaction，再只覆寫 BFM 有採樣的欄位。

- [agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:235](agent/slave_agent_bfm/axi4_slave_driver_bfm.sv#L235)、[agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:308](agent/slave_agent_bfm/axi4_slave_driver_bfm.sv#L308)、[agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:367](agent/slave_agent_bfm/axi4_slave_driver_bfm.sv#L367)：AW capture/copy 缺三個欄位
- [agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:697](agent/slave_agent_bfm/axi4_slave_driver_bfm.sv#L697)：AR sampling/copy 缺三個欄位
- [slave/axi4_slave_driver_proxy.sv:217](slave/axi4_slave_driver_proxy.sv#L217)、[slave/axi4_slave_driver_proxy.sv:744](slave/axi4_slave_driver_proxy.sv#L744)：reactive write/read dummy transaction 被 randomize
- [slave/axi4_slave_tx.sv:45](slave/axi4_slave_tx.sv#L45)、[slave/axi4_slave_tx.sv:126](slave/axi4_slave_tx.sv#L126)：遺失欄位有的保持零、有的可為隨機值；`arregion` 還只有 1 bit
- [slave/axi4_slave_driver_proxy.sv:498](slave/axi4_slave_driver_proxy.sv#L498)、[slave/axi4_slave_driver_proxy.sv:815](slave/axi4_slave_driver_proxy.sv#L815)、[slave/axi4_slave_driver_proxy.sv:1147](slave/axi4_slave_driver_proxy.sv#L1147)：response/exclusive logic 實際消費這些欄位

既有 coverage run 曾在 manager side 記錄 `READ_NORMAL_ACCESS`，但同一 read 到 slave response logic 時成為 `READ_EXCLUSIVE_ACCESS`，並建立 exclusive monitor：`/tmp/v4_axi4_trackb_cov_sweep_test.log:3415-3419,3693-3705`。這份 log 來自 reset 修正前的 binary，只用來證明 metadata data path，不列為 current regression verdict。

影響：exclusive response、cache/region metadata 與 memory behavior 可與 pins 不一致。建議在 handshake 時完整擷取所有 Ax fields，且 observed request semantics 不得繼承 randomized dummy values。

### 4. [P1] Slave 在固定 timeout 後撤回 BVALID/RVALID，直接違反 AXI VALID invariant

B channel 在沒有 reset、也沒有 `BVALID && BREADY` handshake 時，3000-cycle timeout 會 `break`，接著撤回 BVALID。兩個 R branches 同樣在 50000 cycles 後撤回 RVALID/RLAST。

- [agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:588](agent/slave_agent_bfm/axi4_slave_driver_bfm.sv#L588)：assert BVALID
- [agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:628](agent/slave_agent_bfm/axi4_slave_driver_bfm.sv#L628)、[agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:657](agent/slave_agent_bfm/axi4_slave_driver_bfm.sv#L657)：timeout 後 deassert
- [agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:819](agent/slave_agent_bfm/axi4_slave_driver_bfm.sv#L819)、[agent/slave_agent_bfm/axi4_slave_driver_bfm.sv:859](agent/slave_agent_bfm/axi4_slave_driver_bfm.sv#L859)：R channel 同型 timeout

原註解稱 manager 沒有 outstanding-response collector，但 current source 已有 standing B/R collectors：[agent/master_agent_bfm/axi4_master_driver_bfm.sv:215](agent/master_agent_bfm/axi4_master_driver_bfm.sv#L215)、[agent/master_agent_bfm/axi4_master_driver_bfm.sv:336](agent/master_agent_bfm/axi4_master_driver_bfm.sv#L336)。因此留下 protocol violation 的主要理由已過期。

影響：VIP 自己可製造 transaction loss、phantom completion 或 DUT-facing protocol violation。建議 timeout 只 report 一次並繼續 hold VALID；test watchdog 負責終止真正的 deadlock。

### 5. [P1] Monitor 無法關聯合法的 cross-ID response reorder，也無法重建 R beat interleave

Master/slave monitor proxy 都在看到當前 B 或完整 R burst 後，從 issue-order FIFO head 取 AW/W 或 AR metadata。不同 ID 的 response 可以合法 reorder；read data 也可在不同 RID 間交錯。現行 R monitor BFM 使用單一 static beat index 與單一 packet，會把交錯 beat 混在一起。

- [master/axi4_master_monitor_proxy.sv:202](master/axi4_master_monitor_proxy.sv#L202)、[master/axi4_master_monitor_proxy.sv:257](master/axi4_master_monitor_proxy.sv#L257)：B/R 與 FIFO head 合併
- [slave/axi4_slave_monitor_proxy.sv:191](slave/axi4_slave_monitor_proxy.sv#L191)、[slave/axi4_slave_monitor_proxy.sv:249](slave/axi4_slave_monitor_proxy.sv#L249)：slave monitor 同型
- [agent/master_agent_bfm/axi4_master_monitor_bfm.sv:251](agent/master_agent_bfm/axi4_master_monitor_bfm.sv#L251)、[agent/slave_agent_bfm/axi4_slave_monitor_bfm.sv:267](agent/slave_agent_bfm/axi4_slave_monitor_bfm.sv#L267)：單一 R accumulator，未依 RID 分流
- [env/axi4_scoreboard.sv:2684](env/axi4_scoreboard.sv#L2684)：後段雖用 address/shape keyed matching，但 address 已由錯誤 FIFO head 注入，無法復原
- [env/axi4_scoreboard.sv:2827](env/axi4_scoreboard.sv#L2827)：outstanding map 只證明某 ID 尚有計數，不證明 response 與正確 request metadata 配對

影響：合法 reorder 可造成 false mismatch；若被交換的 response 值相同，也可能掩蓋 routing error。建議 monitor 以 BID/RID 對 outstanding request queue 做 keyed join，R channel 使用 per-RID accumulator。

### 6. [P1] Sparse WSTRB 會讓 slave memory model 壓縮 byte address

INCR path 的 `k` 只在 strobe bit 為 1 時增加；例如單 beat 只有 lane 2 asserted，byte 2 會被寫到 `awaddr+0` 而非 `awaddr+2`。WRAP path 使用相同的壓縮方式，還會破壞 wrap progression。FIXED path 用 `awaddr + strb`，可作直接反例。

- [slave/axi4_slave_driver_proxy.sv:1483](slave/axi4_slave_driver_proxy.sv#L1483)：FIXED 使用 lane offset
- [slave/axi4_slave_driver_proxy.sv:1504](slave/axi4_slave_driver_proxy.sv#L1504)：INCR 使用只對 asserted lanes 遞增的 `k`
- [slave/axi4_slave_driver_proxy.sv:1525](slave/axi4_slave_driver_proxy.sv#L1525)：WRAP 同型
- [test/axi4_wstrb_alternating_test.sv:32](test/axi4_wstrb_alternating_test.sv#L32)、[seq/master_sequences/axi4_master_wstrb_seq.sv:20](seq/master_sequences/axi4_master_wstrb_seq.sv#L20)：現有 directed test 明確使用 `0101/1010` sparse strobes

影響：read-after-write reference memory 可讀到錯誤 byte lane；某些 end-to-end test 也可能因兩邊共同錯誤而自洽。建議先獨立計算每個 beat 的 base address，再對 `beat_base + lane` 套用 WSTRB byte enable。

### 7. [P1] Standing B/R collectors 把 per-transaction READY delay 變成 response 之後的 channel gap

Transaction API 將 `b_wait_states`/`r_wait_states` 定義為「driving BREADY/RREADY 前的 wait states」。current collector 卻先接受 handshake，之後才載入 global delay counter；per-transaction task 也在 response 可能已被 collector 接受後才更新該 global request。

- [master/axi4_master_tx.sv:193](master/axi4_master_tx.sv#L193)：transaction-level wait-state API
- [agent/master_agent_bfm/axi4_master_driver_bfm.sv:230](agent/master_agent_bfm/axi4_master_driver_bfm.sv#L230)、[agent/master_agent_bfm/axi4_master_driver_bfm.sv:256](agent/master_agent_bfm/axi4_master_driver_bfm.sv#L256)：B handshake 在前，delay 在後
- [agent/master_agent_bfm/axi4_master_driver_bfm.sv:354](agent/master_agent_bfm/axi4_master_driver_bfm.sv#L354)、[agent/master_agent_bfm/axi4_master_driver_bfm.sv:397](agent/master_agent_bfm/axi4_master_driver_bfm.sv#L397)：R 同型
- [agent/master_agent_bfm/axi4_master_driver_bfm.sv:619](agent/master_agent_bfm/axi4_master_driver_bfm.sv#L619)、[agent/master_agent_bfm/axi4_master_driver_bfm.sv:762](agent/master_agent_bfm/axi4_master_driver_bfm.sv#L762)：sequence request 太晚寫入 global delay

多筆 outstanding 時，單一 global delay 還會彼此覆寫。影響：backpressure stimulus 沒有施加在指定 response 上，coverage/checker 的 wait-state 語意失真。建議把 delay 與 outstanding BID/RID request 一起排隊，並在 assertion of READY 之前倒數。

### 8. [P1] Track-B coverage sweep 繞過專案 watchdog

Smoke parent 有自己的 500 us watchdog，base test 也只在其 `run_phase()` 中啟動 watchdog；coverage subclass 完全 override `run_phase()`，沒有呼叫任何 watchdog，卻持有 objection 並依序阻塞在最多 `2 * 96 * num_masters` 次 `sequence.start()`。

- [test/axi4_trackb_smoke_test.sv:81](test/axi4_trackb_smoke_test.sv#L81)：parent 的 bounded body/watchdog
- [test/axi4_base_test.sv:501](test/axi4_base_test.sv#L501)：base watchdog 啟動點
- [test/axi4_trackb_cov_sweep_test.sv:29](test/axi4_trackb_cov_sweep_test.sv#L29)、[test/axi4_trackb_cov_sweep_test.sv:59](test/axi4_trackb_cov_sweep_test.sv#L59)：override 後的無界 blocking loops

舊 coverage binary 最終有結束，因此本 finding 不是「已觀察到 hang」，而是 current control flow 沒有 project-scoped terminal bound。外部 regression timeout 只能 kill job，不能提供帶 test context 的 UVM verdict。建議抽出可重用 watchdog task，coverage sweep 與 smoke 均顯式 race test body against it。

### 9. [P2] 每個 partial channel packet 都 sample 整個 monolithic covergroup，產生假 coverage hits

AW/W/B/AR/R 五個 analysis ports 都接到同一 subscriber；subscriber 每次 `write()` 無條件 sample 整個 covergroup。Partial transaction 未觀測的 2-state fields 為合法零值，因此 write-only traffic 也可命中 READ_FIXED、READ_1_BYTE、RID0×READ_OKAY 等 bins/crosses；read traffic 同樣污染 write-side bins。

- [master/axi4_master_agent.sv:115](master/axi4_master_agent.sv#L115)、[slave/axi4_slave_agent.sv:109](slave/axi4_slave_agent.sv#L109)：五個 channel fan-in
- [master/axi4_master_coverage.sv:639](master/axi4_master_coverage.sv#L639)、[master/axi4_master_coverage.sv:721](master/axi4_master_coverage.sv#L721)：每個 packet sample 全 covergroup
- [slave/axi4_slave_coverage.sv:535](slave/axi4_slave_coverage.sv#L535)、[slave/axi4_slave_coverage.sv:620](slave/axi4_slave_coverage.sv#L620)：slave side 同型
- [master/axi4_master_seq_item_converter.sv:186](master/axi4_master_seq_item_converter.sv#L186)、[pkg/axi4_globals_pkg.sv:242](pkg/axi4_globals_pkg.sv#L242)：新 2-state transaction 的未填欄位為零，且零是合法 OKAY/default enum

同一個真實欄位被 AW/W/B 重複 sample 通常只增加 hit count；真正灌高 percentage 的是 opposite-channel/default fields 首次命中合法 zero bins。WSTRB 小 covergroup 有 queue-size guard，不列入此 finding。建議拆成 channel-specific covergroups/callback，或只在完成的 B/R aggregate packet sample transaction-level crosses。

### 10. [P2] Master write-response monitor path 永遠把 BUSER 留為零

Master monitor BFM 有接到 BUSER pin，但 response sampler 沒有寫入 struct；最終 combined converter 又建立新 object，只複製 BID/BRESP。因為欄位是 2-state `bit`，scoreboard 看到的 master BUSER 固定為零。

- [agent/master_agent_bfm/axi4_master_monitor_bfm.sv:46](agent/master_agent_bfm/axi4_master_monitor_bfm.sv#L46)、[agent/master_agent_bfm/axi4_master_monitor_bfm.sv:196](agent/master_agent_bfm/axi4_master_monitor_bfm.sv#L196)：pin 存在，sampler 只寫 BID/BRESP/wait count
- [master/axi4_master_monitor_proxy.sv:202](master/axi4_master_monitor_proxy.sv#L202)、[master/axi4_master_seq_item_converter.sv:391](master/axi4_master_seq_item_converter.sv#L391)：runtime response path 與重新配置的 object
- [master/axi4_master_seq_item_converter.sv:418](master/axi4_master_seq_item_converter.sv#L418)：combined converter 再次漏掉 BUSER
- [agent/slave_agent_bfm/axi4_slave_monitor_bfm.sv:217](agent/slave_agent_bfm/axi4_slave_monitor_bfm.sv#L217)、[slave/axi4_slave_seq_item_converter.sv:543](slave/axi4_slave_seq_item_converter.sv#L543)：slave side 正確 sample/copy，可作對照
- [env/axi4_scoreboard.sv:975](env/axi4_scoreboard.sv#L975)：scoreboard 實際比較 BUSER

影響：正確透傳非零 BUSER 時會 false mismatch；slave/source 為零、DUT 將 manager-side pin 錯改為非零時會 false PASS。最小 checker 修正是在 BFM handshake sample 加 `req.buser = buser`，並在 `to_write_addr_data_resp_class()` 複製 BUSER。BUSER QoS/user coverage 另有 write-response port 未連接的獨立 wiring gap，不混入本 finding。

## 審查期間已修正並重新驗證

另一個 session 在本次 review 進行中修正 scoreboard reset semaphore leak。舊 binary 在 reset 後仍有 monitor traffic，但五個 scoreboard channel 全部顯示 `0 received, 0 matched`，最後為：

```text
/tmp/v4_reset_sem_smoke_high.log:2278-2282
WRITE_ADDRESS channel: 0 received, 0 matched
...
READ_DATA channel: 0 received, 0 matched

/tmp/v4_reset_sem_smoke_high.log:2579-2580
UVM_ERROR :    9
UVM_FATAL :    0
```

Current source 在 [env/axi4_scoreboard.sv:488](env/axi4_scoreboard.sv#L488) 於 reset 後重建五把 semaphores。相同 Track-B smoke 路徑重新 compile/run 後：

```text
/tmp/codex_current_trackb_smoke.log:6098-6102
WRITE_ADDRESS channel: 10 received, 10 matched
WRITE_DATA channel: 10 received, 10 matched
WRITE_RESPONSE channel: 10 received, 10 matched
READ_ADDRESS channel: 10 received, 10 matched
READ_DATA channel: 10 received, 10 matched

/tmp/codex_current_trackb_smoke.log:6234
TestCase PASSED!!!

/tmp/codex_current_trackb_smoke.log:6294-6295
UVM_ERROR :    0
UVM_FATAL :    0
```

另有一份較早的 temporary compile log 曾因 `s_until_with` 報 assertion syntax errors；current assertions 已改為 VCS 可接受形式，fresh full build 無 compile error，因此該候選 finding 已被反駁並排除。

## 驗證摘要

### Current full Track-B compile

VCS W-2024.09-SP1，以 NIC-400 10x10、256-bit DATA、8-bit ID、coverage/assertions 編譯，成功完成 compile + elaboration + link：

```text
/tmp/f0-current.RkxKKa/v6.log:2633
CPU time: 60.061 seconds to compile + 1.029 seconds to elab + 2.202 seconds to link
```

- Compile errors：0
- ID port-width `PCWM-W` warnings：0
- Warnings：22，其中 20 個 `VCM-HFUFR` 來自 `sim/coverage_scope.cm_hier` 的 `#` comment lines 被當成 hierarchy patterns；另有 `-lca` usage 與 ignored `+no_timing_check`

### Current Track-B smoke

執行命令：

```bash
cd /tmp/f0-current.RkxKKa
timeout 300 ./simv +UVM_TESTNAME=axi4_trackb_smoke_test \
  +BUS_MATRIX_MODE=ENHANCED +UVM_VERBOSITY=UVM_LOW \
  +ntb_random_seed=424242 -l /tmp/codex_current_trackb_smoke.log
```

Process exit code 0；log 明確包含 `TestCase PASSED!!!`、`UVM_ERROR : 0`、`UVM_FATAL : 0`，路徑如上。這證明 current reset/基本 10x10 smoke 路徑，不足以推翻 findings 1–10 的未驅動 corner cases。

### Standalone fabric smoke

`bash ../run_fabric_smoke.sh /tmp/codex_trackb_fabric_smoke_review` exit 0，log 為：

```text
/tmp/codex_trackb_fabric_smoke_review/run.log:5-12
[PASS] CASE1 unmapped->DECERR
[PASS] CASE2 S0 base ->OKAY
[PASS] CASE3 S0 base read->OKAY
=== FABRIC SMOKE TEST PASSED (3/3) ===
```

對 script success gate 注入 synthetic failure marker 時 exit code 為 1，證明 failure text 不再被當成 shell success。

### 其餘檢查與限制

- `git diff --check`：tracked diff clean；本報告另以 trailing-whitespace scan 檢查通過
- 未執行完整 regression
- 未以 current binary 重跑 coverage sweep/UCIS closure
- 未新增 directed cross-ID reorder、R interleave、sparse-WSTRB byte-map、per-response READY delay 或 nonzero-BUSER tests；這五類 finding 目前是 source-path proof + 三方抗辯確認，尚無 fail-then-pass 修復證據

## 多方抗辯結果

每項重大結論都由 skeptic、red-team、simplifier 三個獨立鏡頭以「預設推翻」立場審查；10/10 findings 均 3/3 `SURVIVED`，達 confirmed 門檻。

| # | Finding | Skeptic | Red-team | Simplifier |
|---|---|---|---|---|
| 1 | Completeness guards | SURVIVED | SURVIVED | SURVIVED |
| 2 | Track-B topology fail-open | SURVIVED | SURVIVED | SURVIVED |
| 3 | Reactive Ax metadata loss | SURVIVED | SURVIVED | SURVIVED |
| 4 | VALID timeout withdrawal | SURVIVED | SURVIVED | SURVIVED |
| 5 | Monitor reorder/interleave | SURVIVED | SURVIVED | SURVIVED |
| 6 | Sparse WSTRB addressing | SURVIVED | SURVIVED | SURVIVED |
| 7 | READY delay semantics | SURVIVED | SURVIVED | SURVIVED |
| 8 | Coverage sweep watchdog | SURVIVED | SURVIVED | SURVIVED |
| 9 | Partial-packet coverage | SURVIVED | SURVIVED | SURVIVED |
| 10 | Master BUSER loss | SURVIVED | SURVIVED | SURVIVED |

抗辯造成的限縮也已反映在本文：Finding 3 不採用未被 log 證明的 write-exclusive runtime claim；Finding 9 區分 hit-count duplication 與真正的 percentage 污染；Finding 10 只宣稱已證實的 checker 影響，不把獨立的 coverage wiring gap混為一談。

## Delivery / reproducibility risks

以下不計入 8 P1 + 2 P2，但在提交前應處理：

- 新增的 Track-B-specific tests、sequences、NIC-400 wrappers/filelists 與 smoke script 目前全是 untracked；`git ls-files` 對這些路徑均無輸出。若只提交 tracked diff，整條 Track-B flow 會遺失。
- [top/axi4_fabric_ip_wrapper.sv:4](top/axi4_fabric_ip_wrapper.sv#L4) 宣稱由 `scratchpad/gen_wrapper.py` 生成，但該 generator 不在 worktree；兩個 wrapper 合計 1,439 lines，無法可靠重建或 diff source-of-truth。
- [sim/coverage_scope.cm_hier:1](sim/coverage_scope.cm_hier#L1) 使用 `#` comments，fresh VCS build 產生 20 個 hierarchy-region warnings。應改用工具支援的 comment syntax，並確認 include/exclude directives 實際套用後再採信 code coverage。

## Agent 狀態

- Domain reviewers finished：3
- Adversarial reviewers finished：3
- Running：0
- Killed：0
