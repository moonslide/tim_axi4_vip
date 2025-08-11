# AXI4 Bus Matrix / DUT-Only（No Reference）混合狀況（sequence）組合測試計畫

> **目標**：在保留原「6 sequences 合成 1 testcase」設計的前提下，讓同一份測試計畫同時支援：  
> - **Mode-A：Enhanced Bus Matrix Reference Model（有參考模型）**  
> - **Mode-B：DUT-Only（無參考模型 / 無 reference bus matrix）**  
> 並自動適配非 10×10 的 M×N 拓樸。

---

## 模式與拓樸支援

### 測試模式
- **Mode-A（有參考）**：以 *enhanced bus matrix ref model* 做為資料正確性與路由的 oracle。  
- **Mode-B（無參考）**：以**自洽式（self-consistency）與可觀測不變量（invariants）**為 oracle：  
  1) 以 memory-backed slave BFM 建立**可重讀驗證（write→readback）**。  
  2) 以 AXI Protocol Checker / SVA 檢查 handshake、順序、4KB 邊界、ID/Outstanding。  
  3) 以**守恆類不變量**檢查（例：每筆成功寫入須對應 1 筆 B 回應；每個 ARID 的 R beats 與 LEN 相符等）。

### 拓樸（自動化）
- **參數化**：`N_MASTER`, `N_SLAVE` 自動化讀入（UVM config_db/plusarg）或由 env 掃描 agent 數量取得。  
- **流量模板**（all-to-all、hotspot、ring、bipartite、striped）對應 `M×N` 自動生成；非 10×10 亦可覆蓋。

---

## 實施原則（Test Orchestration Rule）
- **單元化**：每個狀況 → 一個 `uvm_sequence`（參數化控制 Slave/位址/長度/ID/QoS 等）。  
- **6-in-1**：每個 testcase 由 6 個 sequences 組合（序列 / 並行 / 鉤子 hook 觸發 mid-burst reset）。  
- **可重現**：記錄 `seed/knobs/duration/hook`。  
- **可量測**：每個 sequence 具明確 `Pass/Fail` 與 coverage；testcase 匯總 KPI（吞吐、延遲、錯誤率）。

---

## 無參考模型（Mode-B）下的 Oracle 與驗證策略

### 1) 可重讀驗證（Readback Oracle）
- 在每個可寫地址區段建立 **memory-backed slave BFM**（或簡化 RAM model）。  
- 寫入（AW/W）完成並接收 `B` 成功後，以相同位址發出 `AR/R` 讀回，比對資料覆蓋率含：  
  - `WSTRB` 部分寫入（byte-lane 口罩）  
  - INCR/WRAP 突發跨界處理（不跨 4KB）  
  - 多 ID / 多 outstanding 下的順序性 per-ID 檢查

### 2) 不變量（Invariants）與進展性（Progress）
- **寫守恆**：`num_aw_accepted == num_b_returned`（按 ID/Txn 對應）。  
- **讀守恆**：每個 `AR` 的 `LEN` 對應正確數目的 `R` beats，`RLAST` 位置正確。  
- **進展性**：在無永久 backpressure 的假設下，不應出現活鎖；可用 watchdog/heartbeat 監測。

### 3) 路由與位址映射
- 以 `address_map` 推導**期望目的 Slave**，比對實際回應來源（若能觀測 crossbar port）；若不可觀測，以**讀回成功性**與**錯誤回應（DECERR/SLVERR）**作為路由間接驗證。

---

