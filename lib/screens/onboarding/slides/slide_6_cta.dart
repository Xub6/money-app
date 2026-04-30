import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class Slide6Cta extends StatelessWidget {
  final bool hasExpenses;
  final VoidCallback onAddExpense;
  final VoidCallback onSkip;

  const Slide6Cta({
    super.key,
    required this.hasExpenses,
    required this.onAddExpense,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
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
                Icons.check_circle_rounded,
                size: 52,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '你已準備好了！',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            '完成以下步驟，開始掌管你的財務。',
            style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _CheckItem(label: '了解記帳功能', checked: true, cs: cs),
                const SizedBox(height: 12),
                _CheckItem(label: '了解預算管理', checked: true, cs: cs),
                const SizedBox(height: 12),
                _CheckItem(label: '了解投資追蹤', checked: true, cs: cs),
                const SizedBox(height: 12),
                _CheckItem(
                  label: '新增第一筆支出',
                  checked: hasExpenses,
                  cs: cs,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddExpense,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                '新增第一筆支出',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onSkip,
              child: Text(
                '直接進入 App',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool checked;
  final ColorScheme cs;

  const _CheckItem({
    required this.label,
    required this.checked,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          checked
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: checked ? AppColors.gold : cs.onSurfaceVariant,
          size: 22,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: checked ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
