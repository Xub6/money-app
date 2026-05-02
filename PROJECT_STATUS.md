# 錢錢管家 — 開發進度報告

> 最後更新：2026-05-02（RC 前總驗收）
> 前一版本日期：2026-04-19（已大幅過期，本版完全覆寫）

---

## 總體進度

```
■■■■■■■■■■■■■■■■■■■■  100% — Release Candidate ✅
```

---

## 目前狀態：Release Candidate Ready

所有 P0 / P1 / P2 修復已完成，並通過 Sean 手機實機確認。
自動化測試全數通過，APK 與 AAB 皆已建置。

---

## 完成功能總覽

### 核心記帳
- 支出 / 收入新增、編輯、刪除（長按選單）
- 分類系統（餐飲、交通、娛樂等）
- 月份切換（累進導航 + BottomSheet 任意月份跳轉）
- 首頁月份 chip 狀態指示（金色 active，永遠高辨識）
- 預算進度（含 / 不含固定開銷，設定持久化）
- 支出分析（甜甜圈圖 + 本月 / 雙月 / 半年切換）
- 明細頁（收支切換、分類篩選、月份選擇器、淨額顯示）

### 帳戶管理
- 多帳戶（儲蓄 / 信用 / 其他，多幣別）
- 淨資產總覽（= 資產 - 負債 + 投資組合現值）
- 支出 / 收入自動調整帳戶餘額
- 刪除帳戶後關聯支出 / 持股 accountId 自動置 null

### 投資追蹤
- 台股（TWSE API 中文名稱）、美股（Yahoo Finance）
- 現價刷新、損益計算（含手續費 / 交易稅）
- 持股買入 / 刪除自動連動帳戶餘額

### 資料管理
- SQLite 主要儲存（v3 schema：支出含 type / account_id）
- AES 加密 SharedPreferences meta
- JSON 備份 v2.0（含帳戶 / 持股 / 預算）
- 備份建立、還原、**單筆刪除**（v2.0 新增）
- Excel / CSV 匯出（3 個 sheet）

### UX / 品質
- 深色模式全面 colorScheme（iOS/Material 標準色）
- 新手導覽（16 步 Coach-marks Tour + demo 資料）
- 互動式說明（FAB / 長按明細 互動步驟）
- i18n 國際化骨架（flutter_localizations）
- Feedback 功能（n8n webhook，附圖，ManagePage 入口）
- SearchPage 全文搜尋

### 上架素材
- Play Store 截圖 × 5（1080×1920）
- Feature Graphic（1024×500）
- Privacy Policy（GitHub Pages）
- Store listing 文案（繁體中文）
- Firebase Auth（Google 登入，預設關閉，kFirebaseConfigured=false）

---

## 修復紀錄（P0 / P1 / P2）

### P0（全部完成 2026-05-02）
| ID | 問題 | 狀態 |
|----|------|------|
| BUG-01/02 | dynamicTotal / categoryTotals 誤計入收入 | ✅ |
| BUG-04 | clearDemoData() 未呼叫 _save()，demo 殘留 | ✅ |
| BUG-05b | 強制帳戶選擇，加「不關聯帳戶」chip | ✅ |
| BUG-03 | BackupData v2.0 含帳戶 / 持股，舊版 fallback | ✅ |

### P1（全部完成 2026-05-02）
| ID | 問題 | 狀態 |
|----|------|------|
| P1-1 | 月份切換不支援連續翻月 | ✅ |
| P1-2 | 刪除帳戶後孤兒 accountId 未清除 | ✅ |
| P1-3 | 持股買入/刪除未連動帳戶餘額 | ✅ |
| P1-4 | 明細收支顯示無符號 / 顏色 | ✅ |

### P2（全部完成並 Sean 手機實機確認 2026-05-02）
| ID | 問題 | 狀態 |
|----|------|------|
| P2-1 | 首頁月份 chip 辨識度不足 | ✅ Sean 確認 |
| P2-2 | 含固定開銷開關重開 App 後重置 | ✅ Sean 確認 |
| P2-3 | 明細頁月份按鈕太小、不可操作 | ✅ Sean 確認 |
| P2-4 | 首頁 / 明細頁 selectedMonth 不同步 | ✅ Sean 確認 |
| P2-5 | 備份無法刪除單筆 | ✅ Sean 確認 |

---

## 自動化驗證結果（2026-05-02）

| 項目 | 結果 |
|------|------|
| flutter analyze | 0 error / 0 warning / 36 info |
| flutter test | 17/17 passed |
| flutter build apk --release | ✅ 59.3 MB |
| AAB（play store 用） | ✅ 已存在 build/app/outputs/bundle/release/app-release.aab |

---

## 未解決已知問題（不阻擋 RC）

- 36 個 flutter analyze info（均為 prefer_const / deprecated deprecated_member_use 等風格建議，不影響功能）
- Firebase Auth 預設關閉（kFirebaseConfigured=false），Google 登入需 Sean 設定 Firebase 專案後才能啟用
- i18n 只有骨架，僅繁體中文，無多語系切換 UI

---

## 尚未完成（上架前 Sean 需手動處理）

1. Firebase 正式設定（若要啟用 Google 登入）
2. 產生 signed AAB / APK（需 keystore）
3. Play Console：上傳 AAB、截圖、Feature Graphic、填寫 store listing
4. 隱私政策 URL 填入 Play Console
5. 封閉測試 → 開放測試 → 正式上架審核

---

## 技術架構快覽

| 層 | 說明 |
|----|------|
| UI | Flutter Widget（main.dart 約 2800 行，各 Screen 分檔） |
| 狀態 | Provider（AppState, ThemeProvider, TourController） |
| 儲存 | SQLite（expenses/fixedItems）+ AES 加密 SP（meta） |
| 股價 | Yahoo Finance API（美股）/ TWSE API（台股） |
| 匯率 | Yahoo Finance（並行抓取 7 幣別） |
| 備份 | App Documents 目錄 JSON 檔案（v2.0 schema） |
| 測試 | Unit（17 cases）+ Smoke（3 cases） |
