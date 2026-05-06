# 錢錢管家 — 開發進度報告

> 最後更新：2026-05-06（P0 i18n 結案，RC Candidate 確認）

---

## 總體進度

```
■■■■■■■■■■■■■■■■■■■■  100% — RC Candidate ✅  等待 Play Console 上架流程
```

---

## 目前狀態：RC Candidate — 等待 Play Console 身分驗證

所有 P0 / P1 / P2 修復已完成，**Sean 手機實機全語言切換驗證通過**。
等待 Google Play Console 身分驗證（電話驗證）完成後，進入上架流程。

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
- 備份建立、還原、單筆刪除
- Excel / CSV 匯出（3 個 sheet，含 i18n 欄位名稱）

### UX / 品質
- 深色模式全面 colorScheme（iOS/Material 標準色）
- 新手導覽（16 步 Coach-marks Tour + demo 資料）
- i18n 四語完整（繁中 / 簡中 / English / 日本語）— **Sean 實機驗證通過**
- Feedback 功能（n8n webhook）
- SearchPage 全文搜尋

### 上架素材
- Play Store 截圖 × 5（1080×1920）
- Feature Graphic（1024×500）
- Privacy Policy（GitHub Pages）
- Store listing 文案（繁體中文）

---

## 修復紀錄

### P0（全部結案）

| ID | 問題 | 結案日 | Commit |
|----|------|--------|--------|
| BUG-01/02 | dynamicTotal / categoryTotals 誤計入收入 | 2026-05-02 | — |
| BUG-04 | clearDemoData() 未呼叫 _save() | 2026-05-02 | — |
| BUG-05b | 強制帳戶選擇 UI | 2026-05-02 | — |
| BUG-03 | BackupData v2.0 schema | 2026-05-02 | — |
| **i18n-P0** | **語言切換後 UI 殘留中文（hardcoded strings）** | **2026-05-06** | **1c55254** |

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

## 自動化驗證結果（2026-05-06）

| 項目 | 結果 |
|------|------|
| flutter analyze | 0 error / 34 info |
| flutter test | 通過 |
| flutter build apk --release | ✅ 59.4 MB |
| flutter build appbundle --release | ✅ build/app/outputs/bundle/release/app-release.aab |
| Sean 手機實機 — 功能驗收 | ✅ 通過（2026-05-02） |
| Sean 手機實機 — 四語切換驗收 | ✅ 通過（2026-05-06） |

---

## 版本資訊

| 項目 | 值 |
|------|----|
| versionName | 2.0.0 |
| versionCode | 1 |
| APK | build/app/outputs/flutter-apk/app-release.apk |
| AAB | build/app/outputs/bundle/release/app-release.aab |

---

## Play Console 上架 Checklist

### 前置（Sean 操作）
- [ ] Google Play Console 電話驗證完成
- [ ] 開發者帳戶身分驗證通過

### App 建立
- [ ] 建立新 App「錢錢管家」
- [ ] 預設語言：繁體中文（zh-TW）
- [ ] 類型：App / 免費

### 內部測試版本
- [ ] 建立內部測試軌道
- [ ] 上傳 app-release.aab（需 keystore 簽署）
- [ ] 加入測試人員（Sean + 測試裝置）

### 商店資訊
- [ ] App 名稱：錢錢管家
- [ ] 簡短說明（≤80 字）
- [ ] 完整說明（≤4000 字）
- [ ] 截圖 × 2~8 張（已備妥 5 張）
- [ ] Feature Graphic 1024×500（已備妥）
- [ ] App 圖示 512×512（已備妥）

### 合規
- [ ] 資料安全問卷（蒐集哪些資料、加密、分享對象）
- [ ] 內容分級問卷（答完自動取得分級）
- [ ] 隱私權政策 URL（已有 GitHub Pages 版本）
- [ ] 目標受眾 / 內容（一般大眾，無針對兒童）

### 上架
- [ ] 提交內部測試審核
- [ ] 測試通過後，提交正式版本審核
- [ ] 審核通過 → 正式上架

---

## 已知次要問題（不阻擋上架）

- 34 個 flutter analyze info（prefer_const / deprecated API 風格建議）
- Firebase Auth 預設關閉（kFirebaseConfigured=false），Google 登入需 Firebase 專案設定後才能啟用
- export_service CSV/Excel 中，category 欄位儲存的是 zh_TW 原始值（使用者資料），非 i18n 顯示值（設計決策）
