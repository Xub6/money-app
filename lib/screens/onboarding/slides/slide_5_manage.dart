import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class Slide5Manage extends StatelessWidget {
  const Slide5Manage({super.key});

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
                Icons.settings_rounded,
                size: 52,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '全面管理財務',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            '固定開銷、帳戶管理、備份匯出，一切盡在掌握。',
            style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          _FeatureItem(
            icon: Icons.receipt_long_rounded,
            title: '固定開銷',
            desc: '房租、訂閱服務等每月固定支出一次設定',
            cs: cs,
          ),
          _FeatureItem(
            icon: Icons.account_balance_wallet_rounded,
            title: '帳戶管理',
            desc: '多帳戶、多幣別，即時掌握淨資產',
            cs: cs,
          ),
          _FeatureItem(
            icon: Icons.backup_rounded,
            title: '備份與匯出',
            desc: '資料備份、CSV/Excel 匯出，安全無虞',
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
