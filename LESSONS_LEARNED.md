# 錢錢管家 — Lessons Learned

> 記錄開發過程中遇到的問題、教訓與最佳實踐，供未來 App 開發參考。

---

## LL-01：i18n 不能只檢查架構，必須實機語言切換驗證

**事件：** P0 Bug — i18n RC Blocker（2026-05-06 結案）

**問題：**
App 的多語言架構（AppLocalizations、localization keys、4 語言字典）存在且編譯正確，
但 UI 在切換到英文後仍有大量 hardcoded 中文殘留。
Claude 在多個 session 中宣告「i18n 完成」，但實際上並未全面處理所有頁面。

**根本原因：**
1. `flutter analyze` 通過 ≠ runtime 語言切換 UI 行為正確
2. `flutter build apk` 成功 ≠ 所有字串都走 localization path
3. 部分頁面有 hardcoded strings 根本沒有用 `AppLocalizations.of(context, key)`
4. 服務層（backup/encryption/export）exception message 是中文，透過 snackbar 直接顯示

**修復範圍（commit 1c55254）：**
- search_page.dart：RenewalCycle.label、category 顯示
- error_handler.dart：AppException.message 改由 localization key 查找
- backup_service.dart：5 個 BackupException 改用 key
- encryption_service.dart：2 個 DataException 改用 key
- export_service.dart：所有 FileException + CSV/Excel 內容全 i18n（加 Locale param）
- localization.dart：新增 34 個 key，4 語言全補

**教訓（規則）：**

| # | 規則 |
|---|------|
| 1 | i18n 不能只檢查架構存在，**必須實機切換語言驗證** |
| 2 | build 成功不代表 runtime UI 行為正確 |
| 3 | 所有宣稱支援多語言的 App，**發布前必須做四語切換驗收** |
| 4 | Claude 回報完成後，**仍需人工實機確認**，通過後才可關閉 P0 |
| 5 | 未來 release gate 必須採用 **no evidence, no pass** 原則 |

---

## LL-02：服務層 exception message 須用 localization key，不得 hardcode 語言字串

**問題：** `BackupException(message: '備份匯出失敗')` 這類寫法，當 exception 透過 `ErrorHandler.showErrorSnack` 顯示時，會直接呈現中文，忽略用戶設定的語言。

**正確做法：**
```dart
// ❌ 錯誤
throw BackupException(message: '備份匯出失敗');

// ✅ 正確
throw BackupException(message: 'backup_export_error'); // localization key
// ErrorHandler.getLocalizedMessage 會查找 AppLocalizations.of(context, key)
```

---

## LL-03：export service 需要 Locale 參數，不能依賴 BuildContext

**問題：** `ExportService` 是純 service，沒有 BuildContext，所以無法直接呼叫 `AppLocalizations.of(context, key)`。

**解決方案：** 在 export 方法上加 `Locale locale` 參數，使用 `AppLocalizations.translate(locale, key)` 靜態方法。呼叫端（widget）傳入 `Localizations.localeOf(context)`。

---

## LL-04：RC 驗收必須走完整的 Release Quality Gate

**定義（RC Blockers）：**
1. `flutter analyze` 0 error
2. `flutter build apk --release` 成功
3. `flutter build appbundle --release` 成功
4. 實機安裝 APK，走完核心功能流程（記帳、預算、投資、管理）
5. 實機切換 4 種語言，確認 UI 無中文殘留（英文 / 日文 / 簡中 / 繁中）
6. 深色模式切換，確認無硬編碼顏色殘留

**原則：no evidence, no pass。Claude 回報完成 ≠ 通過。Sean 手機實機確認 = 通過。**

---

*本文件隨每次 P0/P1 bug 結案後更新。*
