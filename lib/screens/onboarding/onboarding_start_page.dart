import 'package:flutter/material.dart';
import '../../config/localization.dart';
import '../../core/constants/app_colors.dart';
import '../../core/tour/tour_step.dart';

/// 新手導覽入口選擇頁
/// 三個入口各自傳入不同 OnboardingMode，無 nullable fallback。
class OnboardingStartPage extends StatelessWidget {
  final void Function(OnboardingMode mode) onSelect;
  final VoidCallback? onSkip;

  const OnboardingStartPage({
    super.key,
    required this.onSelect,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 52),

              // ── App icon ──────────────────────────────────
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.gold,
                    size: 36,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ── Title ─────────────────────────────────────
              Text(
                AppLocalizations.of(context, 'onboarding_start_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                AppLocalizations.of(context, 'onboarding_start_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              // ── 快速開始（主推）──────────────────────────
              _OptionCard(
                icon: Icons.flash_on_rounded,
                iconColor: AppColors.gold,
                title: AppLocalizations.of(context, 'onboarding_quick_title'),
                desc: AppLocalizations.of(context, 'onboarding_quick_desc'),
                isHighlight: true,
                onTap: () => onSelect(OnboardingMode.quickStart),
              ),

              const SizedBox(height: 12),

              // ── 完整設定 ──────────────────────────────────
              _OptionCard(
                icon: Icons.tune_rounded,
                iconColor: Colors.blueAccent,
                title: AppLocalizations.of(context, 'onboarding_full_title'),
                desc: AppLocalizations.of(context, 'onboarding_full_desc'),
                onTap: () => onSelect(OnboardingMode.fullSetup),
              ),

              const SizedBox(height: 12),

              // ── 先看範例 ──────────────────────────────────
              _OptionCard(
                icon: Icons.visibility_rounded,
                iconColor: Colors.purpleAccent,
                title: AppLocalizations.of(context, 'onboarding_demo_title'),
                desc: AppLocalizations.of(context, 'onboarding_demo_desc'),
                onTap: () => onSelect(OnboardingMode.demo),
              ),

              const Spacer(),

              // ── 跳過 ──────────────────────────────────────
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: cs.onSurface.withValues(alpha: 0.35),
                ),
                child: Text(
                  AppLocalizations.of(context, 'onboarding_skip'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 選項卡片 ──────────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;
  final bool isHighlight;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
    this.isHighlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: isHighlight
          ? AppColors.gold.withValues(alpha: 0.07)
          : cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHighlight
                  ? AppColors.gold.withValues(alpha: 0.55)
                  : cs.outlineVariant.withValues(alpha: 0.25),
              width: isHighlight ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: cs.onSurface.withValues(alpha: 0.28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
