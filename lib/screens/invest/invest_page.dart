import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/app_state.dart';
import '../../data/models/stock_holding.dart';
import '../../core/constants/app_colors.dart';
import 'add_edit_investment_page.dart';

const _kGold = AppColors.gold;
const _kGreen = AppColors.success;
const _kRed = AppColors.error;
const _kCard = AppColors.cardLight;

String _fmt(double v) {
  if (v.abs() >= 1000000) {
    return '${(v / 1000000).toStringAsFixed(1)}M';
  }
  final fmt = NumberFormat('#,##0', 'en_US');
  return fmt.format(v.round());
}

String _fmtPrice(double v) {
  if (v >= 100) return v.toStringAsFixed(1);
  if (v >= 10) return v.toStringAsFixed(2);
  return v.toStringAsFixed(3);
}

class InvestPage extends StatefulWidget {
  final AppState state;
  const InvestPage({super.key, required this.state});

  @override
  State<InvestPage> createState() => _InvestPageState();
}

class _InvestPageState extends State<InvestPage> {
  AppState get s => widget.state;

  Future<void> _openAdd() async {
    final result = await Navigator.push<StockHolding>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditInvestmentPage()),
    );
    if (result != null && mounted) {
      s.addHolding(result);
    }
  }

  Future<void> _openEdit(StockHolding h) async {
    final result = await Navigator.push<StockHolding>(
      context,
      MaterialPageRoute(builder: (_) => AddEditInvestmentPage(existing: h)),
    );
    if (result != null && mounted) {
      s.updateHolding(h.id, result);
    }
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
          decoration: const InputDecoration(
            labelText: 'USD/TWD',
            hintText: '32.0',
          ),
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
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('投資', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),

              // ── 投資總覽 ──
              _PortfolioSummaryCard(
                usdTwdRate: s.usdTwdRate,
                totalValue: totalValue,
                totalCost: totalCost,
                totalProfit: totalProfit,
                profitPct: profitPct,
                isGain: isGain,
                onEditRate: _showRateEditor,
              ),
              const SizedBox(height: 20),

              // ── 持股明細 ──
              Row(children: [
                const Text('持股明細', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${holdings.length} 檔', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
              const SizedBox(height: 12),

              if (holdings.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(children: [
                    Icon(Icons.show_chart_rounded, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('還沒有持股', style: TextStyle(color: Colors.grey, fontSize: 15)),
                    const SizedBox(height: 6),
                    const Text('點右下角 + 新增第一筆投資',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ]),
                )
              else
                ...holdings.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HoldingCard(
                    holding: h,
                    usdTwd: s.usdTwdRate,
                    onTap: () => _showHoldingDetail(h),
                  ),
                )),
            ]),
          ),

          // ── FAB ──
          Positioned(
            bottom: 24,
            right: 18,
            child: FloatingActionButton(
              heroTag: 'invest_fab',
              onPressed: _openAdd,
              backgroundColor: _kGold,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 匯率列
        Row(children: [
          const Text('投資總覽', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: onEditRate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('USD/TWD ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(usdTwdRate.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(width: 4),
                const Icon(Icons.edit_outlined, color: Colors.white54, size: 13),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // 總現值
        const Text('總現值（TWD）', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text('NT\$ ${_fmt(totalValue)}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),

        const Divider(color: Colors.white12, height: 1),
        const SizedBox(height: 16),

        // 成本 / 損益
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('總成本', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 4),
            Text('NT\$ ${_fmt(totalCost)}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('總損益', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              '${isGain ? '+' : ''}NT\$ ${_fmt(totalProfit)}',
              style: TextStyle(
                color: isGain ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
                fontSize: 16, fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${isGain ? '+' : ''}${profitPct.toStringAsFixed(2)}%',
              style: TextStyle(
                color: isGain ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
                fontSize: 13, fontWeight: FontWeight.w600,
              ),
            ),
          ])),
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          // 代碼 + 幣別
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(h.code,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              if (isUsd) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('USD',
                      style: TextStyle(color: Color(0xFF1565C0), fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            const SizedBox(height: 3),
            Text('${_fmtShares(h.shares)} 股',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
          const Spacer(),

          // 價格 + 損益
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (h.currentPrice > 0) ...[
              Text(
                isUsd
                    ? 'US\$ ${_fmtPrice(h.currentPrice)}'
                    : 'NT\$ ${_fmtPrice(h.currentPrice)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              if (isUsd)
                Text(
                  '≈ NT\$ ${_fmt(h.currentPrice * usdTwd)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
            ] else
              const Text('尚無現價', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: profitColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${isGain ? '+' : ''}NT\$ ${_fmt(profit)}  ${isGain ? '+' : ''}${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: profitColor, fontSize: 12, fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),

          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        ]),
      ),
    );
  }
}

String _fmtShares(double shares) {
  if (shares == shares.roundToDouble()) return shares.round().toString();
  return shares.toString();
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(h.code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          if (isUsd) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('USD', style: TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _kGold),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: _kRed),
            onPressed: onDelete,
          ),
        ]),
        const SizedBox(height: 16),

        _DetailRow('股數', '${_fmtShares(h.shares)} 股'),
        _DetailRow('總成本', 'NT\$ ${_fmt(h.totalCost)}'),
        if (h.currentPrice > 0) ...[
          _DetailRow('現價', isUsd
              ? 'US\$ ${_fmtPrice(h.currentPrice)}  (≈ NT\$ ${_fmt(h.currentPrice * usdTwd)})'
              : 'NT\$ ${_fmtPrice(h.currentPrice)}'),
          _DetailRow('現值', 'NT\$ ${_fmt(currentValue)}'),
        ],
        _DetailRow('損益', '${isGain ? '+' : ''}NT\$ ${_fmt(profit)}  (${isGain ? '+' : ''}${pct.toStringAsFixed(2)}%)',
            valueColor: profitColor),
        _DetailRow('買入日期', DateFormat('yyyy/MM/dd').format(h.purchaseDate)),

        if (h.buyReason.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('買入理由', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(h.buyReason, style: const TextStyle(fontSize: 14)),
        ],
        if (h.sellStrategy.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('出場策略', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(h.sellStrategy, style: const TextStyle(fontSize: 14)),
        ],
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _DetailRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(
        width: 72,
        child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
      Expanded(
        child: Text(value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? Colors.black87)),
      ),
    ]),
  );
}
