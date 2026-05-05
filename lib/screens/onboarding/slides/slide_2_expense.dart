import 'package:flutter/material.dart';
import '../../../config/localization.dart';
import '../../../core/constants/app_colors.dart';

class Slide2Expense extends StatelessWidget {
  const Slide2Expense({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pie_chart_rounded,
                size: 52,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context, 'slide2_title'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context, 'slide2_subtitle'),
            style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          _FeatureItem(
            icon: Icons.add_circle_outline_rounded,
            title: AppLocalizations.of(context, 'slide2_f1_title'),
            desc: AppLocalizations.of(context, 'slide2_f1_desc'),
            cs: cs,
          ),
          _FeatureItem(
            icon: Icons.local_fire_department_rounded,
            title: AppLocalizations.of(context, 'slide2_f2_title'),
            desc: AppLocalizations.of(context, 'slide2_f2_desc'),
            cs: cs,
          ),
          _FeatureItem(
            icon: Icons.search_rounded,
            title: AppLocalizations.of(context, 'slide2_f3_title'),
            desc: AppLocalizations.of(context, 'slide2_f3_desc'),
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final ColorScheme cs;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
