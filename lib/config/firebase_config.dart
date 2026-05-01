import 'package:firebase_core/firebase_core.dart';

/// Set to true after filling in the values below from your Firebase project.
/// Firebase setup guide: see FIREBASE_SETUP.md in project root.
const kFirebaseConfigured = false;

/// Firebase project values — fill these in after creating the project.
/// How to get them: Firebase Console → Project Settings → Your apps → Android
const _apiKey             = 'YOUR_API_KEY';
const _appId              = 'YOUR_APP_ID';          // e.g. 1:123456:android:abcdef
const _messagingSenderId  = 'YOUR_SENDER_ID';
const _projectId          = 'YOUR_PROJECT_ID';      // e.g. qoryva-money-app
const _storageBucket      = 'YOUR_STORAGE_BUCKET';  // e.g. qoryva-money-app.appspot.com

/// Web OAuth client ID (for Google Sign-In serverClientId)
/// Firebase Console → Authentication → Sign-in method → Google → Web client ID
const kGoogleWebClientId  = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

const kFirebaseOptions = FirebaseOptions(
  apiKey: _apiKey,
  appId: _appId,
  messagingSenderId: _messagingSenderId,
  projectId: _projectId,
  storageBucket: _storageBucket,
);
