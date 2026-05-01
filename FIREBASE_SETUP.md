# Firebase 設定指南（啟用 Gmail 登入）

> 完成以下步驟後，在 `lib/config/firebase_config.dart` 填入對應值，並將 `kFirebaseConfigured` 改為 `true`，重新建置 APK 即可啟用。

---

## 步驟 1：建立 Firebase 專案

1. 前往 https://console.firebase.google.com/
2. 點「建立專案」→ 輸入名稱（例如：`qoryva-money-app`）
3. 可選擇停用 Google Analytics（簡化設定）→ 建立

---

## 步驟 2：新增 Android 應用程式

1. 在 Firebase 專案首頁，點「新增應用程式」→ 選 Android 圖示
2. 填入：
   - Android 套件名稱：`com.qoryva.moneymanager`
   - 應用程式暱稱：`錢錢管家`
   - **偵錯 SHA-1**（開發用，從 debug keystore 取得）
   - **發布 SHA-1**（Play Store 正式版）：`7A:48:FD:CB:10:3F:83:AC:42:86:AB:62:89:B2:E8:95:9E:2A:75:94`
3. 點「註冊應用程式」

---

## 步驟 3：取得 google-services.json（備用）

> 本專案使用手動 FirebaseOptions，**不需要** google-services.json。但若 Google 要求下載，跳過即可。

---

## 步驟 4：取得設定值填入程式碼

1. Firebase Console → 齒輪圖示 → 「專案設定」
2. 往下捲到「您的應用程式」→ 選 Android 應用程式
3. 複製以下值，填入 `lib/config/firebase_config.dart`：

| 程式碼常數 | Firebase 欄位名稱 |
|------------|------------------|
| `_apiKey` | API 金鑰 |
| `_appId` | 應用程式 ID（格式：`1:123:android:abc`）|
| `_messagingSenderId` | 傳訊者 ID |
| `_projectId` | 專案 ID |
| `_storageBucket` | 儲存空間值區 |

---

## 步驟 5：啟用 Google 登入

1. Firebase Console → 左側「驗證」→「Sign-in method」
2. 點「Google」→ 啟用 → 填入「專案支援電子郵件」（用你的 Gmail）→ 儲存
3. 在同頁面，點「Web SDK 設定」→ 複製「Web 用戶端 ID」
4. 填入 `lib/config/firebase_config.dart` 的 `kGoogleWebClientId`

---

## 步驟 6：建立 Firestore 資料庫

1. Firebase Console → 左側「Firestore Database」→ 建立資料庫
2. 選「正式模式」→ 選擇伺服器位置（`asia-east1` 台灣最近）→ 啟用
3. 前往「規則」，貼上以下安全規則：

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 步驟 7：啟用並重建

開啟 `lib/config/firebase_config.dart`，將：
```dart
const kFirebaseConfigured = false;
```
改為：
```dart
const kFirebaseConfigured = true;
```

然後重建 APK：
```bash
cd ~/money-app && /c/src/flutter/bin/flutter build apk --release
```

---

## 查看用戶資料

Firebase Console → Firestore Database → `users` 集合，可看到每位登入用戶的：
- 電子郵件
- 名稱
- 是否同意接收行銷訊息（`marketingOptIn`）
- 首次登入時間、最後使用時間
