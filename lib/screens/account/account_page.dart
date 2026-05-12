import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/localization.dart';
import '../../core/constants/app_colors.dart';
import '../../core/tour/tour_controller.dart';
import '../../core/tour/tour_keys.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/account.dart';
import '../../data/repositories/app_state.dart';
import 'add_edit_account_page.dart';
import '../transfer/transfer_page.dart';
import '../manage/fixed_expenses_page.dart';
import '../loan/loan_page.dart';

String _fmt(double v) => NumberFormat('#,##0', 'en_US').format(v.round());

class AccountPage extends StatefulWidget {
  final AppState state;
  final bool isFromTour;
  const AccountPage({super.key, required this.state, this.isFromTour = false});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  AppState get s => widget.state;
  bool _includeStock = true;
  static const _kIncludeStockKey = 'account_include_stock';

  @override
  void initState() {
    super.initState();
    _loadIncludeStock();
  }

  Future<void> _loadIncludeStock() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_kIncludeStockKey);
    if (saved != null && mounted) setState(() => _includeStock = saved);
  }

  Future<void> _setIncludeStock(bool value) async {
    s.hapticLight();
    setState(() => _includeStock = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIncludeStockKey, value);
  }

  Future<void> _openAdd() async {
    // Notify tour: clears spotlight so AddEditAccountPage is fully interactive
    if (mounted) {
      try { context.read<TourController>().notifyAddAccountPageOpened(); } catch (_) {}
    }
    final result = await Navigator.push<Account>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditAccountPage()),
    );
    if (!mounted) return;
    if (result != null) {
      s.addAccount(result);
      // Notify tour: controller handles auto-pop + goToTab(0) + success snackbar
      try { context.read<TourController>().onAccountCreated(result); } catch (_) {}
    } else {
      // User cancelled — restore spotlight on the + button
      try { context.read<TourController>().notifyFormDismissed(); } catch (_) {}
    }
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

  void _showBudgetSheet() {
    final ctrl = TextEditingController(text: s.budget.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text(AppLocalizations.of(context, 'monthly_budget'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context, 'cancel'),
                  style: TextStyle(
                      color:
                          Theme.of(ctx).colorScheme.onSurfaceVariant)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  prefixText: 'NT\$ ',
                  filled: true,
                  fillColor: Theme.of(ctx).colorScheme.primaryContainer,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.gold, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(ctrl.text.trim());
                if (val != null && val > 0) {
                  s.setBudget(val);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppLocalizations.of(context, 'budget_updated')),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                elevation: 0,
              ),
              child: Text(AppLocalizations.of(context, 'update'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Key? rowKey,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      key: rowKey,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
          ),
          Icon(Icons.chevron_right, color: AppColors.gold, size: 18),
        ]),
      ),
    );
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
            key: TourKeys.accountAddBtn,
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
          final stockValue = s.totalPortfolioValue;
          final displayAssets = _includeStock ? s.totalAssetsDisplay : s.totalAssets;
          final displayNet = _includeStock ? s.netAssets : s.totalAssets - s.totalLiabilities;
          final liabilities = s.totalLiabilities;
          final isNegative = displayNet < 0;
          return CustomScrollView(
            slivers: [
              if (widget.isFromTour)
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: AppColors.gold.withValues(alpha: 0.12),
                    child: Row(children: [
                      const Icon(Icons.north_east_rounded, color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context, 'tour_account_hint'),
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
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
                            'NT\$ ${_fmt(displayNet)}',
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
                                  Text('NT\$ ${_fmt(displayAssets)}',
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
                          // ── 股票投資組合行 + 含股票開關 ──
                          if (stockValue > 0) ...[
                            const SizedBox(height: 12),
                            Divider(color: cs.outlineVariant, height: 1),
                            const SizedBox(height: 12),
                            Row(children: [
                              Icon(Icons.show_chart_rounded,
                                  size: 16, color: AppColors.gold),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context, 'stock_portfolio'),
                                style: TextStyle(
                                    color: cs.onSurfaceVariant, fontSize: 12),
                              ),
                              const Spacer(),
                              Text(
                                'NT\$ ${_fmt(stockValue)}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gold),
                              ),
                            ]),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _setIncludeStock(!_includeStock),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _includeStock
                                      ? AppColors.gold
                                      : cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(
                                    _includeStock
                                        ? Icons.toggle_on_rounded
                                        : Icons.toggle_off_rounded,
                                    size: 16,
                                    color: _includeStock
                                        ? Colors.white
                                        : cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context, 'include_stock'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _includeStock
                                          ? Colors.white
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ]),
                  ),
                ),
              ),

              // ── 帳戶轉帳入口 ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TransferPage()),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      child: Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded,
                              color: AppColors.gold, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                              AppLocalizations.of(context, 'transfer'),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              AppLocalizations.of(context, 'from_account') +
                                  ' → ' +
                                  AppLocalizations.of(context, 'to_account'),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant),
                            ),
                          ]),
                        ),
                        Icon(Icons.chevron_right,
                            color: AppColors.gold, size: 18),
                      ]),
                    ),
                  ),
                ),
              ),

              // ── 定期管理 & 借款管理 ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                  child: Column(children: [
                    // 定期管理 header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(AppLocalizations.of(context, 'periodic_management'),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant)),
                      ),
                    ),
                    // 固定開銷
                    ListenableBuilder(
                      listenable: s,
                      builder: (_, __) => _featureRow(
                        icon: Icons.receipt_long_rounded,
                        title: AppLocalizations.of(context, 'fixed_expenses'),
                        subtitle: AppLocalizations.ofParam(context, 'fixed_count_monthly', {'count': s.fixedItems.length, 'amount': NumberFormat('#,###').format(s.fixedTotal)}),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    FixedExpensesPage(state: s))),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 月預算
                    ListenableBuilder(
                      listenable: s,
                      builder: (_, __) => _featureRow(
                        icon: Icons.savings_rounded,
                        title: AppLocalizations.of(context, 'monthly_budget'),
                        subtitle: AppLocalizations.ofParam(context, 'budget_current', {'amount': NumberFormat('#,###').format(s.budget)}),
                        onTap: _showBudgetSheet,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 借款管理 header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(AppLocalizations.of(context, 'loan_management'),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant)),
                      ),
                    ),
                    // 借款紀錄
                    ListenableBuilder(
                      listenable: s,
                      builder: (_, __) {
                        final active =
                            s.loans.where((l) => !l.isCompleted).length;
                        return _featureRow(
                          icon: Icons.handshake_rounded,
                          title: AppLocalizations.of(context, 'loan_records'),
                          subtitle: active > 0
                              ? AppLocalizations.ofParam(context, 'loan_active_count', {'count': active})
                              : AppLocalizations.of(context, 'no_loans_active'),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      LoanPage(state: s))),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ]),
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
