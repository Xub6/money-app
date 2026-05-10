import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/localization.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/fixed_item.dart';
import '../../data/repositories/app_state.dart';
import 'add_edit_fixed_page.dart';

String _fmtF(int n) => NumberFormat('#,###').format(n);

class FixedExpensesPage extends StatelessWidget {
  final AppState state;
  const FixedExpensesPage({super.key, required this.state});

  Future<void> _openDialog(BuildContext context, {FixedItem? existing}) async {
    final result = await Navigator.push<FixedItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditFixedPage(existing: existing),
        fullscreenDialog: true,
      ),
    );
    if (result == null) return;
    if (existing != null) {
      state.updateFixed(existing.id, result);
    } else {
      state.addFixed(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        title: const Text('固定開銷',
            style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.gold,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold, size: 26),
            onPressed: () => _openDialog(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final items = state.fixedItems;
          if (items.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.receipt_long_outlined,
                    size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('尚無固定開銷',
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
                const SizedBox(height: 6),
                Text('點右上角 + 新增',
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
            itemCount: items.length + 1,
            itemBuilder: (ctx, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Text('每月固定',
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant)),
                    const Spacer(),
                    Text('NT\$ ${_fmtF(state.fixedTotal)}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700)),
                  ]),
                );
              }
              final f = items[index - 1];
              final now = DateTime.now();
              return _FixedItemTile(
                item: f,
                completed: f.isCompleted,
                remaining: f.remainingPeriods(now),
                cs: cs,
                onEdit: () => _openDialog(context, existing: f),
                onDelete: () {
                  state.deleteFixed(f.id);
                  state.hapticHeavy();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('已刪除固定開銷「${f.title}」'),
                    action: SnackBarAction(
                        label: '復原', onPressed: () => state.addFixed(f)),
                    duration: const Duration(seconds: 3),
                    showCloseIcon: true,
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _FixedItemTile extends StatelessWidget {
  final FixedItem item;
  final bool completed;
  final int? remaining;
  final ColorScheme cs;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FixedItemTile({
    required this.item,
    required this.completed,
    required this.remaining,
    required this.cs,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
            color: AppColors.error, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async =>
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('刪除固定開銷',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              content:
                  Text('確定要刪除「${item.title}」嗎？\n刪除後不會再自動扣款。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('取消')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('刪除',
                      style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ) ??
          false,
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onLongPress: onEdit,
        child: Opacity(
          opacity: completed ? 0.45 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(12)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.receipt_long,
                        color: completed
                            ? cs.onSurfaceVariant
                            : AppColors.gold,
                        size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item.title,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: completed
                                    ? cs.onSurfaceVariant
                                    : cs.onSurface))),
                    Text('NT\$ ${_fmtF(item.amount)}',
                        style:
                            const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    if (item.debitDay > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          AppLocalizations.ofParam(context,
                              'debit_day_value', {'day': item.debitDay}),
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    GestureDetector(
                      onTap: onEdit,
                      child: const Icon(Icons.edit_outlined,
                          color: AppColors.gold, size: 18),
                    ),
                  ]),
                  if (item.totalPeriods != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const SizedBox(width: 28),
                      if (completed)
                        Text(
                            AppLocalizations.ofParam(context,
                                'periods_completed', {'n': item.totalPeriods}),
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant))
                      else ...[
                        Flexible(
                          child: Text(
                            AppLocalizations.ofParam(context,
                                'fixed_start_periods', {
                              'date': DateFormat('yyyy/MM')
                                  .format(item.startDate),
                              'n': item.totalPeriods
                            }),
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            AppLocalizations.ofParam(context,
                                'periods_remaining_label', {'n': remaining}),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: completed
                            ? 1.0
                            : (item.totalPeriods! - (remaining ?? 0)) /
                                item.totalPeriods!,
                        minHeight: 4,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(completed
                            ? cs.onSurfaceVariant
                            : AppColors.gold),
                      ),
                    ),
                  ],
                ]),
          ),
        ),
      ),
    );
  }
}
