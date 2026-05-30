import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/localization.dart';
import '../../data/models/stock_holding.dart';
import '../../data/repositories/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../../services/stock_service.dart';

class _BrokerPreset {
  final String name;
  final double feeRate;
  final double minFee; // 最低手續費（元），0 = 無限制
  const _BrokerPreset(this.name, this.feeRate, {this.minFee = 0});
  String get feeLabel {
    if (feeRate == 0) return '0%';
    final pct = feeRate * 100;
    return '${pct.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}%';
  }
  String get minFeeLabel => minFee > 0 ? '最低${minFee.toStringAsFixed(0)}元' : '';
}

// 台股券商（手續費上限 0.1425%，加交易稅 0.3%，最低手續費 1 元）
const _twdBrokers = [
  _BrokerPreset('元大證券', 0.000855, minFee: 1),
  _BrokerPreset('富邦證券', 0.0007, minFee: 1),
  _BrokerPreset('永豐金證券', 0.001425, minFee: 1),
  _BrokerPreset('凱基證券', 0.0007, minFee: 1),
  _BrokerPreset('國泰證券', 0.0007, minFee: 1),
  _BrokerPreset('中信證券', 0.0007, minFee: 1),
  _BrokerPreset('群益證券', 0.0007, minFee: 1),
  _BrokerPreset('台新證券', 0.0007, minFee: 1),
  _BrokerPreset('玉山證券', 0.0007, minFee: 1),
  _BrokerPreset('統一證券', 0.0007, minFee: 1),
  _BrokerPreset('兆豐證券', 0.001425, minFee: 1),
  _BrokerPreset('華南永昌', 0.001425, minFee: 1),
];

// 美股券商（無交易稅）
const _usdBrokers = [
  _BrokerPreset('複委託 標準', 0.005, minFee: 0),
  _BrokerPreset('元大複委託', 0.005, minFee: 0),
  _BrokerPreset('富邦複委託', 0.005, minFee: 0),
  _BrokerPreset('永豐複委託', 0.005, minFee: 0),
  _BrokerPreset('凱基複委託', 0.005, minFee: 0),
  _BrokerPreset('第一證券 Firstrade', 0.0, minFee: 0),
  _BrokerPreset('嘉信理財 Schwab', 0.0, minFee: 0),
  _BrokerPreset('富途牛牛 Futu', 0.0008, minFee: 0),
  _BrokerPreset('Interactive Brokers', 0.0008, minFee: 0),
];

