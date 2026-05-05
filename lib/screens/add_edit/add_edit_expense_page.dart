import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/localization.dart';
import '../../data/models/expense_item.dart';
import '../../data/repositories/app_state.dart';
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
  late TransactionType _type;
  late String? _selectedAccountId;
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
      _type = item.type;
      _selectedAccountId = item.accountId;
    } else {
      _titleCtrl = TextEditingController();
      _amtCtrl = TextEditingController();
      _noteCtrl = TextEditingController();
      _selectedCategory = '餐飲';
      _selectedDate = _today;
      _type = TransactionType.expense;
      _selectedAccountId = null;
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

  bool _isNamedDate(DateTime d) =>
      _isSameDay(d, _today) ||
      _isSameDay(d, _today.subtract(const Duration(days: 1))) ||
      _isSameDay(d, _today.subtract(const Duration(days: 2)));

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
        .where((e) => e.type == _type && e.category == _selectedCategory)
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

    final titleError = Validators.validateTitle(context, title);
    if (titleError != null) {
      ErrorHandler.showErrorSnack(context, titleError);
      return;
    }
    final amtError = Validators.validateAmount(context, amtStr);
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
      type: _type,
      accountId: _selectedAccountId,
    );

    Navigator.pop(context, newItem);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;
    final suggestions = _suggestions;
    final cs = Theme.of(context).colorScheme;
    final accounts = Provider.of<AppState>(context, listen: false).accounts;
    final isIncome = _type == TransactionType.income;
    final typeColor = isIncome ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          isEdit
              ? AppLocalizations.of(context, 'edit_entry')
              : (isIncome ? AppLocalizations.of(context, 'add_income') : AppLocalizations.of(context, 'add_expense')),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context, 'cancel'), style: const TextStyle(color: AppColors.gold)),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.gold),
                  )
                : Text(isEdit ? AppLocalizations.of(context, 'update') : AppLocalizations.of(context, 'save_label'),
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── 收入/支出 切換 ──
          _SectionLabel(AppLocalizations.of(context, 'type_label')),
          const SizedBox(height: 10),
          Row(children: [
            _TypeToggle(
              label: AppLocalizations.of(context, 'expense_type'),
              selected: !isIncome,
              color: AppColors.error,
              onTap: () => setState(() {
                _type = TransactionType.expense;
                if (isIncomeCategoryName(_selectedCategory)) _selectedCategory = '餐飲';
              }),
            ),
            const SizedBox(width: 12),
            _TypeToggle(
              label: AppLocalizations.of(context, 'income'),
              selected: isIncome,
              color: AppColors.success,
              onTap: () => setState(() {
                _type = TransactionType.income;
                if (!isIncomeCategoryName(_selectedCategory)) _selectedCategory = '薪資';
              }),
            ),
          ]),
          const SizedBox(height: 24),

          // ── 帳戶選擇 ──
          if (accounts.isNotEmpty) ...[
            _SectionLabel(AppLocalizations.of(context, 'account_label')),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 不關聯帳戶（永遠顯示在最前）
                  GestureDetector(
                    onTap: () => setState(() => _selectedAccountId = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedAccountId == null
                            ? cs.outlineVariant.withValues(alpha: 0.35)
                            : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedAccountId == null
                              ? cs.outline
                              : cs.outlineVariant,
                          width: _selectedAccountId == null ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppLocalizations.of(context, 'unlinked_account'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedAccountId == null
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                              )),
                          const SizedBox(height: 2),
                          Text(AppLocalizations.of(context, 'no_balance_effect'),
                              style: TextStyle(
                                  fontSize: 11, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                  // 各帳戶 chip
                  ...accounts.map((a) {
                    final sel = _selectedAccountId == a.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAccountId = a.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? typeColor.withValues(alpha: 0.12)
                              : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel ? typeColor : cs.outlineVariant,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(a.displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? typeColor : cs.onSurface,
                                )),
                            const SizedBox(height: 2),
                            Text(
                              '${a.currencySymbol} ${a.balance.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: sel
                                      ? typeColor.withValues(alpha: 0.8)
                                      : cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context, 'no_accounts_hint'),
                    style:
                        TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ]),
            ),
            const SizedBox(height: 24),
          ],

          // ── 日期 ──
          _SectionLabel(AppLocalizations.of(context, 'date')),
          const SizedBox(height: 10),
          Row(children: [
            _DateBtn(
              label: AppLocalizations.of(context, 'today'),
              sub: DateFormat('d').format(_today),
              selected: _isSameDay(_selectedDate, _today),
              onTap: () => setState(() => _selectedDate = _today),
            ),
            const SizedBox(width: 10),
            _DateBtn(
              label: AppLocalizations.of(context, 'yesterday'),
              sub: DateFormat('d')
                  .format(_today.subtract(const Duration(days: 1))),
              selected: _isSameDay(
                  _selectedDate, _today.subtract(const Duration(days: 1))),
              onTap: () => setState(() =>
                  _selectedDate = _today.subtract(const Duration(days: 1))),
            ),
            const SizedBox(width: 10),
            _DateBtn(
              label: AppLocalizations.of(context, 'day_before_yesterday'),
              sub: DateFormat('d')
                  .format(_today.subtract(const Duration(days: 2))),
              selected: _isSameDay(
                  _selectedDate, _today.subtract(const Duration(days: 2))),
              onTap: () => setState(() =>
                  _selectedDate = _today.subtract(const Duration(days: 2))),
            ),
          ]),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickOtherDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_isNamedDate(_selectedDate)
                      ? AppColors.gold
                      : cs.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: Row(children: [
                Text(AppLocalizations.of(context, 'other_date'),
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                  style: TextStyle(
                    color: !_isNamedDate(_selectedDate)
                        ? AppColors.gold
                        : cs.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),

          // ── 類別 ──
          _SectionLabel(isIncome ? AppLocalizations.of(context, 'income_category') : AppLocalizations.of(context, 'expense_category')),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: (isIncome ? kIncomeCategories : kCategories).map((c) {
              final sel = _selectedCategory == c.name;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = c.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: sel
                        ? c.color.withValues(alpha: 0.15)
                        : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? c.color : cs.outlineVariant,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(c.icon,
                            color: sel ? c.color : cs.onSurfaceVariant,
                            size: 26),
                        const SizedBox(height: 6),
                        Text(AppLocalizations.translateCategory(context, c.name),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? c.color : cs.onSurfaceVariant,
                            )),
                      ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── 推薦項目 ──
          if (suggestions.isNotEmpty) ...[
            _SectionLabel(AppLocalizations.ofParam(context, 'recommended_items', {'category': AppLocalizations.translateCategory(context, _selectedCategory)})),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .map((item) => GestureDetector(
                        onTap: () => _applySuggestion(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(item.title,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface)),
                            Text('NT\$ ${item.amount}',
                                style: TextStyle(
                                    fontSize: 11, color: cs.onSurfaceVariant)),
                          ]),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // ── 明細 ──
          _SectionLabel(isIncome ? AppLocalizations.of(context, 'income_detail') : AppLocalizations.of(context, 'expense_detail')),
          const SizedBox(height: 10),
          _InputField(controller: _titleCtrl, hint: AppLocalizations.of(context, 'name_hint'), label: null),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _InputField(
                controller: _amtCtrl,
                hint: '0',
                label: AppLocalizations.of(context, 'amount'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffix:
                    Text('NT\$', style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          _InputField(
              controller: _noteCtrl, hint: AppLocalizations.of(context, 'note_optional'), label: null, maxLines: 2),
          const SizedBox(height: 32),

          // ── 儲存按鈕 ──
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: isIncome ? AppColors.success : AppColors.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                isEdit
                    ? AppLocalizations.of(context, 'update_entry')
                    : (isIncome ? AppLocalizations.of(context, 'save_income') : AppLocalizations.of(context, 'save_expense')),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ── 類型切換按鈕 ──

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? color : cs.onSurfaceVariant,
          ),
        ),
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
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}

class _DateBtn extends StatelessWidget {
  final String label, sub;
  final bool selected;
  final VoidCallback onTap;
  const _DateBtn(
      {required this.label,
      required this.sub,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: selected ? AppColors.gold : cs.outlineVariant),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : cs.onSurfaceVariant,
              )),
          Text(sub,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : cs.onSurface,
              )),
        ]),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(label!,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: cs.onSurface)),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
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
}
