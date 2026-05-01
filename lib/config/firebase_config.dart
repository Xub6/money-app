import 'package:firebase_core/firebase_core.dart';

/// Set to true after filling in the values below from your Firebase project.
/// Firebase setup guide: see FIREBASE_SETUP.md in project root.
const kFirebaseConfigured = true;

const _apiKey             = 'AIzaSyASSQpYm72HU4TUTIoiR8Xi2Xjkw1L_i9A';
const _appId              = '1:549445262486:android:f4e941e57cfa9b8129f6b7';
const _messagingSenderId  = '549445262486';
const _projectId          = 'mp-01-7bdb0';
const _storageBucket      = 'mp-01-7bdb0.firebasestorage.app';

/// Web OAuth client ID — 啟用 Google 登入後取得
/// Firebase Console → 驗證 → Sign-in method → Google → Web 用戶端 ID
const kGoogleWebClientId  = '549445262486-beo0n137i2mgb3ropgk9o8jamq9ld1ts.apps.googleusercontent.com';

const kFirebaseOptions = FirebaseOptions(
  apiKey: _apiKey,
  appId: _appId,
  messagingSenderId: _messagingSenderId,
  projectId: _projectId,
  storageBucket: _storageBucket,
);
