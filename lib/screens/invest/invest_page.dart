import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/app_state.dart';
import '../../data/models/stock_holding.dart';
import '../../core/constants/app_colors.dart';
import '../../services/stock_service.dart';
import 'add_edit_investment_page.dart';

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

    final items = s.holdings.map((h) => (
      id: h.id,
      code: h.code,
      isTwd: h.currency == StockCurrency.twd,
    )).toList();

    final quotes = await StockService.fetchBatch(items);
    if (!mounted) return;

    for (final entry in quotes.entries) {
      s.updateHoldingPrice(entry.key, entry.value.price, name: entry.value.name);
    }

    setState(() => _refreshing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('已更新 ${quotes.length} 檔現價'),
        backgroundColor: _kGreen,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<StockHolding>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditInvestmentPage()),
    );
    if (result != null && mounted) s.addHolding(result);
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
        title: const Text('設定匯率', style: TextStyle(fontWeight: FontWeight.w800)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'USD/TWD', hintText: '32.0'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final rate = double.tryParse(ctrl.text.trim());
              if (rate != null && rate > 0) {
                s.setUsdTwdRate(rate);
                Navigator.pop(context);
              }
            },
            child: const Text('確認', style: TextStyle(color: _kGold, fontWeight: FontWeight.w700)),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已刪除 ${h.code}'),
              action: SnackBarAction(
                label: '復原',
                textColor: Colors.amber,
                onPressed: () => s.addHolding(h),
              ),
            ),
          );
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
              child: Row(children: [
                const Text('投資', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const Spacer(),
                if (s.holdings.isNotEmpty)
                  GestureDetector(
                    onTap: _refreshAllPrices,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: _refreshing
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(strokeWidth: 2, color: _kGold))
                          : const Icon(Icons.refresh_rounded, color: _kGold, size: 20),
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
                const Text('持股明細', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${holdings.length} 檔',
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
                    Icon(Icons.show_chart_rounded, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('還沒有持股', style: TextStyle(color: Colors.grey, fontSize: 15)),
                    const SizedBox(height: 6),
                    const Text('點右上角 + 新增第一筆投資',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ]),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HoldingCard(
                      holding: holdings[i],
                      usdTwd: s.usdTwdRate,
                      onTap: () => _showHoldingDetail(holdings[i]),
                    ),
                  ),
                  childCount: holdings.length,
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
          Text('投資總覽',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
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
                        color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(width: 4),
                Icon(Icons.edit_outlined, color: cs.onSurfaceVariant, size: 12),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),

        Text('總現值', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 4),
        Text('NT\$ ${_fmt(totalValue)}',
            style: TextStyle(
                color: cs.onSurface, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),

        Divider(color: cs.outlineVariant, height: 1),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('總成本',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 4),
              Text('NT\$ ${_fmt(totalCost)}',
                  style: TextStyle(
                      color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('總損益',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '${isGain ? '+' : ''}NT\$ ${_fmt(totalProfit)}',
                style: TextStyle(
                    color: profitColor, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                '${isGain ? '+' : ''}${profitPct.toStringAsFixed(2)}%',
                style: TextStyle(
                    color: profitColor, fontSize: 13, fontWeight: FontWeight.w600),
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
  final VoidCallback onTap;

  const _HoldingCard({required this.holding, required this.usdTwd, required this.onTap});

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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(h.name.isNotEmpty ? h.name : h.code,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis),
                ),
                if (isUsd) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                ),
              const SizedBox(height: 2),
              if (h.currentPrice > 0) ...[
                if (isUsd) ...[
                  Text('\$ ${_fmtPrice(h.currentPrice)} USD',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  Text('NT\$ ${_fmt(h.currentPrice * usdTwd)}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                ] else
                  Text('NT\$ ${_fmtPrice(h.currentPrice)}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ] else
                Text('尚無現價',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ]),
          ),

          // 右：損益
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${isGain ? '+' : ''}NT\$ ${_fmt(profit)}',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: profitColor),
            ),
            const SizedBox(height: 2),
            Text(
              '(${isGain ? '+' : ''}${pct.toStringAsFixed(1)}%)',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: profitColor),
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(h.name.isNotEmpty ? h.name : h.code,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isUsd) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.12),
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
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
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
            _DetailRow('股數', '${_fmtShares(h.shares)} 股', cs: cs),
            _DetailRow('總成本', 'NT\$ ${_fmt(h.totalCost)}', cs: cs),
            if (h.currentPrice > 0) ...[
              _DetailRow(
                  '現價',
                  isUsd
                      ? 'US\$ ${_fmtPrice(h.currentPrice)}  (≈ NT\$ ${_fmt(h.currentPrice * usdTwd)})'
                      : 'NT\$ ${_fmtPrice(h.currentPrice)}',
                  cs: cs),
              _DetailRow('現值', 'NT\$ ${_fmt(currentValue)}', cs: cs),
            ],
            _DetailRow(
              '預估損益',
              '${isGain ? '+' : ''}NT\$ ${_fmt(profit)}  (${isGain ? '+' : ''}${pct.toStringAsFixed(2)}%)',
              valueColor: profitColor,
              subtitle: isUsd ? null : '已扣手續費 ${(h.feeRate * 100).toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}%＋交易稅 0.3%',
              cs: cs,
            ),
            _DetailRow('買入日期', DateFormat('yyyy/MM/dd').format(h.purchaseDate), cs: cs),
            if (h.buyReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('買入理由',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(h.buyReason, style: const TextStyle(fontSize: 14)),
            ],
            if (h.sellStrategy.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('出場策略',
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
  const _DetailRow(this.label, this.value, {this.valueColor, this.subtitle, required this.cs});

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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
