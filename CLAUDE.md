# 給下一個 Claude 的說明書

## 第一步：永遠先讀這兩個

1. 這個檔案（你現在在讀）
2. `progress_file.txt` — 上次做到哪、目前狀態

---

## 專案基本資訊

- **App 名稱**：錢錢管家
- **類型**：Flutter 個人財務 app（Android）
- **GitHub**：https://github.com/Xub6/money-app.git（分支：main）
- **本機路徑**：`C:/Users/sshuser/money-app`
- **Flutter 路徑**：`/c/src/flutter/bin/flutter`

---

## 用戶溝通習慣

- 用戶說「全權交給你」或用 `echo "..."` 傳達需求，代表**完全授權，直接做不用逐步確認**
- 用戶會把截圖放到 `build/app/outputs/flutter-apk/photo/` 讓你看目前 app 狀態
- 用戶說「github check」→ 讀 `progress_file.txt` 了解上次進度
- 溝通語言：繁體中文

---

## 標準工作流程（每次改完功能都要跑完）

```bash
# 1. 建 APK
cd ~/money-app && /c/src/flutter/bin/flutter build apk --release

# 2. commit + push
git add <改過的檔案>
git commit -m "feat/fix: 描述"
git push origin main
```

- APK 路徑：`C:\Users\sshuser\money-app\build\app\outputs\flutter-apk\app-release.apk`
- 用戶用手機 SSH app（Server Auditor）直接從上面路徑下載安裝，**不需要 GitHub Releases**
- push 用 SSH（`git@github.com:Xub6/money-app.git`），**不需要 PAT**

---

## 更新 progress_file.txt（每次完成後必做）

```
## 目前狀態：待機中
最後完成任務：xxx（2026-xx-xx）✅
```

把完成的項目加進完成紀錄，然後 commit push。

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

## 主色系

- 金色主色：`AppColors.gold = Color(0xFFC59B63)`
- 深色模式：手動定義 ColorScheme（`theme_provider.dart`），底色 `#111111`，卡片 `#1C1C1E`
- **禁止**在 widget 裡硬寫 `Colors.white`、`Colors.black`、`Colors.grey`，一律用 `Theme.of(context).colorScheme.*`

---

## 已知慣例

- 截圖參考放在 `build/app/outputs/flutter-apk/photo/`，用戶每次放新截圖讓你看現況
- 台股持股需按 🔄 刷新才會抓中文名稱（Yahoo Finance 回英文，TWSE 回中文）
- `kGoldLight` 這類硬編碼淺色不能用在深色模式，改用 `colorScheme.primaryContainer`
