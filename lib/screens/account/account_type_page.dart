import 'package:flutter/material.dart';
import '../../data/models/account.dart';
import '../../core/constants/app_colors.dart';

class AccountTypePage extends StatelessWidget {
  const AccountTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final savings = kAccountTypes.where((t) => t.category == AccountCategory.savings).toList();
    final credit = kAccountTypes.where((t) => t.category == AccountCategory.credit).toList();

    Widget section(String title, List<AccountTypeOption> types) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
          child: Text(title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: List.generate(types.length, (i) {
              final t = types[i];
              return Column(children: [
                InkWell(
                  onTap: () => Navigator.pop(context, t),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(children: [
                      Text(t.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Expanded(child: Text(t.name,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface))),
                      Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
                    ]),
                  ),
                ),
                if (i < types.length - 1)
                  Divider(height: 1, indent: 54, color: cs.outlineVariant),
              ]);
            }),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: const Text('帳戶類型', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
          color: AppColors.gold,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            section('儲蓄帳戶', savings),
            section('信用帳戶', credit),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
