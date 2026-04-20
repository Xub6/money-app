import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/stock_holding.dart';
import '../../core/constants/app_colors.dart';
import '../../services/stock_service.dart';

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

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _sharesCtrl = TextEditingController(text: e != null ? e.shares.toString() : '');
    _costCtrl = TextEditingController(text: e != null ? e.totalCost.toStringAsFixed(0) : '');
    _priceCtrl = TextEditingController(
        text: e != null && e.currentPrice > 0 ? e.currentPrice.toString() : '');
    _reasonCtrl = TextEditingController(text: e?.buyReason ?? '');
    _strategyCtrl = TextEditingController(text: e?.sellStrategy ?? '');
    _currency = e?.currency ?? StockCurrency.twd;
    _purchaseDate = e?.purchaseDate ?? DateTime.now();
    if (e?.name.isNotEmpty == true) _fetchedName = e!.name;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _sharesCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _reasonCtrl.dispose();
    _strategyCtrl.dispose();
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
    final quote = await StockService.fetchQuote(code, _isTwd);
    if (!mounted) return;
    if (quote == null) {
      setState(() {
        _fetching = false;
        _fetchError = '找不到「$code」，請確認代碼是否正確';
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
      _snack('請輸入股票代碼');
      return;
    }
    final shares = double.tryParse(_sharesCtrl.text.trim());
    if (shares == null || shares <= 0) {
      _snack('請輸入有效的股數');
      return;
    }
    final cost = double.tryParse(_costCtrl.text.trim());
    if (cost == null || cost <= 0) {
      _snack('請輸入有效的成本（TWD）');
      return;
    }
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
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(isEdit ? '編輯持股' : '新增投資',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: AppColors.gold)),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(isEdit ? '更新' : '儲存',
                style: const TextStyle(
                    color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── 幣別 ──
            _SectionHeader('選擇市場'),
            _GroupCard(cs: cs, child: Row(children: [
              _CurrencyChip(
                label: '🇹🇼  台股',
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
                label: '🇺🇸  美股',
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
            _SectionHeader(_isTwd ? '股票代碼（例：2330、0050）' : '股票代碼（例：AAPL、TSLA）'),
            _GroupCard(
              cs: cs,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _codeCtrl,
                      textCapitalization: _isTwd ? TextCapitalization.none : TextCapitalization.characters,
                      style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface, fontSize: 18),
                      onChanged: _searchSuggestions,
                      onSubmitted: (_) => _fetchPrice(),
                      decoration: InputDecoration(
                        hintText: _isTwd ? '輸入代碼或名稱' : 'Enter symbol',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w400, fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _fetching
                      ? const SizedBox(
                          width: 36, height: 36,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                          ))
                      : GestureDetector(
                          onTap: _fetchPrice,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('查詢現價',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                ]),

                // 查詢結果
                if (_fetchedName != null)
                  Container(
                    margin: const EdgeInsets.only(top: 6, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_fetchedName!,
                            style: const TextStyle(
                                color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                      if (_priceCtrl.text.isNotEmpty)
                        Text(
                          _isTwd
                              ? 'NT\$ ${_priceCtrl.text}'
                              : 'US\$ ${_priceCtrl.text}',
                          style: const TextStyle(
                              color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                    ]),
                  ),

                if (_fetchError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 15),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_fetchError!,
                            style: const TextStyle(color: AppColors.error, fontSize: 12)),
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
                      children: _suggestions.map((r) => InkWell(
                        onTap: () => _selectSuggestion(r),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                      fontSize: 12, color: cs.onSurfaceVariant),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text(r.exchange,
                                style: TextStyle(
                                    fontSize: 11, color: cs.onSurfaceVariant)),
                          ]),
                        ),
                      )).toList(),
                    ),
                  ),
                if (_loadingSuggestions)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                        child: SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))),
                  ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── 股票資訊 ──
            _SectionHeader('交易資訊'),
            _GroupCard(
              cs: cs,
              child: Column(children: [
                _InlineRow(
                  label: '股數',
                  cs: cs,
                  child: TextField(
                    controller: _sharesCtrl,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: '100',
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Divider(height: 1, color: cs.outlineVariant),
                _InlineRow(
                  label: '總成本',
                  cs: cs,
                  child: TextField(
                    controller: _costCtrl,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: '58000',
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      prefixText: 'NT\$ ',
                      prefixStyle: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
                Divider(height: 1, color: cs.outlineVariant),
                _InlineRow(
                  label: '現價',
                  cs: cs,
                  child: TextField(
                    controller: _priceCtrl,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: '自動帶入',
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
            _SectionHeader('購買日期'),
            _GroupCard(
              cs: cs,
              child: GestureDetector(
                onTap: _pickDate,
                behavior: HitTestBehavior.opaque,
                child: _InlineRow(
                  label: '日期',
                  cs: cs,
                  child: Text(
                    DateFormat('MMM d, yyyy', 'en_US').format(_purchaseDate),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── 投資筆記 ──
            _SectionHeader('投資筆記（選填）'),
            _GroupCard(
              cs: cs,
              child: Column(children: [
                _NoteRow(
                  emoji: '💡',
                  label: '買入理由',
                  controller: _reasonCtrl,
                  hint: '例如：看好 AI 趨勢',
                  cs: cs,
                ),
                Divider(height: 1, color: cs.outlineVariant),
                _NoteRow(
                  emoji: '🏳️',
                  label: '賣出時機',
                  controller: _strategyCtrl,
                  hint: '例如：漲 30% 賣出一半',
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
  final String label;
  final Widget child;
  final ColorScheme cs;
  const _InlineRow({required this.label, required this.child, required this.cs});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface)),
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
                  fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
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
                borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
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
              color: selected ? AppColors.gold : cs.surfaceContainerHighest,
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
