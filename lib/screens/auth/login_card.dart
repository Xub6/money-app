import 'package:flutter/material.dart';
import '../../config/firebase_config.dart';
import '../../config/localization.dart';
import '../../data/models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../core/constants/app_colors.dart';

class LoginCard extends StatefulWidget {
  const LoginCard({super.key});

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  UserProfile? _profile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (kFirebaseConfigured) _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await AuthService.getProfile();
    if (mounted) setState(() => _profile = p);
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final p = await AuthService.signInWithGoogle();
    if (mounted) setState(() { _profile = p; _loading = false; });
    if (p != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.ofParam(context, 'welcome_name', {'name': p.displayName})),
          backgroundColor: AppColors.gold,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context, 'confirm_logout')),
        content: Text(AppLocalizations.of(context, 'logout_note')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context, 'cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context, 'logout'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.signOut();
      if (mounted) setState(() => _profile = null);
    }
  }

  Future<void> _toggleOptIn(bool value) async {
    setState(() => _profile = _profile?.copyWith(marketingOptIn: value));
    await AuthService.setMarketingOptIn(value);
  }

  @override
  Widget build(BuildContext context) {
    if (!kFirebaseConfigured) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context, 'personal_account'),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.45),
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _profile == null
              ? _buildSignInTile(cs)
              : _buildProfileTile(cs),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSignInTile(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppLocalizations.of(context, 'sign_in_gmail'),
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(AppLocalizations.of(context, 'backup_description'),
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(AppLocalizations.of(context, 'google_signin'), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(AppLocalizations.of(context, 'signin_optional'),
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.35))),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(ColorScheme cs) {
    final p = _profile!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
                backgroundColor: AppColors.gold.withValues(alpha: 0.3),
                child: p.photoUrl == null
                    ? Text(p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.gold))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.displayName,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: cs.onSurface),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(p.email,
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
        SwitchListTile(
          dense: true,
          title: Text(AppLocalizations.of(context, 'receive_updates'),
              style: TextStyle(fontSize: 14, color: cs.onSurface)),
          subtitle: Text(AppLocalizations.of(context, 'receive_updates_subtitle'),
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45))),
          value: p.marketingOptIn,
          onChanged: _toggleOptIn,
          activeThumbColor: AppColors.gold,
        ),
        Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
        TextButton(
          onPressed: _signOut,
          child: Text(AppLocalizations.of(context, 'logout'), style: TextStyle(color: cs.error, fontSize: 14)),
        ),
      ],
    );
  }
}
