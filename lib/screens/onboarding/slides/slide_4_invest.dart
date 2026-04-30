import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class Slide4Invest extends StatelessWidget {
  const Slide4Invest({super.key});

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
                Icons.candlestick_chart_rounded,
                size: 52,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '追蹤投資組合',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            '記錄持股、成本與損益，台股美股通吃。',
            style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          _FeatureItem(
            icon: Icons.show_chart_rounded,
            title: '即時現價',
            desc: '台股、美股現價一鍵刷新',
            cs: cs,
          ),
          _FeatureItem(
            icon: Icons.currency_exchange_rounded,
            title: '多幣別換算',
            desc: '自動換算 TWD/USD 損益',
            cs: cs,
          ),
          _FeatureItem(
            icon: Icons.notes_rounded,
            title: '買入理由與策略',
            desc: '記錄買入原因與出場計畫',
            cs: cs,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '投資功能僅供個人紀錄與資訊整理使用，不構成投資建議。投資有風險，請自行判斷。',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
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