String _fmtRate(double r) {
  if (r == 0) return '0';
  return (r * 100)
      .toStringAsFixed(4)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

class AddEditInvestmentPage extends StatefulWidget {
  final StockHolding? existing;
  const AddEditInvestmentPage({super.key, this.existing});

  @override
  State<AddEditInvestmentPage> createState() => _AddEditInvestmentPageState();
}

class _AddEditInvestmentPageState extends State<AddEditInvestmentPage> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _sharesCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _strategyCtrl;
  late StockCurrency _currency;
  late DateTime _purchaseDate;

  bool _fetching = false;
  String? _fetchedName;
  String? _fetchError;
  List<StockSearchResult> _suggestions = [];
  bool _loadingSuggestions = false;
  late final TextEditingController _brokerCtrl;
  late final TextEditingController _feeRateCtrl;
  late final TextEditingController _minFeeCtrl;
  List<_BrokerPreset> _brokerSuggestions = [];
  String _selectedBroker = '';
  String? _selectedDeductAccountId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _sharesCtrl =
        TextEditingController(text: e != null ? e.shares.toString() : '');
    _costCtrl = TextEditingController(
        text: e != null ? e.totalCost.toStringAsFixed(0) : '');
    _priceCtrl = TextEditingController(
        text: e != null && e.currentPrice > 0 ? e.currentPrice.toString() : '');
    _reasonCtrl = TextEditingController(text: e?.buyReason ?? '');
    _strategyCtrl = TextEditingController(text: e?.sellStrategy ?? '');
    _currency = e?.currency ?? StockCurrency.twd;
    _purchaseDate = e?.purchaseDate ?? DateTime.now();
    _selectedBroker = e?.broker ?? '';
    _selectedDeductAccountId = e?.deductAccountId;
    if (e?.name.isNotEmpty == true) _fetchedName = e!.name;
    final existingRate = e?.feeRate ?? 0.001425;
    final existingMinFee = e?.minFee ?? 1.0;
    _brokerCtrl = TextEditingController();
    _feeRateCtrl = TextEditingController(text: _fmtRate(existingRate));
    _minFeeCtrl = TextEditingController(
        text: existingMinFee > 0 ? existingMinFee.toStringAsFixed(0) : '0');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _sharesCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _reasonCtrl.dispose();
    _strategyCtrl.dispose();
    _brokerCtrl.dispose();
    _feeRateCtrl.dispose();
    _minFeeCtrl.dispose();
    super.dispose();
  }

  bool get _isTwd => _currency == StockCurrency.twd;

  Future<void> _fetchPrice() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _fetching = true;
      _fetchError = null;
      _fetchedName = null;
      _suggestions = [];
    });
    final quote = await StockService.fetchQuoteWithChineseName(code, _isTwd);
    if (!mounted) return;
    if (quote == null) {
      setState(() {
        _fetching = false;
        _fetchError = AppLocalizations.ofParam(context, 'stock_not_found', {'code': code});
      });
    } else {
      _priceCtrl.text = quote.price.toString();
      setState(() {
        _fetching = false;
        _fetchedName = quote.name;
      });
    }
  }

  Future<void> _searchSuggestions(String query) async {
    if (query.length < 1) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _loadingSuggestions = true);
    final results = await StockService.search(query, _isTwd);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _loadingSuggestions = false;
    });
  }

  void _selectSuggestion(StockSearchResult r) {
    _codeCtrl.text = r.symbol;
    setState(() {
      _suggestions = [];
      _fetchedName = r.name;
    });
    _fetchPrice();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  void _save() {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      _snack(AppLocalizations.of(context, 'enter_stock_code'));
      return;
    }
    final shares = double.tryParse(_sharesCtrl.text.trim());
    if (shares == null || shares <= 0) {
      _snack(AppLocalizations.of(context, 'enter_valid_shares'));
      return;
    }
    final cost = double.tryParse(_costCtrl.text.trim());
    if (cost == null || cost <= 0) {
      _snack(AppLocalizations.of(context, 'enter_valid_cost'));
      return;
    }
    final feeRate = (double.tryParse(_feeRateCtrl.text.trim()) ?? 0.1425) / 100;
    final minFee = double.tryParse(_minFeeCtrl.text.trim()) ?? 0.0;
    Navigator.pop(
      context,
      StockHolding(
        id: widget.existing?.id,
        code: code,
        name: _fetchedName ?? widget.existing?.name ?? '',
        shares: shares,
        totalCost: cost,
        currency: _currency,
        purchaseDate: _purchaseDate,
        currentPrice: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        buyReason: _reasonCtrl.text.trim(),
        sellStrategy: _strategyCtrl.text.trim(),
        createdAt: widget.existing?.createdAt,
        feeRate: feeRate.clamp(0, 0.01),
        minFee: minFee.clamp(0, 999),
        broker: _selectedBroker,
        deductAccountId: _selectedDeductAccountId,
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final cs = Theme.of(context).colorScheme;

    final appState = context.read<AppState>();
    final nonStockAccounts = appState.accounts
        .where((a) => a.typeName != '股票帳戶')
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(isEdit ? AppLocalizations.of(context, 'edit_holding') : AppLocalizations.of(context, 'add_investment'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context, 'cancel'), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(isEdit ? AppLocalizations.of(context, 'update') : AppLocalizations.of(context, 'save_label'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── 幣別 ──
            _SectionHeader(AppLocalizations.of(context, 'select_market')),
            _GroupCard(
                cs: cs,
                child: Row(children: [
                  _CurrencyChip(
                    label: AppLocalizations.of(context, 'tw_stocks'),
                    selected: _isTwd,
                    onTap: () => setState(() {
                      _currency = StockCurrency.twd;
                      _suggestions = [];
                      _fetchedName = null;
                      _fetchError = null;
                    }),
                    cs: cs,
                  ),
                  const SizedBox(width: 10),
                  _CurrencyChip(
                    label: AppLocalizations.of(context, 'us_stocks'),
                    selected: !_isTwd,
                    onTap: () => setState(() {
                      _currency = StockCurrency.usd;
                      _suggestions = [];
                      _fetchedName = null;
                      _fetchError = null;
                    }),
                    cs: cs,
                  ),
                ])),
            const SizedBox(height: 20),

            // ── 股票代碼 + 搜尋 ──
            _SectionHeader(_isTwd ? AppLocalizations.of(context, 'code_section_tw') : AppLocalizations.of(context, 'code_section_us')),
            _GroupCard(
              cs: cs,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _codeCtrl,
                          textCapitalization: _isTwd
                              ? TextCapitalization.none
                              : TextCapitalization.characters,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              fontSize: 18),
                          onChanged: _searchSuggestions,
                          onSubmitted: (_) => _fetchPrice(),
                          decoration: InputDecoration(
                            hintText: _isTwd ? AppLocalizations.of(context, 'code_input_hint_tw') : 'Enter symbol',
                            hintStyle: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                                fontSize: 15),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _fetching
                          ? SizedBox(
                              width: 36,
                              height: 36,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: cs.primary),
                              ))
                          : GestureDetector(
                              onTap: _fetchPrice,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(AppLocalizations.of(context, 'query_price'),
                                    style: TextStyle(
                                        color: cs.onPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ),
                            ),
                    ]),

                    // 查詢結果
                    if (_fetchedName != null)
                      Container(
                        margin: const EdgeInsets.only(top: 6, bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Icon(Icons.check_circle_rounded,
                              color: cs.primary, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_fetchedName!,
                                style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                          if (_priceCtrl.text.isNotEmpty)
                            Text(
                              _isTwd
                                  ? 'NT\$ ${_priceCtrl.text}'
                                  : 'US\$ ${_priceCtrl.text}',
                              style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14),
                            ),
                        ]),
                      ),

                    if (_fetchError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 4),
                        child: Row(children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_fetchError!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 12)),
                          ),
                        ]),
                      ),

                    // 搜尋建議
                    if (_suggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: _suggestions
                              .map((r) => InkWell(
                                    onTap: () => _selectSuggestion(r),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      child: Row(children: [
                                        Text(r.symbol,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: cs.onSurface)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(r.name,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: cs.onSurfaceVariant),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        Text(r.exchange,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: cs.onSurfaceVariant)),
                                      ]),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    if (_loadingSuggestions)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: cs.primary))),
                      ),
                  ]),
            ),
            const SizedBox(height: 20),

            // ── 扣款帳戶 ──
            if (nonStockAccounts.isNotEmpty) ...[
              _SectionHeader(AppLocalizations.of(context, 'debit_account_label')),
              _GroupCard(
                cs: cs,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Text(AppLocalizations.of(context, 'debit_account_hint'), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _DeductChip(
                        label: AppLocalizations.of(context, 'not_linked'),
                        selected: _selectedDeductAccountId == null,
                        onTap: () => setState(() => _selectedDeductAccountId = null),
                        cs: cs,
                      ),
                      ...nonStockAccounts.map((a) {
                        final sel = _selectedDeductAccountId == a.id;
                        // 幣別不符警示
                        final acctIsUsd = a.currency == 'USD';
                        final mismatch = (_currency == StockCurrency.usd) != acctIsUsd;
                        return _DeductChip(
                          label: a.displayName,
                          selected: sel,
                          mismatch: sel && mismatch,
                          onTap: () => setState(() => _selectedDeductAccountId = a.id),
                          cs: cs,
                        );
                      }),
                    ]),
                  ),
                  if (_selectedDeductAccountId != null) ...[
                    Builder(builder: (ctx) {
                      final acct = nonStockAccounts.firstWhere((a) => a.id == _selectedDeductAccountId, orElse: () => nonStockAccounts.first);
                      final acctIsUsd = acct.currency == 'USD';
                      final mismatch = (_currency == StockCurrency.usd) != acctIsUsd;
                      if (!mismatch) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Row(children: [
                          Icon(Icons.warning_amber_rounded, size: 14, color: cs.primary),
                          const SizedBox(width: 6),
                          Expanded(child: Text(AppLocalizations.of(context, 'currency_mismatch_warning'), style: TextStyle(fontSize: 11, color: cs.primary))),
                        ]),
                      );
                    }),
                  ],
                  const SizedBox(height: 4),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // ── 券商 & 手續費 ──
            _SectionHeader(_isTwd ? AppLocalizations.of(context, 'broker_fee_section_tw') : AppLocalizations.of(context, 'broker_fee_section_us')),
            _GroupCard(
                cs: cs,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 52,
                        child: Row(children: [
                          Text(AppLocalizations.of(context, 'broker'),
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _brokerCtrl,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface),
                              decoration: InputDecoration(
                                hintText: _isTwd ? AppLocalizations.of(context, 'broker_hint_tw') : 'Enter broker',
                                hintStyle: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onChanged: (q) {
                                _selectedBroker = q;
                                final list = _isTwd ? _twdBrokers : _usdBrokers;
                                setState(() {
                                  _brokerSuggestions = q.isEmpty
                                      ? list
                                      : list
                                          .where((b) => b.name.contains(q))
                                          .toList();
                                });
                              },
                              onTap: () {
                                setState(() {
                                  _brokerSuggestions =
                                      _isTwd ? _twdBrokers : _usdBrokers;
                                });
                              },
                            ),
                          ),
                        ]),
                      ),
                      if (_brokerSuggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: _brokerSuggestions
                                .map((b) => InkWell(
                                      onTap: () {
                                        setState(() {
                                          _brokerCtrl.text = b.name;
                                          _selectedBroker = b.name;
                                          _feeRateCtrl.text =
                                              _fmtRate(b.feeRate);
                                          _minFeeCtrl.text = b.minFee > 0
                                              ? b.minFee.toStringAsFixed(0)
                                              : '0';
                                          _brokerSuggestions = [];
                                        });
                                        FocusScope.of(context).unfocus();
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 11),
                                        child: Row(children: [
                                          Expanded(
                                            child: Text(b.name,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color: cs.onSurface)),
                                          ),
                                          Text(
                                            b.minFeeLabel.isNotEmpty
                                                ? '${AppLocalizations.ofParam(context, 'fee_label_fmt', {'fee': b.feeLabel})}  ${b.minFeeLabel}'
                                                : AppLocalizations.ofParam(context, 'fee_label_fmt', {'fee': b.feeLabel}),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: cs.onSurfaceVariant)),
                                        ]),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      Divider(height: 1, color: cs.outlineVariant),
                      _InlineRow(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocalizations.of(context, 'fee_rate'),
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(AppLocalizations.of(context, 'fee_where_to_find')),
                                  content: Text(AppLocalizations.of(context, 'fee_help_body')),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                                ),
                              ),
                              child: Icon(Icons.help_outline_rounded, size: 16, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                        cs: cs,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _feeRateCtrl,
                                  textAlign: TextAlign.right,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface),
                                  decoration: InputDecoration(
                                    hintText: _isTwd ? '0.1425' : '0.5',
                                    hintStyle:
                                        TextStyle(color: cs.onSurfaceVariant),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              Text(' %',
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600)),
                            ]),
                      ),
                      if (_isTwd) ...[
                        Divider(height: 1, color: cs.outlineVariant),
                        _InlineRow(
                          label: AppLocalizations.of(context, 'min_commission'),
                          cs: cs,
                          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: _minFeeCtrl,
                                textAlign: TextAlign.right,
                                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
                                decoration: InputDecoration(
                                  hintText: '1',
                                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            Text(' 元', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ],
                      if (_isTwd) ...[
                        Divider(height: 1, color: cs.outlineVariant),
                        _InlineRow(
                          label: AppLocalizations.of(context, 'tx_tax'),
                          cs: cs,
                          child: Text(AppLocalizations.of(context, 'fixed_rate_03'),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ])),
            const SizedBox(height: 20),

            // ── 股票資訊 ──
            _SectionHeader(AppLocalizations.of(context, 'trade_info')),
            _GroupCard(
              cs: cs,
              child: Column(children: [
                _InlineRow(
                  label: AppLocalizations.of(context, 'shares'),
                  cs: cs,
                  child: TextField(
                    controller: _sharesCtrl,
                    textAlign: TextAlign.right,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: '100',
                      hintStyle: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.35),
                          fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Divider(height: 1, color: cs.outlineVariant),
                _InlineRow(
                  label: AppLocalizations.of(context, 'total_cost'),
                  cs: cs,
                  child: TextField(
                    controller: _costCtrl,
                    textAlign: TextAlign.right,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: '58000',
                      hintStyle: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.35),
                          fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      prefixText: 'NT\$ ',
                      prefixStyle: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.35)),
                    ),
                  ),
                ),
                Divider(height: 1, color: cs.outlineVariant),
                _InlineRow(
                  label: AppLocalizations.of(context, 'current_price'),
                  cs: cs,
                  child: TextField(
                    controller: _priceCtrl,
                    textAlign: TextAlign.right,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context, 'auto_fill'),
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      prefixText: _isTwd ? 'NT\$ ' : 'US\$ ',
                      prefixStyle: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── 購買日期 ──
            _SectionHeader(AppLocalizations.of(context, 'purchase_date')),
            _GroupCard(
              cs: cs,
              child: GestureDetector(
                onTap: _pickDate,
                behavior: HitTestBehavior.opaque,
                child: _InlineRow(
                  label: AppLocalizations.of(context, 'date'),
                  cs: cs,
                  child: Text(
                    DateFormat('MMM d, yyyy', 'en_US').format(_purchaseDate),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── 投資筆記 ──
            _SectionHeader(AppLocalizations.of(context, 'invest_notes_optional')),
            _GroupCard(
              cs: cs,
              child: Column(children: [
                _NoteRow(
                  emoji: '💡',
                  label: AppLocalizations.of(context, 'buy_reason'),
                  controller: _reasonCtrl,
                  hint: AppLocalizations.of(context, 'buy_reason_hint'),
                  cs: cs,
                ),
                Divider(height: 1, color: cs.outlineVariant),
                _NoteRow(
                  emoji: '🏳️',
                  label: AppLocalizations.of(context, 'sell_timing'),
                  controller: _strategyCtrl,
                  hint: AppLocalizations.of(context, 'sell_timing_hint'),
                  cs: cs,
                ),
              ]),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class _GroupCard extends StatelessWidget {
  final Widget child;
  final ColorScheme cs;
  const _GroupCard({required this.child, required this.cs});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: child,
      );
}

class _InlineRow extends StatelessWidget {
  final dynamic label; // String or Widget
  final Widget child;
  final ColorScheme cs;
  const _InlineRow(
      {required this.label, required this.child, required this.cs});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: Row(children: [
          label is Widget
              ? label as Widget
              : Text(label as String,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface)),
          const SizedBox(width: 12),
          Expanded(child: child),
        ]),
      );
}

class _NoteRow extends StatelessWidget {
  final String emoji, label, hint;
  final TextEditingController controller;
  final ColorScheme cs;
  const _NoteRow({
    required this.emoji,
    required this.label,
    required this.hint,
    required this.controller,
    required this.cs,
  });
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$emoji  $label',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              filled: true,
              fillColor: cs.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ]),
      );
}

class _CurrencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _CurrencyChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.cs});
  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : cs.onSurfaceVariant)),
            ),
          ),
        ),
      );
}

class _DeductChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool mismatch;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _DeductChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
    this.mismatch = false,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 8, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? (mismatch ? Colors.orange : cs.primary)
                  : cs.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? (mismatch ? Colors.orange : cs.primary)
                      : cs.onSurfaceVariant)),
        ),
      );
}
