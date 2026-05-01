import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/firebase_config.dart';
import '../data/models/user_profile.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db   = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn(
    serverClientId: kGoogleWebClientId,
  );

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  static Future<UserProfile?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) return null;

      // Check if existing profile to preserve marketingOptIn
      final doc = await _db.collection('users').doc(user.uid).get();
      final existing = doc.data();
      final optIn = existing?['marketingOptIn'] as bool? ?? false;

      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? googleUser.email,
        displayName: user.displayName ?? googleUser.displayName ?? '',
        photoUrl: user.photoURL ?? googleUser.photoUrl,
        marketingOptIn: optIn,
        createdAt: existing != null
            ? DateTime.tryParse(existing['createdAt'] as String? ?? '') ??
                DateTime.now()
            : DateTime.now(),
      );

      await _db
          .collection('users')
          .doc(user.uid)
          .set(profile.toFirestore(), SetOptions(merge: true));

      return profile;
    } catch (e) {
      return null;
    }
  }

  static Future<UserProfile?> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data == null) return null;
      return UserProfile(
        uid: user.uid,
        email: data['email'] as String? ?? user.email ?? '',
        displayName: data['displayName'] as String? ?? '',
        photoUrl: data['photoUrl'] as String?,
        marketingOptIn: data['marketingOptIn'] as bool? ?? false,
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> setMarketingOptIn(bool value) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({
      'marketingOptIn': value,
      'lastSeenAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
