import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_item.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/error_handler.dart';

class AddEditExpensePage extends StatefulWidget {
  final ExpenseItem? existingItem;
  final List<ExpenseItem> allExpenses;

  const AddEditExpensePage({
    super.key,
    this.existingItem,
    this.allExpenses = const [],
  });

  @override
  State<AddEditExpensePage> createState() => _AddEditExpensePageState();
}

class _AddEditExpensePageState extends State<AddEditExpensePage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amtCtrl;
  late final TextEditingController _noteCtrl;
  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;

  final _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _titleCtrl = TextEditingController(text: item.title);
      _amtCtrl = TextEditingController(text: item.amount.toString());
      _noteCtrl = TextEditingController(text: item.note);
      _selectedCategory = item.category;
      _selectedDate = item.date;
    } else {
      _titleCtrl = TextEditingController();
      _amtCtrl = TextEditingController();
      _noteCtrl = TextEditingController();
      _selectedCategory = '餐飲';
      _selectedDate = _today;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(DateTime d) {
    if (_isSameDay(d, _today)) return '今天';
    if (_isSameDay(d, _today.subtract(const Duration(days: 1)))) return '昨天';
    if (_isSameDay(d, _today.subtract(const Duration(days: 2)))) return '前天';
    return DateFormat('M/d').format(d);
  }

  Future<void> _pickOtherDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: _today.add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  List<ExpenseItem> get _suggestions {
    final seen = <String>{};
    return widget.allExpenses
        .where((e) => e.category == _selectedCategory)
        .where((e) => seen.add(e.title))
        .take(5)
        .toList();
  }

  void _applySuggestion(ExpenseItem item) {
    setState(() {
      _titleCtrl.text = item.title;
      _amtCtrl.text = item.amount.toString();
      if (item.note.isNotEmpty) _noteCtrl.text = item.note;
    });
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amtStr = _amtCtrl.text.trim();

    final titleError = Validators.validateTitle(title);
    if (titleError != null) {
      ErrorHandler.showErrorSnack(context, titleError);
      return;
    }
    final amtError = Validators.validateAmount(amtStr);
    if (amtError != null) {
      ErrorHandler.showErrorSnack(context, amtError);
      return;
    }

    setState(() => _isLoading = true);

    final newItem = ExpenseItem(
      id: widget.existingItem?.id,
      title: title,
      category: _selectedCategory,
      amount: double.parse(amtStr).round(),
      date: _selectedDate,
      note: _noteCtrl.text.trim(),
      createdAt: widget.existingItem?.createdAt,
    );

    Navigator.pop(context, newItem);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;
    final suggestions = _suggestions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? '編輯支出' : '新增記帳',
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
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  )
                : Text(isEdit ? '更新' : '儲存',
                    style: const TextStyle(
                        color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── 日期 ──
          _SectionLabel('日期'),
          const SizedBox(height: 10),
          Row(children: [
            _DateBtn(
              label: '今天',
              sub: DateFormat('d').format(_today),
              selected: _isSameDay(_selectedDate, _today),
              onTap: () => setState(() => _selectedDate = _today),
            ),
            const SizedBox(width: 10),
            _DateBtn(
              label: '昨天',
              sub: DateFormat('d').format(_today.subtract(const Duration(days: 1))),
              selected: _isSameDay(_selectedDate, _today.subtract(const Duration(days: 1))),
              onTap: () => setState(() => _selectedDate = _today.subtract(const Duration(days: 1))),
            ),
            const SizedBox(width: 10),
            _DateBtn(
              label: '前天',
              sub: DateFormat('d').format(_today.subtract(const Duration(days: 2))),
              selected: _isSameDay(_selectedDate, _today.subtract(const Duration(days: 2))),
              onTap: () => setState(() => _selectedDate = _today.subtract(const Duration(days: 2))),
            ),
          ]),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickOtherDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_isSameDay(_selectedDate, _today) &&
                          !_isSameDay(_selectedDate, _today.subtract(const Duration(days: 1))) &&
                          !_isSameDay(_selectedDate, _today.subtract(const Duration(days: 2)))
                      ? AppColors.gold
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Row(children: [
                const Text('其他日期', style: TextStyle(color: Colors.black54, fontSize: 14)),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                  style: TextStyle(
                    color: _dateLabel(_selectedDate) == DateFormat('M/d').format(_selectedDate)
                        ? AppColors.gold
                        : Colors.black38,
                    fontSize: 14,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          // ── 支出類別 ──
          _SectionLabel('支出類別'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: kCategories.map((c) {
              final sel = _selectedCategory == c.name;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = c.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: sel ? c.color.withValues(alpha: 0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? c.color : Colors.grey.shade200,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(c.icon, color: sel ? c.color : Colors.grey.shade400, size: 26),
                    const SizedBox(height: 6),
                    Text(c.name, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: sel ? c.color : Colors.black54,
                    )),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── 推薦項目 ──
          if (suggestions.isNotEmpty) ...[
            Row(children: [
              _SectionLabel('${_selectedCategory} 推薦項目'),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((item) => GestureDetector(
                onTap: () => _applySuggestion(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(item.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('NT\$ ${item.amount}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // ── 支出明細 ──
          _SectionLabel('支出明細'),
          const SizedBox(height: 10),
          _InputField(
            controller: _titleCtrl,
            hint: '項目名稱',
            label: null,
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _InputField(
                controller: _amtCtrl,
                hint: '0',
                label: '金額',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffix: const Text('NT\$', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          _InputField(
            controller: _noteCtrl,
            hint: '備註（選填）',
            label: null,
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          // ── 儲存按鈕 ──
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                isEdit ? '更新支出' : '儲存記帳',
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

// ── 小元件 ──

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54),
  );
}

class _DateBtn extends StatelessWidget {
  final String label, sub;
  final bool selected;
  final VoidCallback onTap;
  const _DateBtn({required this.label, required this.sub, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.gold : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? AppColors.gold : Colors.grey.shade200),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: selected ? Colors.white : Colors.black54,
        )),
        Text(sub, style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w800,
          color: selected ? Colors.white : Colors.black87,
        )),
      ]),
    ),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.label,
    this.keyboardType,
    this.suffix,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(children: [
      if (label != null) ...[
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(label!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: label != null ? 0 : 16,
              vertical: 14,
            ),
          ),
        ),
      ),
      if (suffix != null)
        Padding(padding: const EdgeInsets.only(right: 16), child: suffix!),
    ]),
  );
}
