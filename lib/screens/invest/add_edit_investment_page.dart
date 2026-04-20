import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/stock_holding.dart';
import '../../core/constants/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _sharesCtrl = TextEditingController(text: e != null ? e.shares.toString() : '');
    _costCtrl = TextEditingController(text: e != null ? e.totalCost.toStringAsFixed(0) : '');
    _priceCtrl = TextEditingController(text: e != null && e.currentPrice > 0 ? e.currentPrice.toString() : '');
    _reasonCtrl = TextEditingController(text: e?.buyReason ?? '');
    _strategyCtrl = TextEditingController(text: e?.sellStrategy ?? '');
    _currency = e?.currency ?? StockCurrency.twd;
    _purchaseDate = e?.purchaseDate ?? DateTime.now();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入股票代碼')),
      );
      return;
    }
    final shares = double.tryParse(_sharesCtrl.text.trim());
    if (shares == null || shares <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入有效的股數')),
      );
      return;
    }
    final cost = double.tryParse(_costCtrl.text.trim());
    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入有效的成本（TWD）')),
      );
      return;
    }

    final result = StockHolding(
      id: widget.existing?.id,
      code: code,
      shares: shares,
      totalCost: cost,
      currency: _currency,
      purchaseDate: _purchaseDate,
      currentPrice: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      buyReason: _reasonCtrl.text.trim(),
      sellStrategy: _strategyCtrl.text.trim(),
      createdAt: widget.existing?.createdAt,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? '編輯持股' : '新增持股',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 幣別
          _SectionLabel('幣別'),
          const SizedBox(height: 10),
          Row(children: [
            _CurrencyBtn(
              label: 'TWD 台股',
              selected: _currency == StockCurrency.twd,
              onTap: () => setState(() => _currency = StockCurrency.twd),
            ),
            const SizedBox(width: 12),
            _CurrencyBtn(
              label: 'USD 美股',
              selected: _currency == StockCurrency.usd,
              onTap: () => setState(() => _currency = StockCurrency.usd),
            ),
          ]),
          const SizedBox(height: 24),

          // 股票代碼
          _SectionLabel('股票代碼'),
          const SizedBox(height: 10),
          _InputField(
            controller: _codeCtrl,
            hint: _currency == StockCurrency.usd ? 'NVDA' : '2330',
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 20),

          // 股數 / 成本
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionLabel('股數'),
              const SizedBox(height: 10),
              _InputField(
                controller: _sharesCtrl,
                hint: '100',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionLabel('總成本（TWD）'),
              const SizedBox(height: 10),
              _InputField(
                controller: _costCtrl,
                hint: '50000',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ])),
          ]),
          const SizedBox(height: 20),

          // 現價（選填）
          _SectionLabel('現價（選填，${_currency == StockCurrency.usd ? 'USD' : 'TWD'}）'),
          const SizedBox(height: 10),
          _InputField(
            controller: _priceCtrl,
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),

          // 買入日期
          _SectionLabel('買入日期'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Text(DateFormat('yyyy/MM/dd').format(_purchaseDate),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // 買入理由
          _SectionLabel('買入理由（選填）'),
          const SizedBox(height: 10),
          _InputField(
            controller: _reasonCtrl,
            hint: '例如：看好 AI 趨勢',
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // 出場策略
          _SectionLabel('出場策略（選填）'),
          const SizedBox(height: 10),
          _InputField(
            controller: _strategyCtrl,
            hint: '例如：漲 30% 賣出一半',
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                isEdit ? '更新持股' : '新增持股',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54),
  );
}

class _CurrencyBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CurrencyBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.gold : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.black54,
          )),
        ),
      ),
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextCapitalization textCapitalization;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    textCapitalization: textCapitalization,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black26),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
