import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/localization.dart';
import '../../core/utils/error_handler.dart';
import '../../data/repositories/app_state.dart';
import '../../data/models/account.dart';
import '../../core/constants/app_colors.dart';
import 'add_edit_account_page.dart';

String _fmt(double v) => NumberFormat('#,##0', 'en_US').format(v.round());

class AccountPage extends StatefulWidget {
  final AppState state;
  const AccountPage({super.key, required this.state});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  AppState get s => widget.state;

  Future<void> _openAdd() async {
    final result = await Navigator.push<Account>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditAccountPage()),
    );
    if (result != null && mounted) s.addAccount(result);
  }

  Future<void> _openEdit(Account a) async {
    final result = await Navigator.push<Account>(
      context,
      MaterialPageRoute(builder: (_) => AddEditAccountPage(existing: a)),
    );
    if (result != null && mounted) s.updateAccount(a.id, result);
  }

  void _delete(Account a) {
    s.deleteAccount(a.id);
    ErrorHandler.showUndoSnack(
        context, AppLocalizations.ofParam(context, 'deleted_item', {'name': a.displayName}), () => s.addAccount(a));
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
        title: Text(AppLocalizations.of(context, 'accounts'), style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.gold,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold, size: 26),
            onPressed: _openAdd,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          final savings = s.accounts
              .where((a) => a.category == AccountCategory.savings)
              .toList();
          final credit = s.accounts
              .where((a) => a.category == AccountCategory.credit)
              .toList();
          final net = s.netAssets;
          final assets = s.totalAssets;
          final liabilities = s.totalLiabilities;
          final isNegative = net < 0;
          return CustomScrollView(
            slivers: [
              // ── 淨資產卡片 ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context, 'net_assets'),
                              style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(
                            'NT\$ ${_fmt(net)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color:
                                  isNegative ? AppColors.error : cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: cs.outlineVariant, height: 1),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(AppLocalizations.of(context, 'assets'),
                                      style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('NT\$ ${_fmt(assets)}',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.success)),
                                ])),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                  Text(AppLocalizations.of(context, 'liabilities'),
                                      style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('NT\$ ${_fmt(liabilities)}',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: liabilities > 0
                                              ? AppColors.error
                                              : cs.onSurfaceVariant)),
                                ])),
                          ]),
                        ]),
                  ),
                ),
              ),

              // ── 儲蓄帳戶 ──
              if (savings.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
                    child: Row(children: [
                      Text(AppLocalizations.of(context, 'savings_accounts'),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface)),
                      const Spacer(),
                      Text(AppLocalizations.ofParam(context, 'count_unit', {'n': savings.length}),
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 13)),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AccountCard(
                          account: savings[i],
                          fxRates: s.fxRates,
                          onTap: () => _openEdit(savings[i]),
                          onDelete: () => _delete(savings[i]),
                        ),
                      ),
                      childCount: savings.length,
                    ),
                  ),
                ),
              ],

              // ── 信用帳戶 ──
              if (credit.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
                    child: Row(children: [
                      Text(AppLocalizations.of(context, 'credit_accounts'),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface)),
                      const Spacer(),
                      Text(AppLocalizations.ofParam(context, 'count_unit', {'n': credit.length}),
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 13)),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AccountCard(
                          account: credit[i],
                          fxRates: s.fxRates,
                          onTap: () => _openEdit(credit[i]),
                          onDelete: () => _delete(credit[i]),
                          isCredit: true,
                        ),
                      ),
                      childCount: credit.length,
                    ),
                  ),
                ),
              ],

              // ── 空狀態 ──
              if (s.accounts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 40, 18, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 48, color: cs.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(AppLocalizations.of(context, 'no_accounts'),
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(AppLocalizations.of(context, 'add_first_account'),
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 13)),
                      ]),
                    ),
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final Map<String, double> fxRates;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isCredit;

  const _AccountCard({
    required this.account,
    required this.fxRates,
    required this.onTap,
    required this.onDelete,
    this.isCredit = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = account;
    final balanceTwd = a.balanceTwd(fxRates);
    final isNeg = balanceTwd < 0;

    return Dismissible(
      key: Key(a.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text(AppLocalizations.of(context, 'confirm_delete_title'),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                content: Text(AppLocalizations.ofParam(context, 'delete_confirm_account', {'name': a.displayName})),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(AppLocalizations.of(context, 'cancel'),
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(AppLocalizations.of(context, 'delete'),
                        style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child:
                    Text(a.icon ?? '💳', style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(a.displayName,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  if (a.note.isNotEmpty)
                    Text(a.note,
                        style:
                            TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '${a.currencySymbol} ${_fmt(a.balance)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: (isCredit || isNeg) ? AppColors.error : cs.onSurface,
                ),
              ),
              if (a.currency != 'TWD')
                Text('≈ NT\$ ${_fmt(balanceTwd)}',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
          ]),
        ),
      ),
    );
  }
}

extension on Account {
  String? get icon {
    try {
      return kAccountTypes
          .firstWhere((t) => t.name == typeName && t.category == category)
          .icon;
    } catch (_) {
      return null;
    }
  }
}