## Sequence Library（狀況單元）
| Sequence Name | 狀況/主題 | 場景說明 | 主要參數（例） | Mode-A（有參考） | Mode-B（無參考） |
|---|---|---|---|---|---|
| axi4_master_reset_smoke_seq | Reset-Smoke | 上電釋放 reset 後發最小流量 | rst_pulse=sync-deassert | Ref 與 DUT 狀態一致 | 通道 idle、無 X、PC 0 error |
| axi4_master_midburst_reset_read_seq | Mid-Burst Reset（Read） | 讀 INCR LEN=255 中段 reset | m=0 s=0 len=255 hook=128 | Ref 交易終止/恢復一致 | R 通道清空；reset 後可再讀 |
| axi4_master_midburst_reset_write_seq | Mid-Burst Reset（Write） | 寫 INCR LEN=255 中段 reset | m=0 s=0 len=255 hook=100 | Ref 一致；無半寫殘留 | Readback 驗證無半寫；守恆成立 |
| axi4_slave_reset_backpressure_seq | Reset × Backpressure | 長拉低 READY 後 reset | s=7 hold=5k | Ref 在 reset 釋放後恢復 | 堆疊清空、PC 0 error |
| axi4_master_all_to_all_saturation_seq | All-to-All Saturation | M×N 同時讀寫 | len=255 out=max | 吞吐/延遲貼近 Ref | 無死結；KPI 達標 |
| axi4_master_hotspot_many_to_one_seq | Hotspot（Many→One） | 多 Master 擠單 Slave | s=0 mix=7:3 | 公平性 vs Ref | 公平性以延遲/份額衡量 |
| axi4_master_one_to_many_fanout_seq | One→Many | 單 Master 打滿全 Slaves | m=0 id_pool=wide | 順序/吞吐 vs Ref | per-ID 順序正確 |
| axi4_master_mixed_burst_lengths_seq | Mixed Burst | LEN=1..256 混合 | mix_len | 與 Ref 比對 | WLAST/RLAST 正確 |
| axi4_master_4kb_boundary_seq | 4KB 邊界 | 合法/非法跨 4KB | align=[0, misaligned] | 非法被攔截/回錯 | 與 PC/SVA 結論一致 |
| axi4_master_max_outstanding_seq | Max Outstanding | 撐滿 ID/Outstanding | id=max out=max | 與 Ref 一致 | 無溢位；回傳對應 |
| axi4_slave_backpressure_storm_seq | Backpressure Storm | 多 Slave 交錯背壓 | staggered | Ref 進展性良好 | 無通道鎖死 |
| axi4_master_qos_arbitration_seq | QoS 仲裁 | 高/低 QoS 競爭 | hi=M0 lo=M1..9 | 優先度與 Ref 一致 | 以延遲/吞吐份額衡量 |
| axi4_master_region_routing_seq | REGION 路由 | AxREGION→不同 Slaves | region_map | 路由比對 Ref | 地址映射/回應來源驗證 |
| axi4_master_read_reorder_seq | R 亂序整併 | 多 ID/多 Slave | arid_pool | 回傳整併與 Ref 一致 | 每 ID 回傳對應 |
| axi4_slave_write_response_throttling_seq | 寫回應節流 | 延遲/壓縮 B | b_delay=rand | B 流控與 Ref 一致 | BID 對應 AWID |
| axi4_slave_long_tail_latency_seq | 長尾延遲 | 單 Slave 超長延遲 | s=8 delay=50k | 其他流量不連坐 | 無全域阻塞 |
| axi4_master_read_write_contention_seq | 讀寫對打 | 同一 Slave 競爭 | s=3 same/near | 與 Ref 一致 | KPI 合理、PC 0 error |
| axi4_slave_sparse_error_injection_seq | 稀疏錯誤注入 | SLVERR/DECERR | rate=1% | 錯誤隔離 | 錯誤僅限來源 Slave |

> **PC = Protocol Checker**。Mode-A 與 Mode-B 都建議同時開啟 PC/VIP。

---

## 混合測試（6 Sequences / Testcase）— 命名與組合

### axi4_saturation_midburst_reset_qos_boundary_test
- **目的**：壓力下注入 mid-burst reset 與背壓，檢查 QoS、公平性、4KB 邊界與錯誤隔離。  
- **組合**：  
  1. **[並行]** axi4_master_all_to_all_saturation_seq + axi4_master_qos_arbitration_seq — *120k cyc*  
  2. **[鉤子]** 於步驟 1 第 80k cyc 觸發 **axi4_master_midburst_reset_read_seq**  
  3. **[序列]** axi4_slave_backpressure_storm_seq — *100k cyc*  
  4. **[序列]** axi4_master_4kb_boundary_seq — *20k trx*  
  5. **[序列]** axi4_slave_sparse_error_injection_seq — *rate=1%*  
  6. **[序列]** axi4_master_reset_smoke_seq — *clean-up*  
