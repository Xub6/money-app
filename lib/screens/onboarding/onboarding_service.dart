import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _seenKey = 'onboarding_seen';
  static const _versionKey = 'onboarding_version';
  static const _skipRedirectKey = 'onb_skip_redirect_pending';
  static const kOnboardingVersion = 1;

  static Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
    await prefs.setInt(_versionKey, kOnboardingVersion);
  }

  static Future<void> setSkipRedirectPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipRedirectKey, true);
  }

  static Future<bool> isSkipRedirectPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skipRedirectKey) ?? false;
  }

  static Future<void> clearSkipRedirectPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skipRedirectKey);
  }
}
