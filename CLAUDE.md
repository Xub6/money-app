# 給下一個 Claude 的說明書

## 第一步：永遠先讀這兩個

1. 這個檔案（你現在在讀）
2. `progress_file.txt` — 上次做到哪、目前狀態

讀完後問用戶：「上次做到 [狀態]，要繼續還是有新任務？」

---

## 專案基本資訊

- **App 名稱**：錢錢管家
- **類型**：Flutter 個人財務 app（Android）
- **GitHub**：https://github.com/Xub6/money-app.git（分支：main）
- **本機路徑**：`C:/Users/sshuser/money-app`
- **Flutter 路徑**：`/c/src/flutter/bin/flutter`
- **用戶 GitHub**：Xub6

---

## 溝通習慣

| 用戶說 | 代表 |
|--------|------|
| 「全權交給你」 | 完全授權，直接做完整條流程，不需逐步確認 |
| `echo "..."` 傳需求 | 同上，直接執行 |
| `github check` | 先看 `git log`、`git status`，報告目前狀態 |
| 把截圖放到 `photo/` | 想讓你看目前 app 畫面，主動去讀 |
| `ls -l "..."` 或 `wget "..."` 夾帶中文訊息 | 是口誤，真正的需求在引號裡的中文 |

- 溝通語言：**繁體中文**
- 截圖位置：`build/app/outputs/flutter-apk/photo/`（手機透過 SSH 上傳）

---

## 標準工作流程（每次改完功能都要跑完）

```bash
# 1. 建 APK
cd ~/money-app && /c/src/flutter/bin/flutter build apk --release

# 2. commit + push（SSH，不需要 PAT）
git add <改過的檔案>
git commit -m "feat/fix/design: 描述"
git push origin main

# 3. 更新 progress_file.txt → commit push
```

- APK 路徑：`C:\Users\sshuser\money-app\build\app\outputs\flutter-apk\app-release.apk`
- 用戶用手機 SSH app（Server Auditor）直接從上面路徑下載安裝，**不需要 GitHub Releases**
- push 用 SSH（金鑰 `~/.ssh/id_ed25519`），**完全不需要 PAT**

---

## 圖示（App Icon）相關

- 主圖檔：`assets/icon.png`（1024×1024）
- 生成工具：Node.js + `canvas` 套件（`node_modules/canvas` 已安裝）
- 生成指令範例：`node -e "const { createCanvas } = require('canvas'); ..."`
- 每次修改圖示後必做：
  1. 重新生成所有 Android mipmap：mdpi(48) / hdpi(72) / xhdpi(96) / xxhdpi(144) / xxxhdpi(192)
  2. 複製一份 JPG 到 `build/app/outputs/flutter-apk/photo/app_icon.jpg` 讓用戶 SSH 預覽
  3. 重建 APK + commit push

---

## 設計規範

### 顏色
- 金色主色：`AppColors.gold = Color(0xFFC59B63)`
- 深色模式：`theme_provider.dart` 手動定義 ColorScheme，底色 `#111111`，卡片 `#1C1C1E`
- **禁止**在 widget 裡硬寫 `Colors.white`、`Colors.black`、`Colors.grey`，一律用 `Theme.of(context).colorScheme.*`
- CustomPainter 無 context，顏色要當參數傳入
- `AppColors.goldLight` 等硬編碼淺色禁用於深色模式，改 `colorScheme.primaryContainer`

### UI 風格
- 表單頁面偏好 **iOS grouped sections**：section header + 欄位卡片，label 左 input 右
- 用戶會傳參考截圖，要**仔細讀圖對齊**，不要自行發揮
- 遇到分散的 UI 入口，主動建議統一（如統一 FAB）
- 各頁面一致性優先

---

## 技術架構

| 項目 | 說明 |
|------|------|
| 頁面 | 記帳（DashboardPage）、明細（DetailPage）、投資（InvestPage）、管理（ManagePage） |
| 導航 | PageView 左右滑動 + BottomAppBar 缺口中央 FAB |
| 狀態管理 | Provider（AppState、ThemeProvider） |
| 儲存 | SharedPreferences（JSON） |
| 股價 | Yahoo Finance API（`stock_service.dart`） |
| 台股中文名 | TWSE codeQuery API（`_fetchTwseNameByCode`） |
| 匯率 | `AppState.fxRates Map<String, double>`，並行抓取 TWD/USD/JPY/EUR/GBP/CNY/HKD |

### 中央 FAB 行為
- Tab 0/1（記帳/明細）→ 新增支出（Icons.add）
- Tab 2（投資）→ 新增投資（Icons.trending_up_rounded）
- Tab 3（管理）→ 新增固定開銷（Icons.playlist_add_rounded）

---

## 已知技術細節 & 坑

- **台股搜尋**：用 TWSE `codeQuery` API，不用 Yahoo Finance（Yahoo 搜不到中文）
- **美股搜尋**：用 Yahoo Finance `/v1/finance/search`
- **損益計算**：`netCurrentValueTwd = gross × (1 - feeRate - txTax)`（台股 txTax=0.003，美股=0）
- **台股刷新**：需按 🔄 才會抓 TWSE 中文名（Yahoo 只回英文）
- **GCM 問題**：HTTPS push 被 Windows GCM 攔截，已改用 SSH，不會再遇到
- **深色模式常見遺漏**：FilterChip / Card / TextField 的 `backgroundColor`/`fillColor`/`color` 很容易忘記改

---

## 已完成功能清單

| # | 功能 | 完成日 |
|---|------|--------|
| 1 | 深色模式全面改用 colorScheme | 2026-04-20 |
| 2 | 投資頁面改版（對齊參考設計） | 2026-04-20 |
| 3 | 即時股價（Yahoo Finance） | 2026-04-20 |
| 4 | 統一中央 FAB | 2026-04-20 |
| 5 | 頁面左右滑動切換（PageView） | 2026-04-20 |
| 6 | SSH 金鑰設定（取代 PAT） | 2026-04-20 |
| 7 | App 名稱改「錢錢管家」 | 2026-04-21 |
| 8 | 月份按鈕顯示實際月份數字 | 2026-04-21 |
| 9 | 預算進度「含/不含固定開銷」切換 | 2026-04-21 |
| 10 | 台股中文搜尋（TWSE API） | 2026-04-21 |
| 11 | 券商手續費自訂（台股/美股分開） | 2026-04-21 |
| 12 | App 圖示設計（多版本） | 2026-04-21 |
| 13 | 投資總現值改用扣費後淨值 | 2026-04-21 |
| 14 | 深色模式配色改版（iOS/Material 標準色） | 2026-04-21 |
| 15 | 持股中文名稱優先顯示 | 2026-04-21 |
| 16 | 賬戶管理功能（多幣別、淨資產） | 2026-04-21 |
| 17 | 搜索頁深色模式修正 | 2026-04-21 |
| 18 | App 圖示重設計（金融風格柱狀圖） | 2026-04-21 |

---

## 更新 progress_file.txt（每次完成後必做）

格式：
```
## 目前狀態：待機中
最後完成任務：xxx（2026-xx-xx）✅

### 完成紀錄
- [日期] 功能描述
```

完成後 `git add progress_file.txt && git commit -m "docs: 更新進度" && git push origin main`