- **Mode-A 驗證**：Ref 對比（資料/路由/吞吐）。  
- **Mode-B 驗證**：Readback、PC/SVA、守恆/進展性 KPI。

### axi4_throughput_ordering_longtail_throttled_write_test
- **組合**：axi4_master_one_to_many_fanout_seq → axi4_master_max_outstanding_seq → **[並行]** axi4_slave_long_tail_latency_seq + axi4_master_read_reorder_seq → axi4_slave_write_response_throttling_seq → axi4_master_reset_smoke_seq  
- **焦點**：順序性、單一長尾對全域影響、寫回應壅塞（Mode-B 以 KPI/Readback 驗證）。

### axi4_hotspot_fairness_boundary_error_reset_backpressure_test
- **組合**：**[並行]** axi4_master_hotspot_many_to_one_seq + axi4_master_mixed_burst_lengths_seq → axi4_master_read_write_contention_seq → axi4_master_4kb_boundary_seq → axi4_slave_sparse_error_injection_seq → axi4_slave_reset_backpressure_seq  
- **焦點**：仲裁公平、WLAST/RLAST、4KB 邊界、錯誤隔離、reset 清疊。

### axi4_qos_region_routing_reset_backpressure_test
- **組合**：axi4_master_region_routing_seq → **[並行]** axi4_master_qos_arbitration_seq + axi4_master_all_to_all_saturation_seq → axi4_master_midburst_reset_read_seq → axi4_slave_backpressure_storm_seq → axi4_master_reset_smoke_seq  
- **焦點**：路由與策略一致性（Mode-B 依地址映射與 PC/SVA 驗證）。

### axi4_write_heavy_midburst_reset_rw_contention_test
- **組合**：axi4_master_mixed_burst_lengths_seq → axi4_slave_write_response_throttling_seq → **[並行]** axi4_master_all_to_all_saturation_seq + axi4_master_midburst_reset_write_seq → axi4_master_read_write_contention_seq → axi4_master_reset_smoke_seq  
- **焦點**：寫路徑壓縮、mid-burst reset 對寫一致性影響（Mode-B 以 Readback 驗證）。

### axi4_stability_burnin_longtail_backpressure_error_recovery_test
- **組合**：**[並行]** axi4_master_all_to_all_saturation_seq + axi4_master_one_to_many_fanout_seq + axi4_slave_backpressure_storm_seq → axi4_slave_long_tail_latency_seq → axi4_slave_sparse_error_injection_seq → axi4_master_reset_smoke_seq  
- **焦點**：長時穩定、無記憶體洩漏、計數器不溢位、錯誤處理品質（兩模式皆適用）。

---

## 排程與並行標註
- **[序列]**：上一段結束後再開始。  
- **[並行]**：同 Phase 內同時啟動多個 sequences。  
- **[鉤子 hook]**：在其他 sequence 進行中於指定條件/時刻觸發（如 mid-burst reset）。

> 範例時間線（axi4_saturation_midburst_reset_qos_boundary_test 概念）  
```
Phase-1: |==== axi4_master_all_to_all_saturation_seq (0~120k) ====|
         |==== axi4_master_qos_arbitration_seq (0~120k) ====|
Hook    :                ^ axi4_master_midburst_reset_read_seq at 80k (mid-burst)
Phase-2:                         |== axi4_slave_backpressure_storm_seq (120k~220k) ==|
Phase-3:                                           | axi4_master_4kb_boundary_seq |
Phase-4:                                             | axi4_slave_sparse_error_injection_seq |
Phase-5:                                                | axi4_master_reset_smoke_seq |
```

---



## 驗收與量測（兩模式通用）
- **Pass**：Protocol Checker 0 error、無死結/活結、scoreboard 一致性 100%。  
- **KPI**：吞吐（GB/s）、延遲分佈（p50/p95/p99）、重試率、reset 復原時間、錯誤隔離率、仲裁公平度。  
- **覆蓋**：突發長度×對齊×4KB 邊界×ID/Outstanding×QoS×REGION×Reset×Backpressure。




