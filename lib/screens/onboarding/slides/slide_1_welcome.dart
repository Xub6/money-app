import 'package:flutter/material.dart';
import '../../../config/localization.dart';
import '../../../core/constants/app_colors.dart';

class Slide1Welcome extends StatelessWidget {
  const Slide1Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 64,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            AppLocalizations.of(context, 'slide1_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context, 'slide1_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context, 'slide1_intro'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
