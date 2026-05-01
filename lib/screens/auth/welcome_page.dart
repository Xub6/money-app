import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/firebase_config.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class WelcomePage extends StatefulWidget {
  final VoidCallback onComplete;
  const WelcomePage({super.key, required this.onComplete});

  static Future<bool> isSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('welcome_seen') ?? false;
  }

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final p = await AuthService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (p != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('歡迎，${p.displayName}！'),
          backgroundColor: AppColors.gold,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    await _markSeen();
    if (mounted) widget.onComplete();
  }

  Future<void> _continueAsGuest() async {
    await _markSeen();
    if (mounted) widget.onComplete();
  }

  static Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_seen', true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App icon
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset('assets/icon.png', width: 100, height: 100),
              ),
              const SizedBox(height: 24),

              Text(
                '錢錢管家',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '輕鬆管理每一分錢',
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),

              const Spacer(flex: 3),

              // Google sign in
              if (kFirebaseConfigured) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(FontAwesomeIcons.google,
                                  size: 18, color: Colors.black),
                              SizedBox(width: 10),
                              Text('使用 Google 登入',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Guest
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _loading ? null : _continueAsGuest,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: cs.onSurface.withValues(alpha: 0.2), width: 1.5),
                    foregroundColor: cs.onSurface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('以訪客身分繼續',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Google 登入為選填，所有財務資料均儲存於本機',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
