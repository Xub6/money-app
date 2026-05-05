import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/error_handler.dart';
import '../../data/repositories/app_state.dart';
import '../../data/models/stock_holding.dart';
import '../../core/constants/app_colors.dart';
import '../../services/stock_service.dart';
import 'add_edit_investment_page.dart';
import '../../core/tour/tour_keys.dart';
import '../../config/localization.dart';

const _kGold = AppColors.gold;
const _kGreen = AppColors.success;
const _kRed = AppColors.error;

String _fmt(double v) {
  if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  return NumberFormat('#,##0', 'en_US').format(v.round());
}

String _fmtPrice(double v) {
  if (v >= 100) return v.toStringAsFixed(2);
  if (v >= 10) return v.toStringAsFixed(2);
  return v.toStringAsFixed(3);
}

String _fmtShares(double shares) {
  if (shares == shares.roundToDouble()) return shares.round().toString();
  return shares.toString();
}

class InvestPage extends StatefulWidget {
  final AppState state;
  const InvestPage({super.key, required this.state});

  @override
  State<InvestPage> createState() => _InvestPageState();
}

class _InvestPageState extends State<InvestPage> {
  AppState get s => widget.state;
  bool _refreshing = false;

  Future<void> _refreshAllPrices() async {
    if (_refreshing || s.holdings.isEmpty) return;
    setState(() => _refreshing = true);

    final items = s.holdings
        .map((h) => (
              id: h.id,
              code: h.code,
              isTwd: h.currency == StockCurrency.twd,
            ))
        .toList();

    final results = await Future.wait([
      StockService.fetchBatchPrices(items),
      s.refreshUsdTwdRate(),
    ]);
    if (!mounted) return;

    final prices = results[0] as Map<String, double>;
    for (final entry in prices.entries) {
      // 只更新價格，name 傳 null 以保留原有中文名稱
      s.updateHoldingPrice(entry.key, entry.value);
    }

    setState(() => _refreshing = false);
    if (mounted) {
      final total = s.holdings.length;
      final updated = prices.length;
      final msg = updated == 0
          ? AppLocalizations.of(context, 'price_fetch_failed')
          : updated < total
              ? AppLocalizations.ofParam(context, 'price_updated_partial', {'updated': updated, 'total': total})
              : AppLocalizations.ofParam(context, 'price_updated_all', {'n': updated});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: updated == 0 ? _kRed : _kGreen,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Future<void> _openEdit(StockHolding h) async {
    final result = await Navigator.push<StockHolding>(
      context,
      MaterialPageRoute(builder: (_) => AddEditInvestmentPage(existing: h)),
    );
    if (result != null && mounted) s.updateHolding(h.id, result);
  }

  void _showRateEditor() {
    final ctrl = TextEditingController(text: s.usdTwdRate.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(AppLocalizations.of(context, 'set_fx_rate'), style: const TextStyle(fontWeight: FontWeight.w800)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:
              const InputDecoration(labelText: 'USD/TWD', hintText: '32.0'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context, 'cancel'))),
          TextButton(
            onPressed: () {
              final rate = double.tryParse(ctrl.text.trim());
              if (rate != null && rate > 0) {
                s.setUsdTwdRate(rate);
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context, 'confirm'),
                style: const TextStyle(color: _kGold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showHoldingDetail(StockHolding h) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _HoldingDetailSheet(
        holding: h,
        usdTwd: s.usdTwdRate,
        onEdit: () {
          Navigator.pop(context);
          _openEdit(h);
        },
        onDelete: () {
          Navigator.pop(context);
          s.deleteHolding(h.id);
          ErrorHandler.showUndoSnack(
              context, AppLocalizations.ofParam(context, 'deleted_holding', {'code': h.code}), () => s.addHolding(h));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final holdings = s.holdings;
    final totalValue = s.totalPortfolioValue;
    final totalCost = s.totalPortfolioCost;
    final totalProfit = s.totalPortfolioProfit;
    final profitPct = s.totalPortfolioProfitPct;
    final isGain = totalProfit >= 0;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 0),
              child: Row(key: TourKeys.investHeader, children: [
                Text(AppLocalizations.of(context, 'invest'),
                    style:
                        const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const Spacer(),
                Opacity(
                  opacity: s.holdings.isNotEmpty ? 1.0 : 0.0,
                  child: GestureDetector(
                    key: TourKeys.investRefresh,
                    onTap: s.holdings.isNotEmpty ? _refreshAllPrices : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: _refreshing
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _kGold))
                          : const Icon(Icons.refresh_rounded,
                              color: _kGold, size: 20),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: _PortfolioSummaryCard(
                usdTwdRate: s.usdTwdRate,
                totalValue: totalValue,
                totalCost: totalCost,
                totalProfit: totalProfit,
                profitPct: profitPct,
                isGain: isGain,
                onEditRate: _showRateEditor,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
              child: Row(children: [
                Text(AppLocalizations.of(context, 'holding_detail'),
                    style:
                        const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(AppLocalizations.ofParam(context, 'holdings_count', {'n': holdings.length}),
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
            ),
          ),
          if (holdings.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(children: [
                    Icon(Icons.show_chart_rounded,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context, 'no_holdings'),
                        style: const TextStyle(color: Colors.grey, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(AppLocalizations.of(context, 'add_first_invest'),
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ]),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final h = holdings[i];
                    final accountName = h.accountId != null
                        ? s.accounts
                            .where((a) => a.id == h.accountId)
                            .map((a) => a.displayName)
                            .firstOrNull
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HoldingCard(
                        holding: h,
                        usdTwd: s.usdTwdRate,
                        accountName: accountName,
                        onTap: () => _showHoldingDetail(h),
                      ),
                    );
                  },
                  childCount: holdings.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              child: Text(
                AppLocalizations.of(context, 'invest_disclaimer'),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 總覽卡片 ──
class _PortfolioSummaryCard extends StatelessWidget {
  final double usdTwdRate, totalValue, totalCost, totalProfit, profitPct;
  final bool isGain;
  final VoidCallback onEditRate;

  const _PortfolioSummaryCard({
    required this.usdTwdRate,
    required this.totalValue,
    required this.totalCost,
    required this.totalProfit,
    required this.profitPct,
    required this.isGain,
    required this.onEditRate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profitColor = isGain ? _kGreen : _kRed;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(AppLocalizations.of(context, 'invest_overview'),
              style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: onEditRate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('USD/TWD: ',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                Text(usdTwdRate.toStringAsFixed(2),
                    style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const SizedBox(width: 4),
                Icon(Icons.edit_outlined, color: cs.onSurfaceVariant, size: 12),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Text(AppLocalizations.of(context, 'total_value'), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 4),
        Text('NT\$ ${_fmt(totalValue)}',
            style: TextStyle(
                color: cs.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Divider(color: cs.outlineVariant, height: 1),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context, 'total_cost'),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 4),
              Text('NT\$ ${_fmt(totalCost)}',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(AppLocalizations.of(context, 'total_profit'),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '${isGain ? '+' : ''}NT\$ ${_fmt(totalProfit)}',
                style: TextStyle(
                    color: profitColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                '${isGain ? '+' : ''}${profitPct.toStringAsFixed(2)}%',
                style: TextStyle(
                    color: profitColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ]),
      ]),
    );
  }
}

// ── 持股卡片 ──
class _HoldingCard extends StatelessWidget {
  final StockHolding holding;
  final double usdTwd;
  final String? accountName;
  final VoidCallback onTap;

  const _HoldingCard({
    required this.holding,
    required this.usdTwd,
    required this.onTap,
    this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    final h = holding;
    final profit = h.profitTwd(usdTwd);
    final pct = h.profitPct(usdTwd);
    final isGain = profit >= 0;
    final profitColor = isGain ? _kGreen : _kRed;
    final isUsd = h.currency == StockCurrency.usd;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          // 左：名稱 + 代碼 + 現價
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(h.name.isNotEmpty ? h.name : h.code,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis),
                ),
                if (isUsd) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('USD',
                        style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
              if (h.name.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 1, bottom: 2),
                  child: Text(h.code,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                ),
              if (accountName != null)
                Container(
                  margin: const EdgeInsets.only(top: 2, bottom: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(accountName!,
                      style: const TextStyle(
                          color: _kGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 2),
              if (h.currentPrice > 0) ...[
                if (isUsd) ...[
                  Text('\$ ${_fmtPrice(h.currentPrice)} USD',
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  Text('NT\$ ${_fmt(h.currentPrice * usdTwd)}',
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                ] else
                  Text('NT\$ ${_fmtPrice(h.currentPrice)}',
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ] else
                Text(AppLocalizations.of(context, 'no_current_price'),
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ]),
          ),

          // 右：損益
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${isGain ? '+' : ''}NT\$ ${_fmt(profit)}',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: profitColor),
            ),
            const SizedBox(height: 2),
            Text(
              '(${isGain ? '+' : ''}${pct.toStringAsFixed(1)}%)',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: profitColor),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── 持股詳情 ──
class _HoldingDetailSheet extends StatelessWidget {
  final StockHolding holding;
  final double usdTwd;
  final VoidCallback onEdit, onDelete;

  const _HoldingDetailSheet({
    required this.holding,
    required this.usdTwd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final h = holding;
    final profit = h.profitTwd(usdTwd);
    final pct = h.profitPct(usdTwd);
    final isGain = profit >= 0;
    final profitColor = isGain ? _kGreen : _kRed;
    final isUsd = h.currency == StockCurrency.usd;
    final currentValue = h.currentValueTwd(usdTwd);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(h.name.isNotEmpty ? h.name : h.code,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isUsd) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('USD',
                                style: TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ]),
                      if (h.name.isNotEmpty)
                        Text(h.code,
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 13)),
                    ]),
              ),
              IconButton(
                  icon: const Icon(Icons.edit_outlined, color: _kGold),
                  onPressed: onEdit),
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: _kRed),
                  onPressed: onDelete),
            ]),
            const SizedBox(height: 16),
            _DetailRow(AppLocalizations.of(context, 'shares'), AppLocalizations.ofParam(context, 'shares_value', {'n': _fmtShares(h.shares)}), cs: cs),
            _DetailRow(AppLocalizations.of(context, 'total_cost'), 'NT\$ ${_fmt(h.totalCost)}', cs: cs),
            if (h.currentPrice > 0) ...[
              _DetailRow(
                  AppLocalizations.of(context, 'current_price'),
                  isUsd
                      ? 'US\$ ${_fmtPrice(h.currentPrice)}  (≈ NT\$ ${_fmt(h.currentPrice * usdTwd)})'
                      : 'NT\$ ${_fmtPrice(h.currentPrice)}',
                  cs: cs),
              _DetailRow(AppLocalizations.of(context, 'current_value_label'), 'NT\$ ${_fmt(currentValue)}', cs: cs),
            ],
            _DetailRow(
              AppLocalizations.of(context, 'est_profit'),
              '${isGain ? '+' : ''}NT\$ ${_fmt(profit)}  (${isGain ? '+' : ''}${pct.toStringAsFixed(2)}%)',
              valueColor: profitColor,
              subtitle: isUsd
                  ? null
                  : AppLocalizations.ofParam(context, 'fee_and_tax_note', {'fee': (h.feeRate * 100).toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}),
              cs: cs,
            ),
            _DetailRow(AppLocalizations.of(context, 'buy_date'), DateFormat('yyyy/MM/dd').format(h.purchaseDate),
                cs: cs),
            if (h.buyReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context, 'buy_reason'),
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(h.buyReason, style: const TextStyle(fontSize: 14)),
            ],
            if (h.sellStrategy.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context, 'sell_strategy'),
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(h.sellStrategy, style: const TextStyle(fontSize: 14)),
            ],
          ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final String? subtitle;
  final Color? valueColor;
  final ColorScheme cs;
  const _DetailRow(this.label, this.value,
      {this.valueColor, this.subtitle, required this.cs});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(label,
                  style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? cs.onSurface)),
              if (subtitle != null)
                Text(subtitle!,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
          ),
        ]),
      );
}
